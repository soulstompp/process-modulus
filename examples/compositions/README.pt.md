**Português europeu.** As composições que este repositório tem, e as três precondições que fazem delas uma álgebra.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

⭐⭐⭐ HÁ DUAS CAMADAS E NÃO SÃO DUAS LEITURAS DA MESMA COISA. Os OBJETOS DE DOMÍNIO são os
objetos relacionais, `pm.*` em `assets/ddl/schema.ddl`. As COMPOSIÇÕES são as consultas,
`assets/sqlc/**.sqlc`, e são vistas ad-hoc que este repositório nunca constrói: o `CREATE VIEW`
aparece zero vezes no esquema. Todo o resto aqui refere-se a uma composição pelo NOME, tal como um
`.sqlc` se refere a outro `.sqlc` e nunca lhe repete o SQL.

⭐⭐ E O DAG DE COMPOSIÇÃO É UM GRAFO DE CHAMADAS. O `sql-composer`, o BPMN 2.0 e este modelo são
a álgebra de alcançabilidade de uma relação binária bem fundada sobre nomes, o que é uma afirmação
com três precondições: cada nome resolve, nenhum nome se expande em si mesmo, a expansão tem
princípio e fim. Este exemplo AFIRMA as três sobre a árvore real em vez de as repetir.

⛔⛔ A QUE VALE MAIS É O CONTRASTE NO FIM. Uma camada alcançada duas vezes dentro de uma fusão é
o `checks/jagged_layer`, uma violação, porque o portador é CONSERVADO e um só total fecha sobre
ambas as ocorrências. Uma composição alcançada duas vezes dentro de uma raiz é o CASO NORMAL e não
custa nada, porque uma consulta é idempotente e o planeador lê a relação uma vez. A mesma álgebra
de substituição, a mesma forma de grafo, veredictos opostos. A diferença é o portador, e é nisso
que consiste tudo o que este modelo acrescenta aos seus dois vizinhos.

# E as composições do próprio modelo encaixam, que é onde a analogia deixa de pagar

O `examples/matrices/main.rs` §3 constrói `F`, a incidência que leva as camadas-parte às camadas
compostas. As composições encaixam, portanto `F` compõe, e a restrição de unicidade ao nível do
documento não. A um nível, «nenhuma parte usada duas vezes» é uma chave; a dois, tem de passar a
ser «nenhuma folha alcançável por dois caminhos», o que nenhum validador consegue ver, porque o
segundo caminho passa por um documento que o primeiro não contém. Essa é a regra que o
`assets/sqlc/README.md` nomeia como aquela a que nenhum validador chega, e é a mesma álgebra de
substituição sobre a qual este ficheiro afirma três precondições.

⭐⭐ **Uma composição encaixada tem dois fundos diferentes, um por quantidade, no mesmo grafo.**
Uma SOMA sobre partes chega ao fundo nas camadas de que `F` não consegue descer, porque abaixo
dessas não resta nada para somar. Um RESTO chega ao fundo mais cedo: na primeira camada cuja
própria procura e valor nominal não foram ambos escalados por um só fator de conversão com
largura. Aí o `n − d` é legítimo e o par arquivado é uma afirmação que quem compõe subscreve,
pelo que descer para além dele deita fora essa afirmação e todas as correções que quem compõe já
aplicou, que teriam então de ser reconstruídas de baixo e podem falhar por razões que a figura
arquivada já tinha resolvido. Uma camada sem partes satisfaz a segunda condição trivialmente, que
é a razão pela qual os dois fundos se confundem com facilidade. O `composition/descent` é o
primeiro; o `composition/remainder_frontier` é o segundo.

⛔ **O terminal do grafo move-se portanto com a quantidade que está a ser dobrada**, o que não é
verdade em nenhum dos dois sistemas de composição a que este repositório é de resto análogo. Os
terminais de um grafo de chamadas são os seus terminais; as folhas de uma consulta são as suas
folhas, selecione-se o que se selecionar. Aqui um nó intermédio transporta uma figura que alguém
assinou, e é isso que o torna um sítio onde parar. ⭐ O que é o contraste acima dito do outro
lado: a mesma forma de grafo, e o que decide o veredicto é o portador e não a forma.

⭐ Não precisa de base de dados. O DAG de composição é um facto sobre a árvore de código.

```text
cargo run --example compositions
```
