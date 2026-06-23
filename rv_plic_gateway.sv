`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 09:47:42 AM
// Design Name: 
// Module Name: rv_plic_gateway
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

module rv_plic_gateway #(
  parameter int N_SOURCE = 32
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic [N_SOURCE-1:0] src,
  input  logic [N_SOURCE-1:0] le,        // Level = 0, Edge = 1

  input  logic [N_SOURCE-1:0] claim,     // $onehot0(claim)
  input  logic [N_SOURCE-1:0] complete,  // $onehot0(complete)

  output logic [N_SOURCE-1:0] ip
);

  // Internal signals
  logic [N_SOURCE-1:0] ia;     // Interrupt Active
  logic [N_SOURCE-1:0] set;    // Set condition
  logic [N_SOURCE-1:0] src_d;  // Delayed source

  // -----------------------------
  // Edge detection register
  // -----------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      src_d <= '0;
    else
      src_d <= src;
  end

  // -----------------------------
  // Set logic (edge/level)
  // -----------------------------
  integer i;
  always_comb begin
    set = '0;  // 🔧 safe default

    for (i = 0; i < N_SOURCE; i = i + 1) begin
      if (le[i])
        set[i] = src[i] & ~src_d[i]; // edge-triggered
      else
        set[i] = src[i];             // level-triggered
    end
  end

  // -----------------------------
  // Interrupt Pending (ip)
  // -----------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ip <= '0;
    end else begin
      ip <= (ip | (set & ~ia & ~ip)) & (~claim);
    end
  end

  // -----------------------------
  // Interrupt Active (ia)
  // -----------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ia <= '0;
    end else begin
      ia <= (ia | (set & ~ia)) & (~complete);
    end
  end

endmodule