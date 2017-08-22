//---------------------------------------------------------------------------------------

// BGBG.../GRGR...

//---------------------------------------------------------------------------------------

module demosaic(

		//
		clock, reset_n,
		//
		vs_i, hs_i, de_i,
		//
		bayer,
		//
		vs_o, hs_o, de_o,
		//
		rgb_r_o, rgb_g_o, rgb_b_o
 
);

//---------------------------------------------------------------------------------------

input								clock;
input								reset_n;

input								vs_i;
input								hs_i;
input								de_i;
input		[7:0]					bayer;

output								vs_o;
output								hs_o;
output								de_o;
output		[7:0]					rgb_r_o;
output		[7:0]					rgb_g_o;
output		[7:0]					rgb_b_o;

//---------------------------------------------------------------------------------------

reg									r_de_d0;
reg									r_de_d1;
reg									r_de_d2;
reg									r_hs_d0;
reg									r_hs_d1;
reg									r_hs_d2;
reg									r_vs_d0;
reg									r_vs_d1;
reg									r_vs_d2;

wire		[7:0]					s_bayer_n0_d0;
wire		[7:0]					s_bayer_n_d0;
wire		[7:0]					s_bayer_n1_d0;
reg			[7:0]					r_bayer_n0_d0;
reg			[7:0]					r_bayer_n_d0;
reg			[7:0]					r_bayer_n1_d0;
reg			[7:0]					r_bayer_n0_d1;
reg			[7:0]					r_bayer_n_d1;
reg			[7:0]					r_bayer_n1_d1;
reg			[7:0]					r_bayer_n0_d2;
reg			[7:0]					r_bayer_n_d2;
reg			[7:0]					r_bayer_n1_d2;

reg			[9:0]					r_rgb_r;
reg			[9:0]					r_rgb_g;
reg			[9:0]					r_rgb_b;

reg									line_odd_even;
reg									pixel_odd_even;

//---------------------------------------------------------------------------------------

buffer_3line buffer_3line_u0(

        .aclr(!r_vs_d0 && vs_i),
		.clken(de_i),
		.clock(clock),
		.shiftin(bayer),
		.shiftout(),
		.taps0x(s_bayer_n0_d0),
		.taps1x(s_bayer_n_d0),
		.taps2x(s_bayer_n1_d0)
	
);
/*
shift_vs_hs_de shift_vs_hs_de_u0(

		.clock(clock),
		.shiftin({vs_i, hs_i, de_i}),
		.shiftout(),
		.taps0x(),
		.taps1x({r_vs_d0, r_hs_d0, r_de_d0})
		
);
*/
//---------------------------------------------------------------------------------------

assign vs_o = vs_i;
assign hs_o = hs_i;
assign de_o = r_de_d2;

assign rgb_r_o = r_rgb_r;
assign rgb_g_o = r_rgb_g;
assign rgb_b_o = r_rgb_b;

//---------------------------------------------------------------------------------------

always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
				r_vs_d0 <= 1'b0;
				r_de_d0 <= 1'b0;
				r_hs_d0 <= 1'b0;
				r_vs_d1 <= 1'b0;
				r_de_d1 <= 1'b0;
				r_hs_d1 <= 1'b0;
				r_de_d2 <= 1'b0;
			end
		else
			begin
				r_vs_d0 <= vs_i;
				r_de_d0 <= de_i;
				r_hs_d0 <= hs_i;
				r_vs_d1 <= r_vs_d0;
				r_de_d1 <= r_de_d0;
				r_hs_d1 <= r_hs_d0;
				r_de_d2 <= r_de_d1;
			end
	end
	
always@(posedge clock)
	begin
		if(de_i)
			begin
				r_bayer_n0_d0 <= s_bayer_n0_d0;
				r_bayer_n_d0 <= s_bayer_n_d0;
				r_bayer_n1_d0 <= s_bayer_n1_d0;
				r_bayer_n0_d1 <= r_bayer_n0_d0;
				r_bayer_n_d1 <= r_bayer_n_d0;
				r_bayer_n1_d1 <= r_bayer_n1_d0;
				r_bayer_n0_d2 <= r_bayer_n0_d1;
				r_bayer_n_d2 <= r_bayer_n_d1;
				r_bayer_n1_d2 <= r_bayer_n1_d1;
			end	
	end
	
always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			line_odd_even <= 1'b0;			// even, line 0
		else if(!r_vs_d1 && r_vs_d0)
			line_odd_even <= 1'b0;
		else if(r_de_d0 && !de_i)
			line_odd_even <= ~line_odd_even;
		else
			line_odd_even <= line_odd_even;
	end
	
always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			pixel_odd_even <= 1'b0;			// even, pixel 0
		else if(!r_hs_d1 && r_hs_d0)
			pixel_odd_even <= 1'b0;
		else if(r_de_d1)
			pixel_odd_even <= ~pixel_odd_even;
	end	
	
always@(posedge clock)
	begin
		if(line_odd_even == 1'b0)
			begin
				if(pixel_odd_even == 1'b0)
					begin
						r_rgb_r <= (r_bayer_n0_d0 + r_bayer_n1_d0 + r_bayer_n1_d2 + r_bayer_n0_d2) >> 2;
						r_rgb_g <= (r_bayer_n0_d1 + r_bayer_n1_d1 + r_bayer_n_d0 + r_bayer_n_d2) >> 2;
						r_rgb_b <= r_bayer_n_d1;
					end
				else
					begin
						r_rgb_r <= (r_bayer_n0_d1 + r_bayer_n1_d1) >> 1;
						r_rgb_g <= r_bayer_n_d1;
						r_rgb_b <= (r_bayer_n_d0 + r_bayer_n_d2) >> 1;
					end
			end
		else
			begin
				if(pixel_odd_even == 1'b0)
					begin
						r_rgb_r <= (r_bayer_n_d0 + r_bayer_n_d2) >> 1;
						r_rgb_g <= r_bayer_n_d1;
						r_rgb_b <= (r_bayer_n0_d1 + r_bayer_n1_d1) >> 1;
					end
				else
					begin
						r_rgb_r <= r_bayer_n_d1;
						r_rgb_g <= (r_bayer_n0_d1 + r_bayer_n1_d1 + r_bayer_n_d0 + r_bayer_n_d2) >> 2;
						r_rgb_b <= (r_bayer_n0_d0 + r_bayer_n1_d0 + r_bayer_n1_d2 + r_bayer_n0_d2) >> 2;
					end
			end
	end

endmodule