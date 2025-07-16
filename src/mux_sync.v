module mux_sync (  // Seleção sinal de sincronização
    input wire [3:0] sync,  
    input wire [1:0] mux_ctrl,  
    input wire en_mux,  
    output reg sync_out 
);
    always @(*) begin  
        if (en_mux) begin  // Habilitado
            case (mux_ctrl)  
                2'b00: sync_out = sync[0];  // Canal 1
                2'b01: sync_out = sync[1];  // Canal 2
                2'b10: sync_out = sync[2];  // Canal 3
                2'b11: sync_out = sync[3];  // Canal 4
                default: sync_out = 1'b0;  // Default
            endcase
        end else begin  // Desabilitado
            sync_out = 1'b0;  // Zera saída.
        end
    end
endmodule