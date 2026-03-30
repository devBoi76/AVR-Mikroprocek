# Podział Pracy

- [x] Instrukcje ALU (B. Margas)
- [ ] wyekstrachować ALU do modułu (B. Margas)
- [x] Podstawowy Instruction Decode (J. Mrzygłód)
- [x] Szkielet (J. Mrzygłód)
- [x] Program Memory (P. Pasieka)
- [x] ładowanie po UART (P. Pasieka)
- [x] SRAM i Stos `STS`, `LDS`, `PUSH`, `POP` (J. Mrzygłód)
- [x] `IN`, `OUT`, `MOV` (P. Pasieka)

# Kroki do syntezy

Nasza implementacja jest asyntezowalana. Np. SRAM jest zaimplementowane jako 1024 indywidualne rejestry i niewiadomo ile multiplekserów (zobaczcie elaborated schematic)

Poniżej jest lista kroków, które przybliżą nas do realnego CPU:

- [ ] Synchroniczny SRAM - obecnie po prostu indeksujemy `sram[pc]` - to nie jest wskazane i powoduje, że cały SRAM musi być jako indywidualne rejestry
  * [ ] Wyciągnąć SRAM do osobnego moduły z dobrze zdefiniowanym interfejsem (CPU powinno widzieć je tak samo jak widzi obecnie PROGRAM MEMORY)
  * [ ] "Happy-path" dla rejestrów - pozbyć się `assign sram[31:0] = r[31:0];` i traktować rejestry w osobnej ścierzce (powód jak wyżej)
  * [ ] Pozbyć się `r[Rd] <= sram[IO_BASE + A];` - powód jak wyżej
- [ ] Wyekstrachować ALU do modułu - pozwoli to na lepsze ustrukturyzowanie logiki podczas implementacji

Więcej wyjdzie w praniu

# Instrukcje do zaimplementowania

## Arithmetic/Logic
- [x] `ADD`
- [x] `ADC`
- [x] `SUB`
- [x] `SBC`
- [x] `AND`
- [x] `ANDI`
- [x] `OR`
- [x] `ORI`
- [x] `EOR`
- [x] `INC`
- [x] `DEC`
- [x] `TST`
- [x] `CLR`
- [x] `MUL`
- [x] `MULS`

## Control Flow
- [x] `RJMP`
- [x] `JMP`
- [ ] `RCALL`
- [x] `CALL`
- [x] `RET`
- [ ] `CP`
- [ ] `CPI`
- [x] `BREQ`
- [x] `BRNE`

## Data Transfer
- [x] `LDI`
- [x] `MOV`
- [x] `LDS`
- [ ] `LD` (niektóre wersje)
- [x] `STS`
- [ ] `ST` (niektóre wersje)
- [x] `IN`
- [x] `OUT`
- [x] `PUSH`
- [x] `POP`
- [ ] `XCH`

## Bit and Bit-Test Instructions
- [ ] `LSL`
- [ ] `LSR`
- [ ] `SWAP`
- [ ] Instrukcje ustawiające/czyszczące Status Register (clc, cln, itd.)

## MCU Control Instructions
- [ ] NOP
