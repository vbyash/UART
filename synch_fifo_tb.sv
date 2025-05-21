`timescale 1ns / 1ps

module fifo_tb;

parameter DATA_WIDTH = 8;
parameter DEPTH      = 32;
parameter ADDR_WIDTH = 5;

reg reset;
reg clock;
reg [DATA_WIDTH-1:0] data_in;
reg push, pop;
wire [DATA_WIDTH-1:0] data_out;
wire fifo_full, fifo_empty;

// Instantiate the fifo
fifo #(
	.DATA_WIDTH(DATA_WIDTH),
	.DEPTH(DEPTH),
	.ADDR_WIDTH(ADDR_WIDTH)
) uut (
	.reset(reset),
	.clock(clock),
	.data_in(data_in),
	.push(push),
	.pop(pop),
	.data_out(data_out),
	.fifo_full(fifo_full),
	.fifo_empty(fifo_empty)
);

// Clock generation
initial begin
	clock = 0;
	forever #5 clock = ~clock;  // 10ns period clock
end

integer i;

initial begin
	// Initialize signals
	reset = 1; push = 0; pop = 0; data_in = 0;
	#20;
	reset = 0;

	// Check empty after reset
	#10;
	if (!fifo_empty) $display("ERROR: FIFO should be empty after reset");
	if (fifo_full) $display("ERROR: FIFO should NOT be full after reset");

	// Push data until full
	for (i = 0; i < DEPTH; i = i + 1) begin
		push = 1;
		pop = 0;
		data_in = i + 1;
		#10;
		if (fifo_full && i != DEPTH-1) $display("ERROR: FIFO full early at count %0d", i);
	end

	// Try to push when full (should not write or increase count)
	push = 1; pop = 0; data_in = 8'hAA;
	#10;
	if (!fifo_full) $display("ERROR: FIFO should be full");
	
	// Pop all data and check order
	for (i = 0; i < DEPTH; i = i + 1) begin
		push = 0;
		pop = 1;
		#10;
		if (data_out != i + 1) 
			$display("ERROR: data_out mismatch at pop %0d, got %0h expected %0h", i, data_out, i + 1);
	end

	// Check empty again
	push = 0; pop = 0;
	#10;
	if (!fifo_empty) $display("ERROR: FIFO should be empty after all pops");

	// Push and pop at same time multiple cycles
	for (i = 0; i < 20; i = i + 1) begin
		push = 1;
		pop = 1;
		data_in = i + 100;
		#10;
	end

	// Push some elements, then pop some elements to test wrap-around
	for (i = 0; i < DEPTH/2; i = i + 1) begin
		push = 1; pop = 0; data_in = i + 50;
		#10;
	end

	for (i = 0; i < DEPTH/4; i = i + 1) begin
		push = 0; pop = 1;
		#10;
	end

	// Push again to test wrap-around of pointers
	for (i = 0; i < DEPTH/2; i = i + 1) begin
		push = 1; pop = 0; data_in = i + 150;
		#10;
	end

	push = 0; pop = 1;
	#150;

	//------------------------------------------
	// NEW TEST CASE:
	// Fill FIFO, then push+pop together, then pop
	//------------------------------------------
	$display("=== New test case: push+pop after full ===");

	// Reset
	reset = 1; #10; reset = 0;
	push = 0; pop = 0; data_in = 0; #20;

	// Fill FIFO
	for (i = 0; i < DEPTH - 1; i = i + 1) begin
		push = 1; pop = 0; data_in = i + 10; #10;
	end
	push = 1; pop = 1; data_in = DEPTH  + 9; #10;
	//if (!fifo_full) $display("ERROR: FIFO should be full");

	// push and pop together
	push = 1; pop = 1; data_in = 8'hEE; #10;
	$display("Push+Pop data: wrote 0xEE, got 0x%0h", data_out);

	// Now only pops, expect [11, 12, ..., 41, EE]
	push = 0;
	for (i = 1; i < DEPTH; i = i + 1) begin
		pop = 1; #10;
		$display("Popped: 0x%0h", data_out);
	end
    #10;
	pop = 0; #10;

	$display("Testbench finished.");
	$stop;
end

endmodule
