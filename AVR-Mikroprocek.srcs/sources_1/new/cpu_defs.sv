// Definiujesz pakiet. Później da się go zaimportować. Np. w innym pliku piszesz:
// import cpu_defs::* // importujesz wszystko z pakietu cpu_defs
// memory_bus_t memory_bus; // możesz wykorzystać definicje z tego pakietu
package cpu_defs;

parameter int BITS_DATA = 8;
parameter int BITS_ADDR = 16;
parameter int BITS_INST = 16;

// Definiujesz typ data_word_t (TYPY KOŃCZYMY _T JAKO ZWYCZAJ)
// data_word_t == logic [BITS_DATA-1:0] czyli (BITS_DATA == 8) bitów
// nie jest określone jeszcze czy to `reg`, czy `wire` - w SV
// to rozróżnienie jest trochę inne.
typedef logic [BITS_DATA-1:0] data_word_t;
typedef logic [BITS_ADDR-1:0] addr_word_t;
typedef logic [BITS_INST-1:0] inst_word_t;
typedef logic [4:0] reg_addr_t;

// two operands rd, rr, np. wykorzystana w ADD
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

typedef union packed {
    inst_word_t raw;
    inst_rr_rd_t rr_rd;
    inst_imm_t imm;
} inst_t;


// TODO: dodaj S_WRITEBACK wykorzystana np. w instrukcjach dot. pamięci RAM
typedef enum logic [1:0] {
    S_FETCH,
    S_EXECUTE,
    S_MEMOP
} cpu_state_e;

// Wewnętrzna reprezentacja poleceń. Nie ma znaczenia ile te wartości wynoszą. 
typedef enum logic [6:0] {
    OP_LDI,
    OP_LDS,
    OP_STS,
    OP_ADD,
    OP_UNKNOWN = 7'bxxxxxxx
} opcode_e;

endpackage : cpu_defs

