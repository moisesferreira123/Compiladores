#include <cstdio>

extern int yyparse();

int main() {
    printf("Starting parser...\n");
    int result = yyparse();
    printf("Parsing finished with code %d\n", result);
    return result;
}
