// One 14-bit AD9248-style bus, interleaving A/B samples at 128 MS/s.
module ft8_virtual_rf #(
    parameter int unsigned PIPELINE_CYCLES = 7,
    parameter logic [31:0] PHASE_INCREMENT = 32'h3800_0000,
    parameter logic signed [13:0] AMPLITUDE = 14'sd4096
) (
    input logic clk_128, input logic rst_n,
    output logic clka, output logic clkb,
    output logic signed [13:0] data,
    output logic otra, output logic otrb
);
    logic select_b;
    logic [31:0] phase_a, phase_b;
    logic signed [13:0] pipe_a [0:PIPELINE_CYCLES-1];
    logic signed [13:0] pipe_b [0:PIPELINE_CYCLES-1];
    integer ia, ib;

    function automatic logic signed [13:0] nco_sample(input logic [31:0] phase);
        logic signed [13:0] magnitude;
        begin
            magnitude = phase[30] ? -AMPLITUDE : AMPLITUDE;
            nco_sample = phase[31] ? -magnitude : magnitude;
        end
    endfunction

    always_ff @(posedge clk_128 or negedge rst_n) begin
        if (!rst_n) begin
            select_b <= 1'b0; clka <= 1'b0; clkb <= 1'b1; data <= '0;
            otra <= 1'b0; otrb <= 1'b0; phase_a <= '0; phase_b <= '0;
            for (ia = 0; ia < PIPELINE_CYCLES; ia++) pipe_a[ia] <= '0;
            for (ib = 0; ib < PIPELINE_CYCLES; ib++) pipe_b[ib] <= '0;
        end else begin
            // Each output clock is 64 MHz; they are always complementary.
            clka <= ~clka; clkb <= ~clkb; select_b <= ~select_b;
            otra <= 1'b0; otrb <= 1'b0;
            if (!select_b) begin
                phase_a <= phase_a + PHASE_INCREMENT;
                pipe_a[0] <= nco_sample(phase_a);
                for (ia = 1; ia < PIPELINE_CYCLES; ia++) pipe_a[ia] <= pipe_a[ia-1];
                data <= pipe_a[PIPELINE_CYCLES-1];
            end else begin
                phase_b <= phase_b + PHASE_INCREMENT;
                pipe_b[0] <= nco_sample(phase_b);
                for (ib = 1; ib < PIPELINE_CYCLES; ib++) pipe_b[ib] <= pipe_b[ib-1];
                data <= pipe_b[PIPELINE_CYCLES-1];
            end
        end
    end
endmodule
