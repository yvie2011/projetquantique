/*
 * generation_code.c
 *
 * Generation du fichier cible OpenQASM a partir des constructions
 * reconnues par l'analyseur syntaxique.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "generation_code.h"

/* Fichier dans lequel on ecrit le code genere */
static FILE *fichier_sortie = NULL;

/* Indique si les registres qreg/creg ont deja ete ecrits */
static int registres_deja_generes = 0;

/* Prefixe optionnel pour une instruction conditionnelle OpenQASM */
static char prefixe_conditionnel[128] = "";

int ouvrir_fichier_sortie(const char *nom_fichier)
{
    fichier_sortie = fopen(nom_fichier, "w");
    if (fichier_sortie == NULL) {
        fprintf(stderr,
                "Impossible d'ouvrir le fichier de sortie '%s'.\n",
                nom_fichier);
        return -1;
    }

    registres_deja_generes = 0;

    fprintf(fichier_sortie, "// Code genere par le compilateur Quanta\n");
    fprintf(fichier_sortie, "OPENQASM 2.0;\n");
    fprintf(fichier_sortie, "include \"qelib1.inc\";\n\n");

    return 0;
}

void fermer_fichier_sortie(void)
{
    if (fichier_sortie != NULL) {
        fclose(fichier_sortie);
        fichier_sortie = NULL;
    }
}

void generer_declarations_registres(void)
{
    int nq;
    int nc;

    if (fichier_sortie == NULL || registres_deja_generes) {
        return;
    }

    nq = nombre_qubits();
    nc = nombre_bits_classiques();

    if (nq > 0) {
        fprintf(fichier_sortie, "qreg q[%d];\n", nq);
    }
    if (nc > 0) {
        fprintf(fichier_sortie, "creg c[%d];\n", nc);
    }
    fprintf(fichier_sortie, "\n");

    registres_deja_generes = 1;
}

void generer_porte_unaire(const char *nom_porte, const char *nom_qubit)
{
    EntreeSymbole *entree;

    generer_declarations_registres();

    entree = rechercher_symbole(nom_qubit);
    if (entree == NULL) {
        return;
    }

    fprintf(fichier_sortie,
            "%s%s q[%d];\n",
            prefixe_conditionnel,
            nom_porte,
            entree->indice_registre);
}

void generer_porte_cnot(const char *nom_controle, const char *nom_cible)
{
    EntreeSymbole *controle;
    EntreeSymbole *cible;

    generer_declarations_registres();

    controle = rechercher_symbole(nom_controle);
    cible = rechercher_symbole(nom_cible);
    if (controle == NULL || cible == NULL) {
        return;
    }

    fprintf(fichier_sortie,
            "%scx q[%d],q[%d];\n",
            prefixe_conditionnel,
            controle->indice_registre,
            cible->indice_registre);
}

void generer_mesure(const char *nom_qubit, const char *nom_bit)
{
    EntreeSymbole *qubit;
    EntreeSymbole *bit;

    generer_declarations_registres();

    qubit = rechercher_symbole(nom_qubit);
    bit = rechercher_symbole(nom_bit);
    if (qubit == NULL || bit == NULL) {
        return;
    }

    fprintf(fichier_sortie,
            "measure q[%d] -> c[%d];\n",
            qubit->indice_registre,
            bit->indice_registre);
}

void generer_affichage(const char *nom_bit)
{
    EntreeSymbole *bit;

    generer_declarations_registres();

    bit = rechercher_symbole(nom_bit);
    if (bit == NULL) {
        return;
    }

    fprintf(fichier_sortie,
            "// afficher le bit classique c[%d] (nom source : %s)\n",
            bit->indice_registre,
            nom_bit);
}

FILE *obtenir_fichier_sortie(void)
{
    return fichier_sortie;
}

void definir_prefixe_conditionnel(const char *prefixe)
{
    if (prefixe == NULL) {
        prefixe_conditionnel[0] = '\0';
        return;
    }

    strncpy(prefixe_conditionnel, prefixe, sizeof(prefixe_conditionnel) - 1);
    prefixe_conditionnel[sizeof(prefixe_conditionnel) - 1] = '\0';
}
