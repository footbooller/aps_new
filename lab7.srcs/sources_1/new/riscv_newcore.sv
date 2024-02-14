`timescale 1ns / 1ps

module riscv_newcore(
    input logic clk_i,
    input logic rst_i,
    //interrupt subsystem
    input logic [31:0] int_req_i,
    output logic [31:0] int_fin_o,
    
    //instruction memory
    input logic [31:0] instr_i,
    output logic [31:0] instr_addr_o,
    
    // periph bus
    input logic [31:0]  data_rdata_i,
    output logic        data_req_o,
    output logic        data_we_o,
    output logic [3:0]  data_be_o,
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o
    );
    
    logic [31:0] mcause;
    logic int_i;
    logic int_rst;
    logic [31:0] mie;
        
    riscv_core core(
        .clk_i(clk_i),
        .rst_i(rst_i),
        // memory interface
        .instr_i(instr_i),
        .instr_addr_o(instr_addr_o),
        
        .data_rdata_i(data_rdata_i),
        .data_req_o(data_req_o),
        .data_we_o(data_we_o),
        .data_be_o(data_be_o),
        .data_addr_o(data_addr_o),
        .data_wdata_o(data_wdata_o),
        
        //interrupt controller
        .mcause_i(mcause),
        .int_i(int_i),
        .int_rst_o(int_rst),
        .mie_o(mie)
    );
    
    intctrl_riscv intctrl(
        .clk_i(clk_i),
        .int_rst_i(int_rst),
        
        .mie_i(mie),
        .int_req_i(int_req_i),
        .mcause_o(mcause),
        .int_o(int_i),
        .int_fin_o(int_fin_o)
    );
    
    
    
endmodule
