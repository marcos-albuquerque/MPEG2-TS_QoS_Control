module mux #(
    parameter DATA_WIDTH
)(  // Seleciona dados de um canal baseado no controle.
    input  [DATA_WIDTH-1:0] in_1,
    input  [DATA_WIDTH-1:0] in_2,
    input  [DATA_WIDTH-1:0] in_3,
    input  [DATA_WIDTH-1:0] in_4, 
    input  [1:0] mux_ctrl,  // Controle de seleção (2 bits).
    output [DATA_WIDTH-1:0] out  // Dados selecionados (para FIFO).
);
    always @(*) begin  // Bloco combinacional, executa em qualquer mudança.
        case (mux_ctrl)  // Seleciona com base em mux_ctrl (sempre ativo agora).
            2'b00: out = in_1;  // Canal 1 (default inicial).
            2'b01: out = in_2;  // Canal 2.
            2'b10: out = in_3;  // Canal 3.
            2'b11: out = in_4;  // Canal 4.
            default: out = 8'b0;  // Caso inválido: zera para segurança.
        endcase
    end
endmodule