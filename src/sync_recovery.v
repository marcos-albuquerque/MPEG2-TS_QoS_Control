module sync_recovery(
    input clk, rst,
    input [7:0] byte_in,
    input byte_valid,
    output reg valid_packet,
    output reg [7:0] byte_out
);

    localparam IDLE = 0, CONTAGEM = 1, VERIFICACAO = 2, SYNC_FOUND = 3;
    localparam SYNC_BYTE = 8'h47, MAX_REPS = 8'd10;

    reg [1:0] state;
    reg [7:0] COUNT_BYTES;
    reg [7:0] COUNT_REPS;
    reg [7:0] buffer[187:0];

    always@(posedge clk or negedge rst) begin
        if (!rst) begin
            
        end else if (byte_valid) begin
            case (state)
                IDLE: begin
                    valid_packet <= 1'b0;
                    if (byte_in == SYNC_BYTE) begin
                        state = CONTAGEM;
                    end 
                end 
                    
                CONTAGEM: begin
                    if (COUNT_BYTES == 8'd187) begin
                        state = VERIFICACAO;
                    end
                end

                VERIFICACAO: begin
                    if (byte_in == SYNC_BYTE && COUNT_REPS < MAX_REPS) begin
                        state = CONTAGEM;
                    end else if (byte_in == SYNC_BYTE && COUNT_REPS == MAX_REPS) begin
                        state = SYNC_FOUND;
                        valid_packet <= 1'b1;
                    end else  begin
                        state = IDLE;
                        COUNT_REPS <= 4'd0;
                    end 
                end

                SYNC_FOUND: begin
                    state = CONTAGEM;
                end

                default: state = IDLE;
            endcase

        end
    end


    always@(posedge clk or negedge rst) begin
        case (state) 
            IDLE: begin
                COUNT_BYTES <= 1'b1;
                COUNT_REPS <= 4'd0;
            end

            CONTAGEM: begin
                COUNT_BYTES <= COUNT_BYTES + 1'b1;
            end

            VERIFICACAO: begin
                COUNT_BYTES <= 8'd0;
                COUNT_REPS <= COUNT_REPS + 1'b1;
            end

            SYNC_FOUND: begin
                COUNT_REPS <= 4'd0;
                COUNT_BYTES <= 8'd2;
            end
        endcase

        
    end

    always@(posedge clk) begin
        byte_out = byte_in;
    end

endmodule




module top_module_sync(
    input clk, rst,
    input [7:0] byte_1, byte_2, byte_3, byte_4,
    output [7:0] ts1, ts2, ts3, ts4,
    output valid_1, valid_2, valid_3, valid_4

);

    sync_module v1(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_1),
                    .byte_valid(1'b1),
                    .valid_packet(valid_1),
                    .byte_out(ts1)
    );

    sync_module v2(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_2),
                    .byte_valid(1'b1),
                    .valid_packet(valid_2),
                    .byte_out(ts2)
    );

    sync_module v3(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_3),
                    .byte_valid(1'b1),
                    .valid_packet(valid_3),
                    .byte_out(ts3)
    );

    sync_module v4(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_4),
                    .byte_valid(1'b1),
                    .valid_packet(valid_4),
                    .byte_out(ts4)
    );



endmodule