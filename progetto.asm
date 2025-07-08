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


    # ciclo di lettura dell'area di memoria 'TEMPERATURE'    
    leggi_temperature:
        move     	$t0, $zero              # $t0 contatore 
        move        $t1, $s2                # copia temporanea di $s2
        ciclo_di_lettura:
            bge         $t0, 16, leggi_temperature              # controllo se ho letto tutto lo spazio di memoria
                                                                # 16 = 64Byte / 4Byte 
                                                                # quando arrivo al limite massimo, rincomincio da 0
            # $t2 -> senosre (1 word = (2Byte + 2Byte)) 
            # $t3 -> numero del sensore (parte sx della word, 2Byte)
            # $t4 -> valore del sensore (parte dx della word, 2Byte)

            lw          $t2, 0($t1)         # carico in $t2 il valore della word corrente
            
            # lettura dei dati
            srl         $t3, $t2, 16        # ottengo l'id del sensore (16 bit a sinistra)
            andi        $t4, $t2, 0xFFF     # ottengo il valore del sensore (16 bit a destra)

            # faccio i controlli

            # aggiornamento del contatore e calcolo dell'indirizzo successivo da leggere
            addi        $t0, 1              # incremento il contatore di 1
            addi        $t1, $t1, 4         # vado alla prossima word in memoria
            j           ciclo_di_lettura    # ritorno al ciclo di lettura




# -------------- AGGIORNAMENTO CONTATORI --------------

# aggiornamento del contatore di rest
agg_cont_reset:
    lw      $t9, 0($s4)             # carico nel registro $t9 il valore di $s4
    addi    $t9, $t9, 1             # incremento il contatore di 1
    sw      $t9, 0($s4)             # aggiorno $s4 con il nuovo valore
    jr      $ra                     # ritorno al chiamante

reset_cont_reset:
    lw      $t9, 0($s4)             # carico nel registro $t9 il valore di $s4
    move    $t9, $zero              # azzero
    sw      $t9, 0($s4)                # aggiorno $s4 con il nuovo valore
    jr      $ra                     # ritorno al chiamante

agg_cont_allarm:
    lw      $t9, 0($s5)             # carico nel registro $t9 il valore di $s5
    addi    $t9, $t9, 1             # incremento il contatore di 1
    sw      $t9, 0($s5)             # aggiorno $s5 con il nuovo valore
    jr      $ra                     # ritorno al chiamante

reset_cont_allarm:
    lw      $t9, 0($s5)             # carico nel registro $t9 il valore di $s5
    move    $t9, $zero              # azzero
    sw      $t9, 0($s5)             # aggiorno $s5 con il nuovo valore
    jr      $ra                     # ritorno al chiamante

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

# disattivazione della sirena
disattiva_sirena:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del primo bit di COMMAND
    andi    $t9, $t9, 0xFE          # deasserisco il bit con la maschera 0XFE
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritorno al chiamante

# attiva impianto ad acqua
attiva_acqua:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del secondo bit di COMMAND
    ori     $t9, $t9, 0x02          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritorno al chiamante

# disattiva impianto ad acqua
disattiva_acqua:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del secondo bit di COMMAND
    andi    $t9, $t9, 0xFD          # deasserisco il bit con la maschera 0xFD
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritorno al chiamante

# chiama VVFF
chiama_vvff:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del terzo bit di COMMADN
    ori     $t9, $t9, 0x04          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritoro al chiamante

# disattiva chiamata VVFF
end_chiama_vvff:
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del terzo bit di COMMADN
    andi    $t9, $t9, 0xFB          # deasserisco il bit con la maschera 0xFB
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    jr      $ra                     # ritoro al chiamante