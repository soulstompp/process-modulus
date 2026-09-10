# `assets/fixtures/` — um documento por estado, e NÃO um segundo conjunto de documentos

> **Grafia do AO90.** A versão inglesa está em [`README.md`](README.md) e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

⛔⛔⛔ **ESTES SÃO ESTIPULAÇÕES, NÃO ARQUIVOS, E A DIFERENÇA É A RAZÃO INTEIRA PELA QUAL A PASTA
EXISTE.** Cada documento em [`assets/corpus/`](../corpus/) é uma afirmação sobre uma empresa: uma
procura que alguém observou, um resto que alguém suportou. Cada documento aqui é uma afirmação sobre
o ESQUEMA: que um estado que ele admite valida, faz a viagem de ida e volta, e é tratado pelas
regras. Nada aqui afirma coisa alguma sobre empresa nenhuma, e nada aqui pode ser citado como prova
sobre uma.

## Por que não podem viver na mesma pasta

Os estados apagados do conjunto de documentos são PROVA. Nenhuma stack em `assets/corpus/` arquiva
`couplings` como `absent/reason = none`, porque ninguém que arquivou nesse conjunto testou se as
suas camadas se movem independentemente, **e isso é um achado sobre o estado da prova**, reportado
pelo `rules.sql` e afirmado pelo `tests/corpus_parse.rs`.

Acrescente-se um `none` ao conjunto para acender o braço e o achado passa a ser mentira. Recuse-se
acrescentá-lo em qualquer sítio e o braço segue sem teste, que é a armadilha que este repositório já
nomeia: *um limite sem nada para limitar é o que passa mais alto.* Duas perguntas que rimam e que
ficam em eixos diferentes, que é a divisão que o próprio esquema traça entre `Verdict` e
`AbsenceReason`.

| | `assets/corpus/` | `assets/fixtures/` |
|---|---|---|
| responde a | isto consegue exprimir uma empresa real? | cada estado admitido funciona? |
| um documento é | uma afirmação sobre o mundo | uma estipulação sobre o esquema |
| um estado apagado significa | **ninguém fez isso ainda**, um achado | uma lacuna de cobertura, um defeito |
| pode ser editado para acender um braço | nunca | é essa a sua função |
| citado em achados como prova | sim | nunca |

## Para que serve cada um

| ficheiro | acende |
|---|---|
| `every-absence.xml` | `StatedCouplings/none`, `window/none`, todo o braço de ausência de `StatedFit`, `boundOrigin/notApplicable`, `StatedDivisibility/none` |
| `every-elimination.xml` | `StatedEliminations/none` e `/unmeasured`, e as duas somas diferentes que devem |
| `every-claimed.xml` | `Claimed/partial`, o valor que o `CoverageEntry/complete` não conseguia transportar |
| `every-local-part.xml` | a construção de três camadas: a deles, a minha, uma feita das duas, e o `StatedNotation/uri` sob uma parte LOCAL |
| `every-partial-elimination.xml` | o meio da escala de eliminação: um `e` de valor nominal que não é zero nem uma parte inteira, pelo que o `e` se lê como MAGNITUDE e não como espécie de fusão |
| `every-unsized-conversion.xml` | o braço ausente de `Part/factor`: uma conversão que ninguém mediu, que não é uma parte que não precisa de nenhuma |
| `every-draft.xml` | `StatedNotation/unmeasured`, `StatedScope/unmeasured` e `StatedEvidence/unmeasured`, o documento que quem adota pela primeira vez tem de facto, incluindo o único estado em que nem chega a dizer se observou alguma coisa |
| `every-unit-cycle.xml` | um CICLO NO GRAFO DAS UNIDADES: três camadas cujas conversões vão de GPU a GPU-hora a nó-hora e de volta, para que se possa sequer perguntar por uma viagem completa. O grafo das partes fica uma cadeia e nada é composto a partir de si mesmo, são as UNIDADES que dão a volta |
| `every-nested-conversion.xml` | uma CONVERSÃO COM LARGURA POR BAIXO DE UMA CONVERSÃO COM LARGURA, que é o estado em que um resto composto deixa de ser calculável um nível de cada vez. Três camadas em cadeia, ambas as arestas com um fator com largura, e as quotas de detentor arquivadas a concordar com a figura recursiva e não com a de um nível, pelo que um leitor que pare demasiado cedo acusa um arquivo correto |

**Um fixture prova alcançabilidade, nunca correção.** Que um documento que arquiva
`claimed = partial` valide diz que o estado existe; nada diz sobre se um executor reporta `notable`
para uma testemunha que responde além dele. Os controlos negativos em `tests/fixtures.rs` são a
outra metade, e mutam um documento já lido em vez de ler um ficheiro, porque o que verificam é se o
VERIFICADOR morde.

⭐ **Os três verbos no topo deste ficheiro aterram em três sítios e só um deles é o
`tests/fixtures.rs`.** É um validador que faz a validação. O `tests/roundtrip.rs` faz a viagem de
ida e volta, percorrendo esta pasta ao lado do conjunto de documentos, para que um estado que o
esquema admite seja também um estado que o crate gerado consegue escrever de volta e voltar a ler.
As regras são o terceiro.
