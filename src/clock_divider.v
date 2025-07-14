module clock_divider (
    input  wire        rst,
    input  wire        clk2,
    input  wire [3:0]  valid,
    input  wire [1:0]  mux_ctrl,
    output reg         clk_out
);
    reg [3:0] counter;

    always @(posedge clk2 or posedge rst) begin
        if (rst) begin
            counter <= 0;
            clk_out <= 0;
        end else if (|valid) begin // Divide por 4 (100MHz -> 25MHz, ajuste para 27MHz pode precisar de fator diferente)
                counter <= counter + 1;
                if (counter == 3) begin
                    clk_out <= ~clk_out;
                    counter <= 0;
                end
            end
    end
endmodule


