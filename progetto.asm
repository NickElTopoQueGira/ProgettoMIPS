.data
# 'spazi' di memoria 
.align 2
ALLARMS:        .word   0x03AA1071
                                    # Sensore 0  : 01 (temp >60, no fumo)
                                    # Sensore 1  : 00 (normale)
                                    # Sensore 2  : 11 (temp >60 e fumo)
                                    # Sensore 3  : 01 (temp >60, no fumo)
                                    # Sensore 4  : 00 (normale)
                                    # Sensore 5  : 00 (normale)
                                    # Sensore 6  : 01 (temp >60, no fumo)
                                    # Sensore 7  : 00 (normale)
                                    # Sensore 8  : 10 (fumo, temp <=60)
                                    # Sensore 9  : 10 (fumo, temp <=60)
                                    # Sensore 10 : 10 (fumo, temp <=60)
                                    # Sensore 11 : 10 (fumo, temp <=60)
                                    # Sensore 12 : 11 (temp >60 e fumo)
                                    # Sensore 13 : 00 (normale)
                                    # Sensore 14 : 01 (temp >60, no fumo)
                                    # Sensore 15 : 00 (normale)

.align 2
TEMPERATURE:    .word 0x00000046    # Sensore 0  : ID=0, temp=70°C
                .word 0x0001001E    # Sensore 1  : ID=1, temp=30°C
                .word 0x0002005A    # Sensore 2  : ID=2, temp=90°C
                .word 0x00030050    # Sensore 3  : ID=3, temp=80°C
                .word 0x00040028    # Sensore 4  : ID=4, temp=40°C
                .word 0x0005001E    # Sensore 5  : ID=5, temp=30°C
                .word 0x00060046    # Sensore 6  : ID=6, temp=70°C
                .word 0x00070000    # Sensore 7  : ID=7, temp=0°C
                .word 0x00080032    # Sensore 8  : ID=8, temp=50°C
                .word 0x0009003C    # Sensore 9  : ID=9, temp=60°C
                .word 0x000A002D    # Sensore 10 : ID=10, temp=45°C
                .word 0x000B0037    # Sensore 11 : ID=11, temp=55°C
                .word 0x000C006E    # Sensore 12 : ID=12, temp=110°C
                .word 0x000D0019    # Sensore 13 : ID=13, temp=25°C
                .word 0x000E004B    # Sensore 14 : ID=14, temp=75°C
                .word 0x000F0023    # Sensore 15 : ID=15, temp=35°C

.align 2
RECORD:         .space 32   

# contatori
.align 2
cont_temp_over:	.word 0		# contatore che conta il numero di sensori che hanno una temperatura maggiore uguale a 60 gradi
cont_sec_pass: 	.word 0		# contatore che conta quanti secondi sono passati

.align 2
modalita_scelta: .word 0    # variabile che memorizza la modilità dei sensori (0=statici, 1=manuale)

.align 0
COMMAND:        .byte 0  

# messaggi
msg_sirena_attiva:       .asciiz " Sirena attiva\n"
msg_sirena_disattiva:    .asciiz " Sirena spenta\n"
msg_acqua_attiva:        .asciiz " Acqua attiva\n"
msg_acqua_disattiva:     .asciiz " Acqua spenta\n"
msg_chiamata_VVFF:       .asciiz " Chiamata ai VVFF in corso\n"
msg_VVFF_non_chiamati:   .asciiz " VVFF NON chiamati\n"
msg_VVFF_fine_chiamata:  .asciiz " Fine chiamata VVFF\n"
msg_temperatura:         .asciiz " Temperatura sensore:  "
msg_id:                  .asciiz " Id sensore: "
msg_valore:              .asciiz " Valore sensore: "
msg_si_fumo:             .asciiz " Fumo: SI "
msg_no_fumo:             .asciiz " Fumo: NO "
msg_command:             .asciiz " Command: \n"
msg_riepilogo_record:    .asciiz " Riepilogo RECORD: "
msg_sensori_salvati:     .asciiz " Sensori Salvati: \n"
msg_acapo:               .asciiz "\n"
msg_linea:               .asciiz "\n-----------------------------------\n"
ins_temp_init:           .asciiz "  > Temperatura: (°C): "
msg_err_temp_iniz:       .asciiz "  ! Valore non valido. Inserire un valore tra 0 e 200.\n"
ins_fumo_init:           .asciiz "  > Fumo (0=no, 1=si): "
msg_err_fumo_iniz:       .asciiz "  ! Valore non valido. Inserisci 0 o 1.\n"
msg_ok_temp:             .asciiz "  + Temperatura inserita correttamente.\n"
msg_ok_fumo:             .asciiz "  + Valore fumo inserito correttamente.\n"
msg_iniziale:            .asciiz " Sistema di gestione di un'allarme anti-incendio. \n"
msg_scelta_modalita:     .asciiz " Selezionare quali dati utilizzare: (0) dati precaricati; (1) dati inseriti manualmente -> "
msg_err_scelta:          .asciiz "  ! Scelta non valida. Inserire 0 o 1.\n"


.text
.globl main

# -------------- INIZIO: MAIN --------------
main:
    # caricamento dei dati nei registri
    # 'spazi' di memoria
    la      $s0, ALLARMS            # carico l'indirizzo di ALLARMS nel registro $s0
    la      $s1, COMMAND            # carico l'indirizzo di COMMAND nel registro $s1
    la      $s2, TEMPERATURE        # carico l'indizirro di TEMPERATURE nel registro $s2
#    la      $s3, RECORD             # carico l'indirizzo di RECORD nel registro $s3 ----> SPOSTATO NELLE SUB-RUTINE CHE LO UTILIZZANO
    
    # contatori
    la      $s4, cont_temp_over		# carico l'indirizzo del contatore dei sensori che hanno una temperatura
									# maggiore uguale di 60 gradi nel registro $s4
									
	la		$s5, cont_sec_pass 		# carico l'indirizzo del contatore dei secondi passati (cicli di lettura)
									# nel registro $s5
   
    li      $v0, 4                      # carico in $v0 il codice per la stampa di una stringa
    la      $a0, msg_iniziale            # carico in $a0 l'indirizzo del messaggio iniziale
    syscall                              # eseguo la stampa del messaggio iniziale

# --- SCELTA MODALITÀ CON LOOP E FORMATTAZIONE ---
scelta_modalita_loop:
    li      $v0, 4                       # carico in $v0 il codice per la stampa di una stringa
    la      $a0, msg_scelta_modalita      # carico in $a0 la domanda di scelta modalità
    syscall                               # stampo la domanda

    li      $v0, 5                       # carico in $v0 il codice per la lettura di un intero da tastiera
    syscall                               # eseguo la lettura
    move    $t0, $v0                      # salvo in $t0 il valore appena inserito dall'utente

    li      $v0, 4                       
    la      $a0, msg_linea
    syscall

    li      $v0, 4
    la      $a0, msg_acapo
    syscall

    beq     $t0, $zero, usa_statici       # se scelta=0 salto a usa_statici
    li      $t1, 1
    beq     $t0, $t1, scelta_manuale      # se scelta=1 salto a scelta_manuale

    li      $v0, 4
    la      $a0, msg_err_scelta
    syscall
    j       scelta_modalita_loop

scelta_manuale:
    li      $t2, 1                        # carico 1 = modalità manuale
    sw      $t2, modalita_scelta           # salvo la modalità scelta in memoria
    jal     init_sensori_manuale           # inizializzo sensori manualmente
    j       fine_scelta_iniz               # salto alla fine della scelta modalità

usa_statici:
    sw      $zero, modalita_scelta         # salvo 0 = modalità dati precaricati
    j       fine_scelta_iniz

fine_scelta_iniz:
    jal     reset_record


    # inizializzazione RECORD
    fine_scelta:
    jal     reset_record

    # stack
    addi    $sp, $sp, -16            # sposto indietro l'indirizzo dello stack 
    
    # NOTA: 
    # Ogni 5 secondi (ovvero ogni 5 ripetizioni di main_ciclo) se su command non vine registrato niente
    # il sistema si resetta

    # Ogni lettura viene intervallata da un secondo
    # Ad ogni lettura, se il 3 bit di command e' asserito (quello dei VVFF) viene deasserito

    main_ciclo:
        # comunico lo stato di RECORD
        jal     riepilogo_record

        # aspetto un secondo
        jal     attendi_un_secondo

        # deasserisco il bit della chiamata dei VVFF se asserito, altrimenti rimane uguale
        jal     smetti_di_chiamare

		# verifica se sussistono le condizioni per il reset
        jal     verifica_condizioni_reset
        
        # incremento del contatore cont_sec_pass
		jal 	inc_cont_sec_pass

        # ciclo di lettura dell'area di memoria 'TEMPERATURE'    
        leggi_temperature:            
            move     	$t0, $zero                      # $t0 contatore (indice) 
            move        $t1, $s2                        # copia temporanea di $s2
            
            ciclo_di_lettura:
                bge         $t0, 16, fine_lettura_ciclo         # controllo se ho letto tutto lo spazio di memoria
                                                        # 16 = 64Byte / 4Byte 
                                                        # quando arrivo al limite massimo, rincomincio da 0
                
                # ------------- salvataggio valori in stack -------------
				# salvo sullo stack i valori dei registri $t0, $t1
                sw      $t0, 0($sp)                     # salvo nello stack il valore dell'indice 
                sw      $t1, 4($sp)                     # salvo nello stack il valore del sensore
                
                # ------------- ID e Valore sensori -------------
				# senosre (1 word = (2Byte + 2Byte)) 
                # numero del sensore (parte sx della word, 2Byte)
                # valore del sensore (parte dx della word, 2Byte)
                lw      $t9, 0($t1)                     # carico in un registro temp il valore di $t1
				srl 	$t2, $t9, 16					# id del sensore
				andi 	$t3, $t9, 0xFFFF				# valore del sensore

                # ------------- salvataggio valori in stack -------------
                sw      $t2, 8($sp)                     # salvo nello stack il valore dell'id del sensore
                sw      $t3, 12($sp)                    # salvo nello stack il valore del valore del sensore

                # ------------- messaggio di stato sensore -------------
                move    $a0, $t2                        # argomento 0: id sensore
                move    $a1, $t3                        # argomento 1: valore sensore
                jal     msg_temperatura_sensore         # stampo i valori del sensore sulla console 

				# ------------- messaggio di stato di command -------------
                jal     msg_command_status              # status di command sulla console
				
                # ------------- messaggio: linea sulla console -------------
                jal stampa_solo_linea
                
                # ------------- recupero valori dallo stack -------------
				lw      $t2, 8($sp)                     # reimposto id sensore
                lw      $t3, 12($sp)                    # reimposto valore sensore
				
				# ------------- controllo att sirena -------------
                # controllo se esistono le condizioni x l'attivazione della sirena 
                move    $a0, $t2                   		# argomento 0: id del sensore corrente
                jal     cond_att_sirena                 # verifico se ci sono le condizioni necessarie per attivare
                                                        # la sirena. NON e' necessario che la temperatura sia superiore  ai 40 gradi
                                                        # basta solo la presenza di fumo su almeno un sensore

                # ------------- recupero valori dallo stack -------------
				lw      $t2, 8($sp)                     # reimposto id sensore
                lw      $t3, 12($sp)                    # reimposto valore sensore

				# ------------- controllo temperatura -------------
                # se la temperatura e' minore di 40gradi
                lw      $t3, 12($sp)                    # recupero il valore del sensore
                ble     $t3, 0x28, aggiorna_successivo  # se la temperatura e' <= 40 gradi vado al successivo
                # altrimenti:

                # eseguo il salto se la temperatura e' maggiore di 40
                move    $a0, $t2                    	# argomento 0: id del sensore
                move    $a1, $t3                		# argomento 1: valore del sensore
                jal     temp_maggiore_quaranta          # la temperatura e' > 40 gradi

				# ------------- progressione ciclo -------------
                # aggiornamento del contatore e calcolo dell'indirizzo successivo da leggere
                aggiorna_successivo:
                    # recupero i valori salvati in precedenza nello stack (dopo il salto)
                    lw          $t0, 0($sp)             # recupero il valode del contatore
                    lw          $t1, 4($sp)             # recupero il valode di $t1 prima del salto
                    addi        $t0, $t0,1              # incremento il contatore di 1
                    addi        $t1, $t1, 4             # vado alla prossima word in memoria
                    j           ciclo_di_lettura        # ritorno al ciclo di lettura

                # --- Controllo se reinserire i sensori manualmente a fine ciclo ---
fine_lettura_ciclo:
 # Controllo per reinserire i sensori manualmente 
lw      $t0, modalita_scelta              # carico la modalità scelta
beq     $t0, $zero, skip_reinserimento    # se 0 = statici, salto
# modalità manuale → chiedo reinserimento
jal     init_sensori_manuale               # richiamo routine inserimento manuale

skip_reinserimento:
j       main_ciclo                         # ritorno all'inizio del ciclo


    # fine del programma
    addi    $sp, $sp, 16     # ripristino lo stack
    li      $v0, 10         # codice di uscita dal programma
    syscall
# -------------- FINE: MAIN --------------

# -------------- INIZIO: TEMPERATURA MAGGIORE DI 40 GRADI --------------
temp_maggiore_quaranta:
    # $a0: id del sensore
    # $a1: valore del sensore
    addi    $sp, $sp, -12               # spazio per 3 word
    sw      $a0, 0($sp)                 # salvo: id del sensore
    sw      $a1, 4($sp)                 # salvo: valore del sensore
    sw      $ra, 8($sp)                 # salvo: valore di ritorno

    # salvataggio in RECORD
    lw      $a0, 0($sp)                 # recupero l'id del sensore
    jal     salva_record
    
    # Se la temperatura e' minore di 60 gradi
    blt     $a1, 0x3C, fin_temp_maggiore_quaranta
    
	# la temperatura e' >= 60
    jal     inc_cont_temp_over          # aggiorno il contatore sensori attivi (temp >= 60)

    lw      $a0, 0($sp)                 # argomento 0: recupero il valore dell'id del sensore
    jal     cond_att_acqua              # verifico se ci sono le condizioni per l'attivazione dell'estrazione ad acqua
    
    jal     cond_call_VVFF              # verifico se ci sono le condizione per chiamare i VVFF

    fin_temp_maggiore_quaranta:
        lw      $ra, 8($sp)             # recupero dove devo ritornare
        addi    $sp, $sp, 12            # resetto lo stack
        jr      $ra                     # ritorno al chiamante
    nop
# -------------- FINE: TEMPERATURA MAGGIORE DI 40 GRADI --------------


# -------------- INIZIO: COND ATT SIRENA --------------
cond_att_sirena:
    # se viene rilevato fumo in almeno un sensore, viene attivata la sirena
    addi    $sp, $sp, -8                    # sposto indietro l'indirizzo dello stack pointer di 8 byte
    sw      $a0, 0($sp)                     # salvo: id del sensore
    sw      $ra, 4($sp)                     # salvo: indirizzo di ritorno 

    lw      $t0, 0($s0)                     # recupero il valore di allarms

    # creazione della maschera
    sll     $t1, $a0, 1                     # $t1 = id_sensore * 2
    addi    $t1, $t1, 1                     # $t1 + 1
 
    li      $t2, 1
    sllv    $t2, $t2, $t1                   # t2 = 1 << (id * 2 + 1) -> mashcera per il fumo
 
    and     $t3, $t0, $t2                   # t3 = ALLARMS and maschera

    # controllo del valore
    beq     $t3, $zero, non_attiva_sirena   # se il bit di fumo non e' asserito non eseguo niente
    # altrimenti
    jal attiva_sirena                       # attiva la sirena

    non_attiva_sirena:
        lw      $ra, 4($sp)                 # recupero il valore dell'indirizzo al quale tornare
        addi    $sp, $sp, 8                 # reset dell'indirizzo dello stack pointer 
        jr      $ra                         # ritorno al chiamante
    nop
# -------------- FINE: COND ATT SIRENA --------------


# -------------- INIZIO: COND ATT ACQUA --------------
cond_att_acqua:
    addi        $sp, $sp, -8                # sposto indietro l'indirizzo dello stack pointer di 8 byte
    sw          $a0, 0($sp)                 # salvo: id del sensore
    sw          $ra, 4($sp)                 # salvo: indirizzo di ritorno
    
    # verifica delle condizioni necessarie per attivare l'estrasione ad acqua. 
    # l'estrazione ad acqua viene attivata solo quando in almeno 2 sensori per almeno 5 sec 
    # viene rilevata una temperatura >= 60 gradi.

    lw      $t0, 0($s4)                     # leggo il valore aggiornato del contatore dei sensori attivi
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
# -------------- FINE: COND ATT ACQUA --------------


# -------------- INIZIO: COND CALL VVFF --------------
cond_call_VVFF:
    addi        $sp, $sp, -8
    sw          $a0, 0($sp)                 # salvo: id del sensore corrente
    sw          $ra, 4($sp)                 # salvo: registro $ra

    lw          $t0, 0($s0)                 # carico nel registro $t0 ALLARMS

    # la temperatura e' maggiore di 60 gradi per il valore in TEMPERATURE
    # controllo se anche il bit in ALLARMS della temperatura e' asserito

    # Calcolo posizione base dei bit
    sll         $t1, $a0, 1                 # $t1 = id * 2

    # Maschera temperatura
    li          $t2, 1
    sllv        $t2, $t2, $t1               # $t2 = 1 << (id * 2)
    and         $t4, $t0, $t2               # isola bit temperatura

    # Maschera fumo
    addi        $t1, $t1, 1                 # posizione fumo = id * 2 + 1
    li          $t3, 1
    sllv        $t3, $t3, $t1               # $t3 = 1 << (id * 2 + 1)
    and         $t5, $t0, $t3               # isola bit fumo

    # controllo dei bit
    # controllo del bit della temperatura
    bne         $t4, $t2, fin_con_call_VVFF # se la temperatura non e' asserita
    # il bit e' asserito
    # controllo del bit di fumo
    bne         $t5, $t3, fin_con_call_VVFF # se il fumo non e' asserito
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
    beq         $v0, $zero, fin_smetti_di_chiamare # $v0 == 0 -> non faccio niente
    jal end_chiama_vvff                         # termino la chiamata ai VVFF

    fin_smetti_di_chiamare:
        lw          $ra, 0($sp)                 # recupero il valore dell'indirizzo di ritorno
        addi        $sp, $sp, 4                 # resetto lo stack
        jr          $ra                         # ritorno al chiamante
        nop


is_vvff_call:
    addi        $sp, $sp, -4            # stack
    sw          $ra, 0($sp)             # salvo il valore di $ra

    # controllo se il terzo bit di COMMAND e' asserito
    lb          $t0, 0($s1)             # carico nel registro $t0 il valore di COMMAND
    
    andi        $v0, $t0, 0x04          # maschera per isolare il bit
    srl         $v0, $v0, 2             # shift a dx per ottenere 0 o 1  

    lw          $ra, 0($sp)             # carico il valore dallo stack
    addi        $sp, $sp, 4             # ripristino lo stack
    jr          $ra                     # ritorno al chiamante
    nop
# -------------- FINE: COND CALL VVFF --------------


# -------------- INIZIO: TEMPO DI ATTESA --------------
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
# -------------- FINE: TEMPO DI ATTESA --------------


# -------------- INIZIO: RESET --------------
verifica_condizioni_reset:
    addi    $sp, $sp, -4            # stack
    sw      $ra, 0($sp)             # salvo il valore di $ra
    
    # verifico se sono passati 5 secondi
    lw      $t0, 0($s5)                 # carico il valore del contatore delle iterazioni
    blt     $t0, 0x5, fine_verifica     # $t0 < 5 -> fine verifica 
    # verifico se COMMAND e' tutto a zero
    lb      $t1, 0($s1)                 # carico command
    andi    $t1, $t1, 0xFF              # command andi 0xFF
    beq     $t1, $zero, reset           # se command e' a zero resetto

    fine_verifica:
        lw      $ra, 0($sp)             # carico il valore dallo stack
        addi    $sp, $sp, 4             # ripristino lo stack
        jr      $ra                     # ritorno al chiamante
        nop

reset:
    addi    $sp, $sp, -4            # stack
    sw      $ra, 0($sp)             # salvo il valore di $ra
    
    jal     reset_cont_sec_pass
    jal     reset_cont_temp_over
    jal     reset_record
    
    lw      $ra, 0($sp)             # carico il valore dallo stack
    addi    $sp, $sp, 4             # ripristino lo stack
    jr      $ra
    nop

reset_record:
    addi    $sp, $sp, -4            # stack
    sw      $ra, 0($sp)             # salvo il valore di $ra
    la      $s3, RECORD             # recupero l'indirizzo di RECORD

    move    $t0, $zero              # inizializzo un'indice
    li      $t8, 0xFF               # valore per inizializzare

    reset_record_loop:
        bge     $t0, 32, end_reset_record       # se ho finito l'area di memoria, finisco
        add     $t1, $s3, $t0                   # recupero l'indirizzo successivo a quello di partenza
        sh      $t8, 0($t1)                     # azzero il valore corrispondente all'indirizzo 
        addi    $t0, $t0, 2                     # passo alla prossima coppia
        j       reset_record_loop               # ritorno ad inizio ciclo
    
    end_reset_record:
        lw      $ra, 0($sp)             # carico il valore dallo stack
        addi    $sp, $sp, 4             # ripristino lo stack
        jr      $ra                     # ritorno al chiamante
        nop
# -------------- FINE: RESET --------------


# -------------- INIZIO: SALVA_RECORD --------------
salva_record:
    addi    $sp, $sp, -8    # stack
    sw      $a0, 0($sp)     # salvo: id sensore
    sw      $ra, 4($sp)     # salvo: indirizzo al quale devo tornare

    la      $s3, RECORD     # Recupero l'indirizzo di record
    mul     $t0, $a0, 2     # offset = id * 2 Byte
    add     $s3, $s3, $t0   # indirizzo + offset
    sh      $a0, 0($s3)     # salvo il valore

    lw      $ra, 4($sp)     # carico l'indirizzo del punto a cui tornare
    addi    $sp, $sp, 8     # ripristino stack
    jr      $ra             # ritorno al chiamante
    nop
# -------------- FINE: SALVA_RECORD --------------


# -------------- INIZIO: FUNZIONE FUMO --------------
is_presenza_di_fumo:
    addi    $sp, $sp, -8    # stack
    sw      $a0, 0($sp)     # salvo: id sensore
    sw      $ra, 4($sp)     # salvo: indirizzo al quale devo tornare

    # accedo a ALLARMS 
    lw      $t0, 0($s0)     # carico il valore di ALLARMS in $t0

    # creo la maschera (secondo bit della coppia)
    li      $t1, 1           # base della maschera
    sll     $t2, $a0, 1      # id * 2
    addi    $t2, $t2, 1      # id * 2 + 1
    sllv    $t1, $t1, $t2    # maschera = 1 << (id * 2 + 1)

    # applico la maschera
    and     $t3, $t0, $t1    # applico la maschera

    # normalizzo il risultato e rirorno il valore
    srlv    $v0, $t3, $t2    # normalizzo a 0 o 1

    lw      $ra, 4($sp)     # carico l'indirizzo del punto a cui tornare
    addi    $sp, $sp, 8     # ripristino stack
    jr      $ra             # ritorno al chiamante
    nop
# -------------- FINE: FUNZIONE FUMO --------------


# -------------- INIZIO: FUNZIONI DI COMMAND --------------
# funzionamento:
# se viene rilevato fumo, il primo bit viene asserito
# se viene rilevata una temperatura > 60 gradi (in almeno 2 sensori) vine asserito il secondo bit
# se viene rilevato fumo e la temperatura e' > 60 in un sensore, viene asserito il terzo bit
#            (ori - attiva)           (andi - disattiva)
# bit 0 -> (0b00000 001 -> 0x1)      (0b00000 110 -> 0x6)
# bit 1 -> (0b00000 010 -> 0x2)      (0b00000 101 -> 0x5)
# bit 2 -> (0b00000 100 -> 0x4)      (0b00000 011 -> 0x3)
# 
# N: i 5 bit a 0, vengono sempre resettati a 0. NON c'e' nessuna perdita di informazioni
# dal momento che devo lavorare solo con i primi 3 bit (0, 1, 2) 

# attivazione della sirena
attiva_sirena:
    addi    $sp, $sp, -4            # stack
    sw      $ra, 0($sp)             # salvo il valore di $ra

    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del primo bit di COMMAND
    ori     $t9, $t9, 0x01          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_sirena_attiva
    syscall
    

    lw      $ra, 0($sp)             # carico il valore dallo stack
    addi    $sp, $sp, 4             # ripristino lo stack
    jr      $ra                     # ritorno al chiamante
    nop

# disattivazione della sirena
disattiva_sirena:
    addi    $sp, $sp, -4            # stack
    sw      $ra, 0($sp)             # salvo il valore di $ra
    
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del primo bit di COMMAND
    andi    $t9, $t9, 0x6           # deasserisco il bit con la maschera 0X6
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_sirena_disattiva
    syscall    
    
    lw      $ra, 0($sp)             # carico il valore dallo stack
    addi    $sp, $sp, 4             # ripristino lo stack
    jr      $ra                     # ritorno al chiamante
    nop

# attiva impianto ad acqua
attiva_acqua:
    addi    $sp, $sp, -4            # stack
    sw      $ra, 0($sp)             # salvo il valore di $ra
    
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del secondo bit di COMMAND
    ori     $t9, $t9, 0x02          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_acqua_attiva
    syscall
    
    lw      $ra, 0($sp)             # carico il valore dallo stack
    addi    $sp, $sp, 4             # ripristino lo stack
    jr      $ra                     # ritorno al chiamante
    nop

# disattiva impianto ad acqua
disattiva_acqua:
    addi    $sp, $sp, -4            # stack
    sw      $ra, 0($sp)             # salvo il valore di $ra
    
    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del secondo bit di COMMAND
    andi    $t9, $t9, 0x5           # deasserisco il bit con la maschera 0x5
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_acqua_disattiva
    syscall
    
    lw      $ra, 0($sp)             # carico il valore dallo stack
    addi    $sp, $sp, 4             # ripristino lo stack
    jr      $ra                     # ritorno al chiamante
    nop

# chiama VVFF
chiama_vvff:
    addi    $sp, $sp, -4            # stack
    sw      $ra, 0($sp)             # salvo il valore di $ra

    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del terzo bit di COMMADN
    ori     $t9, $t9, 0x04          # asserisco il bit
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_chiamata_VVFF
    syscall
    
    lw      $ra, 0($sp)             # carico il valore dallo stack
    addi    $sp, $sp, 4             # ripristino lo stack
    jr      $ra                     # ritorno al chiamante
    nop

# disattiva chiamata VVFF
end_chiama_vvff:
    addi    $sp, $sp, -4            # stack
    sw      $ra, 0($sp)             # salvo il valore di $ra

    lb      $t9, 0($s1)             # carico nel registro $t9 il valore del terzo bit di COMMADN
    andi    $t9, $t9, 0x3           # deasserisco il bit con la maschera 0x3
    sb      $t9, 0($s1)             # aggiorno COMMAND con il nuovo valore
    # messaggio sulla console
    li      $v0, 4
    la      $a0, msg_VVFF_fine_chiamata
    syscall

    lw      $ra, 0($sp)             # carico il valore dallo stack
    addi    $sp, $sp, 4             # ripristino lo stack
    jr      $ra                     # ritorno al chiamante
    nop
# -------------- FINE: FUNZIONI DI COMMAND --------------


# -------------- INIZIO: AGGIORNAMENTO CONTATORI --------------
inc_cont_temp_over:
    addi    $sp, $sp, -4        # stack
    sw      $ra, 0($sp)         # salvo il valore di $ra
    
    lw      $t9, 0($s4)         # recupero il valore
    addi    $t9, $t9, 1         # incremento
    sw      $t9, 0($s4)         # aggiorno il valore

    lw      $ra, 0($sp)         # carico il valore dallo stack
    addi    $sp, $sp, 4         # ripristino lo stack
    jr      $ra                 # ritorno al chiamante
    nop

inc_cont_sec_pass:
    addi    $sp, $sp, -4        # stack
    sw      $ra, 0($sp)         # salvo il valore di $ra
    
    lw      $t9, 0($s5)         # recupero il valore
    addi    $t9, $t9, 1         # incremento
    sw      $t9, 0($s5)         # aggiorno il valore

    lw      $ra, 0($sp)         # carico il valore dallo stack
    addi    $sp, $sp, 4         # ripristino lo stack
    jr      $ra                 # ritonro al chiamante
    nop

dec_cont_temp_over:
    addi    $sp, $sp, -4        # stack
    sw      $ra, 0($sp)         # salvo il valore di $ra

    lw      $t9, 0($s4)         # recupero il valore
    ble     $t9, $zero, end_dec # $t9 <= 0 -> end_dec 
    addi    $t9, $t9, -1        # decremento
    sw      $t9, 0($s4)         # aggiorno il valore

    end_dec:
        lw      $ra, 0($sp)         # carico il valore dallo stack
        addi    $sp, $sp, 4         # ripristino lo stack
        jr      $ra                 # ritorno al chiamante
        nop

reset_cont_temp_over:
    addi    $sp, $sp, -4        # stack
    sw      $ra, 0($sp)         # salvo il valore di $ra

    sw      $zero, 0($s4)       # azzero il contatore
    
    lw      $ra, 0($sp)         # recupero il valore di $ra
    addi    $sp, $sp, 4         # ripristino lo stack
    jr      $ra                 # ritono al chiamante
    nop 

reset_cont_sec_pass:
    addi    $sp, $sp, -4        # stack
    sw      $ra, 0($sp)         # salvo il valore di $ra

    sw      $zero, 0($s5)       # azzero il contatore
    
    lw      $ra, 0($sp)         # recupero il valore di $ra
    addi    $sp, $sp, 4         # ripristino lo stack
    jr      $ra                 # ritono al chiamante
    nop
# -------------- FINE: AGGIORNAMENTO CONTATORI --------------


# -------------- INIZIO: MESSAGGI DI STATO --------------
# -------------- MESSAGGIO STATO COMMAND --------------
msg_command_status:
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    # messaggio di stato di COMMAND:
    li      $v0, 4
    la      $a0, msg_command
    syscall

    jal     msg_stato_sirena
    jal     msg_stato_acqua
    jal     msg_stato_VVFF

    lw      $ra, 0($sp)
    addi    $sp, $sp, 4
    jr      $ra
    nop

# -------------- MESSAGGIO STATO SIRENA (BIT 0) --------------
msg_stato_sirena:
    addi    $sp, $sp, -4            # Stack
    sw      $ra, 0($sp)             # salvo il valore del reg di ritorno

    lb      $t0, 0($s1)             # carico il valore di COMMAND in $t0

    # creo la maschera per il primo bit 

    # per ottenere il valore del primo bit:
    # and 00000001 

    and     $t1, $t0, 0x1           # $t1 contiene il valore del primo bit (0)

    # controllo se e' asserito
    beq     $t1, 0x1, msg_stato_sirena_attiva         # se asserito messaggio sirena attiva
    # messaggio sirena non attiva
    li      $v0, 4
    la      $a0, msg_sirena_disattiva
    syscall
    j       fin_msg_stato_sirena

    msg_stato_sirena_attiva:
        # sirena attiva
        li      $v0, 4
        la      $a0, msg_sirena_attiva
        syscall

    fin_msg_stato_sirena:
        lw      $ra, 0($sp)             # recupero il valore del reg di ritorno
        addi    $sp, $sp, 4             # ripristino lo stack
        jr      $ra                     # torno indietro
        nop

# -------------- MESSAGGIO STATO ACQUA (BIT 1) --------------
msg_stato_acqua:
    addi    $sp, $sp, -4            # Stack
    sw      $ra, 0($sp)             # salvo il valore del reg di ritorno

    lb      $t0, 0($s1)             # carico il valore di COMMAND in $t0

    # creo la maschera per il secondo bit 

    # per ottenere il valore del secondo bit:
    # and 00000010 

    and     $t1, $t0, 0x2           # $t1 contiene il valore del secondo bit (1)

    # controllo se e' asserito
    beq     $t1, 0x2, msg_stato_acqua_attiva         # se asserito messaggio acqua attiva
    # messaggio sirena non attiva
    li      $v0, 4
    la      $a0, msg_acqua_disattiva
    syscall
    j       fin_msg_stato_acqua

    msg_stato_acqua_attiva:
        # sirena attiva
        li      $v0, 4
        la      $a0, msg_acqua_attiva
        syscall

    fin_msg_stato_acqua:
        lw      $ra, 0($sp)             # recupero il valore del reg di ritorno
        addi    $sp, $sp, 4             # ripristino lo stack
        jr      $ra                     # torno indietro
        nop

# -------------- MESSAGGIO STATO VVFF (BIT 2) --------------
msg_stato_VVFF:
    addi    $sp, $sp, -4            # Stack
    sw      $ra, 0($sp)             # salvo il valore del reg di ritorno

    lb      $t0, 0($s1)             # carico il valore di COMMAND in $t0

    # creo la maschera per il terzo bit 

    # per ottenere il valore del terzo bit:
    # and 00000100 

    and     $t1, $t0, 0x4           # $t1 contiene il valore del terzo bit (2)

    # controllo se e' asserito
    beq     $t1, 0x04, msg_stato_VVFF_chiamato         # se asserito messaggio di chiamata
    # messaggio sirena non attiva
    li      $v0, 4
    la      $a0, msg_VVFF_non_chiamati
    syscall
    j       fin_msg_stato_VVFF

    msg_stato_VVFF_chiamato:
        # sirena attiva
        li      $v0, 4
        la      $a0, msg_chiamata_VVFF
        syscall

    fin_msg_stato_VVFF:
        lw      $ra, 0($sp)             # recupero il valore del reg di ritorno
        addi    $sp, $sp, 4             # ripristino lo stack
        jr      $ra                     # torno indietro
        nop

# -------------- MESSAGGIO TEMPERATURA SENSORE --------------
msg_temperatura_sensore:
    addi    $sp, $sp, -12
    sw      $a0, 0($sp)     # salvo: id del sensore
    sw      $a1, 4($sp)     # salvo: valore del sensore
    sw      $ra, 8($sp)     # salvo: valore dell'indirizzo di ritorno

    move    $t0, $a0        # id sensore
    move    $t1, $a1        # valore sensore

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

    # fumo
    lw      $a0, 0($sp)             # carico $a0 l'id del sensore
    jal     is_presenza_di_fumo     # entro nella funzione
    bne     $v0, $zero, si_fumo     # $v0 != 0 -> fumo
    # scritta: Fumo NO
    li      $v0, 4
    la      $a0, msg_no_fumo
    syscall
    j       fine_scritta            # vado alla fine

    si_fumo:
        # scritta: Fumo SI
        li      $v0, 4
        la      $a0, msg_si_fumo
        syscall

    fine_scritta:
        # scritta: \n
        li      $v0, 4
        la      $a0, msg_acapo
        syscall
        
        lw      $ra, 8($sp)     # recupero il valore dell'indirizzo di ritorno
        addi    $sp, $sp, 12    # resetto lo stack (corretto da 8 a 12)
        jr      $ra             # ritorno al chiamante
        nop

# -------------- MESSAGGIO SOLO LINEA --------------
stampa_solo_linea:
    addi    $sp, $sp, -4    # stack
    sw      $ra, 0($sp)     # salvo il registro al quale tornare
    # scritta: linea
    li      $v0, 4
    la      $a0, msg_linea
    syscall

    lw      $ra, 0($sp)     # recupero il valore di $ra
    addi    $sp, $sp, 4     # reimpostao lo stack
    jr      $ra             # torno a $ra
    nop

# -------------- MESSAGGIO ELEMENTI PRESENTI IN RECORD --------------
riepilogo_record:
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    # scritta: riepilogo RECORD
    li      $v0, 4
    la      $a0, msg_riepilogo_record
    syscall

    # scritta: sensori salvati
    li      $v0, 4
    la      $a0, msg_sensori_salvati
    syscall

    li      $t9, 0          # indice
    loop_riepilogo:
        bge     $t9, 16, end_riepilogo  # if $t9 > 16 -> end_riepilogo
        mul     $t0, $t9, 2
        lh      $t8, RECORD($t0)        # recupero il valore

        beq     $t8, 0xFF, skip_stampa     # $t8 == 0xFF -> skip stampa

        # scritta: id
        li      $v0, 4
        la      $a0, msg_id
        syscall

        # scritta: id valore
        li      $v0, 1
        move    $a0, $t8
        syscall

        

        # scritta: a capo
        li      $v0, 4
        la      $a0, msg_acapo
        syscall
        
        skip_stampa:
            addi     $t9, $t9, 1     # $t9 * 2
            j       loop_riepilogo

    end_riepilogo:
        jal     stampa_solo_linea
        lw      $ra, 0($sp)
        addi    $sp, $sp, 4
        jr      $ra
        nop
# -------------- FINE: MESSAGGI DI STATO --------------

# -------------- INIZIO: INIZIALIZZAZIONE SENSORI MANUALE --------------
init_sensori_manuale:
    addi    $sp, $sp, -8                # stack
    sw      $ra, 0($sp)                 # salvataggio dell'indirizzo di ritorno al chiamante
    sw      $t6, 4($sp)                 # salvataggio del contatore dei sensori

    li      $t6, 0                      # inizializzazione indice sensore a 0

isens_loop:
    bge     $t6, 16, fine_init_sens     # verifico se l'indice è maggiore o uguale a 16 (tutti i sensori sono stati inizializzati), uscita

    # intestazione sensore
    li      $v0, 4                      # stampa di una stringa
    la      $a0, msg_id                 
    syscall
    li      $v0, 1                      # stampa di un intero
    move    $a0, $t6                    # passaggio dell'indice del sensore
    syscall
    li      $v0, 4                      # stampa a capo
    la      $a0, msg_acapo
    syscall

# --- lettura valore temperatura ---
leggi_temp:
    li      $v0, 4                      # richiesta della temperatura
    la      $a0, ins_temp_init
    syscall
    li      $v0, 5                      # inserimento del valore di temperatura
    syscall
    move    $t7, $v0                    # salvataggio in $t7 del valore inserito
    bltz    $t7, temp_err               # messaggio di errore se temperatura < 0
    li      $t8, 200                    # valore massimo registrato dal sensore
    sltu    $t9, $t8, $t7               # $t9 = 1 se $t7 > 200
    bne     $t9, $zero, temp_err        # messaggio di errore se viene superato il valore soglia

    # salvataggio temperatura
    sll     $t8, $t6, 16                # spostamento a sinistra dell'ID sensore
    or      $t8, $t8, $t7               # ID e temperatura combinati in un unica word
    sll     $t9, $t6, 2                 # calcolo dell'offset
    add     $t9, $t9, $s2               # indirizzo temperature + offset
    sw      $t8, 0($t9)                 # salvataggio della word in TEMPERATURE

    # conferma salvataggio temperatura
    li      $v0, 4                      # messaggio di conferma inserimento della temperatura
    la      $a0, msg_ok_temp
    syscall

    j       lettura_fumo                # jump alla lettura del valore del fumo

temp_err:
    li      $v0, 4                      # messaggio di errore per la temperatura
    la      $a0, msg_err_temp_iniz
    syscall
    j       leggi_temp                  # ripetere la lettura per la temperatura

# --- lettura del valore per il fumo ---
lettura_fumo:
    li      $v0, 4                      # richiesta del valore del fumo (0 = NO, 1 = SI)
    la      $a0, ins_fumo_init
    syscall
    li      $v0, 5                      # salvataggio del valore inserito
    syscall
    move    $t7, $v0                    # se valore inserito = 0 -> non c'è fumo
    beq     $t7, $zero, fumo_zero
    li      $t8, 1                      # se valore inserito = 1 -> presenza di fumo
    beq     $t7, $t8, fumo_uno      

    li      $v0, 4                      # messaggio di errore per il fumo
    la      $a0, msg_err_fumo_iniz
    syscall
    j       lettura_fumo                # ripetere la lettura per il fumo

fumo_zero:
    li      $t8, 1                      
    sll     $t9, $t6, 1          
    addi    $t9, $t9, 1                 # posizione bit fumo = ID * 2 + 1
    sllv    $t8, $t8, $t9               # maschera 
    nor     $t8, $t8, $zero             # inverte i valori 
    lw      $t1, 0($s0)                 # carica valore ALLARMS
    and     $t1, $t1, $t8               # azzeramento del bit fumo per questo sensore
    sw      $t1, 0($s0)                 # salvataggio di ALLARMS aggiornato

    li      $v0, 4                      # messaggio di conferma del fumo
    la      $a0, msg_ok_fumo            
    syscall
    j       separa_sensore              # jump alla spaziatura tra i sensori

fumo_uno:
    li      $t8, 1                      
    sll     $t9, $t6, 1                 
    addi    $t9, $t9, 1                 # posizione bit fumo = ID * 2 + 1
    sllv    $t8, $t8, $t9               # maschera
    lw      $t1, 0($s0)                 # carico valore ALLARMS
    or      $t1, $t1, $t8               # asserimento del bit fumo nel sensore
    sw      $t1, 0($s0)                 # salvataggio di ALLARMS aggiornato

    li      $v0, 4                      # messaggio di caricamento del fumo
    la      $a0, msg_ok_fumo
    syscall

# --- spaziatura tra i sensori ---
separa_sensore:
    li      $v0, 4                      # inserimento della linea per separare i sensori
    la      $a0, msg_linea
    syscall

    addi    $t6, $t6, 1                 # passaggio al sensore successivo
    j       isens_loop                  # ripetizione del ciclo per il sensore successivo

fine_init_sens:
    lw      $ra, 0($sp)                 # recupero dell'indirizzo di ritorno
    lw      $t6, 4($sp)                 # recupero contatore con indice del sensore
    addi    $sp, $sp, 8                 # ripristino dello stack
    jr      $ra                         # ritorno al chaimante
    nop
# -------------- FINE: INIZIALIZZAZIONE SENSORI MANUALE --------------