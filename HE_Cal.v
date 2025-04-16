`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/12 00:19:37
// Design Name: 
// Module Name: HE_Cal
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

 module HE_Calc(
    clk,
    HE_Start,
    reset,
    din,
    dst_out,
    we1,
    we2,
    state
);

parameter DWIDTH    = 8;
parameter AWIDTH    = 21;
parameter MEM_SIZE  = 545920;
parameter TOTAL_PIX = 1091840;
parameter MAX_VALUE = 256;
parameter IDLE      = 7'b0000001;
parameter INIT      = 7'b0000010;
parameter HIST1_LUT = 7'b0000100; 
parameter HIST2_LUT = 7'b0001000;
parameter CDF_LUT   = 7'b0010000;
parameter DST_LUT   = 7'b0100000;
parameter DONE      = 7'b1000000;

input                   clk;
input                   reset;
input                   we1;
input                   we2;
input                   HE_Start;
input      [DWIDTH-1:0] din;
output reg [AWIDTH-1:0] dst_out;
output     [6:0]        state;

reg init_done, hist1_done, hist2_done, cdf_done, dst_done, out_done;
reg [6:0] current_state;
reg [6:0] next_state;
reg [AWIDTH-1:0] counter;
reg [AWIDTH-1:0] calcGrayHist [0:MAX_VALUE-1];
reg [AWIDTH-1:0] CDF          [0:MAX_VALUE-1];
reg [AWIDTH-1:0] DST          [0:MAX_VALUE-1];
reg [DWIDTH-1:0] din_reg;
reg [6:0] prev_state;

reg init_start, hist1_start, hist2_start, cdf_start, dst_start, out_start;

assign state = current_state;

always @(posedge clk or posedge reset) begin
    if (reset)
        prev_state <= IDLE;
    else
        prev_state <= current_state;
end

always @(posedge clk) begin
    if (current_state != prev_state) begin
        case (current_state)
            INIT      : init_start  <= 1;
            HIST1_LUT : hist1_start <= 1;
            HIST2_LUT : hist2_start <= 1;
            CDF_LUT   : cdf_start   <= 1;
            DST_LUT   : dst_start   <= 1;
            DONE      : out_start   <= 1;
        endcase
    end
end

always @ (*) begin
    case(current_state)
        IDLE      : next_state = (HE_Start == 1)    ? INIT      : IDLE;
        INIT      : next_state = (init_done == 1)   ? HIST1_LUT : INIT;
        HIST1_LUT : next_state = (hist1_done == 1)  ? HIST2_LUT : HIST1_LUT;
        HIST2_LUT : next_state = (hist2_done == 1)  ? CDF_LUT   : HIST2_LUT;
        CDF_LUT   : next_state = (cdf_done == 1)    ? DST_LUT   : CDF_LUT;
        DST_LUT   : next_state = (dst_done == 1)    ? DONE      : DST_LUT;
        DONE      : next_state = (out_done == 1)    ? IDLE      : DONE;
        default   : next_state = current_state;  
    endcase
end

always @ (posedge clk or posedge reset) begin
    if (reset)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(posedge clk) begin
    din_reg <= din;  
end

always @ (posedge clk) begin
    case(current_state)
        IDLE : begin
            if(HE_Start) begin
                init_done  <= 0; init_start <= 1;
                hist1_done <= 0; hist1_start <= 0;
                hist2_done <= 0; hist2_start <= 0;
                cdf_done   <= 0; cdf_start   <= 0;
                dst_done   <= 0; dst_start   <= 0;
                out_done   <= 0; out_start   <= 0;
                counter    <= 0;
            end
        end

        INIT : begin
            if (init_start) begin
                counter <= 0;
                init_start <= 0;
            end else if(counter < MAX_VALUE) begin
                calcGrayHist[counter] <= 0;
                CDF[counter]          <= 0;
                DST[counter]          <= 0;
                counter <= counter + 1;
            end else begin
                init_done <= 1;
            end
        end

        HIST1_LUT : begin
            if (hist1_start) begin
                counter <= 0;
                hist1_start <= 0;
            end else if(we1 && (counter < MEM_SIZE)) begin
                calcGrayHist[din_reg] <= calcGrayHist[din_reg] + 1;
                counter <= counter + 1;
            end else if(counter == MEM_SIZE) begin
                hist1_done <= 1;
                hist2_start <= 1;
            end
        end

        HIST2_LUT : begin
            if (hist2_start) begin
                counter <= 0;
                hist2_start <= 0;
            end else if(we2 && (counter < MEM_SIZE)) begin
                calcGrayHist[din_reg] <= calcGrayHist[din_reg] + 1;
                counter <= counter + 1;
            end else if(counter == MEM_SIZE) begin
                hist2_done <= 1;
                cdf_start <= 1;
            end
        end

        CDF_LUT : begin
            if (cdf_start) begin
                counter <= 0;
                cdf_start <= 0;
            end else if(counter < MAX_VALUE) begin
                if (counter == 0)
                    CDF[0] <= calcGrayHist[0];
                else
                    CDF[counter] <= CDF[counter - 1] + calcGrayHist[counter];
                counter <= counter + 1;
            end else begin
                cdf_done <= 1;
                dst_start <= 1;
            end
        end

        DST_LUT : begin
            if (dst_start) begin
                counter <= 0;
                dst_start <= 0;
            end else if (counter < MAX_VALUE) begin
                DST[counter] <= (CDF[counter] * (MAX_VALUE - 1) + (TOTAL_PIX >> 1)) / TOTAL_PIX;
                counter <= counter + 1;
            end else begin
                dst_done <= 1;
                out_start <= 1;
            end
        end

        DONE : begin
            if (out_start) begin
                counter <= 0;
                out_start <= 0;
            end else if(counter < MAX_VALUE) begin
                dst_out <= DST[counter];
                counter <= counter + 1;
            end else begin
                out_done <= 1;
            end
        end
    endcase
end

endmodule