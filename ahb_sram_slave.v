`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.10.2026 19:17:46
// Design Name: 
// Module Name: ahb_sram_slave
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

module ahb_sram_slave #(
    parameter MEM_DEPTH  = 256,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  HCLK,
    input  wire                  HRESETn,
    input  wire                  HSEL,
    input  wire [ADDR_WIDTH-1:0] HADDR,
    input  wire [1:0]            HTRANS,
    input  wire                  HWRITE,
    input  wire [2:0]            HSIZE,
    input  wire                  HREADY,
    input  wire [DATA_WIDTH-1:0] HWDATA,
    output wire                  HREADYOUT,
    output wire                  HRESP,
    output wire [DATA_WIDTH-1:0] HRDATA
);

    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    reg [ADDR_WIDTH-1:0] addr_q;
    reg                  write_q;
    reg                  active_q;

    wire valid_transfer = HSEL && HREADY && (HTRANS == 2'b10 || HTRANS == 2'b11);

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_q   <= {ADDR_WIDTH{1'b0}};
            write_q  <= 1'b0;
            active_q <= 1'b0;
        end else if (HREADY) begin
            addr_q   <= HADDR;
            write_q  <= HWRITE;
            active_q <= valid_transfer;
        end
    end

    always @(posedge HCLK) begin
        if (HREADY && active_q && write_q) begin
            mem[addr_q[9:2]] <= HWDATA;
        end
    end

    assign HRDATA    = (active_q && !write_q) ? mem[addr_q[9:2]] : {DATA_WIDTH{1'b0}};
    assign HREADYOUT = 1'b1;
    assign HRESP     = 1'b0;

endmodule