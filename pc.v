`include "opcodes.v"

module PC(reset, clk, next_pc, current_pc, pc_signal);
input clk;
input reset;
input [31: 0] next_pc;
input pc_signal;
output reg [31: 0] current_pc;

   
    always@(posedge clk) begin
        if(reset) begin
            current_pc <= 32'b0;
        end
        else begin
           if(pc_signal)
            current_pc <= next_pc;
            
        end
    end
endmodule