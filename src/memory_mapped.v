/*
 * memory_mapped
 * The Memory_mapped module is responsible for receiving parameters for the internal functions of main_control 
 * and providing information about its internal state.
 *
 * @input  clk              - System clock
 * @input  rstn             - Negative system reset
 * @input  mm_write_en      - Signal enable writing in memory mapped
 * @input  mm_read_en       - Signal enable reading in memory mapped
 * @input  mm_addr          - Address memory
 * @input  mm_wdata         - Data write
 * @output mm_rdata         - Data read
 *
 * @output fallback_enable  - Enable fall back
 * @output manual_enable    - Enable manual mode
 * @output manual_channel   - Channel if manual mode is on
 * @output channel_priority - Choose priority channel
 * @output reset_timer      - Internal timer
 *
 * @input active_channel    - Channel selected by main control
 * @input signal_present    - Signal present per channel
 * @input error_count_ch0   - Channel 1 packet loss counter
 * @input error_count_ch1   - Channel 2 packet loss counter
 * @input error_count_ch2   - Channel 3 packet loss counter
 * @input error_count_ch3   - Channel 4 packet loss counter
 *
 * Author: Matheus do Nascimento Santos
 */

module memory_mapped (
    input              clk,
    input              rstn,

    // Memory-mapped interface
    input              mm_write_en,
    input              mm_read_en,
    input       [7:0]  mm_addr,
    input       [31:0] mm_wdata,
    output reg  [31:0] mm_rdata,

    // Connections from main_control module
    output             fallback_enable,
    output             manual_enable,
    output      [1:0]  manual_channel,
    output      [7:0]  channel_priority,
    output      [19:0] reset_timer,  // 20 bits

    input       [1:0]  active_channel,
    input       [3:0]  signal_present,
    input       [7:0]  error_count_ch0,
    input       [7:0]  error_count_ch1,
    input       [7:0]  error_count_ch2,
    input       [7:0]  error_count_ch3
);

    reg [31:0] mm_reg [0:2];

    assign fallback_enable       = mm_reg[0][0];
    assign manual_enable         = mm_reg[0][1];
    assign manual_channel        = mm_reg[0][3:2];
    assign channel_priority      = mm_reg[0][11:4];
    assign reset_timer           = mm_reg[0][31:12];

    // Writing and Reading in memory_mapped
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            mm_reg[0][0] <= 0;
            mm_reg[0][1] <= 0;
            mm_reg[0][3:2] <= 2'b00;
            mm_reg[0][11:4] <= 8'b11100100;
            mm_reg[0][31:12] <= 0;
            mm_reg[1] <= 0;
            mm_reg[2] <= 0;
        end else begin
            mm_reg[1] <= {26'd0, signal_present, active_channel};
            mm_reg[2] <= {error_count_ch3, error_count_ch2, error_count_ch1, error_count_ch0};
            if (mm_write_en)
                if      (mm_addr  == 8'h00) begin
                    mm_reg[0]    <= mm_wdata;
                end
            if (mm_read_en)
                if      (mm_addr  == 8'h00) mm_rdata  <= mm_reg[0];
                else if (mm_addr  == 8'h01) mm_rdata  <= mm_reg[1];
                else if (mm_addr  == 8'h02) mm_rdata  <= mm_reg[2];
        end
    end

endmodule