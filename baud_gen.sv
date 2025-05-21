module baud_gen #( parameter DIVISOR = 6
) (
	input sys_clk, reset,
	output reg baud_clk
);

integer counter;
always @(posedge sys_clk) begin
	if(reset) begin 
		counter <= 0;
		baud_clk <= 0;
	end
	else begin
		if(counter < DIVISOR/2) begin
			counter <= counter + 1;
		end
		else begin
			counter <= 0;
			baud_clk <= ~baud_clk;
		end
	end
end

endmodule
