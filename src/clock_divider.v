module clock_divider (  // Divisor de clock de 100MHz para ~25MHz (aproximação para 27MHz; divisão por 4).
    input wire rst,  // Reset assíncrono.
    input wire clk2,  // Clock entrada (100MHz).
    input wire [3:0] valid,  // Validações (habilita divisão se qualquer valid ativo).
    input wire [1:0] mux_ctrl,  // Controle (não usado, mantido pelo diagrama).
    output reg clk_out  // Clock saída (~25MHz para FIFO rclk).
);
    reg [1:0] counter;  // Contador pequeno para divisão por 4 (não óbvio: toggle a cada 2 ciclos pra 50% duty cycle).

    always @(posedge clk2 or posedge rst) begin  // Bloco sequencial.
        if (rst) begin
            counter <= 0;  // Zera contador.
            clk_out <= 0;  // Zera saída.
        end else if (|valid) begin  // Habilita só se valid ativo (OR bit a bit).
            counter <= counter + 1;  // Incrementa.
            if (counter == 3) begin  // Atinge 3: divide por 4.
                clk_out <= ~clk_out;  // Inverte pra gerar pulso (50% duty).
                counter <= 0;  // Reseta.
            end
        end
    end
endmodule