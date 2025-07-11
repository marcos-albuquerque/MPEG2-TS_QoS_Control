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
 * @output rcnt           - Indica quants escritas foram feitas
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
    output reg [DATA_WIDTH-1:0]     rdata,
    output reg                      rempty,
    output wire [ADDR_WIDTH:0]      rcnt
  );

  localparam DEPTH = 1 << ADDR_WIDTH;

  // Ponteiros de escrita
  reg [ADDR_WIDTH:0] wptr_bin;
  reg [ADDR_WIDTH:0] wptr_bin_next;
  reg [ADDR_WIDTH:0] wptr_gray;
  reg [ADDR_WIDTH:0] wptr_gray_next;
  reg [ADDR_WIDTH-1:0] waddr;

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

  assign we = !wfull && wen  ;
  assign waddr = wptr_bin[ADDR_WIDTH-1:0];
  assign wptr_bin_next = wptr_bin + we;
  assign wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;


  assign wfull_val = (wptr_gray_next == {~rsync_r2w_ptr2[ADDR_WIDTH:ADDR_WIDTH-1],
                                         rsync_r2w_ptr2[ADDR_WIDTH-2:0]});

  assign re = !rempty && ren ;
  assign raddr = rptr_bin[ADDR_WIDTH-1:0];
  assign rptr_bin_next = rptr_bin + re;
  assign rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next;

  assign rempty_val = (rptr_gray == wsync_w2r_ptr2);

  //---- Lógica escrita -----//

  // Escrita na memória
  always @(posedge wclk)
  begin
    if (we)
    begin
      mem[waddr] <= wdata;
    end
  end

  // Sincronização Leitura -> Escrita
  always @(posedge wclk or negedge wrst_n)
  begin
    if (!wrst_n)
    begin
      {rsync_r2w_ptr2, rsync_r2w_ptr1} <= 0;
    end
    else
    begin
      {rsync_r2w_ptr2, rsync_r2w_ptr1} <= {rsync_r2w_ptr1,rptr_gray};
    end
  end

  // Atualização dos ponteiros de escrita
  always @(posedge wclk or negedge wrst_n)
  begin
    if (!wrst_n)
    begin
      wptr_bin  <= 0;
      wptr_gray <= 0; // Ponteiro Gray atual de escrita
    end
    else
    begin
      wptr_bin  <= wptr_bin_next;
      wptr_gray <= wptr_gray_next;
    end
  end

  // Atualização do sinal wfull
  always @(posedge wclk or negedge wrst_n)
  begin
    if (!wrst_n)
    begin
      wfull <= 0;
    end
    else
    begin
      wfull <= wfull_val;
    end
  end


  //---- Lógica leitura -----//

  //Contagem de elementos na FIFO
  reg [ADDR_WIDTH:0] wsync_w2r_ptr_bin;
  assign wsync_w2r_ptr_bin[ADDR_WIDTH] = wsync_w2r_ptr2[ADDR_WIDTH];
  genvar i;
  generate
    for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1)
    begin
      assign wsync_w2r_ptr_bin[i] = wsync_w2r_ptr_bin[i+1] ^ wsync_w2r_ptr2[i];
    end
  endgenerate

  assign rcnt = wsync_w2r_ptr_bin - rptr_bin;


  // Leitura da memória
  always @(posedge rclk or negedge rrst_n)
  begin
    if (!rrst_n)
    begin
      rdata <= {DATA_WIDTH{1'b0}};
    end
    else if (re)
    begin
      rdata <= mem[raddr];
    end
  end

  // Sincronização Escrita -> Leitura
  always @(posedge rclk or negedge rrst_n)
  begin
    if (!rrst_n)
    begin
      {wsync_w2r_ptr2, wsync_w2r_ptr1} <= 0;
    end
    else
    begin
      {wsync_w2r_ptr2, wsync_w2r_ptr1} <= {wsync_w2r_ptr1,wptr_gray};
    end
  end

  // Atualização dos ponteiros de leitura
  always @(posedge rclk or negedge rrst_n)
  begin
    if (!rrst_n)
    begin
      rptr_bin  <= 0;
      rptr_gray <= 0; // Ponteiro Gray atual de leitura
    end
    else
    begin
      rptr_bin  <= rptr_bin_next;
      rptr_gray <= rptr_gray_next;
    end
  end

  // Atualização da saída rempty
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
