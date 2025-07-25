`timescale 1ns/1ps
//`define DEBUG //Enable display

module stimulus_from_file #(
    parameter FILE_NAME1 = "tsdata1_loss.ts",
    parameter FILE_NAME2 = "tsdata2_loss.ts",
    parameter FILE_NAME3 = "tsdata3_loss.ts",
    parameter FILE_NAME4 = "tsdata4_loss.ts",
    parameter DATA_WIDTH = 8
    // parameter DEPTH      = 
)(
    input  clk,
    input  rstn,
    output reg [3:0] valid,
    output reg eof, // end of file
    output [DATA_WIDTH-1:0] byte_data1,     // ts data
    output [DATA_WIDTH-1:0] byte_data2,
    output [DATA_WIDTH-1:0] byte_data3,
    output [DATA_WIDTH-1:0] byte_data4
);
    // output regs
    reg [DATA_WIDTH-1:0] byte_data1_,
                         byte_data2_,
                         byte_data3_,
                         byte_data4_;

    // variables to store file handles
    integer fh1,
            fh2,
            fh3,
            fh4;
    
    initial begin
        byte_data1_ <= 0;
        byte_data2_ <= 0;
        byte_data3_ <= 0;
        byte_data4_ <= 0;
        valid       <= 0;
        eof = 0;
        wait(rstn == 1);
        fh1 = $fopen(FILE_NAME1, "rb");
        fh2 = $fopen(FILE_NAME2, "rb");
        fh3 = $fopen(FILE_NAME3, "rb");
        fh4 = $fopen(FILE_NAME4, "rb");

        if (!fh1) begin
            `ifdef DEBUG
                $display("Error to open file: ", FILE_NAME1);
            `endif
            $finish();
        end else if (!fh2) begin
            `ifdef DEBUG
                $display("Error to open file: ", FILE_NAME2);
            `endif
            $finish();
        end else if (!fh3) begin
            `ifdef DEBUG
                $display("Error to open file: ", FILE_NAME3);
            `endif
            $finish();
        end else if (!fh4) begin
            `ifdef DEBUG
                $display("Error to open file: ", FILE_NAME4);
            `endif
            $finish();
        end else begin
            // Keep reading lines until EOF is found
            while (! $feof(fh1)) begin
                @(posedge clk)                
                    byte_data1_ = $fgetc(fh1);
                    valid[0] = 1'b1;
                    `ifdef DEBUG
                        $display("Data1: %h", byte_data1);
                    `endif
                    byte_data2_ = $fgetc(fh2);
                    valid[1] = 1'b1;
                    `ifdef DEBUG
                        $display("Data2: %h", byte_data2);
                    `endif
                    byte_data3_ = $fgetc(fh3);
                    valid[2] = 1'b1;
                    `ifdef DEBUG
                        $display("Data3: %h", byte_data3);
                    `endif
                    byte_data4_ = $fgetc(fh4);
                    valid[3] = 1'b1;
                    `ifdef DEBUG
                        $display("Data4: %h", byte_data4);
                        $display("EOF: %0d", $feof(fh1));
                    `endif
            end
            eof <= 1;
        end

        $fclose(fh1);
        $fclose(fh2);
        $fclose(fh3);
        $fclose(fh4);
    end

    assign byte_data1 = byte_data1_;
    assign byte_data2 = byte_data2_;
    assign byte_data3 = byte_data3_;
    assign byte_data4 = byte_data4_;
endmodule

module clock_generator #(
    parameter real FREQ_HZ = 100_000_000,           // Default: 100 MHz
    parameter      START_POLARITY = 1               // Default: Start with HIGH (1)
)(
    output clk
);
    localparam real HALF_PERIOD = 1.0 / (2.0 * FREQ_HZ) * 1e9; 
    reg clock;

    initial clock = START_POLARITY;                 // Set initial polarity

    always begin
        #(HALF_PERIOD) clock = ~clock;              // Toggle clock
    end

    assign clk = clock;
endmodule