module continuity_counter (
    input  wire        clk, // Sinal de clock, que sincroniza o funcionamento do circuito
    input  wire        rst, // Sinal de reset, que reinicia o circuito quando ativado 0
    input  wire        sync, // Sinal que indica o início de uma nova sequência de dados
    input  wire        valid, // Sinal que indica se o dado de entrada (data) é válido
    input  wire [7:0]  data, // Dado de entrada (onde chega o fluxo de dados)
    output reg  [7:0] error_count // Contador que eu vou entregar na saída 
);

    reg [3:0]  count;         // Contador de 4 bits que acompanha quantos bytes foram recebidos (de 0 a 15)
    reg [3:0]  last_count;     // Armazena o valor do contador de continuidade do último pacote processado
    reg [3:0]  current_data;  //  Armazena os 4 bits menos significativos do byte atual, que representam o contador de continuidade atual
   
    
    
    localparam IDLE=0, CONTAGEM=1, PROCESSAMENTO=2; // IDLE = Estado inicial, onde o circuito espera o sinal sync para começar
                                                    //  CONTAGEM = Estado onde o circuito conta bytes até o quarto byte
                                                    // PROCESSAMENTO = 
    reg [1:0]  estado; // Um registrador de 2 bits que indica o estado atual da máquina de estados


    always @(posedge clk or negedge rst) begin // define o que acontece a cada pulso de clock ou quando o reset é ativado
    I
        if (rst) begin // Tudo volta ao estado inicial.

            count        <= 4'd0; // é zerado (começa a contar bytes do zero)
            last_count    <= 4'd0; // é zerado (nenhum contador de continuidade anterior)
            error_count  <= 8'd0; // é zerado (nenhum erro registrado)
            estado       <= IDLE; // estado vai pra IDLE - o circuito volta ao estado inicial, esperando o sinal sync
        end else if (valid) begin
             case (estado)        // Seleciona a lógica com base no valor do registrador estado. Cada estado (IDLE, CONTAGEM, PROCESSAMENTO)
                IDLE: begin
                    if (sync==1) begin // indica o início de uma nova sequência de dados
                      count <= 0;
                      estado <= CONTAGEM; // Passa para o estado da maquina de estados chamado CONTAGEM
                    end  
                end
                CONTAGEM: begin
                    if (count==2) begin // verifica se eu contei até o quarto byte
                        current_data <= data [3:0]; // armazena o valor de continuidade atual que foi pego do byte atual
                        estado <= PROCESSAMENTO;
                    end

                    else 

                        count <= count + 1; // Incrementa o contador de bytes (count) em 1 a cada pulso de clock
                     
                end

                PROCESSAMENTO: begin
                    if (current_data != last_data +1) 
                    
                        count_error <= count_error + 1;
                        last_data <=  current_data;
                        
                

                        estado<= IDLE;

             

                    
                end

                default:estado <= IDLE;  // Caso o registrador estado tenha um valor inválido (não IDLE, CONTAGEM ou PROCESSAMENTO), a máquina de estados retorna ao estado IDLE
            endcase

        end

            
    end

endmodule
