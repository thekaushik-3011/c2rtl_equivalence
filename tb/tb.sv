// tb/tb.sv
`timescale 1ns/1ps
module tb;
  parameter CLK_PERIOD = 10;
  reg clk;
  reg rst_n;
  reg in_valid;
  reg [31:0] in_data;
  wire out_valid;
  wire [31:0] out_data;

  // Instantiate DUT
  top dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_data(in_data),
    .out_valid(out_valid),
    .out_data(out_data)
  );

  // Clock
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  integer vec_fh, out_fh;
  reg [255:0] line;
  integer r;
  integer id;
  reg [31:0] vin;

  initial begin
    rst_n = 0;
    in_valid = 0;
    in_data = 32'h0;
    # (CLK_PERIOD * 4);
    rst_n = 1;

    vec_fh = $fopen("inputs/cosim_inputs.csv","r");
    if (vec_fh == 0) begin
      $display("Error: open inputs/cosim_inputs.csv");
      $finish;
    end
    out_fh = $fopen("results/sim_out.csv","w");
    $fwrite(out_fh, "cycle,id,in,exp,out\n");

    r = $fgets(line, vec_fh); // skip header
    integer cycle;
    cycle = 0;
    while (!$feof(vec_fh)) begin
      r = $fgets(line, vec_fh);
      if ($sscanf(line, "%d,%h", id, vin) >= 1) begin
        @(posedge clk);
        in_valid <= 1;
        in_data <= vin;
        @(posedge clk);
        // sample outputs
        $fwrite(out_fh, "%0d,%0d,0x%0h,0x%0h,0x%0h\n", cycle, id, vin, out_data, out_data);
        in_valid <= 0;
        in_data <= 32'h0;
        cycle = cycle + 1;
      end
    end

    $fclose(vec_fh);
    $fclose(out_fh);
    # (CLK_PERIOD * 10);
    $display("TB Done");
    $finish;
  end
endmodule
