`timescale 1ns/1ps

module top_sync_recovery_tb();
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

    wire [3:0] valid;

    stimulus_from_file # (
        .FILE_NAME1(FILE_NAME1),
        .FILE_NAME2(FILE_NAME2),
        .FILE_NAME3(FILE_NAME3),
        .FILE_NAME4(FILE_NAME4),
        .DATA_WIDTH(DATA_WIDTH)
    )
    stimulus_from_file_inst (
        .clk(wclk),
        .valid(valid),
        .byte_data1(byte_data1),
        .byte_data2(byte_data2),
        .byte_data3(byte_data3),
        .byte_data4(byte_data4)
    ); 

    
    wire valid_1, valid_2, valid_3, valid_4;
    wire [7:0] byte_1, byte_2, byte_3, byte_4;
    wire sync_1, sync_2, sync_3, sync_4;

    top_module_sync sync_recovery_inst1(
                    .clk(wclk), 
                    .rst(reset_n),
                    .byte_1(byte_data1),
                    .byte_2(byte_data2),
                    .byte_3(byte_data3),
                    .byte_4(byte_data4),
                    .byte_valid1(valid[0]),
                    .byte_valid2(valid[1]),
                    .byte_valid3(valid[2]),
                    .byte_valid4(valid[3]),
                    .sync_1(sync_1), 
                    .sync_2(sync_2), 
                    .sync_3(sync_3), 
                    .sync_4(sync_4),
                    .valid_1(valid_1),
                    .valid_2(valid_2),
                    .valid_3(valid_3),
                    .valid_4(valid_4),
                    .ts1(byte_1),
                    .ts2(byte_2),
                    .ts3(byte_3),
                    .ts4(byte_4)
    );

    initial begin
        reset_n = 1'b0; #40;
        reset_n = 1'b1; 
        #1000_0000 $stop; 
        // ...
    end

endmodule
