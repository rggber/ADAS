`timescale 1ps/1ps

module vin_frame_buffer_ctrl_ch1
 #(
	parameter MEM_DATA_BITS = 64
) 
(
	input rst_n,                                    
	input vin_clk,                                  
	input vin_vs,                                   
	input vin_de,                                  
	input[15:0] vin_data,                          
	input[11:0] vin_width,                          
	input[11:0] vin_height,                         
	
	input mem_clk,                                  
	output reg wr_burst_req,                        
	output reg[9:0] wr_burst_len,                   
	output reg[23:0] wr_burst_addr,                 
	input wr_burst_data_req,                       
	output[MEM_DATA_BITS - 1:0] wr_burst_data,      
	input burst_finish,                             
	
	//
	input[7:0]	base_ch1_hsync,
	input[15:0]	base_ch1_vsync,
	input[15:0]	width_ch1
);                                                   
localparam BURST_LEN = 10'd128;              
localparam BURST_IDLE = 3'd0;                
localparam BURST_ONE_LINE_START = 3'd1;       
localparam BURSTING = 3'd2;                   
localparam BURST_END = 3'd3;                  
localparam BURST_ONE_LINE_END = 3'd4;         
reg[2:0] burst_state = 3'd0;                  
reg[2:0] burst_state_next = 3'd0;             
reg[11:0] burst_line = 12'd0;
reg[11:0] remain_len = 12'd0;
reg vin_vs_mem_clk_d0 = 1'b0;
reg vin_vs_mem_clk_d1 = 1'b0;
reg frame_flag = 1'b0;
wire[11:0] rdusedw;

//
reg[7:0]	r_base_ch1_hsync_d0;
reg[7:0]	r_base_ch1_hsync_d1;
reg[15:0]	r_base_ch1_vsync_d0;
reg[15:0]	r_base_ch1_vsync_d1;
reg[15:0]	r_width_ch1_d0;
reg[15:0]	r_width_ch1_d1;

always@(posedge mem_clk)
begin
	r_base_ch1_hsync_d0 <= base_ch1_hsync;
	r_base_ch1_hsync_d1 <= r_base_ch1_hsync_d0;
	r_base_ch1_vsync_d0 <= base_ch1_vsync;
	r_base_ch1_vsync_d1 <= r_base_ch1_vsync_d0;
	r_width_ch1_d0 <= width_ch1;
	r_width_ch1_d1 <= r_width_ch1_d0;
end

fifo_4096_16d_64q fifo_4096_16d_64q_m0(
	.aclr(frame_flag),
	.data(vin_data),					
	.rdclk(mem_clk),
	.rdreq(wr_burst_data_req),
	.wrclk(vin_clk),
	.wrreq(vin_de),
	.q(wr_burst_data),
	.rdempty(),
	.rdusedw(rdusedw),
	.wrfull(),
	.wrusedw());

always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		wr_burst_addr <= 24'd0;
	else if(burst_state_next == BURST_ONE_LINE_START)
		wr_burst_addr <= {2'd0,burst_line[10:0],3'd0,r_base_ch1_hsync_d1};//24bit ddr addr
	else if(burst_state_next == BURST_END  && burst_state != BURST_END)
		wr_burst_addr <= wr_burst_addr + BURST_LEN[7:0];
	else
		wr_burst_addr <= wr_burst_addr;
end

always@(posedge mem_clk)
begin
	vin_vs_mem_clk_d0 <= vin_vs;
	vin_vs_mem_clk_d1 <= vin_vs_mem_clk_d0;
	frame_flag <= vin_vs_mem_clk_d0 && ~vin_vs_mem_clk_d1;
end

always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		burst_state <= BURST_IDLE;
	else if(frame_flag)
		burst_state <= BURST_IDLE;
	else
		burst_state <= burst_state_next;
end
always@(*)
begin
	case(burst_state)
		BURST_IDLE:
			if(rdusedw > BURST_LEN[7:0])
				burst_state_next <= BURST_ONE_LINE_START;
			else
				burst_state_next <= BURST_IDLE;
		BURST_ONE_LINE_START:
			burst_state_next <= BURSTING;
		BURSTING:
			if(burst_finish)
				burst_state_next <= BURST_END;
			else
				burst_state_next <= BURSTING;
		BURST_END:
			if(remain_len == 12'd0)
				burst_state_next <= BURST_ONE_LINE_END;
			else if(rdusedw >= BURST_LEN[7:0])// || (remain_len <= BURST_LEN && rdusedw == remain_len - 10'd1))//һ��ͻ������,��һ������һ��ͻ��
				burst_state_next <= BURSTING;
			else
				burst_state_next <= BURST_END;
		BURST_ONE_LINE_END:
			burst_state_next <= BURST_IDLE;
		default:
			burst_state_next <= BURST_IDLE;
	endcase
end


always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		burst_line <= 12'd0;
	else if(frame_flag)
		burst_line <= r_base_ch1_vsync_d1[11:0];
	else if(burst_state == BURST_ONE_LINE_END)
		burst_line <= burst_line + 12'd1;
	else
		burst_line <= burst_line;
end


always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		remain_len <= 12'd0;
	else if(burst_state_next == BURST_ONE_LINE_START)
		remain_len <= r_width_ch1_d1[11:0];
	else if(burst_state_next == BURST_END && burst_state != BURST_END)
		if(remain_len < BURST_LEN)
			remain_len <= 12'd0;
		else
			remain_len <= remain_len - BURST_LEN;	
	else
		remain_len <= remain_len;
end

always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		wr_burst_len <= 10'd0;
	else if(burst_state_next == BURSTING && burst_state != BURSTING)
		if(remain_len > BURST_LEN)
			wr_burst_len <= BURST_LEN;
		else
			wr_burst_len <= remain_len;
	else
		wr_burst_len <=  wr_burst_len;
end

always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		wr_burst_req <= 1'd0;
	else if(burst_state_next == BURSTING && burst_state != BURSTING)
		wr_burst_req <= 1'b1;
	else if(burst_finish  || wr_burst_data_req || burst_state == BURST_IDLE)
		wr_burst_req <= 1'b0;
	else
		wr_burst_req <= wr_burst_req;
end

endmodule 