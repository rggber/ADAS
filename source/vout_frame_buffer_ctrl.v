module vout_frame_buffer_ctrl#(
	parameter MEM_DATA_BITS = 64
)(
	input rst_n,                                  
	input vout_clk,                                
	input vout_vs,                                 
	input vout_rd_req,                             
	output[15:0] vout_data,                       
	input[11:0] vout_width,                        
	input[11:0] vout_height,                       
                                                   
	input mem_clk,                                
	output reg rd_burst_req,                       
	output reg[9:0] rd_burst_len,                  
	output reg[23:0] rd_burst_addr,                
	input rd_burst_data_valid,                     
	input[MEM_DATA_BITS - 1:0] rd_burst_data,      
	input burst_finish                            
);                                                 
localparam BURST_LEN = 10'd32;                    
localparam BURST_IDLE = 3'd0;                      
localparam BURST_ONE_LINE_START = 3'd1;            
localparam BURSTING = 3'd2;                        
localparam BURST_END = 3'd3;                       
localparam BURST_ONE_LINE_END = 3'd4;              
reg[2:0] burst_state = 3'd0;                       
reg[2:0] burst_state_next = 3'd0;                  
reg[11:0] burst_line = 12'd0;                     
reg frame_flag;
reg vout_vs_mem_clk_d0;
reg vout_vs_mem_clk_d1;
reg[10:0] remain_len;
wire[11:0] wrusedw;
fifo_1024_64d_16q fifo_1024_64d_16q_m0(
	.aclr(frame_flag),
	.data(rd_burst_data),
	.rdclk(vout_clk),
	.rdreq(vout_rd_req),
	.wrclk(mem_clk),
	.wrreq(rd_burst_data_valid),
	.q(vout_data),
	.rdempty(),
	.rdusedw(),
	.wrfull(),
	.wrusedw(wrusedw));
	

always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		rd_burst_addr <= 24'd0;
	else if(burst_state_next == BURST_ONE_LINE_START)
		rd_burst_addr <= {2'd0,burst_line[10:0],11'd0};//24bit ddr addr
	else if(burst_state_next == BURST_END && burst_state != BURST_END)
		rd_burst_addr <= rd_burst_addr + {15'd0,BURST_LEN[8:0]};
	else
		rd_burst_addr <= rd_burst_addr;
end	

/////////////////////////////////////////////////////

always@(posedge mem_clk)
begin
	vout_vs_mem_clk_d0 <= vout_vs;
	vout_vs_mem_clk_d1 <= vout_vs_mem_clk_d0;
	frame_flag <= vout_vs_mem_clk_d0 && ~vout_vs_mem_clk_d1;
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
			if(wrusedw < 512 - BURST_LEN[7:0])
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
			if(remain_len == 11'd0)
				burst_state_next <= BURST_ONE_LINE_END;
			else if(wrusedw < 512 - BURST_LEN[7:0])
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
		burst_line <= 12'd0;
	else if(burst_state_next == BURST_ONE_LINE_END && burst_state == BURST_END)
		burst_line <= burst_line + 12'd1;
	else
		burst_line <= burst_line;
end



always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		remain_len <= 11'd0;
	else if(burst_state_next == BURST_ONE_LINE_START)
		remain_len <= vout_width[10:0];
	else if(burst_state_next == BURST_END && burst_state != BURST_END)
		if(remain_len < BURST_LEN)
			remain_len <= 11'd0;
		else
			remain_len <= remain_len - BURST_LEN;	
	else
		remain_len <= remain_len;
end


always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		rd_burst_len <= 10'd0;
	else if(burst_state_next == BURSTING && burst_state != BURSTING)
		if(remain_len > BURST_LEN)
			rd_burst_len <= BURST_LEN;
		else
			rd_burst_len <= remain_len;
	else
		rd_burst_len <=  rd_burst_len;
end


always@(posedge mem_clk or negedge rst_n)
begin
	if(!rst_n)
		rd_burst_req <= 1'd0;
	else if(burst_state_next == BURSTING && burst_state != BURSTING)
		rd_burst_req <= 1'b1;
	else if(burst_finish || burst_state == BURST_IDLE || rd_burst_data_valid)
		rd_burst_req <= 1'b0;
	else
		rd_burst_req <= rd_burst_req; 
end

endmodule 