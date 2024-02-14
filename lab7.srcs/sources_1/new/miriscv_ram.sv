`timescale 1ns / 1ps

module miriscv_ram(
        input logic clk_i,
        input logic rst_n_i,
        
        output logic [31:0] instr_data_o,
        input logic [31:0] instr_addr_i,
        
        output logic [31:0] data_rdata_o,
        input logic data_req_i,
        input logic data_we_i,
        input logic [3:0] data_be_i,
        input logic [31:0] data_addr_i,
        input logic [31:0] data_wdata_i
        
    );
    
    logic [7:0] instr_rom [1024];
    logic [7:0] data_ram [1024];
    
    initial begin
        $readmemh("program.txt", instr_rom);
    end
    
    
    logic [9:0] instr_loaddr, data_loaddr;
    assign instr_loaddr = {instr_addr_i[9:2], 2'b00};  
    assign data_loaddr = {data_addr_i[9:2], 2'b00};
    
    always_comb begin 
        instr_data_o <= {instr_rom[instr_loaddr+3], instr_rom[instr_loaddr+2], instr_rom[instr_loaddr+1], instr_rom[instr_loaddr]};
    end
    
    always_ff @(posedge clk_i) begin //запись
    
        if (data_req_i & data_we_i) begin
            if (data_be_i[0]) data_ram[data_loaddr] <= data_wdata_i[7:0];
            if (data_be_i[1]) data_ram[data_loaddr+1] <= data_wdata_i[15:8];
            if (data_be_i[2]) data_ram[data_loaddr+2] <= data_wdata_i[23:16];
            if (data_be_i[3]) data_ram[data_loaddr+3] <= data_wdata_i[31:24];
        end
    end
    //чтение        
    always_comb begin
        if (!data_we_i & data_req_i) 
        data_rdata_o <= {data_ram[data_loaddr+3], data_ram[data_loaddr+2], data_ram[data_loaddr+1], data_ram[data_loaddr]};
    end

endmodule
