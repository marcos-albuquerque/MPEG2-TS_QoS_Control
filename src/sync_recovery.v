module sync_recovery(
    input clk, rst,
    input [7:0] byte_in,
    input byte_valid,
    output reg sync,
    output reg valid,
    output reg [7:0] byte_out
);

    localparam IDLE = 0, CONTAGEM = 1, VERIFICACAO = 2, SYNC_FOUND = 3;
    localparam SYNC_BYTE = 8'h47, MAX_REPS = 8'd125;

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
            flag <= 1'b0;
        end else if (byte_valid) begin
            valid <= byte_valid;
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
            sync <= 1'b0;
        end
    end
endmodule
