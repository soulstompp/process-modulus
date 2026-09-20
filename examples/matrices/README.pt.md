**Português europeu.** A segunda testemunha: a mesma aritmética, calculada por outra via.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

O `assets/sql/matrices.sql` calcula cada matriz na base de dados, com junções e `GROUP BY`. Este
programa tira as mesmas linhas de lá e calcula com o `nalgebra`, onde um produto de matrizes é um
produto de matrizes. Depois afirma que os dois concordam.

⭐⭐ ESSA AFIRMAÇÃO É O QUE IMPORTA, E É O PADRÃO DO PRÓPRIO REPOSITÓRIO APLICADO À ARITMÉTICA. O
`tests/independence.rs` argumenta que corroboração entre duas coisas que partilham um caminho de
código não vale nada. Uma consulta que calcula um número e um README que diz «vejam, está certo» é
UMA TESTEMUNHA A AFIRMAR. Recalculá-lo por outra via e comparar são duas, e a afirmação que o
`assets/sqlc/README.md` faz, de que um produto de matrizes É uma junção com um `GROUP BY`, deixa de
ser coisa que o autor disse e passa a ser coisa que foi verificada.

⚠️ Os dois lados partilham a carga, e isso está bem: a carga não é o que está a ser provado. O que
está a ser provado é a aritmética que fica por cima dela.

# O modelo, para quem quer as matrizes

O suficiente para o reconstruir sem ler o README, que é escrito para outra pessoa. Acaba onde a
rede de fluxo se torna óbvia, de propósito.

Um documento declara um conjunto de **camadas**. Cada camada ℓ transporta três quantidades na sua
própria unidade: uma procura `d`, uma oferta comprometida `n` (o valor nominal), e um quantum `q`,
a unidade indivisível em que a oferta chega. A oferta vem em unidades inteiras, portanto `n = kq`
para `k` inteiro; a procura não. O **resto** é `r = n − d`. Cada quantidade é um intervalo de três
pontos, portanto isto é aritmética de intervalos do princípio ao fim, e tanto a magnitude do resto
como o seu **sinal** são avaliados ao longo do intervalo da procura. A §1 recalcula ambos.

**O resto é diagonal.** Nada acerca da camada *a* entra no resto da camada *b*. Vale a pena
dizê-lo de forma direta, porque o resto do modelo são matrizes e o pressuposto natural é que sejam
elas a fazer o trabalho aqui. Não são.

⛔ **Não há norma, espetro nem valor próprio no mapa de composição** até que alguém escolha uma
escala por camada, o que é um ato de modelação e não um ato matemático. O que fixa essa
decomposição em soma direta são as unidades, não um produto interno. Vocabulário espetral trazido
ao `F Φ − E` descreve um modelo que ninguém está a construir.

⭐ **Duas palavras dessa recusa têm mesmo referentes, e não são as espetrais.** A própria **matriz
de incidência** do grafo das camadas tem uma característica, `n − c`, e uma decomposição ortogonal
honesta: o seu espaço de arestas é o **espaço de cortes** (o espaço das linhas) mais o **espaço de
ciclos** (o núcleo), que são complementos ortogonais e somam o número de arestas. Este modelo põe
uma regra em cada um. Um balanço NUM NÓ é a regra de fusão, `x_composta = Σ φ x_parte − e`, e vive
no espaço de cortes. Uma soma AO LONGO DE UM CICLO é a regra de conversão, `1 ∈ Π φ`, e vive no
espaço de ciclos. Portanto uma declaração pode satisfazer uma e quebrar a outra, e os dois grafos
precisam de duas regras em vez de uma.

⛔ **E o espaço de ciclos do grafo das camadas é zero**, que é a razão por que nada aqui circula: o
espaço de cortes é todo o espaço de arestas, todo o vetor de arestas é uma diferença de potencial,
e uma composição não tem direção nenhuma em que circular. É o portador conservado dito em álgebra
linear, e é a razão por que não há ponto fixo, nem inversa de Leontief, nem pergunta de
convergência a fazer. O `rank/cycle_space.sqlc` calcula as duas dimensões para cada grafo aqui em
vez de as afirmar, e o `src/proofs/README.md` §10 prova as identidades.

⭐⭐ **E o dobrar `F Φ` é outra matriz, com quatro subespaços seus, que é a distinção que aqui corre
mal mais vezes.** A incidência acima é `m × n`, uma linha por aresta. O dobrar é
`|fusões| × |partes|`, baixo e largo. Cada parte pertence a uma só fusão, portanto os suportes das
linhas são disjuntos e a característica é simplesmente o número de linhas: o **espaço das colunas**
é todo o espaço das fusões e o **núcleo à esquerda** é vazio, mantido lá pelo
`algebra/fusions_have_parts`. O **núcleo** do lado das partes é o que carrega uma afirmação,
`Σ (partes − 1)` dimensões de fornecimento que quem compôs disse que o seu valor composto não vê, e
o **espaço das linhas** ao lado dele é uma direção estritamente positiva por fusão, que é a razão
por que nenhum desvio não negativo é invisível. As §3d e §3e calculam os quatro.

⭐⭐⭐ **Indexados por CAMADA dos dois lados, os mesmos factos arquivados dão um operador QUADRADO,
e é nilpotente.** Uma composição é bem fundada, portanto alguma potência dele é zero, `(I − F Φ)` é
invertível e `(I − F Φ)⁻¹ = I + F Φ + (F Φ)²` é uma soma finita e não um limite. Essa série É o
`composition/descent.sqlc`, e a §3e multiplica as matrizes e afirma que as duas coincidem, com o
índice de nilpotência confrontado com a descida mais funda que a relação do fecho reporta. ⛔ É
também a razão por que não há pergunta de convergência: a série termina, e se não terminasse o
modelo estaria a dizer que uma camada se compõe a partir de si própria.

# O dicionário, porque os mesmos objetos são calculados duas vezes

Tudo o que está acima tem uma relação com nome, e este é o único sítio onde os dois registos ficam
lado a lado. ⛔ Os cabeçalhos `.sqlc` NOMEIAM a matriz de que cada relação é a forma esparsa, o
`entries/holders.sqlc` abre com *«H, A MATRIZ DOS DETENTORES»*, e depois argumentam em junções.
Portanto os substantivos são partilhados e os operadores não, e quem chega a uma consulta nunca tem
de segurar um segundo formalismo para a acompanhar. Este é o dicionário; todos os outros ficheiros
são um dos seus lados.

| aqui | relação |
|---|---|
| `d`, `n`, `draw` | `layers/demand`, `layers/nameplate`, `layers/drawn` |
| `r = n − d` | `layers/remainder` |
| `F` (incidência) | `composition/parts` |
| `Φ x` (partes convertidas) | `composition/converted` |
| `F Φ x − e` | `composition/fused` |
| `ker(F Φ)` | `rank/composition_kernel` |
| `row(F Φ)` | `rank/composition_row_space` |
| `col(F Φ)`, `ker((F Φ)ᵀ)` | `rank/composition_image` |
| `(I − F Φ)⁻¹ = I + F Φ + (F Φ)²` | `composition/descent`, `rank/composition_closure` |
| `e` | `eliminations/filed` |
| `H`, `S`, `C` | `entries/holders`, `entries/slacks`, `entries/couplings` |
| `D`, `N` | `entries/draws`, `entries/inductions` |

⛔ As contagens de linhas não são escritas aqui de propósito: uma contagem em prosa está certa até
o conjunto de documentos se mexer da próxima vez e fica calada quanto a isso a partir daí. Corra-se
uma relação e leia-se a contagem no próprio rodapé do psql, ou corra-se este programa, que imprime
cada figura que usa.

⭐⭐⭐ **UM PRODUTO MATRIZ-VETOR É UMA JUNÇÃO COM UM `GROUP BY`.** Não por analogia. `F Φ x` é
calculado em dois ficheiros e a diferença entre eles é tudo o que separa uma matriz diagonal de uma
matriz geral: o `composition/converted.sqlc` é `parts ⋈ demand` a multiplicar por um escalar, e o
`composition/fused.sqlc` é a mesma junção mais uma soma `γ`. **Uma matriz diagonal é uma junção sem
agregação. Uma matriz geral é a mesma junção com ela.** O `Φ` não pode misturar linhas, portanto não
precisa de `GROUP BY`; o `F` soma partes numa camada composta, portanto é exatamente um `γ` sobre a
incidência. Todo o resto acerca dos dois é idêntico.

O restante conjunto de operadores mapeia com a mesma clareza:

| operação | relacional | nota |
|---|---|---|
| transposta `Dᵀ` | `ρ`, renomear | nenhum dado se move; `Dᵀ` é `D` com duas colunas renomeadas |
| `−e` | `⟕` e depois um `coalesce` com guarda | o preenchimento só é sólido depois de `σ` retirar as linhas que nada devem |
| uma linha nula de `F` | uma camada composta sem linha de parte | uma anti-junção, com a forma de `composition/leaves` |
| `DᵀN` | uma junção no índice de operação partilhado | os padrões compõem-se; as quantidades não, por causa das unidades |

⭐ **Correr os dois e afirmar a concordância é como uma afirmação aqui ganha a palavra
«verificada».** Uma formulação matricial é fácil de raciocinar e fácil de estar errada em silêncio,
porque cada erro de forma continua a produzir um número. Uma formulação relacional é mais difícil de
ler e falha alto. O `checks/fusion_sum_disagrees` faz depois da concordância uma regra de
conformidade em vez de um teste num exemplo que alguém tem de se lembrar de correr.

Correr com uma base de dados carregada:

```text
createdb process_modulus_proof
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example matrices
```

⛔ Não há salto silencioso. Sem base de dados, falha em vez de correr, porque uma prova que passa
sem ter executado é a armadilha da vacuidade que este repositório não se cansa de nomear.
