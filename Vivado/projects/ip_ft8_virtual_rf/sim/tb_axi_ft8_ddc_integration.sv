`timescale 1ns/1ps

// Full-chain simulation driven through the same AXI4-Lite register interface
// used by PS software: AXI -> FT8 source -> AD9248 emulator -> ADC input -> DDC.
module tb_axi_ft8_ddc_integration;
    // ---- Explicit simulation and receiver settings ----
    localparam realtime CLK128_HALF_PERIOD_NS = 3.90625;
    localparam integer  RESET_CLOCKS          = 16;
    localparam time     RESULT_TIMEOUT         = 400ms;
    localparam logic    SELECT_VIRTUAL         = 1'b1;
    localparam logic [14:0] FT8_RF_FREQ_KHZ    = 15'd14075;
    localparam logic [24:0] DDC_VFO_HZ         = 25'd14074000;

    localparam logic [6:0] REG_CONTROL         = 7'h00;
    localparam logic [6:0] REG_RF_FREQ_KHZ     = 7'h04;
    localparam logic [6:0] REG_SYMBOL_WORD0    = 7'h08;
    localparam logic [6:0] REG_STATUS          = 7'h28;
    localparam logic [6:0] REG_SOURCE          = 7'h2c;
    localparam logic [6:0] REG_VFO_HZ          = 7'h30;
    localparam logic [31:0] CMD_START_FT8      = 32'h00000001;
    localparam logic [31:0] CMD_STOP_FT8       = 32'h00000002;

    // Tone n is written to ft8_symbols[3*n +: 3], so tone 0 is at the LSB.
    localparam logic [2:0] FT8_TONES [0:78] = '{
        3,1,4,0,6,5,2,
        0,3,1,7,4,5,2,6,4,5,0,5,4,7,6,7,0,4,6,0,6,0,2,1,4,3,2,0,5,
        3,1,4,0,6,5,2,
        6,4,0,4,0,1,3,6,5,0,5,4,5,4,5,0,7,0,6,4,0,4,1,1,4,0,0,4,2,
        3,1,4,0,6,5,2
    };

    logic clk128 = 1'b0;
    logic axi_resetn = 1'b0;
    always #(CLK128_HALF_PERIOD_NS) clk128 = ~clk128;

    logic [6:0] awaddr = 0; logic awvalid = 0, awready;
    logic [31:0] wdata = 0; logic [3:0] wstrb = 0; logic wvalid = 0, wready;
    logic [1:0] bresp; logic bvalid, bready = 0;
    logic [6:0] araddr = 0; logic arvalid = 0, arready;
    logic [31:0] rdata; logic [1:0] rresp; logic rvalid, rready = 0;

    logic select_virtual, start_ft8, stop_ft8;
    logic [14:0] rf_freq_khz;
    logic [236:0] ft8_symbols;
    logic [24:0] vfo_hz;
    logic [15:0] gain, volume;
    logic [1:0] audio_source;
    logic signed [13:0] source_sample_a, source_sample_b;
    logic source_active;
    logic clka, clkb;
    logic signed [13:0] virtual_data;
    logic virtual_otra, virtual_otrb;
    logic signed [13:0] ddc_sample_a, ddc_sample_b;
    logic ddc_valid_a, ddc_valid_b, selected_otra, selected_otrb;
    logic signed [23:0] i_out, q_out;
    logic output_valid;
    logic [236:0] expected_symbols;
    integer tone_index, word_index;
    integer output_count = 0;
    logic start_seen = 0;

    axi_ft8_control control (
        .s_axi_aclk(clk128), .s_axi_aresetn(axi_resetn),
        .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
        .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(rready),
        .source_active(source_active), .status_flags(32'd0),
        .select_virtual, .start_ft8, .stop_ft8, .rf_freq_khz, .ft8_symbols,
        .vfo_hz, .gain, .volume, .audio_source
    );

    ft8_virtual_rf_core ft8_source (
        .clk128, .start_ft8, .stop_ft8, .rf_freq_khz, .ft8_symbols,
        .sample_a(source_sample_a), .sample_b(source_sample_b), .source_active
    );

    ad9248_emulator adc_emulator (
        .clk128, .clka, .clkb, .sample_a(source_sample_a), .sample_b(source_sample_b),
        .data(virtual_data), .otra(virtual_otra), .otrb(virtual_otrb)
    );

    adc_input adc_front_end (
        .clk128, .select_virtual,
        .adc_data(14'sd0), .adc_otra(1'b0), .adc_otrb(1'b0),
        .virtual_data, .virtual_otra, .virtual_otrb, .clka, .clkb,
        .ddc_sample_a, .ddc_sample_b, .ddc_valid_a, .ddc_valid_b,
        .otra(selected_otra), .otrb(selected_otrb)
    );

    ddc_64m_to_8k ddc_channel_a (
        .clk128, .sample_in(ddc_sample_a), .sample_valid(ddc_valid_a), .vfo_hz,
        .i_out, .q_out, .output_valid
    );

    task automatic axi_write(input logic [6:0] addr, input logic [31:0] data);
        begin
            @(posedge clk128); awaddr <= addr; awvalid <= 1'b1;
            do @(posedge clk128); while (!awready);
            awvalid <= 1'b0;
            // Keep address and data deliberately independent.
            @(posedge clk128); wdata <= data; wstrb <= 4'hf; wvalid <= 1'b1;
            do @(posedge clk128); while (!wready);
            wvalid <= 1'b0;
            do @(posedge clk128); while (!bvalid);
            if (bresp != 2'b00) $fatal(1, "AXI write error at 0x%02h", addr);
            bready <= 1'b1; @(posedge clk128); bready <= 1'b0;
        end
    endtask

    task automatic axi_read(input logic [6:0] addr, output logic [31:0] data);
        begin
            @(posedge clk128); araddr <= addr; arvalid <= 1'b1;
            do @(posedge clk128); while (!arready);
            arvalid <= 1'b0;
            do @(posedge clk128); while (!rvalid);
            data = rdata;
            if (rresp != 2'b00) $fatal(1, "AXI read error at 0x%02h", addr);
            rready <= 1'b1; @(posedge clk128); rready <= 1'b0;
        end
    endtask

    always @(posedge clk128) begin
        if (start_ft8) start_seen <= 1'b1;
        if (output_valid) begin
            output_count <= output_count + 1;
            if ($isunknown(i_out) || $isunknown(q_out))
                $fatal(1, "DDC produced undefined I/Q");
            if ((i_out == 24'sh7fffff) || (i_out == 24'sh800000) ||
                (q_out == 24'sh7fffff) || (q_out == 24'sh800000))
                $fatal(1, "DDC output saturated");
        end
    end

    logic [31:0] readback;
    initial begin
        expected_symbols = '0;
        for (tone_index = 0; tone_index < 79; tone_index = tone_index + 1)
            expected_symbols[3*tone_index +: 3] = FT8_TONES[tone_index];

        repeat (RESET_CLOCKS) @(posedge clk128);
        axi_resetn <= 1'b1;
        repeat (4) @(posedge clk128);

        axi_write(REG_SOURCE, SELECT_VIRTUAL);
        axi_write(REG_RF_FREQ_KHZ, FT8_RF_FREQ_KHZ);
        axi_write(REG_VFO_HZ, DDC_VFO_HZ);
        for (word_index = 0; word_index < 8; word_index = word_index + 1)
            axi_write(REG_SYMBOL_WORD0 + word_index*4,
                      (word_index == 7) ? {19'd0, expected_symbols[236:224]} :
                                          expected_symbols[word_index*32 +: 32]);

        if (ft8_symbols !== expected_symbols) $fatal(1, "FT8 symbol register mismatch");
        axi_write(REG_CONTROL, CMD_START_FT8);
        repeat (8) @(posedge clk128);
        if (!start_seen || !source_active) $fatal(1, "START_FT8 did not activate source");
        axi_read(REG_STATUS, readback);
        if (!readback[0]) $fatal(1, "STATUS does not report active FT8 source");

        #(RESULT_TIMEOUT);
        if (output_count == 0) $fatal(1, "No DDC I/Q samples within timeout");
        $display("PASS: AXI configured 79 tones and produced %0d valid DDC I/Q samples", output_count);
        axi_write(REG_CONTROL, CMD_STOP_FT8);
        repeat (8) @(posedge clk128);
        if (source_active) $fatal(1, "STOP_FT8 did not stop source");
        $finish;
    end
endmodule
