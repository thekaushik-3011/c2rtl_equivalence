// rtl/top.v
`timescale 1ns/1ps
module top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         in_valid,
    input  wire [31:0]  in_data,
    output reg          out_valid,
    output reg  [31:0]  out_data
);

  reg [31:0] sum;
  reg in_valid_d;       // pipeline register to reflect 1-cycle latency
  reg [31:0] in_data_d;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum <= 32'h0;
      in_valid_d <= 1'b0;
      in_data_d <= 32'h0;
      out_valid <= 1'b0;
      out_data <= 32'h0;
    end else begin
      // sample and pipeline input
      in_valid_d <= in_valid;
      in_data_d <= in_data;

      if (in_valid) begin
        sum <= sum + in_data; // wrap-around modulo 2^32 (Verilog default)
      end

      // output one-cycle-later behavior
      out_valid <= in_valid_d;
      if (in_valid_d) begin
        out_data <= sum; // note: sum was updated in same cycle as sampled input; pipeline chosen so golden must match
      end else begin
        out_data <= 32'h0;
      end
    end
  end

endmodule
