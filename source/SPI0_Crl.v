//---------------------------------------------------------------------------------------

module SPI0_Crl(
		
		//
		clock, reset_n,
		//
		MCU_SCK_i, MCU_MISO_o, MCU_MOSI_i, MCU_NSS_i,
		//
		base_ch0_hsync, base_ch0_vsync, width_ch0, 
		base_ch1_hsync, base_ch1_vsync, width_ch1, 
		base_ch2_hsync, base_ch2_vsync, width_ch2,
		chx_load_en, img_mode

);

//---------------------------------------------------------------------------------------

//
input								clock;
input								reset_n;

//
input								MCU_SCK_i;
output								MCU_MISO_o;
input								MCU_MOSI_i; 
input								MCU_NSS_i;

//
output		[7:0]					base_ch0_hsync;
output		[7:0]					base_ch1_hsync;
output		[7:0]					base_ch2_hsync;
output		[15:0]					base_ch0_vsync;
output		[15:0]					base_ch1_vsync;
output		[15:0]					base_ch2_vsync;
output		[15:0]					width_ch0;
output		[15:0]					width_ch1;
output		[15:0]					width_ch2;
output		[7:0]					chx_load_en;
output		[7:0]					img_mode;

//---------------------------------------------------------------------------------------

//							
reg			[7:0]					r_base_ch0_hsync;
reg			[7:0]					r_base_ch1_hsync;
reg			[7:0]					r_base_ch2_hsync;
reg			[15:0]					r_base_ch0_vsync;
reg			[15:0]					r_base_ch1_vsync;
reg			[15:0]					r_base_ch2_vsync;
reg			[15:0]					r_width_ch0;
reg			[15:0]					r_width_ch1;
reg			[15:0]					r_width_ch2;
reg			[7:0]					r_chx_load_en;
reg			[7:0]					r_img_mode;
//
reg			[2:0]					ST;
//
reg									sck_pedge;
reg									sck_nedge;
reg									sck_d0;
reg									sck_d1;
reg									nss_pedge;
reg									nss_nedge;
reg									nss_d0;
reg									nss_d1;
reg			[3:0]				    spi_cnt;
reg			[7:0]					spi_addr;
reg			[7:0]					spi_dat;		

//---------------------------------------------------------------------------------------

parameter							IDLE = 3'd0;
parameter							SPI0_BYTE1_START = 3'd1;
parameter							SPI0_BYTE1_TANSFER = 3'd2;
parameter							SPI0_BYTE1_END = 3'd3;
parameter							SPI0_BYTE2_START = 3'd4;
parameter							SPI0_BYTE2_TANSFER = 3'd5;
parameter							SPI0_BYTE2_END = 3'd6;

//---------------------------------------------------------------------------------------

assign base_ch0_hsync = r_base_ch0_hsync;
assign base_ch1_hsync = r_base_ch1_hsync;
assign base_ch2_hsync = r_base_ch2_hsync;
assign base_ch0_vsync = r_base_ch0_vsync;
assign base_ch1_vsync = r_base_ch1_vsync;
assign base_ch2_vsync = r_base_ch2_vsync;
assign width_ch0 = r_width_ch0;
assign width_ch1 = r_width_ch1;
assign width_ch2 = r_width_ch2;
assign chx_load_en = r_chx_load_en;
assign img_mode = r_img_mode;


//---------------------------------------------------------------------------------------

always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
				sck_d0 <= 1'b0;
				sck_d1 <= 1'b0;
				nss_d0 <= 1'b0;
				nss_d1 <= 1'b0;
				sck_pedge <= 1'b0;
				sck_nedge <= 1'b0;
				nss_pedge <= 1'b0;
				nss_nedge <= 1'b0;
			end
		else 
			begin
				sck_d0 <= MCU_SCK_i;
				sck_d1 <= sck_d0;
				sck_pedge <= sck_d0 && ~sck_d1;
				sck_nedge <= ~sck_d0 && sck_d1;
				nss_d0 <= MCU_NSS_i;
				nss_d1 <= nss_d0;
				nss_pedge <= nss_d0 && ~nss_d1;
				nss_nedge <= ~nss_d0 && nss_d1;
			end
	end

always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
				//
				spi_cnt <= 0;
				spi_addr <= 0;
				spi_dat <= 0;
				//
				ST <= IDLE;
			end
		else
			begin
				case(ST)
					IDLE : 
						if(nss_nedge)
							ST <= SPI0_BYTE1_START;
						else
							begin
								ST <= IDLE;
							end
					SPI0_BYTE1_START :
						begin
							ST <= SPI0_BYTE1_TANSFER;
							spi_cnt <= 0;
						end
					SPI0_BYTE1_TANSFER:
						begin
							if(spi_cnt < 8)
								begin
									if(sck_nedge)
										begin
											spi_cnt <= spi_cnt + 1;
											spi_addr <= {spi_addr[6:0], MCU_MOSI_i};
										end
								end
							else
								begin
									ST <= SPI0_BYTE1_END;
									spi_cnt <= 0;
								end
						end
					SPI0_BYTE1_END:
						begin
							ST <= SPI0_BYTE2_START;
						end
					SPI0_BYTE2_START :
						begin
							ST <= SPI0_BYTE2_TANSFER;
							spi_cnt <= 0;
						end
					SPI0_BYTE2_TANSFER:
						begin
							if(spi_cnt < 8)
								begin
									if(sck_nedge)
										begin
											spi_cnt <= spi_cnt + 1;
											spi_dat <= {spi_dat[6:0], MCU_MOSI_i};
										end
								end
							else
								begin
									ST <= SPI0_BYTE2_END;
								end
						end
					SPI0_BYTE2_END:
						begin
							if(nss_pedge)
								ST <= IDLE;
							else
								ST <= SPI0_BYTE2_END;
						end
					default:
						ST <= IDLE;
				endcase
			end
	end

always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
			    r_base_ch0_hsync <= 0;
				r_base_ch1_hsync <= 0; 
				r_base_ch2_hsync <= 0;
				r_base_ch0_vsync <= 0;
				r_base_ch1_vsync <= 0; 
				r_base_ch2_vsync <= 0;
				r_width_ch0 <= 0;
				r_width_ch1 <= 0;
				r_width_ch2 <= 0;
				r_chx_load_en <= 0;
				r_img_mode <= 0;
			end
		else if(nss_pedge)
			case(spi_addr)
				0 : r_img_mode <= spi_dat;
				1 : r_base_ch0_hsync <= spi_dat;
				2 : r_base_ch1_hsync <= spi_dat;
				3 :	r_base_ch2_hsync <= spi_dat;
				//4 : r_base_ch2_hsync <= spi_dat;
				5 : r_base_ch0_vsync[15:8] <= spi_dat;
				6 : r_base_ch0_vsync[7:0] <= spi_dat;
				7 :	r_base_ch1_vsync[15:8] <= spi_dat;
				8 : r_base_ch1_vsync[7:0] <= spi_dat;
				9 : r_width_ch0[15:8] <= spi_dat;
			   10 : r_width_ch0[7:0] <= spi_dat;
			   11 :	r_width_ch1[15:8] <= spi_dat;
			   12 : r_width_ch1[7:0] <= spi_dat;
			   13 :	r_base_ch2_vsync[15:8] <= spi_dat;
			   14 : r_base_ch2_vsync[7:0] <= spi_dat;
			   15 :	r_width_ch2[15:8] <= spi_dat;
			   16 : r_width_ch2[7:0] <= spi_dat;
			   17 : r_chx_load_en <= spi_dat;
			    default : 
					begin
					end
			endcase
	end	
//---------------------------------------------------------------------------------------

endmodule


