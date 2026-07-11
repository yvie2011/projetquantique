/*
 * table_symboles.h
 *
 * Table des symboles pour le mini-langage quantique.
 * Elle sert a l'analyse semantique : verifier qu'un identifiant
 * a ete declare avant d'etre utilise, et connaitre sa nature
 * (qubit ou bit classique issu d'une mesure).
 */

#ifndef TABLE_SYMBOLES_H
#define TABLE_SYMBOLES_H

/* Nombre maximal de symboles memorises dans la table */
#define TAILLE_MAX_TABLE 64

/* Longueur maximale d'un nom d'identifiant */
#define LONGUEUR_MAX_NOM 64

/*
 * Nature d'un symbole dans le langage quantique.
 * Un qubit est une variable quantique.
 * Un bit classique stocke le resultat d'une mesure.
 */
typedef enum {
    NATURE_QUBIT,
    NATURE_BIT_CLASSIQUE
} NatureSymbole;

/*
 * Une entree de la table des symboles.
 * indice_registre : numero attribue au symbole pour la generation de code
 * (q[0], q[1], ... ou c[0], c[1], ...).
 */
typedef struct {
    char nom[LONGUEUR_MAX_NOM];
    NatureSymbole nature;
    int indice_registre;
    int est_declare;
} EntreeSymbole;

/*
 * Initialise la table des symboles (vide au demarrage).
 */
void initialiser_table_symboles(void);

/*
 * Declare un nouveau symbole.
 * Retourne 0 en cas de succes, -1 si le symbole existe deja
 * ou si la table est pleine.
 */
int declarer_symbole(const char *nom, NatureSymbole nature);

/*
 * Recherche un symbole par son nom.
 * Retourne un pointeur vers l'entree, ou NULL s'il est inconnu.
 */
EntreeSymbole *rechercher_symbole(const char *nom);

/*
 * Verifie qu'un symbole existe et possede la nature attendue.
 * Affiche un message d'erreur semantique et retourne -1 en cas d'echec.
 * Retourne 0 si tout est correct.
 */
int verifier_nature_symbole(const char *nom, NatureSymbole nature_attendue);

/*
 * Nombre de qubits declares (utile pour generer qreg q[N]).
 */
int nombre_qubits(void);

/*
 * Nombre de bits classiques declares (utile pour generer creg c[N]).
 */
int nombre_bits_classiques(void);

#endif /* TABLE_SYMBOLES_H */
