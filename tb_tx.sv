`timescale 1ns/1ps

module uart_tx_tb;

  // DUT inputs
  reg         sys_clk;
  reg         reset;
  reg  [7:0]  tx_data_i;
  reg         parity_en, sticky_parity, eps, stop_bit;
  reg  [1:0]  wls;
  reg         Txhr_empty;

  // DUT outputs
  wire        tx_done;
  wire        txd_o;
  wire        Txsr_empty;
  wire        Txhr_rd_en;
  wire        baud_clk;

  // Instantiate baud generator
  baud_gen #(.DIVISOR(6)) baud_gen_inst (
    .sys_clk(sys_clk),
    .reset(reset),
    .baud_clk(baud_clk)
  );

  // Instantiate UART TX
  uart_tx uart_tx_inst (
    // inferred
    .tx_data_i(tx_data_i),
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

  // Clock generation
  always #5 sys_clk = ~sys_clk;  // 100 MHz

  // Task to send a byte and wait for tx_done
  task send_uart_byte(
    input [7:0] data,
    input pe, input sp, input e, input sb, input [1:0] wl
  );
  begin
    // Setup
    tx_data_i = data;
    parity_en = pe;
    sticky_parity = sp;
    eps = e;
    stop_bit = sb;
    wls = wl;

    Txhr_empty = 0;
    repeat(3) @(posedge baud_clk);  // Hold for 3 baud clocks
    Txhr_empty = 1;

    // Wait for tx_done
    wait(tx_done == 1);
    @(posedge baud_clk);
    $display("[%0t ns] Sent byte: %02h | parity_en=%b sticky=%b eps=%b stop_bit=%b wls=%b",
              $time, data, pe, sp, e, sb, wl);
  end
  endtask

  initial begin
    // Init
    sys_clk = 0;
    reset = 1;
    tx_data_i = 0;
    parity_en = 0;
    sticky_parity = 0;
    eps = 0;
    stop_bit = 0;
    wls = 2'b11;
    Txhr_empty = 1;

    #50 reset = 0;
    #100;

    // --- Basic case: 8-bit, no parity, 1 stop
    send_uart_byte(8'hA5, 0, 0, 0, 0, 2'b11);

    // --- Even parity, not sticky, 7-bit word, 1 stop
    send_uart_byte(8'h5A, 1, 0, 1, 0, 2'b10);

    // --- Odd parity, not sticky, 6-bit word, 1 stop
    send_uart_byte(8'h3C, 1, 0, 0, 0, 2'b01);

    // --- Sticky parity = 1, should force parity bit to 1 (regardless of data parity), 8-bit
    send_uart_byte(8'hFF, 1, 1, 0, 0, 2'b11);

    // --- Sticky parity = 1, eps = 1 ? parity should be forced to 0
    send_uart_byte(8'h00, 1, 1, 1, 0, 2'b00);

    // --- No parity, but 2 stop bits
    send_uart_byte(8'hC3, 0, 0, 0, 1, 2'b11);

    // --- Even parity, 2 stop bits, 7-bit
    send_uart_byte(8'h77, 1, 0, 1, 1, 2'b10);

    // --- 1.5 Stop Bits Test Case (5-bit word, stop_bit=1)
    send_uart_byte(8'h1F, 0, 0, 0, 1, 2'b00);

    #200;
    $display("UART TX Extended Testbench completed.");
    $finish;
  end

endmodule
