`timescale 1ns / 1ps

module i2c_slave_tb;

    // Inputs
	 reg clk;
    reg rst;
    reg scl;
    reg sda_in;

    // Bidirectional SDA line com alta-impedancia forcada em 1
    tri1 sda;

    // Outputs
    wire start;
	 
	 reg dados; // Armazenar os dados enviados pelo escravo 0: nao armazena, 1: armazena
	 reg [3:0] data_bit_counter; // Contador para os bits dos dados
	 reg [7:0] received_data;    // Registrador para armazenar os dados recebidos

    wire [7:0] data_out; // Dado recebido
	 reg [7:0] data_in;  // Dado a ser enviado pelo escravo
	 
	 wire data_ready;
	 wire ack_error;

    // Internal variables
    reg [7:0] master_data; // Mestre envia dados para o escravo
    reg [7:0] master_address = 8'b11010100; // Endereco do mestre (7 bits + bit R/W)
	 
	 reg sda_controle;
	 
	 integer negedge_detected;

    integer i;

    // Instanciar o escravo I2C
    i2c_slave uut (
	     .clk(clk),
        .reset(rst),
		  .scl(scl),
        .sda(sda),
        .data_out(data_out),
		  .data_in(data_in),
		  .data_ready(data_ready),
		  .ack_error(ack_error),
        .start(start)
    );

    // Controla a linha SDA
    assign sda = sda_controle ? 1'bz : sda_in;

    // Clock SCL
    always begin
        #100 scl = ~scl; // Frequencia do clock 5 MHz 
    end
	 
	 always begin
	     #5 clk = ~clk; // Frequencia do clock 100 MHz
    end

    initial begin
        // Inicializacao
        rst = 1;
		  clk = 1;
        scl = 0;
        master_data = 8'b10101010; // Dado a ser enviado para o escravo
		  data_in = 8'b11001100;     // Dado que o escravo devera enviar

		  dados = 0; 
		  data_bit_counter = 0;
		  received_data = 0;
		  
		  sda_controle = 0;
		  sda_in = 1;
		  
        // Libera o reset
        #15 rst = 0;

        // Simulacao do envio do endereco pelo mestre no modo escrita
        $display("Iniciando operacao de escrita...");

        // Enviar start condition (SDA vai de 1 para 0 com SCL = 1)
        @(posedge scl) #20 sda_in = 0;

        @(negedge scl);

        // Enviar endereco (7 bits + R/W = 0 para escrita)
        negedge_detected = 0; // Inicializar o sinal
 
        for (i = 7; i >= 0; i = i - 1) begin
            sda_in = master_address[i];
				
				// Aguardar uma das condicoes: borda de descida ou estado 2
				wait (uut.state == 2 || negedge_detected);

            // Resetar o sinal apos deteccao
            negedge_detected = 0;
        end

		  // Libera o barramento (espera ACK do escravo)
		  sda_controle = 1;
        
		  wait (uut.state == 3); 
		  
		  sda_controle = 0;

        // Enviar dados (8 bits)
		  negedge_detected = 0; // Inicializar o sinal
		  
        for (i = 7; i >= 0; i = i - 1) begin
            sda_in = master_data[i];
				
				// Aguardar uma das condicoes: borda de descida ou estado 2
				wait (uut.state == 2 || negedge_detected);

            // Resetar o sinal apos deteccao
            negedge_detected = 0;
        end

		  // Libera o barramento (espera ACK do escravo)
		  sda_controle = 1;
		  
		  wait (uut.state == 0)
		  
		  sda_controle = 0;

        // Enviar stop condition (SDA vai de 0 para 1 com SCL = 1)
        @(negedge scl) sda_in = 0;
        @(posedge scl) #20 sda_in = 1;
        
        #100;

        // Simulacao do envio do endereco pelo mestre no modo leitura
        $display("Iniciando operacao de leitura...");

        // Enviar start condition
        @(posedge scl) #20 sda_in = 0;
        @(negedge scl);

        // Enviar endereco (7 bits + R/W = 1 para leitura)
        master_address[0] = 1; // Configurar bit R/W para leitura
        
		  negedge_detected = 0; // Inicializar o sinal
		  
        for (i = 7; i >= 0; i = i - 1) begin
            sda_in = master_address[i];
				
				// Aguardar uma das condicoes: borda de descida ou estado 2
				wait (uut.state == 2 || negedge_detected);

            // Resetar o sinal apos deteccao
            negedge_detected = 0;
        end

        // Libera o barramento (espera ACK do escravo)
        sda_controle = 1;
		  
		  wait(uut.state == 4);
		  
		  dados = 1;
		  
        // Ler dados do escravo (8 bits)
        for (i = 7; i >= 0; i = i - 1) begin
            @(posedge scl);
            $display("Bit lido: %b", sda);
        end
		  
		  dados = 0;
		  
		  wait (uut.state == 5); 
		  
		  sda_controle = 0;

		  // Simula o mestre enviando ACK para o escravo
		  sda_in = 0;
		  sda_in = 0;

        // Enviar stop condition
        @(negedge scl) sda_in = 0;
        @(posedge scl) #20 sda_in = 1;
		  
        #50;

        $stop;
    end
	 
	 // Detectar a borda de descida de SCL
    always @(negedge scl) begin
        negedge_detected = 1;
    end
	 
	 // Armazenamento do dado recebido a cada borda de subida do SCL
    always @(posedge scl) begin
        if (data_bit_counter < 8 && dados) begin
            received_data[7 - data_bit_counter] <= sda; // Armazena o bit do endereco recebido
            data_bit_counter <= data_bit_counter + 1; // Incrementa o contador de bits do endereco
        end else if (data_bit_counter == 8) begin
            // Quando todos os 7 bits do endereco forem recebidos, faz a comparacao
            $display("Dado recebido: %h, esperado: %h", received_data, data_in);
            if (received_data == data_in) begin
                $display("Dado corretamente recebido.");
            end else begin
                $display("Erro na recepcao do dado.");
            end
            data_bit_counter <= 0; // Reseta o contador de bits do endereco
        end
    end


endmodule
