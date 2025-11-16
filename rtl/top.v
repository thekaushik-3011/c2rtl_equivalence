// rtl/top.v - 4-tap FIR Filter (WIDTH-SAFE)
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
  
  // Variables for MAC computation
  reg [1:0] read_idx;
  reg signed [15:0] tap_val;
  reg signed [15:0] coeff_val;
  reg signed [31:0] product;
  reg signed [47:0] next_acc;
  
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
      
      // Default outputs
      out_valid <= 1'b0;
      out_data <= 32'h0;
      
      // MAC state machine
      if (in_valid_d && mac_stage < 4) begin
        // Calculate buffer read index (circular)
        read_idx = buf_idx - 2'd1 - mac_stage[1:0];
        tap_val = buffer[read_idx];
        
        // Select coefficient
        case (mac_stage[1:0])
          2'd0: coeff_val = COEFF0;
          2'd1: coeff_val = COEFF1;
          2'd2: coeff_val = COEFF2;
          2'd3: coeff_val = COEFF3;
        endcase
        
        // Compute product (32-bit result from 16x16)
        product = tap_val * coeff_val;
        
        // Accumulate with proper width extension
        next_acc = acc + {{16{product[31]}}, product};  // Sign-extend to 48 bits
        acc <= next_acc;
        mac_stage <= mac_stage + 3'd1;
        
        // Output when MAC completes
        if (mac_stage == 3'd3) begin
          out_valid <= 1'b1;
          // Scale down by 2^12 and truncate to 16 bits
          out_data <= {16'h0, next_acc[27:12]};
          mac_stage <= 3'd0;
          acc <= 48'sd0;
        end
        
      end else if (!in_valid_d && mac_stage != 0) begin
        // Reset MAC if input stream stops
        mac_stage <= 3'd0;
        acc <= 48'sd0;
      end
      
      // Pipeline input valid signal
      in_valid_d <= in_valid;
    end
  end

endmodule