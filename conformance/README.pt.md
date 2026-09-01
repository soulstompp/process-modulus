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
`xs:import`ar. Autorar a lista continua a ser legítimo, desde que seja rotulada como nossa. Um
perfil desses publica a leitura que este projeto faz dessa norma, no espaço de nomes deste
projeto, citando o dela. Isso é falsificável, e um contabilista pode apontar para um valor que
errámos.

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
| `framework/absent reason="none"` | **Não, positivamente.** Alguém foi ver, e a entidade não reporta ao abrigo de normativo nenhum. O perfil não se aplica, e dizê-lo é um resultado acerca de nada |
| `framework/absent reason="unmeasured"` | **Desconhecido.** A entidade reporta ao abrigo de alguma coisa e não a nomeou. Pode ser ou não ser a deste perfil |
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

O XSD 1.0 não tem `xs:assert` e não consegue comparar entre elementos. Quarenta e quatro regras
deste modelo estão enunciadas na prosa dos próprios esquemas e não têm porta nenhuma a
guardá-las. Quarenta e uma delas transportam a marca `NOT REACHABLE BY A VALIDATOR` na anotação
que as enuncia, de forma que um leitor consiga distinguir uma regra vinculativa de uma não
verificada. As três linhas marcadas abaixo com asterisco estão enunciadas em prosa sem essa
marca, o que é uma lacuna na marcação e não no raciocínio.

**Dezasseis das quarenta e quatro já não são apenas devidas — correm.** O
[`assets/sql/rules.sql`](../assets/sql/rules.sql) exprime-as como uma consulta sobre o conjunto
de documentos carregado em Postgres, e um resultado vazio quer dizer que todas se verificaram.
Isso inclui a regra que validador nenhum vê por princípio: *nenhuma camada-folha é alcançável
por dois caminhos* precisa de um percurso recursivo entre documentos, e o segundo caminho
atravessa uma declaração que o primeiro não contém.

**Isso não desobriga das regras; desobriga-as PARA ESTE CONJUNTO DE DOCUMENTOS.** Um adotante
corre o mesmo ficheiro contra as suas próprias declarações, que é o essencial de o distribuir. E
a consulta reporta quantas linhas cada regra examinou, porque quatro das dezasseis veem
atualmente apenas duas camadas cada — quase nada no conjunto declara uma margem numérica, e um
limite sem nada para limitar é o que passa mais alto. Duas reportam `VACUOUS` abertamente e
ficam a dizê-lo em vez de serem silenciosamente contadas como passadas.

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
produziu está perfeitamente bem formada. **Dez das vinte camadas com quantum em
`assets/corpus/` estão hoje nesse estado.**

**O esquema já está seguro e o raciocínio para isso é que nunca tinha sido escrito.** O
`Remainder` transporta `quantity`, `sign`, `absorber` e `holder` — o total, e nunca as duas
componentes. **Leia-se este bloco como a derivação de `r` por parte de um implementador, e nunca
como instrução de preenchimento para `m·q` e para o resíduo**, que não são `Claim`s no caso
geral.

### As regras, e onde estão enunciadas

A tabela completa das quarenta e quatro, com o tipo em cuja anotação cada uma vive, está na
[versão inglesa](README.md).
Estão aqui agrupadas por aquilo que um implementador tem de fazer para as cumprir.

| grupo | o que é devido |
|---|---|
| **aritmética sobre um documento** | os limites de uma `Claim` ordenam-se; a capacidade nominal é um múltiplo inteiro do quantum; o quantum é expresso na unidade da capacidade nominal que divide; as parcelas somam `\|capacidade nominal − procura\|`; o `sign` concorda com a comparação dos intervalos |
| **aritmética entre documentos** | a figura de uma camada composta iguala `Σ partes − Σ eliminações`, por quantidade; uma eliminação subtrai componente a componente e não inverte extremos; um fator é estritamente positivo, portanto o produto intervalar é componente a componente; o resto de uma parte convertida é convertido diretamente e nunca rederivado |
| **alcançável só por quem consiga ir buscar a cadeia** | a declaração de uma ponta de `dependence` existe, e a camada nomeada está lá; a `version` nomeia a edição efetivamente lida; nenhuma camada-folha é alcançável por dois caminhos quando as composições encaixam |
| **juízo, devido por uma pessoa e por mais ninguém** | as partes de uma fusão são fungíveis, portanto os seus restos se podem compensar; o `observed` de um acoplamento descreve uma observação real; um `narrowsWhen` nomeia algo que estreitaria de facto o intervalo |
| **coerência de unidades** | uma margem é expressa na unidade das parcelas que limita; uma margem medida como duração é convertida antes de ser declarada, por `quantidade = duração × taxa`; o denominador de uma unidade cobre pelo menos um ciclo de funcionamento inteiro |
| **regras da janela** | uma `window` é a duração ATIVA, uma por período da unidade da capacidade nominal, e nunca o intervalo parado; exige que a unidade nomeie um período; é TRANSPORTADA através de uma fusão e nunca somada |
| **quem suporta** | `party` e `asOf` aparecem só num detentor `counterparty`; um detentor `counterparty` nomeia a sua `party`; um tipo de detentor aparece no máximo uma vez por resto |

⚠️ **Esta é uma vista agrupada e não uma segunda lista.** A versão inglesa é a autoritativa e
transporta as quarenta e quatro linhas com o tipo exato em que cada regra está enunciada. Se as
duas divergirem, a inglesa está certa e isto é o defeito.
