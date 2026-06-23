`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 06:15:22 PM
// Design Name: 
// Module Name: testbench_plic
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
module testbench_plic;

  parameter int N_SOURCE = 30;
  parameter int N_TARGET = 2;
  parameter int MAX_PRIO  = 7;

  localparam logic [31:0] BASE = 32'h0c00_0000;

  logic clk;
  logic rst_n;

  logic        valid_i;
  logic        write_i;
  logic [31:0] addr_i;
  logic [31:0] wdata_i;
  logic        ready_o;
  logic [31:0] rdata_o;
  logic        error_o;

  logic [N_SOURCE-1:0] le_i;
  logic [N_SOURCE-1:0] irq_sources_i;
  logic [N_TARGET-1:0] eip_targets_o;

  plic_ip #(
    .N_SOURCE(N_SOURCE),
    .N_TARGET(N_TARGET),
    .MAX_PRIO(MAX_PRIO)
  ) dut (
    .clk_i(clk),
    .rst_ni(rst_n),

    .valid_i(valid_i),
    .write_i(write_i),
    .addr_i(addr_i),
    .wdata_i(wdata_i),
    .ready_o(ready_o),
    .rdata_o(rdata_o),
    .error_o(error_o),

    .le_i(le_i),
    .irq_sources_i(irq_sources_i),
    .eip_targets_o(eip_targets_o)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task reset_dut();
    begin
      rst_n = 0;
      valid_i = 0;
      write_i = 0;
      addr_i  = 0;
      wdata_i = 0;
      irq_sources_i = '0;
      le_i = '1;
      repeat (4) @(posedge clk);
      rst_n = 1;
      repeat (2) @(posedge clk);
    end
  endtask

  task bus_write(input logic [31:0] addr, input logic [31:0] data);
    begin
      @(posedge clk);
      valid_i <= 1;
      write_i <= 1;
      addr_i  <= addr;
      wdata_i <= data;

      @(posedge clk);
      valid_i <= 0;
      write_i <= 0;
      addr_i  <= 0;
      wdata_i <= 0;
    end
  endtask

  task bus_read(input logic [31:0] addr, output logic [31:0] data);
    begin
      @(posedge clk);
      valid_i <= 1;
      write_i <= 0;
      addr_i  <= addr;

      @(posedge clk);
      data = rdata_o;
      valid_i <= 0;
      addr_i  <= 0;
    end
  endtask

  task send_interrupt(input int id);
    begin
      irq_sources_i = '0;
      irq_sources_i[id] = 1'b1;
      repeat (2) @(posedge clk);
      irq_sources_i = '0;
      repeat (2) @(posedge clk);
    end
  endtask

  task claim_target0(output logic [31:0] claim_data);
    begin
      bus_read(32'h0c20_0004, claim_data);
    end
  endtask

  task complete_target0(input logic [31:0] id);
    begin
      bus_write(32'h0c20_0004, id);
    end
  endtask

  logic [31:0] claim_data;

//  initial begin
//    $display("TIME\tIRQ\t\t\t\tEIP\tRDATA\tERROR");
//    $monitor("%0t\t%b\t%b\t%h\t%b",
//             $time, irq_sources_i, eip_targets_o, rdata_o, error_o);
//  end

  initial begin
    reset_dut();

    // Configure priority for sources
    bus_write(32'h0c00_0000, 32'd3); // source 0 priority
    bus_write(32'h0c00_0004, 32'd4); // source 1 priority
    bus_write(32'h0c00_0008, 32'd5); // source 2 priority
    bus_write(32'h0c00_000c, 32'd6); // source 3 priority

    // Enable interrupts for target 0
    bus_write(32'h0c00_2000, 32'h0000_ffff);

    // Threshold target 0 = 0
    bus_write(32'h0c20_0000, 32'd0);

    $display("Test1: Single interrupt source 3");
    send_interrupt(3);
    repeat (3) @(posedge clk);

    claim_target0(claim_data);
    $display("Claim ID = %0d", claim_data[4:0]);

    complete_target0(claim_data);
    repeat (3) @(posedge clk);

    $display("Test_2: Single interrupt source 2");
    send_interrupt(2);
    repeat (3) @(posedge clk);

    claim_target0(claim_data);
    $display("Claim ID = %0d", claim_data[4:0]);

    complete_target0(claim_data);
    repeat (3) @(posedge clk);

    $display("test 3: Multiple interrupts source and 3");
    irq_sources_i = '0;
    irq_sources_i[1] = 1'b1;
    irq_sources_i[3] = 1'b1;
    repeat (2) @(posedge clk);
    irq_sources_i = '0;
    repeat (3) @(posedge clk);

    claim_target0(claim_data);
    $display("Claim ID = %0d", claim_data[4:0]);

    complete_target0(claim_data);
    repeat (3) @(posedge clk);

    $display("TEST4: Level-triggered source 2");
    le_i = '0;
    irq_sources_i = '0;
    irq_sources_i[2] = 1'b1;
    repeat (5) @(posedge clk);

    claim_target0(claim_data);
    $display("Claim ID = %0d", claim_data[4:0]);

    complete_target0(claim_data);
    irq_sources_i[2] = 1'b0;
    repeat (5) @(posedge clk);

    $display("TEST5: Idle check");
    irq_sources_i = '0;
    repeat (5) @(posedge clk);

    $display("Simulation Completed");
    $finish;
  end

endmodule