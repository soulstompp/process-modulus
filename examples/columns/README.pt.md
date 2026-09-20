**Português europeu.** Que matriz neste repositório tem um espaço de colunas, e o que vive na metade dele que nenhum potencial explica?

**Grafia do AO90.** Este ficheiro segue o Acordo Ortográfico de 1990, e é essa a versão
autoritativa para o português.

## A matriz é das composições, não das quantidades

Uma matriz de camadas por quantidades parece a óbvia para interrogar, e não tem espaço de colunas
digno desse nome. As suas colunas misturam uma contagem de pessoas com uma taxa de encomendas por
dia, portanto cada entrada de uma matriz de Gram sobre ela é uma soma de produtos de coisas
incomensuráveis. `entries/cross_layer_edges.sqlc` já publica exatamente esse produto, sob os nomes
de coluna `the_unit_that_warns_you` e `the_product_nobody_should_use`.

O obstáculo é mais preciso do que um aviso, e vale a pena enunciá-lo como uma invariância.
Converter um arquivamento para uma unidade comum multiplica cada linha pelo seu próprio fator
positivo, uma diagonal positiva `D`. Sob `A -> DA`, a característica, o espaço nulo e o espaço de
linhas não se movem, e o espaço de colunas e a Gram movem-se.

Isso não é a matriz de magnitudes não ter espaço de colunas. É a matriz de magnitudes ter um
**condicionalmente**, sobre um facto que vive noutro grafo e é invisível a partir das suas
próprias linhas. `D` existe exatamente quando a regra de conversão do grafo de unidades fecha: os
fatores multiplicarem para um à volta de cada ciclo diz que `log φ` não transporta nada no espaço
de ciclos, o que diz que é um gradiente, o que diz que existe um potencial, um tamanho logarítmico
absoluto por unidade. **Esse potencial é o `D`.** Portanto o espaço de colunas está lá, fixado por um
potencial que pertence a um grafo que a matriz não contém, e `checks/conversion_cycle_does_not_close` é a
regra que decide se pode ser alcançado. O corpus dá um intervalo que contém um em vez de um
exatamente, portanto o potencial fica determinado até essa largura, e a geometria que ele fixa
também.

O grafo de composição não tem tal condição a cumprir, e é essa toda a sua vantagem. Os seus nós
são os modelos sob `assets/sqlc/`, as suas arestas são as diretivas `:compose` entre eles, e o que
uma aresta transporta é uma **contagem**. Contagens são adimensionais, portanto `D` é a identidade
e não há nada a consultar noutro sítio. Esta é a matriz cujo produto interno é canónico sem mais,
e é por isso a primeira a interrogar.

## O produto é uma junção com um `GROUP BY`

Escreva-se `B` para a matriz de incidência, uma linha por aresta e uma coluna por modelo,
transportando `-1` no progenitor e `+1` no filho. Então `BᵀB` é o laplaciano do grafo: grau na
diagonal, adjacência negativa fora dela.

Nada é transposto para lá chegar. Uma matriz esparsa guardada por colunas é a sua forma de
coordenadas, que é uma relação, portanto `Bᵀ` são dois nomes de coluna trocados e nenhum dado se
move. `BᵀB` é então uma auto-junção sobre o índice de arestas com um `GROUP BY` sobre o par de
nós, e o tamanho da junção está fixado de antemão: cada aresta tem exatamente dois extremos,
portanto cada fibra é dois e a junção devolve `4m` linhas antes do agrupamento. Uma junção que
devolva outra coisa significa que a incidência não é uma incidência.

## As quatro dimensões, cada uma verificada duas vezes

```text
rank(B)   = n - c          o espaço de cortes, os gradientes
ker(B)    = c              as constantes, uma por componente
ciclo     = m - n + c      as circulações
corte + ciclo = m          e os dois preenchem o espaço de arestas
```

Cada linha é calculada por duas vias que não partilham código. As componentes vêm de um
percurso; a característica vem de eliminação sobre o laplaciano; o espaço de ciclos vem da
contagem de arestas. Uma identidade com uma só via é uma definição repetida, portanto o programa
afirma a concordância em vez de imprimir um dos números sozinho.

## Uma dimensão é um número, e só uma base se compõe

O mesmo percurso que conta as componentes devolve a divisão que faz do espaço de ciclos um objeto
em vez de um tamanho. Aceita uma aresta quando ela junta duas componentes e rejeita-a caso
contrário, portanto o que aceita é uma floresta de expansão, `n - c` arestas, e o que rejeita é
uma corda. Cada corda fecha exatamente um ciclo: ela própria, mais o único caminho pela floresta
que junta os seus extremos.

Esses vetores são uma base, e a independência vem de graça em vez de ser argumentada. Todas as
outras arestas de um ciclo fundamental são arestas da floresta, portanto cada vetor da base é o
único que transporta a sua própria corda. Essa é uma terceira via para `m - n + c`, construtiva
onde as outras duas são aritméticas, e o programa afirma que as três concordam.

Cada um é verificado como um erro de sinal merece ser verificado, por medição e não por
raciocínio: um vetor de ciclo tem saldo zero em cada nó, portanto um vetor com um sinal errado
nalgum sítio não está no espaço de ciclos de todo, e di-lo.

## O que o grafo de composição é, e os grafos do próprio modelo não são

O modelo põe uma regra em cada metade desta decomposição. Um balanço num nó é a regra de fusão e
vive no espaço de cortes; uma soma à volta de um ciclo é a regra de conversão e vive no espaço de
ciclos. O espaço de ciclos do grafo de camadas tem de ser zero, porque um ciclo aí é uma partição
desenhada fina demais. O do grafo de unidades pode ser não nulo e é obrigado a fechar.

O grafo que este repositório compõe não obedece a nenhuma das duas, e a razão é a dobra. Uma
consulta é idempotente, portanto compor uma relação duas vezes lê-a uma vez e a multiplicidade não
custa nada. Um fornecimento é um portador conservado, portanto a mesma forma no grafo de camadas é
uma contagem dupla. A mesma álgebra, veredictos opostos sobre um facto, e o espaço de ciclos é
onde a diferença é visível: aqui é grande e é livre.

É também por isso que o grafo não tem pesos e `splices` é um vetor de arestas em vez de um peso de
aresta. Pesar o laplaciano pela contagem de repetições afirmaria a regra aditiva, que é aquela a
que este grafo não obedece.

## Uma circulação nula significa que existe um potencial

Cada vetor de arestas divide-se, ortogonal e exatamente, num gradiente e numa circulação. A parte
do gradiente é o que algum número único por modelo explica, através das suas diferenças. A
circulação é o que nenhum tal número alcança, porque é um facto sobre pares e não sobre extremos.

Não é um teste novo. `checks/conversion_cycle_does_not_close` põe-no ao grafo de unidades, onde o
potencial é um tamanho logarítmico absoluto por unidade e a regra é que os fatores multiplicam
para um à volta de cada ciclo. A mesma pergunta é posta aqui a três vetores: o vetor de uns, que
pergunta se o grafo tem níveis; `splices`, que pergunta se compor duas vezes é uma propriedade de
uma relação; e `inner_joins`, que pergunta se o alcance de uma junção interna tem um potencial.

O terceiro é o que tem consequência. `algebra/dimension_use.sqlc` permite exatamente um modelo
para fazer junção interna da dimensão de camadas, e diz no seu próprio cabeçalho que não consegue
ver como um progenitor permitido usa essa dimensão, apenas que é permitido. A circulação responde
à pergunta que a lista não consegue: execute-o e leia qual aresta transporta mais.

## E o espaço dos nós também se parte, que é a metade que nunca tinha sido escrita

Todas as divisões acima são de um vetor de ARESTAS. O espaço dos nós tem a sua, no espaço das
linhas de `B`, que é todo o saldo que algum fluxo produz, e no núcleo, que são as constantes, uma
por componente. São complementos ortogonais tal como o espaço de cortes e o de ciclos são.

O que torna a divisão útil é que um saldo soma sempre zero em cada componente. Cada linha de `B`
tem um `-1` e um `+1`, portanto `B` envia o vetor só com uns para zero, e por isso um vetor de nós
cujos totais por componente não sejam zero não é o saldo de vetor de arestas nenhum. O grau é um
desses vetores: o aperto de mão põe o seu total no dobro do número de arestas, portanto a sua parte
nas constantes não se pode anular, e nenhum fluxo pelas arestas tem o grau como saldo.

É essa a forma que uma eliminação tem no grafo do próprio modelo. Uma correção assente no espaço
das linhas moveria fornecimento entre camadas e deixaria o total de cada componente onde estava;
uma eliminação não deixa, e é por isso que é subtraída em vez de transportada.
`src/proofs/README.md`, entrada `elimination_leaves`, é onde se prova.

O calibre acima é um pino e este é uma projeção, e são atos diferentes. Pinar um nó escolhe um
representante de uma classe lateral, portanto um potencial não tem parte nas constantes que valha
a pena reportar. Um vetor que chega de fora tem, e é um número sobre o vetor em vez de sobre a
escolha.

## Como executar

```bash
cargo run --example columns          # não precisa de DATABASE_URL, de propósito
```

O grafo é o sistema de ficheiros, portanto este programa não precisa de base de dados. Lê
`assets/sqlc/` através do único leitor que `compositions`, `soundness` e `observations` partilham,
e confere o resultado contra `assets/dag/edges.sql`, que é a cópia do próprio emissor. Uma
discordância aí significa que um dos dois está desatualizado, e não que algum esteja errado.

Escreve cinco relações em `assets/arrow/`, em Arrow IPC, porque nenhuma das audiências de uma
matriz corre Rust. `incidence` é `B`, `laplacian` é `BᵀB`, e `cycles` é a base acima, uma linha
por `(ciclo, aresta, sinal)`. `templates` e `edges` transportam o que a divisão deixa num nó e
numa aresta: o potencial que cada vetor induz, e o gradiente e a circulação que cada aresta leva.
Juntam-se por `node` e `edge`, e é isso que torna os subespaços componíveis fora deste programa e
não só dentro dele:

```python
import polars as pl
pl.read_ipc("assets/arrow/laplacian.arrow")
```

```r
arrow::read_ipc_file("assets/arrow/laplacian.arrow")
```

Cada uma é escrita duas vezes, uma em Arrow IPC e outra em parquet. A segunda é para quem não
tem nenhum dos dois, porque o `duckdb` abre parquet sem instalar nada:

```sql
SELECT parent, child, inner_joins_circulation FROM 'assets/arrow/edges.parquet'
ORDER BY abs(inner_joins_circulation) DESC LIMIT 5;
```

## Uma nota sobre o uso de polars

É correto e não é normal. Um motor de dataframes está aqui a segurar álgebra de subespaços: uma
junção no lugar de um produto de matrizes, um grupo como uma dobra sobre fibras, e uma forma de
coordenadas no lugar de uma coluna esparsa. Um leitor que chegue à procura de análise não
encontrará nenhuma. O motor foi tomado por uma propriedade que uma biblioteca de matrizes densas
não tem: uma coluna transporta uma máscara de validade ao lado dos seus valores, portanto um zero
arquivado e um valor que ninguém arquivou não são os mesmos bytes.
