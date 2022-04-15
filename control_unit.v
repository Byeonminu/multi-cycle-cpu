`include "opcodes.v"


module ControlUnit (
                    input reset,
                    input [6:0] opcode,
                    input [2:0] cur_state,
                    output reg pc_write_cond,
                    output reg pc_write,
                    output reg lorD,
                    output reg mem_read,
                    output reg mem_write,
                    output reg mem_to_reg,
                    output reg ir_write,
                    output reg pc_source,
                    output reg write_enable,
                    output reg ALUsrc_A,
                    output reg [1:0] ALUsrc_B,
                    output reg [1:0] aluop,
                    output reg [2:0] next_state);

// always @(*) begin
//     // $display("current pc is %x", current_pc);
//     $display("currnet state is %b", cur_state);
//     $display("next_state is %b", next_state);
//     $display("opcode is %b", opcode);
//   end




always @(*) begin
    if(reset) begin
        lorD = 0;
        mem_read = 1;
        ir_write = 1;
    end
end





// state transition
always @(*) begin
    if(cur_state == `INIT) begin
        next_state = `IF;
    end
    else if(cur_state == `IF) begin  // IF
         next_state = `ID;
    end
    else if(cur_state == `ID) begin //ID
        if(opcode == `ECALL) next_state = `IF;
        else next_state = `EX; 
    end
    else if(cur_state == `EX) begin // EX
        if(opcode == `LW || opcode == `SW)  next_state = `MEM;
        else if(opcode == `JAL || opcode == `JALR || opcode == `ADD || opcode == `ADDI || opcode == `BEQ) next_state = `WB;
    end
    else if(cur_state == `MEM) begin //MEM
        if(opcode == `LW) next_state = `WB;
        else if(opcode == `SW) next_state = `IF;
    end 
    else if(cur_state == `WB) next_state = `IF; //WB
    
end



always @(cur_state or opcode) begin
    if(cur_state == `IF) begin  // IF
        //$display("IFIFIFIFIFIFIFIFIFIFIFIFIFIFIFIFIF");
        ir_write =      1;
        //$display("IF 안에서 opcode = %x", opcode);
        if(opcode == `ADD || opcode == `ADDI || opcode == `LW || opcode == `SW || opcode == `JAL || opcode == `JALR || opcode == `ECALL || opcode == `BEQ) begin
        //$display("IF 안에 if문에 들어온지 확인하기!");
        
        lorD =          0;
        mem_read =      1;
        
        pc_write_cond = 0;
       
        pc_write = 0;
        mem_write = 0;
        write_enable = 0;

        // pc_source =    0;
        ALUsrc_A =     0;
        ALUsrc_B = 2'b00;
        // ir_write = 0;
        end
       

       
    end
    else if(cur_state == `ID) begin
        //$display("IDIDIDIDIDIDIDIDIDIDIDIDIDIDIDID");
        
        aluop =     2'b00;
        ir_write =      0;
        if(opcode == `ADD || opcode == `ADDI || opcode == `LW || opcode == `SW || opcode == `JALR) begin
        
       
        ALUsrc_A =      0;
        ALUsrc_B =  2'b01;
        pc_write =      0;
      
        end
        else if (opcode == `BEQ) begin
           
            ir_write = 0;
            mem_read = 0;
            pc_write = 1;
            pc_source =     0;
            ALUsrc_A =      0;
            ALUsrc_B =  2'b01;  
            
        end
        else if (opcode == `ECALL) begin
         
            ALUsrc_A =      0;
            ALUsrc_B =  2'b01;
            pc_source =     0;
            pc_write =      1;
        end
    end
    else if(cur_state == `EX) begin // EX
        //$display("EXEXEXEXEXEXEXEXEXEXEXEXEXEXEXEXEXEXEXEX");
        case (opcode) 
        7'b0110011 : aluop = 2'b10; // R-type
        7'b0000011 : aluop = 2'b00; // lw-type
        7'b0100011 : aluop = 2'b00; // s-type
        7'b1100011 : aluop = 2'b00; // sb-type
        7'b0010011 : aluop = 2'b11; // I-type
        7'b1100111 : aluop = 2'b00; // jalr-type
        7'b1101111 : aluop = 2'b00; // jal-type
        endcase
        if(opcode == `ADD) begin // R type
        mem_to_reg =    0;
        ALUsrc_A =      1;
        ALUsrc_B =  2'b00;
        end
        else if(opcode == `ADDI) begin // I type
        
        ALUsrc_A =      1;
        ALUsrc_B =  2'b10;
        end
        else if(opcode == `JAL) begin // JAL type
        
        ALUsrc_A =      0;
        ALUsrc_B =  2'b01;
        end
        else if(opcode == `JALR) begin // JALR type
        
        ALUsrc_A =      1;
        ALUsrc_B =  2'b10;
        end
        else if(opcode == `LW) begin // LW type
        
        ir_write = 0;
        ALUsrc_A =      1;
        ALUsrc_B =  2'b10;
        
        end
        else if(opcode == `SW)  begin//  SW type
        
        ALUsrc_A =      1;
        ALUsrc_B =  2'b10;

        end
        else if (opcode == `BEQ) begin
            
            ALUsrc_A =      0;
            ALUsrc_B =  2'b10;
            pc_write = 0;
        end
        
    end
    else if(cur_state == `MEM) begin //MEM
      //$display("MEMMEMMEMMEMMEMMEMMEMMEMMEMMEMMEMMEMMEMMEMMEM");
        if(opcode == `LW) begin // LW type
        
        mem_read =      1;
        lorD =          1;
        mem_to_reg =    1;
        
        end
        else if(opcode == `SW) begin // SW type
    
        pc_write =      1;
        lorD = 1;
        mem_write =     1;

        pc_source =     0;
     
        ALUsrc_A =      0;
        ALUsrc_B =  2'b01;
        aluop =     2'b00;
        end
    end 
    else if(cur_state == `WB) begin
        //$display("WBWBWBWBWBWBWBWBWBWBWBWBWBWBWB");
        case (opcode) 
        7'b1100011 : aluop = 2'b01; // sb-type
        default : aluop = 2'b00;
        endcase
        if(opcode == `ADD) begin // R type
       
        pc_write =      1;
       
        
     
        pc_source =     0;
        write_enable =  1;
        ALUsrc_A =      0;
        ALUsrc_B =  2'b01;
        end
        else if(opcode == `ADDI) begin//I type
        pc_write =      1;
       
        mem_to_reg =    0;
     
        pc_source =     0;
        write_enable =  1;
        ALUsrc_A =      0;
        ALUsrc_B =  2'b01;

        end
        if(opcode == `JAL) begin // JAL type
      
        pc_write =      1;
        
        mem_to_reg =    0;
       
        pc_source =     0;
        write_enable =   1;
        ALUsrc_A =      0;
        ALUsrc_B =  2'b10;
        end
        else if(opcode == `JALR) begin // JALR type
     
        pc_write =      1;
        mem_to_reg =    0;
        pc_source =     0;
        write_enable =     1;
    
        end
        else if(opcode == `LW) begin // LW type
   
        pc_write =      1;       
        
        
        pc_source =     0;
        write_enable =  1;
        ALUsrc_A =      0;
        ALUsrc_B =  2'b01;
        end
        else if (opcode == `BEQ) begin
            pc_write_cond = 1;
            pc_write = 0;
            pc_source =     1;
            ALUsrc_A = 1;
            ALUsrc_B = 2'b00;
        end
    end

end



endmodule