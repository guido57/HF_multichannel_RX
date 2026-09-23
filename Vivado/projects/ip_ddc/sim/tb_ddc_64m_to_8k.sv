`timescale 1ns/1ps

// End-to-end frequency test without an FFT. A LUT RF source produces the
// first two K1ABC offsets; complex phase rotation measures the DDC output.
module tb_ddc_64m_to_8k;
    localparam logic [47:0] RF_BASE_STEP = 48'd61902504643789;
    localparam logic [47:0] TONE_STEP = 48'd27487791;
    localparam integer SAMPLES_PER_TEST_TONE = 10_240_000; // one 160 ms FT8 symbol
    localparam real TWO_PI = 6.2831853071795864769;

    logic clk128 = 1'b0;
    logic signed [13:0] sample_in = '0;
    logic sample_valid = 1'b0;
    logic [24:0] vfo_hz = 25'd14075000;
    logic signed [23:0] i_out;
    logic signed [23:0] q_out;
    logic output_valid;
    logic signed [15:0] sine_lut [0:255];
    logic [47:0] rf_phase = '0;
    logic [2:0] source_tone = 3;
    integer source_sample_count = 0;
    integer observed_tone = -1;
    integer settle_count = 0;
    integer measure_count = 0;
    real previous_i = 0.0;
    real previous_q = 0.0;
    real phase_sum = 0.0;
    real delta_phase;
    real measured_hz;
    real expected_hz;

    initial $readmemh("sine_lut.mem", sine_lut);
    always #3.90625 clk128 = ~clk128;

    ddc_64m_to_8k dut (
        .clk128, .sample_in, .sample_valid, .vfo_hz,
        .i_out, .q_out, .output_valid
    );

    // Produce one real sample every two clk128 cycles: 64 MS/s.
    always @(posedge clk128) begin
        sample_valid <= ~sample_valid;
        if (!sample_valid) begin
            sample_in <= sine_lut[rf_phase[47:40]] >>> 2;
            rf_phase <= rf_phase + RF_BASE_STEP + source_tone * TONE_STEP;
            source_sample_count <= source_sample_count + 1;
            if (source_sample_count == SAMPLES_PER_TEST_TONE-1) begin
                source_tone <= 1;
                source_sample_count <= 0;
            end
        end
    end

    always @(posedge clk128) begin
        if (output_valid) begin
            if (observed_tone != source_tone) begin
                observed_tone = source_tone;
                settle_count = 0;
                measure_count = 0;
                phase_sum = 0.0;
            // Discard startup/change transients from both CIC and FIR.
            end else if (settle_count < 400) begin
                settle_count = settle_count + 1;
                previous_i = $itor(i_out);
                previous_q = $itor(q_out);
            end else begin
                delta_phase = $atan2(previous_i*$itor(q_out) - previous_q*$itor(i_out),
                                     previous_i*$itor(i_out) + previous_q*$itor(q_out));
                phase_sum = phase_sum + delta_phase;
                previous_i = $itor(i_out);
                previous_q = $itor(q_out);
                measure_count = measure_count + 1;

                if (measure_count == 600) begin
                    measured_hz = phase_sum * 8000.0 / (TWO_PI * 600.0);
                    expected_hz = observed_tone * 6.25;
                    $display("DDC tone %0d: expected %.6f Hz, measured %.6f Hz",
                             observed_tone, expected_hz, measured_hz);
                    // This short phase estimator is intentionally separate
                    // from the production RTL; allow its residual LUT/spur bias.
                    if ((measured_hz < expected_hz-1.0) ||
                        (measured_hz > expected_hz+1.0))
                        $fatal(1, "DDC frequency outside tolerance");
                    if (observed_tone == 1) begin
                        $display("PASS: DDC distinguishes 18.75 Hz and 6.25 Hz");
                        $finish;
                    end
                    measure_count = 0;
                end
            end
        end
    end
endmodule
