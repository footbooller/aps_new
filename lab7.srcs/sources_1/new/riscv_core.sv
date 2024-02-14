`timescale 1ns / 1ps

module riscv_core(
    input logic clk_i,
    input logic rst_i,
    // ��������� ������
    
    
    //��� ������ ����������
    input logic [31:0] instr_i,
    output logic [31:0] instr_addr_o,
    //��� ������ ������
    input logic [31:0]  data_rdata_i,
    output logic        data_req_o,
    output logic        data_we_o,
    output logic [3:0]  data_be_o,
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    
    //���������� ����������
    input logic [31:0] mcause_i,
    input logic int_i,
    
    output logic int_rst_o,
    output logic [31:0] mie_o
    );
    ////////////////////////////////////////////////////////////////////////////////////////
    logic [31:0] PC; // program counter
    
    logic [4:0] read_addr_1;    //������ ��
    logic [4:0] read_addr_2;
    logic [4:0] write_addr;
    
    logic [31:0] imm_I; // ���������
    logic [31:0] imm_U;
    logic [31:0] imm_S;
    logic [31:0] imm_B;
    logic [31:0] imm_J;
    
    assign read_addr_1 = instr_i[19:15]; // ������� � ��
    assign read_addr_2 = instr_i[24:20];
    assign write_addr = instr_i[11:07];
    
    assign imm_I = {{20{instr_i[31]}}, instr_i[31:20]};// ���������������� ���������
    assign imm_U = {instr_i[31:12], 12'h000};
    assign imm_S = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
    assign imm_B = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
    assign imm_J = {{10{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[31:21],1'b0};
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    logic stall;
    
    logic gpr_we; // ������ � �����������
    logic wb_sel;
    logic [1:0] a_sel;
    logic [2:0] b_sel;
    logic [4:0] alu_op;
    logic branch;
    logic jal;
    logic [1:0] jalr;
    
    logic mem_we;
    logic [2:0] mem_size;
    logic [31:0] mem_wd;
    logic mem_req;
    logic [31:0] mem_rd;
    
    logic enpc;
    
    logic csr;
    logic [2:0] csr_op;
    
    decoder_riscv decoder_riscv( // ����������� �����������
        .fetched_instr_i(instr_i),
        .stall_i(stall),
        .int_i(int_i),
        
        .a_sel_o(a_sel),
        .b_sel_o(b_sel),
        .alu_op_o(alu_op),
        
        .mem_req_o(mem_req),
        .mem_we_o(mem_we),
        .mem_size_o(mem_size),
        
        .gpr_we_o(gpr_we),
        .wb_sel_o(wb_sel),
        .illegal_instr_o(),
        
        .branch_o(branch),
        .jal_o(jal),
        .jalr_o(jalr),
        
        .enpc_o(enpc),
        
        .csr_o(csr),
        .int_rst_o(int_rst_o),
        .csr_op_o(csr_op)
        
    );
    /////////////////////////////////////////////////////////////////////////////////////
    logic [31:0] wb_data;
    logic [31:0] csr_or_wb;
    logic [31:0] read_data1; // ������ � ��
    logic [31:0] read_data2;
    
    rf_riscv rf_riscv(      //����������� ��
        .clk_i(clk_i),
        .write_enable_i(gpr_we),
        
        .read_addr1_i(read_addr_1),
        .read_addr2_i(read_addr_2),
        .write_addr_i(write_addr),
        
        .write_data_i(csr_or_wb),
        .read_data1_o(read_data1),
        .read_data2_o(read_data2)
    );
    
    assign mem_wd = read_data2; // ����������� ������ mem_wd
    ///////////////////////////////////////////////////////////////////////////////////////////   
    logic [31:0] alu_a; //����� ���
    logic [31:0] alu_b;
    
    always_comb begin //������������� �� ����� ��� �
        alu_a <= 32'b0;
        case (a_sel)
            0: alu_a <= read_data1;
            1: alu_a <= PC; //�������� �� PC
            2: alu_a <= 32'b0;
        endcase
    end
    
    always_comb begin //������������� �� ����� ��� �
        alu_b <= 32'b0;
        case (b_sel)
            0: alu_b <= read_data2;
            1: alu_b <= imm_I;
            2: alu_b <= imm_U;
            3: alu_b <= imm_S;
            4: alu_b <= 32'd4;
        endcase
    end
    
    logic [31:0] result_alu; //������ � ���
    logic flag;
    
    alu_riscv alu_riscv( //����������� ���
        .a_i(alu_a),
        .b_i(alu_b),
        .alu_op_i(alu_op),
        .result_o(result_alu),
        .flag_o(flag)
    );
    
    /////////////////////////////////////////////////////////////////////////////////
    
    always_comb begin // ������������� wb_data
        case (wb_sel)
            0: wb_data <= result_alu;
            1: wb_data <= mem_rd;
        endcase
    end
    
    //////////////////////////////////////////////////////////////////////////////////
   
    logic jb_mux;   //���������� ����������
    logic [31:0] boj;
    logic [31:0] PC_const;
    
    assign jb_mux = (branch & flag) | jal;
    
    always_comb begin //������������� branch or jamp
        case (branch)
            0: boj <= imm_J;
            1: boj <= imm_B;
        endcase
    end
    
    always_comb begin //������������� ��� PC_const
        case (jb_mux)
            0: PC_const <= 32'd4;
            1: PC_const <= boj;
        endcase
    end
    
    //////////////////////////////////////////////////////////////////////////////////
    
   // ��������
    logic [31:0] PC_d;
    logic [31:0] PC_add;
    logic [31:0] PC_jalr;
    logic [31:0] mepc;
    logic [31:0] mtvec;
    
    assign PC_add = PC + PC_const;
    assign PC_jalr = read_data1 + imm_I;
    
    always_comb begin // ������������� jalr
        PC_d <= '0;
        case (jalr)
            2'b00: PC_d <= PC_add;
            2'b01: PC_d <= PC_jalr;
            2'b10: PC_d <= mepc;
            2'b11: PC_d <= mtvec;
        endcase
    end
    
    always_ff @(posedge clk_i) begin 
    
        if (rst_i)
            PC <= 32'b0;
            
        else begin
            if (enpc == 0)
                PC <= PC_d;
            else
                PC <= PC;  
        end
        
    end
    
    assign instr_addr_o = PC;
//////////////////////////////////////////////////////////////////////////////////
    
    miriscv_lsu lsu( // ����������� LSU
        .clk_i(clk_i),
        .arstn_i(rst_i),
        //lsu protocol
        .lsu_addr_i(result_alu),
        .lsu_we_i(mem_we),
        .lsu_size_i(mem_size),
        .lsu_data_i(mem_wd),
        .lsu_req_i(mem_req),
        .lsu_stall_req_o(stall),
        .lsu_data_o(mem_rd),
        //mem protocol
        .data_rdata_i(data_rdata_i),
        .data_req_o(data_req_o),
        .data_we_o(data_we_o),
        .data_be_o(data_be_o),
        .data_addr_o(data_addr_o),
        .data_wdata_o(data_wdata_o)
    );
//////////////////////////////////////////////////////////////////////////////////
    logic [31:0] data_csr;
    CSR_riscv CSR(  //����������� CSR
        .clk_i(clk_i),
        
        .write_data_i(read_data1),
        .csr_op_i(csr_op),
        .pc_i(PC),
        .addr_i(instr_i[31:20]),
        .mcause_i(mcause_i),
        
        .mie_o(mie_o),
        .mtvec_o(mtvec),
        .mepc_o(mepc),
        .read_data_o(data_csr)
    );
//////////////////////////////////////////////////////////////////////////////////
    always_comb begin
        case (csr)
            0: csr_or_wb <= wb_data;
            1: csr_or_wb <= data_csr;
        endcase
    end
///////////////////////////////////////////////////////////////////////////////////
endmodule
