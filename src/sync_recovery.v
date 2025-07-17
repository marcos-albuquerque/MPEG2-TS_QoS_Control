module sync_recovery(
    input clk, rst,
    input [7:0] byte_in,
    input byte_valid,
    output reg sync,
    output reg valid,
    output reg [7:0] byte_out
);

    localparam IDLE = 0, CONTAGEM = 1, VERIFICACAO = 2, SYNC_FOUND = 3;
    localparam SYNC_BYTE = 8'h47, MAX_REPS = 8'd255;

    reg [1:0] state;
    reg [7:0] count_bytes;
    reg [7:0] count_reps;
    reg flag;

    always@(posedge clk or negedge rst) begin
        if (!rst) begin
            state = IDLE;
            valid <= 1'b0;
            byte_out <= 1'b0;
            sync = 1'b0;
        end else if (byte_valid) begin
            valid <= 1'b1;
            byte_out <= byte_in;

            case (state)
                IDLE: begin
                    flag <= 1'b0;
                    count_bytes <= 1'b1;
                    count_reps <= 8'd0;
                    if (byte_in == SYNC_BYTE) begin
                        state <= CONTAGEM;
                    end 
                end 
                    
                CONTAGEM: begin
                    sync <= 1'b0;
                    count_bytes <= count_bytes + 1'b1;
                    if (count_bytes == 8'd187) begin
                        state <= VERIFICACAO;
                    end
                end

                VERIFICACAO: begin
                    if (byte_in == SYNC_BYTE) begin
                        count_bytes <= 8'd1;
                        count_reps <= count_reps + 1'b1;
                        if (flag) sync <= 1'b1;
                        if (count_reps < MAX_REPS) state <= CONTAGEM;
                        if (count_reps >= MAX_REPS) begin
                            if (!flag) state <= SYNC_FOUND;
                            if (flag) state <= CONTAGEM;
                        end 
                    end else begin
                        count_reps <= 1'b0;
                        state <= IDLE;
                    end
                end

                SYNC_FOUND: begin
                    count_reps <= 4'd0;
                    count_bytes <= 8'd2;
                    flag <= 1'b1;
                    state <= CONTAGEM;
                end

                default: state <= IDLE;
            endcase
        end else begin 
            valid <= 1'b0;
            byte_out <= 1'b0;
            sync <= 1'b0;
        end
    end
endmodule




module top_module_sync(
    input clk, rst,
    input [7:0] byte_1, byte_2, byte_3, byte_4,
    input byte_valid1, byte_valid2, byte_valid3, byte_valid4,
    output [7:0] ts1, ts2, ts3, ts4,
    output sync_1, sync_2, sync_3, sync_4,
    output valid_1, valid_2, valid_3, valid_4

);

    sync_recovery v1(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_1),
                    .byte_valid(byte_valid1),
                    .sync(sync_1),
                    .byte_out(ts1),
                    .valid(valid_1)
    );

    sync_recovery v2(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_2),
                    .byte_valid(byte_valid2),
                    .sync(sync_2),
                    .byte_out(ts2),
                    .valid(valid_2)
    );

    sync_recovery v3(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_3),
                    .byte_valid(byte_valid3),
                    .sync(sync_3),
                    .byte_out(ts3),
                    .valid(valid_3)
    );

    sync_recovery v4(
                    .clk(clk), 
                    .rst(rst),
                    .byte_in(byte_4),
                    .byte_valid(byte_valid4),
                    .sync(sync_4),
                    .byte_out(ts4),
                    .valid(valid_4)
    );



endmodule