MCU  := avrxmega2
SRCS := $(wildcard *.asm)
HEXS := $(SRCS:.asm=.mem)

.PHONY: all clean

all: $(HEXS)

%.o: %.asm
	avr-as --no-pad-sections -mmcu=$(MCU) -o $@ $<

%.elf: %.o
	avr-ld --no-relax -o $@ $< -m$(MCU)

%.bin: %.elf
	avr-objcopy -O binary $< $@
%.mem: %.bin
	xxd -p $< | fold -w4 > $@

clean:
	rm -f *.o *.elf *.hex *.bin *.mem
