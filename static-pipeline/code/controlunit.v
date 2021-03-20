`timescale 1ns / 1ps
module controlunit(
    input clk,
    input [31:0] inst,
    input [31:0] rs,
    input [31:0] rt,
    output reg [4:0]aluchoice,
    output reg [1:0]alu_achoice,
    output reg [1:0]alu_bchoice,
    output reg [1:0]rf_addrinchoice,
    output reg [2:0]rf_inchoice,
    output reg rf_inallow,
    output reg hi_inchoice,
    output reg lo_inchoice,
    output reg [1:0]dmem_inchoice,
    output reg [2:0]dmem_outchoice,
    
    output reg mfc0src,
    output reg mtc0src,
    output reg exception,
    output reg _eret,
    output reg [4:0]cause
    );
    wire [16:0]moreop;
    assign moreop = {inst[31:21],inst[5:0]};
    wire [11:0]opcode;
    assign opcode = {inst[31:26],inst[5:0]};
    wire [5:0]halfop;
    assign halfop = {inst[31:26]};
          
    parameter [5:0]
    addi = 6'b001000,
    addiu = 6'b001001,
    andi = 6'b001100,
    ori = 6'b001101,
    sltiu = 6'b001011,
    lui = 6'b001111,
    xori = 6'b001110,
    slti = 6'b001010,
    beq = 12'b000100,
    bne = 6'b000101,
    bgez = 6'b000001,
    
    j = 6'b000010,
    jal = 6'b000011,
        
    lw = 6'b100011,
    sw = 6'b101011,
    lb = 6'b100000,
    lbu = 6'b100100,
    lhu = 6'b100101,
    sb = 6'b101000,
    sh = 6'b101001,
    lh = 6'b100001;
     
    parameter [11:0] 
    addu = 12'b000000_100001,
    _and = 12'b000000_100100,
    _xor = 12'b000000_100110,
    _nor = 12'b000000_100111,
    _or = 12'b000000_100101,
    sll = 12'b000000_000000,
    sllv = 12'b000000_000100,
    sltu = 12'b000000_101011,
    sra = 12'b000000_000011,
    srl = 12'b000000_000010,
    subu = 12'b000000_100011,
    add = 12'b000000_100000,
    sub = 12'b000000_100010,
    slt = 12'b000000_101010,
    srlv = 12'b000000_000110,
    srav = 12'b000000_000111,
    clz = 12'b011100_100000,
    divu = 12'b000000_011011,
    mul = 12'b011100_000010,
    multu = 12'b000000_011001,
    teq = 12'b000000_110100,
    div = 12'b000000_011010,
    
    jr = 12'b000000_001000,
    jalr = 12'b000000_001001,

    mfhi = 12'b000000_010000,
    mflo = 12'b000000_010010,
    mthi = 12'b000000_010001,
    mtlo = 12'b000000_010011,
    
    eret = 12'b010000_011000,
    syscall = 12'b000000_001100,
    _break = 12'b000000_001101;
    
    parameter [16:0]
    mfc0 = 17'b010000_00000_000000,
    mtc0 = 17'b010000_00100_000000;
                
    //根据opcode和当前状态确认当前控制信号
    always @(posedge clk) 
    begin;
        //alu的操作
        case(opcode)
            addu,addiu:aluchoice <= 5'b00000;
            add,addi:aluchoice <= 5'b00001;
            subu:aluchoice <= 5'b00010;
            sub:aluchoice <= 5'b00011;
            andi,_and:aluchoice <= 5'b00100;
            ori,_or:aluchoice <= 5'b00101;
            xori,_xor:aluchoice <= 5'b00110;
            _nor:aluchoice <= 5'b00111;
            lui:aluchoice <= 5'b01000;
            sltu,sltiu:aluchoice <= 5'b01001;
            slt,slti:aluchoice <= 5'b01010;
            sra,srav:aluchoice <= 5'b01011;
            srl,srlv:aluchoice <= 5'b01100;
            sll,sllv:aluchoice <= 5'b01101;
            beq:aluchoice <= 5'b01110;
            bne:aluchoice <= 5'b01111;
            bgez:aluchoice <= 5'b10000;
            div:aluchoice <= 5'b10001;
            divu:aluchoice <= 5'b10010;
            mul:aluchoice <= 5'b10011;
            multu:aluchoice <= 5'b10100;
            clz:aluchoice <= 5'b10101;
            teq:aluchoice <= 5'b10110;
            default: aluchoice <= 5'b00000;
        endcase
        case(halfop)
            addiu:aluchoice <= 5'b00000;
            addi, lw, sw, lb, lbu, lhu, sb, sh, lh:aluchoice <= 5'b00001;
            andi:aluchoice <= 5'b00100;
            ori:aluchoice <= 5'b00101;
            xori:aluchoice <= 5'b00110;
            lui:aluchoice <= 5'b01000;
            sltiu:aluchoice <= 5'b01001;
            slti:aluchoice <= 5'b01010;
            beq:aluchoice <= 5'b01110;
            bne:aluchoice <= 5'b01111;
            bgez:aluchoice <= 5'b10000;
            default: aluchoice <= aluchoice;
        endcase
        //alu_a选择
        case(opcode)
            sll, srl, sra:alu_achoice <= 2'b10;
            sllv, srlv, srav:alu_achoice <= 2'b01;
            default: alu_achoice <= 2'b00;   
        endcase
        //alu_b选择
        case(halfop)
            jal, jalr:alu_bchoice <= 2'b11;
            andi, ori, xori, lw, sw, lb, lbu, lhu, sb, sh, lh:alu_bchoice <= 2'b10;
            addi,addiu, sltiu, lui, slti:alu_bchoice <= 2'b01;
            default: alu_bchoice <= 2'b00;    
        endcase
        //rf_addrin选择
        case(halfop)
            addi,addiu, andi, ori, sltiu, lui, xori, slti, lw, sw, lb, lbu, lhu, sb, sh, lh:rf_addrinchoice = 2'b01;
            jal:rf_addrinchoice = 2'b10;
            default: rf_addrinchoice = 2'b00;    
        endcase
        if(moreop == mfc0)
            rf_addrinchoice = 2'b01;
        else
            rf_addrinchoice = rf_addrinchoice;
        //rf_in选择
        if(halfop == jal || opcode == jalr)
            rf_inchoice <= 3'b001;
        else if(halfop == lw || halfop == lb || halfop == lbu || halfop == lhu || halfop == lh)
            rf_inchoice <= 3'b010;
        else if(opcode == mul || opcode == multu)
            rf_inchoice <= 3'b011;
        else if(moreop == mfc0)
            rf_inchoice <= 3'b100;
        else if(opcode == mfhi)
            rf_inchoice <= 3'b101;
        else if(opcode == mflo)
            rf_inchoice <= 3'b110;
        else
            rf_inchoice <= 0;
        //rf_inallow选择
        if (halfop != sw && halfop != sh && halfop != sb && halfop != beq && halfop != bne)
            rf_inallow <= 1;
        else
            rf_inallow <= 0;
        //hi_lo
        if(opcode == mthi)
        begin
            hi_inchoice <= 1;
            lo_inchoice <= 0;
        end
        else if(opcode == mtlo)
        begin
            hi_inchoice <= 0;
            lo_inchoice <= 1;
        end
        else
        begin
            hi_inchoice <= 0;
            lo_inchoice <= 0;
        end
        //dmem
        case(halfop)
            sw:dmem_inchoice <= 2'b01;
            sh:dmem_inchoice <= 2'b10;
            sb:dmem_inchoice <= 2'b11;
            default: dmem_inchoice <= 2'b00;
        endcase
        case(halfop)
            lw:dmem_outchoice <= 3'b000;
            lh:dmem_outchoice <= 3'b001;
            lhu:dmem_outchoice <= 3'b010;
            lb:dmem_outchoice <= 3'b011;
            lbu:dmem_outchoice <= 3'b100;
            default: dmem_outchoice <= 3'b000;
        endcase
        //cp0
        case(opcode)
            teq:
            begin 
                if(rs == rt)
                begin
                    exception <= 1;
                    _eret <= 0;
                    cause <= 5'b01101;
                end
            end
            _break:
            begin 
                exception <= 1;
                _eret <= 0;
                cause <= 5'b01001;
            end
            eret:
            begin 
                exception <= 0;
                _eret <= 1;
            end
            syscall:
            begin   
                exception <= 1;
                _eret <= 0;
                cause <= 5'b01000;
            end
            default:
            begin 
                exception <= 0;
                _eret <= 0;
                cause <= 5'b00000;
            end
        endcase
        if(moreop == mfc0)
        begin
            mfc0src <= 1;
            mtc0src <= 0;
        end
        else if(moreop == mtc0)
        begin
            mfc0src <= 0;
            mtc0src <= 1;
        end
        else
        begin
            mfc0src <= 0;
            mtc0src <= 0;
        end       
   end
endmodule