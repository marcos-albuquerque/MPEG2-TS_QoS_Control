//FSM States
`define IDLE        2'd0
`define CONFIG_MODE 2'd1
`define AUTO_MODE   2'd2
`define MANUAL_MODE 2'd3

//Channels
`define CHANNEL1     2'd0
`define CHANNEL2     2'd1
`define CHANNEL3     2'd2
`define CHANNEL4     2'd3

module main_control(
    // Main_control inputs
    input         clk,
    input         rst,
    input  [3:0]  valid,     // 4bits  -> ch1 = [0]   / ch2 = [1]    / ch3 = [2]     / ch4 = [3]
    input  [31:0] err_count, // 32bits -> ch1 = [0:7] / ch2 = [8:15] / ch3 = [16:23] / ch4 = [24:31]

    // Memory_mapped interface
    input         mm_write_en,
    input         mm_read_en,
    input  [7:0]  mm_addr,
    input  [31:0] mm_wdata,
    output [31:0] mm_rdata,

    // Main_control output
    output [1:0]  mux_control,
    output        en_mux,
    output        en_reset_counter
);

    //Memory_mapped variables
    wire        fallback_enable;
    wire        manual_enable;
    wire [1:0]  manual_channel;
    wire [7:0]  channel_priority;
    wire [19:0] reset_timer;

    //Main_control variables
    reg  [1:0]  active_channel;
    wire [3:0]  signal_present;
    wire [7:0]  error_count_ch0;
    wire [7:0]  error_count_ch1;
    wire [7:0]  error_count_ch2;
    wire [7:0]  error_count_ch3;

    //Aux variables
    reg [1:0]  state;
    reg [19:0] intern_counter;
    reg [3:0]  signal_present_ctrl;
    reg        en_module;
    reg        reset_packet_loss_counter;

    assign error_count_ch0 = err_count[7:0];
    assign error_count_ch1 = err_count[15:8];
    assign error_count_ch2 = err_count[23:16];
    assign error_count_ch3 = err_count[31:24];

    assign signal_present[0]  = valid[0];
    assign signal_present[1]  = valid[1];
    assign signal_present[2]  = valid[2];
    assign signal_present[3]  = valid[3];
    
    assign mux_control        = active_channel;
    assign en_mux             = en_module;
    assign en_reset_counter   = reset_packet_loss_counter;

    memory_mapped mm_mapped (

        // Memory_mapped control pins
        .clk        (clk),
        .rst        (rst),
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
        .signal_present (signal_present),
        .error_count_ch0(error_count_ch0),
        .error_count_ch1(error_count_ch1),
        .error_count_ch2(error_count_ch2),
        .error_count_ch3(error_count_ch3)
    );

    //System counter
    //When intern_counter = reset_timer, it'll search a new channel
    always @(posedge clk or posedge rst) begin : INTERN_COUNTER_LOGIC
        if(rst) begin 
            intern_counter    <= 20'd0;
        end 
        else begin
            if(en_module)  
                if      (intern_counter == reset_timer) intern_counter <= 20'd0; // if intern_counter = reset_timer, it starts a new count.
                else if (state == `CONFIG_MODE)         intern_counter <= 20'd0; // // if state = config it starts a new count.
                else                                    intern_counter <= intern_counter + 1;
        end
    end

    //Detect signal by channel
    always @(*) begin : CHANNEL_SIGNAL_LOGIC
        if(rst) begin
            signal_present_ctrl     <= 4'b0000;
        end
        else begin
            if (reset_packet_loss_counter) // if a new count has been started, signal_present_ctrl will a new search 
                signal_present_ctrl <= 4'b0000;
            else begin  // signal_present_ctrl = 1 if valid = 1 inside a time windows of intern_counter
                if(valid[0]) signal_present_ctrl[0] <= 1'b1;
                if(valid[1]) signal_present_ctrl[1] <= 1'b1;
                if(valid[2]) signal_present_ctrl[2] <= 1'b1;
                if(valid[3]) signal_present_ctrl[3] <= 1'b1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin : MAIN_ALWAYS
        if(rst) begin
            state                     <= `IDLE;
            active_channel            <= `CHANNEL1;
            en_module                 <= 1'b0;
            reset_packet_loss_counter <= 1'b0;
        end
        else begin
            case(state)
                //Waiting config parameters
                `IDLE: begin
                    if(mm_write_en)  state <= `CONFIG_MODE;
                    else             state <= `IDLE;
                end
                //Selecting mode, manual or automatic
                `CONFIG_MODE: begin
                    en_module                 <= 1'b1;
                    reset_packet_loss_counter <= 1'b1;
                    if(manual_enable) begin
                        active_channel <= manual_channel;
                        state          <= `MANUAL_MODE;
                    end
                    else begin
                        active_channel <= channel_priority[1:0];
                        state          <= `AUTO_MODE;
                    end
                end
                //In automatic mode, the FSM selects the best channel based on the continuity counter.
                `AUTO_MODE: begin
                    reset_packet_loss_counter <= 1'b0;
                    if      (mm_write_en)
                        state                     <= `CONFIG_MODE;
                    else if (intern_counter > reset_timer-1) begin
                        active_channel            <= select_new_channel(fallback_enable,channel_priority,err_count,signal_present_ctrl);
                        reset_packet_loss_counter <= 1'b1;
                    end
                    else 
                        state                     <= `AUTO_MODE;

                end
                //In manual mode, the FSM selects the channel chosen by the configuration
                `MANUAL_MODE: begin
                    if  (mm_write_en)   state <= `CONFIG_MODE;
                    else                state <= `MANUAL_MODE;
                end

                default:                state <= `IDLE;

            endcase
        end
    end

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
                
            //$display("teste: %d | chnel: ",priority_decode(channel_priority[7:6],err_count), channel_priority[7:6]);
        
        end

    endfunction

    //This function returns the channel counter
    function [7:0] priority_decode(
        input [1:0]  var_decode,
        input [31:0] err_count
    );
        begin
            case(var_decode)
                `CHANNEL1 : priority_decode = err_count[7:0];
                `CHANNEL2 : priority_decode = err_count[15:8];
                `CHANNEL3 : priority_decode = err_count[23:16];
                `CHANNEL4 : priority_decode = err_count[31:24];
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
                `CHANNEL1 : valid_decode = signal_present_ctrl[0];
                `CHANNEL2 : valid_decode = signal_present_ctrl[1];
                `CHANNEL3 : valid_decode = signal_present_ctrl[2];
                `CHANNEL4 : valid_decode = signal_present_ctrl[3];
                default   : valid_decode = 1'b0;
            endcase
        end
    endfunction

endmodule