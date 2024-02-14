`timescale 1ns / 1ps

module ps2_sb_ctrl(
/*
    „асть интерфейса модул€, отвечающа€ за подключение к системной шине
*/
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [31:0]  addr_i,
  input  logic         req_i,
  input  logic [31:0]  write_data_i,
  input  logic         write_enable_i,
  output logic [31:0]  read_data_o,

/*
    „асть интерфейса модул€, отвечающа€ за отправку запросов на прерывание
    процессорного €дра
*/

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

/*
    „асть интерфейса модул€, отвечающа€ за подключение к модулю,
    осуществл€ющему прием данных с клавиатуры
*/
  input  logic kclk_i,
  input  logic kdata_i
);

    logic [7:0] scan_code;
    logic       scan_code_is_unread;
    
    logic [7:0] keycode;
    logic valid;
    
    PS2Receiver PS2Receiver(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .kclk_i(kclk_i),
        .kdata_i(kdata_i),
        .keycodeout_o(keycode),
        .keycode_valid_o(valid)
    );
    //записываем в регистры значение с приемника и выставл€ем сигналы unread
    always_ff @(posedge clk_i) begin 
        if (rst_i | (addr_i == 32'h24 & write_data_i[0] == 1 & write_enable_i & req_i)) begin
            scan_code <= 0;
            scan_code_is_unread <= 0;
        end else begin
            if (valid) begin
                scan_code <= keycode;
                scan_code_is_unread <= 1;
            end
            
            if (!valid & interrupt_return_i == 32'h1) begin
                scan_code_is_unread <= 0; 
            end
        end
    end    
    //чтение из регистров
    always_comb begin
        read_data_o <= 0;
        if ( req_i & !write_enable_i) begin
            case (addr_i)
                32'h0: read_data_o <= {24'b0, scan_code};
                32'h4: read_data_o <= {31'b0, scan_code_is_unread};
            endcase
        end
    end
    
    assign interrupt_request_o = scan_code_is_unread;
    
    
    
    
endmodule