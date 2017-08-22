//---------------------------------------------------------------------------------------

// SKIP 2X1 

//---------------------------------------------------------------------------------------

module skip_2x1(

		//
		clock, reset_n,
		//
		vs_i, hs_i, de_i,
		//
		rgb_r_i, rgb_g_i, rgb_b_i,
		//
		vs_o, hs_o, de_o,
		//
		rgb_r_o, rgb_g_o, rgb_b_o,
		//
		image_mode_i
		
);

//---------------------------------------------------------------------------------------

input								clock;
input								reset_n;

input								vs_i;
input								hs_i;
input								de_i;
input[7:0]							rgb_r_i;
input[7:0]							rgb_g_i;
input[7:0]							rgb_b_i;

output								vs_o;
output								hs_o;
output								de_o;
output[7:0]							rgb_r_o;
output[7:0]							rgb_g_o;
output[7:0]							rgb_b_o;

input[7:0]							image_mode_i;

/////////////////////////////////////////////////////////////////////////////////////////

reg									r_de_d0;
reg									r_de_d1;
reg									r_hs_d0;
reg									r_hs_d1;
reg									r_vs_d0;
reg									r_vs_d1;
reg[7:0]							r_rgb_r_d0;
reg[7:0]							r_rgb_g_d0;
reg[7:0]							r_rgb_b_d0;
reg[7:0]							r_rgb_r_d1;
reg[7:0]							r_rgb_g_d1;
reg[7:0]							r_rgb_b_d1;
reg									r_pixel_valid;
reg[7:0]							r_image_mode;

//---------------------------------------------------------------------------------------

assign vs_o = r_vs_d0;
assign hs_o = r_hs_d0;
assign de_o = r_de_d0 & ( r_image_mode[0] ? r_pixel_valid : 1 );

assign rgb_r_o = r_rgb_r_d0;
assign rgb_g_o = r_rgb_g_d0;
assign rgb_b_o = r_rgb_b_d0;

//---------------------------------------------------------------------------------------

always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
				r_image_mode <= 0;					
			end
		else if(!r_vs_d0 && vs_i)
			begin
				r_image_mode <= image_mode_i;
			end
	end
	
always@(posedge clock)
	begin
		r_rgb_r_d0 <= rgb_r_i;
		r_rgb_g_d0 <= rgb_g_i;
		r_rgb_b_d0 <= rgb_b_i;
	end	
	
always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
				r_de_d0 <= 1'b0;					
				r_de_d1 <= 1'b0;					
			end
		else
			begin
				r_de_d0 <= de_i;
				r_de_d1 <= r_de_d0;
			end
	end

always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
				r_hs_d0 <= 1'b0;					
				r_hs_d1 <= 1'b0;					
			end
		else
			begin
				r_hs_d0 <= hs_i;
				r_hs_d1 <= r_hs_d0;
			end
	end
	
always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
				r_vs_d0 <= 1'b0;					
				r_vs_d1 <= 1'b0;					
			end
		else
			begin
				r_vs_d0 <= vs_i;
				r_vs_d1 <= r_vs_d0;
			end
	end
	
always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
				r_pixel_valid <= 1'b1;					
			end
		else if(r_de_d0 && !de_i)
			begin
				r_pixel_valid <= 1'b1;
			end
		else if(de_i)
			r_pixel_valid <= ~r_pixel_valid;
	end	
	
endmodule
