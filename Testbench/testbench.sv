module testbench;
	logic clk,reset;
	logic [7:0] port_b_out;
	

	MCU MCU1(
		.clk(clk),
		.reset(reset),
		.port_b_out(port_b_out)
	);

	always #5 clk = ~clk;
	initial begin
		clk = 0; reset = 1;
		#10 reset = 0;
		#2200 $stop;
	end
endmodule
