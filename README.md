# IFT2035_TP2_Scheme

IFT2035 – Travail pratique #2 – 2018.11.18
PROGRAMMATION FONCTIONNELLE
Marc Feeley

Le TP2 a pour but de vous faire pratiquer la programmation fonctionnelle et en particulier les concepts
suivants : les fonctions r´ecursives, la forme it´erative, les continuations, et le traitement de liste. Vous devez
r´ealiser en Scheme en style fonctionnel un interpr`ete pour le langage du TP1 (avec quelques simplifications)
et comparer l’approche fonctionnelle avec l’approche imp´erative.
Pour ce travail vous devez utiliser uniquement le sous-ensemble fonctionnel de Scheme (en particulier,
vous ne devez pas utiliser les formes-sp´eciales “set!” et “begin” dans votre programme, ni les fonctions
pr´ed´efinies contenant un point d’exclamation, comme “set-car!” et “vector-set!”). Vous pouvez
cependant utiliser les fonctions “vector-set” et “list-set” qui sont similaires `a “vector-set!” et
“list-set!” mais qui sont purement fonctionnelles (elles ne modifient pas le vecteur ou la liste mais
retournent un nouveau vecteur ou liste). Pour utiliser ces fonctions, ainsi que d’autres fonctions pr´ed´efinies
sur les listes (“fold”, “fold-right”, “iota”, “make-list”, “take”, “drop”, “last”, etc), vous aurez
besoin de la version v4.9.1 de Gambit disponible sur github et http://gambitscheme.org.
Le but du travail ´etant de vous faire pratiquer les concepts de programmation fonctionnelle, utilisez les
concepts que nous avons vus en classe lorsque c’est appropri´e (fonctions d’ordre sup´erieur, forme it´erative,
continuations, etc). L’´el´egance de votre codage est un facteur important dans l’´evaluation de ce travail.
Vous avez `a r´ealiser un programme en Scheme ainsi que r´ediger un rapport contenant une analyse du
programme et une comparaison du style fonctionnel et le style imp´eratif.

1 Programmation
Le travail demand´e consiste `a r´ealiser en Scheme en style fonctionnel un interpr`ete pour le langage d´efini
pour le TP1 mais avec quelques simplifications. Votre interpr`ete fera la lecture du code source du programme `a ex´ecuter, puis analysera ce code pour construire sa repr´esentation sous forme d’un arbre de
syntaxe abstraite (ASA), puis fera l’ex´ecution du programme directement `a partir de l’ASA.
Nous vous fournissons un squelette du programme (petit-interp.scm sur Studium) qui fait la lecture du code source, une analyse syntaxique partielle et une ex´ecution de l’ASA partielle. Seul l’´enonc´e
“print” avec une constante en param`etre est implant´e, par exemple le programme “print(42);” ex´ecutera
correctement.
Vous ne devez pas changer la lecture du code source qui est dans une zone bien d´elimit´ee `a la fin
du squelette que nous vous fournissons. Vous pouvez modifier le reste du code comme vous le voulez,
voire mˆeme le remplacer totalement par votre propre code, `a condition que votre programme respecte la
sp´ecification dans cet ´enonc´e (entre autre il faut que l’ex´ecution donne la bonne sortie et que vous limitiez
votre codage au sous-ensemble fonctionnel de Scheme). Dans le squelette le traitement se fait en utilisant
le “Continuation Passing Style” (CPS) pour d´efinir des fonctions qui “retournent” plus d’une valeur, mais
si vous pr´ef´erez un style o`u les fonctions retournent une structure de donn´ee contenant les r´esultats de la
fonction vous pouvez r´ecrire les fonctions pertinentes du squelette. La solution du professeur est `a peu
pr`es 200 lignes de code plus longue que le squelette.
Votre interpr`ete sera ex´ecut´e par Gambit avec la commande suivante :
% gsi petit-interp.scm < prog.c
Cela fera en sorte que le contenu du fichier prog.c soit lu par le programme petit-interp.scm, puis
analys´e, puis ex´ecut´e, ce qui affichera `a la sortie les valeurs imprim´ees avec “print” ou bien un message
d’erreur si prog.c est syntaxiquement invalide ou cause une erreur `a l’ex´ecution (comme une division par
z´ero).

2 Langage
Votre interpr`ete doit accepter le langage sp´ecifi´e par la grammaire suivante.
<program> ::= <stat>
<stat> ::= "if" <paren_expr> <stat>
| "if" <paren_expr> <stat> "else" <stat>
| "while" <paren_expr> <stat>
| "do" <stat> "while" <paren_expr> ";"
| ";"
| "{" { <stat> } "}"
| <expr> ";"
| "print" <paren_expr> ";"
<expr> ::= <test>
| <id> "=" <expr>
<test> ::= <sum>
| <sum> "<" <sum>
| <sum> "<=" <sum>
| <sum> ">" <sum>
| <sum> ">=" <sum>
| <sum> "==" <sum>
| <sum> "!=" <sum>
<sum> ::= <mult>
| <sum> "+" <mult>
| <sum> "-" <mult>
<mult> ::= <term>
| <mult> "*" <term>
| <mult> "/" <term>
| <mult> "%" <term>
<term> ::= <id> ;; les identificateurs ont une longueur quelconque
| <int> ;; les constantes entieres ont une longueur quelconque
| <paren_expr>
<paren_expr> ::= "(" <expr> ")"
Donc, par rapport au langage du TP1, les ´etiquettes ont ´et´e retir´ees du langage et les identificateurs
et constantes enti`eres ont une longueur quelconque.
Tout comme pour le TP1 les op´erateurs “/” et “%” correspondent `a la division enti`ere et le reste apr`es
division, c’est-`a-dire l’expression “14/4” s’´evalue `a 3 et “14%4” s’´evalue `a 2 (ce sont les mˆemes calculs que
“(quotient 14 4)” et “(remainder 14 4)” en Scheme). Les calculs se font donc exclusivement avec des
nombres entiers. D’autre part, il n’y a pas de limite sur la taille des entiers calcul´es (`a part la m´emoire
disponible sur l’ordinateur). Cela ne pose pas vraiment un probl`eme d’implantation car le langage Scheme
ne place pas de limite sur la taille des entiers. Il faut cependant que l’interpr`ete d´etecte les cas de division
par z´ero et termine l’ex´ecution du programme apr`es avoir affich´e un message explicatif.
Voici un exemple d’utilisation de l’interpr`ete. Si le fichier prog.c contient
{
  nb = 2;
  i = 1;
  while (i < 9) {
  nb = nb*nb;
  i = i+1;
  print(nb);
  }
}
alors l’ex´ecution de
% gsi petit-interp.scm < prog.c
doit donner la sortie
4
16
256
65536
4294967296
18446744073709551616
340282366920938463463374607431768211456
115792089237316195423570985008687907853269984665640564039457584007913129639936
Votre analyseur syntaxique (la fonction parse du squelette) doit construire un ASA du programme
source. En Scheme c’est assez naturel d’utiliser des S-expressions pour les ASA. Une S-expression c’est
une liste qui contient comme premier ´el´ement un symbole qui indique la nature de ce noeud de l’ASA,
et les ´el´ements restants sont les attributs et/ou enfants de ce noeud. Par exemple, la S-expression
(PRINT (INT 42)) est l’ASA du programme source “print(42);”. Un exemple plus complexe est le
programme prog.c ci-dessus dont l’ASA est :
(SEQ (EXPR (ASSIGN "nb" (INT 2)))
(SEQ (EXPR (ASSIGN "i" (INT 1)))
(SEQ (WHILE (LT (VAR "i") (INT 9))
(SEQ (EXPR (ASSIGN "nb" (MUL (VAR "nb") (VAR "nb"))))
(SEQ (EXPR (ASSIGN "i" (ADD (VAR "i") (INT 1))))
(SEQ (PRINT (VAR "nb"))
(EMPTY)))))
(EMPTY))))
Le coeur de votre interpr`ete (la fonction execute du squelette) fait l’ex´ecution du programme `a partir
de son ASA. Cette fonction va donc parcourir r´ecursivement la S-expression pour ex´ecuter les ´enonc´es et
expressions qui s’y trouvent. L’interpr`ete doit gˆerer une structure d’environnement (par exemple une liste
d’association) qui indique la valeur de chaque variable du programme. L’interpr`ete doit aussi accumuler
(par exemple dans une chaˆıne de caract`eres) toutes les sorties effectu´ees par les “print” ex´ecut´es pour
qu’`a la fin de l’ex´ecution toutes les sorties accumul´ees soient affich´ees (par la fonction main du squelette).
Votre interpr`ete doit ˆetre robuste et ne pas terminer abruptement avec une erreur autre que l’affichage
de messages d’erreur de syntaxe ou de division par z´ero du programme interpr´et´e.
Votre code Scheme doit ˆetre enti`erement contenu dans un fichier dont le nom est “petit-interp.scm”.
Vous devez utiliser le fichier “petit-interp.scm” de la page Studium du cours comme point de d´epart
et seulement modifier la premi`ere section. Pour faciliter le d´eboguage, l’ex´ecution de l’interpr`ete peut se
faire en lan¸cant gsi avec la commande “gsi -:dar petit-interp.scm”, ou vous pouvez faire “chmod
+x petit-interp.scm” suivi de “./petit-interp.scm”. Cela vous donnera une REPL de d´eboguage
lorsqu’il y a une erreur d’ex´ecution dans votre code. N’oubliez pas aussi que l’utilisation de “trace” et
d’appels `a “pp” peut aider `a comprendre l’ex´ecution de votre code. Vous avez avantage `a utiliser emacs
pour ´editer vos fichiers et faire le d´eboguage. Les instructions relatives `a l’utilisation de Gambit dans
emacs sont donn´ees ici : http://www.iro.umontreal.ca/~gambit/doc/gambit.html#Emacs-interface.

3 Rapport
Vous devez r´ediger un rapport qui:
1. Explique bri`evement le fonctionnement g´en´eral du programme (maximum de 1 page au total).
2. Explique comment les probl`emes de programmation suivants ont ´et´e r´esolus (en 2 `a 3 pages au total):
(a) comment se fait l’analyse syntaxique du programme interpr´et´e
(b) comment se fait l’interpr´etation du programme interpr´et´e (autant les ´enonc´es que les expressions)
(c) comment se fait l’interpr´etation des affectations aux variables et la gestion de l’environnement
(d) comment se fait l’interpr´etation des ´enonc´es “print”
(e) comment se fait le traitement des erreurs
3. Compare votre exp´erience de d´eveloppement avec le TP1 (en 1 `a 2 pages au total). Combien de lignes
de code ont vos programmes C et Scheme? Sans tenir compte de votre niveau de connaissance des
langages C et Scheme, quels sont les traitements qui ont ´et´e plus faciles et plus difficiles `a exprimer
en Scheme? Ind´ependamment des particularit´es syntaxiques de Scheme, pour quelles parties du
programme l’utilisation du style de programmation fonctionnel a-t’il ´et´e b´en´efique et pour quelles
parties d´etrimental? Pour quelles parties avez vous utilis´e des r´ecursions en forme it´erative? Pour
quelles parties avez vous utilis´e des continuations?

4 Evaluation ´
• Ce travail compte pour 15 points dans la note finale du cours. Indiquez vos noms clairement au
d´ebut du programme. Vous devez faire le travail par groupes de 2 personnes. Vous devez
confirmer la composition de votre ´equipe (noms des co´equipiers) au d´emonstrateur. Si
vous ne trouvez pas de partenaire d’ici quelques jours, parlez-en au d´emonstrateur.
• Le programme sera ´evalu´e sur 8 points et le rapport sur 7 points. Un programme qui plante `a
l’ex´ecution, mˆeme dans une situation extrˆeme, se verra attribuer z´ero sur 8 (c’est un incitatif `a bien
tester votre programme). Assurez-vous de pr´evoir toutes les situations d’erreur.
• Vous devez remettre un fichier “.tar” qui contient uniquement deux fichiers : votre rapport (qui doit
se nommer rapport.pdf) et le programme (qui doit se nommer petit-interp.scm). La remise doit
se faire au plus tard `a 23h55 vendredi le 14 d´ecembre sur le site Studium du cours. En supposant que
vos deux fichiers sont dans le r´epertoire tp2, vous pouvez cr´eer le fichier “.tar” avec la commande
“tar cf tp2.tar tp2”.
• L’´el´egance et la lisibilit´e du code, l’exactitude et la performance, la lisibilit´e du rapport, et l’utilisation
d’un fran¸cais sans fautes sont des crit`eres d’´evaluation.
5 Annexe
Le programme suivant peut vous ˆetre utile pour tester votre interpr`ete :
{
  n = 1000;
  one = 1;
  while (n>0) { one = one*10; n = n-1; }
  a = one;
  x = one*one/2;
  r = x; while ((n = (r+x/r)/2) < r) r = n;
  t = one/4;
  p = 1;
  while (a != r) {
  x = a*r;
  y = (a+r)/2;
  z = y-a;
  a = y;
  r = x; while ((n = (r+x/r)/2) < r) r = n;
  t = t - p*z*z/one;
  p = p*2;
  }
  x = a+r;
  print(x*x/(4*t));
}
