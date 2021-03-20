`timescale 1ns / 1ps
module controlunit(
    input [31:0] inst,
    input [31:0] rs,
    input [31:0] rt,
    output [4:0]aluchoice,
    output [1:0]alu_achoice,
    output [1:0]alu_bchoice,
    output [1:0]rf_addrinchoice,
    output [2:0]rf_inchoice,
    output rf_inallow,
    output hi_inchoice,
    output lo_inchoice,
    output [1:0]dmem_inchoice,
    output [2:0]dmem_outchoice,
    output mfc0src,
    output mtc0src,
    output exception,
    output _eret,
    output [4:0]cause
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

    assign aluchoice =  (opcode==addu || halfop==addiu) ? 5'b00000:
                        (opcode==add || halfop==addi || halfop==lw || halfop==sw || halfop==lb || halfop==lbu || halfop==lhu || halfop==sb || halfop==sh || halfop==lh) ? 5'b00001:
                        (opcode==subu) ? 5'b00010:
                        (opcode==sub) ? 5'b00011:
                        (opcode==_and || halfop==andi) ? 5'b00100:
                        (opcode==_or || halfop==ori) ? 5'b00101:
                        (opcode==_xor || halfop==xori) ? 5'b00110:
                        (opcode==_nor) ? 5'b00111:
                        (halfop==lui) ? 5'b01000:
                        (opcode==sltu || halfop==sltiu) ? 5'b01001:
                        (opcode==slt || halfop==slti) ? 5'b01010:
                        (opcode==sra || opcode==srav) ? 5'b01011:
                        (opcode==srl || opcode==srlv) ? 5'b01100:
                        (opcode==sll || opcode==sllv) ? 5'b01101:
                        (halfop==beq) ? 5'b01110:
                        (halfop==bne) ? 5'b01111:
                        (halfop==bgez) ? 5'b10000:
                        (opcode==div) ? 5'b10001:
                        (opcode==divu) ? 5'b10010:
                        (opcode==mul) ? 5'b10011:
                        (opcode==multu) ? 5'b10100:
                        (opcode==clz) ? 5'b10101:
                        (opcode==teq) ? 5'b10110: 5'b00000;

    assign alu_achoice= (opcode==sll || opcode==srl || opcode==sra) ? 2'b10:
                        (opcode==sllv || opcode==srlv || opcode==srav) ? 2'b01: 2'b00;
    
    assign alu_bchoice= (halfop==jal || halfop==jalr) ? 2'b11:
                        (halfop==andi || halfop==ori || halfop==xori || halfop==lw || halfop==sw ||
                         halfop==lb || halfop==lbu || halfop==lhu || halfop==sb || halfop==sh || halfop==lh) ? 2'b10:
                        (halfop==addi || halfop==addiu || halfop==sltiu || halfop==lui || halfop==slti) ? 2'b01: 2'b00;
                        
    assign rf_addrinchoice= (halfop==addi || halfop==addiu || halfop==andi || halfop==ori ||
                             halfop==sltiu || halfop==lui || halfop==xori || halfop==slti ||
                             halfop==lw || halfop==sw || halfop==lb || halfop==lbu || 
                             halfop==lhu || halfop==sb || halfop==sh || halfop==lh ||
                             moreop == mfc0) ? 2'b01:
                            (halfop==jal) ? 2'b10: 2'b00;
                             
    assign rf_inchoice= (halfop == jal || opcode == jalr) ? 3'b001:
                        (halfop == lw || halfop == lb || halfop == lbu || halfop == lhu || halfop == lh) ? 3'b010:
                        (opcode == mul || opcode == multu) ? 3'b011:
                        (moreop == mfc0) ? 3'b100:
                        (opcode == mfhi) ? 3'b101:
                        (opcode == mflo) ? 3'b110: 0;
    assign rf_inallow = (halfop != sw && halfop != sh && halfop != sb && halfop != beq && halfop != bne) ? 1: 0;

    assign hi_inchoice= (opcode == mthi) ? 1: 0;                        

    assign lo_inchoice= (opcode == mtlo) ? 1: 0;

    assign dmem_inchoice =  (halfop==sw) ? 2'b01:
                            (halfop==sh) ? 2'b10:
                            (halfop==sb) ? 2'b11: 2'b00;
    
    assign dmem_outchoice = (halfop==lh) ? 3'b001:
                            (halfop==lhu) ? 3'b010:
                            (halfop==lb) ? 3'b011:
                            (halfop==lbu) ? 3'b100: 3'b000; //lw->dmem_outchoice==3'b000
    
    assign exception =  ((opcode==teq && rs==rt) || opcode==_break || opcode==syscall) ? 1: 0;

    assign _eret =  (opcode==eret) ? 1: 0;

    assign cause =  (opcode==teq && rs==rt) ? 5'b01101:
                    (opcode==_break) ? 5'b01001:
                    (opcode==syscall) ? 5'b01000:    
                    (opcode==_break) ? 5'b01001: 5'b00000;   

    assign mfc0src= (moreop == mfc0) ? 1: 0;    

    assign mtc0src= (moreop == mtc0) ? 1: 0;

endmodule