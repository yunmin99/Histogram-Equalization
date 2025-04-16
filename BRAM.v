`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/11 20:42:27
// Design Name: 
// Module Name: BRAM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BRAM(
    we,
    clk,
    addr, 
    dout,
    din,
    start_he
);

parameter DWIDTH = 8;
parameter MEM_SIZE = 545920;
parameter AWIDTH = 21;

input we;
input clk;
input [AWIDTH-1:0] addr;
input [DWIDTH-1:0] din;
input start_he;
output reg [DWIDTH-1:0] dout;

(* ram_style = "block" *)reg [DWIDTH-1:0] ram[0:MEM_SIZE-1];


always @(posedge clk) begin
    if(we) begin
        ram[addr] <= din;
    end
    if (start_he) begin
        dout <= ram[addr];
    end
end

endmodule 