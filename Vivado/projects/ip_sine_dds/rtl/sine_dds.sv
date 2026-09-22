// 1 kHz direct-digital synthesizer.  The ROM has one full 256-sample period.
module sine_dds #(
  parameter int CLK_HZ = 100_000_000,
  parameter int TONE_HZ = 1_000
) (
  input  logic               clk,
  input  logic               rst_n,
  output logic signed [15:0] sine_out,
  output logic signed [15:0] cosine_out,
  output logic        [31:0] phase_out
);
  // round(2^32 * TONE_HZ / CLK_HZ); 42950 at the default parameters.
  localparam logic [31:0] PHASE_INC =
      (64'd4_294_967_296 * TONE_HZ + (CLK_HZ / 2)) / CLK_HZ;
  logic [31:0] phase_acc;
  logic [15:0] sine_rom [0:255];

  initial $readmemh("sine_lut.mem", sine_rom);

  always_ff @(posedge clk) begin
    if (!rst_n)
      phase_acc <= '0;
    else
      phase_acc <= phase_acc + PHASE_INC;
  end

  // The eight MSBs address a complete cycle; output is signed two's complement.
  always_comb begin
    sine_out = sine_rom[phase_acc[31:24]];
    // cos(theta) = sin(theta + 90 degrees); 64 LUT addresses = one quarter turn.
    cosine_out = sine_rom[phase_acc[31:24] + 8'd64];
    phase_out = phase_acc;
  end
endmodule
