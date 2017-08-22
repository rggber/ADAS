fifo_4096_24	fifo_4096_24_inst (
	.aclr ( aclr_sig ),
	.data ( data_sig ),
	.rdclk ( rdclk_sig ),
	.rdreq ( rdreq_sig ),
	.wrclk ( wrclk_sig ),
	.wrreq ( wrreq_sig ),
	.q ( q_sig ),
	.rdempty ( rdempty_sig ),
	.rdusedw ( rdusedw_sig ),
	.wrfull ( wrfull_sig ),
	.wrusedw ( wrusedw_sig )
	);
