`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 09:46:02 AM
// Design Name: 
// Module Name: plic_ip
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

module plic_ip #(
  parameter int N_SOURCE = 30,
  parameter int N_TARGET = 2,
  parameter int MAX_PRIO = 7
)(
  input  logic clk_i,
  input  logic rst_ni,

  input  logic        valid_i,
  input  logic        write_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,

  output logic        ready_o,
  output logic [31:0] rdata_o,
  output logic        error_o,

  input  logic [N_SOURCE-1:0] le_i,
  input  logic [N_SOURCE-1:0] irq_sources_i,
  output logic [N_TARGET-1:0] eip_targets_o
);

  localparam SRCW  = $clog2(N_SOURCE+1);
  localparam PRIOW = $clog2(MAX_PRIO+1);

  logic [N_SOURCE-1:0] ip;

  logic [PRIOW-1:0] prio_q [N_SOURCE];
  logic [PRIOW-1:0] prio_d [N_SOURCE];
  logic [N_SOURCE-1:0] prio_we;

  logic [N_SOURCE*PRIOW-1:0] prio_flat;

  logic [N_SOURCE-1:0] ie_q [N_TARGET];
  logic [N_SOURCE-1:0] ie_d [N_TARGET];
  logic [N_TARGET-1:0] ie_we;

  logic [PRIOW-1:0] threshold_q [N_TARGET];
  logic [PRIOW-1:0] threshold_d [N_TARGET];
  logic [N_TARGET-1:0] threshold_we;

  logic [SRCW-1:0] claim_id [N_TARGET];
  logic [SRCW-1:0] complete_id [N_TARGET];

  logic [N_TARGET-1:0] claim_re;
  logic [N_TARGET-1:0] complete_we;

  logic [N_SOURCE-1:0] claim;
  logic [N_SOURCE-1:0] complete;

  integer i, j;

  always_comb begin
    for (i = 0; i < N_SOURCE; i++)
      prio_flat[i*PRIOW +: PRIOW] = prio_q[i];
  end

  plic_regs #(
    .N_SOURCE(N_SOURCE),
    .N_TARGET(N_TARGET),
    .MAX_PRIO(MAX_PRIO)
  ) u_regs (
    .prio_i(prio_q),
    .prio_o(prio_d),
    .prio_we_o(prio_we),

    .ip_i(ip),

    .ie_i(ie_q),
    .ie_o(ie_d),
    .ie_we_o(ie_we),

    .threshold_i(threshold_q),
    .threshold_o(threshold_d),
    .threshold_we_o(threshold_we),

    .cc_i(claim_id),
    .cc_o(complete_id),
    .cc_we_o(complete_we),
    .cc_re_o(claim_re),

    .valid(valid_i),
    .write(write_i),
    .addr(addr_i),
    .wdata(wdata_i),

    .ready(ready_o),
    .rdata(rdata_o),
    .error(error_o)
  );

  always_comb begin
    claim = '0;
    complete = '0;

    for (j = 0; j < N_TARGET; j++) begin
      if (claim_re[j] && claim_id[j] > 0 && claim_id[j] <= N_SOURCE)
        claim[claim_id[j]-1] = 1'b1;

      if (complete_we[j] && complete_id[j] > 0 && complete_id[j] <= N_SOURCE)
        complete[complete_id[j]-1] = 1'b1;
    end
  end

  rv_plic_gateway #(
    .N_SOURCE(N_SOURCE)
  ) gateway (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .src(irq_sources_i),
    .le(le_i),
    .claim(claim),
    .complete(complete),
    .ip(ip)
  );

  genvar k;
  generate
    for (k = 0; k < N_TARGET; k++) begin : gen_target
      rv_plic_target #(
        .N_SOURCE(N_SOURCE),
        .MAX_PRIO(MAX_PRIO)
      ) target (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .ip(ip),
        .ie(ie_q[k]),
        .prio_flat(prio_flat),
        .threshold(threshold_q[k]),
        .irq(eip_targets_o[k]),
        .irq_id(claim_id[k])
      );
    end
  endgenerate

  integer m, n;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (m = 0; m < N_SOURCE; m++)
        prio_q[m] <= '0;

      for (n = 0; n < N_TARGET; n++) begin
        ie_q[n] <= '0;
        threshold_q[n] <= '0;
      end
    end else begin
      for (m = 0; m < N_SOURCE; m++) begin
        if (prio_we[m])
          prio_q[m] <= prio_d[m];
      end

      for (n = 0; n < N_TARGET; n++) begin
        if (ie_we[n])
          ie_q[n] <= ie_d[n];

        if (threshold_we[n])
          threshold_q[n] <= threshold_d[n];
      end
    end
  end

endmodule