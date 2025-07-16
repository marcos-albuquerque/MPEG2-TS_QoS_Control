module mux_data (  
    input wire [7:0] data_s1,  
    input wire [7:0] data_s2,  
    input wire [7:0] data_s3,  
    input wire [7:0] data_s4,  
    input wire [1:0] mux_ctrl,  // Controle de seleção
    input wire en_mux,  // Habilitação do MUX
    output reg [7:0] data_out  
);
    always @(*) begin  
        if (en_mux) begin  // Se habilitado, seleciona:
            case (mux_ctrl)  
                2'b00: data_out = data_s1;  // Canal 1
                2'b01: data_out = data_s2;  // Canal 2
                2'b10: data_out = data_s3;  // Canal 3
                2'b11: data_out = data_s4;  // Canal 4
                default: data_out = 8'b0;  // Default: zero
            endcase
        end else begin  // Se desabilitado, zera
            data_out = 8'b0;  
        end
    end
endmodule