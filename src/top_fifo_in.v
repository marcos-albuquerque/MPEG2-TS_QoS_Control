/*
 * top_fifo
 * Combinação de 4 FIFO's assincronas 
 *
 * @input wclk                                           - Clock de escrita.
 * @input wrst_n                                         - Reset assíncrono de escrita.
 * @input wdata1,wdata2,wdata3,wdata4                    - Dados a serem escritos nas FIFO's.
 * @ouput valid1,valid2,valid3,valid4                    - Indica que o bit de saída é válido 
 * 
 * @input rrst_n                                         - Reset assíncrono para o domínio de leitura.
 * @output rdata1,rdata2,rdata3,rdata4                   - Dados lidos das FIFO's.
 * @output valid_out1,valid_out2,valid_out3,valid_out4   - Indica que o bit de saída é válido.
 * Autor: Jorge Ivan Augusto De Oliveira Filho
 */


module top_fifo_in #(
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
    output     [DATA_WIDTH-1:0]     rdata1,rdata2,rdata3,rdata4,
    output                          valid_out1,valid_out2,valid_out3,valid_out4
  );



  fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_inst1 (
                    .wclk(wclk),
                    .wrst_n(wrst_n),
                    .wdata(wdata1),
                    .valid_in(valid1),
                    .rclk(rclk),
                    .rrst_n(rrst_n),
                    .rdata(rdata1),
                    .valid_out(valid_out1)
                  );

  fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_inst2 (
                    .wclk(wclk),
                    .wrst_n(wrst_n),
                    .wdata(wdata2),
                    .valid_in(valid2),
                    .rclk(rclk),
                    .rrst_n(rrst_n),
                    .rdata(rdata2),
                    .valid_out(valid_out2)
                  );

  fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_inst3 (
                    .wclk(wclk),
                    .wrst_n(wrst_n),
                    .wdata(wdata3),
                    .valid_in(valid3),
                    .rclk(rclk),
                    .rrst_n(rrst_n),
                    .rdata(rdata3),
                    .valid_out(valid_out3)
                  );

  fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_inst4 (
                    .wclk(wclk),
                    .wrst_n(wrst_n),
                    .wdata(wdata4),
                    .valid_in(valid4),
                    .rclk(rclk),
                    .rrst_n(rrst_n),
                    .rdata(rdata4),
                    .valid_out(valid_out4)
                  );

endmodule
