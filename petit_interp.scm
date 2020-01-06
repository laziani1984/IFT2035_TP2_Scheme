#! /usr/bin/env gsi -:dar

;;; Ce devoir est présenté par : Waël ABOU ALI et Nahuel LONDONO.

;;; Fichier : petit-interp.scm

;;;----------------------------------------------------------------------------

;;; Vous devez modifier cette section.  La fonction parse-and-execute
;;; doit etre definie, et vous pouvez modifier et ajouter des
;;; definitions de fonction afin de bien decomposer le traitement a
;;; faire en petites fonctions.  Il faut vous limiter au sous-ensemble
;;; *fonctionnel* de Scheme dans votre codage (donc n'utilisez pas
;;; set!, set-car!, vector-set!, list-set!, begin, print, display,
;;; etc).

;; La fonction parse-and-execute recoit en parametre une liste des
;; caracteres qui constituent le programme a interpreter.  La
;; fonction retourne une chaine de caracteres qui sera imprimee comme
;; resultat final du programme.  S'il y a une erreur lors de
;; l'analyse syntaxique ou lors de l'execution, cette chaine de
;; caracteres contiendra un message d'erreur pertinent.  Sinon, la
;; chaine de caracteres sera l'accumulation des affichages effectues
;; par les enonces "print" executes par le programme interprete.

(define parse-and-execute
  (lambda (inp)
    (parse inp execute)))

;; La fonction next-sym recoit deux parametres, une liste de
;; caracteres et une continuation.  La liste de caracteres sera
;; analysee pour en extraire le prochain symbole.  La continuation
;; sera appelee avec deux parametres, la liste des caracteres restants
;; (apres le symbole analyse) et le symbole qui a ete lu (soit un
;; symbole Scheme ou une chaine de caractere Scheme dans le cas d'un
;; <id> ou un entier Scheme dans le cas d'un <int>).  S'il y a une
;; erreur d'analyse (tel un caractere inapproprie dans la liste de
;; caracteres) la fonction next-sym retourne une chaine de caracteres
;; indiquant une erreur de syntaxe, sans appeler la continuation.


;; ** Analyseur lexical **
;; -----------------------

(define next-sym
  (lambda (inp cont)
    (cond ((null? inp)
           (cont inp 'EOI)) ;; retourner symbole EOI a la fin de l'input
          ((blanc? (@ inp))
           (next-sym ($ inp) cont)) ;; sauter les blancs
          (else
           (let ((c (@ inp)))
             (cond ((chiffre? c)   (symbol-int inp cont))
                   ((lettre? c)    (symbol-id inp cont))
                   ((char=? c #\return) (cont ($ inp) 'EOL))
                   ((char=? c #\() (cont ($ inp) 'LPAR))
                   ((char=? c #\)) (cont ($ inp) 'RPAR))
                   ((char=? c #\;) (cont ($ inp) 'SEMI))
                   ((char=? c #\{) (cont ($ inp) 'LACCO))
                   ((char=? c #\}) (cont ($ inp) 'RACCO))
                   ((char=? c #\=) 
                      (let ((inp1 ($ inp))) 
                        (if (char=? (@ inp1) #\=) 
                          (cont ($ inp1) 'EQUALS)
                          (cont ($ inp) 'EQ))))
                   ((char=? c #\<)
                      (let ((inp1 ($ inp))) 
                        (if (char=? (@ inp1) #\=) 
                        (cont ($ inp1) 'LSTE)
                        (cont ($ inp) 'LSTN))))
                   ((char=? c #\>)
                      (let ((inp1 ($ inp))) 
                        (if (char=? (@ inp1) #\=) 
                          (cont ($ inp1) 'GRTE)
                          (cont ($ inp) 'GRTN))))
                   ((char=? c #\!) 
                      (let ((inp1 ($ inp))) 
                        (if (char=? (@ inp1) #\=) 
                          (cont ($ inp1) 'NOTEQ))))
                   ((char=? c #\+) (cont ($ inp) 'PLUS))
                   ((char=? c #\-) (cont ($ inp) 'MINUS))
                   ((char=? c #\*) (cont ($ inp) 'ASTRSK))
                   ((char=? c #\/) (cont ($ inp) 'SLSH))
                   ((char=? c #\%) (cont ($ inp) 'MDLS))
                   (else
                    (syntax-error))))))))


;; La fonction @ prend une liste de caractere possiblement vide et
;; retourne le premier caractere, ou le caractere #\nul si la liste
;; est vide.

(define @
  (lambda (inp)
    (if (null? inp) #\nul (car inp))))

;; La fonction $ prend une liste de caractere possiblement vide et
;; retourne la liste des caracteres suivant le premier caractere s'il
;; y en a un.

(define $
  (lambda (inp)
    (if (null? inp) '() (cdr inp))))

;; La fonction blanc? teste si son unique parametre est un caractere
;; blanc.

(define blanc?
  (lambda (c)
    (or (char=? c #\space) (char=? c #\newline) 
        (char=? c #\tab) (char=? c #\return))))

;; La fonction chiffre? teste si son unique parametre est un caractere
;; numerique.

(define chiffre?
  (lambda (c)
    (and (char>=? c #\0) (char<=? c #\9))))

;; La fonction lettre? teste si son unique parametre est une lettre
;; minuscule.

(define lettre?
  (lambda (c)
    (and (char>=? c #\a) (char<=? c #\z))))

;; La fonction symbol-int recoit deux parametres, une liste de
;; caracteres qui debute par un chiffre et une continuation.  La liste
;; de caracteres sera analysee pour en extraire le symbole <int>.  La
;; continuation sera appelee avec deux parametres, la liste des
;; caracteres restants apres le symbole <int> analyse et le symbole
;; <int> qui a ete lu (un entier Scheme qui est la valeur numerique du
;; symbole <int>).

(define symbol-int
  (lambda (inp cont)
    (symbol-int-aux inp cont 0)))

(define symbol-int-aux
  (lambda (inp cont n)
    (if (chiffre? (@ inp))
        (symbol-int-aux ($ inp)
                        cont
                        (+ (* 10 n) (- (char->integer (@ inp)) 48)))
        (cont inp n))))


;; La fonction symbol-id recoit deux parametres, une liste de
;; caracteres qui debute par une lettre minuscule et une continuation.
;; La liste de caracteres sera analysee pour en extraire le prochain
;; symbole (soit un mot cle comme "print" ou un <id>).  La
;; continuation sera appelee avec deux parametres, la liste des
;; caracteres restants apres le symbole analyse et le symbole qui a
;; ete lu (soit un symbole Scheme, comme PRINT-SYM, ou une chaine de
;; caracteres Scheme qui correspond au symbole <id>).

(define symbol-id
  (lambda (inp cont)
    (symbol-id-aux inp cont '())))

(define symbol-id-aux
  (lambda (inp cont lst)
    (if (lettre? (@ inp))
        (symbol-id-aux ($ inp) cont (cons (@ inp) lst))
        (let ((id (list->string (reverse lst))))
          (cond ((string=? id "print")
                 (cont inp 'PRINT-SYM))
                ((string=? id "do")
                 (cont inp 'DO-SYM))
                ((string=? id "while")
                 (cont inp 'WHILE-SYM))
                ((string=? id "if")
                 (cont inp 'IF-SYM))
                ((string=? id "else")
                 (cont inp 'ELSE-SYM))
                (else
                 (cont inp id)))))))

;; -----------------------------------------------------------------
;; ** Analyseur syntaxique ** |
;; ----------------------------

;; La fonction syntax-error retourne le message d'erreur indiquant une
;; erreur de syntaxe.

(define syntax-error
  (lambda ()
    "syntax error\n"))


(define opers-test
  (list (cons 'LSTN 'LT)
      (cons 'LSTE 'LTOE)
      (cons 'GRTN 'GT)
      (cons 'GRTE 'GTOE)
      (cons 'EQUALS 'EQLS)
      (cons 'NOTEQ 'NTEQ)))

(define opers-sum
  (list (cons 'PLUS 'ADD)
      (cons 'MINUS 'SUB)))

(define opers-mult
  (list (cons 'ASTRSK 'MUL)
      (cons 'SLSH 'DIV)
      (cons 'MDLS 'MOD)))

(define opers
  (list (cons 'ADD (lambda (x y) (+ x y)))
        (cons 'SUB (lambda (x y) (- x y)))
        (cons 'MUL (lambda (x y) (* x y)))
        (cons 'DIV (lambda (x y) (quotient x y)))
        (cons 'MOD (lambda (x y) (remainder x y)))
        (cons 'LT (lambda (x y) (< (- x y) 0)))
        (cons 'GT (lambda (x y) (> (- x y) 0)))
        (cons 'EQLS (lambda (x y) (= (- x y) 0)))))

;; La fonction expect recoit trois parametres, un symbole, une liste
;; de caracteres et une continuation.  La liste de caracteres sera
;; analysee pour en extraire le prochain symbole qui doit etre le meme
;; que le premier parametre de la fonction.  Dans ce cas la
;; continuation sera appelee avec un parametre, la liste des
;; caracteres restants apres le symbole analyse.  Si le prochain
;; symbole n'est pas celui qui est attendu, la fonction expect
;; retourne une chaine de caracteres indiquant une erreur de syntaxe.

(define expect
  (lambda (expected-sym inp cont)
    (next-sym inp
              (lambda (inp sym)
                (if (equal? sym expected-sym)
                    (cont inp)
                    (syntax-error))))))

;; La fonction parse recoit deux parametres, une liste de caracteres
;; et une continuation.  La liste de caracteres sera analysee pour
;; verifier qu'elle est conforme a la syntaxe du langage.  Si c'est le
;; cas, la continuation sera appelee avec une S-expression qui
;; represente l'ASA du programme.  Sinon la fonction parse retourne
;; une chaine de caracteres indiquant une erreur de syntaxe.

(define parse
  (lambda (inp cont)
    (<program> inp ;; analyser un <program>
               (lambda (inp program)
                (next-sym inp
                  (lambda (inp2 sym)
                    (cond ((equal? sym 'EOI)
                            (cont program)))))))))

;; -----------------------------------------------------------------

;; Les fonctions suivantes, <program>, <stat>, ... recoivent deux
;; parametres, une liste de caracteres et une continuation.  La liste
;; de caracteres sera analysee pour verifier qu'elle debute par une
;; partie qui est conforme a la categorie correspondante de la
;; grammaire du langage.  Si c'est le cas, la continuation sera
;; appelee avec deux parametres : une liste des caracteres restants du
;; programme et une S-expression qui represente l'ASA de ce fragment
;; de programme.  Sinon ces fonctions retournent une chaine de
;; caracteres indiquant une erreur de syntaxe.

(define <program>
  (lambda (inp cont) 
    (<stat> inp
      (lambda (inp row)
        (next-sym inp 
          (lambda (inp2 sym)
            (cond ((equal? sym 'EOI)
                   (cont inp row))
                  (else 
                    (<program> inp
                      (lambda (inp2 expr)
                        (cont inp2
                              (append row (list expr))))))))))))) ;; analyser un <stat>

;; -----------------------------------------------------------------

(define <stat>
  (lambda (inp cont)
    (next-sym inp
      (lambda (inp2 sym)
        (case sym ;; determiner quel genre de <stat>
          ((PRINT-SYM)
           (<print_stat> inp2 cont))
          ((DO-SYM)
           (<do_stat> inp2 cont))
          ((WHILE-SYM)
           (<while_stat> inp2 cont))
          ((IF-SYM)
           (<if_stat> inp2 cont))
          ((ELSE-SYM)
           (<else_stat> inp2 cont))
          ((LACCO)
           (<acco_stat> inp cont))
          ((RACCO)
           (<acco_stat> inp cont))
          ((SEMI)
           (<semi_stat> inp cont))
        (else
          (<expr_stat> inp cont)))))))

;; -----------------------------------------------------------------

(define <semi_stat>
  (lambda (inp cont)
    (expect 'SEMI ;; doit etre suivi de ";"
            inp
            (lambda (inp)
              (cont inp 'SEQ)))))

;; -----------------------------------------------------------------

(define <if_stat>
  (lambda (inp cont)
    (<paren_expr> inp
                  (lambda (inp2 expr)
                    (<stat> inp2
                            (lambda (inp3 expr2)
                              (next-sym inp3
                                (lambda (inp4 sym)
                                  (if (equal? sym 'ELSE-SYM)
                                    (<else_stat> inp4
                                          (lambda (inp expr3)
                                            (cont inp
                                                  (list 'IF 
                                                        expr
                                                        expr2
                                                        expr3))))
                                      (cont inp3 
                                            (list 'IF
                                                  expr 
                                                  expr2)))))))))))

;; -----------------------------------------------------------------

(define <else_stat>
  (lambda (inp cont)
    (<stat> inp
      (lambda (inp2 expr)
        (cont inp2
              (list 'ELSE 
                     expr))))))


;; -----------------------------------------------------------------

(define <do_stat>
  (lambda (inp cont)
    (<stat> inp
            (lambda (inp2 expr)
              (next-sym inp2
                        (lambda (inp3 sym)
                          (if (equal? sym 'WHILE-SYM)
                            (<while_stat> inp3
                                          (lambda (inp2 expr2)
                                            (<semi_stat> inp2
                                                        (lambda (inp expr3)
                                                          (cont inp (list expr3
                                                                         (list 'DO 
                                                                                expr 
                                                                                expr2))))))))))))))

                ;; ------------------------------------------- ;;

(define <while_stat>
  (lambda (inp cont)
    (<paren_expr> inp
                  (lambda (inp2 expr)
                    (next-sym inp2
                      (lambda (inp3 sym)
                        (cond ((equal? sym 'SEMI)
                               (cont inp2 
                                     (list 'WHILE expr)))
                              (else
                                (<stat> inp2
                                        (lambda (inp3 expr2)
                                          (cont inp3
                                                (list 'WHILE 
                                                       expr 
                                                        expr2))))))))))))

;; -----------------------------------------------------------------

(define <acco_stat>
  (lambda (inp cont)
    (next-sym inp
              (lambda (inp2 sym)
                (if (equal? sym 'LACCO)
                  (<stat> inp2
                          (lambda (inp expr)
                            (cont inp expr)))
                  (cont inp2 (list 'EMPTY)))))))

;; -----------------------------------------------------------------

(define <print_stat>
  (lambda (inp cont)
    (<paren_expr> inp ;; analyser un <paren_expr>
                  (lambda (inp expr)
                    (<semi_stat> inp
                      (lambda (inp expr2)
                              (cont inp (list expr2
                                              (list 'PRINT 
                                                    expr)))))))))

;; -----------------------------------------------------------------

(define <expr_stat>
  (lambda (inp cont)
    (<expr> inp ;; analyser un <expr>
            (lambda (inp expr)
              (next-sym inp
                (lambda (inp2 sym)
                  (if (equal? sym 'SEMI)
                    (<semi_stat> inp
                      (lambda (inp2 expr2)
                          (cont inp2 
                               (list expr2 (list 'EXPR expr)))))
                    (cont inp2 (list 'EXPR expr)))))))))

;; -----------------------------------------------------------------


(define <paren_expr>
  (lambda (inp cont)
    (expect 'LPAR ;; doit debuter par "("
            inp
            (lambda (inp2)
              (<expr> inp2 ;; analyser un <expr>
                      (lambda (inp3 expr)
                        (expect 'RPAR ;; doit etre suivi de ")"
                                inp3
                                (lambda (inp)
                                  (cont inp
                                        expr)))))))))

;; -----------------------------------------------------------------

(define <expr>
  (lambda (inp cont)
    (next-sym inp ;; verifier 1e symbole du <expr>
              (lambda (inp2 sym1)
                (next-sym inp2 ;; verifier 2e symbole du <expr>
                          (lambda (inp3 sym2)
                            (if (and (string? sym1) ;; combinaison "id =" ?
                                     (equal? sym2 'EQ))
                                (<expr> inp3
                                        (lambda (inp expr)
                                          (cont inp
                                                (list 'ASSIGN
                                                      sym1
                                                      expr))))
                                (<test> inp cont))))))))

;; -----------------------------------------------------------------



(define <test>
  (lambda (inp cont)
    (<sum> inp
      (lambda (inp2 expr)
        (next-sym inp2
              (lambda (inp3 sym)
                (if (assoc sym opers-test)
                  (<sum> inp3
                         (lambda (inp expr2)
                            (cont inp
                                  (list (cdr (assoc sym opers-test)) 
                                        expr 
                                        expr2)))))))
                  (cont inp2 expr)))))  

;; -----------------------------------------------------------------

(define <sum>
  (lambda (inp cont)
    (<mult> inp
      (lambda (inp2 expr)
       (next-sym inp2
              (lambda (inp3 sym)
                (if (assoc sym opers-sum)
                  (<mult> inp3
                          (lambda (inp expr2)
                            (cont inp
                                  (list (cdr (assoc sym opers-sum)) 
                                        expr 
                                        expr2))))
                  (cont inp2 expr))))))))

;; -----------------------------------------------------------------

(define <mult>
  (lambda (inp cont)
    (<term> inp
      (lambda (inp2 expr)
       (next-sym inp2
              (lambda (inp3 sym)
                (if (assoc sym opers-mult)
                  (<mult> inp3
                          (lambda (inp expr2)
                            (cont inp
                                  (list (cdr (assoc sym opers-mult)) 
                                        expr 
                                        expr2))))
                  (cont inp2 expr))))))))

;; -----------------------------------------------------------------

(define <term>
  (lambda (inp cont)
    (next-sym inp ;; verifier le premier symbole du <term>
              (lambda (inp2 sym)
                (cond ((string? sym) ;; identificateur?
                       (cont inp2 (list 'VAR sym)))
                      ((number? sym) ;; entier?
                       (cont inp2 (list 'INT sym)))
                      (else
                       (<paren_expr> inp cont)))))))

;; -----------------------------------------------------------------

;; La fonction execute prend en parametre l'ASA du programme a
;; interpreter et retourne une chaine de caracteres qui contient
;; l'accumulation de tout ce qui est affiche par les enonces "print"
;; executes par le programme interprete.

(define execute
  (lambda (ast)
    (exec-step '() ;; etat des variables globales
               ""  ;; sortie jusqu'a date
               ast ;; ASA du programme
               (lambda (env output ast)
                 output)))) ;; retourner l'output pour qu'il soit affiche


(define exec-step
  (lambda (env output ast cont)
    (exec-stat env
               output
               ast
              (lambda (env output ast)
                (if (null? ast)
                  (cont env output ast)
                  (exec-step env output ast cont))))))

(define get-val
  (lambda (env ast)
    (let ((symb (cdr (assoc (car ast) opers))))
    (let ((fst_elem (caadr ast)))
    (let ((sec_elem (caaddr ast)))
    (let ((fst_val (cadadr ast)))
    (let ((sec_val (cadr (caddr ast))))   
    (if (and (equal? fst_elem 'INT)         ;; ex: (+ 2 2)
             (equal? sec_elem 'INT)) 
              (symb fst_val sec_val)     
              (if (and (equal? fst_elem 'VAR)   ;; ex: (+ x x)
                       (equal? sec_elem 'VAR))
                (symb (cdr (assoc fst_val env)) 
                (cdr (assoc sec_val env)))
                (cond ((equal? fst_elem 'VAR)   ;; ex: (+ x 2)
                     (symb (cdr (assoc fst_val env)) sec_val))
                    ((equal? sec_elem 'VAR)     ;; ex: (+ 2 x)
                     (symb fst_val (cdr (assoc sec_val env))))
                    (else 
                      ("syntax error\n"))))))))))))

(trace get-val)
;; La fonction exec-stat fait l'interpretation d'un enonce du
;; programme.  Elle prend quatre parametres : une liste d'association
;; qui contient la valeur de chaque variable du programme, une chaine
;; de caracteres qui contient la sortie accumulee a date, l'ASA de
;; l'enonce a interpreter et une continuation.  La continuation sera
;; appelee avec deux parametres : une liste d'association donnant la
;; valeur de chaque variable du programme apres l'interpretation de
;; l'enonce et une chaine de caracteres qui contient la sortie
;; accumulee apres l'interpretation de l'enonce.

(define exec-stat ;; stats : expr, (paren), { }, if(else), do(while)
  (lambda (env output ast cont)
    (display output)
    (newline)
    (if (null? ast)
      (cont env output ast)
      (if (equal? (car ast) 'SEQ)
        (exec-stat env output (cdr ast) cont)
        (case (caar ast)
            ((SEQ)
              (exec-stat env 
                         output 
                         (cdar ast) 
                         cont))

            ((PRINT)
              (exec-expr env ;; evaluer l'expression du print
                         output
                         (cadar ast)
                         (lambda (env output val)
                         (cont env ;; ajouter le resultat a la sortie
                               (string-append output
                                               (number->string val)
                                               "\n")
                               (cdr ast)))))

            ((EXPR)
              (exec-expr  env ;; evaluer l'expression
                          output
                          (cadar ast)
                          (lambda (env2 output2 val)
                            (if (assoc (car env2) env)
                              (cont env output (cdr ast))
                              (cont (append env (list env2))
                                    output 
                                    (cdr ast))))))


            ((DO)
              (exec-expr env
                         output
                         (cadar ast)
                         cont))

            ((WHILE)
              (exec-expr env
                         output
                         (cadar ast)
                         (lambda (env output val)
                          (if (equal? val #t)
                            (exec-stat env
                                       output
                                       (cddar ast)
                                        cont)
                            (cont env output val)))))    

            ((IF)
              (exec-expr env
                         output
                         (cadar ast)
                         cont))

            ((ELSE)
              (exec-expr env
                         output
                         (cadar ast)
                         cont))

            ((EMPTY)
              (if (null? (cdr ast))
                (cont env output (cdr ast))
                (exec-stat env output (cdr ast) cont)))

            (else
             "internal error (unknown statement AST)\n"))))))

;; La fonction exec-expr fait l'interpretation d'une expression du
;; programme.  Elle prend quatre parametres : une liste d'association
;; qui contient la valeur de chaque variable du programme, une chaine
;; de caracteres qui contient la sortie accumulee a date, l'ASA de
;; l'expression a interpreter et une continuation.  La continuation
;; sera appelee avec deux parametres : une liste d'association donnant
;; la valeur de chaque variable du programme apres l'interpretation de
;; l'expression et une chaine de caracteres qui contient la sortie
;; accumulee apres l'interpretation de l'expression.

(define exec-expr
  (lambda (env output ast cont)
    (let ((symb (car ast)))
    (if (and (assoc symb opers) 
      (equal? (car (assoc symb opers)) symb))  
        (let ((val (get-val env ast)))
        (cont env         ;; pour calculer les opérations primaires ADD, SUM, MUL, DIV, MOD 
              output
              val))
            

      (case (car ast)

        ((INT)
         (cont env
               output
               (cadr ast)))

        ((VAR)
          (cont env
                output
                (if (assoc (cadr ast) env)
                  (cdr (assoc (cadr ast) env))
                  ("variable not assigned to a value \n"))))

        ((ASSIGN)
          (if (not (equal? (cadr ast) 'INT))
            (cont (cons (cadr ast) (cadr (caddr ast)))
                  output
                  (cdddr ast))))

        (else
          "internal error (unknown expression AST)\n"))))))

;; -----------------------------------------------------------------

;;; *** NE MODIFIEZ PAS CETTE SECTION ***

(define main
  (lambda ()
    (print (parse-and-execute (read-all (current-input-port) read-char)))))
    
;;;----------------------------------------------------------------------------
