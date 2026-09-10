**Português europeu.** Os três grafos que este modelo compõe, como os lane sets de uma só pool.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do BPMN e do XSD ficam em inglês, porque são os nomes do artefacto.

⭐⭐⭐ A POOL GRANDE É O MODELO, E OS TRÊS GRAFOS SÃO LANE SETS SOBRE ELA. As quinze pools por
documento que o `examples/diagramming/main.rs` emite ficam DENTRO desta. Um `laneSet` é uma
partição que se declara exaustiva, e três LANES poriam cada composição em exatamente uma; medido,
169 de 220 composições tocam em mais do que um grafo, porque uma relação que lê uma parte E o seu
fator está no grafo das camadas e no grafo das unidades, e é isso que um fator É. O BPMN permite
vários lane sets sobre um mesmo processo por esta razão exata.

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

```text
DATABASE_URL=... cargo run --example graphs
```
