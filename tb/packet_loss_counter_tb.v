`timescale 1ns/1ps

module packet_loss_counter_tb ();
    localparam FILE_NAME1 = "tsdata1_loss.ts";
    localparam FILE_NAME2 = "tsdata2_loss.ts";
    localparam FILE_NAME3 = "tsdata3_loss.ts";
    localparam FILE_NAME4 = "tsdata4_loss.ts";
    localparam DATA_WIDTH = 8;

    reg  clk;
    reg  reset_n;
    reg  valid;
    reg  sync;
    reg  [7:0] ts_data;
    reg  en_reset_counter;
    wire [7:0] error_count;


    wire [DATA_WIDTH-1:0] byte_data1;
    wire [DATA_WIDTH-1:0] byte_data2;
    wire [DATA_WIDTH-1:0] byte_data3;
    wire [DATA_WIDTH-1:0] byte_data4;

    stimulus_from_file # (
        .FILE_NAME1(FILE_NAME1),
        .FILE_NAME2(FILE_NAME2),
        .FILE_NAME3(FILE_NAME3),
        .FILE_NAME4(FILE_NAME4),
        .DATA_WIDTH(DATA_WIDTH)
    )
    stimulus_from_file_inst (
        .clk(clk),
        .byte_data1(byte_data1),
        .byte_data2(byte_data2),
        .byte_data3(byte_data3),
        .byte_data4(byte_data4)
    );

    packet_loss_counter  uut (
        .clk(clk),
        .reset_n(reset_n),
        .valid(valid),
        .sync(sync),
        .en_reset_counter(en_reset_counter),
        .ts_data(ts_data),
        .error_count(error_count)
    );

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        en_reset_counter = 1'b0;
        valid = 1'b0;
        sync = 1'b0;
        reset_n = 1'b0; #40;
        reset_n = 1'b1;

        repeat(4700) begin
            @(posedge clk)
            if (byte_data1 == 8'h47) begin
                sync = 1'b1;
                valid = 1'b1;
                ts_data = byte_data1;
            end else begin
                sync = 1'b0;
                valid = 1'b1;
                ts_data = byte_data1;
            end
        end

        // testing the main control reset counter signal
        en_reset_counter = 1'b1; #10;
        en_reset_counter = 1'b0;
        repeat(94000) begin
            @(posedge clk)
            if (byte_data1 == 8'h47) begin
                sync = 1'b1;
                valid = 1'b1;
                ts_data = byte_data1;
            end else begin
                sync = 1'b0;
                valid = 1'b1;
                ts_data = byte_data1;
            end
        end
    end
endmodule
