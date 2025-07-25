`timescale 1us / 100ns

module tb_main_control();

    // Main_control regs
    reg         clk;
    reg         rst;
    reg  [31:0] err_count;
    reg  [3:0]  sync;

    // Memory_mapped pins
    reg         mm_write_en;
    reg         mm_read_en;
    reg  [7:0]  mm_addr;
    reg  [31:0] mm_wdata;
    wire [31:0] mm_rdata;

    // Main_control wire
    wire [1:0]  mux_control;
    wire        en_reset_counter;

    main_control uut (
        // Main_control inputs
        .clk(clk),
        .rstn(!rst),
        .err_count(err_count), // 32bits -> ch1 = [0:7] / ch2 = [8:15] / ch3 = [16:23] / ch4 = [24:31]
        .sync(sync),

        // Memory_mapped pins
        .mm_write_en(mm_write_en),
        .mm_read_en(mm_read_en),
        .mm_addr(mm_addr),
        .mm_wdata(mm_wdata),
        .mm_rdata(mm_rdata),

        // Main_control output
        .mux_control(mux_control),
        .en_reset_counter(en_reset_counter)
    );

    reg        fallback_enable;
    reg        manual_enable;
    reg [1:0]  manual_channel;
    reg [7:0]  channel_priority;
    reg [19:0] reset_timer;


    initial begin
        mm_write_en = 0;
        mm_read_en = 0;
        mm_addr = 0;
        mm_wdata = 0;

        err_count = 0;

        rst = 1;
        clk = 0;
        #2;
        rst = 0;
        forever #1 clk = ~clk;
    end

    initial begin
        forever begin
            err_count[7:0]   = ($random % 6 + 6) % 6;
            err_count[15:8]  = ($random % 6 + 6) % 6;
            err_count[23:16] = ($random % 6 + 6) % 6;
            err_count[31:24] = ($random % 6 + 6) % 6;
            sync             = $random;
            #20;
        end
    end

    initial begin
        fallback_enable  = 1;
        manual_enable    = 0;
        manual_channel   = 00;
        channel_priority = 8'b11_01_00_10;
        reset_timer      = 20'd30;
        mm_write(8'h00,{reset_timer,channel_priority,manual_channel,manual_enable,fallback_enable});
        #520;
        $display("Mudanca de parametros %t",$time);
        fallback_enable  = 1;
        manual_enable    = 1;
        manual_channel   = 10;
        channel_priority = 8'b11_01_10_00;
        reset_timer      = 20'd30;
        mm_write(8'h00,{reset_timer,channel_priority,manual_channel,manual_enable,fallback_enable});
        #500;
        fallback_enable  = 0;
        manual_enable    = 0;
        manual_channel   = 11;
        channel_priority = 8'b00_11_10_01;
        reset_timer      = 20'd50;
        mm_write(8'h00,{reset_timer,channel_priority,manual_channel,manual_enable,fallback_enable});
        #2000;
        $stop;
    end

    initial begin
        forever begin
            #20;
            mm_read(8'h01);
            @(posedge clk);
            @(posedge clk);
            $display("canal ativo: %b | presenca de sinal %b",mm_rdata[1:0],mm_rdata[5:2]);
            mm_read(8'h02);
            @(posedge clk);
            @(posedge clk);
            $display("interno canal 1: %d | canal 2: %d | canal 3: %d | canal 4: %d",err_count[7:0],err_count[15:8],err_count[23:16],err_count[31:24]);
            $display("externo canal 1: %d | canal 2: %d | canal 3: %d | canal 4: %d",mm_rdata[7:0],mm_rdata[15:8],mm_rdata[23:16],mm_rdata[31:24]);
        end
    end

    task mm_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            mm_addr     <= addr;
            mm_wdata    <= data;
            mm_write_en <= 1'b1;
            @(posedge clk);
            mm_write_en <= 1'b0;
        end
    endtask

    task mm_read(input [7:0] addr);
        begin
            @(posedge clk);
            mm_addr    <= addr;
            mm_read_en <= 1'b1;
            @(posedge clk);
            //data = mm_rdata;
            mm_read_en <= 1'b0;
        end
    endtask


endmodule
