module pipe_MIPS16 (clk1, clk2); 
input clk1, clk2; // Two-phase clock 
reg [15:0] PC, IF_ID_IR, IF_ID_NPC, RR_EX_NPC, EX_MEM_NPC, MEM_WB_NPC, RR_EX_IR; 
reg [15:0] ID_RR_IR, ID_RR_NPC, RR_EX_A, RR_EX_B, ID_RR_Imm, RR_EX_Imm; 
reg [2:0] ID_RR_type, RR_EX_type, EX_MEM_type, MEM_WB_type; 
reg [15:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_A; 
reg EX_MEM_cond; 
reg [15:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
reg [15:0] ID_RR_JMP_ADDRESS; // JUMP Address 
reg [15:0] Reg [0:7]; // Register bank (16 x 8) 
reg [15:0] Mem [0:1023]; // 1024 x 32 memory
reg Carry, Zero; // Carry Flag and Zero Flag
 
parameter ADDR=4'b0001, ADI=4'b0000, NAND=4'b0010, LW=4'b0100, SW=4'b0101, LM=4'b1100, SM=4'b1101, LA=4'b1110, SA=4'b1111, BEQ=4'b1000, JAL=4'b1001, JLR=4'b1010, JRI=4'b1011;  
parameter RR_ALU=3'b000, RI_ALU=3'b001, LOAD=3'b010, STORE=3'b011, BRANCH=3'b100, JUMP=3'b101;
parameter ADD=2'b00, ADC=2'b01, ADZ=2'b10, ADL=2'b11, NDU=2'b00, NDC=2'b01, NDZ=2'b10;
//reg HALTED;  // Set after HLT instruction is completed (in WB stage) 
reg TAKEN_BRANCH, TAKEN_JUMP; // Required to disable instructions after branch
 
always @(posedge clk1) begin // IF (Instruction Fetch) Stage 
 //if (HALTED == 0) 
// begin 
  if ((EX_MEM_IR[15:12] == BEQ) && (EX_MEM_cond == 1)) begin
    IF_ID_IR <= #2 Mem[EX_MEM_ALUOut]; 
    TAKEN_BRANCH <= #2 1'b1;
//    TAKEN_JUMP <= #2 1'b0; 
    IF_ID_NPC <= #2 EX_MEM_ALUOut + 1; 
    PC <= #2 EX_MEM_ALUOut + 1; 
  end
  //else if (TAKEN_JUMP) begin
  else if ((ID_RR_IR[15:12]==4'b1001)||(ID_RR_IR[15:12]==4'b1010)||(ID_RR_IR[15:12]==4'b1011)) begin
    IF_ID_IR <= #2 Mem[ID_RR_JMP_ADDRESS];
    TAKEN_BRANCH <= #2 1'b0;
//    TAKEN_JUMP <= #2 1'b1;
    IF_ID_NPC <= #2 ID_RR_JMP_ADDRESS + 1; 
    PC <= #2 ID_RR_JMP_ADDRESS + 1;
  end 
  else begin 
    IF_ID_IR <= #2 Mem[PC];
    TAKEN_BRANCH <= #2 1'b0;
//    TAKEN_JUMP <= #2 1'b0; 
    IF_ID_NPC <= #2 PC + 1; 
    PC <= #2 PC + 1; 
  end
//  if ((IF_ID_IR[15:12]==4'b1001) || (IF_ID_IR[15:12]==4'b1011))
//  ID_RR_Imm <= #2 {{7{IF_ID_IR[8]}}, {IF_ID_IR[8:0]}};
//  else ID_RR_Imm <= #2 {{10{IF_ID_IR[5]}}, {IF_ID_IR[5:0]}};
end
 
always @(posedge clk2) begin // ID (Instruction Decode) Stage
//  if (HALTED == 0) 
// begin 
//  if (IF_ID_IR[11:9] == 3'b000) ID_RR_A <= 0; 
//  else ID_RR_A <= #2 Reg[IF_ID_IR[11:9]]; // "rs" 
//  if (IF_ID_IR[8:6] == 3'b000) ID_RR_B <= 0; 
//  else ID_RR_B <= #2 Reg[IF_ID_IR[8:6]]; // "rt" 
  ID_RR_NPC <= #2 IF_ID_NPC; 
  ID_RR_IR <= #2 IF_ID_IR;
  if ((IF_ID_IR[15:12]==4'b1001) || (IF_ID_IR[15:12]==4'b1011))
  ID_RR_Imm <= #2 {{7{IF_ID_IR[8]}}, {IF_ID_IR[8:0]}};
  else ID_RR_Imm <= #2 {{10{IF_ID_IR[5]}}, {IF_ID_IR[5:0]}};

  case (IF_ID_IR[15:12]) 
    ADDR, NAND: begin
      ID_RR_type <= #2 RR_ALU;
      TAKEN_JUMP <= #2 1'b0;
    end
    ADI: begin
      ID_RR_type <= #2 RI_ALU;
      TAKEN_JUMP <= #2 1'b0;
    end
    LW: begin
      ID_RR_type <= #2 LOAD;
      TAKEN_JUMP <= #2 1'b0;
    end
    SW: begin
      ID_RR_type <= #2 STORE;
      TAKEN_JUMP <= #2 1'b0;
    end
    BEQ: begin
      ID_RR_type <= #2 BRANCH;
      TAKEN_JUMP <= #2 1'b0;
    end 
    JAL: begin
      ID_RR_type <= #2 JUMP;
      TAKEN_JUMP <= #2 1'b1;
      ID_RR_JMP_ADDRESS <= #2 (IF_ID_NPC - 1) + {{7{IF_ID_IR[8]}}, {IF_ID_IR[8:0]}};
    end
    JLR: begin
      ID_RR_type <= #2 JUMP;
      TAKEN_JUMP <= #2 1'b1;
      ID_RR_JMP_ADDRESS <= #2 Reg[IF_ID_IR[8:6]];
    end
    JRI: begin
      ID_RR_type <= #2 JUMP;
      TAKEN_JUMP <= #2 1'b1;
      ID_RR_JMP_ADDRESS <= #2 Reg[IF_ID_IR[11:9]] + {{7{IF_ID_IR[8]}}, {IF_ID_IR[8:0]}};
    end
    default: ID_RR_type <= #2 3'b111; // Invalid opcode
  endcase
end

always @(posedge clk1) begin //RR (Register Read) Stage
  RR_EX_NPC <= #2 ID_RR_NPC;
  RR_EX_IR <= #2 ID_RR_IR;
  RR_EX_type <= #2 ID_RR_type;
  RR_EX_Imm <= #2 ID_RR_Imm;
  if (ID_RR_IR[11:9] == 3'b000) RR_EX_A <= #2 0; 
  else RR_EX_A <= #2 Reg[ID_RR_IR[11:9]]; // "rs" 
  if (ID_RR_IR[8:6] == 3'b000) RR_EX_B <= #2 0; 
  else RR_EX_B <= #2 Reg[ID_RR_IR[8:6]]; // "rt"
end
 
always @(posedge clk2) begin // EX (Execution) Stage 
// if (HALTED == 0) 
// begin
  EX_MEM_NPC <= #2 RR_EX_NPC;
  EX_MEM_type <= #2 RR_EX_type; 
  EX_MEM_IR <= #2 RR_EX_IR;
//  EX_MEM_Imm <= #2 RR_EX_Imm
//  TAKEN_BRANCH <= #2 0; 
  case (RR_EX_type) 
    RR_ALU: begin 
      case (RR_EX_IR[15:12]) // "opcode" 
        ADDR: begin
          case (RR_EX_IR[1:0])
            ADD: {Carry,EX_MEM_ALUOut} <= #2 RR_EX_A + RR_EX_B;
            ADC: begin
              if (Carry) {Carry,EX_MEM_ALUOut} <= #2 RR_EX_A + RR_EX_B;
              else {Carry,EX_MEM_ALUOut} <= {Carry,EX_MEM_ALUOut};
            end
            ADZ: begin
              if (Zero) {Carry,EX_MEM_ALUOut} <= #2 RR_EX_A + RR_EX_B;
              else {Carry,EX_MEM_ALUOut} <= {Carry,EX_MEM_ALUOut};
            end
            ADL: {Carry,EX_MEM_ALUOut} <= #2 RR_EX_A + (2*RR_EX_B);
          endcase
        end
        NAND: begin
          case (RR_EX_IR[1:0])
            NDU: EX_MEM_ALUOut <= #2 ~(RR_EX_A & RR_EX_B);
            NDC: begin
              if (Carry) EX_MEM_ALUOut <= #2 ~(RR_EX_A & RR_EX_B);
              else EX_MEM_ALUOut <= EX_MEM_ALUOut;
            end
            NDZ: begin
              if (Zero) EX_MEM_ALUOut <= #2 ~(RR_EX_A & RR_EX_B);
              else EX_MEM_ALUOut <= EX_MEM_ALUOut;
            end
          endcase
        end
        //default: EX_MEM_ALUOut <= #2 16'hxxxxxxxx; 
      endcase
    end
  
    RI_ALU: {Carry,EX_MEM_ALUOut} <= #2 RR_EX_A + RR_EX_Imm; // ADI Instruction  
  
    LOAD, STORE: begin 
      EX_MEM_ALUOut <= #2 RR_EX_B + RR_EX_Imm; 
      EX_MEM_A <= #2 RR_EX_A; 
    end

    BRANCH: begin 
      EX_MEM_ALUOut <= #2 RR_EX_NPC + RR_EX_Imm; 
      EX_MEM_cond <= #2 (RR_EX_A == RR_EX_B); 
    end

    JUMP: begin
      case (RR_EX_IR[15:12])
        JAL: EX_MEM_ALUOut <= #2 (RR_EX_NPC - 1) + RR_EX_Imm;
        JLR: EX_MEM_ALUOut <= #2 RR_EX_B;
        JRI: EX_MEM_ALUOut <= #2 RR_EX_A + RR_EX_Imm;
      endcase
    end

    default: EX_MEM_ALUOut <= #2 16'hxxxx;
  endcase
end
 
always @(posedge clk1) begin // MEM (Memory Access) Stage 
// if (HALTED == 0) 
// begin
  MEM_WB_NPC <= #2 EX_MEM_NPC;
  MEM_WB_type <= #2 EX_MEM_type; 
  MEM_WB_IR <= #2 EX_MEM_IR; 
  case (EX_MEM_type) 
    RR_ALU, RI_ALU: begin
      MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;
      if (EX_MEM_ALUOut == 16'h0000) Zero <= #2 1'b1;
      else Zero <= #2 1'b0;
    end
    LOAD: begin
      MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut];
      if (Mem[EX_MEM_ALUOut]==16'h0000) Zero <= #2 1'b1;
      else Zero <= #2 1'b0;
    end
    STORE: if (TAKEN_BRANCH == 0) Mem[EX_MEM_ALUOut] <= #2 EX_MEM_A; // Disable write
    //JUMP: 
  endcase
end 
 
always @(posedge clk2) begin // WB (Writeback) Stage
  if (TAKEN_BRANCH == 0) begin // Disable write if branch taken 
    case (MEM_WB_type) 
      RR_ALU: Reg[MEM_WB_IR[5:3]] <= #2 MEM_WB_ALUOut; // "rd" 
      RI_ALU: Reg[MEM_WB_IR[8:6]] <= #2 MEM_WB_ALUOut; // "rt" 
      LOAD: Reg[MEM_WB_IR[11:9]] <= #2 MEM_WB_LMD; // "rt" 
      JUMP: if ((MEM_WB_IR[15:12]==4'b1001)||(RR_EX_NPC[15:12]==4'b1010)) Reg[MEM_WB_IR[11:9]] <= #2 MEM_WB_NPC; 
    endcase
  end
end

endmodule
 