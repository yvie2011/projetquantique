%{
/*
 * analyseur_lexical.l
 *
 * Analyseur lexical du mini-langage quantique Quanta.
 * Flex lit ce fichier et produit un programme C (lex.yy.c)
 * qui decoupe le texte source en unites lexicales (jetons).
 *
 * Chaque jeton est renvoye a Bison via return NOM_DU_JETON.
 * Pour un identifiant, le lexeme est copie dans yylval.texte.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "jetons.h"

%}

%option noyywrap
%option nounput
%option noinput

/* Expressions regulieres nommees */
lettre          [a-zA-Z]
chiffre         [0-9]
identifiant     {lettre}({lettre}|{chiffre}|_)*
espace          [ \t\r]+

%%

"qubit"         { return JETON_QUBIT; }
"bit"           { return JETON_BIT; }
"porte_h"       { return JETON_PORTE_H; }
"porte_x"       { return JETON_PORTE_X; }
"porte_y"       { return JETON_PORTE_Y; }
"porte_z"       { return JETON_PORTE_Z; }
"porte_cnot"    { return JETON_PORTE_CNOT; }
"mesurer"       { return JETON_MESURER; }
"dans"          { return JETON_DANS; }
"afficher"      { return JETON_AFFICHER; }
"si"            { return JETON_SI; }
"alors"         { return JETON_ALORS; }
"fsi"           { return JETON_FSI; }

{identifiant}   {
                    /*
                     * On alloue une copie du lexeme pour que Bison
                     * puisse l'utiliser dans les actions semantiques.
                     */
                    yylval.texte = strdup(yytext);
                    return JETON_IDENTIFIANT;
                }

";"             { return JETON_POINT_VIRGULE; }
","             { return JETON_VIRGULE; }
"("             { return JETON_PARENTHESE_OUVRANTE; }
")"             { return JETON_PARENTHESE_FERMANTE; }
"=="            { return JETON_EGAL_EGAL; }
"1"             { yylval.entier = 1; return JETON_ENTIER; }
"0"             { yylval.entier = 0; return JETON_ENTIER; }

{espace}        { /* ignorer les espaces et tabulations */ }
\n              { /* ignorer les retours a la ligne */ }

"//".*          { /* commentaire jusqu'a la fin de ligne */ }

.               {
                    fprintf(stderr,
                            "Erreur lexicale : caractere inconnu '%s'\n",
                            yytext);
                }

%%
