/*
 * Copyright (c) 2026 Rom DuPlain (@4kbyte)
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_romd_uart_hello #(
  parameter integer CLOCK_HZ = 50_000_000,
  parameter integer BAUD_RATE = 115_200,
  parameter integer INTER_MESSAGE_DELAY_MS = 1_000
) (
  input  wire [7:0] ui_in,
  output wire [7:0] uo_out,
  input  wire [7:0] uio_in,
  output wire [7:0] uio_out,
  output wire [7:0] uio_oe,
  input  wire       ena,
  input  wire       clk,
  input  wire       rst_n
);

  localparam integer CLKS_PER_BIT = (CLOCK_HZ + (BAUD_RATE / 2)) / BAUD_RATE;
  localparam [63:0] INTER_MESSAGE_CLKS =
      (64'(CLOCK_HZ) * INTER_MESSAGE_DELAY_MS) / 1_000;
  localparam integer BAUD_COUNTER_WIDTH =
      CLKS_PER_BIT > 1 ? $clog2(CLKS_PER_BIT) : 1;
  localparam integer PAUSE_COUNTER_WIDTH =
      INTER_MESSAGE_CLKS > 1 ? $clog2(INTER_MESSAGE_CLKS) : 1;
  localparam [4:0] MESSAGE_LENGTH = 5'd21;

  reg [BAUD_COUNTER_WIDTH-1:0] baud_counter;
  reg [3:0] bit_index;
  reg [4:0] message_index;
  reg [PAUSE_COUNTER_WIDTH-1:0] pause_counter;
  reg [9:0] shift_register;
  reg transmitting;

  wire uart_tx = transmitting ? shift_register[0] : 1'b1;

  function automatic [7:0] message_byte;
    input [4:0] index;
    begin
      case (index)
        5'd0:  message_byte = 8'h48; // H
        5'd1:  message_byte = 8'h65; // e
        5'd2:  message_byte = 8'h6c; // l
        5'd3:  message_byte = 8'h6c; // l
        5'd4:  message_byte = 8'h6f; // o
        5'd5:  message_byte = 8'h2c; // ,
        5'd6:  message_byte = 8'h20; // space
        5'd7:  message_byte = 8'h54; // T
        5'd8:  message_byte = 8'h69; // i
        5'd9:  message_byte = 8'h6e; // n
        5'd10: message_byte = 8'h79; // y
        5'd11: message_byte = 8'h54; // T
        5'd12: message_byte = 8'h61; // a
        5'd13: message_byte = 8'h70; // p
        5'd14: message_byte = 8'h65; // e
        5'd15: message_byte = 8'h6f; // o
        5'd16: message_byte = 8'h75; // u
        5'd17: message_byte = 8'h74; // t
        5'd18: message_byte = 8'h21; // !
        5'd19: message_byte = 8'h0d; // carriage return
        5'd20: message_byte = 8'h0a; // line feed
        default: message_byte = 8'h00;
      endcase
    end
  endfunction

  always @(posedge clk) begin
    if (!rst_n) begin
      baud_counter <= '0;
      bit_index <= 4'd0;
      message_index <= 5'd0;
      pause_counter <= '0;
      shift_register <= 10'h3ff;
      transmitting <= 1'b0;
    end else if (transmitting) begin
      if (baud_counter == CLKS_PER_BIT - 1) begin
        baud_counter <= '0;
        if (bit_index == 4'd9) begin
          bit_index <= 4'd0;
          transmitting <= 1'b0;
        end else begin
          bit_index <= bit_index + 1'b1;
          shift_register <= {1'b1, shift_register[9:1]};
        end
      end else
        baud_counter <= baud_counter + 1'b1;
    end else if (message_index < MESSAGE_LENGTH) begin
      baud_counter <= '0;
      shift_register <= {1'b1, message_byte(message_index), 1'b0};
      message_index <= message_index + 1'b1;
      transmitting <= 1'b1;
    end else if (pause_counter == INTER_MESSAGE_CLKS - 1) begin
      message_index <= 5'd0;
      pause_counter <= '0;
    end else
      pause_counter <= pause_counter + 1'b1;
  end

  assign uo_out = {3'b000, uart_tx, 4'b0000};
  assign uio_out = 8'b00000000;
  assign uio_oe = 8'b00000000;

  wire _unused = &{ena, ui_in, uio_in, 1'b0};
endmodule

`default_nettype wire
