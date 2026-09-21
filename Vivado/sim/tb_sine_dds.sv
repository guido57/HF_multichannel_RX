`timescale 1ns/1ps
module tb_sine_dds;
  localparam int CLK_HZ = 100_000_000;
  localparam int TONE_HZ = 1_000;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic signed [15:0] sine_out;
  logic signed [15:0] cosine_out;
  logic [31:0] phase_out;

  sine_dds #(.CLK_HZ(CLK_HZ), .TONE_HZ(TONE_HZ)) dut (.*);
  always #5 clk = ~clk; // 100 MHz

  initial begin
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    // 1.1 ms captures more than one 1 kHz period.
    repeat (1100_000) @(posedge clk);
    $display("Completed 1.1 ms sine DDS simulation.");
    $finish;
  end
endmodule
