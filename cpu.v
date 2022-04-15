// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

`include "mux.v"
`include "pc.v"
`include "Memory.v"
`include "control_unit.v"
`include "ImmediateGenerator.v"
`include "opcodes.v"
`include "alu.v"
`include "RegisterFile.v"


module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/

  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.

  //PC
  wire [31:0] next_pc;
  wire [31:0] current_pc;
  wire pc_signal;

  wire alu_bcond_temp;
  assign alu_bcond_temp = (IR[14:12] == 3'b000 & alu_bcond[0] == 1) ? 1: 
  (IR[14:12] == 3'b001 & alu_bcond[0] == 0) ? 1 :
  (IR[14:12] == 3'b100 & alu_bcond[1] == 1) ? 1 : 
  (IR[14:12] == 3'b101 & (alu_bcond[0] == 1 | alu_bcond[2] == 1 )) ? 1 : 1'b0;

  // always @(*) begin
  //   $display("alu_bcond_temp : %b, pc_signal: %b",alu_bcond_temp, pc_signal);

  // end

  assign pc_signal = (pc_write_cond & alu_bcond_temp) | pc_write;

  //Register File
  wire [4:0] rs1;          
  wire [4:0] rs2;          
  wire [4:0] rd;        
  wire [31:0] rd_din;           
  wire [31:0] rs1_dout;  
  wire [31:0] rs2_dout;
  
  assign rs1 = IR[19:15];
  assign rs2 = IR[24:20];
  assign rd = IR[11:7]; 
 
  // always @(rd) begin
  //   $display("rd is %d in cpu", rd);
  // end

  mux_2_to_1 memdata_rf(ALUOut, MDR, mem_to_reg, rd_din);

 
  //Control unit
  wire pc_write_cond;
  wire pc_write;
  wire lorD;
  wire mem_read;
  wire mem_write;
  wire mem_to_reg;
  wire ir_write;
  wire pc_source;
  wire [1:0] aluop;
  wire ALUsrc_A;
  wire [1:0] ALUsrc_B;
  wire write_enable;

  reg [2:0] cur_state;
  wire [2:0] next_state;


  always @(posedge clk) begin
    if(reset)
      cur_state <= `INIT; // Init
    else
      cur_state <= next_state;
  end




  //Memory
  wire [31:0] addr;
  wire [31:0] din;
  wire [31:0] dout;

  assign din = B;

  mux_2_to_1 pc_mem(current_pc, ALUOut, lorD, addr);


  always @(posedge clk) begin
    if(ir_write == 1) 
    IR <= dout;
   
    MDR <= dout;

    ALUOut <= alu_result;
   
    A <= rs1_dout;
    B <= rs2_dout;
    // $display("mdr is %x", MDR);
    // $display("ALUOut is %x", ALUOut);
    //  $display("A : %x, B : %x", A, B);
  end

  // always @(*) begin
  //    A <= rs1_dout;
  //    B <= rs2_dout;
  // end

  //immediate generator
  wire [31:0] imm_gen_out;

  // alu & alu_control
  wire [3:0] alu_control;
  wire [2:0] alu_bcond;
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;
  wire [31:0] alu_result;

  mux_2_to_1 alu_in1(current_pc, A, ALUsrc_A, alu_in_1);
  mux_4_to_1 alu_in2(B, 3'b100, imm_gen_out, ALUsrc_B, alu_in_2);

  mux_2_to_1 alu_pc(alu_result, ALUOut, pc_source, next_pc);
 




  assign is_halted = (reg_file.rf[17] == 10 & IR[6:0] == `ECALL) ? 1 : 0;
 
  // always @(reg_file.rf[17]) begin
  //   $display("reg_file.rf[17] is %x", reg_file.rf[17]);
  //   // $display("IR[6:0] is %b", IR[6:0]);
  // end



  // integer i;
  // always @(*) begin
  //   if(current_pc >= 8'h8c) begin
  //     for (i = 0; i < 32; i = i + 1)
  //       $display("%d %x\n", i, reg_file.rf[i]);
  //       $finish();
  //   end
  // end


  // always @(current_pc) begin
  //   $display("ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ %x", current_pc);
  // end

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .pc_signal(pc_signal), // input
    .current_pc(current_pc)   // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(rs1),          // input
    .rs2(rs2),          // input
    .rd(rd),           // input
    .rd_din(rd_din),       // input
    .write_enable(write_enable),    // input
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout)      // output
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(addr),         // input
    .din(din),          // input
    .mem_read(mem_read),     // input
    .mem_write(mem_write),    // input
    .dout(dout)          // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .opcode(IR[6:0]), // input
    .pc_write_cond(pc_write_cond),
    .pc_write(pc_write),
    .lorD(lorD),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .ir_write(ir_write),
    .pc_source(pc_source),
    .aluop(aluop),
    .ALUsrc_A(ALUsrc_A),
    .ALUsrc_B(ALUsrc_B),
    .write_enable(write_enable),
    .reset(reset),
    .cur_state(cur_state),
    .next_state(next_state)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IR),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .part_of_inst(IR),  // input
    .aluop(aluop), // input
    .alu_control(alu_control)         // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_control(alu_control),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

 

endmodule
