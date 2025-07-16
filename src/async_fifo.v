module fifo_async (  // FIFO assíncrona para sincronizar saídas MUX para 27MHz.
    parameter DATA_WIDTH = 10,  
    parameter FIFO_DEPTH = 4,  
    parameter ADDR_WIDTH = 2   
) (
    input wire wclk,  // Clock escrita 
    input wire rclk,  // Clock leitura
    input wire rst,  
    input wire w_en,  // Write enable (pode vir de en_mux ou valid_out)
    input wire r_en,  // Read enable (ativo quando downstream pronto)
    input wire [DATA_WIDTH-1:0] data_input,  
    output reg [DATA_WIDTH-1:0] data_out,  // [9:2]=DATA, [1]=VALID, [0]=SYNC
    output wire full,  // FIFO cheia
    output wire empty  // FIFO vazia
)
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];  
    reg [ADDR_WIDTH:0] w_ptr_bin, r_ptr_bin;  
    reg [ADDR_WIDTH:0] w_ptr_gray, r_ptr_gray;  

   
    reg [ADDR_WIDTH:0] w_ptr_gray_sync1, w_ptr_gray_sync2;  // w_ptr sync para rclk
    reg [ADDR_WIDTH:0] r_ptr_gray_sync1, r_ptr_gray_sync2;  // r_ptr sync para wclk

    // Binário para Gray
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Escrita
    always @(posedge wclk or posedge rst) begin
        if (rst) begin
            w_ptr_bin <= 0;
            w_ptr_gray <= 0;
        end else if (w_en && !full) begin
            mem[w_ptr_bin[ADDR_WIDTH-1:0]] <= data_input;
            w_ptr_bin <= w_ptr_bin + 1;
            w_ptr_gray <= bin_to_gray(w_ptr_bin + 1);
        end
    end

    // Leitura
    always @(posedge rclk or posedge rst) begin
        if (rst) begin
            r_ptr_bin <= 0;
            r_ptr_gray <= 0;
            data_out <= 0;
        end else if (r_en && !empty) begin
            data_out <= mem[r_ptr_bin[ADDR_WIDTH-1:0]];
            r_ptr_bin <= r_ptr_bin + 1;
            r_ptr_gray <= bin_to_gray(r_ptr_bin + 1);
        end
    end

    // Sync w_ptr para rclk
    always @(posedge rclk or posedge rst) begin
        if (rst) begin
            w_ptr_gray_sync1 <= 0;
            w_ptr_gray_sync2 <= 0;
        end else begin
            w_ptr_gray_sync1 <= w_ptr_gray;
            w_ptr_gray_sync2 <= w_ptr_gray_sync1;
        end
    end

    // Sync r_ptr para wclk
    always @(posedge wclk or posedge rst) begin
        if (rst) begin
            r_ptr_gray_sync1 <= 0;
            r_ptr_gray_sync2 <= 0;
        end else begin
            r_ptr_gray_sync1 <= r_ptr_gray;
            r_ptr_gray_sync2 <= r_ptr_gray_sync1;
        end
    end

   
    assign empty = (r_ptr_gray == w_ptr_gray_sync2);
    assign full = (w_ptr_gray == {~r_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], r_ptr_gray_sync2[ADDR_WIDTH-2:0]});
endmodule