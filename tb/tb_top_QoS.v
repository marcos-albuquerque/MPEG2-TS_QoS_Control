`timescale 1ns/1ps

module tb_top_QoS();
    localparam real DATA_FREQUENCY = 27e6;      // Clock frequency in Hz
    localparam real SYS_FREQUENCY  = 108e6;
    localparam FILE_NAME1 = "tsdata1_loss.ts";
    localparam FILE_NAME2 = "tsdata2_loss.ts";
    localparam FILE_NAME3 = "tsdata3_loss.ts";
    localparam FILE_NAME4 = "tsdata4_loss.ts";
    localparam DATA_WIDTH = 8;

    reg         reset_n;
    wire        wclk;
    wire        rclk;
    wire [3:0]  valid;
    wire [DATA_WIDTH-1:0] byte_data1;
    wire [DATA_WIDTH-1:0] byte_data2;
    wire [DATA_WIDTH-1:0] byte_data3;
    wire [DATA_WIDTH-1:0] byte_data4;

    reg         mm_write_en;
    reg         mm_read_en;
    reg  [7:0]  mm_addr;
    reg  [31:0] mm_wdata;
    wire [31:0] mm_rdata;

    wire        clk_out;
    wire        valid_out;
    wire        syn_out;
    wire [7:0]  ts_data_out;

    reg        fallback_enable;
    reg        manual_enable;
    reg [1:0]  manual_channel;
    reg [7:0]  channel_priority;
    reg [19:0] reset_timer;

    integer fd_out1;
    integer fd_out2;
    integer fd_out3;
    integer fd_out4;

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
        .byte_data1(byte_data1),
        .byte_data2(byte_data2),
        .byte_data3(byte_data3),
        .byte_data4(byte_data4)
    );

    top_QoS top_qos_inst (
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

    initial begin : reading_from_mm // Reading internal parameters
        wait(reset_n==1);
        forever begin
            #2000;
            mm_read(8'h00);
            @(posedge rclk);
            @(posedge rclk);
            $display("fallback_enable: %b | manual_enable %b | manual_channel %b | channel_priority %b | reset_timer %d",mm_rdata[0],mm_rdata[1],mm_rdata[3:2],mm_rdata[11:4],mm_rdata[31:12]);
            mm_read(8'h01);
            @(posedge rclk);
            @(posedge rclk);
            $display("canal ativo: %b | presenca de sinal %b",mm_rdata[1:0],mm_rdata[5:2]);
            mm_read(8'h02);
            @(posedge rclk);
            @(posedge rclk);
            $display("externo canal 1: %d | canal 2: %d | canal 3: %d | canal 4: %d",mm_rdata[7:0],mm_rdata[15:8],mm_rdata[23:16],mm_rdata[31:24]);
        end
    end

    initial begin : writing_to_mm // Writing internal paramers
        wait(reset_n==1);
        forever begin           // I think it's not necessary writting to MM forever
            $display("Mudanca de parametros %t",$time);
            fallback_enable  = 1;
            manual_enable    = 0;
            manual_channel   = 00;
            channel_priority = 8'b11_01_00_10;
            reset_timer      = 20'd750_000;             // 2250 = 3 MPEG packages (Receive 1 MPEG package with 750 clock cycles).
            mm_write(8'h00,{reset_timer,channel_priority,manual_channel,manual_enable,fallback_enable});
            #1000000;
            $display("Mudanca de parametros %t",$time);
            fallback_enable  = 1;
            manual_enable    = 1;
            manual_channel   = 10;
            channel_priority = 8'b11_01_10_00;
            reset_timer      = 20'd150_000;
            mm_write(8'h00,{reset_timer,channel_priority,manual_channel,manual_enable,fallback_enable});
            $display("Mudanca de parametros %t",$time);
            #1000000;
            fallback_enable  = 0;
            manual_enable    = 0;
            manual_channel   = 11;
            channel_priority = 8'b00_11_10_01;
            reset_timer      = 20'd75_000;
            mm_write(8'h00,{reset_timer,channel_priority,manual_channel,manual_enable,fallback_enable});
            #1000000;
        end
    end

    initial begin
        reset_n = 1'b0;
        #100;
        reset_n = 1'b1;
        // Abrir arquivos
        fd_out1 = $fopen("rdata_out1.txt", "w");
        fd_out2 = $fopen("rdata_out2.txt", "w");
        fd_out3 = $fopen("rdata_out3.txt", "w");
        fd_out4 = $fopen("rdata_out4.txt", "w");

        if (fd_out1 == 0 || fd_out2 == 0 || fd_out3 == 0 || fd_out4 == 0) begin
            $error("Error!");
            $stop;
        end

        if (fd_out1 != 0) $fclose(fd_out1);
        if (fd_out2 != 0) $fclose(fd_out2);
        if (fd_out3 != 0) $fclose(fd_out3);
        if (fd_out4 != 0) $fclose(fd_out4);

        wait($feof(stimulus_from_file_inst.fh1)==0);

        // $stop; 
    end

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

endmodule
