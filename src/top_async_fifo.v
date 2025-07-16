module top_mux_fifo (  
    input wire rst,  
    input wire clk2,  // Clock 100MHz
    input wire [7:0] data_s1, data_s2, data_s3, data_s4, 
    input wire [3:0] valid_in,  // MUX e divider
    input wire [3:0] sync_in,  
    input wire [1:0] mux_ctrl,  
    input wire en_mux, 
    input wire r_en,  // Read enable FIFO (de downstream)
    output wire [9:0] data_out_final  // Saída final em 27MHz: [9:2]=DATA, [1]=VALID, [0]=SYNC
);

    wire [7:0] mux_data_out;  
    wire mux_valid_out;  
    wire mux_sync_out;  
    wire clk1;  // 27MHz do divider para rclk da FIFO
    wire [9:0] fifo_data_input;  // mux_data_out, mux_valid_out, mux_sync_out

  
    mux_data mux_data_inst (
        .data_s1(data_s1), .data_s2(data_s2), .data_s3(data_s3), .data_s4(data_s4),
        .mux_ctrl(mux_ctrl), .en_mux(en_mux), .data_out(mux_data_out)
    );

    mux_valid mux_valid_inst (
        .valid(valid_in), .mux_ctrl(mux_ctrl), .en_mux(en_mux), .valid_out(mux_valid_out)
    );

    mux_sync mux_sync_inst (
        .sync(sync_in), .mux_ctrl(mux_ctrl), .en_mux(en_mux), .sync_out(mux_sync_out)
    );

    // Clock Divider (gera clk1=27MHz)
    clock_divider divider_inst (
        .rst(rst), .clk2(clk2), .valid(valid_in), .mux_ctrl(mux_ctrl), .clk_out(clk1)
    );

    // Concatena saídas MUX para input da FIFO
    assign fifo_data_input = {mux_data_out, mux_valid_out, mux_sync_out};

    // FIFO
    fifo_async fifo_inst (
        .wclk(clk2),  // Escrita em 100MHz.
        .rclk(clk1),  // Leitura em 27MHz.
        .rst(rst),  
        .w_en(en_mux),  // Usa en_mux como w_en (assumindo que escreve quando MUX habilitado).
        .r_en(r_en),  // Ativo quando downstream pronto
        .data_input(fifo_data_input),  
        .data_out(data_out_final),  
        .full(fifo_full), .empty(fifo_empty)
    );

endmodule