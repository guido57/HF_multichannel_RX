`timescale 1ns/1ps

// GUI-oriented end-to-end testbench:
// FT8 RF source -> AD9248 emulator -> ADC input -> 8 ksample/s complex DDC.
module tb_ft8_ddc_integration;
    logic clk128 = 1'b0;
    logic [236:0] ft8_symbols =
        237'd75084642826647063703584787342781992170070057832874459365619116406399243;

    logic signed [13:0] source_sample_a;
    logic signed [13:0] source_sample_b;
    logic source_active;
    logic clka;
    logic clkb;
    logic signed [13:0] virtual_data;
    logic virtual_otra;
    logic virtual_otrb;
    logic signed [13:0] ddc_sample_a;
    logic signed [13:0] ddc_sample_b;
    logic ddc_valid_a;
    logic ddc_valid_b;
    logic selected_otra;
    logic selected_otrb;
    logic signed [23:0] i_out;
    logic signed [23:0] q_out;
    logic output_valid;
    integer output_count = 0;

    always #3.90625 clk128 = ~clk128;

    ft8_virtual_rf_core ft8_source (
        .clk128,
        .start_ft8(1'b1),
        .stop_ft8(1'b0),
        .rf_freq_khz(15'd14075),
        .ft8_symbols,
        .sample_a(source_sample_a),
        .sample_b(source_sample_b),
        .source_active
    );

    ad9248_emulator adc_emulator (
        .clk128, .clka, .clkb,
        .sample_a(source_sample_a),
        .sample_b(source_sample_b),
        .data(virtual_data),
        .otra(virtual_otra),
        .otrb(virtual_otrb)
    );

    adc_input adc_front_end (
        .clk128,
        .select_virtual(1'b1),
        .adc_data(14'sd0),
        .adc_otra(1'b0),
        .adc_otrb(1'b0),
        .virtual_data,
        .virtual_otra,
        .virtual_otrb,
        .clka,
        .clkb,
        .ddc_sample_a,
        .ddc_sample_b,
        .ddc_valid_a,
        .ddc_valid_b,
        .otra(selected_otra),
        .otrb(selected_otrb)
    );

    ddc_64m_to_8k ddc_channel_a (
        .clk128,
        .sample_in(ddc_sample_a),
        .sample_valid(ddc_valid_a),
        .vfo_hz(25'd14075000),
        .i_out,
        .q_out,
        .output_valid
    );

    always @(posedge clk128) begin
        if (output_valid) begin
            output_count <= output_count + 1;
            if ($isunknown(i_out) || $isunknown(q_out))
                $fatal(1, "DDC produced an undefined I/Q sample");
            if ((i_out == 24'sh7fffff) || (i_out == 24'sh800000) ||
                (q_out == 24'sh7fffff) || (q_out == 24'sh800000))
                $fatal(1, "DDC output saturated");
        end
    end

    initial begin
        #2ms;
        if (output_count == 0)
            $fatal(1, "No DDC output samples received within 2 ms");
        $display("PASS: received %0d defined 8 ksample/s I/Q outputs", output_count);
    end
endmodule
