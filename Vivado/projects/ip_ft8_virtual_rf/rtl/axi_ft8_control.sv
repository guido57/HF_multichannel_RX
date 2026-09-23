// AXI4-Lite control/status registers for the receiver and FT8 test source.
module axi_ft8_control #(
    parameter integer C_S_AXI_ADDR_WIDTH = 7,
    parameter integer C_S_AXI_DATA_WIDTH = 32
) (
    input  logic                         s_axi_aclk,
    input  logic                         s_axi_aresetn,
    input  logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  logic                         s_axi_awvalid,
    output logic                         s_axi_awready,
    input  logic [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  logic                         s_axi_wvalid,
    output logic                         s_axi_wready,
    output logic [1:0]                   s_axi_bresp,
    output logic                         s_axi_bvalid,
    input  logic                         s_axi_bready,
    input  logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  logic                         s_axi_arvalid,
    output logic                         s_axi_arready,
    output logic [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output logic [1:0]                   s_axi_rresp,
    output logic                         s_axi_rvalid,
    input  logic                         s_axi_rready,

    input  logic                         source_active,
    input  logic [31:0]                  status_flags,
    output logic                         select_virtual,
    output logic                         start_ft8,
    output logic                         stop_ft8,
    output logic [14:0]                  rf_freq_khz,
    output logic [236:0]                 ft8_symbols,
    output logic [24:0]                  vfo_hz,
    output logic [15:0]                  gain,
    output logic [15:0]                  volume,
    output logic [1:0]                   audio_source
);
    localparam logic [236:0] K1ABC_TONES =
        237'd75084642826647063703584787342781992170070057832874459365619116406399243;

    logic [31:0] symbol_word [0:7];
    logic [C_S_AXI_ADDR_WIDTH-1:0] awaddr_q;
    logic [31:0] wdata_q;
    logic [3:0] wstrb_q;
    logic aw_pending, w_pending;
    integer i;

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET s_axi_aresetn" *)
    wire interface_clock_marker = s_axi_aclk;

    function automatic [31:0] merge_wstrb(
        input [31:0] old_value, input [31:0] new_value, input [3:0] strobe
    );
        integer b;
        begin
            merge_wstrb = old_value;
            for (b = 0; b < 4; b = b + 1)
                if (strobe[b]) merge_wstrb[b*8 +: 8] = new_value[b*8 +: 8];
        end
    endfunction

    genvar word_index;
    generate
        for (word_index = 0; word_index < 7; word_index = word_index + 1) begin : pack_symbols
            assign ft8_symbols[word_index*32 +: 32] = symbol_word[word_index];
        end
    endgenerate
    assign ft8_symbols[224 +: 13] = symbol_word[7][12:0];

    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0; s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;  s_axi_bresp <= 2'b00;
            s_axi_arready <= 1'b0; s_axi_rvalid <= 1'b0;
            s_axi_rdata <= '0;     s_axi_rresp <= 2'b00;
            aw_pending <= 1'b0;    w_pending <= 1'b0;
            select_virtual <= 1'b1;
            rf_freq_khz <= 15'd14075;
            vfo_hz <= 25'd14075000;
            gain <= 16'h7fff; volume <= 16'h7fff; audio_source <= 2'd0;
            start_ft8 <= 1'b0; stop_ft8 <= 1'b0;
            for (i = 0; i < 7; i = i + 1)
                symbol_word[i] <= K1ABC_TONES[i*32 +: 32];
            symbol_word[7] <= {19'd0, K1ABC_TONES[224 +: 13]};
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_arready <= 1'b0;
            start_ft8 <= 1'b0;
            stop_ft8 <= 1'b0;

            if (!aw_pending && s_axi_awvalid) begin
                awaddr_q <= s_axi_awaddr;
                aw_pending <= 1'b1;
                s_axi_awready <= 1'b1;
            end
            if (!w_pending && s_axi_wvalid) begin
                wdata_q <= s_axi_wdata;
                wstrb_q <= s_axi_wstrb;
                w_pending <= 1'b1;
                s_axi_wready <= 1'b1;
            end

            if (aw_pending && w_pending && !s_axi_bvalid) begin
                case (awaddr_q[6:2])
                    5'h00: begin
                        if (wstrb_q[0] && wdata_q[0]) start_ft8 <= 1'b1;
                        if (wstrb_q[0] && wdata_q[1]) stop_ft8 <= 1'b1;
                    end
                    5'h01: rf_freq_khz <= merge_wstrb({17'd0, rf_freq_khz}, wdata_q, wstrb_q)[14:0];
                    5'h02: symbol_word[0] <= merge_wstrb(symbol_word[0], wdata_q, wstrb_q);
                    5'h03: symbol_word[1] <= merge_wstrb(symbol_word[1], wdata_q, wstrb_q);
                    5'h04: symbol_word[2] <= merge_wstrb(symbol_word[2], wdata_q, wstrb_q);
                    5'h05: symbol_word[3] <= merge_wstrb(symbol_word[3], wdata_q, wstrb_q);
                    5'h06: symbol_word[4] <= merge_wstrb(symbol_word[4], wdata_q, wstrb_q);
                    5'h07: symbol_word[5] <= merge_wstrb(symbol_word[5], wdata_q, wstrb_q);
                    5'h08: symbol_word[6] <= merge_wstrb(symbol_word[6], wdata_q, wstrb_q);
                    5'h09: symbol_word[7] <= merge_wstrb(symbol_word[7], wdata_q, wstrb_q) & 32'h00001fff;
                    5'h0b: select_virtual <= merge_wstrb({31'd0, select_virtual}, wdata_q, wstrb_q)[0];
                    5'h0c: vfo_hz <= merge_wstrb({7'd0, vfo_hz}, wdata_q, wstrb_q)[24:0];
                    5'h0d: gain <= merge_wstrb({16'd0, gain}, wdata_q, wstrb_q)[15:0];
                    5'h0e: volume <= merge_wstrb({16'd0, volume}, wdata_q, wstrb_q)[15:0];
                    5'h0f: audio_source <= merge_wstrb({30'd0, audio_source}, wdata_q, wstrb_q)[1:0];
                    default: ;
                endcase
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            if (!s_axi_rvalid && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;
                case (s_axi_araddr[6:2])
                    5'h00: s_axi_rdata <= 32'd0;
                    5'h01: s_axi_rdata <= {17'd0, rf_freq_khz};
                    5'h02: s_axi_rdata <= symbol_word[0];
                    5'h03: s_axi_rdata <= symbol_word[1];
                    5'h04: s_axi_rdata <= symbol_word[2];
                    5'h05: s_axi_rdata <= symbol_word[3];
                    5'h06: s_axi_rdata <= symbol_word[4];
                    5'h07: s_axi_rdata <= symbol_word[5];
                    5'h08: s_axi_rdata <= symbol_word[6];
                    5'h09: s_axi_rdata <= symbol_word[7];
                    5'h0a: s_axi_rdata <= status_flags | {31'd0, source_active};
                    5'h0b: s_axi_rdata <= {31'd0, select_virtual};
                    5'h0c: s_axi_rdata <= {7'd0, vfo_hz};
                    5'h0d: s_axi_rdata <= {16'd0, gain};
                    5'h0e: s_axi_rdata <= {16'd0, volume};
                    5'h0f: s_axi_rdata <= {30'd0, audio_source};
                    5'h10: s_axi_rdata <= 32'h46543801; // "FT8", register-map v1
                    default: s_axi_rdata <= 32'd0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
endmodule
