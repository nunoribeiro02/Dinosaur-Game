; Feito por: Diogo Soares (ist199208) e Nuno Ribeiro (ist199293)

; Inicialização de constantes e variáveis--------------------------------------

; Texto
TERM_READ       EQU     FFFFh
TERM_WRITE      EQU     FFFEh
TERM_STATUS     EQU     FFFDh
TERM_CURSOR     EQU     FFFCh
TERM_COLOR      EQU     FFFBh

; Display 7 segmentos
DISPLAY0        EQU     FFF0h
DISPLAY1        EQU     FFF1h
DISPLAY2        EQU     FFF2h
DISPLAY3        EQU     FFF3h
DISPLAY4        EQU     FFEEh
DISPLAY5        EQU     FFEFh

; Temporizador
TIMER_CONTROL   EQU     FFF7h
TIMER_COUNTER   EQU     FFF6h
TIMER_SETSTART  EQU     1
TIMER_SETSTOP   EQU     0
TIMERCOUNT_MAX  EQU     20
TIMERCOUNT_MIN  EQU     1
TIMERCOUNT_INIT EQU     1

; interruptions
INT_MASK        EQU     FFFAh
INT_MASK_VAL    EQU     80FFh ; 1000 0000 0001 1010 b

                ORIG    4000h
STACKBASE       EQU     8000h
N               EQU     80
X               WORD    5
ALTURAMAX       EQU     4 ; altura maxima do cacto, deve ser uma potencia de 2
SALTO           EQU     0600h ; altura que o dino pode saltar

CACTOPOS_INI    EQU     2800h ; posicao onde se desenham os cactos inicialmente
                              ; (os 8 bits mais significativos devem ser iguais
                              ; aos 8 bits mais significativos de DINOPOS_INI)
CACTOPOS        WORD    2800h ; posicao onde se desenham os cactos 
                              


DINOPOS_INI     EQU     2702h ; posicao do dinossauro no inicio do jogo,
                              ; uma linha acima do chao (linha 39, coluna 2)
DINOPOS         WORD    0 ; posicao do dinossauro a cada momento do jogo
DINOPOS_MAX     WORD    0 ; altura maxima que o dino pode atingir ao saltar

DINOCHAR        EQU     00a8h ; representacao do dino em ASCII, correspode '¿'
CACTOCHAR       EQU     0049h ; representacao do cacto em ASCII, correspode 'I'

GAMEOVER        STR     'G A M E  O V E R'

                ORIG    0000h
TERRENO         TAB     N
                MVI     R6, STACKBASE
                
TIMER_COUNTVAL  WORD    TIMERCOUNT_INIT ; indica a medida da contagem do tempo

TIMER_TICK      WORD    0               ; indica o numero de interrupcoes do
                                        ; temporizador que nao foram atendidas
TIME            WORD    0               ; tempo que passou

SCORE           WORD    0               ; pontuacao
START           WORD    0 ; se START = 0, jogo parado 
                          ; se START = 1, jogo em andamento
;=================================================================
; MAIN: the starting point of your program
;-----------------------------------------------------------------
     
MAIN:           MVI     R6,STACKBASE
                
                ; CONFIGURE TIMER ROUNTINES
                ; interrupt mask
                MVI     R1,INT_MASK
                MVI     R2,INT_MASK_VAL
                STOR    M[R1],R2
                ; enable interruptions
                ENI

                ; START TIMER
                MVI     R2,TIMERCOUNT_INIT
                MVI     R1,TIMER_COUNTER
                STOR    M[R1],R2          ; set timer to count 10x100ms
                MVI     R1,TIMER_TICK
                STOR    M[R1],R0          ; clear all timer ticks
                MVI     R1,TIMER_CONTROL
                MVI     R2,TIMER_SETSTART
                STOR    M[R1],R2          ; start timer
                
                ; WAIT FOR EVENT (TIMER/KEY)
                MVI     R5,TIMER_TICK
                
.LOOP:          
                
                LOAD    R1,M[R5]
                CMP     R1,R0
                JAL.NZ  process_timer
                BR      .LOOP


process_timer:  ; aumenta o tempo no temporizador e trata de mostrar no 
                ; display de 7 segmentos a pontuacao em decimal
                ; chama tambem o resto das funcoes necessarias ao jogo
                DEC     R6
                STOR    M[R6], R7                
                
                ; Decrementar TIMER_TICK
                MVI     R2, TIMER_TICK
                DSI     ; nao pode haver interrupcoes neste momento
                LOAD    R1, M[R2]
                DEC     R1
                STOR    M[R2], R1
                ENI     ; reativar as interrupcoes
                
                ; se START = 0, ignora a funcao
                MVI     R1, START
                LOAD    R2, M[R1]
                CMP     R2, R0
                BR.Z    .return
              
                ; Aumentar o tempo
                MVI     R1,TIME
                LOAD    R2,M[R1]
                INC     R2
                STOR    M[R1],R2
                MVI     R1, SCORE
                STOR    M[R1], R2
                ; pontuacao no display4
                MVI     R3, 0
                MVI     R2, SCORE
                LOAD    R1, M[R2]
.loopdisplay4:  MVI     R2, 10000
                CMP     R1, R2
                BR.N    .writedisplay4
                INC     R3
                SUB     R1, R1, R2
                CMP     R1, R2
                BR.NN   .loopdisplay4
.writedisplay4: MVI     R2, DISPLAY4
                STOR    M[R2], R3
                MVI     R2, SCORE
                STOR    M[R2], R1

                ; pontuacao no display3
                MVI     R3, 0
                MVI     R2, SCORE
                LOAD    R1, M[R2]
.loopdisplay3:  MVI     R2, 1000
                CMP     R1, R2
                BR.N    .writedisplay3
                INC     R3
                SUB     R1, R1, R2
                CMP     R1, R2
                BR.NN   .loopdisplay3
.writedisplay3: MVI     R2, DISPLAY3
                STOR    M[R2], R3
                MVI     R2, SCORE
                STOR    M[R2], R1
                
                ; pontuacao no display2
                MVI     R3, 0
                MVI     R2, SCORE
                LOAD    R1, M[R2]
.loopdisplay2:  MVI     R2, 100
                CMP     R1, R2
                BR.N    .writedisplay2
                INC     R3
                SUB     R1, R1, R2
                CMP     R1, R2
                BR.NN   .loopdisplay2
.writedisplay2: MVI     R2, DISPLAY2
                STOR    M[R2], R3
                MVI     R2, SCORE
                STOR    M[R2], R1
                
                ; pontuacao no display1
                MVI     R3, 0
                MVI     R2, SCORE
                LOAD    R1, M[R2]
.loopdisplay1:  MVI     R2, 10
                CMP     R1, R2
                BR.N    .writedisplay1
                INC     R3
                SUB     R1, R1, R2
                CMP     R1, R2
                BR.NN   .loopdisplay1
.writedisplay1: MVI     R2, DISPLAY1
                STOR    M[R2], R3
                MVI     R2, SCORE
                STOR    M[R2], R1

                ; pontuacao no display0
                MVI     R2, DISPLAY0
                STOR    M[R2], R1
                MVI     R2, SCORE
                STOR    M[R2], R1

                JAL     atualizajogo
                ;JAL     atualizaterminal
                
.return:        LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
                
atualizajogo:   DEC     R6 
                STOR    M[R6], R4
                DEC     R6 
                STOR    M[R6], R5 ; guardar R4 e R5 na pilha para os preservar
                
                DEC     R6
                STOR    M[R6], R7 ; guardar R7 na pilha
                 
                MVI     R1, TERRENO
                MVI     R2, N
                DEC     R2 ; para deslocar para a esquerda N-1 vezes
                

.desloca:        ; todos os valores vao ser deslocados 1 vez para a esquerda

                INC     R1 
                LOAD    R4, M[R1] ; guardar o valor da posicao n 
                DEC     R1
                STOR    M[R1], R4 ; substituir o valor de n-1 pelo valor de n
                INC     R1  
                ;JAL     movecacto
                
                DEC     R2
                CMP     R2, R0
                BR.NZ   .desloca   ; se R2 nao for 0, repete o atualizajogo
                                  ; se for 0, significa que todas as posicoes
                                  ; da tabela foram deslocadas uma vez para 
                                  ; a esquerda
                
                DEC     R6 
                STOR    M[R6], R1 ; guardar o ultimo endereco da tabela na pilha
                
                JAL     geracacto

                LOAD    R1, M[R6] ; retirar o ultimo endereco da tabela na pilha
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                       
                MOV     R4, R3
                STOR    M[R1], R4 ; guardar o novo cacto gerado na ultima
                                  ; posicao da tabela
                
                                
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6         ; preservar R4 e R5
                
                JMP     R7
                
geracacto:      DEC     R6 
                STOR    M[R6], R4
                DEC     R6 
                STOR    M[R6], R5 ; guardar R4 e R5 na pilha para os preservar 

                MVI     R1, ALTURAMAX ; R1 tem o valor de ALTURAMAX
                ;LOAD    R1, M[R4] ; R1 tem o valor de ALTURAMAX
                MVI     R4, X
                LOAD    R2, M[R4] ; R2 tem o valor de X
                
                MVI     R4, 1
                AND     R4, R2, R4 ; R4 tem o valor da variavel bit
                SHR     R2
                MVI     R5, X
                STOR    M[R5], R2 ; guarda o novo valor de X
                
                CMP     R4, R0 ; ver se o bit tem valor zero ou nao
                BR.NZ   .if
                BR      .if_2
                
.if:            MVI     R5, B400h
                XOR     R4, R2, R5 ; altera o X
                MVI     R2, X ; R2 tem o endereço de memória de X
                STOR    M[R2], R4 ; guarda o novo valor de X
                
.if_2:          MVI     R5, 62258d
                CMP     R2, R5
                BR.N    .return_5pc ; caso R2 maior que R5, salta para o return
                              ; coisa que so acontece 5% das vezes
                              
                MOV     R3, R0 ; R3 = 0 --> return 0
                BR      .return

.return_5pc:    DEC     R1 ; altura - 1
                AND     R3, R2, R1 ; R3 = X & (altura - 1)
                INC     R3 ; R3 = X & (altura - 1) + 1 
                           ; --> return X & (altura - 1) + 1
          
                
.return:        LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6        ; preservar R4 e R5 
                
                JMP     R7
                
aux_timer_intr: ; auxiliar da interrupcao do timer (temporizador)
                
                DEC     R6
                STOR    M[R6], R1
                DEC     R6
                STOR    M[R6], R2
                ; recomecar temporizador
                MVI     R1, TIMER_COUNTVAL
                LOAD    R2, M[R1]
                MVI     R1, TIMER_COUNTER
                STOR    M[R1], R2          ; set timer to count value
                MVI     R1, TIMER_CONTROL
                MVI     R2, TIMER_SETSTART
                STOR    M[R1], R2          ; comecar temporizador
                ; incrementar TIMER_TICK
                MVI     R2, TIMER_TICK
                LOAD    R1, M[R2]
                INC     R1
                STOR    M[R2], R1
                LOAD    R3, M[R2]
                
                ; preservar
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6
                JMP     R7
                

; Interrupcoes ----------------------------------------------------------------
                ORIG    7FF0h
timer_intr:     ; guardar na pilha
                DEC     R6
                STOR    M[R6], R7
                ; chamar a funcao
                JAL     aux_timer_intr
                ; preservar
                LOAD    R7, M[R6]
                INC     R6
                RTI
                
                ORIG    7F10h
keyzero:        ; guardar na pilha
                DEC     R6
                STOR    M[R6], R1
                DEC     R6
                STOR    M[R6], R2
                ; colocar 1 em R3 para confirmar que KEY0 foi pressionado
                MVI     R1, START
                MVI     R2, 1
                STOR    M[R1], R2
                
                ; preservar
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6   
                RTI

                ORIG    7F30h
keyup:          ; guardar na pilha
                DEC     R6
                STOR    M[R6],R1
                DEC     R6
                STOR    M[R6],R7
                ; chamar a funcao auxiliar para o dino saltar
                ; preservar
                LOAD    R7,M[R6]
                INC     R6
                LOAD    R1,M[R6]
                INC     R6
                RTI
