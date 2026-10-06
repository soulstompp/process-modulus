**Português europeu.** Cada consulta calcula o que o seu cabeçalho diz que calcula?

> **Grafia do AO90.** Também disponível em inglês: `examples/soundness/README.md`.

Cada ficheiro `.sqlc` abre com um cabeçalho que diz o que a relação devolve, e as regras confiam
nesse cabeçalho sem o voltar a ler. Este programa confere essa confiança de duas maneiras: corre
sobre a base de dados carregada as leis de `algebra/roster.sqlc`, que calculam outra vez, por outro
caminho, o que as relações calculam, e lê os próprios ficheiros de `assets/sqlc/` à procura do que
nenhuma lei cobre. Qualquer das verificações abaixo, se falhar, faz parar o programa.

## As verificações, uma a uma

1. Cada lei mantém-se em todos os sujeitos que examina, e nenhuma fica vazia, já que uma lei sem
   sujeitos não confirmou nada.
2. Cada diferença de conjuntos que a árvore faz, seja por `EXCEPT`, por `NOT EXISTS` ou por um
   `LEFT JOIN` filtrado em `IS NULL`, é governada por uma lei, salvo as exceções que o programa
   declara com a sua razão.
3. Cada rol do repositório está de acordo com a população que declara.
4. Cada regra examina linhas da granularidade que declara, e uma regra que diz examinar camadas dá
   exatamente uma linha por camada declarada.
5. Em cada contrato, a população com que o rol se compara ou é independente dele, ou tira do
   próprio rol os nomes dos seus sujeitos; os que tiram estão declarados no programa com a razão,
   e um que passe a tirar sem estar declarado é uma segunda testemunha que se perde em silêncio.
6. Com o corpus esvaziado, dentro de uma transação que no fim se desfaz, cada regra continua a
   dizer que correu, com uma única linha e sem veredicto nenhum, porque a linha do rol existe antes
   da população.
7. O grafo das composições que está carregado na base de dados é o que os ficheiros dizem hoje.
8. Cada sítio que multiplica por um fator de conversão está declarado no programa e lê o sinal do
   operando da mesma maneira que os outros; um sítio novo por declarar, ou um declarado que deixou
   de multiplicar, conta como falha.

## Correr o programa

Precisa da base de dados carregada, que fica como estava:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example soundness
```
