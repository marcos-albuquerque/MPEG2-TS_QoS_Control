/*
 * async_fifo
 * FIFO assincrona que utiliza código gray
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
 * Autor: Jorge Ivan Augusto De Oliveira Filho
 */

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
  ) (
    // Escrita (27 MHz)
    input                           wclk,
    input                           wrst_n,
    input                           wen,
    input      [DATA_WIDTH-1:0]     wdata,
    output reg                      wfull,

    // Leitura (100 MHz)
    input                           rclk,
    input                           rrst_n,
    input                           ren,
    output     [DATA_WIDTH-1:0]     rdata,
    output reg                      rempty
  );

  localparam DEPTH = 1 << ADDR_WIDTH;

  // Ponteiros de escrita
  reg [ADDR_WIDTH:0] wptr_bin;
  wire [ADDR_WIDTH:0] wptr_bin_next;
  reg [ADDR_WIDTH:0] wptr_gray;
  wire [ADDR_WIDTH:0] wptr_gray_next;
  wire [ADDR_WIDTH-1:0] waddr;

  //Ponteiros de sincronização de leitura para domínio de escrita
  reg [ADDR_WIDTH:0] rsync_r2w_ptr1,rsync_r2w_ptr2;

  //Sinais de controle da escrita
  wire we;
  wire wfull_val;

  reg  [ADDR_WIDTH:0] rptr_bin;
  wire [ADDR_WIDTH:0] rptr_bin_next;
  reg [ADDR_WIDTH:0] rptr_gray;
  wire [ADDR_WIDTH:0] rptr_gray_next;
  wire [ADDR_WIDTH-1:0] raddr;

  wire rempty_val;

  //Ponteiros de sincronização de leitura para domínio de escrita
  reg [ADDR_WIDTH:0] wsync_w2r_ptr1;
  reg [ADDR_WIDTH:0] wsync_w2r_ptr2;

  // Memória da FIFO
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // --- Lógica de Escrita ---
  assign we = !wfull && wen;
  assign waddr = wptr_bin[ADDR_WIDTH-1:0];
  assign wptr_bin_next = wptr_bin + we;
  assign wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;

  assign wfull_val = (wptr_gray_next == {~rsync_r2w_ptr2[ADDR_WIDTH:ADDR_WIDTH-1],
                                         rsync_r2w_ptr2[ADDR_WIDTH-2:0]});

  wire re; 
  assign re = !rempty && ren;
  assign raddr = rptr_bin[ADDR_WIDTH-1:0];
  assign rptr_bin_next = rptr_bin + re;
  assign rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next;

  assign rempty_val = (rptr_gray_next == wsync_w2r_ptr2);

  //---- Escrita  -----//

  always @(posedge wclk)
  begin
    if (we)
    begin
      mem[waddr] <= wdata;
    end
  end

  always @(posedge wclk or negedge wrst_n)
  begin
    if (!wrst_n)
    begin
      rsync_r2w_ptr2 <= 0;
      rsync_r2w_ptr1 <= 0;
    end
    else
    begin
      rsync_r2w_ptr2 <= rsync_r2w_ptr1;
      rsync_r2w_ptr1 <= rptr_gray;
    end
  end

  always @(posedge wclk or negedge wrst_n)
  begin
    if (!wrst_n)
    begin
      wptr_bin  <= 0;
      wptr_gray <= 0;
    end
    else
    begin
      wptr_bin  <= wptr_bin_next;
      wptr_gray <= wptr_gray_next;
    end
  end

  always @(posedge wclk or negedge wrst_n)
  begin
    if (!wrst_n)
    begin
      wfull <= 1'b0;
    end
    else
    begin
      wfull <= wfull_val;
    end
  end

  //---- Leitura -----//
  reg [DATA_WIDTH-1:0] rdata_reg;
  assign rdata = rdata_reg;

  always @(posedge rclk or negedge rrst_n)
  begin
    if (!rrst_n)
    begin
      rdata_reg <= {DATA_WIDTH{1'b0}};
    end
    else if (re)
    begin
      rdata_reg <= mem[raddr];
    end
  end

  always @(posedge rclk or negedge rrst_n)
  begin
    if (!rrst_n)
    begin
      wsync_w2r_ptr2 <= 0;
      wsync_w2r_ptr1 <= 0;
    end
    else
    begin
      wsync_w2r_ptr2 <= wsync_w2r_ptr1;
      wsync_w2r_ptr1 <= wptr_gray;
    end
  end

  always @(posedge rclk or negedge rrst_n)
  begin
    if (!rrst_n)
    begin
      rptr_bin  <= 0;
      rptr_gray <= 0;
    end
    else
    begin
      rptr_bin  <= rptr_bin_next;
      rptr_gray <= rptr_gray_next;
    end
  end

  always @(posedge rclk or negedge rrst_n)
  begin
    if (!rrst_n)
    begin
      rempty <= 1'b1;
    end
    else
    begin
      rempty <= rempty_val;
    end
  end

endmodule
