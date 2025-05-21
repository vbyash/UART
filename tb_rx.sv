`timescale 1ns/1ps

module uart_rx_tb;

  reg sys_clk = 0;
  reg reset;
  reg rxd_i;
  wire baud_clk;

  reg [1:0] wls;
  reg pen;
  reg sticky_parity;
  reg eps;

  wire [7:0] rx_data_o;
  wire Rx_wr_en, rx_done;
  wire parity_error, frame_error;

  // 100 MHz system clock
  always #5 sys_clk = ~sys_clk;

  // Instantiate baud generator (16x oversampling)
  baud_gen #(.DIVISOR(6)) bg (
    .sys_clk(sys_clk),
    .reset(reset),
    .baud_clk(baud_clk)
  );

  // Instantiate UART RX
  uart_rx rx_inst (
    .rxd_i(rxd_i),
    .baud_clk(baud_clk),
    .reset(reset),
    .pen(pen),
    .sticky_parity(sticky_parity),
    .eps(eps),
    .wls(wls),
    .rx_data_o(rx_data_o),
    .Rx_wr_en(Rx_wr_en),
    .rx_done(rx_done),
    .parity_error(parity_error),
    .frame_error(frame_error)
  );

  // Function to extract relevant number of bits from data (LSB first)
  function [7:0] mask_bits(input [7:0] val, input integer width);
    integer j;
    begin
      mask_bits = 0;
      for (j = 0; j < width; j = j + 1)
        mask_bits[j] = val[j];
    end
  endfunction

  // Send a UART frame with optional parity and stop error
  task send_uart_frame(
    input [7:0] data,
    input [1:0] wlen,
    input parity_enable,
    input sticky,
    input even,
    input force_parity_error,
    input force_frame_error
  );
    integer i;
    integer nbits;
    reg parity_bit;
    reg [7:0] masked_data;
    begin
      // Set config
      wls = wlen;
      pen = parity_enable;
      sticky_parity = sticky;
      eps = even;

      // Determine number of bits
      nbits = 5 + wlen;
      masked_data = mask_bits(data, nbits);

      // Idle line
      rxd_i = 1;
      @(posedge baud_clk);

      // Start bit
      rxd_i = 0;
      repeat (16) @(posedge baud_clk);

      // Send data LSB first
      for (i = 0; i < nbits; i = i + 1) begin
        rxd_i = data[i];
        repeat (16) @(posedge baud_clk);
      end

      // Send parity bit if enabled
      if (parity_enable) begin
        case ({sticky, even})
          2'b00: parity_bit = ~(^masked_data); // Odd
          2'b01: parity_bit =  ^masked_data;   // Even
          2'b10: parity_bit = 1'b1;            // Sticky high
          2'b11: parity_bit = 1'b0;            // Sticky low
        endcase
        if (force_parity_error) parity_bit = ~parity_bit;
        rxd_i = parity_bit;
        repeat (16) @(posedge baud_clk);
      end

      // Stop bit (1), or 0 to simulate frame error
      rxd_i = force_frame_error ? 0 : 1;
      repeat (16) @(posedge baud_clk);

      rxd_i = 1; // Back to idle
    end
  endtask

  // Check and print results
  task check_result(input string label);
    begin
      wait(rx_done);
      $display("%s: rx_data = %h, parity_err = %b, frame_err = %b", label, rx_data_o, parity_error, frame_error);
      @(posedge baud_clk); // Small gap
    end
  endtask

  // Initial test sequence
  initial begin
    $display("UART RX Comprehensive Test");

    rxd_i = 1;
    reset = 1;
    #100;
    reset = 0;
    #100;

    @(posedge baud_clk);

    // 1. 8-bit no parity (8N1)
    send_uart_frame(8'hA5, 2'b11, 0, 0, 0, 0, 0);
    check_result("Test 1 - 8N1");

    // 2. 5-bit data no parity
    send_uart_frame(8'h15, 2'b00, 0, 0, 0, 0, 0);
    check_result("Test 2 - 5N1");

    // 3. 7-bit data with even parity
    send_uart_frame(8'h55, 2'b10, 1, 0, 1, 0, 0);
    check_result("Test 3 - 7E1");

    // 4. 6-bit data with odd parity
    send_uart_frame(8'h2A, 2'b01, 1, 0, 0, 0, 0);
    check_result("Test 4 - 6O1");

    // 5. Sticky high parity
    send_uart_frame(8'h33, 2'b11, 1, 1, 0, 0, 0);
    check_result("Test 5 - Sticky High");

    // 6. Sticky low parity
    send_uart_frame(8'h33, 2'b11, 1, 1, 1, 0, 0);
    check_result("Test 6 - Sticky Low");

    // 7. Parity error test (flip parity)
    send_uart_frame(8'hAA, 2'b11, 1, 0, 1, 1, 0);
    check_result("Test 7 - Parity Error");

    // 8. Frame error test (bad stop bit)
    send_uart_frame(8'hA5, 2'b11, 0, 0, 0, 0, 1);
    check_result("Test 8 - Frame Error");

    $display("All test cases executed.");
    #200;
    $finish;
  end

endmodule
