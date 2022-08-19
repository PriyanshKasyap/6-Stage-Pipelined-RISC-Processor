//`timescale 1us/1ns
module test_mips16;
reg clk1, clk2; 
integer k; 
pipe_MIPS16 mips (clk1, clk2);
initial begin

 clk1 = 0; clk2 = 0; 
 repeat (20) // Generating two-phase clock 
 begin 
 #5 clk1 = 1; #5 clk1 = 0; 
 #5 clk2 = 1; #5 clk2 = 0; 
 end 
 end
 
 
initial begin
  for (k=0; k<7; k=k+1) begin
    mips.Reg[k] = k; 
    mips.Mem[0] = 16'h1008; // R1 = R0 + R0 = 0
    mips.Mem[1] = 16'h1010; // R2 = R0 + R0 = 0
    mips.Mem[2] = 16'h0248; // R1 = R1 + 8 = 8
    mips.Mem[3] = 16'h048A; // R2 = R2 + 10 = 10 
    mips.Mem[4] = 16'h1298; // R3 = R1 + R2 = 18
    mips.Mem[5] = 16'h9802; // R4 = PC + 1= 6, PC = PC + 2 (PC = Address of Current Instruction = 5)
    mips.Mem[6] = 16'h0000; // Dummy 
    mips.Mem[7] = 16'h12A8; // R5 = R1 + R2 = 18
    mips.Mem[8] = 16'h0000; // Dummy
  end
 
    //mips.HALTED = 0; 
    mips.PC = 0; 
    mips.TAKEN_BRANCH = 0;
    mips.TAKEN_JUMP = 0; 
    #280 for (k=0; k<6; k=k+1) begin
      $display ("R%1d - %2d", k, mips.Reg[k]);
    end
end 
 
initial begin 
//  $dumpfile ("mips.vcd"); 
//  $dumpvars (0, test_mips16);
  $dumpvars ();
  #300 $finish; 
end

endmodule
