/*
 * generation_code.h
 *
 * Generation de code cible pour le mini-langage quantique.
 * Le code produit est un fichier OpenQASM 2.0 simplifie
 * (sortie.qasm), analogue a test.asm dans la methodologie du seminaire.
 */

#ifndef GENERATION_CODE_H
#define GENERATION_CODE_H

#include <stdio.h>
#include "table_symboles.h"

/*
 * Ouvre le fichier de sortie et ecrit l'en-tete OpenQASM.
 * Retourne 0 en cas de succes, -1 en cas d'echec d'ouverture.
 */
int ouvrir_fichier_sortie(const char *nom_fichier);

/*
 * Ferme le fichier de sortie apres generation complete.
 */
void fermer_fichier_sortie(void);

/*
 * Ecrit la declaration des registres quantiques et classiques
 * une fois que toutes les declarations du programme source
 * ont ete analysees. A appeler avant la premiere instruction
 * executable, ou a la fin des declarations.
 */
void generer_declarations_registres(void);

/*
 * Genere l'application d'une porte a un qubit.
 * nom_porte : "h", "x", "y" ou "z"
 */
void generer_porte_unaire(const char *nom_porte, const char *nom_qubit);

/*
 * Genere une porte CNOT controlee (controle, cible).
 */
void generer_porte_cnot(const char *nom_controle, const char *nom_cible);

/*
 * Genere une mesure : measure q[i] -> c[j]
 */
void generer_mesure(const char *nom_qubit, const char *nom_bit);

/*
 * Genere un commentaire indiquant l'affichage d'un bit classique.
 * OpenQASM ne possede pas d'instruction d'affichage native ;
 * on produit donc une annotation exploitable par un simulateur.
 */
void generer_affichage(const char *nom_bit);

/*
 * Acces au fichier de sortie (utilise par le parseur si besoin).
 */
FILE *obtenir_fichier_sortie(void);

/*
 * Active un prefixe conditionnel OpenQASM du type if(c[i]==v)
 * devant la prochaine porte generee. Chaine vide pour desactiver.
 */
void definir_prefixe_conditionnel(const char *prefixe);

#endif /* GENERATION_CODE_H */
