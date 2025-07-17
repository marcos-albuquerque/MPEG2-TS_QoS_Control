module mux_sync (  // Seleciona sinal de sincronização de um canal.
    input wire [3:0] sync,  // Sincronizações dos 4 canais.
    input wire [1:0] mux_ctrl,  // Controle de seleção.
    output reg sync_out  // Sincronização selecionada.
);
    always @(*) begin  // Bloco combinacional.
        case (mux_ctrl)  // Sempre seleciona.
            2'b00: sync_out = sync[0];  // Canal 1.
            2'b01: sync_out = sync[1];  // Canal 2.
            2'b10: sync_out = sync[2];  // Canal 3.
            2'b11: sync_out = sync[3];  // Canal 4.
            default: sync_out = 1'b0;  // Inválido: zera.
        endcase
    end
endmodule