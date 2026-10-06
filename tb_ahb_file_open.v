`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.10.2026 19:14:22
// Design Name: 
// Module Name: tb_ahb_file_open
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

module tb_ahb_file_open;

    reg         HCLK;
    reg         HRESETn;

    // Master 0 Interface
    reg         HBUSREQ_0;
    reg         HLOCK_0;
    wire        HGRANT_0;
    reg  [31:0] HADDR_0;
    reg  [1:0]  HTRANS_0;
    reg         HWRITE_0;
    reg  [2:0]  HSIZE_0;
    reg  [2:0]  HBURST_0;
    reg  [31:0] HWDATA_0;

    // Master 1 Interface
    reg         HBUSREQ_1;
    reg         HLOCK_1;
    wire        HGRANT_1;
    reg  [31:0] HADDR_1;
    reg  [1:0]  HTRANS_1;
    reg         HWRITE_1;
    reg  [2:0]  HSIZE_1;
    reg  [2:0]  HBURST_1;
    reg  [31:0] HWDATA_1;

    // Bus Return Responses
    wire [31:0] HRDATA;
    wire        HREADY;
    wire        HRESP;

    // File I/O Variables
    integer       file_handle;
    integer       scan_status;
    reg [8*120:1] line_buffer;
    integer       master_id;
    reg [7:0]     cmd;
    reg [31:0]    target_addr;
    reg [31:0]    target_data;
    integer       wait_cycles;
    integer       test_num   = 0;
    integer       pass_count = 0;
    integer       fail_count = 0;

    // Clock: 100 MHz (Period = 10ns)
    initial HCLK = 0;
    always #5 HCLK = ~HCLK;

    // Instantiate Top AHB Multi-Master System
    ahb_system_top u_dut (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HBUSREQ_0(HBUSREQ_0), .HLOCK_0(HLOCK_0), .HGRANT_0(HGRANT_0),
        .HADDR_0(HADDR_0), .HTRANS_0(HTRANS_0), .HWRITE_0(HWRITE_0),
        .HSIZE_0(HSIZE_0), .HBURST_0(HBURST_0), .HWDATA_0(HWDATA_0),
        .HBUSREQ_1(HBUSREQ_1), .HLOCK_1(HLOCK_1), .HGRANT_1(HGRANT_1),
        .HADDR_1(HADDR_1), .HTRANS_1(HTRANS_1), .HWRITE_1(HWRITE_1),
        .HSIZE_1(HSIZE_1), .HBURST_1(HBURST_1), .HWDATA_1(HWDATA_1),
        .HRDATA(HRDATA), .HREADY(HREADY), .HRESP(HRESP)
    );

    // =========================================================================
    // Master 0 Arbitration & Write Task
    // =========================================================================
    task m0_write(input [31:0] addr, input [31:0] data, input integer idle_cycles);
        begin
            @(posedge HCLK);
            HBUSREQ_0 <= 1'b1;
            while (!HGRANT_0 || !HREADY) @(posedge HCLK);

            // Address Phase
            HADDR_0  <= addr;
            HTRANS_0 <= 2'b10; // NONSEQ
            HWRITE_0 <= 1'b1;
            HSIZE_0  <= 3'b010;

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);

            // Data Phase
            HWDATA_0  <= data;
            HTRANS_0  <= 2'b00; // IDLE
            HWRITE_0  <= 1'b0;
            HBUSREQ_0 <= 1'b0;

            if (idle_cycles > 0) repeat(idle_cycles) @(posedge HCLK);
        end
    endtask

    // =========================================================================
    // Master 0 Arbitration & Read Task
    // =========================================================================
    task m0_read(input [31:0] addr, input [31:0] exp_data, input integer idle_cycles);
        begin
            @(posedge HCLK);
            HBUSREQ_0 <= 1'b1;
            while (!HGRANT_0 || !HREADY) @(posedge HCLK);

            // Address Phase
            HADDR_0  <= addr;
            HTRANS_0 <= 2'b10;
            HWRITE_0 <= 1'b0;
            HSIZE_0  <= 3'b010;

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);
            HTRANS_0  <= 2'b00;
            HBUSREQ_0 <= 1'b0;

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);

            // Verify Data
            if (HRDATA === exp_data) begin
                $display("[%0t ns] [PASS] Test #%02d | Master 0 READ @ 0x%08h | Match: 0x%08h", 
                         $time, test_num, addr, HRDATA);
                pass_count = pass_count + 1;
            end else begin
                $display("[%0t ns] [FAIL] Test #%02d | Master 0 READ @ 0x%08h | Exp: 0x%08h, Got: 0x%08h", 
                         $time, test_num, addr, exp_data, HRDATA);
                fail_count = fail_count + 1;
            end

            if (idle_cycles > 0) repeat(idle_cycles) @(posedge HCLK);
        end
    endtask

    // =========================================================================
    // Master 1 Arbitration & Write Task
    // =========================================================================
    task m1_write(input [31:0] addr, input [31:0] data, input integer idle_cycles);
        begin
            @(posedge HCLK);
            HBUSREQ_1 <= 1'b1;
            while (!HGRANT_1 || !HREADY) @(posedge HCLK);

            // Address Phase
            HADDR_1  <= addr;
            HTRANS_1 <= 2'b10;
            HWRITE_1 <= 1'b1;
            HSIZE_1  <= 3'b010;

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);

            // Data Phase
            HWDATA_1  <= data;
            HTRANS_1  <= 2'b00;
            HWRITE_1  <= 1'b0;
            HBUSREQ_1 <= 1'b0;

            if (idle_cycles > 0) repeat(idle_cycles) @(posedge HCLK);
        end
    endtask

    // =========================================================================
    // Master 1 Arbitration & Read Task
    // =========================================================================
    task m1_read(input [31:0] addr, input [31:0] exp_data, input integer idle_cycles);
        begin
            @(posedge HCLK);
            HBUSREQ_1 <= 1'b1;
            while (!HGRANT_1 || !HREADY) @(posedge HCLK);

            // Address Phase
            HADDR_1  <= addr;
            HTRANS_1 <= 2'b10;
            HWRITE_1 <= 1'b0;
            HSIZE_1  <= 3'b010;

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);
            HTRANS_1  <= 2'b00;
            HBUSREQ_1 <= 1'b0;

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);

            // Verify Data
            if (HRDATA === exp_data) begin
                $display("[%0t ns] [PASS] Test #%02d | Master 1 READ @ 0x%08h | Match: 0x%08h", 
                         $time, test_num, addr, HRDATA);
                pass_count = pass_count + 1;
            end else begin
                $display("[%0t ns] [FAIL] Test #%02d | Master 1 READ @ 0x%08h | Exp: 0x%08h, Got: 0x%08h", 
                         $time, test_num, addr, exp_data, HRDATA);
                fail_count = fail_count + 1;
            end

            if (idle_cycles > 0) repeat(idle_cycles) @(posedge HCLK);
        end
    endtask

    // =========================================================================
    // Main File Reader Process
    // =========================================================================
    initial begin
        $dumpfile("ahb_file_waves.vcd");
        $dumpvars(0, tb_ahb_file_open);

        // Reset Signals
        HRESETn   = 0;
        HBUSREQ_0 = 0; HLOCK_0 = 0; HADDR_0 = 0; HTRANS_0 = 0; HWRITE_0 = 0; HWDATA_0 = 0; HSIZE_0 = 0; HBURST_0 = 0;
        HBUSREQ_1 = 0; HLOCK_1 = 0; HADDR_1 = 0; HTRANS_1 = 0; HWRITE_1 = 0; HWDATA_1 = 0; HSIZE_1 = 0; HBURST_1 = 0;

        #40;
        HRESETn = 1;
        #10;

        // Open File
        file_handle = $fopen("testcases.txt", "r");
        if (file_handle == 0) begin
            $display("[FATAL] Could not open testcases.txt! Make sure it exists in the simulation working directory.");
            $finish;
        end

        $display("======================================================================");
        $display("     STARTING MULTI-MASTER AHB SIMULATION USING $fopen METHOD         ");
        $display("======================================================================");

        // Parse line by line
        while (!$feof(file_handle)) begin
            scan_status = $fgets(line_buffer, file_handle);
            if (scan_status != 0) begin
                if (line_buffer[8*120:8*119+1] != "#" && line_buffer[8*120:8*119+1] != "\n") begin
                    scan_status = $sscanf(line_buffer, "%d %c %h %h %d", master_id, cmd, target_addr, target_data, wait_cycles);
                    if (scan_status >= 4) begin
                        test_num = test_num + 1;

                        if (master_id == 0) begin
                            if (cmd == "W" || cmd == "w")
                                m0_write(target_addr, target_data, wait_cycles);
                            else if (cmd == "R" || cmd == "r")
                                m0_read(target_addr, target_data, wait_cycles);
                        end 
                        else if (master_id == 1) begin
                            if (cmd == "W" || cmd == "w")
                                m1_write(target_addr, target_data, wait_cycles);
                            else if (cmd == "R" || cmd == "r")
                                m1_read(target_addr, target_data, wait_cycles);
                        end
                    end
                end
            end
        end

        $fclose(file_handle);

        #50;
        $display("======================================================================");
        $display("                         TEST SUMMARY REPORT                          ");
        $display("======================================================================");
        $display(" Total Read Checks: %0d", pass_count + fail_count);
        $display(" Passed:            %0d", pass_count);
        $display(" Failed:            %0d", fail_count);
        if (fail_count == 0 && (pass_count > 0)) begin
            $display(" STATUS:            >>> ALL MULTI-MASTER TESTS PASSED <<<");
        end else begin
            $display(" STATUS:            >>> VERIFICATION FAILED <<<");
        end
        $display("======================================================================");
        $finish;
    end

endmodule
