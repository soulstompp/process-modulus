# O mesmo modelo, duas vezes: como tabelas e como matrizes

> **Português europeu, grafia do AO90.** A versão inglesa está em [`README.md`](README.md) e é a
> que o repositório trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das
> tabelas e dos elementos do XSD ficam em inglês, porque são os nomes do artefacto.

Cinco ficheiros e uma afirmação.

```
schema.ddl            o modelo como relações
ingest.sql            o Postgres a ler assets/corpus/*.xml sozinho, sem ajuda nenhuma
matrices.sql          as matrizes, extraídas com junções
rules.sql             as regras a que o XSD 1.0 não chega, como uma só consulta
queries/              as seis consultas do exemplo, um ficheiro cada, executáveis no psql
../../examples/matrices.rs   a mesma aritmética outra vez, em nalgebra, a afirmar a concordância
```

**A afirmação:** quarenta e quatro regras deste modelo estão escritas na prosa dos esquemas e não
são verificadas por nada, porque o XSD 1.0 não tem `xs:assert` e não consegue comparar um elemento
com outro. Repare-se no que essas regras dizem de facto. *As parcelas somam a grandeza. O sinal
concorda com a comparação de intervalos. Nenhuma folha é alcançável por dois caminhos.* São
junções, somas e comparações — impossíveis numa gramática, correntes numa linguagem de consulta.

**O que isto não é.** Não é um esquema de base de dados recomendado. Nada aqui está normalizado
para escrita, indexado para uma carga de trabalho, ou moldado para uma aplicação. Copiem-se as
ideias, não a disposição.

**Três entradas, e são o mesmo assunto a três profundidades.** Escolha-se aquela que já é a
ferramenta diária — qualquer uma pode ser lida primeiro e as outras duas remetem para ela.

| se trabalha em | comece em | vai levar daqui |
|---|---|---|
| SQL, modelação de dados | [do lado relacional](#do-lado-relacional) | porque é que uma tabela vazia não é um zero |
| **consolidação, auditoria, relato** | [do lado financeiro](#do-lado-financeiro) | a consolidação que já faz, escrita como uma expressão — e o único sítio onde o seu instinto está errado |
| matrizes, otimização | [do lado da álgebra linear](#do-lado-da-álgebra-linear) | o que um intervalo faz que um número não faz |

## Como executar

A metade em SQL precisa de um Postgres e de mais nada. Sem Rust, sem extensões, sem
superutilizador.

```
createdb process_modulus_proof
psql -d process_modulus_proof -f assets/sql/schema.ddl \
                              -f assets/sql/ingest.sql \
                              -f assets/sql/rules.sql
```

Execute-se a partir da raiz do repositório — o `ingest.sql` lê `assets/corpus/*.xml` do lado do
cliente, portanto os caminhos são relativos ao sítio onde o `psql` foi iniciado.

A segunda metade recalcula as mesmas respostas por outra via e afirma que coincidem:

```
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example matrices
```

---

## A ideia que as duas álgebras partilham

Tudo aqui assenta numa frase, e ela é mais pequena do que parece.

> **Uma matriz é uma tabela, e multiplicar duas matrizes é uma junção com um `GROUP BY`.**

Uma entrada de matriz `D[p,l] = 3` é uma linha `(p, l, 3)`. A definição de manual de um produto,

```
(AB)[i,k] = soma em j de A[i,j] * B[j,k]
```

lê-se em português como *encontrar os pares que partilham um índice, multiplicá-los, somar os
grupos.* Ou seja:

```sql
SELECT a.i, b.k, sum(a.v * b.v)   -- multiplicá-los, somá-los
FROM a JOIN b ON a.j = b.j        -- os pares que partilham um índice
GROUP BY a.i, b.k;                -- os grupos
```

Quem alguma vez escreveu uma junção com um `SUM` lá dentro já multiplicou matrizes. Ninguém lhe
disse que era isso. → **verificado em [§3](#3-fφx--e-como-produto-matricial-a-sério)**

**E quem alguma vez consolidou um grupo já o fez à mão.** Somar os membros ao longo de uma
estrutura de participações É `Fx`; a incidência é que membro entra em que linha. → **[do lado
financeiro](#do-lado-financeiro)**, que é a parte rasa da mesma água e o sítio por onde começar se
a notação não for a ferramenta diária.

A direção que mais importa aqui é a outra. Assim que se sabe que uma matriz é uma tabela pode
fazer-se-lhe perguntas que a notação matricial não consegue escrever — *quais destas entradas é
que alguém mediu de facto?* — e isso acaba por ser o assunto deste modelo.

---

## Sete espécies de zero

Esta é a espinha. Quase todas as coisas interessantes abaixo são um zero, e não são o mesmo zero.
Distingui-los é todo o assunto, dos dois lados.

| o zero | o que quer dizer | onde |
|---|---|---|
| **o bom zero** | um resultado vazio *por uma razão que vale a pena ler* | `DᵀN` — [§2](#2-dᵀn-o-bom-zero) |
| **o mau zero** | dois factos diferentes colapsados num só número | `C` densificado — [§5](#5-o-que-custa-densificar) |
| **o zero perigoso** | uma regra que não examinou nada e parece uma passagem | a tabela de cobertura |
| **o zero que se quer** | nenhuma violação, de regras que correram mesmo | a primeira tabela do `rules.sql` |
| **o mesmo zero, duas vezes** | um facto com duas grafias | `absent reason="none"` contra uma afirmação de `[0,0,0]` |
| **o zero de fronteira** | uma comparação a assentar exatamente na linha | `n_low = d_high` — uma convenção escolhida |
| **o zero que NÃO devia ser zero** | uma tabela cujo vazio significaria que ninguém foi ver | os reencaminhamentos abaixo |
| **o zero que agora são dois zeros** | um branco que transportava «verificado e não há» e «ninguém verificou» ao mesmo tempo | `coupling_search`, `elimination_search` — [§6](#6-o-zero-que-afinal-eram-dois) |

**O bom zero é o primeiro a perceber**, porque é o que as pessoas apagam. O `DᵀN` sai vazio neste
conjunto de documentos. Não porque a consulta esteja errada — porque a única operação que ao mesmo
tempo consome e induz tem um consumo que **ninguém mediu**. A matriz que mostraria estrutura entre
camadas está em branco *precisamente porque* a quantidade interessante não tem instrumento, que é
aquilo que este modelo inteiro foi construído para dizer. Apague-se esse resultado por não ser
interessante e apagou-se o resultado.

**O zero perigoso é o que é publicado.** Uma regra sem nada que verificar devolve zero violações, o
que parece idêntico a uma regra que verificou tudo e não encontrou nada errado. Este repositório já
tem nome para isso: *«um limite sem nada para limitar é o que passa mais alto.»* É por isso que o
`rules.sql` termina com uma contagem do que cada regra examinou de facto, e por isso que o exemplo
faz asserções sobre as suas próprias dimensões de amostra antes de fazer asserções sobre as
respostas.

---

## Do lado relacional

A álgebra relacional são seis operações. Já se usam todas; eis onde cada uma assenta.

| operação | o que faz | aqui |
|---|---|---|
| **seleção** (σ) | ficar com as linhas que passam um teste | `WHERE sign = 'transition'` — uma camada em todo o conjunto |
| **projeção** (π) | ficar com algumas colunas | extrair `(camada, low, moda, high)` de uma declaração |
| **renomeação** (ρ) | chamar outra coisa a uma coluna | como `D` e `Dᵀ` diferem; uma transposta é uma renomeação |
| **produto** (×) | cada linha contra cada linha | o que uma junção é antes de se acrescentar a condição |
| **união** (∪) | as linhas de qualquer um | como o `rules.sql` dobra dezasseis verificações numa resposta |
| **diferença** (−) | as linhas de um que não estão no outro | **é o que uma verificação de regra É** |

Essa última linha é a útil. O `rules.sql` nunca pergunta *«isto passou?»*. Pede as linhas que
**falham**, que é uma diferença, e uma resposta vazia quer dizer que todas as linhas estavam no
outro conjunto.

**E há uma sétima que ninguém ensina, e que assenta exatamente neste modelo.** A **divisão**
relacional (÷) responde a *«que X se relacionam com TODOS os Y?»* — que camadas têm os três
amortecedores medidos, que composições usam todas as partes de um membro. A notação matricial não
tem nada que diga «todos os», e este modelo pergunta-o constantemente.

⛔⛔ **A CONDIÇÃO DE JUNÇÃO É ONDE VIVE A CONTABILIDADE, E É A RAZÃO DE ESTA SECÇÃO VIR PRIMEIRO.**
Duas figuras são comparáveis quando citam a mesma autoridade, que é uma cláusula `ON`; onde não
citam, as linhas simplesmente **não juntam**, e um par que não junta diz algo que um NULL não
consegue dizer. É uma operação a fazer o que um plano de contas faz. → **[do lado
financeiro](#do-lado-financeiro)** para o que custa errá-lo, e **[do lado da álgebra
linear](#do-lado-da-álgebra-linear)** para a aritmética por cima. Ambos remetem para aqui, porque a
forma relacional é a que consegue dizer *ninguém foi ver*.

### Porque é que as tabelas têm a forma que têm

**As tabelas que SÃO matrizes são altas. As que contêm atributos são largas.**

A `slack` tem uma linha por camada e por amortecedor — três linhas, e não três colunas — portanto a
tabela *é* a matriz L×3 a que a nota chama `S`. O mesmo para `holder` (L×5), `draw` e `induction`
(P×L), `coupling` (L×L), e `part`, que transporta `F` e `Φ` em conjunto porque uma parte *é* uma
entrada de incidência e o seu fator de conversão ao mesmo tempo. Já a `nameplate` é larga: uma
quantidade, um quantum e uma janela são factos sobre uma oferta, e não entradas de coisa nenhuma.

**Todas as tabelas altas são esparsas, e esparso significa alguma coisa aqui.** Uma entrada que é
zero é uma linha que não está lá. Portanto `C = 0` — a hipótese central do modelo, a de que as
camadas são independentes — não é uma grelha de zeros. É *uma tabela vazia.* E uma tabela vazia não
consegue dizer se alguém foi ver e não encontrou nada, ou se ninguém foi ver.

⭐⭐⭐ **E A CORREÇÃO NÃO É RELACIONAL. É UMA SEGUNDA TABELA, PORQUE O SEGUNDO FACTO É SOBRE A
PROCURA E NÃO SOBRE LINHA NENHUMA.** A `coupling_search` tem uma linha por declaração a dizer o que
aconteceu quando alguém foi procurar; a `elimination_search` faz o mesmo por cada fusão. Nenhuma é
uma matriz, nenhuma tem forma, e nenhuma podia ter sido uma coluna na tabela alta que explica — não
se atribui «ninguém foi ver» a uma linha que não está lá. →
**[§6](#6-o-zero-que-afinal-eram-dois)**

Isto é a ausência tipificada a chegar pelo lado relacional. É a razão de todas as colunas de
quantidade terem uma coluna `absent` companheira a transportar uma razão, e de o DDL obrigar a que
exatamente uma das duas esteja presente:

```sql
CONSTRAINT slack_is_stated_or_typed_absent
    CHECK ((low IS NOT NULL) <> (absent IS NOT NULL))
```

Um `NULL` simples não diz nada sobre *porquê* é nulo, que é a falha que este modelo existe para
evitar. → **o que custa perder isto é a [§5](#5-o-que-custa-densificar)**

---

## Do lado financeiro

⭐⭐⭐ **QUEM CONSOLIDA CONTAS PARA VIVER JÁ FAZ ÁLGEBRA LINEAR E NINGUÉM LHE CHAMA ISSO.** Esta
secção é a parte rasa de propósito: sem valores próprios, sem decomposições, sem nada que não se
tenha feito à mão em todos os períodos. Quatro operações, e cada uma delas já tem nome no seu
trabalho.

| a que lhe chama | o que é | neste modelo |
|---|---|---|
| somar os membros | um produto matricial, `Fx` | a `part` junta às camadas dos membros |
| tradução, reexpressão, conversão de unidades | uma escala **diagonal**, `Φ` | `Part/factor` |
| lançamentos de eliminação | uma subtração vetorial, `e` | `Elimination`, uma linha por quantidade |
| a coluna consolidada | `FΦx − e` | a própria afirmação da camada composta |

**É a consolidação inteira, escrita uma vez.** `FΦx − e` — tomar os membros, pô-los numa unidade,
somá-los ao longo da incidência de participações, subtrair o que foi contado duas vezes. → **e é
verificado contra as declarações na [§3](#3-fφx--e-como-produto-matricial-a-sério), onze camadas, ao
dígito.**

### O plano de contas é uma base, e dois planos são duas bases

⛔⛔ **ESTE É O QUE CUSTA DINHEIRO.** `6250` num plano e `6226` noutro não são dois valores de uma
coisa. São **coordenadas em bases diferentes**, e somá-las é uma mudança de base que ninguém
registou. Todos os contabilistas sabem isto e todas as folhas de cálculo se esquecem, porque um
código é uma cadeia de texto e as cadeias de texto concatenam-se.

O conjunto de documentos declara a mesma pergunta sob US GAAP e sob NCRF-PE. Veja-se o que
acontece:

```
labor.absorbed-evening          ambos recusam: `not-a-financial-fact`   COMPARÁVEL
                                mesmo conjunto de códigos, mesmo URI de taxonomia

compute.reserved-block-idle     os EUA dão 6250, PT dá 6226             NÃO COMPARÁVEL
                                dois planos; nada os mapeia
```

⭐⭐ **As recusas comparam-se e as posições não, e isso não é uma incoerência — é o resultado.** Um
código de recusa vem de um conjunto que é deliberadamente partilhado entre jurisdições; uma posição
num plano de contas não. O modelo transporta ambos como `BorrowedTerm`, que nomeia a autoridade ao
lado do valor, portanto **a comparação ou junta ou não junta.** Sem NULL, sem uma comparação
silenciosa `6250 ≠ 6226` entre cadeias de texto sem relação. ↑ *é a [divisão relacional e a
condição de junção](#do-lado-relacional) a fazer trabalho de contabilidade: a comparabilidade É a
cláusula `ON`.*

Portugal tem um plano nacional sob o SNC. Os Estados Unidos não têm nenhum, portanto a sua
testemunha cita o da própria entidade. **Um modelo que guardasse uma posição como código nu
tê-los-ia comparado e reportado concordância.**

**Isto não é provado por consulta nenhuma deste diretório, e dizê-lo é a coisa honesta.** Os
documentos de cobertura não são carregados — não transportam quantidades, portanto não são matrizes
e não há aqui nada para uma junção fazer. A prova é
[`tests/coverage_parse.rs`](../../tests/coverage_parse.rs), em
`two_regimes_are_comparable_where_they_share_an_authority`, que afirma ambas as metades: que as
recusas se comparam **e** que as posições não. Uma afirmação cuja prova vive noutro sítio deve dizer
onde, em vez de pedir emprestada a autoridade da secção em que está.

### Uma eliminação é o único lançamento que torna um número mais pequeno

⛔⛔⛔ **E UMA REDUÇÃO NÃO EXPLICADA É A FORMA QUE TODOS OS ESCÂNDALOS CONTABILÍSTICOS TÊM EM
COMUM.** Portanto o `Elimination/observed` é obrigatório, e o `Elimination/against` é obrigatório,
porque uma eliminação que não diga *qual das três quantidades* remove é um ajustamento aplicado ao
número que o leitor tiver por acaso na mão.

As três são `demand`, `nameplate`, `draw` — o que foi pedido, o que foi comprometido, o que foi
servido. Uma norma de consolidação elimina **saldos**; estes não são saldos, que é a razão de este
modelo contribuir a distinção em vez de emprestar uma.

**A `nameplate` elimina-se muito mais raramente do que parece**, e a assimetria é a parte
interessante: as pessoas de dois membros são dois conjuntos de pessoas, portanto a capacidade
nominal de mão de obra quase nunca se elimina. Uma reserva que um membro detenha e **revenda** a
outro elimina-se. Se a sua consolidação está a compensar capacidade com a mesma liberdade com que
compensa rédito, uma das duas coisas está errada.

### ⭐⭐ A pergunta que o seu auditor faz, e a que o modelo não sabia responder até este mês

*Alguém foi procurar a dupla contagem?*

Durante duas revisões a resposta era indeclarável. Uma fusão que tinha sido verificada e estava
limpa e uma fusão que ninguém tinha examinado produziam **os mesmos bytes** — uma lista vazia de
eliminações. O que quer dizer que a reconciliação `Σ partes − eliminações = consolidado` era
**exata para as fusões que declaravam uma e um encolher de ombros para as que não declaravam
nenhuma**, e nada no documento dizia qual se estava a ler.

```
eliminations absent none          verificado, limpo -> Σ partes tem de igualar a figura consolidada
eliminations absent unmeasured    NÃO VERIFICADO    -> nenhuma igualdade devida; reportar NÃO VERIFICADO
eliminations absent notApplicable uma só parte      -> nada que possa ser contado duas vezes
```

**Três veredictos, e não dois.** Um verificador tem de conseguir dizer *não verificado*, porque
reportar uma passagem numa reconciliação que ninguém executou é a mesma falha que reportar uma
passagem numa regra que não examinou linha nenhuma. → **[§6](#6-o-zero-que-afinal-eram-dois)**

### Onde o instinto de um contabilista está errado, e vale dez minutos

Tudo o que está acima é aritmética em que já se confia. Este é o único sítio onde o hábito corrente
se parte, e parte-se em silêncio.

**Compensar dois intervalos não se faz componente a componente.** Dada uma capacidade comprometida
de `[9, 10, 11]` e uma procura de `[8, 12, 15]`, a falta *não* é `[9−8, 10−12, 11−15]`. O **pior
caso de uma diferença emparelha o pior de um lado com o melhor do outro**: menos capacidade contra
mais procura.

```
melhor caso   11 − 8   =   3 de sobra
pior caso      9 − 15  =  -6 em falta      <- E NÃO 11 − 15
```

Faça-se componente a componente e o limite inferior emparelha a capacidade da semana boa com a
procura da semana boa, que é um cenário que descreve **uma semana duas vezes** e subestima o lado
mau pela largura inteira dos dois intervalos. É o mesmo erro que traduzir um intervalo à taxa do
melhor caso e ao volume do pior caso ao mesmo tempo. → **o argumento completo, e onde volta a
morder numa consolidação, está em [`r = n − d` inverte os
extremos](#r--n--d-inverte-os-extremos).**

**E a mesma armadilha tem uma forma de conversão.** Um fator cambial ou de unidade multiplica
*tanto* a capacidade *como* a procura da parte que converte, portanto as duas figuras convertidas
ficam **correlacionadas**, e subtraí-las conta duas vezes a dispersão do fator. Isto não é
hipotético: o conjunto tem uma consolidação onde rederivar um resto a partir das figuras
convertidas dá `[1092, 2857, 4198.8]` contra um declarado `[1414, 2857, 4085.6]` — **idênticos na
moda, errados nos dois extremos.** → **[§4](#4-φ-correlacionado-consigo-próprio)**

### ⭐⭐⭐ E a razão de tudo isto estar a ser escrito

**O resto está fora do balanço por construção, e ambos os regimes o dizem pelas mesmas palavras.**

Um serão que um engenheiro a recibo verde absorve não tem contraparte e por isso não tem transação.
Não há nada que reconhecer, base de mensuração nenhuma a aplicar, posição nenhuma a codificar — e
perguntados onde assenta, o US GAAP e as NCRF-PE **devolvem ambos `not-a-financial-fact` do mesmo
conjunto de códigos.**

Essa é a resposta correta e este modelo não a disputa. O que diz é que *a quantidade continua a
existir e alguém continua a suportá-la*, portanto precisa de uma casa que não seja o razão. Todo o
aparelho acima — os amortecedores, os detentores, as ausências tipificadas — é a forma dessa casa, e
a recusa contabilística é a prova de que ela é precisa e não um argumento contra ela.

**A única coisa que refutaria esta secção**: um normativo que O CODIFIQUE. Se o vosso regime tem uma
posição para capacidade absorvida sem contraparte, essa é a coisa mais valiosa que nos podem
devolver, e o [`assets/corpus/coverage-us-gaap.xml`](../corpus/coverage-us-gaap.xml) mostra a forma
que uma resposta toma — incluindo `exception`, que é como uma testemunha discorda do conjunto **de
propósito** em vez de parecer um erro que alguém deixou de perseguir.

---

## Do lado da álgebra linear

**[A secção financeira](#do-lado-financeiro) é o mesmo assunto com a notação tirada**, e não é uma
simplificação: `FΦx − e` lá e `FΦx − e` aqui são uma só expressão. O que esta secção acrescenta é a
parte com que uma consolidação não tem de se preocupar, porque um razão contém números e este modelo
contém **intervalos** — e um intervalo subtrai, converte e compõe por regras que não são as que um
número obedece.

Lida como álgebra linear, uma declaração declara isto.

| | forma | uma entrada é |
|---|---|---|
| `d`, `n`, `q` | L | a procura, a capacidade nominal comprometida e o quantum de uma camada |
| `r = n − d` | L | o resto, e todo o assunto |
| `D` | P×L | o que a operação *p* consome da camada *l*, agora |
| `N` | P×L | o que a operação *p* compromete na camada *l*, mais tarde |
| `C` | L×L | uma dependência **observada** entre dois restos |
| `H` | L×5 | quem suporta o resto da camada *l*, e quanto |
| `S` | L×3 | quanto cada um dos três amortecedores leva |
| `F` | L×P | que declarações-parte compõem em que camada |
| `Φ` | diag | o fator que converte cada parte na unidade composta |
| `e` | L | quantidades contadas em duplicado entre partes, subtraídas uma vez |

Três delas não são o que parecem.

### `DᵀN` compõe-se, mas as suas quantidades não

`DᵀN` é a maneira óbvia de reunir estrutura entre camadas, e a consulta calcula-o em oito linhas.
Depois leia-se a coluna da unidade: `pessoas * lançamentos`. Cada camada transporta a sua própria
unidade, portanto o produto não é uma taxa de coisa nenhuma. **A incidência compõe-se e dá
alcançabilidade; as quantidades não.** Também não há contagem de disparos por operação,
deliberadamente, porque a sequência e o tempo são trabalho do BPMN. → **e neste conjunto está
vazio: [§2](#2-dᵀn-o-bom-zero)**

### `r = n − d` inverte os extremos

Subtrair intervalos cruza os índices: o **inferior** de `n − d` emparelha o inferior de `n` com o
**superior** de `d`. Faça-se ao contrário e todos os restos saem do avesso. A consulta escreve o
cruzamento à vista:

```sql
n.amount_low  - l.demand_high AS r_low,
n.amount_high - l.demand_low  AS r_high
```

Depois recalcula o ajustamento a partir desses extremos e compara com o que o documento declarou.
**Trinta e duas camadas, trinta e duas concordâncias.** É o critério da própria ISO 286 — um ajustamento
compara dois *intervalos*, e não dois pontos — e o XSD não o consegue enunciar de forma nenhuma.
→ **verificado independentemente na [§1](#1-o-ajustamento-recalculado-a-partir-dos-intervalos)**

### `Φ` está correlacionado consigo próprio, e o conjunto prova-o

O que vale o exercício inteiro. Um fator de conversão multiplica **tanto** a capacidade nominal
**como** a procura da mesma parte, portanto os dois intervalos convertidos movem-se em conjunto.
Subtraiam-se como se fossem independentes e a dispersão de `Φ` é contada duas vezes:

```
convertido diretamente, como declarado   1414.0   2857.0   4085.6
rederivado a partir dos totais compostos 1092.0   2857.0   4198.8
```

Coincidem na moda e em mais lado nenhum, porque a moda é o único ponto onde `Φ` é um número único
sem dispersão que duplicar. **Ambas as figuras estão aritmeticamente corretas. Só a primeira é o
resto.** → **verificado na [§4](#4-φ-correlacionado-consigo-próprio)**

### E a regra da fusão confere

`x_composta = F Φ x_partes − e`, ao longo de onze camadas compostas, exata nos três extremos.

Estava errada da primeira vez que correu, porque me esqueci do `e`. As eliminações são o termo que
se deixa cair, e numa camada isso são 90 GPU-hora de procura contadas nas declarações de dois
membros ao mesmo tempo. Nada avisa — os totais saem plausíveis e errados.
→ **como produto matricial a sério na [§3](#3-fφx--e-como-produto-matricial-a-sério)**

---

## O que construir isto encontrou

Três coisas, nenhuma visível a partir do XSD nem do Rust.

### O absorvedor é um termo emprestado, e o meu primeiro DDL bifurcou-o

Declarei `absorber buffer` como uma enumeração de três valores. O conjunto de documentos recusou-se
a carregar:

```
ERROR:  invalid input value for enum buffer: "capacidade"
```

A declaração portuguesa cita uma **edição traduzida** do *Factory Physics*; o seu absorvedor é
`capacidade`. Essa declaração está correta. A minha enumeração é que era a bifurcação, e o README
di-lo por estas palavras: *«um conjunto de valores reescrito é uma bifurcação, e uma bifurcação
afasta-se sem que nada aqui o consiga notar.»* Portanto o valor viaja com a autoridade que o define,
e decidir que `capacidade` significa o mesmo amortecedor que `capacity` é um passo que um **leitor**
dá de propósito — a `buffer_term` guarda esse juízo à vista.

Aconteceu mais duas vezes. Um `boolean NOT NULL` para discreto-ou-contínuo encontrou um documento
que declara a divisibilidade como ausência tipificada: três estados, coluna de dois valores.
**Sempre que uma coluna aqui teve menos estados do que o facto que continha, o conjunto encontrou-o
à primeira execução.**

### Um facto, duas grafias, e uma regra que via uma delas

O idiomatismo para um zero medido é `absent reason="none"` — *«alguém foi ver e é zero.»* Nada
proíbe declará-lo como uma afirmação de `[0, 0, 0]`, que afirma o mesmo. As regras de presença e de
exposição ancoravam-se apenas na ausência, portanto quem declarasse escolhendo a outra grafia era
**silenciosamente saltado pelas duas** — e uma regra que salta é indistinguível de uma que passa.

Ambas as grafias são aceites agora, e uma décima segunda verificação reporta a própria ambiguidade,
porque quem receba e compare duas declarações não pode tratar as duas formas como um só campo.
Reportado, e não legislado: o esquema não o enuncia como regra e se deve fazê-lo é uma questão em
aberto.

### Nada no conjunto diz para que documento aponta uma referência de parte

Uma composição nomeia as suas partes por uma notação e um id —
`urn:example:filing:us-member:2026-08-31` / `compute`. **Documento nenhum declara a sua própria
notação.** A `Composition` transporta witness, observedAt, provenance, regime, citation e fusion, e
nada que diga *«eu sou esse URN.»* O `pm:processModulus` também não.

Portanto uma referência de parte não pode ser resolvida a partir do conjunto de todo, e a regra de
conformidade que diz *«a declaração de uma ponta de dependência existe, e a camada nomeada está
lá»* pressupõe uma consulta que o modelo não fornece. O `ingest.sql` preenche a `filing_identity` a
partir dos **nomes dos ficheiros**, o que é um palpite, escrito como tal.

Escrever uma chave externa foi o que o encontrou. Uma chave precisa de algo para onde apontar, e não
havia lá nada.

---

## O que as consultas podem e não podem dizer

O `rules.sql` imprime três tabelas, e a diferença entre elas é a maior parte do desenho.

**1. Violações.** Linhas que falham uma regra. Vazio é o bom resultado.

**2. Reencaminhamentos.** **Não são violações, e não são passagens.** Coisas que uma consulta
consegue *encontrar* e que só uma pessoa consegue *resolver*. Um acoplamento cujas duas pontas se
fundem numa camada um nível acima é absorvido por essa fusão, e a fusão deve uma frase a dizê-lo —
detetar a estrutura é mecânico, julgar se a frase existe e quer dizer aquilo não é. **Uma execução
limpa tem linhas aqui e isso está correto**, que é a razão de não estarem misturadas com as de
cima:

```
uma fusão que absorva um acoplamento entre as suas próprias partes tem de o dizer
  merge-group-composition  compute-us -> compute-pt   para merge-holding-composition/compute
  merge-group-composition  labour -> on-call          para merge-holding-composition/staff
```

Também reportado aqui: a cobertura do `narrowsWhen`. A anotação diz *«uma afirmação sem ele é mais
fraca, e quem recebe tem direito a dizê-lo»* — portanto quem recebe di-lo com um número. **20 de 26
procuras com intervalo (77%) recusam-se a dizer o que as estreitaria.** Julgar se uma dada frase
estreitaria *de facto* o intervalo é prosa. Contar que afirmações se recusam a oferecer uma não é.

**3. Cobertura**, e esta importa mais do que a primeira:

```
uma afirmação com intervalo não declara narrowsWhen como notApplicable           37   ok
o sinal concorda com a comparação de intervalos                                  33   ok
um quantum é expresso na unidade da capacidade nominal que divide                32   ok
a capacidade nominal é múltiplo inteiro do quantum                               32   ok
as parcelas declaradas somam a grandeza                                          20   ok
uma referência de parte resolve para uma declaração que está aqui                19   ok
uma janela é notApplicable só onde a unidade não tem denominador                 16   ok
nenhuma camada-folha é alcançável por dois caminhos                              10   ok
um ajustamento de folga exclui customer e unrealised                              9   ok
uma margem é expressa na unidade das parcelas que limita                          6   ok
uma fusão que absorva um acoplamento entre as suas partes tem de o dizer          5   ok
um acoplamento atenua-se numa fusão, limitado pela quota da parte                 4   ok
uma fusão só chama malformada à dupla contagem quando tem uma parte               4   ok
um zero medido é declarado como ausência, e não como afirmação de zero            3   ok
uma parcela não excede a margem do amortecedor que a absorveu                     3   ok
uma oferta que não pode correr acima nomeia quem ficou por servir                 3   ok
uma janela é transportada através de uma fusão e nunca somada                     3   ok
a exposição não excede a margem mais as parcelas por servir                       3   ok
uma parte local nomeia uma camada da sua própria pilha                            2   fina
as partes locais não ciclam                                                       2   fina
uma margem de tempo derivada precisa de uma janela que o permita                  1   fina
um valor pontual declara narrowsWhen como notApplicable, por não ter intervalo    0   VÁCUA
```

**A última linha é a maquinaria a funcionar**, e não um defeito dela. Apanha um erro real — um
valor pontual não tem intervalo para estreitar, portanto um `narrowsWhen` num deles é uma cópia ou
uma afirmação declarada com a largura errada — e este conjunto não contém nenhum, portanto não prova
nada aqui e di-lo. Uma regra reportada como `ok` quando não examinou nada é o
zero perigoso; uma regra reportada como VÁCUA é uma regra em que se pode confiar quanto ao resto da
tabela.

⭐⭐ **Quatro destas linhas são novas e nenhuma delas é uma ideia nova.** Cada uma já estava escrita
na prosa dos esquemas e era INVERIFICÁVEL, porque em cada caso o estado de que depende era um branco
— uma lista vazia, um elemento em falta, uma enumeração omitida — e um branco não tem razão por que
agrupar. *Uma janela é transportada através de uma fusão e nunca somada* é a mais afiada: apanhou um
defeito vivo à primeira execução, uma camada composta que tinha deixado cair o ciclo de
funcionamento da sua parte, onde a queda era idêntica byte a byte a uma linha que corre sete dias
por semana. → **[§6](#6-o-zero-que-afinal-eram-dois)**

Outras três são finas pela mesma razão que os testes em Rust o são: quase nada no conjunto declara
uma margem numérica, e a composição local é exercitada por um único documento de estipulação.

### Acoplamentos, e as três formas em que aparecem

`C` é o falsificador do próprio modelo — a pilha é *suposta* ser de camadas independentes, portanto
cada entrada não nula é alguém a reportar que a suposição falhou. Cinco acoplamentos, três formas, e
cada forma verifica-se de maneira diferente:

| forma | no conjunto | o que se pode verificar |
|---|---|---|
| um acoplamento dimensionado numa declaração plana | `refutation compute→labour` | que transporta a sua observação de todo |
| **a propagar-se através de uma fusão** | `group labour→shift-line` torna-se `holding staff→shift-line` | **que ATENUOU** |
| **absorvido por uma fusão acima** | `group compute-us→compute-pt`, `group labour→on-call` | quais — e depois uma pessoa |

⭐⭐ A do meio é a boa verificação, porque o teto vem de dois *outros* documentos. Se `labour` está
acoplado a `shift-line`, e `labour` é fundido em `staff` um nível acima, o acoplamento sobrevive mas
enfraquece: a camada composta é só em parte `labour`, portanto no máximo a quota de `labour` nela se
pode mover.

```
quota de labour em staff       [0,819; 0,804; 0,793]
acoplamento do grupo × quota   [0,082; 0,177; 0,277]   <- o teto
acoplamento declarado na holding [0,06; 0,15; 0,26 ]   OK nos três extremos
```

Nada em qualquer das declarações enuncia esse teto. É uma junção através de uma composição, de uma
fusão e das procuras de duas camadas, e quem declarasse podia ter posto ali qualquer número.

### As regras foram verificadas partindo coisas

Quatro edições dentro de uma transação revertida — um ajustamento reposto na leitura de dois
membros, um detentor apagado, uma parcela inflacionada, uma parte apontada a um segundo pai —
produziram **seis** violações, porque partir a soma das parcelas partiu também o limite da margem.
**As regras não são independentes umas das outras**, o que vale a pena saber antes de confiar numa
única execução verde.

### Onde uma linguagem de consulta para

Não em tudo. Junção nenhuma consegue verificar que uma `observation` num acoplamento descreve uma
observação real, que um `narrowsWhen` nomeia algo que estreitaria de facto o intervalo, ou que uma
nota a dizer *«a parcela que se perde é `unrealised`»* concorda com a lista de detentores ao lado.
Isso é prosa contra dados.

O que consegue fazer é a metade entre elementos e entre documentos do modelo, que é a metade de que
o XSD 1.0 desistiu. Essa metade acaba por ser a maior parte dele.

---

# A fundo: a segunda testemunha

Tudo o que está acima é uma testemunha. O `matrices.sql` calcula um número e este documento diz
*vejam, está certo.* Isso é um autor a afirmar.

⭐⭐ O `examples/matrices.rs` extrai as mesmas linhas e calcula com `nalgebra`, onde um produto
matricial é um produto matricial, e depois afirma que os dois concordam. O padrão do próprio
repositório, [`tests/independence.rs`](../../tests/independence.rs), diz que a corroboração entre
duas coisas que partilhem um caminho de código não vale nada — portanto o SQL faz as suas somas com
`GROUP BY` e o Rust fá-las com `gemm`, e a concordância quer dizer que a afirmação foi verificada e
não apenas enunciada.

Os dois partilham o carregamento, e isso não faz mal: o carregamento não é o que está a ser provado.
A aritmética por cima dele é.

**Não há salto silencioso.** Sem `DATABASE_URL` o exemplo não corre. Uma prova que passa sem
executar é o zero perigoso.

### 1. O ajustamento, recalculado a partir dos intervalos

Constrói `d` e `n` como três `DVector` cada — inferior, moda, superior — e faz a subtração cruzada
como aritmética vetorial, uma linha por extremo. Depois classifica cada camada pelo critério da ISO
286 e compara com o `sign` declarado.

```
1. ajustamentos recalculados a partir dos intervalos: 32 camadas, 0 discordâncias
```

Também afirma `n >= 20` antes de afirmar seja o que for sobre as respostas, para que a verificação
não possa passar por não ter examinado nada. ↑ *a afirmação que isto resolve é [`r = n − d` inverte
os extremos](#r--n--d-inverte-os-extremos).*

### 2. `DᵀN`, o bom zero

```
2. D-transposta N: 2 operações consomem e induzem, 0 com ambos declarados
   «Fechar um contrato empresarial» consome de `labour` e compromete `capability`,
      e O CONSUMO ESTÁ POR MEDIR, portanto o produto é vazio.
```

O produto não é calculado porque não pode ser. **A secção reporta porquê em vez de imprimir uma
matriz vazia**, porque a razão é o resultado: a única entrada entre camadas que este conjunto podia
ter está em falta exatamente pela razão de o modelo existir.
↑ *resolve [`DᵀN` compõe-se, mas as suas quantidades
não](#dᵀn-compõe-se-mas-as-suas-quantidades-não).*

### 3. `FΦx − e`, como produto matricial a sério

`F` é construída como matriz de incidência densa — 1 onde uma parte compõe numa camada — e `Φ` como
diagonal. Depois a fusão são três produtos matriciais a sério, um por extremo, e cada resultado é
comparado com a procura que a camada composta declarou.

```
3. F.Phi.x - e contra a procura composta declarada: 11 camadas, todas concordam; 1 suspensa
```

⭐⭐ **É aqui que «um produto matricial é uma junção com um `GROUP BY`» é verificado.** O
`matrices.sql` calcula as mesmas oito linhas com uma junção e uma soma. A mesma resposta, dois
algoritmos.
↑ *resolve [a ideia](#a-ideia-que-as-duas-álgebras-partilham), [a regra da
fusão](#e-a-regra-da-fusão-confere), e a afirmação de que **uma consolidação É esta expressão** —
[do lado financeiro](#do-lado-financeiro).*

### 4. `Φ`, correlacionado consigo próprio

```
4. Phi: declarado [1414, 2857, 4085.6] contra rederivado [1092, 2857, 4198.8]
   Iguais na moda, afastados nos dois extremos, por 322,0 e 113,2.
```

**A asserção aqui era `> 1.0`, e isso estava errado** — um limiar não distingue uma discordância
pequena e real de *nenhuma* discordância. Nenhuma discordância significaria que `Φ` não tem
dispersão, o que tornaria a secção inteira vácua e continuaria a imprimir verde. São agora duas
asserções: primeiro que algum fator tem mesmo dispersão, e depois que os extremos diferem de todo.
↑ *resolve [`Φ` está correlacionado consigo
próprio](#φ-está-correlacionado-consigo-próprio-e-o-conjunto-prova-o) e a armadilha da conversão em
[onde o instinto de um contabilista está
errado](#onde-o-instinto-de-um-contabilista-está-errado-e-vale-dez-minutos).*

### 5. O que custa densificar

A única secção onde a forma matricial **perde**, guardada para o fim porque é mais útil do que uma
volta de vitória.

```
5. C densificada para 8x8: 3 declarações enunciam um acoplamento, 0 afirmam independência, 5 não dizem nada
   Em `values` as 64 entradas são todas 0.0 e indistinguíveis.
```

Uma declaração onde ninguém foi ver e uma declaração onde alguém foi ver e não encontrou nada
tornam-se o mesmo número no instante em que se aloca a matriz. O exemplo transporta uma máscara
`present` ao lado dos valores, que é a única coisa que os mantém separados — **e nada numa matriz
obriga ninguém a transportar uma.**

⭐⭐ **E A MÁSCARA PRECISOU DE UM TERCEIRO VALOR, QUE É O MESMO ARGUMENTO UMA VOLTA MAIS FUNDO.** Um
bit distingue *declarado* de *branco.* Não consegue distinguir TESTADO-E-ZERO de NINGUÉM-FOI-VER — e
esses são veredictos opostos sobre o próprio modelo. A máscara é `0 | 1 | 2` agora, e a contagem
impressa ao lado dela é o número deste ficheiro que mais vale a pena ler.

É por isso que as tabelas são esparsas e não densas, e é o mau zero num ecrã.
↑ *resolve [porque é que as tabelas têm a forma que
têm](#porque-é-que-as-tabelas-têm-a-forma-que-têm) e a [§6](#6-o-zero-que-afinal-eram-dois).*

### 6. O zero que afinal eram dois

Não é uma secção do exemplo — é uma secção do `rules.sql`, e a razão de as cinco anteriores terem
ficado mais afiadas. Cinco codificações nos dois esquemas continham um facto de três ou quatro
valores em dois estados, e todas elas sobreviveram à revisão **porque os seus dois valores estavam
corretos.** Nada num booleano, ou numa lista vazia, aponta para o que ele não consegue dizer.

| o que era de dois valores | o valor que não tinha codificação |
|---|---|
| `Stack/coupling`, elemento sem limite superior | ⭐⭐ *alguém foi ver e as camadas são independentes* |
| `Fusion/elimination`, elemento sem limite superior | *quem compôs verificou e as partes não se duplicam* |
| `Divisibility/window`, opcional | *a unidade não tem denominador, portanto a pergunta é malformada* |
| `Claim/boundOrigin`, opcional | *nada fixa este limite — o intervalo é onde as medições caíram* |
| `CoverageEntry/complete`, o único `xs:boolean` | *a testemunha responde a PARTE da pergunta* |

```
⛔⛔⛔ ALGUÉM TESTOU O MODELO?
+----------------------------------------------+--------+
| a_hipotese_da_independencia           | pilhas |
+----------------------------------------------+--------+
| alguém foi ver e as camadas MOVEM-SE JUNTAS  | 3 |
| NINGUÉM FOI VER                              | 3 |
| uma só camada; não há par para acoplar       | 1 |
+----------------------------------------------+--------+
```

⛔⛔ **Leia-se a linha que não está lá.** Nenhuma pilha deste conjunto afirma independência. A
afirmação central do modelo — a de que uma camada é um sítio onde um resto é suportado
*independentemente do de todas as outras* — nunca foi testada em oito declarações, e foi uma vez
contradita. Isso é um facto sobre a PROVA e não sobre um documento qualquer, e só é um facto porque
a lista vazia deixou de ser uma resposta.

**A mesma forma um documento acima, e aqui a resposta muda a aritmética.** Uma fusão que declare
`eliminations` como `none` ou `notApplicable` deve uma soma EXATA — a figura composta iguala `Σ`
das partes convertidas, ponto final. Uma que declare `unmeasured` não deve nada e a verificação fica
suspensa. Uma lista vazia comprava em silêncio a primeira leitura para todos os que tinham ganho a
segunda, o que é a regra da soma que a `Elimination` existe para tornar exata, silenciosamente de
volta a um aviso.

**E exigir o `boundOrigin` produziu um resultado que ninguém andava a procurar.**

```
| declarado num elemento irmão (amountOrigin, origem do quantum) | 48 |
| NADA o fixa -- o intervalo é onde as medições caíram           | 68 |
| ninguém perguntou                                              |  3 |
| alguém é dono dele: contractual / intrinsic / policy           |  5 |
```

Cerca de um terço do conjunto responde `derived`, o que quer dizer que **o modelo já enuncia o autor
desse extremo num elemento irmão e não tinha maneira de apontar para ele.** O
`Nameplate/amountOrigin` e o `LumpyQuantum/origin` estavam a fazer o trabalho para a metade da
capacidade nominal de todas as declarações enquanto o `boundOrigin` ficava em branco três linhas
adiante — obrigatório e embrulhado num caso, opcional e silencioso no outro, na mesma sequência.
↑ *resolve [porque é que as tabelas têm a forma que
têm](#porque-é-que-as-tabelas-têm-a-forma-que-têm).*
