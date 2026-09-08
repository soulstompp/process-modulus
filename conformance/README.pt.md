# Perfis de conformidade

> **Português europeu, grafia do AO90.** A versão inglesa está em [`README.md`](README.md) e é
> a que o repositório trata como autoritativa quando as duas divergirem. Os nomes dos tipos e
> dos elementos do XSD ficam em inglês, porque são os nomes do esquema.

**Ainda não há aqui nada, e isso é deliberado.** Um perfil deve seguir um adotante real em vez
de o preceder. Este ficheiro explica o que é um perfil, o que pode e não pode fazer, e a que
regras do modelo um validador não chega por si.

Adotar é uma questão distinta de estar conforme, e tem ficheiro próprio. O
[`adoption.md`](adoption.md) descreve o que é infringir as regras do `BorrowedTerm` e da
`Absence` visto de dentro de um conjunto de documentos que já existe, porque um adotante não
pode agir sobre uma regra que não se reconhece a infringir.

## Para que serve um perfil

O esquema base transporta valores que não possui como `BorrowedTerm { taxonomy, value }`, com a
taxonomia obrigatória. Não consegue validar o valor, porque a maior parte do vocabulário
contabilístico tem a sua autoridade em texto normativo e não numa enumeração publicada. O
`historicalCost` e o `fairValue` estão definidos na ASC 820 e na IFRS 13 em prosa, e uma
taxonomia XBRL publica conceitos e não uma lista de bases de mensuração.

Um perfil de conformidade é um segundo esquema que importa o base e o estreita para um regime,
para documentos que declarem esse regime.

## Um perfil está associado a um par, nunca a um país

Um perfil estreita um par `(autoridade, normativo)`, porque o mesmo normativo é codificado de
maneira diferente por autoridades diferentes. Portugal é o caso trabalhado. Uma microentidade é
`NC-ME` para o `AnexoASNC` da IES e `M` para o referencial do SAF-T, e como o `S` cobre tanto
`NCRF` como `NCRF-PE`, o código do SAF-T não pode ser reconvertido.

Portanto um perfil `pt` não é uma coisa que exista. `pt-ies-anexo-asnc` e `pt-saft-referencial`
são dois perfis, e um documento pode legitimamente declarar ambos os regimes.

## Quando é que um perfil é possível

Só onde o regime publica uma enumeração para a qual um esquema possa apontar. Duas parecem
promissoras:

| regime | a enumeração |
|---|---|
| SAF-T PT | o referencial: `S`, `M`, `N`, `O` |
| IES | `AnexoASNC`: `NIC`, `NCRF`, `NCRF-PE`, `NC-ME` |

Estas duas não coincidem, que é a razão de a `taxonomy` ser obrigatória à partida. Um valor
emprestado sem a sua taxonomia é genuinamente ambíguo, e não meramente não atribuído.

## O mecanismo

O `xs:union` combina tipos simples através de uma fronteira de espaço de nomes assim que o outro
esquema esteja importado. O `schemaLocation` é uma sugestão; o espaço de nomes é a identidade.

```xml
<xs:import namespace="urn:regime" schemaLocation="regime.xsd"/>

<xs:simpleType name="BasisUnderThatRegime">
  <xs:union memberTypes="pm:ContributedBasis regime:Referencial"/>
</xs:simpleType>
```

O `xs:union` é só para tipos simples. Tudo o que tenha subelementos precisa de `xs:choice`, ou
de um grupo de substituição se a extensão tiver de ser possível sem editar este repositório, que
é o mecanismo a procurar se a adoção correr bem.

## O que um perfil não pode fazer

- **Reescrever a lista do regime.** Importá-la. Uma enumeração copiada é uma bifurcação que se
  afasta sem que nada aqui o consiga notar.
- **Aliviar o base.** Um perfil estreita o que é válido. Um documento válido sob um perfil é
  válido sob o esquema base, e o inverso não tem de se verificar.
- **Tornar-se obrigatório.** O esquema base vale por si. Quem declara sem perfil nenhum continua
  a produzir um documento verdadeiro, que é o essencial de nomear a autoridade em vez de validar
  contra ela.

### Onde o regime só publica prosa

Um perfil para um regime cujo vocabulário viva em texto normativo não tem nada que
`xs:import`ar. Autorar a lista continua a ser legítimo, desde que seja rotulada como deste projeto. Um
perfil desses publica a leitura que este projeto faz dessa norma, no espaço de nomes deste
projeto, citando o dela. Isso é falsificável, e um contabilista pode apontar para um valor que
ele erra.

O que nunca pode fazer é apresentar essa lista como sendo a do próprio regime. Onde um regime
publica de facto uma lista, importa-se e nunca se reescreve.

## Um perfil é uma porta. Uma feature do cargo não é.

A biblioteca pode condicionar que perfis compila atrás de features do cargo. Nunca pode
condicionar o que conta como conforme.

O cargo unifica as features em todo o grafo de compilação. Se uma biblioteca no grafo ativar
`us-gaap` e outra ativar `pt-ncrf`, ambas ficam com as duas, em silêncio, e o alargamento
acontece na compilação de outra pessoa, onde ninguém aqui o consegue ver. Um estreitamento
expresso como feature não é um estreitamento. O estreitamento pertence ao validador, onde é por
documento e visível.

O uso aditivo é seguro sob a mesma regra. Um leitor multirregime é legítimo e esperado, já que
uma implementação pode ler documentos portugueses e norte-americanos, portanto a unificação a
produzir um leitor que aceite ambos é o resultado correto e não uma fuga. O que não se pode
mexer é escrever e julgar.

## Contra que documentos é que um perfil corre

A primeira pergunta a que uma execução de perfil tem de responder não é se um documento está
conforme. É se o documento é sequer um daqueles a que o perfil se aplica.

Essa pergunta tem quatro respostas, e não tinha antes de o `Regime/framework` se tornar um
`StatedBorrowedTerm`.

| o documento | está na população do perfil? |
|---|---|
| `framework/term` cujo `(taxonomy, value)` corresponde ao perfil | **Sim.** Corre-se |
| `framework/absent/reason = none` | **Não, positivamente.** Alguém foi ver, e a entidade não reporta ao abrigo de normativo nenhum. O perfil não se aplica, e dizê-lo é um resultado acerca de nada |
| `framework/absent/reason = unmeasured` | **Desconhecido.** A entidade reporta ao abrigo de alguma coisa e não a nomeou. Pode ser ou não ser a deste perfil |
| nenhum elemento `regime` | **Desconhecido, e de outra maneira.** Ninguém disse nada. O `regime` é opcional e a sua ausência é um estado real, já que uma testemunha que não seja um modelo contabilístico não reporta ao abrigo de normativo nenhum e não deve ser obrigada a inventar um |

As quatro são documentos legítimos e as quatro validam, o que é o essencial e não um problema. A
pertença é a pergunta do perfil e não a do validador, e um perfil que não lhe responda
deliberadamente responderá por acidente.

Isso foi executado e não assumido: quatro documentos de cobertura idênticos exceto no bloco do
regime, validados contra o `assertion.xsd`, os quatro aceites. O validador foi primeiro provado
capaz de falhar, já que apagar o `framework` obrigatório do mesmo documento dá *"Missing child
element(s). Expected is one of ( jurisdiction, framework )."*

### O estado que não pode ser fundido nos outros

**`unmeasured` não é `notApplicable`, e fundi-lo ali desfaz a reparação que o tornou dizível.**
`notApplicable` é a afirmação de que o documento está fora da população. Para `reason="none"`
essa afirmação é verdadeira e alguém a estabeleceu. Para `reason="unmeasured"` ninguém a
estabeleceu. Saltar o documento afirma que está fora, corrê-lo afirma que está dentro, e ambos
são factos que ninguém tem.

O `Regime/framework` ganhou o seu invólucro precisamente para que `none` e `unmeasured`
deixassem de partilhar uma codificação na raiz da interpretação. Voltar a fundi-los no ponto em
que os documentos são selecionados não corrige o defeito. Move o defeito para fora do esquema e
para dentro daquilo que consome o esquema, onde validador nenhum o vê.

A falha que isso produz é invisível, que é a espécie cara. Um conjunto de documentos cujo
escalão de entidade esteja deliberadamente por declarar está num estado legítimo e comum, e é um
dos casos para que o invólucro foi construído. Ficaria silenciosamente fora da população de
todos os perfis, e o seu relatório leria como *nada a assinalar* quando a verdade é que o
conjunto ainda não disse ao abrigo do que reporta. Evitar uma deficiência que não existe está
certo, e não pode ser comprado produzindo um relatório de conformidade que não existe.

### O que uma execução de perfil deve reportar

Três contagens em vez de duas, mais o quarto estado nomeado à parte.

| | |
|---|---|
| **conforme** | está na população, e as regras estreitadas verificam-se |
| **não conforme** | está na população, e não se verificam |
| **pertença por estabelecer** | `framework` ausente por `unmeasured`, portanto o perfil não conseguiu perguntar |
| *(reportado ao lado, não dentro)* | `framework` ausente por `none`, e nenhum `regime` de todo. Fora da população, e os dois são distintos |

Uma execução que reporte dois números já fez uma afirmação sobre o terceiro. Reportá-lo na sua
própria linha não custa nada e é a única versão sobre a qual um leitor pode agir, porque
«quarenta documentos não estavam conformes» e «quarenta documentos nunca disseram ao abrigo do
que reportam» pedem trabalhos completamente diferentes.

Numa linha: **um perfil responde `notApplicable` só onde um documento recusou positivamente o
normativo. Onde o normativo está meramente por nomear, a resposta do próprio perfil é que não
conseguiu perguntar.** O `assertion.xsd` já transporta uma palavra para essa forma ao nível da
resposta, que é `cannotAsk`, e reutilizar a palavra existente é melhor do que cunhar uma.

### O que isto não decide

- **Se um perfil pode estreitar um documento que declare vários regimes**, de que só um lhe
  corresponde. O `regime` não tem limite superior e declarar duas codificações de um normativo é
  correto e não duplicado, portanto isto chega assim que exista um segundo perfil.
- **Se um perfil pode estreitar sobre o `chart` além do `framework`.** A questão do tipo está
  decidida, já que o `chart` é um `StatedBorrowedTerm` obrigatório e tem os mesmos quatro estados
  que o `framework`, portanto a tabela acima transfere-se sem alteração. O que não está decidido
  é a quarta linha para um plano de contas de autoria própria. Uma entidade que seja a sua
  própria autoridade de plano nomeou positivamente um plano, portanto não está nem por
  estabelecer nem recusada. Está fora da população de um perfil nacional estando plenamente
  declarada, o que é um quinto estado que mais nenhum elemento tem.

## O que um validador não alcança, e um implementador continua portanto a dever

O XSD 1.0 não tem `xs:assert` e não consegue comparar entre elementos, portanto as regras abaixo
estão enunciadas na prosa dos próprios esquemas e não têm porta nenhuma a guardá-las. Quase
todas transportam a marca `NOT REACHABLE BY A VALIDATOR` na anotação que as enuncia, de forma
que um leitor consiga distinguir uma regra vinculativa de uma não verificada; as linhas marcadas
com asterisco não a transportam, o que é uma lacuna na marcação e não no raciocínio.

⛔ **Este parágrafo não as conta, e um número aqui é um número que ninguém volta a contar.** A
tabela é a única coisa que sabe quantas linhas tem. O `tests/conformance.rs` obriga esta tabela
e a sua gémea inglesa ao mesmo comprimento, aos mesmos asteriscos e à mesma terceira coluna,
porque sem isso afastam-se, e quem leia um dos documentos é devedor do que o outro deve.

⭐⭐ **A TERCEIRA COLUNA NOMEIA A VERIFICAÇÃO QUE CORRE A REGRA, E VAZIA QUER DIZER QUE A REGRA
CONTINUA APENAS DEVIDA.** ⛔ O `tests/conformance.rs` cruza-a com o
[`assets/sqlc/checks/roster.sqlc`](../assets/sqlc/checks/roster.sqlc) NOS DOIS SENTIDOS, pelo
que uma regra que passe a correr sem ficar escrita aqui parte a construção, e um identificador
aqui que já não nomeie uma verificação também. Uma regra pode estar imposta e por documentar, ou
documentada e desaparecida, e este cruzamento é a única coisa que lê uma tabela em prosa contra
uma relação.

**As que já não são apenas devidas, mas correm, são o roster.** O
[`assets/sqlc/checks/roster.sqlc`](../assets/sqlc/checks/roster.sqlc) tem uma linha por cada
regra que corre, com a frase que ela impõe, e é o único sítio onde essa frase está escrita. Um
número aqui seria um número que ninguém volta a contar: este parágrafo já se afastou da sua
própria tabela duas vezes, e por isso passa a nomear o ficheiro. O
[`assets/sql/rules.sql`](../assets/sql/rules.sql) exprime-as como uma consulta sobre o conjunto
de documentos carregado em Postgres, e um resultado vazio quer dizer que todas se verificaram.
Isso inclui a regra que validador nenhum vê por princípio: *nenhuma camada-folha é alcançável
por dois caminhos* precisa de um percurso recursivo entre documentos, e o segundo caminho
atravessa uma declaração que o primeiro não contém.

**Isso não desobriga das regras; desobriga-as PARA ESTE CONJUNTO DE DOCUMENTOS.** Um adotante
corre o mesmo ficheiro contra as suas próprias declarações, que é o essencial de o distribuir. E
a consulta reporta quantas linhas cada regra examinou, porque a cobertura escassa é o modo de
falha aqui: um limite sem nada para limitar é o que passa mais alto. O
[`assets/sql/reports/coverage.sql`](../assets/sql/reports/coverage.sql) imprime o veredito de
cada regra, `ok` contra `⚠️ thin` contra ⛔ `VACUOUS`, e uma regra que não examinou nada **fica a
dizê-lo em vez de ser silenciosamente contada como passada**. As contagens não se repetem aqui:
este documento e o seu gémeo inglês chegaram a dar duas respostas DIFERENTES à mesma pergunta, que
é o que um número em prosa faz.

O que o SQL continua a não alcançar é prosa contra dados: se o `observed` de um acoplamento
descreve uma observação real, se um `narrowsWhen` nomeia algo que estreitaria de facto o
intervalo, se uma nota que afirma que uma parcela é `unrealised` concorda com a lista de
detentores ao lado. Essas continuam devidas por uma pessoa.

### As regras da decomposição são aritmética, o que faz delas uma espécie diferente

As regras que chegaram com a decomposição do `Remainder` não são convenções de prosa. São
aritmética sobre valores que o documento já transporta, portanto um implementador desobriga-se
delas calculando e não lendo:

```
m       = capacidade nominal / q  - piso(procura / q)
resíduo = procura mod q
r       = m*q - resíduo           e, sempre,  r ≡ -procura  (mod q)
```

**O TOTAL É UMA IDENTIDADE E A DIVISÃO NÃO É.** Substituindo `k = capacidade nominal/q` os pisos
cancelam-se de vez:

```
r = (n/q − ⌊d/q⌋)·q − (d − ⌊d/q⌋·q) = n − d
```

Portanto `r` é exato para **qualquer** procura e **qualquer** capacidade nominal, intervalar ou
não — o `⌊⌋` aparece duas vezes com sinais opostos e nunca tem de se resolver. Mas `procura mod
q` é um **dente de serra**, pelo que, avaliado nos três pontos de um intervalo de procura, não
tem de ficar ordenado de todo: `(4,5; 5,2; 6,7)` com `q = 1` dá resíduos `(0,5; 0,2; 0,7)`, que
viola `low ≤ mostLikely ≤ high` — a primeira regra da tabela — ao passo que a procura que os
produziu está perfeitamente bem formada. **Há camadas com quantum em `assets/corpus/` hoje nesse
estado.** O `cargo run --example matrices` conta-as contra o total das camadas com quantum, no seu
recenseamento do resíduo.

**O esquema já está seguro e o raciocínio para isso é que nunca tinha sido escrito.** O
`Remainder` transporta `quantity`, `sign`, `absorber` e `holder` — o total, e nunca as duas
componentes. **Leia-se este bloco como a derivação de `r` por parte de um implementador, e nunca
como instrução de preenchimento para `m·q` e para o resíduo**, que não são `Claim`s no caso
geral.

### As regras, e onde estão enunciadas

A tabela completa, com o tipo em cuja anotação cada regra vive e a verificação que a corre,
está aqui e na [versão inglesa](README.md), com as mesmas linhas pela mesma ordem.

| a regra | onde |
|---|---|---|
| os limites de uma `Claim` satisfazem `low` <= `mostLikely` <= `high` | `Claim` | |
| o valor esperado é derivado e não pode ser transportado | `Claim` | |
| o `size` de um quantum exprime-se na unidade da capacidade nominal que divide | `LumpyQuantum` | `quantum_unit_mismatch` |
| uma oferta cujo `capacitySlack` seja um zero medido, sob um ajuste de interferência, tem de o deter como `customer` ou `unrealised`, em todos os detentores | `Fit` | `nobody_named_as_unserved` |
| a mesma oferta sob um ajuste de TRANSIÇÃO nomeia pelo menos um detentor `customer` ou `unrealised`, presença e não universalidade, porque parte do intervalo é legitimamente folga | `Fit` | `nobody_named_as_unserved` |
| `max(0, procura.high - placa.low)` não excede `capacitySlack.high` mais os máximos das quotas não servidas, avaliado nesse único canto | `Nameplate` | `exposure_unaccounted` |
| um `draw` não excede a capacidade nominal mais o `capacitySlack` que a oferta declarou, já que uma oferta não pode servir mais do que consegue fazer | `Jagged`, `Nameplate` | `draw_exceeds_the_supply` |
| a capacidade nominal é um múltiplo inteiro do quantum, para uma oferta em unidades | `Remainder` | `nameplate_not_a_multiple` |
| a `quantity` é `derived` sempre que a procura, a capacidade nominal e o quantum estejam todos declarados | `Remainder` | |
| um ajuste de `clearance` exclui `customer` e `unrealised`, valendo agora ao longo de todo o intervalo | `Remainder` | `clearance_with_unserved` |
| uma camada que negue ter resto não é contradita pela sua própria procura e capacidade nominal, que entre as duas derivam um | `StatedRemainder` | `denied_remainder_is_not_contradicted` |
| o `sign` concorda com a comparação de INTERVALOS — `clearance` quando `placa.low` >= `procura.high`, `interference` quando `placa.high` <= `procura.low`, `transition` quando se sobrepõem | `Fit` | `fit_disagrees` |
| as `share` declaradas somam `\ | placa - procura\|`, sempre que todas estejam declaradas|`Holder` | `shares_do_not_sum` |
| um `kind` de detentor aparece no máximo uma vez por resto | `Holder` | |
| a declaração de uma ponta de `dependence` existe, e a camada nomeada está lá dentro | `FiledLayer` (`assertion.xsd`) | |
| a `version` de uma ponta de `dependence` nomeia a edição efetivamente lida \* | `FiledLayer` (`assertion.xsd`) | |
| as duas pontas de uma entrada de `dependence` não são a mesma declaração *e* a mesma camada | `DependenceEntry` (`assertion.xsd`) | |
| quem testemunha uma `dependence` não é quem declarou ambas as pontas, porque se for, a observação pertence ao `pm:Coupling` \* | `Dependence` (`assertion.xsd`) | |
| a `filing` de uma parte resolve para uma declaração que está no conjunto de documentos, e para uma camada dentro dela | `FiledLayer` (`assertion.xsd`) | `unresolved_part` |
| uma parte LOCAL, cuja notação é a da sua própria composição, nomeia uma camada da pilha desse mesmo documento | `FiledLayer` (`assertion.xsd`) | `local_part_dangles` |
| camadas que se movem sempre juntas são uma só camada, pelo que um ciclo de partes entre elas falha a definição de camada em vez de nomear uma aresta a cortar | `Layer`, `FiledLayer` (`assertion.xsd`) | `layers_move_together` |
| a `claim` de uma camada composta iguala `Σ partes - Σ eliminações`, por quantidade | `Fusion` (`assertion.xsd`) | `fusion_sum_disagrees` |
| uma eliminação subtrai componente a componente e NÃO inverte os limites | `Elimination` (`assertion.xsd`) | |
| as partes de uma fusão são fungíveis, portanto os seus restos podem compensar-se | `Fusion` (`assertion.xsd`) | |
| `party` e `asOf` aparecem só num detentor `counterparty` | `Holder` | |
| um detentor `counterparty` nomeia a sua `party`, e deve transportar `asOf` | `Holder` | |
| um acoplamento propaga-se através de uma fusão e ATENUA-SE, limitado pela quota da parte na camada em que foi fundida | `Coupling` | `coupling_does_not_attenuate` |
| uma fusão que absorve um acoplamento entre as suas próprias partes di-lo, e nunca o cita como prova | `Coupling` | |
| nenhuma camada folha é alcançável por dois caminhos, quando as composições encaixam | `composition` (`assertion.xsd`) | `jagged_layer` |
| a quota de um detentor não excede a margem do amortecedor que o seu `absorber` nomeia, do lado da interferência, com `unrealised` isento | `Nameplate`, `Layer` | `share_exceeds_slack` |
| a margem de uma camada fundida é limitada pela SOMA das das suas partes, e uma parte sem dimensão torna esse limite sem dimensão | `Nameplate`, `Layer` | |
| o `factor` de uma parte converte para a unidade da camada composta, e está ausente exatamente quando já concordam | `Part` (`assertion.xsd`) | `unit_crossing_without_a_factor` |
| um `factor` é estritamente positivo, portanto o produto de intervalos é componente a componente | `Part` (`assertion.xsd`) | |
| uma eliminação é declarada na unidade composta, DEPOIS da conversão | `Part` (`assertion.xsd`) | |
| o resto de uma parte convertida é convertido diretamente e nunca re-derivado da sua capacidade nominal e procura convertidas | `Part` (`assertion.xsd`) | |
| uma `composition` e uma `dependence` declaradas por um consolidador sobre uma consolidação concordam quanto a testemunha, data e normativo | `Dependence` (`assertion.xsd`) | |
| uma parte que atravessa uma fronteira de regime declara o instrumento que a reconcilia, tal como uma parte que atravessa uma fronteira de unidade declara o fator | `Composition` (`assertion.xsd`) | `regime_crossing_without_a_citation` |
| o `regime` que um compositor atribui a uma parte é um que a declaração dessa parte declara, o que é uma afirmação sobre o outro documento e fora do alcance de qualquer keyref | `FiledLayer` (`assertion.xsd`) | `part_regime_disagrees` |
| uma margem exprime-se na unidade das quotas que limita | `Nameplate`, `Layer` | `slack_unit_mismatch` |
| uma margem medida como duração converte-se antes de ser declarada, por `quantidade = duração x taxa` | `Nameplate`, `Layer` | |
| o denominador de uma unidade cobre pelo menos um ciclo de serviço inteiro da oferta que mede | `Claim` | |
| o `timeSlack` é `derived` só onde a camada corre a TOTALIDADE do seu período, declarada como uma janela de um período inteiro na unidade do próprio período | `Layer` | `derived_slack_over_a_window` |
| uma `claim` que declare `boundOrigin` como `derived` fica ao lado de um elemento irmão que nomeia o autor — `Nameplate/amountOrigin` ou `LumpyQuantum/origin` — de forma que o ponteiro resolva | `Claim` | |
| um valor pontual declara o `narrowsWhen` como `notApplicable`, não tendo largura nenhuma para apertar | `Claim` | `narrows_a_point_value` |
| uma afirmação que ocupa uma largura não declara o `narrowsWhen` como `notApplicable` | `Claim` | `range_says_no_range` |
| um valor pontual não declara o `boundOrigin` ausente como `none`, já que essa razão diz que o limite está onde as medições caíram e nada caiu em lado nenhum | `Claim` | `bound_fell_with_no_range` |
| uma `window` é a duração ATIVA, uma por período da unidade da capacidade nominal, e nunca o intervalo entre elas | `Divisibility` | |
| uma `window` exige que a unidade da capacidade nominal nomeie um período, já que é a parte viva desse denominador | `Divisibility` | |
| uma `window` é TRANSPORTADA através de uma fusão e nunca somada: é uma propriedade da máquina, não uma quantidade | `Divisibility` | `window_lost_or_summed` |
| uma camada que declare uma `window`, OU que declare a sua ausência como `unmeasured`, não pode declarar o `timeSlack` como `derived`, porque em nenhum dos casos se sabe que a folga esteja repartida por igual pelo período | `Divisibility`, `Layer` | `derived_slack_over_a_window` |
| uma `window` declarada como `notApplicable` assenta numa unidade sem denominador, já que uma unidade que nomeia um período tem resposta | `Divisibility` | `window_not_applicable_on_a_rate` |
| uma fusão que declare as `eliminations` como `none` ou `notApplicable` deve uma soma EXATA: a figura composta iguala `Σ` das partes convertidas. Declará-las como `unmeasured` suspende a verificação em vez de a dar por passada | `Fusion` (`assertion.xsd`) | `fusion_sum_disagrees` |
| uma fusão que declare as `eliminations` como `notApplicable` tem exatamente uma parte, já que entre um conjunto de um nada pode ser contado duas vezes | `Fusion` (`assertion.xsd`) | `elimination_not_applicable_with_parts` |
| uma fusão de UMA parte que não elimine nada transporta essa parte inalterada, em todas as quantidades que a camada declara e não só na sua procura | `Fusion` (`assertion.xsd`) | `one_part_fusion_alters_its_part` |
| uma parte cuja unidade difira da camada em que é composta declara o que a converte, mesmo quando a conversão é um, porque então alguém está a afirmar que as duas unidades se trocam | `Part` (`assertion.xsd`) | `unit_crossing_without_a_factor` |
| converter uma quantidade à volta de um ciclo de unidades devolve aquilo de que partiu: o um fica dentro do produto dos fatores à volta do ciclo | `Part` (`assertion.xsd`) | `conversion_cycle_does_not_close` |
| uma camada reafirmada por uma segunda declaração que diz transportá-la inalterada concorda com a primeira, `absorber` incluído \* | `composition` (`assertion.xsd`) | |

⚠️ **Isto é uma tradução e não uma segunda lista.** A versão inglesa é a autoritativa. Se as
duas divergirem, a inglesa está certa e isto é o defeito, e o `tests/conformance.rs` obriga-as
linha a linha.

### ⛔ Acoplamento e fungibilidade são eixos independentes

Isto não está na tabela acima porque não é uma regra a cumprir. É a leitura errada que dois
leitores já fizeram, e fica aqui para que o terceiro não a faça.

Nenhuma das duas linhas de `Coupling` diz que um acoplamento é prova a favor de uma fusão, e isso é
deliberado. **Acoplamento e fungibilidade são eixos independentes**, e os documentos deste
repositório preenchem as duas células fora da diagonal. Duas equipas de entrega em dois países são
uma só camada e não estão acopladas de todo. Uma equipa de entrega e um piquete fora de horas estão
fortemente acoplados e são duas camadas, porque um engenheiro no piquete não entrega
funcionalidades. Uma fusão que cite um acoplamento como justificação responde a uma pergunta
diferente daquela que lhe foi feita.

⚠️ **E a pergunta da fungibilidade é entre instâncias por construção.** «Uma parte» e «a outra» são
duas instâncias, portanto «o mesmo TIPO e não a mesma INSTÂNCIA» é onde a pergunta está VIVA, e
nunca onde é respondida. É respondida no `observed`, com prova. Ver a `asrt:Fusion`.

### ⛔ Um quarto limite está deliberadamente fora da tabela

Listá-lo daria a entender que alguém o deve. As unidades das partes de uma fusão NÃO são verificadas
e não devem ser: as partes escrevem legitimamente uma unidade de duas maneiras — `people` e
`pessoas` — e afirmar que nomeiam uma só unidade É O QUE A FUSÃO DIZ. Um verificador que exija
igualdade de cadeias de carateres rejeita o caso para que o tipo existe. É um limite do mundo e não
uma dívida de quem implementa.
