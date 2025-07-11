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
    output [1:0]  mux_control
);
    //FSM States
    `define IDLE         2'd0
    `define CHOOSE_CHNEL 2'd1
    `define CHANGE_CHNEL 2'd2
    `define FUTURE_USE   2'd3

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
    reg [19:0] timer;

    assign error_count_ch0 = err_count[7:0];
    assign error_count_ch1 = err_count[8:15];
    assign error_count_ch2 = err_count[16:23];
    assign error_count_ch3 = err_count[24:31];

    assign signal_present[0]  = valid[0];
    assign signal_present[1]  = valid[1];
    assign signal_present[2]  = valid[2];
    assign signal_present[3]  = valid[3];
    
    assign mux_control = active_channel;

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

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state           <= `IDLE;
            active_channel  <= `CHANNEL1;
        end
        else begin
            case(state)
                // wait config parameters
                `IDLE: begin
                    if(valid_config)begin
                        state          <= `CHOOSE_CHNEL;
                        active_channel <= 

                        



                    end


                end

                `CHOOSE_CHNEL: begin
                    



                end

                `CHANGE_CHNEL: begin
                    


                end

                default: begin
                    
                end

            endcase
        end
    end

endmodule