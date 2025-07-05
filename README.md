Progetto di laboratorio dell'anno accademico 2024-2025 del corso: Modulo di Calcolatori Elettronici - Informatica

Progetto scelto: Progetto 1
# Testo del progetto
Un sistema basato sul microprocessore MIPS R2000 (clock pari a 100 MHz) gestisce un allarme anti-incendio. 
Il programma di cui si chiede lo sviluppo gestisce da 1 a 16 sensori il cui stato è memorizzato nell'area di memoria denominata ALLARMS. Per ogni sensore vengono dedicati due bit consecutivi, uno che viene asserito quando la temperatura si alza sopra i 60 gradi, il secondo che viene asserito quando viene rilevata la presenza di fumo. 
L'area di memoria viene aggiornata ogni secondo. 
Il software aziona il sistema scrivendo in una area di memoria denominata COMMAND, di tre bit, il primo che azione la sirena quando asserito, il secondo che attiva l'impianto di estrazione ad acqua quando è asserito, il terzo che chiama i VVFF. Il terzo bit viene deasserito dopo un secondo.
Se viene rilevato solo fumo in almeno un sensore, scatta la sirena. Se viene rilevata una temperatura superiore ai 60 gradi in almeno due sensori, per più di 5 secondi, viene attivata l'estinzione ad acqua. Se viene rilevato sia fumo che una temperatura superiore ai 60 gradi nello stesso sensore, viene attivata la sirena, l'impianto di estinzione e vengono chiamati i VVFF. 

Nell'area di memoria denominata TEMPERATURE vengono memorizzate dal sistema, consecutivamente in memoria, le temperature di ogni sensore. Per ogni sensore 2 byte identificato il numero del sensore e due byte identificano la temperature misurata. 
Quando scatta l'allarme temperatura identificare i sensori con una temperatura maggiore di 40 gradi e scrive l'elenco dei sensori nell'area di memoria RECORD. 

Il sistema resetta gli allarmi e l'impianto di estinzione dopo 5 secondi senza fume e temperatura minore di 60 gradi in tutti i sensori. 

Alle celle di memoria sopra menzionate si assegnino indirizzi arbitrari che cadano, però, nell'area dei dati dell'architettura MIPS. Il programma deve essere assemblato, linkato e sottoposto a simulazione. Si faccia una stampa commentate del sorgente del programma realizzato (corredata anche dal relativo flow-chart).
