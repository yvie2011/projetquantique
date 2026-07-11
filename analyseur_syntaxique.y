%{
/*
 * analyseur_syntaxique.y
 *
 * Analyseur syntaxique et generation de code du langage Quanta.
 * Bison lit ce fichier et produit un parseur C.
 *
 * Methodologie (seminaire Messi / Broto) :
 *   1. Flex fournit les jetons (yylex)
 *   2. Bison verifie la grammaire (yyparse)
 *   3. Les actions entre accolades realisent l'analyse semantique
 *      et la generation de code cible (ici OpenQASM)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "table_symboles.h"
#include "generation_code.h"

/* Prototypes fournis par Flex / utilises par Bison */
int yylex(void);
void yyerror(const char *message);

/* Compteur pour etiqueter les blocs conditionnels generes */
static int compteur_condition = 0;

/* Indique si une erreur semantique a ete detectee */
static int erreur_semantique = 0;

%}

/* Definition du type semantique des symboles de la grammaire */
%union {
    char *texte;
    int entier;
}

/* Jetons sans valeur associee */
%token JETON_QUBIT JETON_BIT
%token JETON_PORTE_H JETON_PORTE_X JETON_PORTE_Y JETON_PORTE_Z
%token JETON_PORTE_CNOT
%token JETON_MESURER JETON_DANS JETON_AFFICHER
%token JETON_SI JETON_ALORS JETON_FSI
%token JETON_POINT_VIRGULE JETON_VIRGULE
%token JETON_PARENTHESE_OUVRANTE JETON_PARENTHESE_FERMANTE
%token JETON_EGAL_EGAL

/* Jetons avec valeur */
%token <texte> JETON_IDENTIFIANT
%token <entier> JETON_ENTIER

/* Axiome de la grammaire */
%start programme

%%

programme
    : liste_instructions
      {
          generer_declarations_registres();
          if (!erreur_semantique) {
              printf("Compilation terminee : aucune erreur de syntaxe detectee.\n");
          }
      }
    ;

liste_instructions
    : /* programme vide accepte */
    | liste_instructions instruction
    ;

instruction
    : declaration_qubit
    | declaration_bit
    | application_porte
    | instruction_mesure
    | instruction_affichage
    | bloc_conditionnel
    ;

declaration_qubit
    : JETON_QUBIT JETON_IDENTIFIANT JETON_POINT_VIRGULE
      {
          if (declarer_symbole($2, NATURE_QUBIT) != 0) {
              erreur_semantique = 1;
          }
          free($2);
      }
    ;

declaration_bit
    : JETON_BIT JETON_IDENTIFIANT JETON_POINT_VIRGULE
      {
          if (declarer_symbole($2, NATURE_BIT_CLASSIQUE) != 0) {
              erreur_semantique = 1;
          }
          free($2);
      }
    ;

application_porte
    : JETON_PORTE_H JETON_IDENTIFIANT JETON_POINT_VIRGULE
      {
          if (verifier_nature_symbole($2, NATURE_QUBIT) != 0) {
              erreur_semantique = 1;
          } else {
              generer_porte_unaire("h", $2);
          }
          free($2);
      }
    | JETON_PORTE_X JETON_IDENTIFIANT JETON_POINT_VIRGULE
      {
          if (verifier_nature_symbole($2, NATURE_QUBIT) != 0) {
              erreur_semantique = 1;
          } else {
              generer_porte_unaire("x", $2);
          }
          free($2);
      }
    | JETON_PORTE_Y JETON_IDENTIFIANT JETON_POINT_VIRGULE
      {
          if (verifier_nature_symbole($2, NATURE_QUBIT) != 0) {
              erreur_semantique = 1;
          } else {
              generer_porte_unaire("y", $2);
          }
          free($2);
      }
    | JETON_PORTE_Z JETON_IDENTIFIANT JETON_POINT_VIRGULE
      {
          if (verifier_nature_symbole($2, NATURE_QUBIT) != 0) {
              erreur_semantique = 1;
          } else {
              generer_porte_unaire("z", $2);
          }
          free($2);
      }
    | JETON_PORTE_CNOT JETON_IDENTIFIANT JETON_VIRGULE JETON_IDENTIFIANT JETON_POINT_VIRGULE
      {
          if (verifier_nature_symbole($2, NATURE_QUBIT) != 0
              || verifier_nature_symbole($4, NATURE_QUBIT) != 0) {
              erreur_semantique = 1;
          } else {
              generer_porte_cnot($2, $4);
          }
          free($2);
          free($4);
      }
    ;

instruction_mesure
    : JETON_MESURER JETON_IDENTIFIANT JETON_DANS JETON_IDENTIFIANT JETON_POINT_VIRGULE
      {
          if (verifier_nature_symbole($2, NATURE_QUBIT) != 0
              || verifier_nature_symbole($4, NATURE_BIT_CLASSIQUE) != 0) {
              erreur_semantique = 1;
          } else {
              generer_mesure($2, $4);
          }
          free($2);
          free($4);
      }
    ;

instruction_affichage
    : JETON_AFFICHER JETON_IDENTIFIANT JETON_POINT_VIRGULE
      {
          if (verifier_nature_symbole($2, NATURE_BIT_CLASSIQUE) != 0) {
              erreur_semantique = 1;
          } else {
              generer_affichage($2);
          }
          free($2);
      }
    ;

/*
 * Bloc conditionnel classique sur un bit de mesure :
 *   si (m0 == 1) alors
 *     porte_x q0;
 *   fsi
 *
 * En OpenQASM 2.0, on genere un commentaire structurel et
 * une instruction conditionnelle si le simulateur le permet.
 */
bloc_conditionnel
    : JETON_SI JETON_PARENTHESE_OUVRANTE JETON_IDENTIFIANT JETON_EGAL_EGAL JETON_ENTIER JETON_PARENTHESE_FERMANTE
      JETON_ALORS
      {
          EntreeSymbole *bit;
          char tampon[128];

          compteur_condition++;
          if (verifier_nature_symbole($3, NATURE_BIT_CLASSIQUE) != 0) {
              erreur_semantique = 1;
              definir_prefixe_conditionnel("");
          } else {
              generer_declarations_registres();
              bit = rechercher_symbole($3);
              fprintf(obtenir_fichier_sortie(),
                      "// debut condition %d\n",
                      compteur_condition);
              snprintf(tampon,
                       sizeof(tampon),
                       "if(c[%d]==%d) ",
                       bit->indice_registre,
                       $5);
              definir_prefixe_conditionnel(tampon);
          }
          free($3);
      }
      liste_instructions_condition
      JETON_FSI
      {
          definir_prefixe_conditionnel("");
          fprintf(obtenir_fichier_sortie(),
                  "// fin condition %d\n",
                  compteur_condition);
      }
    ;

liste_instructions_condition
    : application_porte
    | liste_instructions_condition application_porte
    ;

%%

/*
 * yyerror : appelee automatiquement par Bison en cas d'erreur de syntaxe.
 * Parametre message : description fournie par le parseur.
 */
void yyerror(const char *message)
{
    fprintf(stderr, "Erreur de syntaxe : %s\n", message);
}

/*
 * Point d'entree du compilateur.
 * Usage : ./quanta fichier_source.qta
 * Produit : sortie.qasm
 */
int main(int argc, char **argv)
{
    extern FILE *yyin;
    int code_retour;

    if (argc != 2) {
        fprintf(stderr, "Usage : %s fichier_source.qta\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        fprintf(stderr, "Impossible d'ouvrir le fichier source '%s'.\n", argv[1]);
        return 1;
    }

    initialiser_table_symboles();

    if (ouvrir_fichier_sortie("sortie.qasm") != 0) {
        fclose(yyin);
        return 1;
    }

    code_retour = yyparse();

    fermer_fichier_sortie();
    fclose(yyin);

    if (code_retour != 0 || erreur_semantique) {
        fprintf(stderr, "Compilation echouee.\n");
        return 1;
    }

    printf("Fichier genere : sortie.qasm\n");
    return 0;
}
