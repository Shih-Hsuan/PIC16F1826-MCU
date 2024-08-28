module single_port_ram_128x8(
	input [7:0]data,
	input [6:0]addr,
	input ram_en,
	input clk,
	output logic [7:0] q
);
	// Declare the RAM variable
	//reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	logic [7:0] ram[127:0];

	always_ff @(posedge clk)
	begin
		// Write
		if (ram_en)
			ram[addr] <= data;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  

	assign q = ram[addr];
endmodule