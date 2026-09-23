`timescale 1ns/1ps
module tb_axi_ft8_control;
    logic clk = 0, resetn = 0;
    always #5 clk = ~clk;
    logic [6:0] awaddr; logic awvalid, awready;
    logic [31:0] wdata; logic [3:0] wstrb; logic wvalid, wready;
    logic [1:0] bresp; logic bvalid, bready;
    logic [6:0] araddr; logic arvalid, arready;
    logic [31:0] rdata; logic [1:0] rresp; logic rvalid, rready;
    logic source_active; logic [31:0] status_flags;
    logic select_virtual, start_ft8, stop_ft8;
    logic [14:0] rf_freq_khz; logic [236:0] ft8_symbols;
    logic [24:0] vfo_hz; logic [15:0] gain, volume; logic [1:0] audio_source;
    integer start_pulses = 0, stop_pulses = 0;
    axi_ft8_control dut (
        .s_axi_aclk(clk), .s_axi_aresetn(resetn),
        .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
        .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(rready),
        .source_active(source_active), .status_flags(status_flags),
        .select_virtual(select_virtual), .start_ft8(start_ft8), .stop_ft8(stop_ft8),
        .rf_freq_khz(rf_freq_khz), .ft8_symbols(ft8_symbols), .vfo_hz(vfo_hz),
        .gain(gain), .volume(volume), .audio_source(audio_source)
    );
    always @(posedge clk) begin
        if (start_ft8) start_pulses <= start_pulses + 1;
        if (stop_ft8) stop_pulses <= stop_pulses + 1;
    end
    task automatic axi_write(input [6:0] addr, input [31:0] data, input [3:0] strb);
        begin
            @(posedge clk); awaddr <= addr; awvalid <= 1;
            do @(posedge clk); while (!awready); awvalid <= 0;
            @(posedge clk); wdata <= data; wstrb <= strb; wvalid <= 1;
            do @(posedge clk); while (!wready); wvalid <= 0;
            do @(posedge clk); while (!bvalid);
            if (bresp != 0) $fatal(1, "AXI write response %b", bresp);
            bready <= 1; @(posedge clk); bready <= 0;
        end
    endtask
    task automatic axi_read(input [6:0] addr, output [31:0] data);
        begin
            @(posedge clk); araddr <= addr; arvalid <= 1;
            do @(posedge clk); while (!arready); arvalid <= 0;
            do @(posedge clk); while (!rvalid); data = rdata;
            if (rresp != 0) $fatal(1, "AXI read response %b", rresp);
            rready <= 1; @(posedge clk); rready <= 0;
        end
    endtask
    logic [31:0] rd;
    initial begin
        awaddr=0; awvalid=0; wdata=0; wstrb=0; wvalid=0; bready=0;
        araddr=0; arvalid=0; rready=0; source_active=0; status_flags=0;
        repeat (5) @(posedge clk); resetn <= 1; repeat (2) @(posedge clk);
        if (!select_virtual || rf_freq_khz != 14075 || vfo_hz != 14075000) $fatal(1, "Bad defaults");
        if (ft8_symbols[2:0] != 3 || ft8_symbols[5:3] != 1 || ft8_symbols[8:6] != 4) $fatal(1, "Bad tone packing");
        axi_write(7'h04, 7074, 4'hf); axi_read(7'h04, rd);
        if (rd != 7074) $fatal(1, "RF frequency failed");
        axi_write(7'h30, 7073000, 4'hf); axi_read(7'h30, rd);
        if (rd != 7073000) $fatal(1, "VFO failed");
        axi_write(7'h2c, 0, 4'h1); if (select_virtual) $fatal(1, "Source failed");
        axi_write(7'h2c, 1, 4'h1);
        axi_write(7'h08, 32'h89abcdef, 4'hf); axi_write(7'h24, 32'hffffffff, 4'hf);
        if (ft8_symbols[31:0] != 32'h89abcdef || ft8_symbols[236:224] != 13'h1fff) $fatal(1, "Symbols failed");
        source_active=1; status_flags=32'h100; axi_read(7'h28, rd);
        if (rd != 32'h101) $fatal(1, "Status failed");
        axi_write(7'h00, 1, 4'h1); repeat (2) @(posedge clk);
        axi_write(7'h00, 2, 4'h1); repeat (2) @(posedge clk);
        if (start_pulses != 1 || stop_pulses != 1) $fatal(1, "Pulse counts %0d %0d", start_pulses, stop_pulses);
        axi_read(7'h40, rd); if (rd != 32'h46543801) $fatal(1, "ID failed");
        $display("PASS: AXI4-Lite control peripheral verified"); $finish;
    end
endmodule
