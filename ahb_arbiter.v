`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.10.2026 19:08:33
// Design Name: 
// Module Name: ahb_arbiter
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

module ahb_arbiter (
    input  wire       HCLK,
    input  wire       HRESETn,
    input  wire       HREADY,
    
    // Master Requests & Locks
    input  wire       HBUSREQ_0,
    input  wire       HLOCK_0,
    input  wire       HBUSREQ_1,
    input  wire       HLOCK_1,

    // Burst tracking from bus
    input  wire [1:0] HTRANS,
    input  wire [2:0] HBURST,

    // Arbitration Outputs
    output reg        HGRANT_0,
    output reg        HGRANT_1,
    output reg  [3:0] HMASTER,
    output reg        HMASTLOCK
);

    // Current bus ownership
    reg [3:0] next_master;
    reg       next_lock;

    // Simple priority arbitration: Master 0 has priority over Master 1
    always @(*) begin
        if (HBUSREQ_0) begin
            next_master = 4'd0;
            next_lock   = HLOCK_0;
        end else if (HBUSREQ_1) begin
            next_master = 4'd1;
            next_lock   = HLOCK_1;
        end else begin
            next_master = HMASTER; // Maintain current master on idle
            next_lock   = 1'b0;
        end
    end

    // Master Grant and Master ID update occurs when current transfer completes (HREADY=1)
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HGRANT_0  <= 1'b1; // Default grant to Master 0
            HGRANT_1  <= 1'b0;
            HMASTER   <= 4'd0;
            HMASTLOCK <= 1'b0;
        end else if (HREADY) begin
            HMASTER   <= next_master;
            HMASTLOCK <= next_lock;
            HGRANT_0  <= (next_master == 4'd0);
            HGRANT_1  <= (next_master == 4'd1);
        end
    end

endmodule