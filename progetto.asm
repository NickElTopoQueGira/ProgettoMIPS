.data
ALLARMS:        .word 0     # definisco lo spazio di 'ALLARMS'
                            # 1na word perche' ogni sensore ha 
                            # bisogno di 2 bit * 16 sensori 
                            # (16 numero max di sensori) = 
                            # 32 bit = 4 byte = 1 word.
                            # Inizializzo la word a 0

COMMAND:        .byte 0     # definisco lo spazio di 'COMMAND'
                            # lo definisco come byte perche' a me
                            # (da specifica) servono solo 3 bit.
                            # Inizializzo tutto il byte a 0

TEMPERATURE:    .space 64   # definisco lo spazio di 'TEMPERATURE'
                            # dal momento che per ogni sensore vengono
                            # utilizzati 2 Byte per il suo numero identificativo
                            # 2 Byte per il suo valore
                            # allora (2Byte + 2Byte) * 16 sensori = 64Byte
                            # Lo spazio NON vine inizializzato
                            # Questa scrittura e' la veriosne compatta di:
                            # .word 0,*15 zeri

RECORD:         .word 0     # definisco lo spazio di 'RECIRD'
                            # 1na word perche' ogni sensore e'
                            # rappresentato solo dal suo id 
                            # il quale pesa 2 Byte
                            # e quindi 2Byte * 16sensori = 32Byte. 
                            # Inizializzo la word a 0

cont_reset:     .word 0     # contatore per il reset
cont_allarm:    .word 0     # contatore per la sirena

.text
.globl main

main:
