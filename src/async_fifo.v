module fifo_async #(  // FIFO para sincronizar saídas MUX para ~27MHz.
    parameter DATA_WIDTH = 10,  // [9:2]=DATA, [1]=VALID, [0]=SYNC.
    parameter FIFO_DEPTH = 4,  // Profundidade.
    parameter ADDR_WIDTH = 2  // log2(DEPTH).
) (
    input wire wclk, rclk, rst, w_en, r_en,
    input wire [DATA_WIDTH-1:0] data_input,
    output reg [DATA_WIDTH-1:0] data_out,
    output wire full, empty
);
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];  // Memória array.
    reg [ADDR_WIDTH:0] w_ptr_bin, r_ptr_bin;  // Ponteiros binários (extra bit para full/empty).
    reg [ADDR_WIDTH:0] w_ptr_gray, r_ptr_gray;  // Gray para sincronização.

    reg [ADDR_WIDTH:0] w_ptr_gray_sync1, w_ptr_gray_sync2;  // Sync w_ptr para rclk (2 DFFs reduzem metaestabilidade).
    reg [ADDR_WIDTH:0] r_ptr_gray_sync1, r_ptr_gray_sync2;  // Sync r_ptr para wclk.

    function [ADDR_WIDTH:0] bin_to_gray;  // Função Gray (XOR com shift pra evitar glitches em cross-clock).
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    always @(posedge wclk or posedge rst) begin  // Escrita.
        if (rst) {w_ptr_bin, w_ptr_gray} <= 0;
        else if (w_en && !full) begin  // Escreve se não cheia.
            mem[w_ptr_bin[ADDR_WIDTH-1:0]] <= data_input;
            w_ptr_bin <= w_ptr_bin + 1;
            w_ptr_gray <= bin_to_gray(w_ptr_bin + 1);
        end
    end

    always @(posedge rclk or posedge rst) begin  // Leitura.
        if (rst) {r_ptr_bin, r_ptr_gray, data_out} <= 0;
        else if (r_en && !empty) begin  // Lê se não vazia.
            data_out <= mem[r_ptr_bin[ADDR_WIDTH-1:0]];
            r_ptr_bin <= r_ptr_bin + 1;
            r_ptr_gray <= bin_to_gray(r_ptr_bin + 1);
        end
    end

    always @(posedge rclk or posedge rst) begin  // Sync w_ptr.
        if (rst) {w_ptr_gray_sync1, w_ptr_gray_sync2} <= 0;
        else {w_ptr_gray_sync2, w_ptr_gray_sync1} <= {w_ptr_gray_sync1, w_ptr_gray};
    end

    always @(posedge wclk or posedge rst) begin  // Sync r_ptr.
        if (rst) {r_ptr_gray_sync1, r_ptr_gray_sync2} <= 0;
        else {r_ptr_gray_sync2, r_ptr_gray_sync1} <= {r_ptr_gray_sync1, r_ptr_gray};
    end

    assign empty = (r_ptr_gray == w_ptr_gray_sync2);  // Empty: pointers iguais.
    assign full = (w_ptr_gray == {~r_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], r_ptr_gray_sync2[ADDR_WIDTH-2:0]});  // Full: Gray invertido (detecta wrap-around).
endmodule