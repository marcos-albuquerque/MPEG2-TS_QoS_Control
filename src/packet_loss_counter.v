
module packet_loss_counter (
    input  clk,
    input  reset_n,
    input  valid,
    input  sync,
    input  en_reset_counter,
    input  [7:0] ts_data,
    output [7:0] error_count
);
    localparam IDLE         = 0,
               COUNT        = 1,
               PROCESSING   = 2;

    reg [1:0] state;
    reg [1:0] byte_counter;
    reg [1:0] adaption_field_ctrl;
    reg [3:0] previous_cc;          // previous continuity counter (cc)
    reg [3:0] current_cc;           // current cc
    reg firt_cc_flag;               // flag to indicate first cc

    // output reg
    reg [7:0] error_count_;
    assign error_count = error_count_;

    always @(posedge clk, negedge reset_n, posedge en_reset_counter) begin
        if (!reset_n || en_reset_counter) begin
            state <= 0;
            byte_counter <= 0;
            adaption_field_ctrl <= 0;
            previous_cc <= 0;
            current_cc <= 0;
            firt_cc_flag <= 1;
            error_count_ <= 0;
        end else if (valid) begin
            case (state)
                IDLE: begin
                    if (sync) begin
                        state <= COUNT;
                        byte_counter <= 0;
                    end
                end
                COUNT: begin
                    if (byte_counter == 2) begin
                        current_cc <= ts_data[3:0];
                        adaption_field_ctrl <= ts_data[5:4];
                        byte_counter <= 0;
                        state <= PROCESSING;
                    end else begin
                        byte_counter <= byte_counter + 1;
                    end
                end
                PROCESSING: begin
                    // The continuity_counter shall not be incremented when 
                    // the adaptation_field_control of the packet equals '00' or '10'
                    if ((adaption_field_ctrl == 2'b00) || (adaption_field_ctrl == 2'b10)) begin
                        byte_counter <= 0;
                    end else if (!firt_cc_flag) begin
                        if (current_cc == previous_cc + 1) begin
                            byte_counter <= 0;
                        end else begin 
                            error_count_ = error_count_ + 1;
                        end
                        previous_cc <= current_cc;
                    end else begin
                        previous_cc <= current_cc;
                        firt_cc_flag <= 0;
                    end
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
