# `conformance/`: o que um perfil pode estreitar e as regras a que nenhum validador chega

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`conformance/README.md`](../../conformance/README.md).

O esquema base valida a forma de qualquer declaração e deixa, de propósito, duas coisas para quem
vem depois. Uma é o perfil, um esquema à parte que aperta a validação dos documentos que reportam
sob um regime com lista de códigos publicada, coisa que o esquema base não pode fazer sem reescrever
a lista de outra autoridade; a outra são as regras que o esquema enuncia em prosa e a que nenhum
validador chega, e essas ficam a cargo de quem implementa, cada qual com a consulta que a corre,
quando a há. Quem já tem um corpus seu e vai adotar o modelo encontra em
[`adoption.md`](adoption.md) a maneira de reconhecer, nos próprios ficheiros, as formas que o
esquema recusa, a começar por uma lista alheia reescrita em casa.

## Um valor emprestado, e a lista que o confirma

Sempre que uma declaração usa um valor que o modelo não possui, seja um normativo, um plano de
contas ou uma base de mensuração, leva-o como termo emprestado, com a taxonomia de onde veio e o
valor que dela tirou, e o esquema exige as duas metades, já que um valor sem a sua autoridade não
quer dizer nada. O valor, esse, o esquema não o consegue confirmar: a maior parte do vocabulário
contabilístico vive em texto normativo e não numa lista publicada, o `historicalCost` e o
`fairValue` estão definidos em prosa na ASC 820 e na IFRS 13, e não há ali nada que um esquema
possa importar. O que o validador garante é que o documento diz a que autoridade foi buscar cada
termo, o que já torna a afirmação verificável por quem lê, ou por um validador a jusante que conheça
a lista.

Um perfil é esse validador a jusante: um esquema próprio de um regime, que importa a lista que esse
regime publica e só aceita, nos documentos que o reclamam, os valores que lá estão. Pode ainda
alinhar as respostas de uma testemunha com o plano de contas do regime, uma vez que a `taxonomy` do
`chart` é o próprio plano, o mesmo URI que uma posição em `asrt:Answer/holds` tem de levar, e o
teste `every_position_is_held_in_a_chart_its_own_document_declares` faz essa conferência para as
coberturas deste repositório. É uma adição ao esquema base e não um redesenho, e segue quem adota em
vez de o preceder, pelo que o repositório não traz perfil nenhum feito.

## Portugal, quatro normativos em duas codificações

Um regime não é uma lista só, são três eixos: onde, que é o `jurisdiction`; sob que normativo, que é
o `framework`; e quem o codifica, eixo que vai dentro do próprio termo emprestado, na taxonomia. É
este terceiro que decide a que se prende um perfil, e Portugal mostra porquê. A mesma entidade, sob
o mesmo normativo, tem códigos diferentes nas listas das duas autoridades que o codificam, listas
que não coincidem, já que no referencial do SAF-T o `NCRF` e o `NCRF-PE` caem ambos em `S` e o `O`
não tem correspondente no `AnexoASNC` da IES. Uma microentidade portuguesa é,
portanto, `NC-ME` para a IES e `M` para o SAF-T, e declarar os dois regimes é correto e não um
duplicado, uma vez que o par diz o que nenhum dos dois diz sozinho e o código do SAF-T, menos
detalhado, não volta a dar um só valor do outro; o `assets/corpus/refutation.xml` declara-os assim,
e o teste `one_entity_may_declare_two_regimes` segura-o.

Acresce que é o escalão da entidade, a sua dimensão, que escolhe o normativo, pelo que «Portugal»
são pelo menos quatro normativos em duas codificações, e quem recebe apenas «PT» não sabe que regras
produziram os números. Um perfil prende-se, por isso, a um par, a autoridade que codifica e o
normativo codificado, nunca a um país, e é o `id` de cada regime declarado que lhe permite dizer
qual deles estreita, sem que duas declarações possam ser a mesma em silêncio.

## Onde há uma lista publicada para importar

Um perfil só é possível onde o regime publica mesmo uma enumeração, e Portugal publica duas, uma por
cada autoridade:

| regime | a lista |
|---|---|
| SAF-T PT | o referencial: `S`, `M`, `N`, `O` |
| IES | o `AnexoASNC`: `NIC`, `NCRF`, `NCRF-PE`, `NC-ME` |

Onde a autoridade é prosa, como nas bases de mensuração das normas americanas e das IFRS, não há
lista nenhuma para importar, e escrevê-la aqui seria reenunciar a lista de outro corpo dentro deste
espaço de nomes, a bifurcação que o `BorrowedTerm` existe para impedir e que divergiria da original
sem que nada aqui o notasse. Nesse caso o termo emprestado fica como está, a nomear a sua
autoridade, e quem confere o valor é quem lê.

## Importar a lista e juntar-lhe o que é do modelo

Um perfil escreve-se na mesma linguagem de esquema que o modelo, para que qualquer validador
corrente o corra sem instalar nada: importa o esquema que o regime publica e declara um tipo que une
o que o modelo contribui à lista importada.

```xml
<xs:import namespace="urn:regime" schemaLocation="regime.xsd"/>

<xs:simpleType name="BasisUnderThatRegime">
  <xs:union memberTypes="pm:ContributedBasis regime:Referencial"/>
</xs:simpleType>
```

O `urn:regime` e o `regime.xsd` estão no lugar do espaço de nomes e do ficheiro do regime. O tipo
aceita o único valor que o modelo contribui, o `nameplate`, ou um valor da lista do regime, e mais
nenhum, de modo que um documento que reclame o perfil e traga outro valor deixa de validar; e onde o
que se estreita não é um valor simples mas um elemento, o mesmo faz-se com um `xs:choice`.

## O que um perfil deixa como encontrou

Um perfil importa a lista do regime e nunca a copia para dentro deste espaço de nomes, porque uma
cópia é uma bifurcação, e a primeira revisão da lista original deixa-a para trás sem que nada o
note. Também não desduplica os dois regimes de uma entidade nem escolhe um deles, já que a
microentidade que é `NC-ME` para uma autoridade e `M` para a outra declarou dois factos e não o
mesmo duas vezes. A jurisdição, essa, nunca faz as vezes de um normativo, e nada num perfil se pode
prender ao `jurisdiction`, que é um token nu de propósito: `PT` e `PRT` são duas codificações do
mesmo país, validam ambas, e o elemento não diz qual delas se usou. E o perfil acrescenta sem tirar,
pelo que um documento que não o reclame continua a ser lido apenas contra o esquema base, como se o
perfil não existisse.

## A porta é o esquema, e o Cargo só escolhe o que se lê

O crate gera os tipos de Rust a partir dos esquemas, e uma *feature* do Cargo pode pôr os tipos de
um regime a compilar só para quem os pede. Como menu de leitura isso é legítimo, e uma implementação
que leia documentos portugueses e americanos ao mesmo tempo é uma leitora de dois regimes, o que
está certo; como porta, não serve, porque o Cargo unifica as *features* em todo o grafo de
compilação, de modo que, se um crate liga um regime e outro crate do mesmo grafo liga outro, ambos
ficam com os dois, sem aviso. Um estreitamento escrito como *feature* não estreita nada, e o
alargamento dá-se na compilação de outra pessoa, onde ninguém daqui o vê. O que torna um documento
conforme é o perfil, que qualquer validador corre fora de Rust; uma *feature* pode decidir o que se
lê, e nunca o que se escreve nem o que se julga.

## Quem entra na população de um perfil

Um perfil só julga os documentos que o reclamam, e o que decide se um documento entra é o
`framework` dos seus regimes, que o invólucro deixa responder de quatro maneiras distintas:

| o documento | entra na população do perfil? |
|---|---|
| `framework/term` cujo `(taxonomy, value)` coincide com o do perfil | sim |
| `framework/absent/reason = none` | não: alguém foi ver, e a entidade não reporta sob normativo nenhum |
| `framework/absent/reason = unmeasured` | não se sabe: reporta sob algum normativo que ninguém nomeou |
| nenhum elemento `regime` | não: ninguém disse nada |

Corrido sobre um corpus, um perfil não devolve dois desfechos mas três, e deixa ainda documentos ao
lado:

| | |
|---|---|
| **conforme** | da população, e valida contra o perfil |
| **não conforme** | da população, e não valida, com um valor fora da lista, por exemplo |
| **pertença por estabelecer** | `framework` ausente com `unmeasured`, pelo que o perfil não podia perguntar |
| *(ao lado, e não dentro)* | `framework` ausente com `none`, e nenhum `regime`: fora da população, e distintos um do outro |

A pertença por estabelecer não é conforme nem não conforme, e um relatório que a pusesse num dos
dois lados inventava a resposta que o documento diz não ter. Quanto aos dois que ficam de fora, um
diz que alguém foi ver e não há normativo, o outro que ninguém disse nada, e um relatório que os
juntasse perdia precisamente essa diferença.

## O que o validador não alcança fica a cargo de quem implementa

O XSD 1.0 não tem `xs:assert`, não compara um elemento com outro e não segue uma referência para
dentro de outro documento, pelo que boa parte das regras do modelo, a de as quotas somarem o resto,
a de a capacidade nominal ser um múltiplo inteiro do quantum, a de uma camada composta bater certo
com as suas partes, fica fora do alcance de qualquer validador. O esquema enuncia-as em prosa, na
anotação do tipo a que dizem respeito, e põe-nas sob o título `# O que nenhum validador alcança`,
para que quem lê distinga uma regra que a gramática garante de uma que fica por sua conta. Quem
implementa deve-as todas, e o esquema não lhas pode tirar.

Este repositório corre como consulta a maior parte delas. O rol,
[`assets/sqlc/checks/roster.sqlc`](../../assets/sqlc/checks/roster.sqlc), escreve uma única vez cada
regra que corre, com o seu nome curto, o que é uma linha examinada e a frase do esquema que a
enuncia; o [`assets/sql/rules.sql`](../../assets/sql/rules.sql) corre-as todas sobre as declarações
carregadas, sendo uma tabela de violações vazia o bom resultado; e o
[`assets/sql/reports/coverage.sql`](../../assets/sql/reports/coverage.sql) diz, regra a regra,
quantas linhas examinou e quantas a quebraram, para que uma regra que não examinou nada não passe
por uma regra cumprida.

| a regra | onde | a consulta |
|---|---|---|
| o `low` não passa do `mostLikely`, nem o `mostLikely` do `high` | `Claim` | |
| uma afirmação não guarda valor esperado: este deriva-se dos três pontos, e um valor guardado podia contradizê-los | `Claim` | |
| o `size` do quantum vem na unidade da capacidade nominal que divide, e numa capacidade cotada como taxa o lote é um lote dessa taxa | `LumpyQuantum` | `quantum_unit_mismatch` |
| sob `interference`, numa oferta com os três amortecedores declarados e vazios, quem suporta o resto é sempre `customer` ou `unrealised`, porque o excesso não tinha para onde ir | `Fit` | `nobody_named_as_unserved` |
| sob `transition`, nessa mesma oferta e com exposição acima de zero, pelo menos um dos que suportam o resto é `customer` ou `unrealised` | `Fit` | `nobody_named_as_unserved` |
| o que a procura pode passar da oferta no pior canto não excede o que a folga de capacidade absorve mais as quotas que a declaração admite não ter servido | `Nameplate` | `exposure_unaccounted` |
| o consumo não passa do que a oferta consegue fazer, a capacidade nominal mais a folga de capacidade declarada | `Jagged`, `Nameplate` | `draw_exceeds_the_supply` |
| numa oferta aos lotes, a `nameplate` é um múltiplo inteiro do quantum, nos três pontos | `Remainder` | `nameplate_not_a_multiple` |
| a `quantity` de um resto pode ser uma derivação da `magnitude`, e uma `quantity` declarada é a grandeza que a procura e a capacidade nominal da camada dão | `Remainder` | `stated_quantity_is_not_the_magnitude` |
| um ajustamento `clearance` exclui o `customer` e o `unrealised` de quem suporta o resto, porque ninguém ficou por servir | `Remainder` | `clearance_with_unserved` |
| uma camada que nega ter resto não declara ao mesmo tempo uma procura e uma capacidade nominal, que o dariam | `StatedRemainder` | `denied_remainder_is_not_contradicted` |
| o `sign` declarado concorda com a comparação dos dois intervalos: `clearance` quando a capacidade nominal folga em todo o intervalo, `interference` quando interfere em todo ele, `transition` quando os dois se sobrepõem | `Fit` | `fit_disagrees` |
| as quotas (`share`) de quem suporta o resto somam a grandeza do resto sempre que estão todas declaradas, e uma quota por medir suspende a verificação | `Holder` | `shares_do_not_sum` |
| cada ponta de uma `dependence` aponta para uma declaração que existe, num URI que resolve, e para uma camada que lá está | `FiledLayer` (`assertion.xsd`) | |
| a `version` de cada ponta de uma `dependence` é a edição que foi de facto lida | `FiledLayer` (`assertion.xsd`) | |
| as duas pontas de uma entrada de `dependence` não são a mesma camada da mesma declaração | `DependenceEntry` (`assertion.xsd`) | |
| a testemunha de uma `dependence` não é quem declarou as duas pontas, cuja observação própria vai num `pm:Coupling`, dentro da declaração que atesta | `Dependence` (`assertion.xsd`) | |
| o `filing` de uma parte resolve para uma declaração que está no corpus, e para uma camada dentro dela | `FiledLayer` (`assertion.xsd`) | `unresolved_part` |
| uma parte local nomeia uma camada da pilha do próprio documento | `FiledLayer` (`assertion.xsd`) | `local_part_dangles` |
| duas camadas cujos restos se movem sempre em conjunto são uma só, e as partes locais não andam em roda, uma composta a partir da outra e a outra a partir da primeira | `Layer`, `FiledLayer` (`assertion.xsd`) | `layers_move_together` |
| a figura fundida é a soma das partes, já convertidas, menos as eliminações | `Fusion` (`assertion.xsd`) | `fusion_sum_disagrees` |
| uma eliminação subtrai-se ponto a ponto, sem trocar os limites, porque é parte da própria figura de que sai | `Elimination` (`assertion.xsd`) | `fusion_sum_disagrees` |
| só se funde o que é fungível, quando uma unidade de oferta de uma parte serve a procura da outra, e esse juízo é de quem compõe | `Fusion` (`assertion.xsd`) | |
| o `party` e o `asOf` só aparecem em quem suporta o resto como `counterparty` | `Holder` | |
| quem suporta o resto como `counterparty` nomeia o seu `party` e traz o `asOf` em que isso era verdade | `Holder` | |
| um acoplamento que atravessa uma fusão enfraquece, limitado pela quota da parte acoplada na camada composta | `Coupling` | `coupling_does_not_attenuate` |
| um acoplamento nunca é razão para fundir, porque acoplamento e fungibilidade são eixos independentes | `Coupling` | |
| nenhuma camada-folha se alcança por dois caminhos, nem quando as composições encaixam umas nas outras | `composition` (`assertion.xsd`) | `jagged_layer` |
| as quotas de quem suporta o resto não excedem a folga do amortecedor que o `absorber` nomeia, ficando de fora o `customer` e o `unrealised`, que são o que transbordou | `Nameplate`, `Layer` | `share_exceeds_slack` |
| a folga de uma camada fundida não passa da soma das folgas das partes, e uma parte com a folga por dimensionar deixa esse limite sem dimensão | `Nameplate`, `Layer` | |
| um `factor` ausente vale exatamente um, pelo que só falta onde a parte já vem na unidade da camada composta | `Part` (`assertion.xsd`) | `unit_crossing_without_a_factor` |
| um `factor` é sempre maior do que zero, já que um fator nulo ou negativo trocaria a ordem dos limites | `Part` (`assertion.xsd`) | |
| uma eliminação declara-se depois da conversão, na unidade da camada composta | `Part` (`assertion.xsd`) | |
| o resto de uma parte convertida converte-se diretamente, e nunca se volta a tirar da capacidade nominal e da procura convertidas, que contariam duas vezes a incerteza do fator | `Part` (`assertion.xsd`) | |
| uma `composition` e uma `dependence` que quem consolida declara sobre a mesma consolidação concordam na testemunha, na data e no regime \* | `Dependence` (`assertion.xsd`) | |
| uma parte que atravessa uma fronteira de regime traz o que a reconcilia, com a composição a citar o instrumento e a cláusula | `Composition` (`assertion.xsd`) | `regime_crossing_without_a_citation` |
| o `regime` que quem compõe atribui a uma parte é um dos que a própria declaração dessa parte traz | `FiledLayer` (`assertion.xsd`) | `part_regime_disagrees` |
| uma folga vem na unidade das quotas que limita | `Nameplate`, `Layer` | `slack_unit_mismatch` |
| uma folga medida como duração converte-se em quantidade antes de se declarar, multiplicando-a pela taxa | `Nameplate`, `Layer` | |
| o denominador da unidade de uma afirmação cobre pelo menos um período inteiro da oferta que mede | `Claim` | |
| um `timeSlack` só se deriva da `clearance` numa camada que corre o período inteiro, ou cuja unidade não tem período, porque a derivação supõe a sobra espalhada por igual | `Layer` | `derived_slack_over_a_window` |
| um `boundOrigin` ou um `narrowsWhen` declarado como derivação nomeia uma identidade que calcula a própria posição da `Claim`, e o `amountOrigin` e o `quantumOrigin` são a exceção, só para a borda | `Claim` | `identity_does_not_compute_the_claim` |
| um valor pontual declara o `narrowsWhen` como `notApplicable`, porque não tem intervalo que estreitar | `Claim` | `narrows_a_point_value` |
| uma afirmação com intervalo não declara o `narrowsWhen` como `notApplicable` | `Claim` | `range_says_no_range` |
| um valor pontual não declara o `boundOrigin` ausente com `none`, que diria que a borda está onde as medições caíram | `Claim` | `bound_fell_with_no_range` |
| a `window` é a parte viva do período que o denominador da unidade dá, e nunca é mais comprida do que esse período | `Divisibility` | |
| uma oferta sempre ligada declara uma `window` do período inteiro, em vez de não declarar nada | `Divisibility` | |
| uma `window` passa por uma fusão tal como está, sem se somar nem se perder | `Divisibility` | `window_lost_or_summed` |
| uma `window` declarada como quantum tem um `size`, e não o declara `notApplicable`: uma unidade sem período di-lo um nível acima, com a própria `window` em `notApplicable` | `StatedLumpyQuantum` | `window_size_not_applicable` |
| uma `window` em `unmeasured` também impede que o `timeSlack` se derive da `clearance`, porque ninguém sabe se a sobra está espalhada por igual | `Divisibility`, `Layer` | `derived_slack_over_a_window` |
| a `window` só é `notApplicable` onde a unidade não tem período, como numa existência | `Divisibility` | `window_not_applicable_on_a_rate` |
| as `eliminations` dizem que conta é devida: com `none` ou `notApplicable`, a soma das partes iguala a figura composta; com `unmeasured`, a verificação fica suspensa | `Fusion` (`assertion.xsd`) | `fusion_sum_disagrees` |
| só uma fusão de uma parte declara as `eliminations` como `notApplicable` | `Fusion` (`assertion.xsd`) | `elimination_not_applicable_with_parts` |
| uma fusão de uma só parte, sem nada eliminado, transporta essa parte sem alteração | `Fusion` (`assertion.xsd`) | `one_part_fusion_alters_its_part` |
| uma parte que atravessa uma fronteira de unidades declara o que a converte, porque alguém está a afirmar que as duas unidades se trocam uma pela outra | `Part` (`assertion.xsd`) | `unit_crossing_without_a_factor` |
| converter uma quantidade à volta de um circuito de unidades devolve o que se tinha no início | `Part` (`assertion.xsd`) | `conversion_cycle_does_not_close` |
| uma camada que a composição diz transportar sem alteração concorda com a declaração de onde veio, `absorber` incluído \* | `composition` (`assertion.xsd`) | |

### As três colunas, e o asterisco

Todas as linhas são regras a que o XSD 1.0 não chega. A primeira coluna diz a regra por palavras; a
segunda, o tipo do esquema em cuja anotação ela está escrita, no `process-modulus.xsd` salvo quando
diz `assertion.xsd`; a terceira, o nome com que o rol a corre, e fica vazia quando nenhuma consulta
a corre, caso em que a regra é inteiramente de quem implementa. Um nome pode aparecer em mais do que
uma linha, quando uma consulta segura mais do que uma frase do esquema. O asterisco no fim de uma
regra diz que o esquema a enuncia em prosa sem a marca de não alcançável, o que é um facto sobre o
esquema e não sobre a língua em que se lê.

Quantas regras são, quantas trazem asterisco e quantas têm consulta, isso não se escreve aqui: o
`tests/conformance.rs` conta a tabela, obriga as duas línguas a terem as mesmas linhas, os mesmos
asteriscos e os mesmos nomes, pela mesma ordem, e confere os nomes contra o rol nos dois sentidos,
de modo que nenhuma regra que corre fica de fora da tabela e nenhum nome da tabela fica sem regra
no rol.

### Onde ficam as contas

As regras de aritmética, o resto e o seu ajustamento, as unidades inteiras e o resíduo, as quotas e
as folgas, a composição e o que ela elimina, as conversões e as janelas, não têm fórmula nesta
página, porque cada uma é uma consulta, e o percurso de [`assets/sqlc/`](../assets/sqlc/README.md)
mostra-as uma a uma, desde o resto de uma camada até à estrutura inteira.

Há uma que convém ter presente antes de implementar: a divisão de um resto em unidades inteiras e
resíduo lê-a quem recebe, ponto a ponto, e nunca a declara quem envia, já que o `Remainder` leva o
total e nunca as duas partes. Numa boa parte do corpus o intervalo da procura atravessa um múltiplo
inteiro do quantum, e aí o resíduo lido nos três pontos pode sair fora de ordem, sem que a procura
que o produziu tenha defeito algum; o `tests/corpus_parse.rs` segura as duas coisas, que as duas
partes recompõem o resto em cada ponto e que essa travessia é corrente.

### Schematron, mais tarde, e ao lado

O Schematron é o companheiro habitual do XSD 1.0 para regras deste género, fica ao lado do esquema e
não dentro dele, e por isso não lhe custaria nada; é, no entanto, um segundo artefacto, com
ferramentas próprias, e quem não corre os testes deste crate também não vai correr o Schematron. O
próprio esquema diz dos perfis que devem seguir quem adota e não precedê-lo, e o mesmo vale aqui:
o Schematron fica para quando houver quem o peça, e até lá as regras vivem na prosa do esquema,
marcadas, e nas consultas do rol.
