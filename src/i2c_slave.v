`timescale 1ns / 1ps

module i2c_slave (
    input  wire       clk,
    input  wire       rstn,
    input  wire       scl,
    inout  wire       sda,
    output reg  [7:0] data_out,
    input  wire [7:0] data_in,
    input  wire       tx_data_valid,
    output reg        data_ready,
    output reg        rw,          // 0 = master write, 1 = master read
    output reg        ack_error,
    output reg        start,
    output reg        txn_start,
    output reg        tx_byte_done
);

    localparam [6:0] ADDRESS = 7'h6A; // 7'b110_1010

    localparam [3:0] IDLE      = 4'd0;
    localparam [3:0] ADDR      = 4'd1;
    localparam [3:0] ADDR_ACK0 = 4'd2;
    localparam [3:0] ADDR_ACK1 = 4'd3;
    localparam [3:0] RX_BYTE   = 4'd4;
    localparam [3:0] RX_ACK0   = 4'd5;
    localparam [3:0] RX_ACK1   = 4'd6;
    localparam [3:0] WAIT_TX   = 4'd7;
    localparam [3:0] TX_BYTE   = 4'd8;
    localparam [3:0] TX_ACK    = 4'd9;

    reg [3:0] state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    reg [7:0] tx_shift;
    reg       sda_drive_low;
    reg       addr_match;
    reg       ack_sample;
    reg       tx_wait;

    reg scl_meta;
    reg scl_sync;
    reg scl_prev;
    reg sda_meta;
    reg sda_sync;
    reg sda_prev;

    wire scl_rise;
    wire scl_fall;
    wire sda_rise;
    wire sda_fall;
    wire start_cond;
    wire stop_cond;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;

    assign scl_rise  =  scl_sync & ~scl_prev;
    assign scl_fall  = ~scl_sync &  scl_prev;
    assign sda_rise  =  sda_sync & ~sda_prev;
    assign sda_fall  = ~sda_sync &  sda_prev;
    assign start_cond = sda_fall & scl_sync;
    assign stop_cond  = sda_rise & scl_sync;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            scl_meta <= 1'b1;
            scl_sync <= 1'b1;
            scl_prev <= 1'b1;
            sda_meta <= 1'b1;
            sda_sync <= 1'b1;
            sda_prev <= 1'b1;
        end else begin
            scl_meta <= scl;
            scl_prev <= scl_sync;
            scl_sync <= scl_meta;

            sda_meta <= sda;
            sda_prev <= sda_sync;
            sda_sync <= sda_meta;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state        <= IDLE;
            bit_count    <= 3'd7;
            shift_reg    <= 8'h00;
            tx_shift     <= 8'h00;
            data_out     <= 8'h00;
            data_ready   <= 1'b0;
            rw           <= 1'b0;
            ack_error    <= 1'b0;
            start        <= 1'b0;
            txn_start    <= 1'b0;
            tx_byte_done <= 1'b0;
            sda_drive_low <= 1'b0;
            addr_match   <= 1'b0;
            ack_sample   <= 1'b1;
            tx_wait      <= 1'b0;
        end else begin
            data_ready   <= 1'b0;
            txn_start    <= 1'b0;
            tx_byte_done <= 1'b0;

            if (start_cond) begin
                state         <= ADDR;
                bit_count     <= 3'd7;
                sda_drive_low <= 1'b0;
                addr_match    <= 1'b0;
                ack_error     <= 1'b0;
                tx_wait       <= 1'b0;
                start         <= 1'b1;
            end else if (stop_cond) begin
                state         <= IDLE;
                bit_count     <= 3'd7;
                sda_drive_low <= 1'b0;
                tx_wait       <= 1'b0;
                start         <= 1'b0;
            end else begin
                case (state)
                    IDLE: begin
                        bit_count     <= 3'd7;
                        sda_drive_low <= 1'b0;
                    end

                    ADDR: begin
                        sda_drive_low <= 1'b0;
                        if (scl_rise) begin
                            shift_reg[bit_count] <= sda_sync;
                            if (bit_count == 3'd0) begin
                                addr_match <= (shift_reg[7:1] == ADDRESS);
                                rw         <= sda_sync;
                                bit_count  <= 3'd7;
                                state      <= ADDR_ACK0;
                            end else begin
                                bit_count <= bit_count - 3'd1;
                            end
                        end
                    end

                    ADDR_ACK0: begin
                        if (scl_fall) begin
                            sda_drive_low <= addr_match;
                            state         <= ADDR_ACK1;
                        end
                    end

                    ADDR_ACK1: begin
                        if (scl_fall) begin
                            sda_drive_low <= 1'b0;
                            if (addr_match) begin
                                txn_start <= 1'b1;
                                if (rw == 1'b0) begin
                                    state <= RX_BYTE;
                                end else begin
                                    tx_wait <= 1'b1;
                                    state   <= WAIT_TX;
                                end
                            end else begin
                                state <= IDLE;
                            end
                        end
                    end

                    RX_BYTE: begin
                        sda_drive_low <= 1'b0;
                        if (scl_rise) begin
                            shift_reg[bit_count] <= sda_sync;
                            if (bit_count == 3'd0) begin
                                data_out   <= {shift_reg[7:1], sda_sync};
                                data_ready <= 1'b1;
                                bit_count  <= 3'd7;
                                state      <= RX_ACK0;
                            end else begin
                                bit_count <= bit_count - 3'd1;
                            end
                        end
                    end

                    RX_ACK0: begin
                        if (scl_fall) begin
                            sda_drive_low <= 1'b1;
                            state         <= RX_ACK1;
                        end
                    end

                    RX_ACK1: begin
                        if (scl_fall) begin
                            sda_drive_low <= 1'b0;
                            state         <= RX_BYTE;
                        end
                    end

                    WAIT_TX: begin
                        sda_drive_low <= 1'b0;
                        if (tx_wait) begin
                            tx_wait <= 1'b0;
                        end else if (tx_data_valid) begin
                            tx_shift      <= data_in;
                            bit_count     <= 3'd7;
                            sda_drive_low <= ~data_in[7];
                            state         <= TX_BYTE;
                        end
                    end

                    TX_BYTE: begin
                        if (scl_fall) begin
                            if (bit_count == 3'd0) begin
                                sda_drive_low <= 1'b0;
                                state         <= TX_ACK;
                            end else begin
                                bit_count     <= bit_count - 3'd1;
                                sda_drive_low <= ~tx_shift[bit_count - 3'd1];
                            end
                        end
                    end

                    TX_ACK: begin
                        sda_drive_low <= 1'b0;
                        if (scl_rise) begin
                            ack_sample <= sda_sync;
                            ack_error  <= sda_sync;
                        end

                        if (scl_fall) begin
                            if (ack_sample == 1'b0) begin
                                tx_byte_done <= 1'b1;
                                tx_wait      <= 1'b1;
                                state        <= WAIT_TX;
                            end else begin
                                state <= IDLE;
                            end
                        end
                    end

                    default: begin
                        state         <= IDLE;
                        sda_drive_low <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule
