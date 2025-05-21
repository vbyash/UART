module uart_top #(
    parameter DIVISOR = 6,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input sys_clk,
    input reset,
    input [7:0] tx_data_i,
    input tx_wr_en,
    output tx_full,
    output tx_done,
    output txd_o,

    input rxd_i,
    output [7:0] rx_data_o,
    output rx_ready,
    output rx_done,
    output parity_error,
    output frame_error,
    output baud_clock,
    input parity_en,
    input sticky_parity,
    input eps,
    input stop_bit,
    input [1:0] wls
);


// Internal signals
wire baud_clk;
wire Txhr_empty;
wire Txhr_rd_en;
wire Txsr_empty;
wire [7:0] tx_fifo_dout;
wire [7:0] rx_data_out;
wire Rx_wr_en;
wire fifo_rx_empty;


assign baud_clock = baud_clk;

// Baud rate generator
baud_gen #(
    .DIVISOR(DIVISOR)
) baud_inst (
    .sys_clk(sys_clk),
    .reset(reset),
    .baud_clk(baud_clk)
);

// TX FIFO
fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) tx_fifo (
    .reset(reset),
    .clock(baud_clk),
    .data_in(tx_data_i),
    .push(tx_wr_en),
    .pop(Txhr_rd_en),
    .data_out(tx_fifo_dout),
    .fifo_full(tx_full),
    .fifo_empty(Txhr_empty)
);

// RX FIFO
fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)  rx_fifo (
    .reset(reset),
    .clock(baud_clk),
    .data_in(rx_data_out),
    .push(Rx_wr_en),
    .pop(rx_ready),
    .data_out(rx_data_o),
    .fifo_full(), // Not used
    .fifo_empty(fifo_rx_empty)
);

// UART TX
uart_tx uart_tx_inst (
    .tx_data_i(tx_fifo_dout),
    .baud_clk(baud_clk),
    .reset(reset),
    .parity_en(parity_en),
    .sticky_parity(sticky_parity),
    .eps(eps),
    .stop_bit(stop_bit),
    .Txhr_empty(Txhr_empty),
    .wls(wls),
    .tx_done(tx_done),
    .txd_o(txd_o),
    .Txsr_empty(Txsr_empty),
    .Txhr_rd_en(Txhr_rd_en)
);

// UART RX
uart_rx uart_rx_inst (
    .rxd_i(rxd_i),
    .baud_clk(baud_clk),
    .reset(reset),
    .pen(parity_en),
    .sticky_parity(sticky_parity),
    .eps(eps),
    .wls(wls),
    .rx_data_o(rx_data_out),
    .Rx_wr_en(Rx_wr_en),
    .rx_done(rx_done),
    .parity_error(parity_error),
    .frame_error(frame_error)
);

assign rx_ready = ~fifo_rx_empty;

endmodule
