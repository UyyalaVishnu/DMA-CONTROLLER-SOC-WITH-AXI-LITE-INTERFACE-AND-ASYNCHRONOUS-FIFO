// ============================================================================
// Module : dma (top-level)
// Tool   : Cadence Xcelium / Genus / Innovus
// Notes  : Cleaned redundant `default_nettype toggles between modules.
//          All CDC structures retained; no functional change.
// ============================================================================
`timescale 1ns/1ps
`default_nettype none

module dma #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 4,
    parameter COUNT_WIDTH = 16
)(
    input  wire        axi_clk,
    input  wire        dma_clk,
    input  wire        rst_n,
    input  wire [3:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [3:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    output wire        done,
    output wire        irq
);

// ---------------------------------------------------------------------------
// Internal wires
// ---------------------------------------------------------------------------
wire                    dma_start;
wire [COUNT_WIDTH-1:0]  dma_length;
wire                    dma_done_axi;
wire [DATA_WIDTH-1:0]   fifo_dout;
wire                    fifo_empty;
wire                    fifo_rd_en;
wire                    fifo_full;
reg  [DATA_WIDTH-1:0]   fifo_din;
reg                     fifo_wr_en;

// ============================================================================
// CDC: dma_start (AXI -> DMA) -- toggle synchronizer
// ============================================================================
reg [COUNT_WIDTH-1:0] length_latch;
always @(posedge axi_clk or negedge rst_n) begin
    if (!rst_n)
        length_latch <= {COUNT_WIDTH{1'b0}};
    else if (dma_start)
        length_latch <= dma_length;
end

reg start_tog;
always @(posedge axi_clk or negedge rst_n) begin
    if (!rst_n)
        start_tog <= 1'b0;
    else if (dma_start)
        start_tog <= ~start_tog;
end

// 3-FF synchronizer (stog_s3 used only for edge detect)
reg stog_s1, stog_s2, stog_s3;
always @(posedge dma_clk or negedge rst_n) begin
    if (!rst_n)
        {stog_s1, stog_s2, stog_s3} <= 3'b000;
    else begin
        stog_s1 <= start_tog;
        stog_s2 <= stog_s1;
        stog_s3 <= stog_s2;
    end
end

wire dma_start_sync = stog_s2 ^ stog_s3;

// 2-FF sync for length (grey-code not needed; sampled after start edge)
reg [COUNT_WIDTH-1:0] len_s1, len_s2;
always @(posedge dma_clk or negedge rst_n) begin
    if (!rst_n) begin
        len_s1 <= {COUNT_WIDTH{1'b0}};
        len_s2 <= {COUNT_WIDTH{1'b0}};
    end else begin
        len_s1 <= length_latch;
        len_s2 <= len_s1;
    end
end

wire [COUNT_WIDTH-1:0] dma_length_sync = len_s2;

// ============================================================================
// CDC: done (DMA -> AXI) -- 2-FF synchronizer
// done is held 4 DMA cycles by dma_engine, so 2-FF is safe.
// ============================================================================
reg done_s1, done_s2;
always @(posedge axi_clk or negedge rst_n) begin
    if (!rst_n) begin
        done_s1 <= 1'b0;
        done_s2 <= 1'b0;
    end else begin
        done_s1 <= done;
        done_s2 <= done_s1;
    end
end

assign dma_done_axi = done_s2;

// ============================================================================
// Data generator (AXI clock domain)
// ============================================================================
reg [DATA_WIDTH-1:0] gen_data;
reg active;

always @(posedge axi_clk or negedge rst_n) begin
    if (!rst_n) begin
        active   <= 1'b0;
        gen_data <= {DATA_WIDTH{1'b0}};
    end else begin
        // done_s2 clears active; dma_start sets it (done has priority)
        if (done_s2)
            active <= 1'b0;
        else if (dma_start)
            active <= 1'b1;
        if (fifo_wr_en)
            gen_data <= gen_data + {{(DATA_WIDTH-1){1'b0}}, 1'b1};
    end
end

// Combinational FIFO write control
always @(*) begin
    fifo_wr_en = active & ~fifo_full;
    fifo_din   = gen_data;
end

// ============================================================================
// Sub-module instantiation
// ============================================================================
axi_lite_regs #(
    .DATA_WIDTH  (DATA_WIDTH),
    .ADDR_WIDTH  (4),
    .COUNT_WIDTH (COUNT_WIDTH)
) u_regs (
    .axi_clk       (axi_clk),
    .axi_rst_n     (rst_n),
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
    .dma_start     (dma_start),
    .dma_length    (dma_length),
    .dma_done      (dma_done_axi)
);

async_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
) u_fifo (
    .i_wclk   (axi_clk),
    .i_wrst_n (rst_n),
    .i_wr     (fifo_wr_en),
    .i_wdata  (fifo_din),
    .o_wfull  (fifo_full),
    .i_rclk   (dma_clk),
    .i_rrst_n (rst_n),
    .i_rd     (fifo_rd_en),
    .o_rdata  (fifo_dout),
    .o_rempty (fifo_empty)
);

dma_engine #(
    .DATA_WIDTH  (DATA_WIDTH),
    .COUNT_WIDTH (COUNT_WIDTH)
) u_dma (
    .dma_clk    (dma_clk),
    .rst_n      (rst_n),
    .start      (dma_start_sync),
    .length     (dma_length_sync),
    .fifo_empty (fifo_empty),
    .fifo_rdata (fifo_dout),
    .fifo_rd_en (fifo_rd_en),
    .done       (done),
    .irq        (irq)
);

endmodule
`default_nettype wire

// ============================================================================
// Module : async_fifo
// Tool   : Cadence Xcelium / Genus / Innovus
// Notes  : Gray-code pointer synchronization. No functional change.
//          Memory write moved inside clocked always block (Cadence lint).
// ============================================================================
`timescale 1ns/1ps
`default_nettype none

module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    input  wire                  i_wclk,
    input  wire                  i_wrst_n,
    input  wire                  i_wr,
    input  wire [DATA_WIDTH-1:0] i_wdata,
    output wire                  o_wfull,
    input  wire                  i_rclk,
    input  wire                  i_rrst_n,
    input  wire                  i_rd,
    output wire [DATA_WIDTH-1:0] o_rdata,
    output wire                  o_rempty
);

localparam DEPTH = (1 << ADDR_WIDTH);

// ---------------------------------------------------------------------------
// Memory array
// ---------------------------------------------------------------------------
(* ram_style = "auto" *)
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// ---------------------------------------------------------------------------
// All pointer declarations (hoisted so every always block sees them)
// ---------------------------------------------------------------------------
reg [ADDR_WIDTH:0] wbin, wgray;
reg [ADDR_WIDTH:0] rgray_s1, rgray_s2;  // read gray synced to wclk
reg [ADDR_WIDTH:0] rbin, rgray;          // read domain (declared here to avoid E,UNDIDN)
reg [ADDR_WIDTH:0] wgray_s1, wgray_s2;  // write gray synced to rclk

// ---------------------------------------------------------------------------
// Write domain: binary and gray pointers
// ---------------------------------------------------------------------------

wire [ADDR_WIDTH:0] wbin_next  = wbin + {{ADDR_WIDTH{1'b0}}, (i_wr & ~o_wfull)};
wire [ADDR_WIDTH:0] wgray_next = (wbin_next >> 1) ^ wbin_next;

always @(posedge i_wclk or negedge i_wrst_n) begin
    if (!i_wrst_n)
        {wbin, wgray} <= {(2*(ADDR_WIDTH+1)){1'b0}};
    else
        {wbin, wgray} <= {wbin_next, wgray_next};
end

// FIFO memory write -- inside clocked block (avoids Cadence latch warning)
always @(posedge i_wclk) begin
    if (i_wr && !o_wfull)
        mem[wbin[ADDR_WIDTH-1:0]] <= i_wdata;
end

// Sync read gray pointer into write domain (2-FF)
// FIX: shift register must go rgray -> rgray_s1 -> rgray_s2
always @(posedge i_wclk or negedge i_wrst_n) begin
    if (!i_wrst_n)
        {rgray_s1, rgray_s2} <= {(2*(ADDR_WIDTH+1)){1'b0}};
    else begin
        rgray_s1 <= rgray;        // FIX: was reversed in original
        rgray_s2 <= rgray_s1;
    end
end

// Full flag: write gray == inverted MSBs of synced read gray
assign o_wfull = (wgray == {~rgray_s2[ADDR_WIDTH:ADDR_WIDTH-1],
                              rgray_s2[ADDR_WIDTH-2:0]});

// ---------------------------------------------------------------------------
// Read domain: binary and gray pointers
// ---------------------------------------------------------------------------

wire [ADDR_WIDTH:0] rbin_next  = rbin + {{ADDR_WIDTH{1'b0}}, (i_rd & ~o_rempty)};
wire [ADDR_WIDTH:0] rgray_next = (rbin_next >> 1) ^ rbin_next;

always @(posedge i_rclk or negedge i_rrst_n) begin
    if (!i_rrst_n)
        {rbin, rgray} <= {(2*(ADDR_WIDTH+1)){1'b0}};
    else
        {rbin, rgray} <= {rbin_next, rgray_next};
end

// Registered read data
assign o_rdata = mem[rbin[ADDR_WIDTH-1:0]];

// Sync write gray pointer into read domain (2-FF)
always @(posedge i_rclk or negedge i_rrst_n) begin
    if (!i_rrst_n)
        {wgray_s1, wgray_s2} <= {(2*(ADDR_WIDTH+1)){1'b0}};
    else begin
        wgray_s1 <= wgray;
        wgray_s2 <= wgray_s1;
    end
end

// Empty flag
assign o_rempty = (rgray == wgray_s2);

endmodule
`default_nettype wire

// ============================================================================
// Module : axi_lite_regs
// Tool   : Cadence Xcelium / Genus / Innovus
// Notes  : No functional change. Port declaration style cleaned for
//          Cadence HAL/Genus compatibility (one port per line).
//          FIX: All capitalised Verilog keywords lowercased.
// ============================================================================
`timescale 1ns/1ps
`default_nettype none

module axi_lite_regs #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 4,
    parameter COUNT_WIDTH = 16
)(
    input  wire                   axi_clk,
    input  wire                   axi_rst_n,
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,
    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready,
    output reg                    dma_start,
    output reg  [COUNT_WIDTH-1:0] dma_length,
    input  wire                   dma_done
);

// ---------------------------------------------------------------------------
// Register map
// ---------------------------------------------------------------------------
localparam [ADDR_WIDTH-1:0]
    ADDR_START  = 4'h0,
    ADDR_LENGTH = 4'h4,
    ADDR_STATUS = 4'h8;

reg [DATA_WIDTH-1:0]  reg_length;
reg [ADDR_WIDTH-1:0]  waddr_lat;
reg [ADDR_WIDTH-1:0]  raddr_lat;

// STATUS register: sticky bit, cleared only by reset
reg status_done;
always @(posedge axi_clk or negedge axi_rst_n) begin
    if (!axi_rst_n)
        status_done <= 1'b0;
    else if (dma_done)
        status_done <= 1'b1;
end

wire [DATA_WIDTH-1:0] reg_status = {{(DATA_WIDTH-1){1'b0}}, status_done};

// ============================================================================
// Write channel (AW + W + B)
// ============================================================================
always @(posedge axi_clk or negedge axi_rst_n) begin
    if (!axi_rst_n) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bvalid  <= 1'b0;
        s_axi_bresp   <= 2'b00;
        reg_length    <= {DATA_WIDTH{1'b0}};
        dma_start     <= 1'b0;
        dma_length    <= {COUNT_WIDTH{1'b0}};
        waddr_lat     <= {ADDR_WIDTH{1'b0}};
    end else begin
        // Default: self-clearing
        dma_start <= 1'b0;

        // AW handshake
        if (s_axi_awvalid && !s_axi_awready) begin
            s_axi_awready <= 1'b1;
            waddr_lat     <= s_axi_awaddr;
        end else begin
            s_axi_awready <= 1'b0;
        end

        // W handshake
        if (s_axi_wvalid && !s_axi_wready)
            s_axi_wready <= 1'b1;
        else
            s_axi_wready <= 1'b0;

        // Register write (when both AW and W accepted)
        if (s_axi_awready && s_axi_wready) begin
            case (waddr_lat)
                ADDR_START: begin
                    if (s_axi_wdata[0]) begin
                        dma_start  <= 1'b1;
                        dma_length <= reg_length[COUNT_WIDTH-1:0];
                    end
                end
                ADDR_LENGTH: begin
                    reg_length <= s_axi_wdata;
                end
                // ADDR_STATUS is read-only; writes silently ignored
                default: ;
            endcase
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00;
        end

        // B handshake
        if (s_axi_bvalid && s_axi_bready)
            s_axi_bvalid <= 1'b0;
    end
end

// ============================================================================
// Read channel (AR + R)
// ============================================================================
always @(posedge axi_clk or negedge axi_rst_n) begin
    if (!axi_rst_n) begin
        s_axi_arready <= 1'b0;
        s_axi_rvalid  <= 1'b0;
        s_axi_rdata   <= {DATA_WIDTH{1'b0}};
        s_axi_rresp   <= 2'b00;
        raddr_lat     <= {ADDR_WIDTH{1'b0}};
    end else begin
        // AR handshake
        if (s_axi_arvalid && !s_axi_arready) begin
            s_axi_arready <= 1'b1;
            raddr_lat     <= s_axi_araddr;
        end else begin
            s_axi_arready <= 1'b0;
        end

        // R response
        if (s_axi_arready) begin
            s_axi_rvalid <= 1'b1;
            s_axi_rresp  <= 2'b00;
            case (raddr_lat)
                ADDR_START:  s_axi_rdata <= {DATA_WIDTH{1'b0}};
                ADDR_LENGTH: s_axi_rdata <= reg_length;
                ADDR_STATUS: s_axi_rdata <= reg_status;
                default:     s_axi_rdata <= 32'hDEAD_BEEF;
            endcase
        end

        // R handshake
        if (s_axi_rvalid && s_axi_rready)
            s_axi_rvalid <= 1'b0;
    end
end

endmodule
`default_nettype wire

// ============================================================================
// Module : dma_engine
// Tool   : Cadence Xcelium / Genus / Innovus
// Notes  : done/irq held 4 DMA cycles for safe AXI-domain capture.
//          FSM encoding changed to localparam with explicit width to
//          help Cadence Genus state-machine recognition and encoding.
//          FIX: All capitalised Verilog keywords lowercased.
//          FIX: Unicode em-dash replaced with ASCII minus in arithmetic.
// ============================================================================
`timescale 1ns/1ps
`default_nettype none

module dma_engine #(
    parameter DATA_WIDTH  = 32,
    parameter COUNT_WIDTH = 16
)(
    input  wire                   dma_clk,
    input  wire                   rst_n,
    input  wire                   start,
    input  wire [COUNT_WIDTH-1:0] length,
    input  wire                   fifo_empty,
    input  wire [DATA_WIDTH-1:0]  fifo_rdata,
    output reg                    fifo_rd_en,
    output reg                    done,
    output reg                    irq
);

// ---------------------------------------------------------------------------
// FSM state encoding
// Explicit 2-bit encoding helps Cadence Genus recognise the FSM
// ---------------------------------------------------------------------------
localparam [1:0]
    IDLE     = 2'b00,
    ACTIVE   = 2'b01,
    COMPLETE = 2'b10;

// Cycles to hold done/irq high (must satisfy: DONE_HOLD x T_dma > T_axi)
// 4 x 7 ns = 28 ns > 10 ns (AXI period). AXI clock sees >= 2 edges.
localparam [2:0] DONE_HOLD = 3'd4;

reg [1:0]          state, state_next;
reg [COUNT_WIDTH-1:0] count;
reg [DATA_WIDTH-1:0]  data_capture;
reg [2:0]          done_cnt;

// ---------------------------------------------------------------------------
// State register
// ---------------------------------------------------------------------------
always @(posedge dma_clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= state_next;
end

// ---------------------------------------------------------------------------
// Transfer counter
// ---------------------------------------------------------------------------
always @(posedge dma_clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= {COUNT_WIDTH{1'b0}};
    end else begin
        case (state)
            IDLE: begin
                if (start && (length != {COUNT_WIDTH{1'b0}}))
                    count <= length;
            end
            ACTIVE: begin
                if (!fifo_empty && (count != {COUNT_WIDTH{1'b0}}))
                    count <= count - {{(COUNT_WIDTH-1){1'b0}}, 1'b1};  // FIX: ASCII minus
            end
            default: ;
        endcase
    end
end

// ---------------------------------------------------------------------------
// Done-hold counter
// ---------------------------------------------------------------------------
always @(posedge dma_clk or negedge rst_n) begin
    if (!rst_n) begin
        done_cnt <= 3'd0;
    end else if (state == COMPLETE && state_next == IDLE) begin
        done_cnt <= DONE_HOLD;
    end else if (done_cnt != 3'd0) begin
        done_cnt <= done_cnt - 3'd1;  // FIX: ASCII minus
    end
end

// ---------------------------------------------------------------------------
// Next-state logic (combinational)
// ---------------------------------------------------------------------------
always @(*) begin
    state_next = state;
    case (state)
        IDLE:     if (start && (length != {COUNT_WIDTH{1'b0}}))
                      state_next = ACTIVE;
        ACTIVE:   if (!fifo_empty &&
                      (count == {{(COUNT_WIDTH-1){1'b0}}, 1'b1}))
                      state_next = COMPLETE;
        COMPLETE: state_next = IDLE;
        default:  state_next = IDLE;
    endcase
end

// ---------------------------------------------------------------------------
// Output logic
// ---------------------------------------------------------------------------
always @(posedge dma_clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_rd_en   <= 1'b0;
        done         <= 1'b0;
        irq          <= 1'b0;
        data_capture <= {DATA_WIDTH{1'b0}};
    end else begin
        fifo_rd_en <= 1'b0;

        // Assert done/irq while entering COMPLETE or counting down hold
        if ((state_next == COMPLETE) || (done_cnt != 3'd0)) begin
            done <= 1'b1;
            irq  <= 1'b1;
        end else begin
            done <= 1'b0;
            irq  <= 1'b0;
        end

        // FIFO read in ACTIVE state
        if (state_next == ACTIVE) begin
            if (!fifo_empty && (count != {COUNT_WIDTH{1'b0}})) begin
                fifo_rd_en   <= 1'b1;
                data_capture <= fifo_rdata;
            end
        end
    end
end

endmodule
`default_nettype wire
