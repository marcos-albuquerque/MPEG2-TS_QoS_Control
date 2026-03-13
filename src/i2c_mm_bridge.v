/*
 * Bridge entre o escravo I2C e a interface memory-mapped.
 * Protocolo esperado:
 *   write: SLA+W, reg_addr, data[31:24], data[23:16], data[15:8], data[7:0]
 *   read : SLA+W, reg_addr, repeated START, SLA+R, leitura de 4 bytes
 */

module i2c_mm_bridge(

    input clk,
    input rstn,

    // Interface com i2c_slave
    input [7:0] data_out,
    input       data_ready,
    input       rw,           // 0 = master write, 1 = master read
    input       txn_start,
    input       tx_byte_done,

    output reg [7:0] data_in,
    output reg       tx_data_valid,

    // Interface memory-mapped
    output reg [7:0]  mm_addr,
    output reg [31:0] mm_wdata,
    input      [31:0] mm_rdata,

    output reg mm_write_en,
    output reg mm_read_en

);

localparam [2:0] IDLE        = 3'd0;
localparam [2:0] WAIT_CMD    = 3'd1;
localparam [2:0] WRITE_BYTES = 3'd2;
localparam [2:0] READ_REQ    = 3'd3;
localparam [2:0] READ_WAIT   = 3'd4;
localparam [2:0] READ_LATCH  = 3'd5;
localparam [2:0] READ_STREAM = 3'd6;

reg [2:0]  state;
reg [1:0]  byte_cnt;
reg [31:0] write_buffer;
reg [31:0] read_buffer;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        state         <= IDLE;
        byte_cnt      <= 2'd0;
        write_buffer  <= 32'h0000_0000;
        read_buffer   <= 32'h0000_0000;
        data_in       <= 8'h00;
        tx_data_valid <= 1'b0;
        mm_addr       <= 8'h00;
        mm_wdata      <= 32'h0000_0000;
        mm_write_en   <= 1'b0;
        mm_read_en    <= 1'b0;
    end else begin
        mm_write_en   <= 1'b0;
        mm_read_en    <= 1'b0;
        tx_data_valid <= 1'b0;

        case (state)
            IDLE: begin
                byte_cnt <= 2'd0;
                if (data_ready && (rw == 1'b0)) begin
                    mm_addr <= data_out;
                    state   <= WAIT_CMD;
                end
            end

            WAIT_CMD: begin
                if (txn_start && (rw == 1'b1)) begin
                    state <= READ_REQ;
                end else if (txn_start && (rw == 1'b0)) begin
                    byte_cnt <= 2'd0;
                    state    <= IDLE;
                end else if (data_ready && (rw == 1'b0)) begin
                    write_buffer <= {24'h000000, data_out};
                    byte_cnt     <= 2'd1;
                    state        <= WRITE_BYTES;
                end
            end

            WRITE_BYTES: begin
                if (txn_start) begin
                    byte_cnt <= 2'd0;
                    state    <= IDLE;
                end else
                if (data_ready && (rw == 1'b0)) begin
                    write_buffer <= {write_buffer[23:0], data_out};

                    if (byte_cnt == 2'd3) begin
                        mm_wdata    <= {write_buffer[23:0], data_out};
                        mm_write_en <= 1'b1;
                        byte_cnt    <= 2'd0;
                        state       <= IDLE;
                    end else begin
                        byte_cnt <= byte_cnt + 2'd1;
                    end
                end
            end

            READ_REQ: begin
                mm_read_en <= 1'b1;
                state      <= READ_WAIT;
            end

            READ_WAIT: begin
                state <= READ_LATCH;
            end

            READ_LATCH: begin
                read_buffer   <= mm_rdata;
                data_in       <= mm_rdata[31:24];
                tx_data_valid <= 1'b1;
                byte_cnt      <= 2'd0;
                state         <= READ_STREAM;
            end

            READ_STREAM: begin
                tx_data_valid <= 1'b1;

                if (txn_start) begin
                    byte_cnt <= 2'd0;
                    state    <= IDLE;
                end else if (tx_byte_done) begin
                    case (byte_cnt)
                        2'd0: begin
                            data_in  <= read_buffer[23:16];
                            byte_cnt <= 2'd1;
                        end

                        2'd1: begin
                            data_in  <= read_buffer[15:8];
                            byte_cnt <= 2'd2;
                        end

                        2'd2: begin
                            data_in  <= read_buffer[7:0];
                            byte_cnt <= 2'd3;
                        end

                        default: begin
                            byte_cnt <= 2'd0;
                            state    <= IDLE;
                        end
                    endcase
                end
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule
