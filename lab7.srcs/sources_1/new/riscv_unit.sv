`timescale 1ns / 1ps

module riscv_unit(
    input logic clk_i,
    input logic resetn_i,
    
    input  logic kclk_i,     // Тактирующий сигнал клавиатуры
    input  logic kdata_i,    // Сигнал данных клавиатуры
    
    output logic [6:0] hex_led_o,  // Вывод семисегментных индикаторов
    output logic [7:0] hex_sel_o  // Селектор семисегментных индикаторов
    );
    
    logic rst_i;
    assign rst_i = !resetn_i;
    
    logic clk_gen;
    
    clkgen clkgen(
        .clkin(clk_i),
        .clkout(clk_gen)
    );
    
    logic [31:0] int_req;
    logic [31:0] int_fin;
    
    logic [31:0] instr;
    logic [31:0] instr_addr;
    
    logic [31:0] data_rdata;
    logic data_req;
    logic data_we;
    logic [3:0] data_be;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    
    riscv_newcore core(
        .clk_i(clk_gen),
        .rst_i(rst_i),
        //interrupt
        .int_req_i(int_req),
        .int_fin_o(int_fin),
        //instruction memory 
        .instr_i(instr),
        .instr_addr_o(instr_addr),
        //periph bus
        .data_rdata_i(data_rdata),
        .data_req_o(data_req),  
        .data_we_o(data_we),   
        .data_be_o(data_be),   
        .data_addr_o(data_addr), 
        .data_wdata_o(data_wdata) 
    );
    
    
    //подключение периферии
    //addresses
    logic [7:0] periph_ad;
    logic [255:0] periph_req;
    logic [31:0] addr_reg;
    //requests
    logic memory_req;
    logic hex_req;
    logic ps2_req;
    //rdata
    logic [31:0] mem_rdata, ps2_rdata, hex_rdata;
    //interrupt
    logic ps2_intr;
    logic ps2_intf;
    
    assign periph_ad = data_addr[31:24];
    assign addr_reg = {8'd0, data_addr[23:0]};
    
    //one hot encoder
    always_comb begin
        periph_req <= '0;
        periph_req [periph_ad] <= 1;
    end
    //
    assign memory_req = data_req & periph_req[0];
    assign hex_req = data_req & periph_req[4];
    assign ps2_req = data_req & periph_req[3];
    
    assign ps2_intf = int_fin[0];
    assign int_req = {31'b0,ps2_intr}; 
    //подключаем контроллер ps2
    ps2_sb_ctrl ps2_ctrl(
        .clk_i(clk_gen),
        .rst_i(rst_i),                  
        .addr_i(addr_reg),        
        .req_i(ps2_req),         
        .write_data_i(data_wdata),  
        .write_enable_i(data_we),
        .read_data_o(ps2_rdata),   
        
        .interrupt_request_o(ps2_intr),
        .interrupt_return_i(ps2_intf),
        
        .kclk_i(kclk_i),
        .kdata_i(kdata_i)
        
    );
    // подключаем контроллер hex
    hex_sb_ctrl hex_ctrl(
        .clk_i(clk_gen),
        .rst_i(rst_i),                  
        .addr_i(addr_reg),        
        .req_i(hex_req),         
        .write_data_i(data_wdata),  
        .write_enable_i(data_we),
        .read_data_o(hex_rdata),   
        
        .hex_led(hex_led_o),
        .hex_sel(hex_sel_o)
    );
    
    //подключаем память
    miriscv_ram ram(
        .clk_i(clk_gen),
        .rst_n_i(rst_i),
        
        .instr_data_o(instr),
        .instr_addr_i(instr_addr),
        
        .data_rdata_o(mem_rdata),
        .data_req_i(memory_req),  
        .data_we_i(data_we),   
        .data_be_i(data_be),   
        .data_addr_i(addr_reg), 
        .data_wdata_i(data_wdata) 
    );
    
    always_comb begin
        data_rdata <= '0;
        case (periph_ad)
            8'h0: data_rdata <= mem_rdata;
            8'h3: data_rdata <= ps2_rdata;
            8'h4: data_rdata <= hex_rdata;
        endcase
    end
     
endmodule
