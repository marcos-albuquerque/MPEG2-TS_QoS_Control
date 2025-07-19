
module top_QoS (
    input         rst_n,

    input         wclk1,
    input         valid1,
    input  [7:0]  ts_data1,

    input         wclk2,
    input         valid2,
    input  [7:0]  ts_data2,
    
    input         wclk3,
    input         valid3,
    input  [7:0]  ts_data3,
    
    input         wclk4,
    input         valid4,
    input  [7:0]  ts_data4,

    input         rclk,
    
    // Config interface
    input         mm_write_en,
    input         mm_read_en,
    input  [7:0]  mm_addr,
    input  [31:0] mm_wdata,
    output [31:0] mm_rdata,

    // Outputs
    output clk_out,
    output valid_out,
    output syn_out,
    output [7:0] ts_data_out
);
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;

    // ------------------- FIFO INPUT WIRING ---------------
    wire [DATA_WIDTH-1:0] data_fout1,
                          data_fout2,
                          data_fout3,
                          data_fout4;
    wire valid_fout1,
         valid_fout2,
         valid_fout3,
         valid_fout4;

    // ---------------- SYNC_RECOVERY WIRING --------------
    wire sync_out1, sync_out2, sync_out3, sync_out4;
    wire srvalid_out1, srvalid_out2, srvalid_out3, srvalid_out4;
    wire [7:0] srbyte_out1, srbyte_out2, srbyte_out3, srbyte_out4;
    // --------------------------------------------------------

    // ------------- MAIN CONTROL -----------------
    wire [1:0] mux_control;
    wire en_reset_counter;
    // --------------------------------------------

    // --------------FIFO INPUT WIRING-------------------

    top_fifo_in # (
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    top_fifo_in_inst 
    (
        .wclk1(wclk1),
        .wclk2(wclk2),
        .wclk3(wclk3),
        .wclk4(wclk4),
        .wrst_n(rst_n),
        
        .wdata1(ts_data1),
        .wdata2(ts_data2),
        .wdata3(ts_data3),
        .wdata4(ts_data4),
        .valid1(valid1),
        .valid2(valid2),
        .valid3(valid3),
        .valid4(valid4),

        .rclk(rclk),
        .rrst_n(rst_n),
        .rdata1(data_fout1),
        .rdata2(data_fout2),
        .rdata3(data_fout3),
        .rdata4(data_fout4),
        .valid_out1(valid_fout1),
        .valid_out2(valid_fout2),
        .valid_out3(valid_fout3),
        .valid_out4(valid_fout4)
    );
    
    // -------------------------------------------

    // --------------- SYNC RECOVERY WIRING ---------------

    top_sync_recovery  top_sync_recovery_inst (
        .clk(rclk),
        .rst(rst_n),
        .byte_in1(data_fout1),
        .byte_in2(data_fout2),
        .byte_in3(data_fout3),
        .byte_in4(data_fout4),
        .valid_in1(valid_fout1),
        .valid_in2(valid_fout2),
        .valid_in3(valid_fout3),
        .valid_in4(valid_fout4),
        .sync1(sync_out1),
        .sync2(sync_out2),
        .sync3(sync_out3),
        .sync4(sync_out4),
        .valid_out1(srvalid_out1),
        .valid_out2(srvalid_out2),
        .valid_out3(srvalid_out3),
        .valid_out4(srvalid_out4),
        .byte_out1(srbyte_out1),
        .byte_out2(srbyte_out2),
        .byte_out3(srbyte_out3),
        .byte_out4(srbyte_out4)
    );
    // -------------------------------------------

    // --------------- PACKET LOSS COUNTER WIRING --------------- 

    wire [31:0] error_count;

    top_packet_loss_counter  top_packet_loss_counter_inst (
        .clk(rclk),
        .reset_n(rst_n),
        .valid({srvalid_out4,srvalid_out3,srvalid_out2,srvalid_out1}),
        .sync({sync_out4,sync_out3,sync_out2,sync_out1}),
        .en_reset_counter(en_reset_counter),
        .data0(srbyte_out1),
        .data1(srbyte_out2),
        .data2(srbyte_out3),
        .data3(srbyte_out4),
        .error_count(error_count)
    );

    // --------------- MAIN CONTROL WIRING --------------- 

    main_control  main_control_inst (
        .clk(rclk),
        .rstn(rst_n),
        .err_count(error_count),
        .sync({sync_out4,sync_out3,sync_out2,sync_out1}),
        .mm_write_en(mm_write_en),
        .mm_read_en(mm_read_en),
        .mm_addr(mm_addr),
        .mm_wdata(mm_wdata),
        .mm_rdata(mm_rdata),
        .mux_control(mux_control),
        .en_reset_counter(en_reset_counter)
    );

    clock_divider # (
        .FREQUENCY_IN(108_000_000),
        .FREQUENCY_OUT(27_000_000)
    )
    clock_divider_inst (
        .rstn(rst_n),
        .clk2(rclk),
        .clk_pulse_out(clk_out)
    );

    //---------------FIFO OUTPUT WIRING--------------------
    top_fifo_out #(
        .DATA_WIDTH(DATA_WIDTH+1),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) 
        top_fifo_out_inst
    ( 
        .rstn(rst_n),
        .wclk(rclk),
        .rclk(clk_out),
        .mux_ctrl(mux_control),
        .data_s1(srbyte_out1),
        .data_s2(srbyte_out1),
        .data_s3(srbyte_out1),
        .data_s4(srbyte_out1), 
        .valid_in({srvalid_out4,srvalid_out3,srvalid_out2,srvalid_out1}),
        .sync_in({sync_out4,sync_out3,sync_out2,sync_out1}), 
        .data_out_final({valid_out,syn_out,ts_data_out})
    );

endmodule
