module mux_valid (
    input  wire [3:0]  valid,
    input  wire [1:0]  mux_ctrl,
    input  wire        en_mux,
    output reg         valid_out
);
    always @(*) begin
        if (en_mux) begin
            case (mux_ctrl)
                2'b00: valid_out = valid[0];
                2'b01: valid_out = valid[1];
                2'b10: valid_out = valid[2];
                2'b11: valid_out = valid[3];
                default: valid_out = 1'b0;
            endcase
        end else begin
            valid_out = 1'b0;
        end
    end
endmodule