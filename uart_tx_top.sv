
module uart_tx (
	input [7:0] tx_data_i, 
	input baud_clk, reset,
	input parity_en, sticky_parity, eps, stop_bit, Txhr_empty,
	input [1:0] wls,
	output reg tx_done, 
	output reg txd_o,
	output reg Txsr_empty,
	output reg Txhr_rd_en
);

reg [7:0] Tx_shift_reg;
enum bit[2:0]{idle = 3'b000, start = 3'b001, send = 3'b010, parity = 3'b011, stop = 3'b100} state;
reg [4:0] clk_count;
reg [4:0] clk_counter;
reg [2:0] bit_count;
reg [2:0] bit_counter;
reg parity_out;

always @(posedge baud_clk, posedge reset) begin
	if(reset) begin
		state <= idle;
		clk_counter <= 0;
		clk_count <= 15;
		bit_count <= 0;
		bit_counter <= 0;
		txd_o <= 1'b1;
		tx_done <= 0;
		Tx_shift_reg <= 0;
		Txsr_empty <= 1'b1;
		Txhr_rd_en <= 1'b0;
		parity_out <= 1'b0;
	end
	
	else begin
	
		case(state)
			
			idle: begin
				clk_count <= 15;
				bit_count <= 0;
				clk_counter <= 0;
				bit_counter <= 0;
				txd_o <= 1'b1;
				tx_done <= 1'b0;
				if(~Txhr_empty) begin
					Txhr_rd_en <= 1'b1;
					Txsr_empty <= 1'b0;
					state <= start;	
					txd_o <= 1'b0;
				end
				else begin
					state <= idle;
				end
			end
			
			start: begin
			    Tx_shift_reg <= tx_data_i;
			    Txhr_rd_en <= 1'b0;
				if(clk_counter < clk_count ) begin
					clk_counter <= clk_counter + 1;
					state <= start;
				end
				
				else begin	
					bit_count <= {1'b1,wls};					
					case({sticky_parity, eps})
                        2'b00: parity_out <= ~(^Tx_shift_reg);
                        2'b01: parity_out <= ^Tx_shift_reg;
                        2'b10: parity_out <= 1'b1;
                        2'b11: parity_out <= 1'b0;
                    endcase
                        
					txd_o <= Tx_shift_reg[0];
					Tx_shift_reg <= Tx_shift_reg >> 1;
					clk_counter <= 0;
					state <= send;
				end
			end
		
			send: begin
				if(bit_counter < bit_count) begin
					if(clk_counter < clk_count) begin
						clk_counter <= clk_counter + 1;
					end
					else begin
						bit_counter <= bit_counter + 1;
						txd_o <= Tx_shift_reg[0];
						Tx_shift_reg <= Tx_shift_reg >> 1;
						clk_counter <= 0;
					end
					state <= send;
				end
				else begin
					if(clk_counter < clk_count) begin
						clk_counter <= clk_counter + 1;
						state <= send;
					end
					else begin
						clk_counter <= 0;
						Txsr_empty <= 1'b1;
						bit_counter <= 0;
						if(parity_en) begin
							txd_o <= parity_out;
							state <= parity;
						end
						else begin
							txd_o <= 1'b1;
							clk_count <= (stop_bit == 1'b0 )? 5'd15 :(wls == 2'b00) ? 5'd23 : 5'd31;
							state <= stop;
						end
					end
				end
			end
				
			parity: begin
				if(clk_counter < clk_count) begin
					clk_counter <= clk_counter + 1;
					state <= parity;
				end
				else begin 
					clk_counter <= 0;
					txd_o <= 1'b1;
					clk_count <= (stop_bit == 1'b0 )? 5'd15 :(wls == 2'b00) ? 5'd23 : 5'd31;
					state <= stop;
				end
			end
			
			stop: begin
				if(clk_counter < clk_count) begin
					clk_counter <= clk_counter + 1;
					state <= stop;
				end
				else begin
				    clk_counter <= 0;
					state <= idle;
					tx_done <= 1'b1;
				end
			end		
		endcase	
	end
end
endmodule
