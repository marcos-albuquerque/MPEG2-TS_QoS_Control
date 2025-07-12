`timescale 1ns/1ps

module testbench();
  localparam real DATA_FREQUENCY = 100e6;
  localparam real SYS_FREQUENCY = 27e6;       
  localparam FILE_NAME1 = "tsdata1_loss.ts";
  localparam FILE_NAME2 = "tsdata2_loss.ts";
  localparam FILE_NAME3 = "tsdata3_loss.ts";
  localparam FILE_NAME4 = "tsdata4_loss.ts";
  localparam DATA_WIDTH = 8;
  localparam ADDR_WIDTH = 4;

  reg reset_n;
  wire wclk;
  wire rclk;
  wire [DATA_WIDTH-1:0] byte_data1;
  wire [DATA_WIDTH-1:0] byte_data2;
  wire [DATA_WIDTH-1:0] byte_data3;
  wire [DATA_WIDTH-1:0] byte_data4;

  wire [DATA_WIDTH-1:0] rdata1;
  wire [DATA_WIDTH-1:0] rdata2;
  wire [DATA_WIDTH-1:0] rdata3;
  wire [DATA_WIDTH-1:0] rdata4;

  integer fd_out1;
  integer fd_out2;
  integer fd_out3;
  integer fd_out4;

  wire valid_out1, valid_out2, valid_out3, valid_out4;


  top_fifo # (
              .DATA_WIDTH(DATA_WIDTH),
              .ADDR_WIDTH(ADDR_WIDTH)
            )
            top_fifo_inst (
              .wclk(wclk),
              .wrst_n(reset_n),
              .wdata1(byte_data1),
              .wdata2(byte_data2),
              .wdata3(byte_data3),
              .wdata4(byte_data4),
              .valid1(1'b1), 
              .valid2(1'b1),
              .valid3(1'b1),
              .valid4(1'b1),
              .rclk(rclk),
              .rrst_n(reset_n),
              .rdata1(rdata1),
              .rdata2(rdata2),
              .rdata3(rdata3),
              .rdata4(rdata4),
              .valid_out1(valid_out1),
              .valid_out2(valid_out2),
              .valid_out3(valid_out3),
              .valid_out4(valid_out4)
            );

  clock_generator #(SYS_FREQUENCY) CLOCK_W(.clk(wclk));
  clock_generator #(DATA_FREQUENCY) CLOCK_R(.clk(rclk));

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
    reset_n = 1'b0;
    #100;
    reset_n = 1'b1;

    // Abrir arquivos
    fd_out1 = $fopen("rdata_out1.txt", "w");
    fd_out2 = $fopen("rdata_out2.txt", "w");
    fd_out3 = $fopen("rdata_out3.txt", "w");
    fd_out4 = $fopen("rdata_out4.txt", "w");

    if (fd_out1 == 0 || fd_out2 == 0 || fd_out3 == 0 || fd_out4 == 0) begin
        $error("Error!");
        $stop;
    end

  #1000000;
    

    if (fd_out1 != 0) $fclose(fd_out1);
    if (fd_out2 != 0) $fclose(fd_out2);
    if (fd_out3 != 0) $fclose(fd_out3);
    if (fd_out4 != 0) $fclose(fd_out4);

    $stop; 
  end

  always @(posedge rclk) begin
    if (reset_n) begin //
      if (valid_out1) begin
        $fwrite(fd_out1, "%b\n", rdata1);
      end
      if (valid_out2) begin
        $fwrite(fd_out2, "%b\n", rdata2);
      end
      if (valid_out3) begin
        $fwrite(fd_out3, "%b\n", rdata3);
      end
      if (valid_out4) begin
        $fwrite(fd_out4, "%b\n", rdata4);
      end
    end
  end

endmodule
