module main_control(

    // Main_control inputs
    input         clk,
    input         rstn,
    input  [3:0]  valid,     // 4bits  -> ch1 = [0]   / ch2 = [1]    / ch3 = [2]     / ch4 = [3]
    input  [31:0] err_count, // 32bits -> ch1 = [0:7] / ch2 = [8:15] / ch3 = [16:23] / ch4 = [24:31]
    input  [3:0]  sync,

    // Memory_mapped interface
    input         mm_write_en,
    input         mm_read_en,
    input  [7:0]  mm_addr,
    input  [31:0] mm_wdata,
    output [31:0] mm_rdata,

    // Main_control output
    output [1:0]  mux_control,
    output        en_reset_counter
);

    //FSM States
    localparam IDLE        = 2'd0;
    localparam CONFIG_MODE = 2'd1;
    localparam AUTO_MODE   = 2'd2;
    localparam MANUAL_MODE = 2'd3;

    //Channels
    localparam CHANNEL1    = 2'd0;
    localparam CHANNEL2    = 2'd1;
    localparam CHANNEL3    = 2'd2;
    localparam CHANNEL4    = 2'd3;

    //Memory_mapped variables
    wire        fallback_enable;
    wire        manual_enable;
    wire [1:0]  manual_channel;
    wire [7:0]  channel_priority;
    wire [19:0] reset_timer;

    //Main_control variables
    reg  [1:0]  active_channel;

    //Aux variables
    reg [19:0] intern_counter;
    reg [3:0]  signal_present_ctrl;
    reg        reset_packet_loss_counter;
    reg        mm_write_en_fall_detection;
    
    assign mux_control        = active_channel;
    assign en_reset_counter   = reset_packet_loss_counter;

    memory_mapped mm_mapped (

        // Memory_mapped control pins
        .clk        (clk),
        .rstn       (rstn),
        .mm_write_en(mm_write_en),
        .mm_read_en (mm_read_en),
        .mm_addr    (mm_addr),
        .mm_wdata   (mm_wdata),
        .mm_rdata   (mm_rdata),

        // Write
        .fallback_enable (fallback_enable),
        .manual_enable   (manual_enable),
        .manual_channel  (manual_channel),
        .channel_priority(channel_priority),
        .reset_timer     (reset_timer),

        // Read
        .active_channel (active_channel),
        .signal_present (signal_present_ctrl),
        .error_count_ch0(err_count[7:0]),
        .error_count_ch1(err_count[15:8]),
        .error_count_ch2(err_count[23:16]),
        .error_count_ch3(err_count[31:24])
    );

    //System counter
    //When intern_counter = reset_timer, it'll search a new channel
    always @(posedge clk or negedge rstn) begin : INTERN_COUNTER_LOGIC
        if(!rstn) begin
            intern_counter    <= 20'd0;
        end 
        else begin 
            if      (intern_counter == reset_timer) intern_counter <= 20'd0; // if intern_counter = reset_timer, it starts a new count.
            else if (mm_write_en == 1'b1)           intern_counter <= 20'd0; // // if state = config it starts a new count.
            else                                    intern_counter <= intern_counter + 1;
        end
    end

    //Detect signal by channel
    always @(*) begin : CHANNEL_SIGNAL_LOGIC
        if(!rstn) begin
            signal_present_ctrl     <= 4'b0000;
        end
        else begin
            if (reset_packet_loss_counter)          // if a new count has been started, signal_present_ctrl will a new search 
                signal_present_ctrl <= 4'b0000;
            else begin                              // signal_present_ctrl is set to 1 if sync is equal to 1 within a time window defined by intern_counter
                if(sync[0]) signal_present_ctrl[0] <= 1'b1;
                if(sync[1]) signal_present_ctrl[1] <= 1'b1;
                if(sync[2]) signal_present_ctrl[2] <= 1'b1;
                if(sync[3]) signal_present_ctrl[3] <= 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rstn) begin : MAIN_ALWAYS
        if(!rstn) begin
            active_channel             <= CHANNEL1;
            reset_packet_loss_counter  <= 1'b0;
            mm_write_en_fall_detection <= 1'b0;
        end
        else 
            if(mm_write_en) begin
                reset_packet_loss_counter <= 1'b1;
                mm_write_en_fall_detection <= mm_write_en;
            end
            else begin
                if (manual_enable) active_channel <= manual_channel;        // After the CPU finishes writing to memory-mapped registers and manual enable equals 1, it'll select manual channel
                else begin
                    if (mm_write_en_fall_detection != mm_write_en) begin    // After the CPU finishes writing to memory-mapped registers, apply the new configuration..
                        active_channel              <= channel_priority[1:0];
                        mm_write_en_fall_detection  <= mm_write_en;
                        reset_packet_loss_counter   <= 1'b0;
                    end
                    else begin                                              // If none of the earlier conditions are met, automatic mode will be selected.
                        reset_packet_loss_counter <= 1'b0;
                        if (intern_counter > reset_timer-1) begin
                            active_channel            <= select_new_channel(fallback_enable,channel_priority,err_count,signal_present_ctrl);
                            reset_packet_loss_counter <= 1'b1;
                        end
                    end
                end
            end
    end

    //This function compare four channel to select the best channel according its counter.
    function [1:0] select_new_channel(
        input        fallback_enable,
        input [7:0]  channel_priority,
        input [31:0] err_count,
        input [3:0]  signal_present_ctrl
        );

        reg [1:0] partial_result [0:1];

        begin
                                        // if priority channel counter 3 < priority channel counter 2, return priority channel 3, else return priority channel 2
            if(!valid_decode(channel_priority[7:6],signal_present_ctrl))
                partial_result[0] = channel_priority[5:4];
            else
                if(!valid_decode(channel_priority[5:4],signal_present_ctrl))
                    partial_result[0] = channel_priority[7:6];
                else begin
                    if(fallback_enable)  //if fallback_enable = 1, the function returns the highest priority when counters are same.
                        partial_result[0] = (priority_decode(channel_priority[7:6],err_count) <  priority_decode(channel_priority[5:4],err_count)) ? channel_priority[7:6]: channel_priority[5:4];
                    else                 //if fallback_enable = 0, the function stays the current channel when counters are same.
                        partial_result[0] = (priority_decode(channel_priority[7:6],err_count) <= priority_decode(channel_priority[5:4],err_count)) ? channel_priority[7:6]: channel_priority[5:4];
                end

                                        // if priority channel counter 1 < priority channel counter 0, return priority channel 1, else return priority channel 0
            if(!valid_decode(channel_priority[3:2],signal_present_ctrl))
                    partial_result[1] = channel_priority[1:0];
            else
                if(!valid_decode(channel_priority[1:0],signal_present_ctrl))
                        partial_result[1] = channel_priority[3:2];
                else begin
                    if(fallback_enable)  //if fallback_enable = 1, the function returns the highest priority when counters are same.
                        partial_result[1] = (priority_decode(channel_priority[3:2],err_count) <  priority_decode(channel_priority[1:0],err_count)) ? channel_priority[3:2]: channel_priority[1:0];
                    else                 //if fallback_enable = 0, the function stays the current channel when counters are same.
                        partial_result[1] = (priority_decode(channel_priority[3:2],err_count) <= priority_decode(channel_priority[1:0],err_count)) ? channel_priority[3:2]: channel_priority[1:0];
                end
                
                                        //Finally, least channel counter is selected.
            if(!valid_decode(partial_result[0],signal_present_ctrl))
                    select_new_channel = partial_result[1];
            else
                if(!valid_decode(partial_result[1],signal_present_ctrl))
                    select_new_channel = partial_result[0];
                else begin
                    if(fallback_enable)  //if fallback_enable = 1, the function returns the highest priority when counters are same.
                        select_new_channel = (priority_decode(partial_result[0],err_count) <  priority_decode(partial_result[1],err_count)) ? partial_result[0] : partial_result[1];
                    else                 //if fallback_enable = 0, the function stays the current channel when counters are same.
                        select_new_channel = (priority_decode(partial_result[0],err_count) <= priority_decode(partial_result[1],err_count)) ? partial_result[0] : partial_result[1];
                end
        end

    endfunction

    //This function returns the channel counter
    function [7:0] priority_decode(
        input [1:0]  var_decode,
        input [31:0] err_count
    );
        begin
            case(var_decode)
                CHANNEL1 : priority_decode = err_count[7:0];
                CHANNEL2 : priority_decode = err_count[15:8];
                CHANNEL3 : priority_decode = err_count[23:16];
                CHANNEL4 : priority_decode = err_count[31:24];
                default   : priority_decode = 8'd0;
            endcase
        end
    endfunction

    // This function returns signal present per channel
    function valid_decode(
        input [1:0] var_decode,
        input [3:0] signal_present_ctrl
    );
        begin
            case(var_decode)
                CHANNEL1 : valid_decode = signal_present_ctrl[0];
                CHANNEL2 : valid_decode = signal_present_ctrl[1];
                CHANNEL3 : valid_decode = signal_present_ctrl[2];
                CHANNEL4 : valid_decode = signal_present_ctrl[3];
                default   : valid_decode = 1'b0;
            endcase
        end
    endfunction

endmodule