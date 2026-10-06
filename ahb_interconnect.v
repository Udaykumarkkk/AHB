`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.10.2026 19:16:54
// Design Name: 
// Module Name: ahb_interconnect
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

module ahb_interconnect #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  HCLK,
    input  wire                  HRESETn,

    // Master Interface (Muxed from M2S)
    input  wire [ADDR_WIDTH-1:0] HADDR,
    input  wire [1:0]            HTRANS,
    input  wire                  HWRITE,
    input  wire [2:0]            HSIZE,
    input  wire [2:0]            HBURST,
    input  wire [DATA_WIDTH-1:0] HWDATA,
    output wire [DATA_WIDTH-1:0] HRDATA,
    output wire                  HREADY,
    output wire                  HRESP,

    // Slave 0 Interface
    output wire                  HSEL_0,
    input  wire [DATA_WIDTH-1:0] HRDATA_0,
    input  wire                  HREADYOUT_0,
    input  wire                  HRESP_0,

    // Slave 1 Interface
    output wire                  HSEL_1,
    input  wire [DATA_WIDTH-1:0] HRDATA_1,
    input  wire                  HREADYOUT_1,
    input  wire                  HRESP_1
);

    // Decode logic (Address Phase)
    wire sel_s0 = (HADDR[31:16] == 16'h0000);
    wire sel_s1 = (HADDR[31:16] == 16'h2000);

    assign HSEL_0 = sel_s0;
    assign HSEL_1 = sel_s1;

    // Track active slave into Data Phase
    reg [1:0] slave_sel_q;
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            slave_sel_q <= 2'b00;
        end else if (HREADY) begin
            if (sel_s0)      slave_sel_q <= 2'b00;
            else if (sel_s1) slave_sel_q <= 2'b01;
            else             slave_sel_q <= 2'b10; // Default Error Slave
        end
    end

    // Default Slave: 2-cycle Error Generator
    reg err_state_q;
    reg default_ready;
    reg default_resp;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            err_state_q   <= 1'b0;
            default_ready <= 1'b1;
            default_resp  <= 1'b0;
        end else begin
            if (slave_sel_q == 2'b10 && (HTRANS != 2'b00)) begin
                if (!err_state_q) begin
                    err_state_q   <= 1'b1;
                    default_ready <= 1'b0;
                    default_resp  <= 1'b1;
                end else begin
                    err_state_q   <= 1'b0;
                    default_ready <= 1'b1;
                    default_resp  <= 1'b1;
                end
            end else begin
                err_state_q   <= 1'b0;
                default_ready <= 1'b1;
                default_resp  <= 1'b0;
            end
        end
    end

    // Read Data & Response Mux
    assign HRDATA = (slave_sel_q == 2'b00) ? HRDATA_0 :
                    (slave_sel_q == 2'b01) ? HRDATA_1 : {DATA_WIDTH{1'b0}};

    assign HREADY = (slave_sel_q == 2'b00) ? HREADYOUT_0 :
                    (slave_sel_q == 2'b01) ? HREADYOUT_1 : default_ready;

    assign HRESP  = (slave_sel_q == 2'b00) ? HRESP_0 :
                    (slave_sel_q == 2'b01) ? HRESP_1 : default_resp;

endmodule