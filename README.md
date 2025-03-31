# Compilador

## Erros conhecidos
- [ ] Como definir quais escopos podem "sobrescrever" símbolos do escopo pai?
   - **Exemplo**:
   ```c++
   int i = 0;

   int func(int i) { /// Aceitável: o símbolo i do escopo de func tem preferência sobre o do escopo global.
      if (i == 0) {
         float i = 2.4; /// Erro: o símbolo i do escopo do if não pode ter preferência sobre o do escopo de func.
      }
   }
   ```
   - **Sugestão**: Adicionar um booleano no nó que indica se aquele é um escopo forte (tem preferência sobre o pai) ou fraco (o pai tem preferência sobre ele).