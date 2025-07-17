module top_continuity_counter(
    input  clk,
    input  reset_n,
    input  valid[3:0],
    input  sync[3:0],
    input  en_reset_counter,
    input  [7:0] data0,
    input  [7:0] data1,
    input  [7:0] data2,
    input  [7:0] data3,
    output [31:0] error_count
  );


  // Instancia dos 4 módulos CC para fazer a contagem
  // de continuidade dos pacotes

  packet_loss_counter counter_unit1 (
                        .clk(clk),
                        .reset_n(reset_n),
                        .valid(valid[0]),
                        .sync(sync[0]),
                        .en_reset_counter(en_reset_counter),
                        .data(data0),
                        .error_count(error_count[7:0])
                      );

  packet_loss_counter counter_unit2 (
                        .clk(clk),
                        .reset_n(reset_n),
                        .valid(valid[1]),
                        .sync(sync[1]),
                        .en_reset_counter(en_reset_counter),
                        .data(data1),
                        .error_count(error_count[15:8])
                      );
  packet_loss_counter counter_unit3 (
                        .clk(clk),
                        .reset_n(reset_n),
                        .valid(valid[2]),
                        .sync(sync[2]),
                        .en_reset_counter(en_reset_counter),
                        .data(data2),
                        .error_count(error_count[23:16])
                      );
  packet_loss_counter counter_unit4 (
                        .clk(clk),
                        .reset_n(reset_n),
                        .valid(valid[3]),
                        .sync(sync[3]),
                        .en_reset_counter(en_reset_counter),
                        .data(data3),
                        .error_count(error_count[31:24])
                      );

endmodule
