// rtl/top.v - 4-tap FIR Filter
`timescale 1ns/1ps
module top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         in_valid,
    input  wire [31:0]  in_data,
    output reg          out_valid,
    output reg  [31:0]  out_data
);

  // FIR coefficients (16-bit fixed-point, scale 2^12)
  localparam signed [15:0] COEFF0 = 16'sd819;   // 0.2 * 4096
  localparam signed [15:0] COEFF1 = 16'sd1638;  // 0.4 * 4096
  localparam signed [15:0] COEFF2 = 16'sd2048;  // 0.5 * 4096
  localparam signed [15:0] COEFF3 = 16'sd1638;  // 0.4 * 4096

  // Circular buffer for last 4 samples
  reg signed [15:0] buffer [0:3];
  reg [1:0] buf_idx;
  
  // Pipeline registers
  reg in_valid_d;
  reg signed [15:0] in_data_d;
  
  // MAC engine
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
      in_data_d <= 16'sd0;
      acc <= 48'sd0;
      mac_stage <= 3'd0;
      out_valid <= 1'b0;
      out_data <= 32'h0;
    end else begin
      
      // === STAGE 1: Input sampling ===
      in_valid_d <= in_valid;
      in_data_d <= sample;
      
      if (in_valid) begin
        buffer[buf_idx] <= sample;
        buf_idx <= buf_idx + 2'd1;  // Auto-wraps at 4
      end
      
      // === STAGE 2: MAC operation ===
      out_valid <= 1'b0;  // Default
      
      if (in_valid_d && mac_stage < 4) begin
        // Multiply-accumulate pipeline
        reg [1:0] read_idx;
        reg signed [15:0] tap_data;
        reg signed [15:0] coeff;
        
        read_idx = buf_idx - 2'd1 - mac_stage[1:0];
        tap_data = buffer[read_idx];
        
        case (mac_stage[1:0])
          2'd0: coeff = COEFF0;
          2'd1: coeff = COEFF1;
          2'd2: coeff = COEFF2;
          2'd3: coeff = COEFF3;
        endcase
        
        acc <= acc + (tap_data * coeff);
        mac_stage <= mac_stage + 3'd1;
        
        if (mac_stage == 3'd3) begin
          // MAC complete - output scaled result
          out_valid <= 1'b1;
          out_data <= {16'h0, acc[27:12]};  // Scale down by 2^12
          acc <= 48'sd0;
          mac_stage <= 3'd0;
        end
        
      end else if (!in_valid_d) begin
        mac_stage <= 3'd0;
        acc <= 48'sd0;
      end
      
    end
  end

endmodule