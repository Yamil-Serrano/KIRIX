// ----------------------------- 16-bit Register File -----------------------------

module reg_file(
    input         clk,
    input         reg_write,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,
    input  [15:0] write_data,
    output [15:0] read_data1,
    output [15:0] read_data2
);

    // 32 registers 16 bits each
    reg [15:0] registers [0:31];

    // --- Asincronic read ---
    assign read_data1 = (rs1 == 5'd0) ? 16'h0000 : registers[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 16'h0000 : registers[rs2];
    // --- sincronic write ---
    always @(posedge clk) begin
        if (reg_write && rd != 5'd0) // The register 0 is hardwired to 0
            registers[rd] <= write_data;
    end

endmodule

// ----------------------------- 16-bit ALU -----------------------------

module alu_16bit_simple(
    input  [15:0] A,
    input  [15:0] B,
    input  [3:0]  OP,
    output reg [15:0] Result,
    output Zero,
    output Carry,
    output Borrow,
    output Equal,
    output Overflow
);

// Shift amount for shift operations
wire [3:0] shift_amount = B[3:0]; // for shift operation we use 4 bits only from input B
                                        // because if the number is more than 5 bits then 
                                        // the shift result will be 0. The assembler must
                                        // ensure to tell the programmer to put number of 
                                        // shifts in the lower 4 bits of B.

// Operations
wire [15:0] sum_result  =   A + B;
wire [15:0] sub_result  =   A - B;
wire [15:0] and_result  =   A & B;
wire [15:0] nand_result = ~(A & B);
wire [15:0] or_result   =   A | B;
wire [15:0] nor_result  = ~(A | B);
wire [15:0] xor_result  =   A ^ B;
wire [15:0] shift_left  =  A << shift_amount;
wire [15:0] shift_right =  A >> shift_amount;

// for roll i dont use 16 bits because; suppose we want a rol by 20, if we do 16-20 we get -4, verilog 
// dont allow shift with negative numbers, but if we do 16-4 we get 12, and the result is the same because
// of the nature of the roll operation. The assembler must ensure to tell the programmer to put number of 
// shifts in the lower 4 bits of B.
wire [15:0] roll_right_result = (A >> shift_amount) | (A << (16 - shift_amount));
wire [15:0] roll_left_result  = (A << shift_amount) | (A >> (16 - shift_amount));

wire [15:0] neg_result = ~A + 1'b1;        // NEG: change sign (two's complement)
wire [15:0] inc_result = A + 1'b1;
wire [15:0] dec_result = A - 1'b1;
wire [15:0] abs_result = (A[15]==1) ? (~A + 1'b1) : A;


// Operation selector
always @(*) begin
    case (OP)
        4'b0000: Result = sum_result;  // ADD
        4'b0001: Result = sub_result;  // SUB
        4'b0010: Result = and_result;  // AND
        4'b0011: Result = nand_result; // NAND
        4'b0100: Result = or_result;   // OR
        4'b0101: Result = nor_result;  // NOR
        4'b0110: Result = xor_result;  // XOR
        4'b0111: Result = shift_left;  // Shift Left
        4'b1000: Result = shift_right; // Shift Right
        4'b1001: Result = roll_left_result;  // Rotate Left
        4'b1010: Result = roll_right_result; // Rotate Right
        4'b1011: Result = sub_result;  // CMP (same as SUB but we only care about flags) dont store the result in the register file
        4'b1100: Result = neg_result;  // NEG
        4'b1101: Result = inc_result;  // INC
        4'b1110: Result = dec_result;  // DEC
        4'b1111: Result = abs_result;  // ABS
        default: Result = 16'b0;
    endcase
end

// Flags simples
assign Zero  = (Result == 0);
assign Equal = (A == B);
assign Carry = sum_result[16];
assign Borrow = (A < B); // Borrow occurs if A is less than B in subtraction
assign Overflow = (A[15]==0 && B[15]==0 && Result[15]==1) ||  // (+) + (+) = (-)
                  (A[15]==1 && B[15]==1 && Result[15]==0);    // (-) + (-) = (+)


endmodule

