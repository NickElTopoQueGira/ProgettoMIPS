.data
# 'spazi' di memoria 
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

RECORD:         .space 32   # definisco lo spazio di 'RECIRD'
                            # ogni sensore e' rappresentato solo dal suo id 
                            # il quale pesa 2 Byte
                            # e quindi 2Byte * 16sensori = 32Byte.
                            # Lo spazio NON viene inizializzato

# contatori
cont_reset:     .word 0     # contatore per il reset
cont_allarm:    .word 0     # contatore per la sirena
cont_sensor:    .word 0     # contatore sensori attivi

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
    la      $s4, cont_reset         # carico l'indirizzo del contatote del reset nel registro $s4
    la      $s5, cont_allarm        # carico l'indirizzo del contatore del rest dell'allarme nel registro $s5 
    la      $s6, cont_sensor        # carico l'indirizzo del contatore dei sensori attivi

    # reset
    jal     azzera                  # aggiorno tutti i contatori e command

    # ciclo di lettura dell'area di memoria 'TEMPERATURE'    
    leggi_temperature:
        move     	$t0, $zero              # $t0 contatore 
        move        $t1, $s2                # copia temporanea di $s2
        ciclo_di_lettura:
            bge         $t0, 16, main               # controllo se ho letto tutto lo spazio di memoria
                                                    # 16 = 64Byte / 4Byte 
                                                    # quando arrivo al limite massimo, rincomincio da 0
            
            # $t2 -> senosre (1 word = (2Byte + 2Byte)) 
            # $t3 -> numero del sensore (parte sx della word, 2Byte)
            # $t4 -> valore del sensore (parte dx della word, 2Byte)

            lw          $t2, 0($t1)                 # carico in $t2 il valore della word corrente
            
            # faccio i controlli

            # controllo se esistono le condizioni x l'attivazione della sirena 
            srl     $a0, $t2, 16                    # argomento 0: id del sensore corrente
            jal     attiva_sirena                   # verifico se ci sono le condizioni necessarie per attivare
                                                    # la sirena. NON E' necessario che la temperatura sia superiore 
                                                    # ai 40 gradi.

            # se la temperatura e' minore di 40gradi
            andi    $t3, $t2, 0xFFFF
            ble     $t3, 0x28, aggiorna_successivo  # se la temperatura e' <= 40 gradi
                                                    # vado al successivo
            # altrimenti:
            
            # prima di eseguire il salto, mi salvo sullo stack
            # i valori dei registri $t0, $t1
            addi    $sp, $sp, -8                    # sposto indietro l'indirizzo dello stack pointer di 8 Byte 
            sw      $t0, 4($sp)                     # salvo nello stack il valore di t0 nella seconda word
            sw      $t1, 0($sp)                     # salvo nello stack il valore di t1 nella prima word 

            # eseguo il salto se la temperatura e' maggiore di 40
            srl     $a0, $t2, 16                    # argomento 0: id del sensore
            andi    $a1, $t2, 0xFFFF                # argomento 1: valore del sensore
            move    $a2, $t0                        # argomento 2: valore del contatore
            jal     temp_maggiore                   # la temperatura e' > 40 gradi

            # recupero i valori salvati in precedenza nello stack (dopo il salto)
            lw          $t0, 4($sp)             # recupero il valode del contatore
            lw          $t1, 0($sp)             # recupero il valode di $t1 prima del salto
            addi        $sp, $sp, 8             # ripristino lo stack

            # aggiornamento del contatore e calcolo dell'indirizzo successivo da leggere
            aggiorna_successivo:
                addi        $t0, 1                  # incremento il contatore di 1
                addi        $t1, $t1, 4             # vado alla prossima word in memoria
                j           ciclo_di_lettura        # ritorno al ciclo di lettura
    
    # finre del programma
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
    blt     $t4, 0x3C, fin_temp_maggiore
    # la temperatura e' >= 60
    jal     agg_cont_sensor                 # aggiorno il contatore sensori attivi (temp >= 60)

    lw      $a0, 0($sp)                     # argomento 0: recupero il valore dell'id del sensore
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
    bne         $t2, 0x1, fin_con_call_VVFF # $t2 != 0x1 -> fine
    # il bit e' asserito
    bne         $t3, 0x1, fin_con_call_VVFF # $t3 != 0x1 -> fine
    # il bit e' asserito
    jal         chiama_vvff                 # eseguo chiamata
    
    fin_con_call_VVFF:
        lw          $ra, 4($sp)                 # recupero il valore di $ra
        addi        $sp, $sp, 8                 # resetto lo stack
        jr          $ra                         # ritorno al chiamante
        nop


# -------------- AZZERA --------------
azzera:
    # azzeramento dei contatori

    jal reset_cont_reset
    jal reset_cont_allarm
    jal reset_cont_sensor

    # azzeramento command
    jal disattiva_sirena
    jal disattiva_acqua
    jal end_chiama_vvff

    jr      $ra                     # ritonro al chiamante
    nop

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
    jr      $ra                     # ritorno al chiamante
    nop

# disattivazione della sirena
disattiva_sirena:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del primo bit di COMMAND
    andi    $t9, $t9, 0xFE          # deasserisco il bit con la maschera 0XFE
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

# attiva impianto ad acqua
attiva_acqua:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del secondo bit di COMMAND
    ori     $t9, $t9, 0x02          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

# disattiva impianto ad acqua
disattiva_acqua:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del secondo bit di COMMAND
    andi    $t9, $t9, 0xFD          # deasserisco il bit con la maschera 0xFD
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

# chiama VVFF
chiama_vvff:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del terzo bit di COMMADN
    ori     $t9, $t9, 0x04          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop

# disattiva chiamata VVFF
end_chiama_vvff:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del terzo bit di COMMADN
    andi    $t9, $t9, 0xFB          # deasserisco il bit con la maschera 0xFB
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritorno al chiamante
    nop