`timescale 1ns / 1ps

module uart_tb_top;

    // Clock and Reset
    reg sys_clk;
    reg reset;

    // Transmit Side
    reg [7:0] tx_data_i;
    reg tx_wr_en;
    wire tx_full;
    wire tx_done;
    wire txd_o;

    // Receive Side
    reg rxd_i;
    wire [7:0] rx_data_o;
    wire rx_ready;
    wire rx_done;
    wire parity_error;
    wire frame_error;
    wire bclk;
    // Control
    reg parity_en;
    reg sticky_parity;
    reg eps;
    reg stop_bit;
    reg [1:0] wls;

    // Internal wire for loopback
   

    // Clock generation: 1MHz system clock (period = 1us)
    initial begin
        sys_clk = 0;
        forever #500 sys_clk = ~sys_clk; // 1 MHz clock
    end

    // Instantiate UART Top Module
    uart_top #(
        .DIVISOR(6),
        .DATA_WIDTH(8),
        .DEPTH(32),
        .ADDR_WIDTH(5)
    ) uut (
        .sys_clk(sys_clk),
        .reset(reset),
        .tx_data_i(tx_data_i),
        .tx_wr_en(tx_wr_en),
        .tx_full(tx_full),
        .tx_done(tx_done),
        .txd_o(txd_o),
        .baud_clock(bclk),
        .rxd_i(txd_o),  // loopback
        .rx_data_o(rx_data_o),
        .rx_ready(rx_ready),
        .rx_done(rx_done),
        .parity_error(parity_error),
        .frame_error(frame_error),

        .parity_en(parity_en),
        .sticky_parity(sticky_parity),
        .eps(eps),
        .stop_bit(stop_bit),
        .wls(wls)
    );

    // Test Sequence
    initial begin
        // Initial values
        reset = 1;
        tx_wr_en = 0;
        tx_data_i = 8'h00;
        parity_en = 1'b1;
        sticky_parity = 1'b0;
        eps = 1'b0;
        stop_bit = 1'b0;
        wls = 2'b11; // 8 bits

        repeat(2) @(posedge sys_clk);
        reset = 0;

        // Wait a bit after reset
        repeat(5) @(posedge bclk);

        // Transmit byte
        tx_data_i = 8'hA5;
        tx_wr_en = 1;
        @(posedge bclk);
        tx_data_i = 8'hA6;
        @(posedge bclk);
        tx_data_i = 8'hA7;
        @(posedge bclk);        
        tx_wr_en = 0;

        // Wait for transmission and reception to complete
       repeat(3) @(posedge rx_done);

      
       repeat(5) @(posedge bclk);
        $finish;
    end

endmodule
