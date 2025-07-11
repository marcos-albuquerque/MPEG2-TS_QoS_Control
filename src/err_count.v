module contador_mpeg2 (

    input wire clk,
    input wire rst,
    input wire [7:0]  r_data1,  // Byte 1: sync byte (deve ser 0x47)
    input wire [15:0] timer_in,
    input wire        sync,

    output reg [7:0] cc_expected,  // contador de continuidade esperado
);

 

    reg [15:0] timer;

    wire [3:0] cc_received;

    wire sync_byte_ok;

 

    assign cc_received = r_data4[3:0];  // os 4 bits menos significativos de r_data4

    assign sync_byte_ok = (r_data1 == 8'h47); // verifica byte de sincronização

 

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            cc_expected <= 4'd0;

            timer <= 16'd0;

            valid <= 1'b0;

            sync <= 1'b0;

        end else begin

            timer <= timer + 1'b1;

 

            if (timer >= timer_in) begin

                timer <= 16'd0;

 

                if (sync_byte_ok) begin

                    sync <= 1'b1;

                    valid <= (cc_received == cc_expected);  // true se continuidade está correta

 

                    cc_expected <= cc_expected + 1'b1;  // incremento cíclico de 4 bits

                    if (cc_expected == 4'd15)

                        cc_expected <= 4'd0;

                end else begin

                    sync <= 1'b0;

                    valid <= 1'b0;

                end

            end else begin

                sync <= 1'b0;

                valid <= 1'b0;

            end

        end

    end

 

endmodule



`timescale 1ns / 1ps

module contador_mpeg2_tb;

    // Declaração dos sinais
    reg clk;
    reg rst;
    reg [7:0] r_data1;
    reg [7:0] r_data2;
    reg [7:0] r_data3;
    reg [7:0] r_data4;
    reg [15:0] timer_in;
    wire [3:0] cc_expected;
    wire valid;
    wire sync;

    // Instanciação do módulo sob teste
    contador_mpeg2 dut (
        .clk(clk),
        .rst(rst),
        .r_data1(r_data1),
        .r_data2(r_data2),
        .r_data3(r_data3),
        .r_data4(r_data4),
        .timer_in(timer_in),
        .cc_expected(cc_expected),
        .valid(valid),
        .sync(sync)
    );

    // Geração do clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Período de clock de 10ns
    end

    // Procedimento de teste
    initial begin
        // Inicialização
        rst = 1;
        r_data1 = 8'h00;
        r_data2 = 8'h00;
        r_data3 = 8'h00;
        r_data4 = 8'h00;
        timer_in = 16'd10; // Timer de 10 ciclos
        #20;
        
        // Libera reset
        rst = 0;
        #20;

        // Teste 1: Sync byte correto, sequência de CC correta
        $display("Teste 1: Sync byte correto, sequência de CC correta");
        r_data1 = 8'h47; // Sync byte correto
        r_data2 = 8'h1F;
        r_data3 = 8'hFF;
        r_data4 = 8'h00; // CC = 0
        #100; // Espera timer expirar algumas vezes
        
        r_data4 = 8'h01; // CC = 1
        #100;
        
        r_data4 = 8'h02; // CC = 2
        #100;
        
        r_data4 = 8'h03; // CC = 3
        #100;

        // Teste 2: Sync byte incorreto
        $display("Teste 2: Sync byte incorreto");
        r_data1 = 8'h46; // Sync byte errado
        r_data4 = 8'h04;
        #100;

        // Teste 3: Volta para sync byte correto
        $display("Teste 3: Volta para sync byte correto");
        r_data1 = 8'h47;
        r_data4 = 8'h04; // CC = 4
        #100;

        // Teste 4: Teste de reset
        $display("Teste 4: Reset durante operação");
        rst = 1;
        #20;
        rst = 0;
        r_data1 = 8'h47;
        r_data4 = 8'h00; // CC deve começar do 0 novamente
        #100;

        // Teste 5: Teste de continuidade com salto (erro)
        $display("Teste 5: Erro de continuidade");
        r_data4 = 8'h02; // Pula CC = 1
        #100;

        // Teste 6: Teste de overflow do CC
        $display("Teste 6: Teste de overflow do CC");
        r_data4 = 8'h0F; // CC = 15
        #100;
        r_data4 = 8'h00; // CC = 0 (deve ser válido após overflow)
        #100;

        // Finaliza simulação
        $display("Fim da simulação");
        $finish;
    end

    // Monitoramento
    initial begin
        $monitor("Time=%0t rst=%b r_data1=%h r_data4=%h cc_expected=%h valid=%b sync=%b",
                 $time, rst, r_data1, r_data4, cc_expected, valid, sync);
    end

endmodule