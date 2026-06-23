`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 09:51:59 AM
// Design Name: 
// Module Name: plic_regs
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


module plic_regs #(
  parameter int N_SOURCE = 30,
  parameter int N_TARGET = 2,
  parameter int MAX_PRIO  = 7
)(
  input  logic [2:0] prio_i [N_SOURCE],
  output logic [2:0] prio_o [N_SOURCE],
  output logic [N_SOURCE-1:0] prio_we_o,

  input  logic [N_SOURCE-1:0] ip_i,

  input  logic [N_SOURCE-1:0] ie_i [N_TARGET],
  output logic [N_SOURCE-1:0] ie_o [N_TARGET],
  output logic [N_TARGET-1:0] ie_we_o,

  input  logic [2:0] threshold_i [N_TARGET],
  output logic [2:0] threshold_o [N_TARGET],
  output logic [N_TARGET-1:0] threshold_we_o,

  input  logic [$clog2(N_SOURCE+1)-1:0] cc_i [N_TARGET],
  output logic [$clog2(N_SOURCE+1)-1:0] cc_o [N_TARGET],
  output logic [N_TARGET-1:0] cc_we_o,
  output logic [N_TARGET-1:0] cc_re_o,

  input  logic        valid,
  input  logic        write,
  input  logic [31:0] addr,
  input  logic [31:0] wdata,

  output logic        ready,
  output logic [31:0] rdata,
  output logic        error
);

  localparam logic [31:0] BASE = 32'h0c00_0000;

  int src;
  int tgt;

  always_comb begin
    ready = 1'b1;
    rdata = '0;
    error = 1'b0;

    prio_o = '{default:'0};
    prio_we_o = '0;

    ie_o = '{default:'0};
    ie_we_o = '0;

    threshold_o = '{default:'0};
    threshold_we_o = '0;

    cc_o = '{default:'0};
    cc_we_o = '0;
    cc_re_o = '0;

    if (valid) begin

      // Priority: BASE + 4*source
      if (addr >= 32'h0c00_0000 && addr < 32'h0c00_0000 + N_SOURCE*4) begin
        src = (addr - 32'h0c00_0000) >> 2;

        if (write) begin
          prio_o[src] = wdata[2:0];
          prio_we_o[src] = 1'b1;
        end else begin
          rdata[2:0] = prio_i[src];
        end
      end

      // Pending register
      else if (addr == 32'h0c00_1000) begin
        if (write) begin
          error = 1'b1;
        end else begin
          rdata[N_SOURCE-1:0] = ip_i;
        end
      end

      // Enable target 0
      else if (addr == 32'h0c00_2000) begin
        if (write) begin
          ie_o[0] = wdata[N_SOURCE-1:0];
          ie_we_o[0] = 1'b1;
        end else begin
          rdata[N_SOURCE-1:0] = ie_i[0];
        end
      end

      // Enable target 1
      else if (N_TARGET > 1 && addr == 32'h0c00_2080) begin
        if (write) begin
          ie_o[1] = wdata[N_SOURCE-1:0];
          ie_we_o[1] = 1'b1;
        end else begin
          rdata[N_SOURCE-1:0] = ie_i[1];
        end
      end

      // Target 0 threshold
      else if (addr == 32'h0c20_0000) begin
        if (write) begin
          threshold_o[0] = wdata[2:0];
          threshold_we_o[0] = 1'b1;
        end else begin
          rdata[2:0] = threshold_i[0];
        end
      end

      // Target 0 claim/complete
      else if (addr == 32'h0c20_0004) begin
        if (write) begin
          cc_o[0] = wdata[$clog2(N_SOURCE+1)-1:0];
          cc_we_o[0] = 1'b1;
        end else begin
          rdata[$clog2(N_SOURCE+1)-1:0] = cc_i[0];
          cc_re_o[0] = 1'b1;
        end
      end

      // Target 1 threshold
      else if (N_TARGET > 1 && addr == 32'h0c20_1000) begin
        if (write) begin
          threshold_o[1] = wdata[2:0];
          threshold_we_o[1] = 1'b1;
        end else begin
          rdata[2:0] = threshold_i[1];
        end
      end

      // Target 1 claim/complete
      else if (N_TARGET > 1 && addr == 32'h0c20_1004) begin
        if (write) begin
          cc_o[1] = wdata[$clog2(N_SOURCE+1)-1:0];
          cc_we_o[1] = 1'b1;
        end else begin
          rdata[$clog2(N_SOURCE+1)-1:0] = cc_i[1];
          cc_re_o[1] = 1'b1;
        end
      end

      else begin
        error = 1'b1;
      end
    end
  end

endmodule