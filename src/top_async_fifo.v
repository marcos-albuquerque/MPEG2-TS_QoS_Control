/*
 * top_fifo
 * Combinação de 4 FIFO's assincronas que utiliza código gray
 *
 * @input wclk            - Clock de escrita.
 * @input wrst_n          - Reset assíncrono de escrita.
 * @input wen             - Habilita a escrita de dados.
 * @input wdata           - Dados a serem escritos na FIFO.
 * @ouput wfull           - Indica que a FIFO está cheia 
 * 
 * @input rrst_n          - Reset assíncrono para o domínio de leitura.
 * @input ren             - Habilita a leitura de dados.
 * @output rdata          - Dados lidos da FIFO.
 * @output rempty         - Indica que a FIFO está vazia.
 */


module top_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
  ) (
    // Escrita (27 MHz)
    input                           wclk,
    input                           wrst_n,
    input      [DATA_WIDTH-1:0]     wdata1,wdata2,wdata3,wdata4,
    input                           valid1,valid2,valid3,valid4,

    // Leitura (100 MHz)
    input                           rclk,
    input                           rrst_n,
    output reg [DATA_WIDTH-1:0]     rdata1,rdata2,rdata3,rdata4,
  );

  fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_inst1 (
                    .wclk(wclk),
                    .wrst_n(wrst_n),
                    .wdata(wdata1),
                    .valid(valid1),
                    .rclk(rclk),
                    .rrst_n(rrst_n),
                    .rdata(rdata1)
                  );

  fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_inst1 (
                    .wclk(wclk),
                    .wrst_n(wrst_n),
                    .wdata(wdata2),
                    .valid(valid2),
                    .rclk(rclk),
                    .rrst_n(rrst_n),
                    .rdata(rdata2)
                  );

  fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_inst1 (
                    .wclk(wclk),
                    .wrst_n(wrst_n),
                    .wdata(wdata3),
                    .valid(valid3),
                    .rclk(rclk),
                    .rrst_n(rrst_n),
                    .rdata(rdata3)
                  );

  fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_inst1 (
                    .wclk(wclk),
                    .wrst_n(wrst_n),
                    .wdata(wdata4),
                    .valid(valid4),
                    .rclk(rclk),
                    .rrst_n(rrst_n),
                    .rdata(rdata4)
                  );




endmodule
