**Português europeu.** Que consulta compõe qual, e se todos os nomes existem, nada se compõe a si próprio e cada expansão acaba.

> **Grafia do AO90.** Também disponível em inglês: `examples/compositions/README.md`.

Um ficheiro `.sqlc` compõe outro quando o nomeia numa diretiva `:compose` ou `:union`, e é esse
grafo, de quem compõe quem, que este programa lê, diretamente dos ficheiros e sem base de dados
nenhuma, deixando de fora as linhas `#`, que são prosa e não chegam ao SQL composto. O que lê,
escreve-o em `assets/dag/edges.sql`, uma linha por par de pai e filho com quantas vezes o pai
encaixa o filho e quantas dessas vezes o faz num `JOIN` interior, e o `ingest.sql` carrega-o em
`public.compose_edge`, para que as consultas o possam juntar ao resto; trata-se de um facto sobre os
ficheiros, pelo que é o programa que lê os ficheiros que o escreve.

Separa depois os dois níveis que os diagramas desenham, as tabelas `pm.*`, que um diagrama BPMN
mostra como elementos, e as consultas de `assets/sqlc/`, que mostra como processos, e confirma que
cada documento de `assets/bpmn/` tem o seu SVG em `assets/svg/`, pelo menos tão recente como ele, o
que só acontece se o `diagramming` e o `graphs` correram antes do `rendering`. Seguem-se três
condições, e qualquer delas, se falhar, faz parar o programa: cada nome que uma diretiva cita é um
ficheiro que existe; nenhum ficheiro, depois de expandido, volta a dar consigo mesmo, e dois
caminhos que se reencontram mais abaixo não contam como volta; e há um princípio e um fim, raízes
que ninguém compõe e folhas que não compõem nada. Um ficheiro que é raiz e folha ao mesmo tempo tem
de ser corrido por um exemplo, ou figurar numa lista de exceções com a sua razão, como o
`ingest.sqlc`, que o `psql` corre antes de qualquer composição.

## Uma consulta repetida não faz mal, uma parte repetida conta a dobrar

Muitas raízes chegam ao mesmo ficheiro por mais de um caminho, e muitos ficheiros têm mais de um
pai; o programa mostra quais e exige que haja pelo menos um caso, para que a comparação tenha
assunto. Nada disto está errado, uma vez que uma consulta lida duas vezes dá o mesmo que lida uma.
No grafo das partes, onde uma camada se compõe de outras, a mesma forma já é uma infração,
`checks/jagged_layer`, porque uma oferta não se repete sem se somar, e um total que apanhe a mesma
parte por dois caminhos conta-a duas vezes. Quem separa os dois casos é a coluna `splices`, e é por
isso que o grafo emitido a guarda, em vez de reduzir cada par a uma única aresta.

## Até onde desce uma composição

Cada ficheiro, ou compõe outros, e é um processo feito de chamadas, ou lê tabelas, as `pm.*`, o
catálogo ou `public.compose_edge`, e é um processo com elementos lá dentro; os que fazem as duas
coisas aparecem pelo nome, porque saltam por cima da sua própria abstração e isso vê-se num
diagrama. Os que não fazem nenhuma das duas são literais `VALUES`, e são os contratos: um rol diz o
que a árvore tem de conter, pelo que não pode ser tirado da árvore, senão o declarado e o produzido
nunca poderiam discordar. O programa exige que cada um deles seja de facto um literal, com a única
exceção do carregador.

## Correr o programa

Não precisa de base de dados, e reescreve `assets/dag/edges.sql`:

```text
cargo run --example compositions
```
