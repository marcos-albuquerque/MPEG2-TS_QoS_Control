module counter_top(
    input wire clk,
    input wire rst,
    input wire [7:0]  r_data1,  // Byte 1: sync byte (deve ser 0x47)
    input wire [7:0]  r_data2,  // Byte 1: sync byte (deve ser 0x47)
    input wire [7:0]  r_data3,  // Byte 1: sync byte (deve ser 0x47)
    input wire [7:0]  r_data4,  // Byte 1: sync byte (deve ser 0x47)
    input wire [15:0] timer_in,
    input wire [3:0]  sync,

    output reg [31:0] cc_expected,  // contador de continuidade esperado

);

contador_mpeg2 uut1 (clk,rst,r_data1,timer_in,sync[0],cc_expected[7:0]);
contador_mpeg2 uut2 (clk,rst,r_data2,timer_in,sync[1],cc_expected[8:15]);
contador_mpeg2 uut3 (clk,rst,r_data3,timer_in,sync[2],cc_expected[16:23]);
contador_mpeg2 uut4 (clk,rst,r_data4,timer_in,sync[3],cc_expected[24:31]);

endmodule