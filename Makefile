# Makefile du compilateur Quanta (TP1 - langage quantique)
# Methodologie : Flex (analyse lexicale) + Bison (analyse syntaxique)

NOM_COMPILATEUR = quanta

FICHIERS_OBJETS = analyseur_syntaxique.o analyseur_lexical.o \
                  table_symboles.o generation_code.o

.PHONY: all clean test

all: $(NOM_COMPILATEUR)

# Bison produit le parseur C et le fichier jetons.h (definitions des jetons)
analyseur_syntaxique.c jetons.h: analyseur_syntaxique.y
	bison --defines=jetons.h -v -o analyseur_syntaxique.c analyseur_syntaxique.y

# Flex produit l'analyseur lexical C
analyseur_lexical.c: analyseur_lexical.l jetons.h
	flex -o analyseur_lexical.c analyseur_lexical.l

analyseur_syntaxique.o: analyseur_syntaxique.c table_symboles.h generation_code.h
	gcc -Wall -Wextra -c analyseur_syntaxique.c -o analyseur_syntaxique.o

analyseur_lexical.o: analyseur_lexical.c jetons.h
	gcc -Wall -Wextra -c analyseur_lexical.c -o analyseur_lexical.o

table_symboles.o: table_symboles.c table_symboles.h
	gcc -Wall -Wextra -c table_symboles.c -o table_symboles.o

generation_code.o: generation_code.c generation_code.h table_symboles.h
	gcc -Wall -Wextra -c generation_code.c -o generation_code.o

$(NOM_COMPILATEUR): $(FICHIERS_OBJETS)
	gcc $(FICHIERS_OBJETS) -o $(NOM_COMPILATEUR) -lfl

test: $(NOM_COMPILATEUR)
	./$(NOM_COMPILATEUR) exemples/bell.qta
	@echo "----- Contenu de sortie.qasm -----"
	@cat sortie.qasm

clean:
	rm -f $(NOM_COMPILATEUR) $(FICHIERS_OBJETS) \
	      analyseur_syntaxique.c analyseur_lexical.c \
	      jetons.h analyseur_syntaxique.output sortie.qasm
