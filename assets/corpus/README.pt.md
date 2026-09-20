# `assets/corpus/`: o aspeto de um arquivo, e a camada por causa da qual o modelo existe

> **Grafia do AO90.** A versão inglesa está em [`README.md`](README.md), nesta pasta, e é a que o
> repositório trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das
> tabelas e dos elementos do XSD ficam em inglês, porque são os nomes do artefacto.

Cada documento aqui é uma afirmação sobre uma empresa: uma procura que alguém observou, uma oferta
que alguém comprometeu, um resto que alguém suportou. Os números são ilustrativos e não são de
ninguém, o que não altera aquilo que os documentos são, que é arquivos.

⛔ **A pasta ao lado guarda o outro género.** [`assets/fixtures/`](../fixtures/) tem um documento
por estado que o esquema admite, e argumenta a diferença por inteiro em vez de a repetir aqui. A
versão curta: um estado apagado nesta pasta é uma conclusão sobre a prova disponível, e um estado
apagado naquela é um defeito.

## Os documentos

Aparecem cinco elementos de raiz, porque uma afirmação *sobre* um arquivo não é ela própria um
arquivo.

| ficheiro | raiz | o que arquiva |
|---|---|---|
| [`enterprise-contract.xml`](enterprise-contract.xml) | `pm:processModulus` | Quatro camadas e duas operações. A camada lida abaixo é esta |
| [`contrato-empresarial.xml`](contrato-empresarial.xml) | `pm:processModulus` | As mesmas quatro camadas declaradas em português por uma microentidade ao abrigo do `AnexoASNC` da IES |
| [`unstated.xml`](unstated.xml) | `pm:processModulus` | Tudo aquilo que um emissor pode legitimamente declinar, cada um com a razão anexada |
| [`refutation.xml`](refutation.xml) | `pm:processModulus` | Dois contraexemplos ao modelo, arquivados no formato do próprio modelo |
| [`merge-us-member.xml`](merge-us-member.xml) · [`merge-pt-member.xml`](merge-pt-member.xml) | `pm:processModulus` | Dois arquivos honestos que nenhuma heurística consegue fundir. Nenhum é interessante sozinho |
| [`merge-group-composition.xml`](merge-group-composition.xml) | `asrt:composition` | A reparação, arquivada por nenhum dos membros: o que a entidade-mãe tratou como uma camada, e porquê |
| [`merge-holding-composition.xml`](merge-holding-composition.xml) | `asrt:composition` | O segundo nível, que é o que faz as composições aninhar |
| [`dependence-group-consolidation.xml`](dependence-group-consolidation.xml) | `asrt:dependence` | Uma dependência entre dois arquivos, apresentada por quem não é o autor de nenhum deles |
| [`coverage-us-gaap.xml`](coverage-us-gaap.xml) · [`coverage-pt-ncrf-pe.xml`](coverage-pt-ncrf-pe.xml) | `asrt:coverage` | As mesmas perguntas respondidas sob dois regimes, para que as respostas sejam comparáveis chave a chave |
| [`run-2026-08-30.xml`](run-2026-08-30.xml) | `asrt:run` | Uma execução promovida a prova: o extrato datado que um relatório cita |

Cada documento abre com um comentário que diz para que serve. Esse comentário é a entrada acima, e
o ficheiro é onde ele é autoritativo.

## Ler uma camada, que é o modelo inteiro

A camada `labour` de [`enterprise-contract.xml`](enterprise-contract.xml). Três factos, e tudo o
resto decorre deles:

```
procura    entre 4,5 e 6,0 pessoas, mais provavelmente 5,2
oferta     4 pessoas
a unidade  1 pessoa, e não se divide
```

### A procura, e dois factos que viajam ao lado do intervalo

```xml
<pm:demand>
  <pm:amount>
    <pm:claim>
      <pm:low>4.5</pm:low>
      <pm:mostLikely>5.2</pm:mostLikely>
      <pm:high>6.0</pm:high>
      <pm:unit>people</pm:unit>
      <pm:narrowsWhen>
        <pm:narrowing>
          <pm:condition>support interrupts are time-recorded instead of estimated</pm:condition>
          <pm:kind>instrument</pm:kind>
        </pm:narrowing>
      </pm:narrowsWhen>
      <pm:boundOrigin>
        <pm:absent>
          <pm:reason>none</pm:reason>
          <pm:note>nothing sets this bound. The range is where the observations fell</pm:note>
        </pm:absent>
      </pm:boundOrigin>
      ...
    </pm:claim>
  </pm:amount>
</pm:demand>
```

`narrowsWhen` é o que teria de mudar para o intervalo **estreitar**, e `kind` diz se isso é um
instrumento a chegar ou o próprio processo a mudar. Não saber e variar genuinamente são condições
diferentes, e só a primeira melhora por se olhar com mais atenção.

`boundOrigin` é **de quem é a margem**. `none` aqui diz que alguém procurou e não é de ninguém,
porque este intervalo é onde caíram doze meses de observações e não onde uma regra os pôs. Uma
procura limitada por contrato responderia `contractual`, e isso é uma alavanca que alguém poderia
puxar.

### A oferta, onde vive a unidade

```xml
<pm:nameplate>
  <pm:amount>
    <pm:claim>
      <pm:low>4</pm:low><pm:mostLikely>4</pm:mostLikely><pm:high>4</pm:high>
      <pm:unit>people</pm:unit>
      <pm:boundOrigin>
        <pm:derivation>
          <pm:identity>amountOrigin</pm:identity>
          <pm:note>`Nameplate/amountOrigin` says who could have held a different
                   number of these, one element over</pm:note>
        </pm:derivation>
      </pm:boundOrigin>
    </pm:claim>
  </pm:amount>

  <!-- the establishment is ours to set, so the one-person shortfall below
       is a decision rather than a constraint -->
  <pm:amountOrigin><pm:origin>policy</pm:origin></pm:amountOrigin>

  <pm:divisibility><pm:divisibility>
    <pm:lumpy>
      <pm:size><pm:claim>
        <pm:low>1</pm:low><pm:mostLikely>1</pm:mostLikely><pm:high>1</pm:high>
        <pm:unit>people</pm:unit>
      </pm:claim></pm:size>
      <pm:origin>intrinsic</pm:origin>
    </pm:lumpy>
    <pm:window>
      <pm:absent>
        <pm:reason>notApplicable</pm:reason>
        <pm:note>the nameplate is quoted in `people`, a stock with no period, so there
                 is no cycle to be live in part of</pm:note>
      </pm:absent>
    </pm:window>
  </pm:divisibility></pm:divisibility>
</pm:nameplate>
```

⭐⭐ **Duas origens, e mantê-las separadas é a razão de ser do elemento.** `origin` é com quem
teria de falar para mudar o **tamanho de uma unidade**, e `intrinsic` significa ninguém, porque uma
pessoa é uma pessoa. `amountOrigin` é com quem teria de falar para ter **um número diferente
delas**, e `policy` significa quem arquiva, porque o quadro de pessoal é dele.

⭐ Essas duas são também a razão pela qual as afirmações respondem a `boundOrigin` com uma
**derivação** que nomeia a identidade, em vez de se repetirem. A pergunta *de quem é esta margem*
já está respondida um elemento ao lado, e um documento que a respondesse duas vezes acabaria por a
responder de duas maneiras diferentes. Uma `derivation` não é uma ausência: diz que o valor é
calculável e nomeia o que o calcula.

`window` é a outra metade da divisibilidade. Não como a oferta se divide em **quantidade** mas como
se divide no **tempo**: uma linha que trabalha cinco dias em sete, uma máquina parada duas horas por
dia. Um efetivo não tem esse ciclo, por isso a resposta diz qual das alternativas se aplica em vez
de deixar um espaço em branco.

### A folga que cada amortecedor tem

```xml
<pm:capacitySlack>
  <pm:absent>
    <pm:reason>unmeasured</pm:reason>
    <pm:note>a person can work above their rating. HOW FAR ABOVE, and for how long,
             nobody here has measured</pm:note>
  </pm:absent>
</pm:capacitySlack>
<pm:inventorySlack>
  <pm:claim>
    <pm:low>0</pm:low><pm:mostLikely>0</pm:mostLikely><pm:high>0</pm:high>
    <pm:unit>people</pm:unit>
    <pm:provenance>
      <pm:party>platform</pm:party>
      <pm:note>capacity not used today is GONE. Last week's unused hours cannot be
               stockpiled to serve this week</pm:note>
    </pm:provenance>
  </pm:claim>
</pm:inventorySlack>
```

⛔ **Um zero medido é aqui uma AFIRMAÇÃO e nunca uma ausência.** Traz consigo uma unidade, um dono
e uma proveniência, e o ramo da ausência não tem onde pôr nenhuma das três. `[0, 0, 0]` diz que
alguém verificou e a resposta é nada; `unmeasured` diz que ninguém verificou. São declarações
opostas e um elemento vazio escreve-as da mesma maneira.

### A outra face da oferta, que é o que aconteceu de facto

```xml
<pm:jagged>
  <pm:draw>
    <pm:absent>
      <pm:reason>unmeasured</pm:reason>
      <pm:note>no instrument records hours absorbed above the establishment</pm:note>
      <pm:provenance><pm:party>platform</pm:party> ... </pm:provenance>
      <pm:asOf>2026-08-30</pm:asOf>
    </pm:absent>
  </pm:draw>
  <pm:measurementBasis>
    <pm:absent>
      <pm:reason>notApplicable</pm:reason>
      <pm:note>there is no valuation here to have a basis</pm:note>
    </pm:absent>
  </pm:measurementBasis>
</pm:jagged>
```

⭐ **As duas ausências trazem razões diferentes e um recetor não as pode fundir.** O `draw` é
`unmeasured`: um instrumento poderia existir e não existe. A base de mensuração é `notApplicable`:
fazer a pergunta é malformado aqui, porque um efetivo não tem valorização para ter base nenhuma. Um
recetor que tratasse a segunda como uma lacuna reportaria uma deficiência que não existe.

### O resto, que é a conclusão

```xml
<pm:remainder><pm:remainder>
  <pm:sign><pm:fit>interference</pm:fit></pm:sign>
  <pm:absorber>
    <pm:term>
      <pm:taxonomy>urn:example:factory-physics:buffers</pm:taxonomy>
      <pm:value>capacity</pm:value>
    </pm:term>
  </pm:absorber>

  <pm:holder><pm:holder>
    <pm:kind>unrealised</pm:kind>
    <pm:share><pm:absent><pm:reason>unmeasured</pm:reason>
      <pm:note>work that queued, waited and aged out before anyone got to it</pm:note>
    </pm:absent></pm:share>
  </pm:holder></pm:holder>
  <pm:holder><pm:holder>
    <pm:kind>people</pm:kind>
    <pm:share><pm:absent><pm:reason>unmeasured</pm:reason>
      <pm:note>the absorption has no counterparty and therefore no transaction</pm:note>
    </pm:absent></pm:share>
  </pm:holder></pm:holder>

  <pm:quantity>
    <pm:derivation>
      <pm:identity>magnitude</pm:identity>
      <pm:note>computable from this layer's demand and nameplate; the receiver computes it</pm:note>
    </pm:derivation>
  </pm:quantity>
</pm:remainder></pm:remainder>
```

O ajustamento é `interference` no sentido mecânico emprestado da ISO 286: funciona deformando o
material, e inspecionar o resultado não o revela. O amortecedor é o `capacity` de Hopp e Spearman,
citado à taxonomia deles em vez de ser repetido neste espaço de nomes.

⛔⛔ **Repare em qual das duas coisas está ausente, porque não é a que as pessoas esperam.** O
TAMANHO do resto é uma derivação: o documento determina-o e um recetor calcula-o. Aquilo que nenhum
instrumento alcança é a **quota**, quanto daquela diferença a equipa absorveu em vez de recusar.
Isso é uma admissão muito mais pequena e muito mais precisa do que *não sabemos o resto*.

⭐ E o segundo detentor é o que a nota de `timeSlack` desta mesma camada pede. O trabalho que fica
em fila, espera e envelhece em silêncio é `unrealised` e não `people`. Arquivar apenas `people`
teria dito que a equipa absorveu tudo, o que a mesma camada contradiz poucos elementos acima.

### Aquilo a que a camada soma

```
|nameplate - demand|  =  |4 - [4.5, 5.2, 6.0]|  =  [0.5, 1.2, 2.0] pessoas
```

e no modo esse 1,2 divide-se, exatamente e de uma só maneira:

| | | |
|---|---|---|
| **1 pessoa** | uma unidade inteira, e **uma decisão** | contrate mais uma e move-se. `amountOrigin` diz que o quadro de pessoal é de quem arquiva |
| **0,2 de uma pessoa** | o resíduo, e **não uma decisão** | nenhum efetivo o remove. Quatro pessoas deixam 0,2 em falta e cinco deixam 0,8 a sobrar |

⭐⭐⭐ **Esse 0,2 é o assunto.** Ninguém o comprou, por isso nenhuma transação o regista, por isso
nenhum sistema que parta das transações o consegue ver. Este documento diz que existe, diz quem o
suportou, diz que ninguém mediu como os dois portadores o dividem, e diz quem se responsabiliza por
essa declaração.

Uma camada, e é o modelo inteiro.
