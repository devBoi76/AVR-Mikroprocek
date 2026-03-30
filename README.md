# Setup

## Ogólne

- Używamy Vivado 2025.2
- Używamy SystemVerilog (wybór przy tworzeniu nowych plików)
- Używamy gita
- Do każdej większej "funkcji" utwórz brancha w gicie (np. `git branch -c program-memory`) i na niej działaj
- Aktualizuj progress w pliku TODO.md

## Konfiguracja środowiska AVR na Windows

### 1. Instalacja WinAVR
Pobierz i zainstaluj WinAVR: https://winavr.sourceforge.net/download.html  
Instalator automatycznie doda narzędzia (`avr-as`, `avr-ld`, `avr-objcopy`, `xxd`) do PATH.

### 2. Instalacja Make
Pobierz i zainstaluj Make dla Windows: https://gnuwin32.sourceforge.net/packages/make.htm  
Dodaj `C:\Program Files (x86)\GnuWin32\bin` do PATH ręcznie:  
`Ustawienia → System → Informacje → Zaawansowane ustawienia systemu → Zmienne środowiskowe`

### 3. Budowanie projektu
```
cd asm
make all
```
Powinien pojawić się plik `basic.mem`.

## 4. Vivado
Otwórz `AVR-Mikroprocek.xpr` w Vivado.  
Plik `basic.mem` zostanie automatycznie znaleziony przez symulator.

# Przydatne linki

- https://verificationguide.com/systemverilog/systemverilog-tutorial/
- https://docs.amd.com/r/en-US/ug901-vivado-synthesis/SystemVerilog-Support
- https://www.fpga4student.com/2016/11/verilog-microcontroller-code.html
- https://eclipse.umbc.edu/robucci/cmpe311/Lectures/L02-AVR_Archetecture/
- https://eclipse.umbc.edu/robucci/cmpe311/
- https://ww1.microchip.com/downloads/en/devicedoc/AVR-Instruction-Set-Manual-DS40002198A.pdf
- https://en.wikipedia.org/wiki/Atmel_AVR_instruction_set#Instruction_encoding
- https://fruttenboel.nl/AVR/opcodes.html

