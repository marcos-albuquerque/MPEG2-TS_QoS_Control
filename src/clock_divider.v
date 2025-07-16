module clock_divider ( 
    input wire rst,  // Reset assíncrono.
    input wire clk2,  // Clock entrada (100MHz).
    input wire [3:0] valid,  // Validações (habilita divisão se qualquer valid ativo).
    input wire [1:0] mux_ctrl,  // Controle (não usado aqui, mas mantido pelo diagrama).
    output reg clk_out  // Clock saída (~27MHz para FIFO read clock).
);
    reg [6:0] counter;  // Contador maior para divisão aproximada

    always @(posedge clk2 or posedge rst) begin  // Bloco sequencial
        if (rst) begin  
            counter <= 0;  
            clk_out <= 0;  
        end else if (|valid) begin  // Habilita se qualquer valid ativo
            counter <= counter + 1;  
            if (counter == 3) begin  // Divide por ~3.7 
                clk_out <= ~clk_out;  // Inverte para pulso
                counter <= 0;  
            end
        end
    end
endmodule