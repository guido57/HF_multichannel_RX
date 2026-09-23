`timescale 1ns/1ps

// Accelerated self-checking testbench. Production timing remains encoded in
// the RTL parameter defaults; only this instance shortens symbols and slots.
module tb_ft8_virtual_rf;
    localparam integer TEST_SYMBOL_SAMPLES = 8;
    localparam integer TEST_SLOT_SAMPLES = 700;

    logic clk128 = 1'b0;
    logic start_ft8 = 1'b1;
    logic stop_ft8 = 1'b0;
    logic [14:0] rf_freq_khz = 15'd14075;
    logic [236:0] ft8_symbols;
    logic signed [13:0] sample_a, sample_b;
    logic source_active;
    logic [2:0] expected_tones [0:78];
    integer expected_symbol = 0;
    integer observed_slots = 0;

    // K1ABC: ft8_symbols[3*n +: 3] is symbol n.
    initial ft8_symbols = 237'd75084642826647063703584787342781992170070057832874459365619116406399243;
    initial expected_tones = '{
        3,1,4,0,6,5,2,
        0,3,1,7,4,5,2,6,4,5,0,5,4,7,6,7,0,4,6,0,6,0,2,1,4,3,2,0,5,
        3,1,4,0,6,5,2,
        6,4,0,4,0,1,3,6,5,0,5,4,5,4,5,0,7,0,6,4,0,4,1,1,4,0,0,4,2,
        3,1,4,0,6,5,2
    };

    always #3.90625 clk128 = ~clk128;

    ft8_virtual_rf_core #(
        .SYMBOL_SAMPLES(TEST_SYMBOL_SAMPLES),
        .SLOT_SAMPLES(TEST_SLOT_SAMPLES)
    ) dut (
        .clk128, .start_ft8, .stop_ft8, .rf_freq_khz, .ft8_symbols,
        .sample_a, .sample_b, .source_active
    );

    initial begin
        #20;
        if (dut.base_phase_increment !== 48'd61902504643789)
            $fatal(1, "Incorrect 14.075 MHz phase increment");
        if (dut.phase_increment !== 48'd61902587107162)
            $fatal(1, "Incorrect first-tone phase increment");
    end

    // Check every symbol at its first 64 MS/s scheduler tick.
    always @(posedge clk128) begin
        if (dut.running && dut.channel_b && source_active &&
            dut.symbol_sample_count == 0) begin
            if (dut.current_tone !== expected_tones[dut.symbol_index])
                $fatal(1, "Tone mismatch at symbol %0d: expected %0d, observed %0d",
                       dut.symbol_index, expected_tones[dut.symbol_index], dut.current_tone);
            if (dut.symbol_index !== expected_symbol[6:0])
                $fatal(1, "Expected symbol %0d, observed %0d",
                       expected_symbol, dut.symbol_index);
            expected_symbol = expected_symbol + 1;
            if (expected_symbol == 79)
                expected_symbol = 0;
        end

        if (dut.running && dut.channel_b &&
            dut.slot_sample_count == TEST_SLOT_SAMPLES - 1) begin
            if (expected_symbol != 0)
                $fatal(1, "Slot ended before all 79 symbols were observed");
            observed_slots = observed_slots + 1;
            if (observed_slots == 2) begin
                $display("PASS: 79 symbols, TX gap, and 15-second-slot repeat verified");
                $finish;
            end
        end
    end
endmodule
