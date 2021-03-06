module RegisterFile(input	reset,
                    input clk,
                    input [4:0] rs1,          // source register 1
                    input [4:0] rs2,          // source register 2
                    input [4:0] rd,           // destination register
                    input [31:0] rd_din,      // input data for rd
                    input write_enable,       // RegWrite signal
                    output [31:0] rs1_dout,   // output of rs 1
                    output [31:0] rs2_dout);  // output of rs 2
  integer i;
  // Register file
  reg [31:0] rf[0:31];

  // Asynchronously read register file
  assign rs1_dout = rf[rs1];
  assign rs2_dout = rf[rs2];

  // always @(*) begin
  //   $display("rs1: %d, rs2 : %d, rd: %d, rs1_dout : %x, rs2_dout : %x",rs1, rs2, rd, rs1_dout, rs2_dout);
  // end



  always @(posedge clk) begin
    // Initialize register file (do not touch)
    if (reset) begin
      for (i = 0; i < 32; i = i + 1)
        rf[i] <= 32'b0;
      rf[2] <= 32'h2ffc; // stack pointer
    end

    // Synchronously write data to the register
    else begin
      if (write_enable && rd != 0) begin
        rf[rd] <= rd_din;
      //$display("register write (주소)%d <= %x", rd, rd_din);
      end
    end
  end
endmodule
