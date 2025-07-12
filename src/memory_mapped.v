module memory_mapped (
    input  wire        clk,
    input  wire        rst,

    // Interface memory-mapped
    input  wire        mm_write_en,
    input  wire        mm_read_en,
    input  wire [7:0]  mm_addr,
    input  wire [31:0] mm_wdata,
    output reg  [31:0] mm_rdata,

    // Conexões com o módulo QoS core
    output reg         fallback_enable,
    output reg         manual_enable,
    output reg  [1:0]  manual_channel,
    output reg  [7:0]  channel_priority,
    output reg  [19:0] reset_timer,  // 20 bits para 1M ciclos (~20 bits)
    output reg         valid_config,

    input  wire [1:0]  active_channel,
    input  wire [3:0]  signal_present,
    input  wire [7:0]  error_count_ch0,
    input  wire [7:0]  error_count_ch1,
    input  wire [7:0]  error_count_ch2,
    input  wire [7:0]  error_count_ch3
);

    reg [31:0] mm_reg [0:2];

    assign fallback_enable       = mm_reg[0][0];
    assign manual_enable         = mm_reg[0][1];
    assign manual_channel        = mm_reg[0][3:2];
    assign channel_priority      = mm_reg[0][11:4];
    assign reset_timer           = mm_reg[0][31:12];

    // Escrita nos registradores
    always @(posedge clk or posedge rst) begin
        valid_config <= 1'b0;
        if (rst) begin
            mm_reg[0]    <= 0;
            mm_reg[1]    <= 0;
            mm_reg[2]    <= 0;
        end else begin
            mm_reg[1] <= {26'd0, signal_present, active_channel};
            mm_reg[2] <= {error_count_ch3, error_count_ch2, error_count_ch1, error_count_ch0};
            if (mm_write_en)
                if      (mm_addr  == 8'h00) begin
                    mm_reg[0]    <= mm_wdata;
                    valid_config <= 1'b1;
                end
            if (mm_read_en)
                if      (mm_addr  == 8'h00) mm_rdata  <= mm_reg[0];
                else if (mm_addr  == 8'h01) mm_rdata  <= mm_reg[1];
                else if (mm_addr  == 8'h02) mm_rdata  <= mm_reg[2];
        end
    end

endmodule
