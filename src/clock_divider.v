
module clock_divider #(
    parameter FREQUENCY_IN = 108e6,
    parameter FREQUENCY_OUT = 27e6
) (
    input rstn,
    input clk2,
    output clk_pulse_out
);

    localparam integer CLK_COUNT_VAL = (FREQUENCY_IN/FREQUENCY_OUT) - 1;
    localparam COUNTER_SIZE = $clog2(CLK_COUNT_VAL);

    reg [COUNTER_SIZE:0] counter;
    reg clk_pulse_out_;

    always @(posedge clk2) begin
        if (!rstn) begin
            counter <= 0;
            clk_pulse_out_ <= 0;
        end else if (counter < (CLK_COUNT_VAL >> 1)) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
            clk_pulse_out_ <= ~clk_pulse_out_;
        end
    end

    assign clk_pulse_out = clk_pulse_out_;
endmodule
