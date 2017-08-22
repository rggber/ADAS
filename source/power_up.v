//---------------------------------------------------------------------------------------

module power_up(
		
		//clock,reset
		clock, reset_n,
		//
		en_cis1v5, en_cisa3v0, en_cis2v8, cis_pwdn, cis_rst,
		//
		cis_i2c_standby

);

//---------------------------------------------------------------------------------------

//
input								clock;
input								reset_n;

//
output								en_cis1v5;
output								en_cis2v8;
output								en_cisa3v0;
output								cis_pwdn;
output								cis_rst;

//
output								cis_i2c_standby;

//---------------------------------------------------------------------------------------

//							
reg									r_en_cis1v5;
reg									r_en_cis2v8;
reg									r_en_cisa3v0;
reg									r_cis_pwdn;
reg									r_cis_rst;

//
reg									r_cis_i2c_standby;

//
reg		[20:0]						cnt;

//---------------------------------------------------------------------------------------

parameter		[20:0]				delay_tpll = 25000;
parameter		[20:0]				delay_t0 = 25000;
parameter		[20:0]				delay_t1 = 25000;
parameter		[20:0]				delay_t2 = 250000;
parameter		[20:0]				delay_t3 = 50000;
parameter		[20:0]				delay_t4 = 1000000;

//---------------------------------------------------------------------------------------

assign		en_cis2v8 = r_en_cis2v8;
assign		en_cisa3v0 = r_en_cisa3v0;
assign		en_cis1v5 = r_en_cis1v5;
assign		cis_pwdn = r_cis_pwdn;
assign		cis_rst = r_cis_rst;
assign		cis_i2c_standby = r_cis_i2c_standby;

//---------------------------------------------------------------------------------------

always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			cnt <= 0;
		else if( cnt > (delay_t0 + delay_t1 + delay_t2 + delay_t3 + delay_t4 + delay_tpll) )
			cnt <= cnt;
		else
			cnt <= cnt + 1'b1;
	end

always@(posedge clock or negedge reset_n)
	begin
		if(!reset_n)
			begin
				r_en_cis2v8 <= 1'b0;
				r_en_cisa3v0 <= 1'b0;
				r_en_cis1v5 <= 1'b0;
				r_cis_pwdn <= 1'b1;
				r_cis_rst <= 1'b0;
				r_cis_i2c_standby <= 1'b0;
			end
		else if( cnt == delay_tpll )
			r_en_cis2v8 <= 1'b1;
		else if( cnt == (delay_t0 + delay_tpll) )
			r_en_cisa3v0 <= 1'b1;
		else if( cnt == (delay_t0 + delay_t1 + delay_tpll) )
			r_en_cis1v5 <= 1'b1;	
		else if( cnt == (delay_t0 + delay_t1 + delay_t2 + delay_tpll) )
			r_cis_pwdn <= 1'b0;
		else if( cnt == (delay_t0 + delay_t1 + delay_t2 + delay_t3 + delay_tpll) )
			r_cis_rst <= 1'b1;
		else if( cnt == (delay_t0 + delay_t1 + delay_t2 + delay_t3 + delay_t4 + delay_tpll) )
			r_cis_i2c_standby <= 1'b1;
		else
			begin
				r_en_cis2v8 <= r_en_cis2v8;
				r_en_cisa3v0 <= r_en_cisa3v0;
				r_en_cis1v5 <= r_en_cis1v5;
				r_cis_pwdn <= r_cis_pwdn;
				r_cis_rst <= r_cis_rst;
				r_cis_i2c_standby <= r_cis_i2c_standby;
			end
	end
	
//---------------------------------------------------------------------------------------

endmodule


