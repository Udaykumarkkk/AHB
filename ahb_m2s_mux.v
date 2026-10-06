`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.10.2026 19:09:24
// Design Name: 
// Module Name: ahb_m2s_mux
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

module ahb_m2s_mux #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire [3:0]            HMASTER,

    // Master 0 Inputs
    input  wire [ADDR_WIDTH-1:0] HADDR_0,
    input  wire [1:0]            HTRANS_0,
    input  wire                  HWRITE_0,
    input  wire [2:0]            HSIZE_0,
    input  wire [2:0]            HBURST_0,
    input  wire [DATA_WIDTH-1:0] HWDATA_0,

    // Master 1 Inputs
    input  wire [ADDR_WIDTH-1:0] HADDR_1,
    input  wire [1:0]            HTRANS_1,
    input  wire                  HWRITE_1,
    input  wire [2:0]            HSIZE_1,
    input  wire [2:0]            HBURST_1,
    input  wire [DATA_WIDTH-1:0] HWDATA_1,

    // Muxed Bus Outputs
    output reg  [ADDR_WIDTH-1:0] HADDR,
    output reg  [1:0]            HTRANS,
    output reg                   HWRITE,
    output reg  [2:0]            HSIZE,
    output reg  [2:0]            HBURST,
    output reg  [DATA_WIDTH-1:0] HWDATA
);

    always @(*) begin
        case (HMASTER)
            4'd0: begin
                HADDR  = HADDR_0;
                HTRANS = HTRANS_0;
                HWRITE = HWRITE_0;
                HSIZE  = HSIZE_0;
                HBURST = HBURST_0;
                HWDATA = HWDATA_0;
            end
            4'd1: begin
                HADDR  = HADDR_1;
                HTRANS = HTRANS_1;
                HWRITE = HWRITE_1;
                HSIZE  = HSIZE_1;
                HBURST = HBURST_1;
                HWDATA = HWDATA_1;
            end
            default: begin
                HADDR  = {ADDR_WIDTH{1'b0}};
                HTRANS = 2'b00; // IDLE
                HWRITE = 1'b0;
                HSIZE  = 3'b010;
                HBURST = 3'b000;
                HWDATA = {DATA_WIDTH{1'b0}};
            end
        endcase
    end

endmodule
