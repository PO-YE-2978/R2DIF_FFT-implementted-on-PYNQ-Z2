`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/15 14:07:02
// Design Name: 
// Module Name: complex_mult
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


`timescale 1ns / 1ps

// Q1.15 complex multiplier
// Input/output packing: [31:16] = imaginary, [15:0] = real.
module complex_mult(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [31:0] data_in,
    input  wire [31:0] twiddle_in,
    output reg  [31:0] data_out
);

    wire signed [15:0] br = data_in[15:0];
    wire signed [15:0] bi = data_in[31:16];
    wire signed [15:0] wr = twiddle_in[15:0];
    wire signed [15:0] wi = twiddle_in[31:16];

    // Four Q1.15 multiplications produce Q2.30 products.
    reg signed [31:0] t1, t2, t3, t4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t1 <= 32'sd0;
            t2 <= 32'sd0;
            t3 <= 32'sd0;
            t4 <= 32'sd0;
        end else if (en) begin
            t1 <= br * wr;
            t2 <= bi * wi;
            t3 <= br * wi;
            t4 <= bi * wr;
        end
    end

    // Still Q2.30 (with one extra bit for addition/subtraction).
    wire signed [32:0] pr_full = t1 - t2;
    wire signed [32:0] pi_full = t3 + t4;

    // Convert Q2.30 to Q1.15 BEFORE testing for Q1.15 saturation.
    wire signed [32:0] pr_q15 = pr_full >>> 15;
    wire signed [32:0] pi_q15 = pi_full >>> 15;

    function automatic [15:0] sat_q15;
        input signed [32:0] value;
        begin
            if (value > 33'sd32767)
                sat_q15 = 16'h7FFF;
            else if (value < -33'sd32768)
                sat_q15 = 16'h8000;
            else
                sat_q15 = value[15:0];
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'd0;
        end else if (en) begin
            data_out <= {sat_q15(pi_q15), sat_q15(pr_q15)};
        end
    end

endmodule
