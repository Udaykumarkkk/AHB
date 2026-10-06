`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.10.2026 19:10:14
// Design Name: 
// Module Name: ahb_system_top
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


`timescale 1ns/1ps

module ahb_system_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  HCLK,
    input  wire                  HRESETn,

    // Master 0 Interface
    input  wire                  HBUSREQ_0,
    input  wire                  HLOCK_0,
    output wire                  HGRANT_0,
    input  wire [ADDR_WIDTH-1:0] HADDR_0,
    input  wire [1:0]            HTRANS_0,
    input  wire                  HWRITE_0,
    input  wire [2:0]            HSIZE_0,
    input  wire [2:0]            HBURST_0,
    input  wire [DATA_WIDTH-1:0] HWDATA_0,

    // Master 1 Interface
    input  wire                  HBUSREQ_1,
    input  wire                  HLOCK_1,
    output wire                  HGRANT_1,
    input  wire [ADDR_WIDTH-1:0] HADDR_1,
    input  wire [1:0]            HTRANS_1,
    input  wire                  HWRITE_1,
    input  wire [2:0]            HSIZE_1,
    input  wire [2:0]            HBURST_1,
    input  wire [DATA_WIDTH-1:0] HWDATA_1,

    // Common System Responses to Masters
    output wire [DATA_WIDTH-1:0] HRDATA,
    output wire                  HREADY,
    output wire                  HRESP
);

    // Internal Bus & Arbitration Signals
    wire [3:0]            HMASTER;
    wire                  HMASTLOCK;
    wire [ADDR_WIDTH-1:0] HADDR;
    wire [1:0]            HTRANS;
    wire                  HWRITE;
    wire [2:0]            HSIZE;
    wire [2:0]            HBURST;
    wire [DATA_WIDTH-1:0] HWDATA;

    // Slave Selects & Responses
    wire                  HSEL_0;
    wire [DATA_WIDTH-1:0] HRDATA_0;
    wire                  HREADYOUT_0;
    wire                  HRESP_0;

    wire                  HSEL_1;
    wire [DATA_WIDTH-1:0] HRDATA_1;
    wire                  HREADYOUT_1;
    wire                  HRESP_1;

    // 1. Central Arbiter
    ahb_arbiter u_arbiter (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HREADY(HREADY),
        .HBUSREQ_0(HBUSREQ_0),
        .HLOCK_0(HLOCK_0),
        .HBUSREQ_1(HBUSREQ_1),
        .HLOCK_1(HLOCK_1),
        .HTRANS(HTRANS),
        .HBURST(HBURST),
        .HGRANT_0(HGRANT_0),
        .HGRANT_1(HGRANT_1),
        .HMASTER(HMASTER),
        .HMASTLOCK(HMASTLOCK)
    );

    // 2. Master-to-Slave MUX
    ahb_m2s_mux #(ADDR_WIDTH, DATA_WIDTH) u_m2s_mux (
        .HMASTER(HMASTER),
        .HADDR_0(HADDR_0), .HTRANS_0(HTRANS_0), .HWRITE_0(HWRITE_0),
        .HSIZE_0(HSIZE_0), .HBURST_0(HBURST_0), .HWDATA_0(HWDATA_0),
        .HADDR_1(HADDR_1), .HTRANS_1(HTRANS_1), .HWRITE_1(HWRITE_1),
        .HSIZE_1(HSIZE_1), .HBURST_1(HBURST_1), .HWDATA_1(HWDATA_1),
        .HADDR(HADDR), .HTRANS(HTRANS), .HWRITE(HWRITE),
        .HSIZE(HSIZE), .HBURST(HBURST), .HWDATA(HWDATA)
    );

    // 3. Address Decoder & Return Multiplexer (Interconnect)
    ahb_interconnect #(ADDR_WIDTH, DATA_WIDTH) u_interconnect (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HWDATA(HWDATA),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP),
        .HSEL_0(HSEL_0),
        .HRDATA_0(HRDATA_0),
        .HREADYOUT_0(HREADYOUT_0),
        .HRESP_0(HRESP_0),
        .HSEL_1(HSEL_1),
        .HRDATA_1(HRDATA_1),
        .HREADYOUT_1(HREADYOUT_1),
        .HRESP_1(HRESP_1)
    );

    // 4. Slaves
    ahb_sram_slave #(256, ADDR_WIDTH, DATA_WIDTH) u_sram_0 (
        .HCLK(HCLK), .HRESETn(HRESETn), .HSEL(HSEL_0), .HADDR(HADDR),
        .HTRANS(HTRANS), .HWRITE(HWRITE), .HSIZE(HSIZE), .HREADY(HREADY),
        .HWDATA(HWDATA), .HREADYOUT(HREADYOUT_0), .HRESP(HRESP_0), .HRDATA(HRDATA_0)
    );

    ahb_sram_slave #(256, ADDR_WIDTH, DATA_WIDTH) u_sram_1 (
        .HCLK(HCLK), .HRESETn(HRESETn), .HSEL(HSEL_1), .HADDR(HADDR),
        .HTRANS(HTRANS), .HWRITE(HWRITE), .HSIZE(HSIZE), .HREADY(HREADY),
        .HWDATA(HWDATA), .HREADYOUT(HREADYOUT_1), .HRESP(HRESP_1), .HRDATA(HRDATA_1)
    );

endmodule
