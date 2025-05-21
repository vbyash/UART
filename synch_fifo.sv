module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input reset,
    input clock,
    input [DATA_WIDTH-1:0] data_in,
    input push, pop,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg fifo_full,
    output reg fifo_empty
);

reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] rd_addr, wr_addr;
integer i;
integer counter;

// Memory write and data output (includes bypass logic)
always @(posedge clock, posedge reset) begin 
    if (reset) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            fifo_mem[i] <= 0;
        end
        data_out <= 0;
    end else begin
        if (push && pop && counter == 0) begin
            data_out <= data_in;
        end else if (pop && counter > 0) begin
            data_out <= fifo_mem[rd_addr];
        end
        // Write to FIFO memory
        if (push && counter < DEPTH) begin
            fifo_mem[wr_addr] <= data_in;
        end
    end
end


// Control logic
always @(posedge clock, posedge reset) begin
    if (reset) begin
        fifo_empty <= 1;
        fifo_full <= 0;
        wr_addr <= 0;
        rd_addr <= 0;
        counter <= 0;
    end else begin
        // FIFO status
        fifo_empty <= (counter == 0);
        fifo_full  <= (counter == DEPTH);

        case ({push, pop})
            2'b00: begin
                // No operation
            end

            2'b01: begin
                // Pop only
                if (counter > 0) begin
                    counter <= counter - 1;
                    rd_addr <= rd_addr + 1;
                end
            end

            2'b10: begin
                // Push only
                if (counter < DEPTH) begin
                    counter <= counter + 1;
                    wr_addr <= wr_addr + 1;
                end
            end

            2'b11: begin
                // Push and pop together
                // Counter stays same, but increment both pointers (wrap naturally)
                    rd_addr <= rd_addr + 1;
                    wr_addr <= wr_addr + 1;
            end
        endcase
    end
end

endmodule
