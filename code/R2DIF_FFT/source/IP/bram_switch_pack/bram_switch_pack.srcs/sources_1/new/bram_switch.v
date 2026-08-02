`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/19 14:45:06
// Design Name: 
// Module Name: bram_switch
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
//////////////////////////////////////////////////////////////////////////////////
// bram_switch
//
// Purpose
// -------
// Selects the single owner of one True Dual-Port BRAM Port A:
//   select_fft = 0 : AXI BRAM Controller owns Port A (PYNQ reads/writes data)
//   select_fft = 1 : FFT core owns Port A (FFT calculation is running)
//
// The FFT core's Port B connects DIRECTLY to BRAM Port B in Block Design.
// Do not connect the AXI BRAM Controller directly to the BRAM as well.
//////////////////////////////////////////////////////////////////////////////////

module bram_switch #(
    // AXI BRAM Controller in this design exports a 13-bit native BRAM address.
    parameter integer CTRL_ADDR_WIDTH = 13,
    // The FFT IP and Block Memory Generator use 32-bit address buses.
    parameter integer FFT_ADDR_WIDTH  = 32,
    parameter integer MEM_ADDR_WIDTH  = 32,
    parameter integer DATA_WIDTH      = 32
) (
    // 0: controller owns BRAM Port A; 1: FFT owns BRAM Port A
    input  wire                      select_fft,

    // ----------------------------------------------------------
    // AXI BRAM Controller native BRAM-Port-A-side signals
    // ----------------------------------------------------------
    input  wire [CTRL_ADDR_WIDTH-1:0] ctrl_addr,
    input  wire [DATA_WIDTH-1:0]     ctrl_wrdata,
    input  wire                      ctrl_en,
    input  wire [(DATA_WIDTH/8)-1:0] ctrl_we,
    output wire [DATA_WIDTH-1:0]     ctrl_rddata,

    // ----------------------------------------------------------
    // FFT core BRAM Port A signals
    // ----------------------------------------------------------
    input  wire [FFT_ADDR_WIDTH-1:0]  fft_addr_a,
    input  wire [DATA_WIDTH-1:0]     fft_wrdata_a,
    input  wire                      fft_en_a,
    input  wire [(DATA_WIDTH/8)-1:0] fft_we_a,
    output wire [DATA_WIDTH-1:0]     fft_rddata_a,

    // ----------------------------------------------------------
    // Signals sent to the physical Block Memory Generator Port A
    // ----------------------------------------------------------
    output wire [MEM_ADDR_WIDTH-1:0]  mem_addr_a,
    output wire [DATA_WIDTH-1:0]     mem_wrdata_a,
    output wire                      mem_en_a,
    output wire [(DATA_WIDTH/8)-1:0] mem_we_a,
    input  wire [DATA_WIDTH-1:0]     mem_rddata_a
);

    // One and only one master drives every BRAM Port A control signal.
    // The controller address is byte-addressed.  Zero extension preserves it
    // while matching the 32-bit address bus used by the FFT and BRAM IP.
    assign mem_addr_a   = select_fft ? fft_addr_a :
                          {{(MEM_ADDR_WIDTH-CTRL_ADDR_WIDTH){1'b0}}, ctrl_addr};
    assign mem_wrdata_a = select_fft ? fft_wrdata_a : ctrl_wrdata;
    assign mem_en_a     = select_fft ? fft_en_a     : ctrl_en;
    assign mem_we_a     = select_fft ? fft_we_a     : ctrl_we;

    // Both inputs may observe the BRAM output.  Only the selected master
    // uses it, because the other master must remain idle while unselected.
    assign ctrl_rddata  = mem_rddata_a;
    assign fft_rddata_a = mem_rddata_a;

endmodule

