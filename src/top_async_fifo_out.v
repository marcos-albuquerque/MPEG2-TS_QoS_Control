module top_mux_fifo_out(  // Top: Conecta MUXs, Divider, FIFO e Main Control.
    input wire rst, clk2,  // Reset e clock principal (100MHz).
    input wire [7:0] data_s1, data_s2, data_s3, data_s4,  // Dados canais.
    input wire [3:0] valid_in, sync_in,  // Validações e sincronizações.
    input wire [31:0] err_count,  // De Packet Loss Counter (para main_control).
    input wire r_en,  // Read enable FIFO.
    output wire [9:0] data_out_final  // Saída final em ~27MHz.
);

    wire [1:0] mux_ctrl;  // De main_control para MUXs.
    wire [7:0] mux_data_out;  // Saída MUX DATA.
    wire mux_valid_out, mux_sync_out;  // Saídas VALID/SYNC.
    wire clk1;  // ~27MHz do divider para rclk da FIFO.
    wire [9:0] fifo_data_input = {mux_data_out, mux_valid_out, mux_sync_out};  // Concatenado para FIFO.
    wire fifo_full, fifo_empty;  // Flags (não usados aqui, mas disponíveis).

    // Main Control (gera mux_ctrl).
    main_control main_inst (
        .clk(clk2), .rst(rst), .err_count(err_count), .mux_ctrl(mux_ctrl)
    );

    // MUXs (sempre ativos).
    mux_data mux_data_inst (
        .data_s1(data_s1), .data_s2(data_s2), .data_s3(data_s3), .data_s4(data_s4),
        .mux_ctrl(mux_ctrl), .data_out(mux_data_out)
    );
    mux_valid mux_valid_inst (
        .valid(valid_in), .mux_ctrl(mux_ctrl), .valid_out(mux_valid_out)
    );
    mux_sync mux_sync_inst (
        .sync(sync_in), .mux_ctrl(mux_ctrl), .sync_out(mux_sync_out)
    );

    // Clock Divider (gera clk1 ~27MHz).
    clock_divider divider_inst (
        .rst(rst), .clk2(clk2), .valid(valid_in), .mux_ctrl(mux_ctrl), .clk_out(clk1)
    );

    // FIFO (w_en sempre 1, já que MUX sempre ativo).
    fifo_async fifo_inst (
        .wclk(clk2), .rclk(clk1), .rst(rst),
        .w_en(1'b1),  // Sempre escreve (não óbvio: substitui en_mux removido, assume fluxo contínuo).
        .r_en(r_en),
        .data_input(fifo_data_input),
        .data_out(data_out_final),
        .full(fifo_full), .empty(fifo_empty)
    );
endmodule