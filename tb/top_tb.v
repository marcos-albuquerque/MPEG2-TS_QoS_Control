`timescale 1ns/1ps

module top_tb();
    localparam real DATA_FREQUENCY = 100e6;      // Clock frequency in Hz
    localparam real SYS_FREQUENCY = 27e6;
    localparam FILE_NAME1 = "tsdata1_loss.ts";
    localparam FILE_NAME2 = "tsdata2_loss.ts";
    localparam FILE_NAME3 = "tsdata3_loss.ts";
    localparam FILE_NAME4 = "tsdata4_loss.ts";
    localparam DATA_WIDTH = 8;

    reg reset_n;
    wire wclk;
    wire rclk;
    wire [DATA_WIDTH-1:0] byte_data1;
    wire [DATA_WIDTH-1:0] byte_data2;
    wire [DATA_WIDTH-1:0] byte_data3;
    wire [DATA_WIDTH-1:0] byte_data4;


    // TODO: Memory Mapped interconection
    // ...

    clock_generator #(DATA_FREQUENCY, 1) CLOCK100M(.clk(wclk));
    clock_generator #(SYS_FREQUENCY, 1) CLOCK27M(.clk(rclk));

    stimulus_from_file # (
        .FILE_NAME1(FILE_NAME1),
        .FILE_NAME2(FILE_NAME2),
        .FILE_NAME3(FILE_NAME3),
        .FILE_NAME4(FILE_NAME4),
        .DATA_WIDTH(DATA_WIDTH)
    )
    stimulus_from_file_inst (
        .clk(wclk),
        .byte_data1(byte_data1),
        .byte_data2(byte_data2),
        .byte_data3(byte_data3),
        .byte_data4(byte_data4)
    ); 

    initial begin
        reset_n = 1'b0; #40;
        reset_n = 1'b1;

        // ...
    end

endmodule
