# `assets/fixtures/`: os estados a que o corpus não chega, escritos de propósito

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`README.md`](../../../assets/fixtures/README.md).

Os documentos do [corpus](../corpus/) contam o que alguém viu num sistema real, e só passam, por
isso, pelos estados que as empresas de facto declaram; os que o esquema admite e ninguém declarou
ficariam sem documento nenhum que os pusesse à frente das regras, e é para esses que existem as
fixtures. Cada uma é uma estipulação, um documento escrito de propósito em que nada foi observado e
de que nada se pode citar como prova acerca de um negócio, e di-lo duas vezes: num comentário no
topo do ficheiro, para quem o abre, e no `pm:evidence`, com `stipulation`, para quem o recebe. A
exceção é a `every-draft.xml`, cujo estado é justamente o de não dizer nem uma coisa nem outra; o
comentário, esse, também lá está.

## Contadas à parte

O `ingest.sql` lê de uma pasta e da outra para as mesmas tabelas, e as regras do rol correm sobre o
que vem de ambas, mas as contagens de uma nunca se juntam às da outra:

| | `assets/corpus/` | `assets/fixtures/` |
|---|---|---|
| o que declara o `pm:evidence` | `observation` | `stipulation` |
| o que se pode citar | o que alguém viu no sistema que o documento descreve | nada |
| as regras do rol | correm sobre os documentos | correm sobre os documentos, que é para isso que existem |
| o conjunto que os reúne | `scope/corpus.sqlc` | `scope/fixtures.sqlc` |
| uma classe vazia no censo | um estado que nenhuma declaração real produziu, e o documento que vale a pena ter a seguir | um estado que o repositório nunca teve de inventar, e a fixture que falta escrever |

Juntar as duas transformava uma constatação numa mentira. A `every-absence.xml` declara as camadas
de uma padaria independentes umas das outras, depois de alguém ter ido ver (`couplings` ausente, com
`none`), coisa que nenhum documento do corpus declara; contada como prova, responderia que sim à
pergunta sobre se alguém já pôs à prova a independência entre camadas, um sim que ninguém ganhou.
Por isso o censo das classes corre duas vezes, uma sobre cada conjunto:

```sh
psql -d process_modulus -f assets/sql/reports/classes_in_the_corpus.sql
psql -d process_modulus -f assets/sql/reports/classes_in_the_fixtures.sql
```

Cada linha é uma classe de uma classificação, com quantos casos lhe cabem na coluna `balls`, e o
que importa são os zeros, que se leem de maneira diferente em cada lista: na primeira, um zero é um
estado que o modelo admite, que uma consulta calcula e que nenhuma declaração real produziu, e o que
pede é um documento, de uma entidade que o declare ou de um instrumento que o deixe medir; na
segunda, é um estado que nenhuma fixture exercita, uma falha de cobertura que se resolve escrevendo
a fixture que falta.

## Que estado traz cada uma

| ficheiro | o estado |
|---|---|
| `every-absence.xml` | uma padaria inventada que junta num só documento as camadas declaradas independentes depois de alguém ter ido ver (`couplings` com `none`), um forno ativo o período inteiro numa oferta medida por dia, um `sign` deixado ao cálculo de quem recebe, com a derivação `fit`, e outro `unmeasured` numa capacidade que ninguém mediu, o `notApplicable` num balcão medido por um rácio, que ninguém compromete nem se compra em unidade nenhuma, e vários `none` e `unmeasured` que nenhum documento real declara, do plano de contas que não existe à posição de uma operação no modelo de processos |
| `every-elimination.xml` | duas fusões sem nada eliminado que devem contas diferentes: com `none`, alguém procurou contagens a dobrar e não as achou, e o valor composto tem de dar exatamente a soma das partes; com `unmeasured`, ninguém procurou, nada tem de bater certo, e a procura declarada afasta-se de propósito da soma sem que a regra a acuse, porque a deixa suspensa |
| `every-claimed.xml` | uma cobertura com `claimed` em `partial`: a testemunha responde a parte da pergunta e diz qual, estado em que nenhuma testemunha real do corpus está e que, escrito numa cobertura real, poria palavras na boca de um normativo |
| `every-local-part.xml` | a construção que um terceiro faz de ponta a ponta: traz uma camada de outra declaração tal como está, escreve ao lado a sua própria leitura dela e faz uma terceira camada a partir das duas, que continuam separáveis; o documento diz quem é (`notation` com `uri`), e uma parte que aponta para essa mesma notação é uma parte local. Somadas, as duas leituras contariam a mesma quantidade duas vezes, e uma eliminação do tamanho de uma delas tira a cópia |
| `every-partial-elimination.xml` | uma eliminação que tira só parte do que as partes declaram: duas equipas, cada uma com os seus turnos e com um bloco que ambas contam, e a fusão retira esse bloco uma vez, em vez de uma parte inteira, pela mesma regra da soma |
| `every-inverting-elimination.xml` | uma eliminação mais larga do que a soma que corrige: duas partes com capacidade nominal de valor único e um bloco partilhado cujo tamanho é um intervalo, em que tirar o bloco ponto a ponto poria o valor mais baixo acima do mais alto; onde o bloco é maior o grupo detém menos, e a capacidade composta declara-se juntando o valor baixo da soma ao alto do bloco |
| `every-derived-elimination.xml` | uma eliminação declarada como derivação, `sharedParts`, em vez de valor ou de ausência; como as partes não chegam a nenhuma camada comum, nada calcula esse valor, a soma da capacidade nominal fica suspensa e a capacidade composta fica na palavra de quem compõe, enquanto a soma da procura, com a eliminação declarada a zero, continua devida e é verificada |
| `every-unserved-excess.xml` | um excesso sem saída: ajustamento `interference` numa linha com os três amortecedores declarados e todos vazios, de modo que nada absorveu o excesso, o `absorber` declara `none`, e quem o suporta são só os dois que ficam com procura por servir, `customer` e `unrealised` |
| `every-unsized-conversion.xml` | uma conversão que ninguém mediu, `Part/factor` ausente com `unmeasured`, que não é o mesmo que uma parte sem `factor`, já na unidade composta; tratá-la como se as unidades coincidissem afirmaria uma taxa que ninguém declarou, pelo que a soma dessa fusão fica suspensa |
| `every-draft.xml` | o documento que quem adota o esquema tem nas mãos ao princípio, uma camada escrita e mais nada: sem identificador (`notation` com `unmeasured`), sem que alguém tenha perguntado que mais do sistema seria camada (`scope` com `unmeasured`) e sem dizer se observou ou estipulou (`evidence` com `unmeasured`); sem identificador, nenhuma composição o pode citar |
| `every-unit-cycle.xml` | conversões que, de unidade em unidade, regressam à de partida, de GPU a hora-GPU, a hora-nó e de novo a GPU, enquanto as camadas seguem em cadeia e nenhuma se compõe de si própria; uma quantidade convertida a volta inteira não regressa exatamente ao valor de partida, até porque um mês não tem um número fixo de horas, e a regra pede apenas que esse valor caiba no intervalo que a volta dá |
| `every-nested-conversion.xml` | duas conversões encadeadas, de execuções de linha a horas e de horas a lotes, nenhuma de valor fixo; o resto do nível de cima calcula-se a partir do resto já convertido do nível do meio, e não da diferença entre a procura e a capacidade nominal deste, e as quotas que o documento declara batem com o resto calculado assim, nível a nível |
| `every-derived-quantity.xml` | valores compostos declarados como derivação `fusionSum`, que quem recebe calcula a partir da fusão: a procura de uma composição, o consumo de outra e a capacidade nominal de uma terceira; uma composição feita sobre outra só se verifica calculando primeiro a de baixo, e onde uma parte não tem consumo medido, a soma do consumo deixa de ser devida |

## O que uma fixture não mostra

Uma fixture mostra que um estado se alcança: o documento valida contra o seu esquema, passa pelos
tipos Rust gerados a partir dos esquemas e sai de lá igual, e, quando a base de dados o carrega, as
regras correm sobre ele. Que uma regra apanharia um documento errado, isso uma fixture não mostra, e
é esse o trabalho dos controlos negativos do `tests/fixtures.rs`, que pegam numa fixture, a estragam
em memória, sem tocar no ficheiro, e exigem que a mesma verificação que a aceitava passe a
rejeitá-la. Duas delas, a `every-draft.xml` e a `every-claimed.xml`, nunca chegam à base de dados,
porque só os testes em Rust as leem, pelo que nenhuma consulta e nenhum censo as contam. Quanto aos
números, são todos inventados: servem para pôr o modelo à prova e não dizem nada sobre empresa
nenhuma.
