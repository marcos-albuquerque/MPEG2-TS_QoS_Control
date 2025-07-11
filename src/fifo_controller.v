/*
  fifo_controller
  Controle de escrita e leitura da async_fifo
  * @input wclk            - Clock de escrita.
  * @input wrst_n          - Reset assíncrono de escrita.
  * @input wdata           - Dados a serem escritos na FIFO.
  * 
  * @input rrst_n          - Reset assíncrono para o domínio de leitura.
  * @output rdata          - Dados lidos da FIFO.
*/

module fifo_controller #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
  ) (

    // Escrita (27 MHz)
    input                           wclk,
    input                           wrst_n,
    input      [DATA_WIDTH-1:0]     wdata,
    input                           valid_in,

    // Leitura (100 MHz)
    input                           rclk,
    input                           rrst_n,
    output [DATA_WIDTH-1:0]         rdata,
    output                          valid_out
  );

  wire                    fifo_wen;
  wire                    fifo_wfull;
  reg                     fifo_ren;
  wire                    fifo_rempty;
  wire [ADDR_WIDTH:0]     fifo_rcnt;
  reg                     read_flag; 

  parameter MIN_READ_THRESHOLD = 14;

  assign fifo_wen = valid_in && !fifo_wfull;
  assign valid_out = fifo_ren;


  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      read_flag <= 1'b0;
      fifo_ren <= 1'b0;
    end else begin
      if (fifo_rcnt == MIN_READ_THRESHOLD)
        read_flag <= 1'b1;
      else if (fifo_rcnt == 0) 
        read_flag <= 1'b0;  
      fifo_ren <= read_flag && !fifo_rempty;
    end
  end

  async_fifo #(
               .DATA_WIDTH(DATA_WIDTH),
               .ADDR_WIDTH(ADDR_WIDTH)
             ) async_fifo_inst (
               .wclk(wclk),
               .wrst_n(wrst_n),
               .wen(fifo_wen),
               .wdata(wdata),
               .wfull(fifo_wfull),

               .rclk(rclk),
               .rrst_n(rrst_n),
               .ren(fifo_ren),
               .rdata(rdata),
               .rempty(fifo_rempty),
               .rcnt(fifo_rcnt)
             );

endmodule
