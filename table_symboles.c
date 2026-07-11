/*
 * table_symboles.c
 *
 * Implementation de la table des symboles du compilateur quantique.
 */

#include <stdio.h>
#include <string.h>
#include "table_symboles.h"

/* Tableau global contenant toutes les entrees */
static EntreeSymbole table[TAILLE_MAX_TABLE];

/* Nombre d'entrees actuellement utilisees */
static int nombre_entrees = 0;

/* Compteurs pour attribuer les indices de registres */
static int compteur_qubits = 0;
static int compteur_bits_classiques = 0;

void initialiser_table_symboles(void)
{
    int i;

    nombre_entrees = 0;
    compteur_qubits = 0;
    compteur_bits_classiques = 0;

    for (i = 0; i < TAILLE_MAX_TABLE; i++) {
        table[i].nom[0] = '\0';
        table[i].est_declare = 0;
        table[i].indice_registre = -1;
    }
}

int declarer_symbole(const char *nom, NatureSymbole nature)
{
    EntreeSymbole *existant;

    if (nom == NULL) {
        return -1;
    }

    existant = rechercher_symbole(nom);
    if (existant != NULL) {
        fprintf(stderr,
                "Erreur semantique : le symbole '%s' est deja declare.\n",
                nom);
        return -1;
    }

    if (nombre_entrees >= TAILLE_MAX_TABLE) {
        fprintf(stderr, "Erreur semantique : table des symboles pleine.\n");
        return -1;
    }

    strncpy(table[nombre_entrees].nom, nom, LONGUEUR_MAX_NOM - 1);
    table[nombre_entrees].nom[LONGUEUR_MAX_NOM - 1] = '\0';
    table[nombre_entrees].nature = nature;
    table[nombre_entrees].est_declare = 1;

    if (nature == NATURE_QUBIT) {
        table[nombre_entrees].indice_registre = compteur_qubits;
        compteur_qubits++;
    } else {
        table[nombre_entrees].indice_registre = compteur_bits_classiques;
        compteur_bits_classiques++;
    }

    nombre_entrees++;
    return 0;
}

EntreeSymbole *rechercher_symbole(const char *nom)
{
    int i;

    if (nom == NULL) {
        return NULL;
    }

    for (i = 0; i < nombre_entrees; i++) {
        if (strcmp(table[i].nom, nom) == 0) {
            return &table[i];
        }
    }

    return NULL;
}

int verifier_nature_symbole(const char *nom, NatureSymbole nature_attendue)
{
    EntreeSymbole *entree;

    entree = rechercher_symbole(nom);
    if (entree == NULL) {
        fprintf(stderr,
                "Erreur semantique : le symbole '%s' n'est pas declare.\n",
                nom);
        return -1;
    }

    if (entree->nature != nature_attendue) {
        if (nature_attendue == NATURE_QUBIT) {
            fprintf(stderr,
                    "Erreur semantique : '%s' n'est pas un qubit.\n",
                    nom);
        } else {
            fprintf(stderr,
                    "Erreur semantique : '%s' n'est pas un bit classique.\n",
                    nom);
        }
        return -1;
    }

    return 0;
}

int nombre_qubits(void)
{
    return compteur_qubits;
}

int nombre_bits_classiques(void)
{
    return compteur_bits_classiques;
}
