`default_nettype none
`timescale 1ns / 1ps

module tb #(
  parameter integer INTER_MESSAGE_DELAY_MS = 1_000
);

  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  reg clk;
  reg ena;
  reg rst_n;
  reg [7:0] ui_in;
  reg [7:0] uio_in;

  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
  wire uart_tx = uo_out[4];

`ifndef GL_TEST
  tt_um_romd_uart_hello #(
    .CLOCK_HZ              (50_000),
    .BAUD_RATE             (115),
    .INTER_MESSAGE_DELAY_MS(INTER_MESSAGE_DELAY_MS)
  ) user_project (
`else
  tt_um_romd_uart_hello user_project (
`endif
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)
  );

endmodule

`default_nettype wire
