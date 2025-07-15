`timescale 1ns/1ps

module top_tb();
    localparam real DATA_FREQUENCY = 100e6;      // Clock frequency in Hz
    localparam real SYS_FREQUENCY = 27e6;
    localparam FILE_NAME1 = "tsdata1_loss.ts";
    localparam FILE_NAME2 = "tsdata2_loss.ts";
    localparam FILE_NAME3 = "tsdata3_loss.ts";
    localparam FILE_NAME4 = "tsdata4_loss.ts";
    localparam DATA_WIDTH = 8;

    reg rst_n;
    reg valid1;
    reg valid2;
    reg valid3;
    reg valid4;
    
    wire wclk;
    wire rclk;
    wire [DATA_WIDTH-1:0] byte_data1;
    wire [DATA_WIDTH-1:0] byte_data2;
    wire [DATA_WIDTH-1:0] byte_data3;
    wire [DATA_WIDTH-1:0] byte_data4;


    // Memory Mapped config interface
    reg [7:0] mm_addr;
    reg [31:0] mm_wdata;
    reg [31:0] mm_rdata;
    reg mm_read_en;
    reg mm_write_en;

    task mm_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge wclk);
            mm_addr     <= addr;
            mm_wdata    <= data;
            mm_write_en <= 1'b1;
            @(posedge wclk);
            mm_write_en <= 1'b0;
        end
    endtask

    task mm_read(input [7:0] addr, output [31:0] data);
        begin
            @(posedge wclk);
            mm_addr    <= addr;
            mm_read_en <= 1'b1;
            @(posedge wclk);
            data = mm_rdata;
            mm_read_en <= 1'b0;
        end
    endtask

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

    top  DUT (
        .rst_n(rst_n),

        .wclk1(wclk1),
        .valid1(valid1),
        .ts_data1(ts_data1),

        .wclk2(wclk2),
        .valid2(valid2),
        .ts_data2(ts_data2),

        .wclk3(wclk3),
        .valid3(valid3),
        .ts_data3(ts_data3),

        .wclk4(wclk4),
        .valid4(valid4),
        .ts_data4(ts_data4),

        .rclk(rclk),

        .mm_write_en(mm_write_en),
        .mm_read_en(mm_read_en),
        .mm_addr(mm_addr),
        .mm_wdata(mm_wdata),
        .mm_rdata(mm_rdata),

        .clk_out(clk_out),
        .valid_out(valid_out),
        .syn_out(syn_out),
        .ts_data_out(ts_data_out)
    );

    initial begin : tester
        rst_n = 1'b0; #40;
        rst_n = 1'b1;

        // ...
        // TOP
    end

    initial begin : scoreboard
        
    end

endmodule
