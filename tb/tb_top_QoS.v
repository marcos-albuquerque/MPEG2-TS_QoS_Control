`timescale 1ns/1ps

module tb_top_QoS();
    localparam real DATA_FREQUENCY = 25e6;      // Clock frequency in Hz
    localparam real SYS_FREQUENCY  = 100e6;
    localparam FILE_NAME1 = "tsdata1_loss.ts";
    localparam FILE_NAME2 = "tsdata2_loss.ts";
    localparam FILE_NAME3 = "tsdata3_loss.ts";
    localparam FILE_NAME4 = "tsdata4_loss.ts";
    localparam DATA_WIDTH = 8;
    localparam SENTINEL_TIMEOUT = 20'd5_000_000;

    // input signals
    reg         reset_n;
    wire        wclk;
    wire        rclk;
    wire [3:0]  valid;
    wire [DATA_WIDTH-1:0] byte_data1;
    wire [DATA_WIDTH-1:0] byte_data2;
    wire [DATA_WIDTH-1:0] byte_data3;
    wire [DATA_WIDTH-1:0] byte_data4;


    // Signals for writing and reading in memory-mapped
    reg         mm_write_en;
    reg         mm_read_en;
    reg  [7:0]  mm_addr;
    reg  [31:0] mm_wdata;
    wire [31:0] mm_rdata;

    // Config interface
    // rw
    reg        fallback_enable;
    reg        manual_enable;
    reg [1:0]  manual_channel;
    reg [7:0]  channel_priority;
    reg [19:0] reset_timer;
    // r
    reg [1:0] active_channel;
    reg [7:0] error_count_ch0,
        error_count_ch1,
        error_count_ch2,
        error_count_ch3;

    // Output signal
    wire        clk_out;
    wire        valid_out;
    wire        syn_out;
    wire [7:0]  ts_data_out;

    integer fh; // file handle
    wire eof;
    reg [19:0] sentinel;

    clock_generator #(DATA_FREQUENCY, 1) CLOCK27M(.clk(wclk));
    clock_generator #(SYS_FREQUENCY, 1) CLOCK108M(.clk(rclk));

    stimulus_from_file # (
        .FILE_NAME1(FILE_NAME1),
        .FILE_NAME2(FILE_NAME2),
        .FILE_NAME3(FILE_NAME3),
        .FILE_NAME4(FILE_NAME4),
        .DATA_WIDTH(DATA_WIDTH)
    )
    stimulus_from_file_inst (
        .clk(wclk),
        .rstn(reset_n),
        .valid(valid),
        .eof(eof),
        .byte_data1(byte_data1),
        .byte_data2(byte_data2),
        .byte_data3(byte_data3),
        .byte_data4(byte_data4)
    );

    top_QoS DUT (
        .rst_n(reset_n),

        .wclk1(wclk),
        .valid1(valid[0]),
        .ts_data1(byte_data1),

        .wclk2(wclk),
        .valid2(valid[1]),
        .ts_data2(byte_data2),

        .wclk3(wclk),
        .valid3(valid[2]),
        .ts_data3(byte_data3),

        .wclk4(wclk),
        .valid4(valid[3]),
        .ts_data4(byte_data4),

        .rclk(rclk),

        // Config interface
        .mm_write_en(mm_write_en),
        .mm_read_en(mm_read_en),
        .mm_addr(mm_addr),
        .mm_wdata(mm_wdata),
        .mm_rdata(mm_rdata),

        // Outputs
        .clk_out(clk_out),
        .valid_out(valid_out),
        .syn_out(syn_out),
        .ts_data_out(ts_data_out)
    );

    initial begin : vars_initializing
        fallback_enable  <= 0;
        manual_enable    <= 0;
        channel_priority <= 0;
        reset_timer      <= 0;
        mm_write_en      <= 0;
        mm_read_en       <= 0;
        mm_addr          <= 0;
        mm_wdata         <= 0;
    end

    initial begin
        $dumpfile("tb_top_QoS.vcd");
        $dumpvars(0, tb_top_QoS);
    end

    reg [79:0] sr_data_buffer1,
        sr_data_buffer2,
        sr_data_buffer3,
        sr_data_buffer4;

    initial begin
        sr_data_buffer1 <= 0;
        sr_data_buffer2 <= 0;
        sr_data_buffer3 <= 0;
        sr_data_buffer4 <= 0;
        forever begin
            @(posedge wclk);
            sr_data_buffer1 <= {sr_data_buffer1[71:0], byte_data1};
            sr_data_buffer2 <= {sr_data_buffer2[71:0], byte_data2};
            sr_data_buffer3 <= {sr_data_buffer3[71:0], byte_data3};
            sr_data_buffer4 <= {sr_data_buffer4[71:0], byte_data4};
        end
    end

    initial begin
        wait(syn_out);
        forever begin
            @(posedge wclk) begin
                if (!manual_channel) begin
                    if(DUT.en_reset_counter)
                        repeat(10) @(posedge wclk);
                    case (DUT.mux_control)
                        0: begin
                            if (sr_data_buffer1[63:56] != ts_data_out)
                                $display("%t: Error1 %h != %h", $time,
                                sr_data_buffer1[63:56], ts_data_out);
                        end
                        1: begin
                            if (sr_data_buffer2[63:56] != ts_data_out)
                                $display("%t: Error2 %h != %h", $time,
                                sr_data_buffer2[63:56], ts_data_out);
                        end
                        2: begin
                            if (sr_data_buffer3[63:56] != ts_data_out)
                                $display("%t: Error3 %h != %h", $time,
                                sr_data_buffer3[63:56], ts_data_out);
                        end
                        3: begin
                            if (sr_data_buffer4[63:56] != ts_data_out)
                                $display("%t: Error4 %h != %h", $time,
                                sr_data_buffer4[63:56], ts_data_out);
                        end
                    endcase
                end
            end
        end
    end

    initial begin : writing_to_file
        fh = $fopen("rdata_out.ts", "wb");
        if (!fh) begin
            $display("Error when opening file!");
            $finish();
        end
        sentinel = 0;
        wait(valid_out);
        repeat(2) @(posedge clk_out);
        while ((!eof && reset_n) || (sentinel <= SENTINEL_TIMEOUT)) begin
            @(posedge clk_out);
            if (valid_out) begin
                $fwrite(fh, "%c", ts_data_out);
            end
            sentinel <= sentinel + 1;
        end
        $fclose(fh);
        $finish();
    end

    initial begin
        reset_n = 1'b0;
        repeat(13) @(posedge rclk);
        reset_n = 1'b1;

        read_from_mm();
        #50_000;

        // Checking if the system is initialized with automatic mode in channel 0 as default
        @(posedge rclk);
        if(active_channel == 2'b00 && !manual_enable && (channel_priority == 8'b11100100))
            $display("%1t: Active_channel: %d | Ok", $time, active_channel);
        else begin
            $display("Error: active channel not expected!");
            $stop;
        end
        #100;

        // 2250 -> 3 MPEG packages (Receive 1 MPEG package with 750 clock cycles).
        write_to_mm(1, 0, 2'b00, 8'b11_01_10_00, 20'd50_000);
        #1000;
        read_from_mm();
        #50;

        if (active_channel == 2'b00) begin
            $display("Active_channel: %d | Ok", active_channel);
        end else begin
            $display("Error: active channel not expected!");
            $stop;
        end
        #1000000;
        write_to_mm(1, 1, 2'b10, 8'b11_01_10_00, 20'd50_000);
        #300_000;
        write_to_mm(0, 0, 2'b11, 8'b00_11_10_01, 20'd50_000);
        #1000000;

        /* TODO:
        * - [ ] Control and monitor the config interface
        * - [x] Compare results and save them in file
        */
    end

    // ============================== Util Tasks ==============================

    task mm_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge rclk);
            mm_addr     <= addr;
            mm_wdata    <= data;
            mm_write_en <= 1'b1;
            @(posedge rclk);
            mm_write_en <= 1'b0;
        end
    endtask

    task mm_read(input [7:0] addr);
        begin
            @(posedge rclk);
            mm_addr    <= addr;
            mm_read_en <= 1'b1;
            @(posedge rclk);
            mm_read_en <= 1'b0;
        end
    endtask

    task write_to_mm( // fb, me, [1:0]mch, [7:0]ch_prty, [19:0] rst_timer;
        input fb,               // fallback
        input me,               // manual enable
        input [1:0] mch,        // manual channel
        input [7:0] ch_prty,    // priority channel
        input [19:0] rst_timer  // reset timer
    );
        begin
            $display("%t: Writing to mm at address 0x00",$time);
            fallback_enable  = fb;
            manual_enable    = me;
            manual_channel   = mch;
            channel_priority = ch_prty;
            reset_timer      = rst_timer;
            mm_write(8'h00,{reset_timer,channel_priority,manual_channel,manual_enable,fallback_enable});
        end
    endtask

    task read_from_mm();
        begin
            mm_read(8'h00);
            @(posedge rclk);
            @(posedge rclk);
            fallback_enable = mm_rdata[0];
            manual_enable = mm_rdata[1];
            manual_channel = mm_rdata[3:2];
            channel_priority = mm_rdata[11:4];
            reset_timer = mm_rdata[31:12];
            // $display("fallback_enable: %b | manual_enable %b | manual_channel %b | channel_priority %b | reset_timer %d",
            //             mm_rdata[0],mm_rdata[1],mm_rdata[3:2],mm_rdata[11:4],mm_rdata[31:12]);

            mm_read(8'h01);
            @(posedge rclk);
            @(posedge rclk);
            active_channel = mm_rdata[1:0];
            // $display("canal ativo: %b | presenca de sinal %b",mm_rdata[1:0],mm_rdata[5:2]);
            // mm_read(8'h02);
            @(posedge rclk);
            @(posedge rclk);
            error_count_ch0 = mm_rdata[7:0];
            error_count_ch1 = mm_rdata[15:8];
            error_count_ch2 = mm_rdata[23:16];
            error_count_ch3 = mm_rdata[31:24];
            // $display("externo canal 1: %d | canal 2: %d | canal 3: %d | canal 4: %d",
            //         error_count_ch0, error_count_ch1, error_count_ch2, error_count_ch3);


        end
    endtask

    // ============================ End Util Tasks ============================

 endmodule
