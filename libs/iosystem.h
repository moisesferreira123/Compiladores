#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Lê um número inteiro
int readint_1() {
   int i;
   if (scanf("%d", &i) == 1)
      return i;
   else
      return 0; // ou trate erro de leitura
}

// Lê um número de ponto flutuante
float readfloat_1() {
   float f;
   if (scanf("%f", &f) == 1)
      return f;
   else
      return 0.0f; // ou trate erro de leitura
}

// Lê um caractere e retorna seu valor ASCII, ou -1 em caso de EOF
int readchar_1() {
   int c = getchar();
   return c != EOF ? c : -1;
}

// Lê uma string (até o primeiro espaço em branco)
char* readstring_1() {
   char* buffer = (char*)malloc(1024);
   if (!buffer)
      return NULL;
   scanf("%1023s", buffer);
   return buffer;
}

// Lê uma linha (até \n ou EOF)
char* readline_1() {
   char* buffer = (char*)malloc(1024);
   if (!buffer)
      return NULL;
   if (fgets(buffer, 1024, stdin)) {
      size_t len = strlen(buffer);
      if (len > 0 && buffer[len - 1] == '\n') {
         buffer[len - 1] = '\0'; // remove o \n
      }
      return buffer;
   }
   free(buffer);
   return NULL;
}

// Escreve um número inteiro
void printint_1(int i) { printf("%d", i); }

// Escreve um número de ponto flutuante
void printfloat_1(float f) { printf("%f", f); }

// Escreve uma string
void printstr_1(const char* s) { printf("%s", s); }

// Escreve uma string seguida de uma nova linha
void printline_1(const char* s) { printf("%s\n", s); }
