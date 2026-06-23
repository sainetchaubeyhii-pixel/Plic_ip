`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 09:50:12 AM
// Design Name: 
// Module Name: rv_plic_target
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

module rv_plic_target #(
  parameter int N_SOURCE = 32,
  parameter int MAX_PRIO = 7,
  parameter int SRCW  = $clog2(N_SOURCE+1),
  parameter int PRIOW = $clog2(MAX_PRIO+1)
)(
  input  logic clk_i,
  input  logic rst_ni,

  input  logic [N_SOURCE-1:0] ip,
  input  logic [N_SOURCE-1:0] ie,

  input  logic [N_SOURCE*PRIOW-1:0] prio_flat, // ✅ only this

  input  logic [PRIOW-1:0] threshold,

  output logic irq,
  output logic [SRCW-1:0] irq_id
);

  // 🔧 Convert flat → array
  logic [PRIOW-1:0] prio [N_SOURCE];

  integer k;
  always_comb begin
    for (k = 0; k < N_SOURCE; k = k + 1) begin
      prio[k] = prio_flat[k*PRIOW +: PRIOW];
    end
  end

  // -----------------------------
  // Priority selection
  // -----------------------------
  logic [PRIOW-1:0] max_prio;
  logic irq_next;
  logic [SRCW-1:0] irq_id_next;

  integer i;
  always_comb begin
    max_prio    = threshold + 1;
    irq_next    = 0;
    irq_id_next = 0;

    for (i = N_SOURCE; i > 0; i = i - 1) begin
      int idx;
      idx = i - 1;

      if (ip[idx] && ie[idx] && (prio[idx] >= max_prio)) begin
        max_prio    = prio[idx];
        irq_id_next = idx + 1;
        irq_next    = 1;
      end
    end
  end

  // -----------------------------
  // Output registers
  // -----------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      irq    <= 0;
      irq_id <= 0;
    end else begin
      irq    <= irq_next;
      irq_id <= irq_id_next;
    end
  end

endmodule