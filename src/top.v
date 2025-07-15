
module top (
    input rst_n,

    input wclk1,
    input valid1,
    input [7:0] ts_data1,

    input wclk2,
    input valid2,
    input [7:0] ts_data2,
    
    input wclk3,
    input valid3,
    input [7:0] ts_data3,
    
    input wclk4,
    input valid4,
    input [7:0] ts_data4,

    input rclk,
    
    // Config interface
    input mm_write_en,
    input mm_read_en,
    input [7:0] mm_addr,
    input [31:0] mm_wdata,
    input [31:0] mm_rdata,

    // Outputs
    output clk_out,
    output valid_out,
    output syn_out,
    output [7:0] ts_data_out

);
    
endmodule