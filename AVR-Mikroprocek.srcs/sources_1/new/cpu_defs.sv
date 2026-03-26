// Definiujesz pakiet. Później da się go zaimportować. Np. w innym pliku piszesz:
// import cpu_defs::* // importujesz wszystko z pakietu cpu_defs
// memory_bus_t memory_bus; // możesz wykorzystać definicje z tego pakietu
package cpu_defs;

parameter int BITS_ADDR_IO = 6;
parameter int BITS_DATA = 8;
parameter int BITS_ADDR = 16;
parameter int BITS_INST = 16;

// Definiujesz typ data_word_t (TYPY KOŃCZYMY _T JAKO ZWYCZAJ)
// data_word_t == logic [BITS_DATA-1:0] czyli (BITS_DATA == 8) bitów
// nie jest określone jeszcze czy to `reg`, czy `wire` - w SV
// to rozróżnienie jest trochę inne.
typedef logic [BITS_ADDR_IO-1:0] addr_io_word_t;
typedef logic [BITS_DATA-1:0] data_word_t;
typedef logic [BITS_ADDR-1:0] addr_word_t;
typedef logic [BITS_INST-1:0] inst_word_t;
typedef logic [4:0] reg_addr_t;

// two operands rd, rr, np. wykorzystana w ADD, MOV
typedef struct packed {
    logic [5:0] op; 
    logic r_top_bit; 
    logic [4:0] d;
    logic [3:0] r_btm_bits;
} inst_rr_rd_t;

// immediate, np. wykorzystana w LDI
typedef struct packed {
    logic [3:0] op;
    logic [3:0] K_top_bits;
    logic [3:0] d; // registers r16-r31
    logic [3:0] K_btm_bits;
} inst_imm_t;

// IN, OUT
typedef struct packed {
    logic [3:0] op; // 1011
    logic in_out; // 0 = IN, 1 = OUT
    logic [1:0] A_top_bits; 
    logic [4:0] d; // registers r0-r31
    logic [3:0] A_btm_bits;
} inst_io_t;

// RJMP, RCALL
typedef struct packed {
    logic [3:0] op;
    logic signed [11:0] K;
} inst_rjmp_t;

// NOP 
typedef struct packed {
    logic [15:0] nop;
} inst_nop_t;

// CLEAR, SET FLAG BITS
typedef struct packed {
    logic [7:0] op; // 1001 0100
    logic sreg_value; // 1 = clear, 0 = set
    logic [2:0] sreg_bit;
    logic [3:0] constant; // 1000
} inst_BCLRorSET_t; //SREG BIT CLEAR OR SET
 
typedef union packed {
    inst_word_t raw;
    inst_rr_rd_t rr_rd;
    inst_imm_t imm;
    inst_io_t io;
    inst_rjmp_t rjmp;
    inst_nop_t nop;
    inst_BCLRorSET_t BCLRorSET;
} inst_t;


// TODO: dodaj S_WRITEBACK wykorzystana np. w instrukcjach dot. pamięci RAM
typedef enum logic [1:0] {
    S_FETCH,
    S_EXECUTE,
    S_MEMOP
} cpu_state_e;

// Wewnętrzna reprezentacja poleceń. Nie ma znaczenia ile te wartości wynoszą. 
typedef enum logic [20:0] {
    OP_LDI,
    OP_LDS,
    OP_STS,
    OP_PUSH,
    OP_POP,
    OP_ADD,
    OP_ADC,
    OP_SUB,
    OP_SBC,
    OP_AND,
    OP_ANDI,
    OP_OR,
    OP_ORI,
    OP_EOR,
    OP_INC,
    OP_DEC,
    OP_TST,
    OP_CLR,
    OP_MUL,
    OP_MULS,
    OP_IN,
    OP_OUT,
    OP_MOV,
    OP_RJMP,
    OP_NOP,  
    //FLAG CLEAR
    OP_BCLR,
//    OP_CLC,
//    OP_CLH,
//    OP_CLI,
//    OP_CLN,
//    OP_CLS,
//    OP_CLT,
//    OP_CLV,
//    OP_CLZ,
    //FLAG SET 
    OP_BSET,
//    OP_SEC,
//    OP_SEH,
//    OP_SEI,
//    OP_SEN,
//    OP_SES,
//    OP_SET,
//    OP_SEV,
//    OP_SEZ,
    OP_UNKNOWN = 7'bxxxxxxx
} opcode_e;

//Flagi
typedef struct packed{
    logic C; //Carry
    logic Z; //Zero
    logic N; //Negative
    logic V; //Overflow
    logic S; //For signed tests
    logic H; //Half carry
    logic T; //Transfer
    logic I; //Interrupt
} flags_t;

typedef enum logic [2:0] {
    SREG_C = 3'd0,
    SREG_Z = 3'd1,
    SREG_N = 3'd2,
    SREG_V = 3'd3,
    SREG_S = 3'd4,
    SREG_H = 3'd5,
    SREG_T = 3'd6,
    SREG_I = 3'd7
} sreg_bit_e;

endpackage : cpu_defs

