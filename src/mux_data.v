module mux_data (
    input  wire [7:0]  data_s1,
    input  wire [7:0]  data_s2,
    input  wire [7:0]  data_s3,
    input  wire [7:0]  data_s4,
    input  wire [1:0]  mux_ctrl,
    input  wire        en_mux,
    output reg  [7:0]  data_out
);
    always @(*) begin
        if (en_mux) begin
            case (mux_ctrl)
                2'b00: data_out = data_s1;
                2'b01: data_out = data_s2;
                2'b10: data_out = data_s3;
                2'b11: data_out = data_s4;
                default: data_out = 8'b0;
            endcase
        end else begin
            data_out = 8'b0;
        end
    end
endmodule