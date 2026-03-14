// Definiujesz pakiet. Później da się go zaimportować. Np. w innym pliku piszesz:
// import cpu_defs::* // importujesz wszystko z pakietu cpu_defs
// memory_bus_t memory_bus; // możesz wykorzystać definicje z tego pakietu
package cpu_defs;

parameter int BITS_DATA = 8;
parameter int BITS_ADDR = 16;

// Definiujesz typ data_word_t (TYPY KOŃCZYMY _T JAKO ZWYCZAJ)
// data_word_t == logic [BITS_DATA-1:0] czyli (BITS_DATA == 8) bitów
// nie jest określone jeszcze czy to `reg`, czy `wire` - w SV
// to rozróżnienie jest trochę inne.
typedef logic [BITS_DATA-1:0] data_word_t;
typedef logic [BITS_ADDR-1:0] addr_word_t;

// Definiujesz struct'a jak w C. Atrybut `packed` zapewnia,
// że da się go później zsyntetyzować. Zawsze go używamy.
// Przykład wykorzystania:
// ```sv
// memory_bus_t memory_bus; // deklaracja zmiennej
// moj_modul asdf (.data_bus(memory_bus.data_bus)); // użycie pola struktury
// ```
typedef struct packed {
    data_word_t data_bus;
    addr_word_t addr_bus;
} memory_bus_t;

endpackage : cpu_defs
