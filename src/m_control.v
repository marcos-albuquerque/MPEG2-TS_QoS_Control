module main_control(
    // Main_control inputs
    input         clk,
    input         rst,
    input  [3:0]  valid,     // 4bits  -> ch1 = [0]   / ch2 = [1]    / ch3 = [2]     / ch4 = [3]
    input  [31:0] err_count, // 32bits -> ch1 = [0:7] / ch2 = [8:15] / ch3 = [16:23] / ch4 = [24:31]

    // Memory_mapped pins
    input         mm_write_en,
    input         mm_read_en,
    input  [7:0]  mm_addr,
    input  [31:0] mm_wdata,
    output [31:0] mm_rdata,

    // Main_control output
    output [1:0]  mux_control,
    output        en_mux,
    output [19:0] timer
);
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

    //Memory_mapped variables
    wire        fallback_enable;
    wire        manual_enable;
    wire [1:0]  manual_channel;
    wire [7:0]  channel_priority;
    wire [19:0] reset_timer;
    wire        valid_config;

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
    reg        en_module;

    assign error_count_ch0 = err_count[7:0];
    assign error_count_ch1 = err_count[15:8];
    assign error_count_ch2 = err_count[23:16];
    assign error_count_ch3 = err_count[31:24];

    assign signal_present[0]  = valid[0];
    assign signal_present[1]  = valid[1];
    assign signal_present[2]  = valid[2];
    assign signal_present[3]  = valid[3];
    
    assign mux_control = active_channel;
    assign timer       = (!en_module || (state == `CONFIG_MODE)) ? 20'd0: reset_timer;
    assign en_mux      = en_module;

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
        .valid_config    (valid_config),

        // Read
        .active_channel (active_channel),
        .signal_present (signal_present),
        .error_count_ch0(error_count_ch0),
        .error_count_ch1(error_count_ch1),
        .error_count_ch2(error_count_ch2),
        .error_count_ch3(error_count_ch3)
    );

    //System counter. When intern_counter = reset_timer, it'll search a new channel
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            intern_counter    <= 20'd0;
        end 
        else begin
            if(en_module)  
                if      (intern_counter == reset_timer) intern_counter <= 20'd0;
                else if (state == `CONFIG_MODE)         intern_counter <= 20'd0;
                else                                    intern_counter <= intern_counter + 1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state           <= `IDLE;
            active_channel  <= `CHANNEL1;
            en_module       <= 1'b0;
        end
        else begin
            case(state)
                // wait config parameters
                `IDLE: begin
                    if(valid_config) state <= `CONFIG_MODE;
                    else             state <= `IDLE;
                end

                `CONFIG_MODE: begin
                    en_module     <= 1'b1;
                    if(manual_enable) begin
                        active_channel <= manual_channel;
                        state          <= `MANUAL_MODE;
                    end
                    else begin
                        active_channel <= channel_priority[1:0];
                        state          <= `AUTO_MODE;
                    end
                end

                `AUTO_MODE: begin

                    if      (valid_config)                   state          <= `CONFIG_MODE;
                    else if (intern_counter > reset_timer-1) active_channel <= select_new_channel(fallback_enable,channel_priority,err_count);
                    else                                     state          <= `AUTO_MODE;

                end

                `MANUAL_MODE: begin
                    if (valid_config)   state <= `CONFIG_MODE;
                    else                state <= `MANUAL_MODE;
                end

                default:                state <= `IDLE;

            endcase
        end
    end


    function [1:0] select_new_channel(
        input        fallback_enable,
        input [7:0]  channel_priority,
        input [31:0] err_count
        );

        reg [1:0] partial_result [0:1];

        begin
            //if fallback_enable = 1, the function returns the highest priority when counters are same.
            if(fallback_enable) begin

                // if priority channel counter 3 < priority channel counter 2, return priority channel 3, else return priority channel 2
                partial_result[0] = (priority_decode(channel_priority[7:6],err_count) < priority_decode(channel_priority[5:4],err_count)) ? channel_priority[7:6]: channel_priority[5:4];
                $display("teste: %d | chnel: ",priority_decode(channel_priority[7:6],err_count), channel_priority[7:6]);
                // if priority channel counter 1 < priority channel counter 0, return priority channel 1, else return priority channel 0
                partial_result[1] = (priority_decode(channel_priority[3:2],err_count) < priority_decode(channel_priority[1:0],err_count)) ? channel_priority[3:2]: channel_priority[1:0];
                
                select_new_channel = (priority_decode(partial_result[0],err_count) < priority_decode(partial_result[1],err_count)) ? partial_result[0] : partial_result[1];
            end
            //if fallback_enable = 0, the function stays the current channel when counters are same.
            else begin

                // if priority channel counter 3 <= priority channel counter 2, return priority channel 3, else return priority channel 2
                partial_result[0] = (priority_decode(channel_priority[7:6],err_count) <= priority_decode(channel_priority[5:4],err_count)) ? channel_priority[7:6]: channel_priority[5:4];
                
                // if priority channel counter 1 <= priority channel counter 0, return priority channel 1, else return priority channel 0
                partial_result[1] = (priority_decode(channel_priority[3:2],err_count) <= priority_decode(channel_priority[1:0],err_count)) ? channel_priority[3:2]: channel_priority[1:0];
            
                select_new_channel = (priority_decode(partial_result[0],err_count) <= priority_decode(partial_result[1],err_count)) ? partial_result[0] : partial_result[1];

            end
        end

    endfunction

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
                default   : priority_decode = 8'b0;
            endcase
        end
    endfunction

endmodule