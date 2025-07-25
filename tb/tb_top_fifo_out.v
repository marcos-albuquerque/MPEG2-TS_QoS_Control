`timescale 1ns/1ps

module tb_top_fifo_out();
  localparam real SYS_FREQUENCY = 108e6;
  localparam real DATA_FREQUENCY = 27e6; 
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

  wire [7:0] ts_data_out; // [9] valid, [8] sync, [7:0] ts_data
  wire       valid_out;
  wire       sync_out;
  wire [3:0] valid;

  integer fd_out1;
  integer fd_out2;
  integer fd_out3;
  integer fd_out4;

  reg [1:0] mux_ctrl;
  wire [3:0] sync;
  assign sync[0] = (byte_data1 == 8'h47) ? 1'b1 : 1'b0;
  assign sync[1] = (byte_data2 == 8'h47) ? 1'b1 : 1'b0;
  assign sync[2] = (byte_data3 == 8'h47) ? 1'b1 : 1'b0;
  assign sync[3] = (byte_data4 == 8'h47) ? 1'b1 : 1'b0;

  top_fifo_out # (
              .DATA_WIDTH(9),
              .ADDR_WIDTH(4)
            )
            top_fifo_out_inst (
              .rstn(reset_n),
              .wclk(wclk),
              .rclk(rclk),
              .mux_ctrl(mux_ctrl),
              .data_s1(byte_data1),
              .data_s2(byte_data2),
              .data_s3(byte_data3),
              .data_s4(byte_data4),
              .valid_in(valid),
              .sync_in(sync),
              .data_out_final({valid_out,sync_out,ts_data_out})
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
                        .clk(rclk),
                        .rstn(reset_n),
                        .valid(valid),
                        .byte_data1(byte_data1),
                        .byte_data2(byte_data2),
                        .byte_data3(byte_data3),
                        .byte_data4(byte_data4)
                      );

  initial begin
    mux_ctrl = 0;
    forever begin
        #200;
        mux_ctrl = ($random % 3 + 3) % 3; // gera numeros de 0 a 3 (00 a 11);
    end
  end
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

endmodule
