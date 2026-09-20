**Português europeu.** Os três grafos que este modelo compõe, como os lane sets de uma só pool.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do BPMN e do XSD ficam em inglês, porque são os nomes do artefacto.

⭐⭐⭐ A POOL GRANDE É O MODELO, E OS TRÊS GRAFOS SÃO LANE SETS SOBRE ELA. As pools por documento
que o `examples/diagramming/main.rs` emite, uma por declaração carregada, ficam DENTRO desta. Um
`laneSet` é uma partição que se declara exaustiva, e três LANES poriam cada composição em
exatamente uma. As
composições não ficam em exatamente uma: uma relação que lê uma parte E o seu fator está no grafo
das camadas e no grafo das unidades, e é isso que um fator É. O BPMN permite vários lane sets sobre
um mesmo processo por esta razão exata.

⛔⛔ E OS TRÊS LANE SETS NÃO PODEM SER TODOS A CONTENÇÃO. Uma árvore de inclusão dá a cada nó UM
pai, pelo que só um deles pode ser o encaixe que um diagrama desenha. É por isso que o grafo é
aqui um SLOT e não uma escolha silenciosa: o `entries/coupling_presence.sqlc` é perguntado ao
conjunto de documentos por um chamador e a cada documento por outro, ambos estão certos, e um
chamador que não forneça `@scope` NÃO COMPÕE. A escolha sai de um hábito e entra na estrutura.

⭐⭐ A PALAVRA DO BPMN PARA UM SLOT JÁ ESTÁ NA ESPECIFICAÇÃO. Um `participant` tem um `processRef`
OPCIONAL: fornece-se e a pool tem conteúdo, omite-se e tem-se uma BLACK BOX POOL, que é BPMN de
primeira classe para *alguém age aqui e o que faz não está neste diagrama*. Um slot não preenchido
É um participante caixa-negra, e este exemplo emite um para o grafo que não tem arestas, em vez de
fingir que desenhou alguma coisa.

⭐⭐⭐ E O QUE SEPARA OS TRÊS GRAFOS É UM NÚMERO POR GRAFO, E NÃO TRÊS TEORIAS DIFERENTES. Para
uma matriz de incidência sobre `n` nós, `m` arestas e `c` componentes, o espaço de arestas divide-se
no ESPAÇO DE CORTES de dimensão `n − c` e no ESPAÇO DE CICLOS de dimensão `m − n + c`. São
complementos ortogonais e somam `m`, pelo que cada grafo aqui é uma linha da mesma tabela, e um
ciclo quer dizer coisas diferentes em cada um porque cada grafo põe a sua regra numa metade
diferente:

| grafo | o seu espaço de ciclos | um ciclo ali é |
|---|---|---|
| **camadas** | tem de ser **ZERO** | ⛔ uma partição mal declarada: as células eram uma só célula |
| **unidades** | pode ser **NÃO NULO**, e os pesos sobre ele têm de se anular | ⭐ esperado, e obrigatório para fechar |
| **reclamantes** | desconhecido, porque a delegação não é declarada em parte nenhuma | ⛔ não é «ninguém responde»; é um encaixe sem preenchimento |

⛔ **Portanto «cíclico, logo sem característica» é uma confusão entre dois sentidos de uma palavra.**
Um grafo com ciclos não tem característica ORDINAL e tem sempre característica MATRICIAL.

⛔ **E «ciclo» é uma segunda palavra com dois sentidos, e é esta a que morde aqui.** O `m − n + c`
conta ciclos NÃO ORIENTADOS, portanto um zero diz que o grafo é uma FLORESTA. Ser bem fundada é a
questão ORIENTADA, se alguma coisa desce para sempre, e todo o digrafo acíclico o é. Uma floresta é
bem fundada e a recíproca falha: um losango tem quatro arestas sobre quatro nós numa componente,
portanto o seu espaço de ciclos é um, e nada nele desce para sempre. Um espaço de ciclos nulo
oferece a característica ordinal; a característica ordinal não oferece nada em troca. **Portanto
diga-se sempre de que ciclo se trata.** O grafo das camadas é as duas coisas ao mesmo tempo, e isso
é o `checks/jagged_layer` a mantê-lo assim e não uma identidade: um losango nele é uma camada
composta duas vezes, e é por isso que o `composition/descent.sqlc` tem razão em dizer que um losango
não é um ciclo NO SENTIDO DELE e esta tabela tem razão em dizer que é um neste.
O `rank/cycle_space.sqlc` imprime as duas dimensões para cada
grafo que tenha uma aresta, este programa afirma o zero do grafo das camadas contra o
`checks/jagged_layer` não encontrar violação nenhuma, e o `src/proofs/README.md` §10 prova as
identidades.

```text
DATABASE_URL=... cargo run --example graphs
```
