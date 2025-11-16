// rtl/top.v - 4-tap FIR Filter (ACTUALLY FIXED)
`timescale 1ns/1ps
module top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         in_valid,
    input  wire [31:0]  in_data,
    output reg          out_valid,
    output reg  [31:0]  out_data
);

  localparam signed [15:0] COEFF0 = 16'sd819;
  localparam signed [15:0] COEFF1 = 16'sd1638;
  localparam signed [15:0] COEFF2 = 16'sd2048;
  localparam signed [15:0] COEFF3 = 16'sd1638;

  reg signed [15:0] buffer [0:3];
  reg [1:0] buf_idx;
  reg in_valid_d;
  reg signed [47:0] acc;
  reg [2:0] mac_stage;
  
  wire signed [15:0] sample;
  assign sample = in_data[15:0];
  
  integer i;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 4; i = i + 1) buffer[i] <= 16'sd0;
      buf_idx <= 2'd0;
      in_valid_d <= 1'b0;
      acc <= 48'sd0;
      mac_stage <= 3'd0;
      out_valid <= 1'b0;
      out_data <= 32'h0;
    end else begin
      
      // Input sampling
      if (in_valid) begin
        buffer[buf_idx] <= sample;
        buf_idx <= buf_idx + 2'd1;
      end
      
      // Default output
      out_valid <= 1'b0;
      out_data <= 32'h0;
      
      // MAC state machine
      if (in_valid_d && mac_stage < 4) begin
        reg [1:0] idx;
        reg signed [15:0] tap;
        reg signed [15:0] c;
        reg signed [31:0] prod;
        
        idx = buf_idx - 2'd1 - mac_stage[1:0];
        tap = buffer[idx];
        
        case (mac_stage[1:0])
          2'd0: c = COEFF0;
          2'd1: c = COEFF1;
          2'd2: c = COEFF2;
          2'd3: c = COEFF3;
        endcase
        
        prod = tap * c;
        acc <= acc + prod;
        mac_stage <= mac_stage + 3'd1;
        
        // Output when done
        if (mac_stage == 3'd3) begin
          out_valid <= 1'b1;
          out_data <= {16'h0, (acc + prod) >>> 12};  // Include current multiply!
          mac_stage <= 3'd0;
          acc <= 48'sd0;
        end
        
      end else if (!in_valid_d && mac_stage != 0) begin
        mac_stage <= 3'd0;
        acc <= 48'sd0;
      end
      
      in_valid_d <= in_valid;
    end
  end

endmodule