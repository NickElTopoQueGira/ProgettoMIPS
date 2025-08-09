.data
# 'spazi' di memoria 
.align 2
ALLARMS:        .word   0x0000A7F1
# Sensore 0  : 01
                                    # Sensore 1  : 00
                                    # Sensore 2  : 11
                                    # Sensore 3  : 11
                                    # Sensore 4  : 11
                                    # Sensore 5  : 11
                                    # Sensore 6  : 11
                                    # Sensore 7  : 00
                                    # Sensore 8  : 10
                                    # Sensore 9  : 10
                                    # Sensore 10 : 10
                                    # Sensore 11 : 10
                                    # Sensore 12 : 00
                                    # Sensore 13 : 00
                                    # Sensore 14 : 00
                                    # Sensore 15 : 00

.align 0
COMMAND:        .byte 0     

.align 2
TEMPERATURE:    .word 0x00000046    # Sensore 0  : ID=0, temp=70°C (>60 e fumo)
                .word 0x00010041    # Sensore 1  : ID=1, temp=65°C (>60)
                .word 0x0002005A    # Sensore 2  : ID=2, temp=90°C (>60 e fumo)
                .word 0x00030032    # Sensore 3  : ID=3, temp=50°C (>40)
                .word 0x00040028    # Sensore 4  : ID=4, temp=40°C (soglia)
                .word 0x0005001E    # Sensore 5  : ID=5, temp=30°C (<40)
                .word 0x00060046    # Sensore 6  : ID=6, temp=70°C (>60)
                .word 0x00070000    # Sensore 7  : ID=7, temp=0°C (disabilitato)
                .word 0x0008005F    # Sensore 8  : ID=8, temp=95°C (>60)
                .word 0x0009003C    # Sensore 9  : ID=9, temp=60°C (soglia)
                .word 0x000A002D    # Sensore 10 : ID=10, temp=45°C (>40)
                .word 0x000B0037    # Sensore 11 : ID=11, temp=55°C (>40)
                .word 0x000C006E    # Sensore 12 : ID=12, temp=110°C (>60 e fumo)
                .word 0x000D0019    # Sensore 13 : ID=13, temp=25°C (<40)
                .word 0x000E004B    # Sensore 14 : ID=14, temp=75°C (>60)
                .word 0x000F0023    # Sensore 15 : ID=15, temp=35°C (<40)

.align 2
RECORD:         .space 32   

# contatori
.align 2
cont_reset:     .word 0     # contatore per il reset
cont_allarm:    .word 0     # contatore per la sirena
cont_sensor:    .word 0     # contatore sensori attivi

# messaggi
msg_sirena_attiva:       .asciiz "Sirena attiva\n"
msg_sirena_disattiva:    .asciiz "Sirena spenta\n"
msg_acqua_attiva:        .asciiz "Acqua attiva\n"
msg_acqua_disattiva:     .asciiz "Acqua spenta\n"
msg_chiamata_VVFF:       .asciiz "Chiamata VVFF\n"
msg_VVFF_non_chiamati:   .asciiz "VVFF non chiamati\n"
msg_temperatura:         .asciiz "Temperatura sensore:  "
msg_id:                  .asciiz "Id sensore: "
msg_valore:              .asciiz "Valore sensore: "
msg_command:             .asciiz "Command: "
msg_acapo:               .asciiz "\n"

.text
.globl main

main:
    # caricamento dei dati nei registri

    # 'spazi' di memoria
    la      $s0, ALLARMS            # carico l'indirizzo di ALLARMS nel registro $s0
    la      $s1, COMMAND            # carico l'indirizzo di COMMAND nel registro $s1
    la      $s2, TEMPERATURE        # carico l'indizirro di TEMPERATURE nel registro $s2
    la      $s3, RECORD             # carico l'indirizzo di RECORD nel registro $s3
    
    # contatori
    la      $s4, cont_reset         # carico l'indirizzo del contatore del reset nel registro $s4
    la      $s5, cont_allarm        # carico l'indirizzo del contatore del rest dell'allarme nel registro $s5 
    la      $s6, cont_sensor        # carico l'indirizzo del contatore dei sensori attivi
    
    # stack
    addi    $sp, $sp, -8                    # sposto indietro l'indirizzo dello stack pointer di 8 Byte 
    
    # NOTA: 
    # Ogni 5 secondi (ovvero ogni 5 ripetizioni di main_ciclo) se su command non vine registrato niente
    # il sistema si resetta

    # Ogni lettura viene intervallata da un secondo
    # Ad ogni lettura, se il 3 bit di command e' asserito (quello dei VVFF) viene deasserito

    main_ciclo:
        # aspetto un secondo
        jal     attendi_un_secondo

        # deasserisco il bit della chiamata dei VVFF
        # dopo un secondo, se e' a 0 rimane a 0
        jal     smetti_di_chiamare

        # verifica se sussistono le condizioni per il reset
        jal     verifica_condizioni_reset
        
        # incremento il contatore per il reset
        jal     agg_cont_reset

        
        # azzero i contatori utilizzati durante la lettura dei valori
        jal     reset_cont_allarm   
        jal     reset_cont_sensor


        # ciclo di lettura dell'area di memoria 'TEMPERATURE'    
        leggi_temperature:            
            move     	$t0, $zero                      # $t0 contatore 
            move        $t1, $s2                        # copia temporanea di $s2
            
            ciclo_di_lettura:
                bge         $t0, 16, main_ciclo         # controllo se ho letto tutto lo spazio di memoria
                                                        # 16 = 64Byte / 4Byte 
                                                        # quando arrivo al limite massimo, rincomincio da 0
                
                # mi salvo sullo stack i valori dei registri $t0, $t1
                sw      $t0, 4($sp)                     # salvo nello stack il valore di t0 nella seconda word
                sw      $t1, 0($sp)                     # salvo nello stack il valore di t1 nella prima word 
                
                # messaggio sulla console sullo status di COMMAND
                move        $a0, $t0
                jal         msg_command_status          # status di command sulla console
                
                # senosre (1 word = (2Byte + 2Byte)) 
                # numero del sensore (parte sx della word, 2Byte)
                # valore del sensore (parte dx della word, 2Byte)
                lw          $t1, 0($sp)                 # recupero il valore di $t1 dallo stack
                lw          $t0, 4($sp)                 # recupero il valore di $t0 dallo stack
                lw          $t2, 0($t1)                 # carico in $t2 il valore della word corrente (errore)
                
                # faccio i controlli

                # controllo se esistono le condizioni x l'attivazione della sirena 
                srl     $a0, $t2, 16                    # argomento 0: id del sensore corrente
                jal     cond_att_sirena                 # verifico se ci sono le condizioni necessarie per attivare
                                                        # la sirena. NON E' necessario che la temperatura sia superiore 
                                                        # ai 40 gradi.

                # se la temperatura e' minore di 40gradi
                andi    $t3, $t2, 0xFFFF
                ble     $t3, 0x28, aggiorna_successivo  # se la temperatura e' <= 40 gradi
                                                        # vado al successivo
                # altrimenti:

                # comunico sulla console il valore del sensore ed 
                # eseguo il salto se la temperatura e' maggiore di 40
                srl     $a0, $t2, 16                    # argomento 0: id del sensore
                andi    $a1, $t2, 0xFFFF                # argomento 1: valore del sensore
                jal     msg_temperatura_sensore         # messaggio sulla console
                move    $a2, $t0                        # argomento 2: valore del contatore
                jal     temp_maggiore                   # la temperatura e' > 40 gradi

                # aggiornamento del contatore e calcolo dell'indirizzo successivo da leggere
                aggiorna_successivo:
                    # recupero i valori salvati in precedenza nello stack (dopo il salto)
                    lw          $t0, 4($sp)                 # recupero il valode del contatore
                    lw          $t1, 0($sp)                 # recupero il valode di $t1 prima del salto
                    addi        $t0, $t0,1                  # incremento il contatore di 1
                    addi        $t1, $t1, 4             # vado alla prossima word in memoria
                    j           ciclo_di_lettura        # ritorno al ciclo di lettura

                # condizione x attivare lestrazione ad acqua
                jal        cond_att_acqua

    
    # fine del programma
    addi    $sp, $sp, 8     # ripristino lo stack
    li      $v0, 10         # codice di uscita dal programma
    syscall

# -------------- TEMPERATURA MAGGIORE DI 40 GRADI --------------
temp_maggiore:
    addi        $sp, $sp, -16               # sposto indietro l'idirizzo dello stack pointer 4 word 
    sw          $a0, 0($sp)                 # salvo: id del sensore
    sw          $a1, 4($sp)                 # salvo: valore del sensore
    sw          $a2, 8($sp)                 # salvo: valore del contatore
    sw          $ra, 12($sp)                # salvo: indirizzo di ritorno

    # Aggiungo il numero del sensore all'interno di RECORD
    sll     $t0, $a2, 1                     # calcolo dell'offset
                                            # $s2 * 2Byte
    add     $t1, $s3, $t0                   # indirizzo di dove mettere il valore
                                            # nell'area di memoria RECORD
    sh      $a0, 0($t1)                     # salvo l'id del sesnore

    # Se la temperatura e' minore di 60 gradi
    blt     $a1, 0x3C, fin_temp_maggiore
    # la temperatura e' >= 60
    jal     agg_cont_sensor                 # aggiorno il contatore sensori attivi (temp >= 60)

    # lw      $a0, 0($sp)                   # argomento 0: recupero il valore dell'id del sensore
    jal     cond_att_acqua                  # verifico se ci sono le condizioni per l'attivazione dell'estrazione ad acqua
    
    jal     cond_call_VVFF                  # verifico se ci sono le condizione per chiamare i VVFF

    fin_temp_maggiore:
        lw      $ra, 12($sp)                # recupero dove devo ritornare
        addi    $sp, $sp, 16                # resetto lo stack
        jr      $ra                         # ritorno al chiamante
    nop

# -------------- ATTIVAZIONE DELLA SIRENA --------------
cond_att_sirena:
    # se viene rilevato fumo in almeno un sensore, viene attivata la sirena
    addi    $sp, $sp, -8                    # sposto indietro l'indirizzo dello stack pointer di 8 byte
    sw      $a0, 0($sp)                     # salvo: id del sensore
    sw      $ra, 4($sp)                     # salvo: indirizzo di ritorno 

    lw      $t0, 0($sp)                     # recupero l'id del sensore (2 byte)
    lw      $t1, 0($s0)                     # carico nel registro $t1 il valore di ALLARMS

    # creazione della maschera
    sll     $t2, $t0, 1                     # $t2 = ($t1 * 2)
    addi    $t2, $t2, 1                     # $t2 + 1

    # isolo il bit di fumo
    and     $t3, $t1, $t2                   # $t3 = ALLARMS and maschera

    # controllo del valore
    beq     $t3, 0x0, non_attiva_sirena     # se il bit di fumo non e' asserito non eseguo niente
    # altrimenti
    jal attiva_sirena                       # attiva la sirena

    non_attiva_sirena:
        lw      $ra, 4($sp)                 # recupero il valore dell'indirizzo al quale tornare
        addi    $sp, $sp, 8                 # reset dell'indirizzo dello stack pointer 
        jr      $ra                         # ritorno al chiamante
    nop

# -------------- ATTIVAZIONE ACQUA --------------
cond_att_acqua:
    addi        $sp, $sp, -8                # sposto indietro l'indirizzo dello stack pointer di 8 byte
    sw          $a0, 0($sp)                 # salvo: id del sensore
    sw          $ra, 4($sp)                 # salvo: indirizzo di ritorno
    
    # verifica delle condizioni necessarie per attivare l'estrasione ad acqua. 
    # l'estrazione ad acqua viene attivata solo quando in almeno 2 sensori per almeno 5 sec 
    # viene rilevata una temperatura >= 60 gradi.

    lw      $t0, 0($s6)                     # leggo il valore aggiornato del contatore dei sensori attivi
    blt     $t0, 0x2, fin_cond_att_acqua    # se i sensori attivi sono < 2 non faccio niente
    # sesnori attivi >= 2
    lw      $t8, 0($s5)                     # leggo il valore del counter dei sencondi per attivare la sirena
    blt     $t8, 0x5, fin_cond_att_acqua    # se sono passati meno di 5 secondi non faccio niente
    # se sono passati 5 secondi
    jal     attiva_acqua                    # viene attivata l'estrazione ad acqua

    fin_cond_att_acqua:
        lw      $ra, 4($sp)                 # recupero il valore di $ra
        addi    $sp, $sp, 8                 # resetto lo stack
        jr      $ra                         # ritorno al chiamante
    nop

# -------------- CHIAMATA VVFF --------------
cond_call_VVFF:
    addi        $sp, $sp, -8
    sw          $a0, 0($sp)                 # salvo: id del sensore corrente
    sw          $ra, 4($sp)                 # salvo: registro $ra

    lw          $t0, 0($s0)                 # carico nel registro $t0 ALLARMS

    # la temperatura e' maggiore di 60 gradi per il valore in TEMPERATURE
    # controllo se anche il bit in ALLARMS della temperatura e' asserito

    # maschera per isolare il primo bit della coppia
    sll         $t1, $a0, 1                 # $t1 = ($a0 * 2) --> $a0 id del sensore

    # isolo bit della temperatura
    and         $t2, $t0, $t1               # $t2 = ALLARMS and maschera
                                            # $t2 contiene il valore del bit della temperatura

    # maschera per isolare il secondo bit della coppia
    addi        $t1, $t1, 1                 # $t1 = ($a0 * 2) + 1 --> aggiorno la maschera per il secondo bit

    # isolo bit del fumo
    and         $t3, $t0, $t1               # $t3 = ALLARMS and maschera
                                            # $t3 contiene il valore del bit di fumo

    # controllo dei bit
    # controllo del bit della temperatura
    bne         $t2, 0x1, fin_con_call_VVFF # $t2 != 0x1 -> fin
    # il bit e' asserito
    bne         $t3, 0x1, fin_con_call_VVFF # $t3 != 0x1 -> fin
    # il bit e' asserito

    # verifico se i pompieri sono gia' stati chiamati
    jal         is_vvff_call
    beq         $v0, 0x1, fin_con_call_VVFF # i VVFF sono gia' stati chiamati
    # chiamo i VVFF
    jal         chiama_vvff                 # eseguo chiamata
    
    fin_con_call_VVFF:
        lw          $ra, 4($sp)                 # recupero il valore di $ra
        addi        $sp, $sp, 8                 # resetto lo stack
        jr          $ra                         # ritorno al chiamante
        nop

smetti_di_chiamare:
    addi        $sp, $sp, -4                    # sposto indietro l'indirizzo dello stack pointer
    sw          $ra, 0($sp)                     # salvo il valore dell'indirizzo di ritorno

    jal         is_vvff_call                    # controllo se sono stati chiamati i VVFF
    bne         $v0, $zero, end_chiama_vvff     # $v0 != 0 -> smetti

    fin_smetti_di_chiamare:
        lw          $ra, 0($sp)                 # recupero il valore dell'indirizzo di ritorno
        addi        $sp, $sp, 4                 # resetto lo stack
        jr          $ra                         # ritorno al chiamante
        nop


is_vvff_call:
    # controllo se il terzo bit di COMMAND e' asserito
    lb          $t0, 0($s1)             # carico nel registro $t0 il valore di COMMAND
    
    andi        $t1, $t0, 0xFB          # maschera per isolare il bit
    srl         $v0, $t1, 2             # shift a dx 

    jr          $ra                     # ritorno al chiamante
    nop

# -------------- AZZERA --------------
verifica_condizioni_reset:
    # verifico se sono passati 5 secondi
    lw      $t0, 0($s4)                 # carico in $t0 il valore del contatore x il reset
    blt     $t0, 0x5, fin_verifica      # $t0 < 5 -> fine verifica
    # verifico se COMMAND e' tutto a zero
    lb      $t1, 0($s1)                 # carico COMMAND in $t1
    andi    $t1, $t1, 0xFF              # $t1 = COMMAND andi 0xFF
    beq     $t1, $zero, _reset          # se COMMAND e' a zero resetto 
    # si 'COMMAND' est different de zero, je passe a la fin de la 
    # verification parce qu'il y a encore un evenement en cours

    fin_verifica:
        jr      $ra                     # ritonro al chiamante
        nop

_reset:
    # faccio il reset dei contatori
    jal     reset_cont_reset
    jal     reset_cont_allarm
    jal     reset_cont_sensor
    jal     reset_record
    jr      $ra
    nop

# -------------- TEMPO DI ATTESA --------------
attendi_un_secondo:
    addi    $sp, $sp, -4            # sposto indietro lo stak pointer di 4
    sw      $ra, 0($sp)             # salvo: indirizzo al quale tornare

    move    $t0, $zero              # Inizializzo un contatore temporaneo

    # N di clicli da fare:
    # dal momento che addi e' un operazione I-Type impiega 4 operazioni
    # e blt impiega 3 operazioni, devo fare 100 milioni / (4+3) = 100000000 / 7
    li      $t1, 14285714          # 100 milioni / 7 = 1 secondo

    loop:
        addi    $t0, $t0, 1         # incremento il contatore di 1  (4 operazioni (R-Type))
        blt     $t0, $t1, loop      # se $t0 < $t1 -> loop          (3 operazioni)
        j       fine_attesa_un_sec  

    fine_attesa_un_sec:
        lw      $ra, 0($sp)         # ricarico il valore
        addi    $sp, $sp, 4         # rest dello stack
        jr      $ra                 # ritorno al chiamante
        nop

# -------------- AGGIORNAMENTO CONTATORI --------------
reset_record:
    lw      $t0, 0($s3)     # carico RECORD in $t0
    move    $t0, $zero      # azzero
    sw      $t0, 0($s3)     # salvo il nuovo valore
    jr      $ra             # ritorno al chiamante

# -------------- AGGIORNAMENTO CONTATORI --------------

# aggiornamento del contatore di rest
agg_cont_reset:
    lw      $t9, 0($s4)             # carico nel registro $t9 il valore di $s4
    addi    $t9, $t9, 1             # incremento il contatore di 1
    sw      $t9, 0($s4)             # aggiorno $s4 con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

reset_cont_reset:
    lw      $t9, 0($s4)             # carico nel registro $t9 il valore di $s4
    move    $t9, $zero              # azzero
    sw      $t9, 0($s4)             # aggiorno $s4 con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

# aggiornamento contatore per la sirena
agg_cont_allarm:
    lw      $t9, 0($s5)             # carico nel registro $t9 il valore di $s5
    addi    $t9, $t9, 1             # incremento il contatore di 1
    sw      $t9, 0($s5)             # aggiorno $s5 con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

reset_cont_allarm:
    lw      $t9, 0($s5)             # carico nel registro $t9 il valore di $s5
    move    $t9, $zero              # azzero
    sw      $t9, 0($s5)             # aggiorno $s5 con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

# aggiornamento contatore sensori attivi
agg_cont_sensor:
    lw      $t9, 0($s6)             # carico nel registro $t9 il valore di $s6
    addi    $t9, $t9, 1             # incremento il contatore di 1
    sw      $t9, 0($s6)             # aggiorno $s6 con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

reset_cont_sensor:
    lw      $t9, 0($s6)             # carico nel registro $t9 il valore di $s6
    move    $t9, $zero              # azzero
    sw      $t9, 0($s6)             # aggiorno $s6 con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

# -------------- COMMAND --------------

# funzionamento:
# se viene rilevato fumo, il primo bit viene asserito
# se viene rilevata una temperatura > 60 gradi (in almeno 2 sensori) vine asserito il secondo bit
# se viene rilevato fumo e la temperatura e' > 60 in un sensore, viene asserito il terzo bit
#          ori      andi
# bit 0 -> 0x01     0xFE
# bit 1 -> 0x02     0XFD
# bit 2 -> 0x04     0XFB

# attivazione della sirena
attiva_sirena:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del primo bit di COMMAND
    ori     $t9, $t9, 0x01          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_sirena_attiva
    syscall
    jr      $ra                     # ritorno al chiamante
    nop

# disattivazione della sirena
disattiva_sirena:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del primo bit di COMMAND
    andi    $t9, $t9, 0xFE          # deasserisco il bit con la maschera 0XFE
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_sirena_disattiva
    syscall    
    jr      $ra                     # ritorno al chiamante
    nop

# attiva impianto ad acqua
attiva_acqua:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del secondo bit di COMMAND
    ori     $t9, $t9, 0x02          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_acqua_attiva
    syscall
    jr      $ra                     # ritorno al chiamante
    nop

# disattiva impianto ad acqua
disattiva_acqua:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del secondo bit di COMMAND
    andi    $t9, $t9, 0xFD          # deasserisco il bit con la maschera 0xFD
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_acqua_disattiva
    syscall
    jr      $ra                     # ritorno al chiamante
    nop

# chiama VVFF
chiama_vvff:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del terzo bit di COMMADN
    ori     $t9, $t9, 0x04          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_chiamata_VVFF
    jr      $ra                     # ritorno al chiamante
    nop

# disattiva chiamata VVFF
end_chiama_vvff:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del terzo bit di COMMADN
    andi    $t9, $t9, 0xFB          # deasserisco il bit con la maschera 0xFB
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_VVFF_non_chiamati
    syscall
    jr      $ra                     # ritorno al chiamante
    nop
# -------------- MESSAGGIO TEMPERATURA SENSORE --------------
msg_temperatura_sensore:
    addi    $sp, $sp, -12
    sw      $a0, 0($sp)     # salvo: id del sensore
    sw      $a1, 4($sp)     # salvo: valore del sensore
    sw      $ra, 8($sp)     # salvo: valore dell'indirizzo di ritorno

    lw      $t0, 0($sp)     # recupero id del sensore
    lw      $t1, 4($sp)     # recupero valore del sensore

    # scritta: Temperatura sensore
    li      $v0, 4
    la      $a0, msg_temperatura
    syscall

    # scritta: Id
    li      $v0, 4
    la      $a0, msg_id
    syscall

    # id del sensore
    li      $v0, 1
    move    $a0, $t0
    syscall
    # scritta: Valore
    li      $v0, 4
    la      $a0, msg_valore
    syscall

    # valore del sensore
    li      $v0, 1
    lw      $t0, 4($sp)
    move    $a0, $t0
    syscall

    # scritta: \n
    li      $v0, 4
    la      $a0, msg_acapo
    syscall

    fin_msg_temperatura_sensore:
        lw      $ra, 8($sp)     # recupero il valore dell'indirizzo di ritorno
        addi    $sp, $sp, 12    # resetto lo stack (corretto da 8 a 12)
        jr      $ra             # ritorno al chiamante
        nop

# -------------- MESSAGGIO STATO COMMAND --------------
msg_command_status:
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    lb      $t0, 0($s1)             # carico COMMAND in $t0

    # stampo il contatore:
    move    $t2, $a0                # recupero l'argometno e lo metto in $t2
    li      $v0, 1
    move    $a0, $t2
    syscall

    # scritta: command
    li      $v0, 4
    la      $a0, msg_command
    syscall

    # verifico se il primo bit    (0)
    andi    $t1, $t0, 0x01
    beq     $t1, $zero, stampa_sirena_non_attiva
    # sirena attiva
    li      $v0, 4
    la      $a0, msg_sirena_attiva
    syscall

    j dopo_sirena
    
    stampa_sirena_non_attiva:
        li      $v0, 4
        la      $a0, msg_sirena_disattiva
        syscall

    dopo_sirena:
        # verifico se il secondo bit  (1)
        andi    $t1, $t0, 0x02
        beq     $t1, $zero, stampa_acqua_non_attiva
        # acqua attiva
        li      $v0, 4
        la      $a0, msg_acqua_attiva
        syscall
        j       dopo_acqua

    stampa_acqua_non_attiva:
        li      $v0, 4
        la      $a0, msg_acqua_disattiva
        syscall

    dopo_acqua:
        # verifico se il terzo bit    (2)
        andi   $t1, $t0, 0x04
        beq    $t1, $zero, stampa_pompieri_non_chiamati
        # pompieri chiamati
        li      $v0, 4
        la      $a0, msg_chiamata_VVFF
        syscall

    stampa_pompieri_non_chiamati:
        li      $v0, 4
        la      $a0, msg_VVFF_non_chiamati
        syscall

    fin_msg_command_status:
        lw      $ra, 0($sp)     # recupero l'indirizzo di ritorno
        addi    $sp, $sp, 4     # resetto lo stack
        jr      $ra             # ritorno al chiamante
        nop