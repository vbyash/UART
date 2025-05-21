module uart_rx(
	input rxd_i,
	input baud_clk, reset,
	input pen, sticky_parity, eps,
	input [1:0] wls,
	output reg [7:0] rx_data_o,
	output reg Rx_wr_en, rx_done,
	output reg parity_error, frame_error
);

reg [7:0] rx_reg;
reg [2:0] bit_count;
reg [2:0] bit_counter;
reg [3:0] clk_count;
reg [3:0] clk_counter;
enum bit[2:0]{idle = 3'b000, start = 3'b001, collect = 3'b010, parity = 3'b011, stop = 3'b100} state;
reg rx_parity;

always @(posedge baud_clk, posedge reset) begin

	if(reset) begin
		state <= idle;
		rx_reg <= 0;
		bit_count <= 0;
		bit_counter <= 0;
		clk_count <= 0;
		clk_counter <= 0;
		Rx_wr_en <= 0;
		rx_data_o <= 0;
		parity_error <= 0;
		frame_error <= 0;
		rx_done <= 0;
		rx_parity <= 0;
	end

	else begin
		
		case(state)
		
			idle: begin
				if(~rxd_i) begin
					state <= start;
					clk_counter <= clk_counter + 1;
				end	
				else begin
					bit_count <= 0;
					bit_counter <= 0;
					clk_count <= 15;
					clk_counter <= 0;
					rx_data_o <= 0;
					parity_error <= 0;
					frame_error <= 0;
					rx_done <= 0;
					rx_reg <= 0;
					Rx_wr_en <= 1'b0;
				end
			end
			
			start: begin
				
				if(clk_counter < clk_count) begin
					clk_counter <= clk_counter + 1;
					if(clk_counter == 4'd7) begin
						if(rxd_i) begin
							state <= idle;
						end
					end
				end				
				else begin
					bit_count <= {1'b1, wls};
					clk_counter <= 0;
					state <= collect;			
				end		
			end
			
			collect: begin
				if(bit_counter < bit_count) begin
					if(clk_counter < clk_count) begin
						clk_counter <= clk_counter + 1;
						if(clk_counter == 4'd7) begin
							case(wls)
								2'b00: rx_reg <= {3'b000, rxd_i, rx_reg[4:1]}; 
								2'b01: rx_reg <= {2'b00, rxd_i, rx_reg[5:1]}; 
								2'b10: rx_reg <= {1'b0, rxd_i, rx_reg[6:1]}; 
								2'b11: rx_reg <= {rxd_i, rx_reg[7:1]}; 
							endcase
						end
					
					end
					else begin
						clk_counter <= 0;
						bit_counter <= bit_counter + 1;
					end
				end
				else begin
					if(clk_counter < clk_count) begin
						clk_counter <= clk_counter + 1;
						if(clk_counter == 4'd7) begin
							case(wls)
								2'b00: rx_reg <= {3'b000, rxd_i, rx_reg[4:1]}; 
								2'b01: rx_reg <= {2'b00, rxd_i, rx_reg[5:1]}; 
								2'b10: rx_reg <= {1'b0, rxd_i, rx_reg[6:1]}; 
								2'b11: rx_reg <= {rxd_i, rx_reg[7:1]}; 
							endcase
						end
					end
					else begin
						clk_counter <= 0;
						bit_counter <= 0;
						rx_data_o <= rx_reg;
						if(pen) begin
							rx_parity <= ^rx_reg;
							state <= parity;
						end 
						else begin
							state <= stop;
						end
					end
				end		
			end
			
			parity: begin
				if(clk_counter < clk_count) begin
					clk_counter <= clk_counter + 1;
					if(clk_counter == 4'd7) begin 
						case({sticky_parity, eps})
							2'b00: parity_error <= ~^{rxd_i, rx_reg}; 
							2'b01: parity_error <= ^{rxd_i, rx_reg}; 
							2'b10: parity_error <= ~rxd_i; 
							2'b11: parity_error <= rxd_i; 
						endcase
					end
				end
				
				else begin
					clk_counter <= 0;
					state <= stop;
				end 
			end
			
			stop: begin
				if(clk_counter < clk_count) begin
					clk_counter <= clk_counter + 1;
					if(clk_counter == 4'd7) begin
						frame_error <= ~rxd_i;
					end
				end
				else begin
					Rx_wr_en <= ~parity_error;
					rx_done <= 1'b1;
					state <= idle;
					clk_counter <= 0;
				end
			end
		endcase
	end
end 

endmodule