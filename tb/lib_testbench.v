`timescale 1ns/1ps

module stimulus_from_file #(
    parameter FILE_NAME1 = "tsdata1_loss.ts",
    parameter FILE_NAME2 = "tsdata2_loss.ts",
    parameter FILE_NAME3 = "tsdata3_loss.ts",
    parameter FILE_NAME4 = "tsdata4_loss.ts",
    parameter DATA_WIDTH = 8
    // parameter DEPTH      = 
)(
    input clk,
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
        fh1 = $fopen(FILE_NAME1, "rb");
        fh2 = $fopen(FILE_NAME2, "rb");
        fh3 = $fopen(FILE_NAME3, "rb");
        fh4 = $fopen(FILE_NAME4, "rb");

        if (!fh1) begin
            $display("Error to open file: ", FILE_NAME1);
            $finish();
        end else if (!fh2) begin
            $display("Error to open file: ", FILE_NAME2);
            $finish();
        end else if (!fh3) begin
            $display("Error to open file: ", FILE_NAME3);
            $finish();
        end else if (!fh4) begin
            $display("Error to open file: ", FILE_NAME4);
            $finish();
        end else begin
            // Keep reading lines until EOF is found
            while (! $feof(fh1)) begin
                @(posedge clk)
                    byte_data1_ = $fgetc(fh1);
                    $display("Data1: %h", byte_data1);
                    byte_data2_ = $fgetc(fh2);
                    $display("Data2: %h", byte_data2);
                    byte_data3_ = $fgetc(fh3);
                    $display("Data3: %h", byte_data3);
                    byte_data4_ = $fgetc(fh4);
                    $display("Data4: %h", byte_data4);
                    $display("EOF: %0d", !$feof(fh1));
            end
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