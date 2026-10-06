# `assets/corpus/`: como é uma declaração, e uma camada lida do princípio ao fim

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`assets/corpus/README.md`](../../../assets/corpus/README.md).

Os documentos desta pasta estão escritos como os escreveria quem os assina de verdade, seja uma
empresa a declarar o seu negócio, uma testemunha a responder a perguntas ou quem consolida um grupo,
com números ilustrativos que não são de ninguém, e todos declaram em `evidence` que relatam o que
alguém observou. Os de [`fixtures/`](../fixtures/), esses, servem outro fim, que é pôr num documento
cada estado que o esquema admite; aqui o que importa é o aspeto de um negócio inteiro posto por
escrito, com as camadas que tem, as lacunas que admite e os documentos que outros assinam a respeito
dele.

## O que cada documento mostra

- [`enterprise-contract.xml`](../../../assets/corpus/enterprise-contract.xml) é a declaração de
  referência, a de uma empresa de plataforma que reporta nos Estados Unidos, sob US GAAP, e que,
  não havendo lá plano de contas nacional, se nomeia a si própria autoridade do seu; declara
  as camadas `labour`, `compute`, `capability` e `support-cover`, e as duas operações que as
  consomem, fechar um contrato empresarial e servir um pedido de inferência.
- [`contrato-empresarial.xml`](../../../assets/corpus/contrato-empresarial.xml) é essa mesma
  declaração feita em Portugal, por uma microentidade que reporta sob o AnexoASNC da IES, como
  `NCRF-PE`, e que, havendo um plano nacional, usa o do SNC em vez de escrever um seu; as camadas
  chamam-se aqui `pessoal`, `computacao`, `capacidade-entregavel` e `cobertura-de-suporte`, as
  unidades e as notas vêm em português, e é dela que sai a camada lida mais abaixo.
- [`unstated.xml`](../../../assets/corpus/unstated.xml) mostra o que quem declara pode recusar, e
  de que maneira. Tem uma só camada, `margin-ratio`, uma margem em percentagem que não é oferta
  nenhuma, pelo que a capacidade nominal, a divisibilidade, as folgas de existências e de tempo e o
  próprio resto ficam `notApplicable`, ao passo que a folga de capacidade fica `unmeasured`, já que
  ninguém determinou ainda se a margem pode ir além do nominal; e declara dois regimes, um cujo
  normativo ninguém nomeou ainda, porque o escalão da entidade está por atribuir e o plano de contas
  vai atrás dele, e outro em que alguém foi ver e não há normativo nenhum (`none`), com um plano de
  contas da própria entidade.
- [`refutation.xml`](../../../assets/corpus/refutation.xml) declara os casos que contradizem o
  modelo em vez de os discutir: uma camada, `object-storage`, comprada continuamente sem pagar nada a mais (um
  `premium` de `[0, 0, 0]`), que não compromete capacidade nominal nenhuma e por isso tem o resto
  `notApplicable`; um acoplamento observado entre `compute` e `labour`, cujos restos se moveram
  juntos no trimestre em que a reserva passou de 8 para 16 GPU; e um ajustamento `transition`, com
  uma procura de 11,0 a 16,4 GPU contra uma capacidade nominal de 16. A entidade é uma microentidade
  portuguesa com dois regimes, `NC-ME` para a IES e `M` para o SAF-T, códigos de duas listas que
  não se convertem uma na outra; operações, o documento não tem nenhuma, porque uma pilha basta
  para fazer uma declaração.
- [`merge-us-member.xml`](../../../assets/corpus/merge-us-member.xml) é um membro de um grupo,
  declarado nos Estados Unidos sob US GAAP e com plano de contas próprio, que só se lê bem ao lado
  do irmão português: o `labour` dele e o `pessoal` do outro são a mesma camada, o `compute` só
  partilha o nome com o `compute` de lá, e a `shift-line` é a mesma máquina que a
  `linha-partilhada`, uma linha de 10 turnos por semana ativa 5 dias em cada semana, que os dois
  membros declaram por inteiro como capacidade nominal sua, e cada um com folga.
- [`merge-pt-member.xml`](../../../assets/corpus/merge-pt-member.xml) é o membro português, sob o
  AnexoASNC da IES e o plano do SNC. O `pessoal` tem o mesmo ajustamento e o mesmo amortecedor que
  o `labour` americano, só que com outro nome e outra unidade; e como esta entidade opera um banco
  de horas, parte do excesso que as pessoas absorvem torna-se uma obrigação nos seus livros, uma
  quota `booked` com número, ao lado da quota `people`. O `compute` daqui é outra reserva, medida
  em `GPU-hour`, e a `capacidade-instalada`, que só este membro tem, cita o amortecedor de uma
  edição traduzida do vocabulário que as outras camadas citam.
- [`merge-group-composition.xml`](../../../assets/corpus/merge-group-composition.xml) é a
  declaração do grupo, assinada pela casa-mãe (`group-parent`, com o estatuto de
  `parent-undertaking`), que reporta sob IFRS, normativo de nenhum dos membros, e compõe as duas
  declarações: funde `labour` com `pessoal` e elimina a procura que os dois membros contaram duas
  vezes; leva os dois `compute` como duas fusões de uma só parte, `compute-us` e `compute-pt`, que
  é a maneira de responder a uma colisão de nomes; funde a `shift-line` com a `linha-partilhada` e
  elimina os 10 turnos de capacidade nominal declarados duas vezes, pelo que o grupo fica em
  interferência onde cada membro tinha folga; transporta a `capacidade-instalada` tal como veio;
  cria uma camada sua, `on-call`, a escala fora de horas que nenhum membro declara; e declara
  acoplamentos que nenhum membro podia observar, como o de `labour` com `on-call`.
- [`merge-holding-composition.xml`](../../../assets/corpus/merge-holding-composition.xml) é o
  segundo nível, uma holding que compõe a declaração do grupo como o grupo compôs as dos membros,
  já que uma composição é também uma declaração. Funde `labour` e `on-call` numa só camada,
  `staff`, porque corre uma escala única, e diz que com isso absorve o acoplamento que o grupo tinha
  declarado entre as duas; funde `compute-us` e `compute-pt` convertendo placas reservadas em horas
  de placa, a 672 a 744 `GPU-hour per GPU`; e herda o acoplamento de `labour` com `shift-line` mais
  fraco do que o grupo o mediu, uma vez que `labour` é agora só parte de `staff`.
- [`dependence-group-consolidation.xml`](../../../assets/corpus/dependence-group-consolidation.xml)
  é uma dependência observada entre duas declarações por quem não fez nenhuma delas: quem consolida
  o grupo (`Acme Group`, com o estatuto `reviewed-not-audited`) leu a declaração da subsidiária
  portuguesa e a da casa-mãe americana, que não se veem uma à outra, e declara que uma decisão de
  capacidade no `compute` de uma aliviou um resto no `labour` da outra. Cada ponta diz sob que
  regime reportou, `NC-ME` com o SNC de um lado, US GAAP com um plano próprio do outro, e o texto
  do `observed` é tudo o que quem recebe tem para se convencer, porque as duas pontas estão noutro
  sítio.
- [`coverage-us-gaap.xml`](../../../assets/corpus/coverage-us-gaap.xml) é o que a testemunha
  `gaap-us` responde, pergunta a pergunta, sob US GAAP: recusas tiradas de um caderno de códigos
  que não pertence a país nenhum, posições no plano de contas da própria entidade, um `cannotAsk`
  onde um normativo contabilístico não tem opinião, e uma exceção declarada, a das horas
  extraordinárias de um prestador, que têm posição porque um prestador passa fatura.
- [`coverage-pt-ncrf-pe.xml`](../../../assets/corpus/coverage-pt-ncrf-pe.xml) são as perguntas que
  as duas testemunhas partilham, respondidas pela `snc-port` sob o regime português, que vem
  declarado duas vezes para a mesma entidade, `NCRF-PE` para a IES e `S` para o SAF-T, porque o `S`
  cobre também as NCRF completas e não se converte de volta. As recusas saem do mesmo caderno e
  comparam-se linha a linha com as americanas, as posições saem do plano do SNC e não se comparam
  com nada, e a obrigação criada por um contrato empresarial é recusada por outra razão, a falta de
  uma base de mensuração, com a exceção declarada ao lado.
- [`run-2026-08-30.xml`](../../../assets/corpus/run-2026-08-30.xml) é a execução de 30 de agosto de
  2026, promovida a prova: a `snc-port` contra a versão `facility@2026-08-29` do corpus, com um
  veredicto por pergunta, `agreed` onde a resposta coincide, `diverged` onde a cobertura afirmava
  uma posição e a execução recusou, e `notable` onde a testemunha nada afirmava e respondeu mesmo
  assim com uma posição, que é a linha que mais vale a pena ler.

## A camada de pessoal, elemento a elemento

A camada `pessoal` do [`contrato-empresarial.xml`](../../../assets/corpus/contrato-empresarial.xml)
é a equipa da casa, 4 pessoas, e o trabalho que lhe chega pede entre 4,5 e 6,0 pessoas, sendo
5,2 o mais provável. Segue-se aqui pela ordem em que o documento a escreve, da procura ao que se
comprometeu, do que se comprometeu ao que aconteceu, e daí ao resto que fica entre uma coisa e
outra; e em cada elemento o documento ou dá o valor ou diz porque não o dá, de modo que nenhum campo
fica simplesmente em branco.

### A procura, tal como a chefia a reporta

O que a chefia de equipa reporta não é um número mas um intervalo, com o mínimo, o mais provável e o
máximo, e quem o recebe fica a saber, além disso, o que o estreitaria e quem lhe fixou os limites,
coisa que um valor único, uma média, por exemplo, deitaria fora:

```xml
<pm:demand>
  <pm:amount>
    <pm:claim>
      <pm:low>4.5</pm:low>
      <pm:mostLikely>5.2</pm:mostLikely>
      <pm:high>6.0</pm:high>
      <pm:unit>pessoas</pm:unit>
      <pm:denominator>
        <pm:absent><pm:reason>notApplicable</pm:reason></pm:absent>
      </pm:denominator>
      <pm:narrowsWhen>
        <pm:narrowing>
          <pm:condition>as interrupções de apoio passarem a ser registadas em tempo
                        em vez de estimadas</pm:condition>
          <pm:kind>instrument</pm:kind>
        </pm:narrowing>
      </pm:narrowsWhen>
      <pm:boundOrigin>
        <pm:absent>
          <pm:reason>none</pm:reason>
          <pm:note>nada fixa este limite. O intervalo é onde as observações caíram e não onde
                   uma regra as pôs, portanto não há aqui alavanca nenhuma a procurar</pm:note>
        </pm:absent>
      </pm:boundOrigin>
      …
    </pm:claim>
  </pm:amount>
  <pm:patience>
    <pm:absent><pm:reason>unmeasured</pm:reason></pm:absent>
  </pm:patience>
</pm:demand>
```

A largura do intervalo, essa, tem remédio declarado, que é um instrumento, registar em tempo as
interrupções de apoio em vez de as estimar; os limites ninguém os pôs lá (`none`), são onde as
observações caíram, pelo que quem neles buscasse uma alavanca não a encontraria. A unidade,
`pessoas`, não tem nada debaixo do traço, por ser uma existência e não uma taxa, e a paciência,
quanto tempo um pedido sobrevive sem resposta, fica `unmeasured`, e é aí que se esgota o que a
procura tem para dizer.

### O que se comprometeu, e em que unidades vem

Do lado da oferta, a capacidade nominal é o compromisso, 4 pessoas, e o documento diz quem decide
quantas unidades se têm e quem decide o tamanho de cada uma, duas perguntas com autores diferentes:

```xml
<pm:nameplate>
  <pm:amount>
    <pm:claim>
      <pm:low>4</pm:low><pm:mostLikely>4</pm:mostLikely><pm:high>4</pm:high>
      <pm:unit>pessoas</pm:unit>
      …
    </pm:claim>
  </pm:amount>
  <pm:amountOrigin><pm:origin>policy</pm:origin></pm:amountOrigin>
  <pm:divisibility>
    <pm:divisibility>
      <pm:lumpy>
        <pm:size><pm:claim>
          <pm:low>1</pm:low><pm:mostLikely>1</pm:mostLikely><pm:high>1</pm:high>
          <pm:unit>pessoas</pm:unit>
          …
        </pm:claim></pm:size>
        <pm:origin>intrinsic</pm:origin>
      </pm:lumpy>
      <pm:window>
        <pm:absent>
          <pm:reason>notApplicable</pm:reason>
          <pm:note>a capacidade nominal é cotada em `pessoas`, uma existência sem período,
                   pelo que não há período de que uma janela possa ser parte</pm:note>
        </pm:absent>
      </pm:window>
    </pm:divisibility>
  </pm:divisibility>
  …
</pm:nameplate>
```

Quantas pessoas a casa tem é `policy`, decisão sua, que ela pode tomar de outra maneira sem pedir
licença a ninguém, ao passo que o tamanho de cada unidade é `intrinsic`, porque uma pessoa vem
inteira e isso ninguém o muda; e quem recebesse só o número suporia que a falta é um dado da
natureza, quando o documento lhe diz que a quantidade é uma decisão e a unidade não. A janela, por
fim, fica `notApplicable`, e não por esquecimento: só uma oferta medida por período tem uma parte do
período em que está ativa, como a linha de turnos que os membros do grupo partilham, comprometida em
turnos por semana e ativa 5 dias em cada semana, ao passo que uma equipa de pessoas, sendo uma
existência, não corre por período nenhum.

### Quanto aguenta cada amortecedor

Um resto, quando alguma coisa o absorve, vai parar a um de três amortecedores, a capacidade, as
existências ou o tempo, e cada um tem a sua folga: quanto a oferta consegue correr acima do nominal,
quanta produção se pode guardar à frente, quanta procura sobrevive à espera. A camada declara as
três, e cada uma de maneira diferente:

```xml
<pm:capacitySlack>
  <pm:absent>
    <pm:reason>unmeasured</pm:reason>
    <pm:note>uma pessoa pode trabalhar acima da sua capacidade nominal e, na maioria das
             pilhas, é a única oferta que o consegue; até que ponto acima, e durante quanto
             tempo, isso ninguém aqui mediu</pm:note>
  </pm:absent>
</pm:capacitySlack>
<pm:inventorySlack>
  <pm:claim>
    <pm:low>0</pm:low><pm:mostLikely>0</pm:mostLikely><pm:high>0</pm:high>
    <pm:unit>pessoas</pm:unit>
    …
    <pm:provenance>
      <pm:party>padaria-do-largo</pm:party>
      <pm:note>a capacidade que hoje não se usa perde-se, já que as horas não usadas da semana
               passada não se podem armazenar para servir esta, pelo que o `inventory` nunca é
               o `absorber` desta camada</pm:note>
    </pm:provenance>
  </pm:claim>
</pm:inventorySlack>
```

A folga de capacidade existe, porque as pessoas trabalham acima do que lhes cabe, e o tamanho dela é
que ninguém o mediu; a de existências é zero, porque as horas que hoje ficam por usar não se guardam
para a semana seguinte, e um zero declarado é uma afirmação, a de que alguém foi ver, coisa que um
campo vazio nunca diria; e a de tempo, que o documento declara antes da oferta, fica também
`unmeasured`, já que o trabalho em fila sobrevive à espera e ninguém mediu quanto tempo até se
perder em silêncio. Quem recebesse um simples sim ou não por amortecedor ficaria sem saber nada
disto. Uma folga por medir, essa, não deixa verificar se uma quota cabe nela, e a
verificação fica suspensa em vez de passar.

### O que de facto aconteceu

A face irregular é o que a oferta serviu de facto, e é ela que diria quem suportou o excesso, porque
um consumo colado à capacidade nominal com procura a mais quer dizer que o excesso ficou por servir,
e um consumo acima dela quer dizer que alguém o absorveu:

```xml
<pm:jagged>
  <pm:draw>
    <pm:absent>
      <pm:reason>unmeasured</pm:reason>
      <pm:note>nenhum instrumento regista as horas absorvidas acima do quadro de pessoal</pm:note>
      …
    </pm:absent>
  </pm:draw>
  <pm:measurementBasis>
    <pm:absent>
      <pm:reason>notApplicable</pm:reason>
      <pm:note>não há aqui uma valorização que possa ter uma base</pm:note>
    </pm:absent>
  </pm:measurementBasis>
</pm:jagged>
```

Nesta camada, o consumo fica `unmeasured`, e é aqui que mora a carga de quem faz o trabalho: as
horas que as pessoas dão acima do quadro não passam por transação nenhuma, pelo que nenhum
instrumento as regista e a gestão só as conhece de forma indireta. Quem lesse o branco como um
consumo igual ao nominal concluiria que o excesso ficou todo por servir, que é justamente o que o
documento não afirma. A base de mensuração, essa, é `notApplicable`, porque aqui não há valorização
nenhuma de que ela fosse a base.

### O resto, e quem o suporta

Resta o que fica entre a procura e a oferta, com o ajustamento, o amortecedor que o levou, quem o
suporta e quanto é:

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
      <pm:note>trabalho que ficou em fila, esperou e se perdeu antes de alguém lhe chegar</pm:note>
    </pm:absent></pm:share>
  </pm:holder></pm:holder>
  <pm:holder><pm:holder>
    <pm:kind>people</pm:kind>
    <pm:share><pm:absent><pm:reason>unmeasured</pm:reason>
      <pm:note>a absorção não tem contraparte e por isso não tem transação</pm:note>
    </pm:absent></pm:share>
  </pm:holder></pm:holder>
  <pm:quantity>
    <pm:derivation>
      <pm:identity>magnitude</pm:identity>
      <pm:note>calculável a partir da procura e da capacidade nominal desta camada;
               quem recebe calcula</pm:note>
    </pm:derivation>
  </pm:quantity>
</pm:remainder></pm:remainder>
```

O ajustamento é `interference`, já que a capacidade nominal fica abaixo de todo o intervalo da
procura, e o amortecedor que o levou foi a capacidade, as pessoas a trabalhar acima do que lhes
cabe. Quanto a quem o suporta, há dois: as próprias pessoas, `people`, e o trabalho que esperou até
se perder, `unrealised`, ambos com a quota `unmeasured`. O tamanho do resto, esse, não é
desconhecido, é uma derivação que quem recebe calcula a partir da procura e da capacidade nominal,
ambas declaradas, pelo que o documento não guarda uma cópia que pudesse discordar delas; o que
ninguém sabe é a divisão entre os dois que o suportam, e qual das metades cresceu é a pergunta a que
só um instrumento responderia. Com as duas quotas por medir, a regra de que as quotas somam o resto
fica suspensa, sem que nada tenha sido inventado para a fazer passar.

### As contas da camada

Feitas as contas, a procura de 4,5 a 6,0 pessoas contra uma capacidade nominal de 4 deixa um resto
de 0,5 a 2,0 pessoas, sempre em falta, com 1,2 no caso mais provável e 2,0 no pior, que é o que
junta a menor oferta à maior procura. Esses 1,2 não são todos da mesma natureza: uma pessoa inteira
é uma decisão de quadro de pessoal, que o `policy` da capacidade nominal diz caber à própria casa,
ao passo que os 0,2 que sobram são resíduo, e contratação nenhuma os remove. O percurso de
[`assets/sqlc/`](../sqlc/README.md) faz estas contas uma consulta de cada vez, desde o resto de uma
camada até à estrutura inteira.
