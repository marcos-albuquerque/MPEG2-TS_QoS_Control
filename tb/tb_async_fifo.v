`timescale 1ns / 1ps

module tb_async_fifo;

  localparam DATA_WIDTH = 8;
  localparam ADDR_WIDTH = 4;
  localparam DEPTH      = 1 << ADDR_WIDTH;

  reg                      wclk;
  reg                      wrst_n;
  reg                      wen;
  reg  [DATA_WIDTH-1:0]    wdata;
  wire                     wfull;

  reg                      rclk;
  reg                      rrst_n;
  reg                      ren;
  wire [DATA_WIDTH-1:0]    rdata;
  wire                     rempty;

  async_fifo #(
               .DATA_WIDTH(DATA_WIDTH),
               .ADDR_WIDTH(ADDR_WIDTH)
             ) async_fifo_inst (
               .wclk(wclk),
               .wrst_n(wrst_n),
               .wen(wen),
               .wdata(wdata),
               .wfull(wfull),

               .rclk(rclk),
               .rrst_n(rrst_n),
               .ren(ren),
               .rdata(rdata),
               .rempty(rempty)
             );

  // Geração do clock de escrita 27 MHz 
  always #18.5 wclk = ~wclk;

  // Geração do clock de leitura  100 MHz 
  always #5 rclk = ~rclk;


  integer i; 


  initial begin
        wclk <= 0;
        rclk <= 0;
        wrst_n <= 0; 
        rrst_n <= 0; 
        wen <= 0;
        ren <= 0;
        wdata <= 0;

        #100;

        wrst_n <= 1; 
        rrst_n <= 1; 

        #50; 

        wen <= 1;

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wclk); 
            wdata <= $random; 
            $display("At time %0t Wrote %b",$time,wdata);
        end

        @(posedge wclk); 
        wen <= 0;

        @(posedge rclk);

        ren <= 1;
        @(posedge rclk);
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge rclk);
            $display("At time %0t Read %b", $time, rdata, rempty);
        end

        @(posedge rclk);
        ren <= 0;

        #100;


    $stop;

  end

endmodule
