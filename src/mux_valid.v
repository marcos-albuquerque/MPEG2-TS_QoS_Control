module mux_valid (  // Seleciona sinal de validação de um canal.
    input wire [3:0] valid,  // Validações dos 4 canais (valid[0]=canal1, etc.).
    input wire [1:0] mux_ctrl,  // Controle de seleção.
    output reg valid_out  // Validação selecionada.
);
    always @(*) begin  // Bloco combinacional.
        case (mux_ctrl)  // Sempre seleciona baseado em mux_ctrl.
            2'b00: valid_out = valid[0];  // Canal 1.
            2'b01: valid_out = valid[1];  // Canal 2.
            2'b10: valid_out = valid[2];  // Canal 3.
            2'b11: valid_out = valid[3];  // Canal 4.
            default: valid_out = 1'b0;  // Inválido: zera.
        endcase
    end
endmodule