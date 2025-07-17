module sync_recovery(
    input clk, rst,
    input [7:0] byte_in,
    input byte_valid,
    output reg sync,
    output valid,
    output reg [7:0] byte_out
);

    localparam IDLE = 0, CONTAGEM = 1, VERIFICACAO = 2, SYNC_FOUND = 3;
    localparam SYNC_BYTE = 8'h47, MAX_REPS = 8'd4;

    reg [1:0] state;
    reg [7:0] COUNT_BYTES;
    reg [7:0] COUNT_REPS;
    reg sync;

    always@(posedge clk or negedge rst) begin
        if (!rst) begin
            state = IDLE;
            valid <= 1'b0;
        end else if (byte_valid) begin
            valid <= 1'b1;
            byte_out <= byte_in;

            case (state)
                IDLE: begin
                    sync <= 1'b0;
                    sync <= 1'b0;
                    COUNT_BYTES <= 1'b1;
                    COUNT_REPS <= 8'd0;
                    if (byte_in == SYNC_BYTE) begin
                        state <= CONTAGEM;
                    end 
                end 
                    
                CONTAGEM: begin
                    sync <= 1'b0;
                    COUNT_BYTES <= COUNT_BYTES + 1'b1;
                    if (COUNT_BYTES == 8'd187) begin
                        state <= VERIFICACAO;
                    end
                end

                VERIFICACAO: begin
                    COUNT_BYTES <= 8'd1;
                    //COUNT_REPS <= COUNT_REPS + 1'b1;
                    if (byte_in == SYNC_BYTE && sync) sync <= 1'b1;
                    if (byte_in == SYNC_BYTE) begin
                        COUNT_REPS <= COUNT_REPS + 1'b1;
                    end else begin
                        COUNT_REPS <= 1'b0;
                    end
                    if (byte_in == SYNC_BYTE && COUNT_REPS < MAX_REPS) begin
                        state <= CONTAGEM;
                    end else if (byte_in == SYNC_BYTE && COUNT_REPS >= MAX_REPS) begin
                        state <= SYNC_FOUND;
                        $display(state);
                    end else  begin
                        state <= IDLE;
                    end 
                end

                SYNC_FOUND: begin
                    COUNT_REPS <= 4'd0;
                    COUNT_BYTES <= 8'd2;
                    sync <= 1'b1;
                    state <= CONTAGEM;
                end

                default: state <= IDLE;
            endcase
        end else valid <= 1'b0;
    end

endmodule




module top_module_sync(
    input clk, rst,
    input [7:0] byte_1, byte_2, byte_3, byte_4,
    output [7:0] ts1, ts2, ts3, ts4,
    output sync_1, sync_2, sync_3, sync_4,
    output valid_1, valid_2, valid_3, valid_4

);

    sync_recovery v1(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_1),
                    .byte_valid(valid_1),
                    .sync(sync_1),
                    .byte_out(ts1)
    );

    sync_recovery v2(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_2),
                    .byte_valid(valid_2),
                    .sync(sync_2),
                    .byte_out(ts2)
    );

    sync_recovery v3(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_3),
                    .byte_valid(valid_3),
                    .sync(sync_3),
                    .byte_out(ts3)
    );

    sync_recovery v4(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_4),
                    .byte_valid(valid_4),
                    .sync(sync_4),
                    .byte_out(ts4)
    );



endmodule