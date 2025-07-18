/*
 * fifo_controller
 * FIFO assincrona que utiliza código gray
 *
 * @input wclk            - Clock de escrita.
 * @input wrst_n          - Reset assíncrono de escrita.
 * @input wen             - Habilita a escrita de dados.
 * @input wdata           - Dados a serem escritos na FIFO.
 * @output valid_in       - Indica que o bit de entrada é válido
 * 
 * @input rrst_n          - Reset assíncrono para o domínio de leitura.
 * @input ren             - Habilita a leitura de dados.
 * @output rdata          - Dados lidos da FIFO.
 * @output valid_out      - Indica que o bit de saída é válido
 * Autor: Jorge Ivan Augusto De Oliveira Filho
 */

module fifo_controller #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
  ) (

    // Escrita (27 MHz)
    input                       wclk,
    input                       wrst_n,
    input      [DATA_WIDTH-1:0] wdata,
    input                       valid_in,

    // Leitura (100 MHz)
    input                       rclk,
    input                       rrst_n,
    output     [DATA_WIDTH-1:0] rdata,
    output                      valid_out
  );

  // --- Sinais de interface com a FIFO ---
  wire                        fifo_wen;
  wire                        fifo_wfull;
  wire                        fifo_ren; 
  wire                        fifo_rempty;
  wire       [DATA_WIDTH-1:0] fifo_rdata;

  // --- Lógica de Controle ---
  assign fifo_wen = valid_in;

  assign fifo_ren = !fifo_rempty;

  reg           valid_out_reg;
  reg [DATA_WIDTH-1:0]  rdata_reg;

  assign rdata = rdata_reg;
  assign valid_out = valid_out_reg;

  always @(posedge rclk or negedge rrst_n)
  begin
    if (!rrst_n)
    begin
      valid_out_reg <= 1'b0;
      rdata_reg     <= {DATA_WIDTH{1'b0}};
    end
    else
    begin
      if (fifo_ren)
      begin
        rdata_reg     <= fifo_rdata;
        valid_out_reg <= 1'b1;
      end
      else
      begin
        valid_out_reg <= 1'b0;
      end
    end
  end

  async_fifo #(
               .DATA_WIDTH(DATA_WIDTH),
               .ADDR_WIDTH(ADDR_WIDTH)
             ) async_fifo_inst (
               .rdata(fifo_rdata),
               .wfull(fifo_wfull),
               .rempty(fifo_rempty),
               .wdata(wdata),
               .wen(fifo_wen),
               .wclk(wclk),
               .wrst_n(wrst_n),
               .ren(fifo_ren),
               .rclk(rclk),
               .rrst_n(rrst_n)
             );

endmodule
