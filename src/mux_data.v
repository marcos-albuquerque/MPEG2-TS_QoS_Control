module mux_data (  // Seleciona dados de um canal baseado no controle.
    input wire [7:0] data_s1, data_s2, data_s3, data_s4,  // Dados dos 4 canais.
    input wire [1:0] mux_ctrl,  // Controle de seleção (2 bits).
    output reg [7:0] data_out  // Dados selecionados (para FIFO).
);
    always @(*) begin  // Bloco combinacional, executa em qualquer mudança.
        case (mux_ctrl)  // Seleciona com base em mux_ctrl (sempre ativo agora).
            2'b00: data_out = data_s1;  // Canal 1 (default inicial).
            2'b01: data_out = data_s2;  // Canal 2.
            2'b10: data_out = data_s3;  // Canal 3.
            2'b11: data_out = data_s4;  // Canal 4.
            default: data_out = 8'b0;  // Caso inválido: zera para segurança.
        endcase
    end
endmodule