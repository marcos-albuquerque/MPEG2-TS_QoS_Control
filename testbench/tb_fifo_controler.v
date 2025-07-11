
module tb_fifo_controller;

  // Parameters
  localparam DATA_WIDTH = 8;
  localparam ADDR_WIDTH = 4;
  localparam DEPTH      = 1 << ADDR_WIDTH;

  //Ports
  reg wclk;
  reg wrst_n;
  reg [DATA_WIDTH-1:0] wdata;
  reg rclk;
  reg rrst_n;
  reg valid_in;
  wire [DATA_WIDTH-1:0] rdata;
  wire valid_out;

  //Sinais internos para teste
  wire        fifo_wen;
  wire        fifo_wfull;
  wire        fifo_ren;
  wire        fifo_rempty;


  //Sinais de referência para validação
  reg  [DATA_WIDTH-1:0] ref_mem [0:DEPTH-1];
  integer     read_count;
  integer     errors;


  fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_inst (
                    .wclk(wclk),
                    .wrst_n(wrst_n),
                    .wdata(wdata),
                    .valid_in(valid_in),
                    .rclk(rclk),
                    .rrst_n(rrst_n),
                    .rdata(rdata),
                    .valid_out(valid_out)
                  );

  // Atribuição de sinais internos
  assign fifo_wen   = fifo_controller_inst.fifo_wen;
  assign fifo_wfull = fifo_controller_inst.fifo_wfull;
  assign fifo_ren   = fifo_controller_inst.fifo_ren;
  assign fifo_rempty = fifo_controller_inst.fifo_rempty;

  // Geração do clock de escrita 27 MHz
  always #18.5 wclk = ~wclk;

  // Geração do clock de leitura  100 MHz
  always #5 rclk = ~rclk;

  integer i;


  initial
  begin
    $monitor("At time %0t Read: %b", $time,rdata);
    wclk <= 0;
    rclk <= 0;
    wrst_n <= 0;
    rrst_n <= 0;
    wdata <= 0;
    valid_in <= 0;
    read_count = 0;
    errors = 0;


    @(negedge wclk) wrst_n = 1;
    @(negedge rclk) rrst_n = 1;

    #100;

    // Teste 1: Escrita de dados
    $display("Teste 1: Escrita de dados na FIFO.");
    $display("----------------------------------------------");
    for (i = 0; i < DEPTH * 2; i = i + 1)
    begin
      @(posedge wclk);
      if (!fifo_wfull)
      begin
        wdata <= $random;
        valid_in <= 1;
        $display("Em %0t: Ecrito wdata= %b, wfull =%d",$time,wdata,fifo_wfull);
      end
      else
      begin
        $display("Em %0t: a FIFO está cheia, não foi possível escrever, wfull=%b",$time,fifo_wfull);
      end
    end
    @(posedge wclk) valid_in = 0;

    #500;

    $stop;

  end

endmodule
