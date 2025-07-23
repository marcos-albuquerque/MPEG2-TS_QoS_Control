module top_fifo_out #(
    parameter DATA_WIDTH = 9, // [8] sync and [7:0] ts_data
    parameter ADDR_WIDTH = 4
  ) (  // Top: Conecta MUXs, Divider, FIFO e Main Control.
    input        rstn,
    input        wclk,
    input        rclk,  // Reset, clk2(27MHz) e clk2(108MHz).
    input  [1:0] mux_ctrl,
    input  [7:0] data_s1,
    input  [7:0] data_s2,
    input  [7:0] data_s3,
    input  [7:0] data_s4,  // Dados canais.
    input  [3:0] valid_in,
    input  [3:0] sync_in,  // Validações e sincronizações.
    output valid_out,
    output [DATA_WIDTH-1:0] data_out_final  // Saída final em ~27MHz.
);

    wire [7:0] mux_data_out;  // Saída MUX DATA.
    wire mux_valid_out, mux_sync_out;  // Saídas VALID/SYNC.

    // MUXs (sempre ativos).
    mux #(
        .DATA_WIDTH(8)
    ) mux_data_inst (
        .in_1(data_s1),
        .in_2(data_s2), 
        .in_3(data_s3), 
        .in_4(data_s4),
        .mux_ctrl(mux_ctrl), 
        .out(mux_data_out)
    );

    mux #(
        .DATA_WIDTH(1)
    ) mux_valid_inst (
        .in_1(valid_in[0]),
        .in_2(valid_in[1]), 
        .in_3(valid_in[2]), 
        .in_4(valid_in[3]),
        .mux_ctrl(mux_ctrl), 
        .out(mux_valid_out)
    );

    mux #(
        .DATA_WIDTH(1)
    ) mux_sync_inst (
        .in_1(sync_in[0]),
        .in_2(sync_in[1]), 
        .in_3(sync_in[2]), 
        .in_4(sync_in[3]),
        .mux_ctrl(mux_ctrl), 
        .out(mux_sync_out)
    );

    fifo_controller # (
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH)
                  )
                  fifo_controller_out (
                    .wclk(wclk),
                    .wrst_n(rstn),
                    .wdata({mux_sync_out,mux_data_out}),
                    .valid_in(mux_valid_out),
                    .rclk(rclk),
                    .rrst_n(rstn),
                    .rdata(data_out_final),
                    .valid_out(valid_out)
                  );
endmodule