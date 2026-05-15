    `timescale 1ns / 1ps
    //////////////////////////////////////////////////////////////////////////////////
    // Company: 
    // Engineer: 
    // 
    // Create Date: 13.05.2026 18:51:38
    // Design Name: 
    // Module Name: ALU
    // Project Name: 
    // Target Devices: 
    // Tool Versions: 
    // Description: 
    // 
    // Dependencies: 
    // 
    // Revision:
    // Revision 0.01 - File Created
    // Additional Comments:
    // 
    //////////////////////////////////////////////////////////////////////////////////
    
    import cpu_defs::*;
    //Data word A i B to Rd i Rr lub K
    module ALU(
        input opcode_e opcode,
        input data_word_t A,
        input data_word_t B,
        input flags_t flags,
        output logic [7:0] result_alu,
        output  flags_t flagsout,
        output data_word_t multiply_high //Holds MSB durign multiply operation
        );
        always_comb begin
            result_alu = '0;
            flagsout = flags;
            multiply_high = '0;
            case (opcode)
                OP_ADD: begin
                        {flagsout.C, result_alu} = A + B;
                        flagsout.H = (A[3] & B[3]) | (B[3] & !result_alu[3]) | (A[3] & !result_alu[3]);
                        flagsout.V = (A[7] & B[7] & !result_alu[7]) | (!A[7] & !B[7] & result_alu[7]);
                        flagsout.N = result_alu[7];
                        flagsout.S = result_alu[7] ^ ((A[7] & B[7] & !result_alu[7]) | (!A[7] & !B[7] & result_alu[7]));
                        flagsout.Z = (result_alu == 0);
                    end
                    OP_ADC: begin
                        {flagsout.C, result_alu} = A + B + flags.C;
                        flagsout.H = (A[3] & B[3]) | (B[3] & !result_alu[3]) | (A[3] & !result_alu[3]);
                        flagsout.V = (A[7] & B[7] & !result_alu[7]) | (!A[7] & !B[7] & result_alu[7]);
                        flagsout.N = result_alu[7];
                        flagsout.S = result_alu[7] ^ ((A[7] & B[7] & !result_alu[7]) | (!A[7] & !B[7] & result_alu[7]));
                        flagsout.Z = (result_alu == 0) & flags.Z;
                    end
                    OP_SUB: begin
                        result_alu = A - B;
                        flagsout.C = B > A;
                        flagsout.H = (!A[3] & B[3]) | (B[3] & result_alu[3]) | (result_alu[3] & !A[3]);
                        flagsout.V = (A[7] & !B[7] &!result_alu[7]) | (!A[7] & B[7] & result_alu[7]);
                        flagsout.N = result_alu[7];
                        flagsout.S = result_alu[7] ^ ((A[7] & !B[7] &!result_alu[7]) | (!A[7] & B[7] & result_alu[7]));
                        flagsout.Z = (result_alu == 0);
                     end
                     OP_SBC: begin
                        result_alu = A - B - flags.C;
                        flagsout.C = (!A[7] & B[7]) | (B[7] & result_alu[7]) | (result_alu[7] & !A[7]);
                        flagsout.H = (!A[3] & B[3]) | (B[3] & result_alu[3]) | (result_alu[3] & !A[3]);
                        flagsout.V = (A[7] & !B[7] & !result_alu[7]) | (!A[7] & B[7] & result_alu[7]);
                        flagsout.N = result_alu[7];
                        flagsout.S = result_alu[7] ^((A[7] & !B[7] & !result_alu[7]) | (!A[7] & B[7] & result_alu[7]));
                        flagsout.Z = (result_alu == 0) & flags.Z;
                     end
                     OP_AND: begin
                        result_alu = A & B;
                        flagsout.V = 0;
                        flagsout.N = result_alu[7];
                        flagsout.S = 0 ^ result_alu[7];
                        flagsout.Z = (result_alu == 0);
                     end
                     OP_ANDI: begin
                        result_alu = A & B;
                        flagsout.V = 0;
                        flagsout.N = result_alu[7];
                        flagsout.S = 0 ^ result_alu[7];
                        flagsout.Z = (result_alu == 0);
                     end
                     OP_OR: begin
                        result_alu = A | B;
                        flagsout.V = 0;
                        flagsout.N = result_alu[7];
                        flagsout.Z = (result_alu == 0);
                        flagsout.S = 0 ^ result_alu[7];
                     end
                     OP_ORI: begin
                        result_alu = A | B;
                        flagsout.V = 0;
                        flagsout.N = result_alu[7];
                        flagsout.Z = (result_alu == 0);
                        flagsout.S = 0 ^ result_alu[7];
                     end
                     OP_EOR: begin
                        result_alu = A ^ B;
                        flagsout.V = 0;
                        flagsout.N = result_alu[7];
                        flagsout.Z = (result_alu == 0);
                        flagsout.S = 0 ^ result_alu[7];
                     end
                     OP_INC: begin
                        result_alu = A + 1;
                        flagsout.V = (result_alu == 128);
                        flagsout.N = result_alu[7];
                        flagsout.S = (result_alu[7]) ^ (result_alu == 128);
                        flagsout.Z = (result_alu == 0);
                     end
                     OP_DEC: begin
                        result_alu = A - 1;
                        flagsout.V = (result_alu == 127);
                        flagsout.N = result_alu[7];
                        flagsout.S = (result_alu[7]) ^ (result_alu == 127);
                        flagsout.Z = (result_alu == 0);
                     end
                     OP_TST: begin
                        result_alu = A & A;
                        flagsout.V = 0;
                        flagsout.N = A[7];
                        flagsout.S = 0 ^ A[7];
                        flagsout.Z = (A == 0);
                     end
                     OP_CLR: begin
                        flagsout.S = 0;
                        flagsout.V = 0;
                        flagsout.N = 0;
                        flagsout.Z = 1;
                        result_alu = A ^ A;
                     end
                     OP_MUL: begin
                        {multiply_high, result_alu} = A * B;
                        flagsout.C = multiply_high[7];
                        flagsout.Z = (multiply_high == 0 & result_alu == 0);
                     end
                     OP_MULS: begin
                        {multiply_high, result_alu} = $signed(A) * $signed(B);
                        flagsout.C = multiply_high[7];
                        flagsout.Z = (multiply_high == 0 & result_alu == 0);
                     end
                     default: begin
                     end
            endcase 
        end
    
    endmodule
