module mux_valid ( //Seleção sinal de validação.
    input wire [3:0] valid,  // Validações dos 4 canais
    input wire [1:0] mux_ctrl,  // Controle de seleção
    input wire en_mux, 
    output reg valid_out  
);
    always @(*) begin  
        if (en_mux) begin  // Habilitado
            case (mux_ctrl)  
                2'b00: valid_out = valid[0];  // Canal 1
                2'b01: valid_out = valid[1];  // Canal 2
                2'b10: valid_out = valid[2];  // Canal 3
                2'b11: valid_out = valid[3];  // Canal 4
                default: valid_out = 1'b0;  // Default: zero
            endcase
        end else begin  // Desabilitado
            valid_out = 1'b0;  // Zera
        end
    end
endmodule