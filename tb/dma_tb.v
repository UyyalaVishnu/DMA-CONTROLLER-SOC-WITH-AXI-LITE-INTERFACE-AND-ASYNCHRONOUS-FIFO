// ============================================================================
// Testbench : dma_tb
// Tool      : Cadence Xcelium
// FIX: All capitalised Verilog keywords lowercased throughout.
// ============================================================================
`timescale 1ns/1ps
`default_nettype none

module dma_tb;

// ============================================================================
// Parameters
// ============================================================================
parameter DATA_WIDTH    = 32;
parameter ADDR_WIDTH    = 4;
parameter COUNT_WIDTH   = 16;
parameter FIFO_DEPTH    = 16;
parameter [31:0] ADDR_START  = 32'h0000_0000;
parameter [31:0] ADDR_LENGTH = 32'h0000_0004;
parameter [31:0] ADDR_STATUS = 32'h0000_0008;
parameter [1:0]  AXI_OKAY    = 2'b00;
parameter AXI_CLK_PERIOD  = 10;   // 100 MHz
parameter DMA_CLK_PERIOD  = 7;    // ~143 MHz
parameter TIMEOUT_CYCLES  = 5000;

// ============================================================================
// DUT signals
// ============================================================================
reg        axi_clk, dma_clk, rst_n;
reg  [3:0] s_axi_awaddr;
reg        s_axi_awvalid;
wire       s_axi_awready;
reg  [31:0] s_axi_wdata;
reg        s_axi_wvalid;
wire       s_axi_wready;
wire [1:0] s_axi_bresp;
wire       s_axi_bvalid;
reg        s_axi_bready;
reg  [3:0] s_axi_araddr;
reg        s_axi_arvalid;
wire       s_axi_arready;
wire [31:0] s_axi_rdata;
wire [1:0] s_axi_rresp;
wire       s_axi_rvalid;
reg        s_axi_rready;
wire       done;
wire       irq;

// ============================================================================
// Bookkeeping
// ============================================================================
integer pass_count;
integer fail_count;
integer tc_num;
integer timeout;
reg     irq_seen;
reg     done_seen;
reg [31:0] read_data;

// ============================================================================
// DUT instantiation
// ============================================================================
dma #(
    .DATA_WIDTH  (DATA_WIDTH),
    .ADDR_WIDTH  (ADDR_WIDTH),
    .COUNT_WIDTH (COUNT_WIDTH)
) dut (
    .axi_clk       (axi_clk),
    .dma_clk       (dma_clk),
    .rst_n         (rst_n),
    .s_axi_awaddr  (s_axi_awaddr),
    .s_axi_awvalid (s_axi_awvalid),
    .s_axi_awready (s_axi_awready),
    .s_axi_wdata   (s_axi_wdata),
    .s_axi_wvalid  (s_axi_wvalid),
    .s_axi_wready  (s_axi_wready),
    .s_axi_bresp   (s_axi_bresp),
    .s_axi_bvalid  (s_axi_bvalid),
    .s_axi_bready  (s_axi_bready),
    .s_axi_araddr  (s_axi_araddr),
    .s_axi_arvalid (s_axi_arvalid),
    .s_axi_arready (s_axi_arready),
    .s_axi_rdata   (s_axi_rdata),
    .s_axi_rresp   (s_axi_rresp),
    .s_axi_rvalid  (s_axi_rvalid),
    .s_axi_rready  (s_axi_rready),
    .done          (done),
    .irq           (irq)
);

// ============================================================================
// Clock generation
// ============================================================================
initial axi_clk = 1'b0;
always #(AXI_CLK_PERIOD/2) axi_clk = ~axi_clk;

initial dma_clk = 1'b0;
always #(DMA_CLK_PERIOD/2) dma_clk = ~dma_clk;

// ============================================================================
// Waveform database
// ============================================================================
initial begin
    $shm_open("dma_tb.shm");
    $shm_probe(dma_tb, "AS");
    // $dumpfile("dma_tb.vcd");
    // $dumpvars(0, dma_tb);
end

// ============================================================================
// IRQ / done monitors
// ============================================================================
always @(posedge axi_clk) begin
    if (irq)  irq_seen  <= 1'b1;
    if (done) done_seen <= 1'b1;
end

// ============================================================================
// Tasks
// ============================================================================

// --- CHECK_EQ ---------------------------------------------------------------
task CHECK_EQ;
    input [255:0] description;
    input [31:0]  actual;
    input [31:0]  expected;
    begin
        if (actual === expected) begin
            $display("  [PASS] TC%0d: %s (got 0x%08h)", tc_num, description, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] TC%0d: %s expected 0x%08h got 0x%08h",
                     tc_num, description, expected, actual);
            fail_count = fail_count + 1;
        end
    end
endtask

// --- CHECK_TRUE -------------------------------------------------------------
task CHECK_TRUE;
    input [255:0] description;
    input         condition;
    begin
        if (condition) begin
            $display("  [PASS] TC%0d: %s", tc_num, description);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] TC%0d: %s -- condition was FALSE", tc_num, description);
            fail_count = fail_count + 1;
        end
    end
endtask

// --- CHECK_FALSE ------------------------------------------------------------
task CHECK_FALSE;
    input [255:0] description;
    input         condition;
    begin
        if (!condition) begin
            $display("  [PASS] TC%0d: %s", tc_num, description);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] TC%0d: %s -- condition was TRUE (expected FALSE)",
                     tc_num, description);
            fail_count = fail_count + 1;
        end
    end
endtask

// --- clear_flags ------------------------------------------------------------
task clear_flags;
    begin
        irq_seen  = 1'b0;
        done_seen = 1'b0;
    end
endtask

// --- apply_reset ------------------------------------------------------------
task apply_reset;
    begin
        rst_n = 1'b0;
        repeat(10) @(posedge axi_clk);
        @(posedge axi_clk);
        rst_n = 1'b1;
        repeat(5) @(posedge axi_clk);
    end
endtask

// --- axi_write --------------------------------------------------------------
task axi_write;
    input [3:0]  addr;
    input [31:0] data;
    begin
        @(posedge axi_clk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1'b1;
        s_axi_wdata   <= data;
        s_axi_wvalid  <= 1'b1;
        s_axi_bready  <= 1'b1;
        timeout = 0;
        @(posedge axi_clk);
        while (!s_axi_awready) begin
            @(posedge axi_clk);
            timeout = timeout + 1;
            if (timeout > TIMEOUT_CYCLES) begin
                $display("  [FAIL] TIMEOUT waiting for s_axi_awready");
                fail_count = fail_count + 1;
                disable axi_write;
            end
        end
        s_axi_awvalid <= 1'b0;
        timeout = 0;
        while (!s_axi_wready) begin
            @(posedge axi_clk);
            timeout = timeout + 1;
            if (timeout > TIMEOUT_CYCLES) begin
                $display("  [FAIL] TIMEOUT waiting for s_axi_wready");
                fail_count = fail_count + 1;
                disable axi_write;
            end
        end
        s_axi_wvalid <= 1'b0;
        timeout = 0;
        while (!s_axi_bvalid) begin
            @(posedge axi_clk);
            timeout = timeout + 1;
            if (timeout > TIMEOUT_CYCLES) begin
                $display("  [FAIL] TIMEOUT waiting for s_axi_bvalid");
                fail_count = fail_count + 1;
                disable axi_write;
            end
        end
        @(posedge axi_clk);
        s_axi_bready <= 1'b0;
    end
endtask

// --- axi_read ---------------------------------------------------------------
task axi_read;
    input  [3:0]  addr;
    output [31:0] rdata;
    begin
        @(posedge axi_clk);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1'b1;
        s_axi_rready  <= 1'b1;
        timeout = 0;
        @(posedge axi_clk);
        while (!s_axi_arready) begin
            @(posedge axi_clk);
            timeout = timeout + 1;
            if (timeout > TIMEOUT_CYCLES) begin
                $display("  [FAIL] TIMEOUT waiting for s_axi_arready");
                fail_count = fail_count + 1;
                rdata = 32'hDEAD_BEEF;
                disable axi_read;
            end
        end
        s_axi_arvalid <= 1'b0;
        timeout = 0;
        while (!s_axi_rvalid) begin
            @(posedge axi_clk);
            timeout = timeout + 1;
            if (timeout > TIMEOUT_CYCLES) begin
                $display("  [FAIL] TIMEOUT waiting for s_axi_rvalid");
                fail_count = fail_count + 1;
                rdata = 32'hDEAD_BEEF;
                disable axi_read;
            end
        end
        rdata = s_axi_rdata;
        @(posedge axi_clk);
        s_axi_rready <= 1'b0;
    end
endtask

// --- wait_for_done ----------------------------------------------------------
task wait_for_done;
    begin
        timeout = 0;
        @(posedge axi_clk);
        while (!done) begin
            @(posedge axi_clk);
            timeout = timeout + 1;
            if (timeout > TIMEOUT_CYCLES) begin
                $display("  [FAIL] TIMEOUT waiting for done signal");
                fail_count = fail_count + 1;
                disable wait_for_done;
            end
        end
    end
endtask

// --- do_transfer ------------------------------------------------------------
task do_transfer;
    input [15:0] length;
    begin
        axi_write(ADDR_LENGTH[3:0], {16'b0, length});
        axi_write(ADDR_START[3:0],  32'h0000_0001);
        wait_for_done;
    end
endtask

// ============================================================================
// Main test sequence
// ============================================================================
initial begin
    // Initialise
    pass_count    = 0;
    fail_count    = 0;
    tc_num        = 0;
    timeout       = 0;
    s_axi_awaddr  = 4'h0;
    s_axi_awvalid = 1'b0;
    s_axi_wdata   = 32'h0;
    s_axi_wvalid  = 1'b0;
    s_axi_bready  = 1'b0;
    s_axi_araddr  = 4'h0;
    s_axi_arvalid = 1'b0;
    s_axi_rready  = 1'b0;
    irq_seen      = 1'b0;
    done_seen     = 1'b0;
    rst_n         = 1'b1;

    $display("");
    $display("=======================================================");
    $display(" DMA SoC Self-Checking Testbench [Cadence Xcelium]");
    $display(" AXI clk: %0d MHz | DMA clk: %0d MHz",
             1000/AXI_CLK_PERIOD, 1000/DMA_CLK_PERIOD);
    $display("=======================================================");
    apply_reset;

    // =================================================================
    // TC1 - Basic 8-word transfer
    // =================================================================
    tc_num = 1;
    $display("\n  TC1: Basic 8-word transfer");
    clear_flags;
    do_transfer(16'd8);
    repeat(20) @(posedge axi_clk);
    CHECK_TRUE("done pulsed after 8-word transfer", done_seen);
    CHECK_TRUE("irq pulsed after 8-word transfer",  irq_seen);
    axi_read(ADDR_STATUS[3:0], read_data);
    CHECK_EQ  ("STATUS=1 after transfer complete",  read_data, 32'h0000_0001);

    // =================================================================
    // TC2 - Single-word transfer
    // =================================================================
    tc_num = 2;
    $display("\n  TC2: Single-word transfer (length=1)");
    apply_reset; clear_flags;
    do_transfer(16'd1);
    repeat(20) @(posedge axi_clk);
    CHECK_TRUE("done pulsed for length=1 transfer", done_seen);
    CHECK_TRUE("irq pulsed for length=1 transfer",  irq_seen);
    axi_read(ADDR_STATUS[3:0], read_data);
    CHECK_EQ  ("STATUS=1 after length=1 transfer",  read_data, 32'h0000_0001);

    // =================================================================
    // TC3 - Full FIFO depth (length = 16)
    // =================================================================
    tc_num = 3;
    $display("\n  TC3: Full FIFO depth transfer (length=16)");
    apply_reset; clear_flags;
    do_transfer(16'd16);
    repeat(50) @(posedge axi_clk);
    CHECK_TRUE("done pulsed for full-FIFO transfer", done_seen);
    CHECK_TRUE("irq pulsed for full-FIFO transfer",  irq_seen);
    axi_read(ADDR_STATUS[3:0], read_data);
    CHECK_EQ  ("STATUS=1 after full-depth transfer", read_data, 32'h0000_0001);

    // =================================================================
    // TC4 - Back-to-back transfers
    // =================================================================
    tc_num = 4;
    $display("\n  TC4: Back-to-back transfers (no reset between)");
    apply_reset;
    clear_flags;
    do_transfer(16'd4);
    repeat(20) @(posedge axi_clk);
    CHECK_TRUE("done pulsed on transfer 1 of 2", done_seen);
    clear_flags;
    do_transfer(16'd4);
    repeat(20) @(posedge axi_clk);
    CHECK_TRUE("done pulsed on transfer 2 of 2", done_seen);
    CHECK_TRUE("irq pulsed on transfer 2 of 2",  irq_seen);

    // =================================================================
    // TC5 - STATUS register behaviour
    // =================================================================
    tc_num = 5;
    $display("\n  TC5: STATUS register read-only behaviour");
    apply_reset; clear_flags;
    axi_read(ADDR_STATUS[3:0], read_data);
    CHECK_EQ ("STATUS=0 before any transfer",         read_data, 32'h0000_0000);
    do_transfer(16'd4);
    repeat(20) @(posedge axi_clk);
    axi_read(ADDR_STATUS[3:0], read_data);
    CHECK_EQ ("STATUS=1 immediately after transfer",  read_data, 32'h0000_0001);
    axi_write(ADDR_STATUS[3:0], 32'h0000_0000);
    axi_read(ADDR_STATUS[3:0], read_data);
    CHECK_EQ ("STATUS unchanged after write (rd-only)", read_data, 32'h0000_0001);
    apply_reset;
    axi_read(ADDR_STATUS[3:0], read_data);
    CHECK_EQ ("STATUS=0 after reset",                 read_data, 32'h0000_0000);

    // =================================================================
    // TC6 - LENGTH register read/write coherence
    // =================================================================
    tc_num = 6;
    $display("\n  TC6: LENGTH register read/write coherence");
    apply_reset;
    axi_write(ADDR_LENGTH[3:0], 32'h0000_0008);
    axi_read (ADDR_LENGTH[3:0], read_data);
    CHECK_EQ ("LENGTH reads back 0x00000008", read_data, 32'h0000_0008);
    axi_write(ADDR_LENGTH[3:0], 32'h0000_000F);
    axi_read (ADDR_LENGTH[3:0], read_data);
    CHECK_EQ ("LENGTH reads back 0x0000000F", read_data, 32'h0000_000F);
    axi_write(ADDR_LENGTH[3:0], 32'h0000_0001);
    axi_read (ADDR_LENGTH[3:0], read_data);
    CHECK_EQ ("LENGTH reads back 0x00000001", read_data, 32'h0000_0001);

    // =================================================================
    // TC7 - START register self-clearing
    // =================================================================
    tc_num = 7;
    $display("\n  TC7: START register is write-only and self-clearing");
    apply_reset; clear_flags;
    axi_write(ADDR_LENGTH[3:0], 32'h0000_0004);
    repeat(10) @(posedge axi_clk);
    axi_write(ADDR_START[3:0], 32'h0000_0001);
    axi_read (ADDR_START[3:0], read_data);
    CHECK_EQ ("START reads back 0x00000000 (write-only)", read_data, 32'h0000_0000);
    wait_for_done;

    // =================================================================
    // TC8 - Zero-length transfer is a no-op
    // =================================================================
    tc_num = 8;
    $display("\n  TC8: Zero-length transfer is a no-op");
    apply_reset; clear_flags;
    axi_write(ADDR_LENGTH[3:0], 32'h0000_0000);
    axi_write(ADDR_START[3:0],  32'h0000_0001);
    repeat(200) @(posedge axi_clk);
    CHECK_FALSE("done NOT asserted for length=0", done_seen);
    CHECK_FALSE("irq NOT asserted for length=0",  irq_seen);
    axi_read(ADDR_STATUS[3:0], read_data);
    CHECK_EQ  ("STATUS=0 after zero-length no-op", read_data, 32'h0000_0000);

    // =================================================================
    // Summary
    // =================================================================
    $display("");
    $display("=======================================================");
    $display(" RESULTS: %0d PASSED / %0d FAILED / %0d TOTAL",
             pass_count, fail_count, pass_count + fail_count);
    $display("=======================================================");
    $display("");
    $finish(2);
end

endmodule
`default_nettype wire
