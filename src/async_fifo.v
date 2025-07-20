/*
 * fifo_controller
 * Controle de leitura e escrita de FIFO assincrona
 *
 * @input wclk            - Clock de escrita.
 * @input wrst_n          - Reset assíncrono de escrita.
 * @input wdata           - Dados a serem escritos na FIFO.
 * @input valid_in        - Indica que o dado de entrada é válido
 * 
 * @input rclk            - Clock de leitura.
 * @input rrst_n          - Reset assíncrono para o domínio de leitura.
 * @output rdata          - Dados lidos da FIFO.
 * @output valid_out      - Indica que o dado de saída é válido
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

  // --- Estados para controle de leitura ---
  localparam IDLE = 2'b00;
  localparam READING = 2'b01;
  localparam VALID = 2'b10;

  reg [1:0] current_state;
  reg [1:0] next_state;
  
  // --- Registros de saída ---
  reg                         valid_out_reg;
  reg        [DATA_WIDTH-1:0] rdata_reg;
  reg                         pending_read;

  // --- Lógica de Controle de Escrita ---
  assign fifo_wen = valid_in && !fifo_wfull;

  // --- Controle de leitura da FIFO ---
  assign fifo_ren = (current_state == IDLE && !fifo_rempty) || 
                    (current_state == VALID && !fifo_rempty);

  // --- Lógica de Saída ---
  assign rdata = rdata_reg;
  assign valid_out = valid_out_reg;

  // --- Máquina de Estados para Controle de Leitura ---
  always @(*)
  begin
    next_state = current_state;
    case (current_state)
      IDLE: begin
        if (!fifo_rempty)
          next_state = READING;
      end
      
      READING: begin
        next_state = VALID;
      end
      
      VALID: begin
        if (fifo_rempty)
          next_state = IDLE;
        else
          next_state = READING; 
      end
    endcase
  end

  always @(posedge rclk or negedge rrst_n)
  begin
    if (!rrst_n)
    begin
      current_state <= IDLE;
      valid_out_reg <= 1'b0;
      rdata_reg     <= {DATA_WIDTH{1'b0}};
    end
    else
    begin
      current_state <= next_state;
      case (current_state)
        IDLE: begin
          valid_out_reg <= 1'b0;
        end
        
        READING: begin
          valid_out_reg <= 1'b0;
        end
        
        VALID: begin
          rdata_reg     <= fifo_rdata;
          valid_out_reg <= 1'b1;
        end
      endcase
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
