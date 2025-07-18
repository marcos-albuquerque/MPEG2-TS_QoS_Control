module clock_divider (  // Divisor de clock de 100MHz para ~25MHz (aproximação para 27MHz; divisão por 4).
    input wire rstn,  // Reset assíncrono.
    input wire clk2,  // Clock entrada (100MHz).
    output reg clk_out  // Clock saída (~25MHz para FIFO rclk).
);
    reg [1:0] counter;  // Contador pequeno para divisão por 4 (não óbvio: toggle a cada 2 ciclos pra 50% duty cycle).

    always @(posedge clk2 or negedge rstn) begin  // Bloco sequencial.
        if (!rstn) begin
            counter <= 0;  // Zera contador.
            clk_out <= 0;  // Zera saída.
        end else begin
            counter <= counter + 1;  // Incrementa.
            if (counter == 2) begin  // Atinge 2: divide por 4.
                clk_out <= ~clk_out;  // Inverte pra gerar pulso (50% duty).
                counter <= 0;  // Reseta.
            end
        end
    end
endmodule