
module top_sync_recovery (
    input clk, rst,
    input [7:0] byte_in1,
    input [7:0] byte_in2,
    input [7:0] byte_in3,
    input [7:0] byte_in4,
    input valid_in1,
    input valid_in2,
    input valid_in3,
    input valid_in4,
    output reg sync1,
    output reg sync2,
    output reg sync3,
    output reg sync4,
    output reg valid_out1,
    output reg valid_out2,
    output reg valid_out3,
    output reg valid_out4,
    output reg [7:0] byte_out1,
    output reg [7:0] byte_out2,
    output reg [7:0] byte_out3,
    output reg [7:0] byte_out4
);
    sync_recovery  sync_recovery_inst1 (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in1),
        .byte_valid(valid_in1),
        .sync(sync1),
        .valid(valid_out1),
        .byte_out(byte_out1)
    );

    sync_recovery  sync_recovery_inst2 (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in2),
        .byte_valid(valid_in2),
        .sync(sync2),
        .valid(valid_out2),
        .byte_out(byte_out2)
    );

    sync_recovery  sync_recovery_inst3 (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in3),
        .byte_valid(valid_in3),
        .sync(sync3),
        .valid(valid_out3),
        .byte_out(byte_out3)
    );

    sync_recovery  sync_recovery_inst4 (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in4),
        .byte_valid(valid_in4),
        .sync(sync4),
        .valid(valid_out4),
        .byte_out(byte_out4)
    );
endmodule
