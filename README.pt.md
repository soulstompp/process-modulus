# process-modulus

> **Português europeu, grafia do AO90.** A versão inglesa está em [`README.md`](README.md) e é a
> que o repositório trata como autoritativa quando as duas divergirem. Os nomes dos tipos e dos
> elementos do XSD ficam em inglês, porque são os nomes do esquema; a glosa portuguesa acompanha
> entre « ».

`process-modulus` é um esquema XML para descrever como uma empresa satisfaz de facto a procura:
o que comprometeu, em que unidades esse compromisso se divide, o que a divisão deixa por
satisfazer e quem acaba por o suportar. Escrevem-se documentos contra o esquema, validam-se com
qualquer validador de XSD 1.0, e o resultado é uma descrição que outra organização consegue ler
sem executar nada deste código.

> **URI de espaço de nomes provisórios.** Ambos os esquemas e o `build.rs` transportam
> `https://example.invalid/…` até estar decidido o domínio do autor. O `tests/namespace.rs` faz
> da sua alteração uma operação verificada. Todo o resto é definitivo.

O modelo parte de uma observação. Uma empresa é uma pilha de ofertas quantizadas a servir
procuras contínuas. A procura varia de forma suave, ao passo que a oferta chega em unidades
inteiras: uma pessoa, um bloco reservado de equipamento, um lançamento, uma ronda de
financiamento. A diferença entre as duas é um **resto**, e não desaparece. A gestão escolhe que
amortecedor o absorve e quem o suporta. A gestão não escolhe se ele existe.

O que o resto faz a seguir é a parte que demora mais a ver, e não é o que a palavra «sobra»
sugere. Uma empresa a quem se pede mais do que aquilo a que se comprometeu não estanca. Acomoda.
A linha corre um pouco acima do previsto, a fila cresce até quem espera desistir, e a partir daí
uma parcela estável da procura vai-se embora todas as semanas. A empresa está em falta e estável
ao mesmo tempo, e pode ficar assim durante anos. **Nada falha. O que se produz é um resíduo**,
semana após semana, e é esse resíduo o objeto deste esquema.

O que torna a pergunta não «aguentaram?» mas **para onde é que aquilo foi**. Uma parte foi
absorvida pela equipa a trabalhar acima da sua capacidade nominal. Uma parte foi assumida por uma
contraparte, que a faturou. Uma parte foi suportada por um cliente que esperou e depois foi a
outro lado. Uma parte nunca chegou a ser servida. São quatro acontecimentos diferentes com quatro
consequências diferentes, e só uma das cinco maneiras de suportar um resto deixa transação atrás
de si.

É essa que este modelo acrescenta: a capacidade absorvida por quem faz o trabalho. Nada foi
comprado, portanto não há transação, portanto nenhum instrumento a regista, portanto é invisível
para todos os sistemas que partem de transações. O esquema está construído de forma a que
«ninguém mediu isto» seja uma afirmação que alguém declara, e não uma célula que se deixa em
branco.

E, uma vez declarado assim, segue-se algo útil. Se um documento diz quanto foi pedido, quanto foi
comprometido e até onde a oferta pode ser empurrada acima da sua capacidade nominal, então **a
parte do resíduo que não tem registo nenhum por trás pode mesmo assim ser calculada** — não como
argumento sobre trabalho invisível, mas como número, a partir de três campos que o declarante
teve de preencher de qualquer maneira.

Isto é uma exigência real, e vale a pena dizer o preço à cabeça. Escrever contra este esquema
significa comprometer-se a dizer que espécie de branco é cada branco, a exprimir quantidades como
intervalos em vez de números únicos, e a nomear a autoridade por trás de cada valor emprestado a
outrem. Os conjuntos de dados que já existem tendem a não fazer nenhuma das três coisas, e é essa
migração que dá trabalho. O que se ganha é um documento que continua verdadeiro depois de
atravessar uma fronteira organizacional, que é o único sítio onde algo disto interessa.

## Funcionalidades

- **Um esquema, não uma biblioteca.** `schema/process-modulus.xsd` é o artefacto. Validar um
  documento não precisa de Rust nem de nenhuma dependência deste projeto.
- **XSD 1.0 de propósito**, para que o `xmllint`, o validador que vem com o JDK, o `lxml`, o
  Nokogiri e tudo o resto que embrulha a libxml2 possam verificar um documento numa máquina sem
  instalar nada.
- **Ausência tipificada.** Um branco diz que espécie de branco é: `none`, `unmeasured`,
  `notApplicable` ou `derived`. A ausência de prova e a prova da ausência deixam de se parecer.
- **Afirmações de três pontos.** Todas as quantidades são um `low`, um `mostLikely` e um `high`
  com a sua proveniência e data. Não há nenhum tipo numérico simples em todo o modelo.
- **Os valores emprestados transportam a sua autoridade.** Tudo aquilo que este modelo não possui
  viaja como `BorrowedTerm { taxonomy, value }` com a taxonomia obrigatória, portanto um valor
  chega com a autoridade que o define em vez de chegar como um código solto.
- **Os regimes separam-se em eixos.** Jurisdição, normativo e a autoridade que codifica o
  normativo são três perguntas, e uma enumeração que as misture não responde a nenhuma.
- **As respostas viajam sozinhas.** O `schema/assertion.xsd` permite que um segundo interveniente
  responda a um conjunto de perguntas e envie as respostas sem executar nada daqui.
- **As observações entre declarações têm onde ficar.** Uma dependência entre duas entidades que
  declaram em separado pertence a quem leu as duas declarações, e é um documento e não uma nota
  de rodapé em qualquer uma delas.
- **Uma consolidação é um documento que alguém assina.** Duas declarações honestas não podem ser
  fundidas por heurística nenhuma — juntá-las pelo nome da camada funde coisas sem relação;
  juntá-las pelos factos declarados falha o par que é genuinamente uma só camada. Portanto quem
  tem legitimidade declara o mapeamento e assina-o, diz o que tratou como uma só camada e porquê,
  e regista o que retirou para não contar procura duas vezes. As composições encaixam umas nas
  outras.
- **Refutável no seu próprio formato.** O `assets/corpus/refutation.xml` é um documento válido que
  declara dois contraexemplos ao modelo.
- **Uma biblioteca Rust gerada.** Todos os tipos e todos os comentários de documentação vêm dos
  esquemas, portanto o `cargo doc` mostra as anotações do próprio esquema, em inglês e em
  português.
- **As regras inalcançáveis, tornadas executáveis.** Quarenta e quatro regras estão enunciadas na
  prosa dos esquemas e não têm porta nenhuma a guardá-las, porque o XSD 1.0 não consegue comparar
  um elemento com outro. A maior parte são junções e comparações. O [`assets/sql/`](assets/sql/)
  exprime-as como SQL — incluindo aquela que validador nenhum vê, a de que nenhuma camada-folha é
  alcançável por dois caminhos quando as composições encaixam — e reporta quantas linhas cada
  regra examinou, porque uma regra sem nada para verificar é a que passa mais alto.
- **Todo o branco traz uma razão.** Não «o campo está vazio», mas *qual* espécie de vazio: alguém
  procurou e não há; ninguém mediu; a pergunta não se aplica aqui; ou é calculado a partir de
  outra coisa. Isso também vale para as listas — uma pilha sem acoplamentos declarados diz se
  alguém foi procurar, porque «testámos as camadas e são independentes» e «ninguém verificou» são
  afirmações opostas e costumavam ser o mesmo documento.

## Porquê o process-modulus

**O resto é o contributo.** Os amortecedores são os de Hopp e Spearman, fechados em três no
*Factory Physics*, e este modelo adota-os como estão publicados em vez de acrescentar um quarto.
O que acrescenta é um eixo separado: quem suporta o resto. `booked`, `counterparty`, `customer`,
`unrealised` e `people` são os cinco, e só o último não tem instrumento por trás.

**A procura deteriora-se, e é isso que mantém a aritmética honesta.** Uma fila de que ninguém sai
cresce para sempre, e um modelo construído sobre isso classificaria como incoerente qualquer
empresa acima da capacidade — que é a maioria delas, na maior parte do tempo. O `timeSlack` é
quanto tempo a procura sobrevive à espera, declarado como quantidade medida e não como um sim ou
não. É o que permite descrever uma empresa permanentemente em falta como uma entidade em
continuidade e não como uma contradição. Repare-se no que **não** é: não é uma pergunta sobre se
o cliente *está disposto* a esperar. Aqui ninguém recusa nada a ninguém. A procura decai, da
mesma maneira que um pastel não vendido decai.

**Um branco é uma afirmação, portanto deve ser tipificado como tal.** O `unmeasured` num consumo
de mão de obra é o argumento central do modelo, escrito. Se um declarante só puder deixar o campo
vazio, então o argumento e um esquecimento ficam idênticos, e o próprio assunto do modelo torna-se
irregistável no modelo.

**Um código sem a sua autoridade é ambíguo, e não meramente não atribuído.** `6250` é uma conta no
PGC espanhol e outra diferente no BAS sueco. Duas testemunhas que citam o mesmo conjunto de
códigos são comparáveis linha a linha; duas que citam conjuntos diferentes são legivelmente
diferentes em vez de silenciosamente incomparáveis. Exigir a taxonomia é o que compra isso.

**A independência é o que faz a concordância significar alguma coisa.** Esta biblioteca não
depende de nada da base de código cujo modelo corrobora, e o `tests/independence.rs` faz falhar a
compilação se isso deixar de ser verdade. Dois modelos que partilhem um tipo ou um caminho de
código não se podem corroborar, porque a concordância entre eles é uma tautologia. Quem consome
deve gerar os seus tipos a partir do esquema, tal como o seu leitor de BPMN gera a partir dos
esquemas da OMG.

**O desacordo tem para onde ir.** Um modelo contra o qual não se possa declarar um contraexemplo
não está a fazer grande coisa. O `Coupling` regista uma dependência observada entre os restos de
duas camadas, e uma oferta contínua cujo prémio é `none` contradiz a afirmação sobre preços. Ambos
são documentos válidos.

### Ressalvas

* O modelo é deliberadamente pequeno e não é, nem de perto, uma descrição completa de uma empresa.
  Diz o que é uma oferta, o que sobra e quem o suporta. Tudo o que diga respeito a sequência,
  controlo de fluxo e eventos é trabalho do BPMN, e este modelo aponta para o BPMN em vez de o
  reescrever.

* Quarenta e quatro regras ao longo dos dois esquemas estão enunciadas em prosa e nenhum validador
  lhes chega, porque o XSD 1.0 não tem `xs:assert` e não consegue comparar entre elementos.
  Quarenta e uma estão marcadas com `NOT REACHABLE BY A VALIDATOR` na anotação que as enuncia, de
  forma que um leitor consiga distinguir uma regra vinculativa de uma não verificada. O
  [`conformance/README.pt.md`](conformance/README.pt.md) lista as quarenta e quatro e diz o que um
  implementador continua a dever.

* Desserializar não é validar, e há um caso concreto onde as duas diferem. O `Operation` é uma
  sequência com uma escolha repetida lá dentro, que o gerador de código achata num único `Vec`,
  pelo que o `label` deixa de ser um campo singular obrigatório do ponto de vista do `rustc`. O
  XSD continua a impô-lo. Valide-se com um validador de XSD.

* Ainda não é distribuído nenhum perfil de conformidade. Um perfil deve seguir um adotante real em
  vez de o preceder, e o raciocínio está em `conformance/`.

* Os URI dos espaços de nomes ainda são marcadores de posição. Mais nada no repositório é.

## Exemplo: uma equipa de quatro a servir uma procura de cinco

A raiz do documento é um `processModulus`: algumas declarações de regime, uma pilha de camadas, e
quantas operações se quiser a consumir delas.

```xml
<pm:processModulus xmlns:pm="https://example.invalid/process-flow/1.0">
  <pm:regime> ... aquilo ao abrigo do qual este documento reporta ... </pm:regime>
  <pm:stack>
    ... as camadas ...
    <pm:couplings>
      <pm:absent>
        <pm:reason>unmeasured</pm:reason>
        <pm:note>ninguém testou se estas camadas se movem em conjunto</pm:note>
      </pm:absent>
    </pm:couplings>
  </pm:stack>
  <pm:operation> ... o que consome delas ...                          </pm:operation>
</pm:processModulus>
```

O `couplings` é obrigatório, e é o único elemento do esquema que pergunta a quem declara se
**testou** o modelo em vez de perguntar o que mediu. Uma pilha afirma que as suas camadas são
sítios separados onde uma falta pode assentar; é aqui que quem declara diz se alguém verificou.
«Aliviámos uma camada e as outras não se mexeram» e «ninguém foi ver» são afirmações opostas, e
sem isto eram o mesmo documento vazio.

Uma camada é uma procura, uma oferta e o resto entre as duas. Eis a camada de mão de obra do
[`assets/corpus/enterprise-contract.xml`](assets/corpus/enterprise-contract.xml), que é o caso para
o qual o modelo inteiro existe. A procura está entre 4,5 e 6 pessoas. A oferta é de quatro
pessoas, e uma pessoa não é divisível.

```xml
<pm:layer>
  <pm:name>labour</pm:name>

  <pm:demand>
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
      <pm:provenance><pm:party>platform</pm:party></pm:provenance>
      <pm:asOf>2026-08-30</pm:asOf>
    </pm:claim>
  </pm:demand>
```

Dois factos viajam ao lado do intervalo, e respondem a perguntas diferentes. O `narrowsWhen` é o
que teria de mudar para o intervalo **estreitar** — e o `kind` diz se isso é uma medição a chegar
ou o próprio processo a mudar, que é a diferença entre não saber e variar genuinamente. O
`boundOrigin` é **de quem é o limite**: aqui o `none` diz que alguém foi ver e que o limite não é
de ninguém, porque este intervalo é onde caíram doze meses de observações e não onde uma regra o
pôs. Uma procura limitada por um contrato diria `contractual`, e isso é uma alavanca.

A oferta tem duas faces. A `nameplate` é o que foi comprometido, e é onde vive a divisibilidade.
Ficam registadas duas restrições diferentes, e mantê-las separadas é o essencial: `origin` é com
quem se teria de falar para alterar o **tamanho de uma unidade**, e `intrinsic` quer dizer
ninguém, porque uma pessoa é uma pessoa. O `amountOrigin` é com quem se teria de falar para deter
um **número diferente delas**, e `policy` quer dizer nós, porque o quadro de pessoal é nosso.

São esses dois que fazem com que as afirmações acima respondam `derived` ao `boundOrigin` em vez
de se repetirem. A pergunta *de quem é este limite* já está respondida um elemento ao lado, e um
documento que a respondesse duas vezes acabaria por a responder de duas maneiras diferentes.

A `window` é a outra metade da divisibilidade: não como a oferta se divide em **quantidade** mas
como se divide no **tempo** — uma linha que corre cinco dias em sete, uma máquina parada duas
horas por dia. Um efetivo não tem ciclo nenhum desses, portanto a resposta é `notApplicable` e a
razão diz qual das alternativas se quer dizer. Não é um branco.

```xml
  <pm:supply>
    <pm:label>the platform team</pm:label>
    <pm:nameplate>
      <pm:amount>
        <pm:claim>
          <pm:low>4</pm:low><pm:mostLikely>4</pm:mostLikely><pm:high>4</pm:high>
          <pm:unit>people</pm:unit>
          ... narrowsWhen: notApplicable, não há aqui intervalo para estreitar ...
          ... boundOrigin: derived, o amountOrigin abaixo é que o declara ...
        </pm:claim>
      </pm:amount>
      <pm:amountOrigin><pm:origin>policy</pm:origin></pm:amountOrigin>
      <pm:divisibility>
        <pm:divisibility>
          <pm:lumpy>
            <pm:size>
              <pm:claim>
                <pm:low>1</pm:low><pm:mostLikely>1</pm:mostLikely><pm:high>1</pm:high>
                <pm:unit>people</pm:unit>
                ... boundOrigin: derived, a origin abaixo é que o declara ...
              </pm:claim>
            </pm:size>
            <pm:origin>intrinsic</pm:origin>
          </pm:lumpy>
          <pm:window>
            <pm:absent>
              <pm:reason>notApplicable</pm:reason>
              <pm:note>`people` is a stock with no period</pm:note>
            </pm:absent>
          </pm:window>
        </pm:divisibility>
      </pm:divisibility>
      <pm:capacitySlack>
        <pm:absent>
          <pm:reason>unmeasured</pm:reason>
          <pm:note>a person can work above their rating; how far above, nobody has measured</pm:note>
        </pm:absent>
      </pm:capacitySlack>
      <pm:inventorySlack>
        <pm:absent>
          <pm:reason>none</pm:reason>
          <pm:note>an hour not used today is gone; it cannot be stockpiled for next week</pm:note>
        </pm:absent>
      </pm:inventorySlack>
    </pm:nameplate>
```

Os dois elementos de margem dizem quanta folga tem cada amortecedor. Uma pessoa pode ser levada
acima da sua capacidade nominal, portanto esse amortecedor está aberto e ninguém mediu até onde —
`unmeasured`. Uma hora não usada não pode ser guardada para a semana seguinte, portanto esse está
fechado, e `none` é o valor que diz que alguém verificou e não que alguém saltou a pergunta. A
diferença conta mais à frente: uma parcela só pode ser atribuída a um amortecedor que tenha folga
para ela.

O `jagged` é a outra face, que é o que aconteceu de facto. É aqui que o argumento fica declarado.
Nada registou as horas absorvidas acima do quadro de pessoal, portanto o consumo é `unmeasured`
com uma nota a dizer porquê e um interveniente a responder pela afirmação. Não é um elemento
vazio.

```xml
    <pm:jagged>
      <pm:draw>
        <pm:absent>
          <pm:reason>unmeasured</pm:reason>
          <pm:note>no instrument records hours absorbed above the establishment</pm:note>
          <pm:provenance><pm:party>platform</pm:party></pm:provenance>
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
  </pm:supply>
```

Repare-se em que as duas ausências têm razões diferentes. O consumo é `unmeasured`, o que quer
dizer que podia existir um instrumento e não existe. A base de mensuração é `notApplicable`, o que
quer dizer que fazer a pergunta aqui é malformado, porque um efetivo não tem valorimetria de que
possa ter base. Quem recebesse e tratasse a segunda como uma lacuna reportaria uma deficiência que
não existe.

O resto é então a conclusão. A procura excedeu a capacidade nominal, portanto o ajustamento é de
`interference` no sentido mecânico emprestado à ISO 286: funciona por deformação do material, e
inspecionar o produto não o revela. Uma camada também pode estar em falta numas semanas e com
sobra noutras, que é a terceira classe, `transition`, e é a condição corrente de uma empresa no
limite da capacidade. O amortecedor é o `capacity` de Hopp e Spearman, citado à sua taxonomia em
vez de reescrito.

Os **detentores** são onde o argumento assenta. Uma parte do excesso a equipa absorveu, e outra
parte ficou em fila, esperou e foi-se embora em silêncio. Nenhuma das duas deixa registo, portanto
ambas as **parcelas** são `unmeasured` — e note-se o que isso não diz. Não diz que o resto é
desconhecido: a grandeza é `derived` a partir de números que já estão no documento. Diz que
ninguém consegue dizer como é que as duas metades se dividem, o que é uma admissão bem mais
pequena e bem mais afiada.

```xml
  <pm:remainder>
    <pm:remainder>
      <pm:sign><pm:fit>interference</pm:fit></pm:sign>
      <pm:absorber>
        <pm:term>
          <pm:taxonomy>urn:example:factory-physics:buffers</pm:taxonomy>
          <pm:value>capacity</pm:value>
        </pm:term>
      </pm:absorber>
      <pm:holder>
        <pm:holder>
          <pm:kind>people</pm:kind>
          <pm:share>
            <pm:absent>
              <pm:reason>unmeasured</pm:reason>
              <pm:note>the absorption has no counterparty and therefore no transaction</pm:note>
            </pm:absent>
          </pm:share>
        </pm:holder>
      </pm:holder>
      <pm:holder>
        <pm:holder>
          <pm:kind>unrealised</pm:kind>
          <pm:share>
            <pm:absent>
              <pm:reason>unmeasured</pm:reason>
              <pm:note>work that queued, waited and aged out before anyone got to it</pm:note>
            </pm:absent>
          </pm:share>
        </pm:holder>
      </pm:holder>
      <pm:quantity>
        <pm:absent><pm:reason>derived</pm:reason></pm:absent>
      </pm:quantity>
    </pm:remainder>
  </pm:remainder>
</pm:layer>
```

Repare-se em qual das duas está ausente, porque não é a que se espera. A grandeza do resto é
`derived`: o documento determina-a e quem recebe calcula-a. Aquilo a que instrumento nenhum chega
é a `share` — quanto daquela diferença a equipa absorveu em vez de ter recusado.

Quatro pessoas, uma procura de cinco, uma unidade indivisível de um, e uma diferença que assentou
em alguém. O documento diz em quem, diz a grandeza, diz que ninguém mediu a parte que interessa, e
diz quem responde por essa afirmação. É o modelo inteiro numa camada.

## Começar depressa

```bash
cargo test          # lê assets/corpus/ com os tipos gerados e verifica as suas afirmações
cargo doc --open    # as anotações dos esquemas, em inglês e em português, como rustdoc
```

Validar um documento não precisa de nada disso, que é a razão de se distribuir um esquema em vez
de uma biblioteca:

```bash
xmllint --noout --schema schema/process-modulus.xsd assets/corpus/enterprise-contract.xml
xmllint --noout --schema schema/process-modulus.xsd assets/corpus/contrato-empresarial.xml
xmllint --noout --schema schema/assertion.xsd       assets/corpus/coverage-us-gaap.xml
```

E uma terceira via, que verifica as regras a que um validador não chega:

```bash
createdb process_modulus_proof
psql -d process_modulus_proof -f assets/sql/schema.ddl \
                              -f assets/sql/ingest.sql \
                              -f assets/sql/rules.sql
```

O Postgres lê o próprio conjunto de documentos — sem Rust, sem extensões, sem superutilizador.
Ver [`assets/sql/README.pt.md`](assets/sql/README.pt.md), que é o documento onde as regras
são demonstradas.

O `assets/corpus/` tem doze documentos: um contrato empresarial e a sua tradução portuguesa, uma
refutação, um que exercita tudo o que um declarante pode recusar, duas declarações de membros do
grupo e as duas composições encaixadas que os consolidam, dois ficheiros de cobertura que
respondem às mesmas perguntas sob regimes diferentes, um registo de execução, e uma dependência
entre documentos.

## O modelo

A metade de existências descreve uma oferta e o que sobra dela.

| | |
|---|---|
| `Facility` | uma oferta com as duas faces ao mesmo tempo: a `Nameplate` que foi comprometida, e o registo `Jagged` do que aconteceu |
| `Divisibility` | como uma oferta se divide, em dois eixos. Em QUANTIDADE é `lumpy` (discreta) ou `continuous` — uma escolha entre duas formas, não um tamanho que possa ser zero, portanto uma oferta contínua não tem quantum em vez de ter um quantum de zero. No TEMPO pode transportar uma `window`: a máquina que corre das 02:00 às 05:00, o regime de turnos, as duas horas por dia de manutenção. Uma oferta pode ser as duas coisas, e a escolha não o conseguia dizer |
| `LumpyQuantum` | a unidade indivisível que dá o nome ao projeto. Em `a mod n`, `n` é o módulo, e `a mod n` é o resto que ele deixa |
| `ConstraintOrigin` | com quem é preciso falar para alterar alguma coisa: `intrinsic` (ninguém), `contractual` (a contraparte), `policy` (nós, unilateralmente). É perguntado duas vezes, sobre duas coisas diferentes: o tamanho de uma unidade, e quantas unidades se detêm |
| `Remainder` | o que a divisão deixa, e separa-se em quanta inteiros que alguém escolheu mais um resíduo que ninguém consegue remover. O `absorber` nomeia o conjunto de amortecedores de outrem; o `holder`, quem o suporta, é deste modelo |
| `Holder` | quem suporta um resto, e quanto dele. Um resto assenta com frequência em vários intervenientes ao mesmo tempo, portanto cada um transporta uma `share` e as parcelas somam o todo. Um detentor único obrigava o declarante a escolher o maior e deitar fora o resto, e a metade deitada fora costuma ser a interessante |
| as três **margens** | uma quantidade medida por amortecedor, e os três factos sobre uma camada que aritmética nenhuma recupera. `capacitySlack`: até onde a oferta pode ser levada acima da sua capacidade nominal — não capacidade sobrante, a folga ACIMA da nominal. `inventorySlack`: quanto produto se pode manter adiantado. `timeSlack`: quanto tempo a procura sobrevive à espera. Foram três valores booleanos, e um bit diz que um amortecedor existe e não quanto ele leva, portanto qualquer parcela cabia |
| `Fit` | o sinal de um resto, no sentido da ISO 286: `clearance` (folga), `transition` (ajustamento incerto), `interference` (interferência). Um ajustamento `transition` está em falta no topo do intervalo da procura e com sobra na base, que é a condição corrente de uma empresa no limite, e é um valor e não uma hesitação |
| `HolderKind` | as cinco maneiras de suportar um resto: `booked`, `counterparty`, `customer`, `people`, `unrealised`. Só a primeira deixa transação. `customer` e `unrealised` são ambos procura que ninguém serviu, e diferem em se havia alguém para a experimentar |
| `Claim` | como toda a quantidade é expressa, como estimativa de três pontos com a sua proveniência |
| `Absence` | um branco que diz que espécie de branco é. Uma razão a que uma consulta não chega não é uma ausência tipificada, portanto um parágrafo num campo de notas não conta |
| `Provenance` | quem responde por um valor, como `party`, `enteredBy` e `approvedBy`, e que `standing` (legitimidade) tem a afirmação |

A metade de fluxo descreve onde uma oferta encontra uma procura e o que consome dela.

| | |
|---|---|
| `Layer` | uma procura, uma oferta e um resto, mais o `timeSlack`: quanto tempo essa procura sobrevive à espera. Não se o cliente *está disposto* a esperar — isso seria uma afirmação infalsificável sobre o estado de espírito de outra pessoa, declarada por quem beneficia da resposta. A procura decai, como as existências decaem, e isto mede o decaimento |
| `Stack` | as camadas de um sistema, deliberadamente sem ordem |
| `Coupling` | uma dependência observada entre os restos de duas camadas |
| `Operation` | a unidade à qual um consumo é atribuível, e não uma unidade de sequência |
| `Draw` | o que uma operação retira de uma camada, agora |
| `Induction` | um compromisso assumido aqui que se torna um consumo noutro sítio, e quem o assumiu |

### Quatro decisões que vale a pena conhecer

**O esquema não enumera as camadas.** O que faz de alguma coisa uma camada é que o seu resto pode
ser suportado independentemente do de todas as outras. Isso é um teste que se aplica em vez de uma
lista que é preciso receber, é também o quarto falsificador do modelo, e quer dizer que uma camada
nova não exige alteração ao esquema. A pilha não tem ordem pela mesma razão: uma ordenação entre
camadas seria ela própria um acoplamento, e afirmá-la no contentor prejulgaria a pergunta a que o
`Coupling` existe para responder.

**Uma operação consome e produz de forma assimétrica.** O que consome é um consumo contra a oferta
de uma camada, agora. O que produz é um compromisso induzido noutra camada mais tarde, e não uma
quantidade de produto. `Draw` e `Induction` são dois tipos apesar de terem uma forma quase
idêntica, porque juntá-los num só com um discriminador poria duas espécies de facto na mesma
posição.

**O `ConstraintOrigin` mantém um falsificador honesto.** Um fornecedor que passe a vender em
incrementos mais finos é um mercado a mexer-se e não uma refutação do modelo, e separar os quanta
por quem os pode alterar é o que torna a diferença legível.

**O modelo não transporta relógio nenhum, e o tempo entra à mesma por três vias.** Aqui não há
sequência nem carimbo temporal em nada que se mova, porque a sequência e o tempo são trabalho do
BPMN. Mas três escalas temporais diferentes pesam sobre qualquer número num documento, e o modelo
declara duas delas. A primeira é o **quantum** — o tamanho da unidade em que a oferta chega. A
segunda é o **denominador** da unidade, o período sobre o qual uma taxa é cotada: `por trimestre`,
`por semana`, e é aquilo de que uma `window` é uma fração. A terceira é a escala temporal a que
uma quantidade de facto se move, e não tem elemento nenhum. Isso importa porque um intervalo neste
modelo lê-se como *aquilo que não sabemos* — o `narrowsWhen` diz o que o estreitaria — ao passo
que um intervalo que seja variação genuína de semana para semana não estreita por se medir com
mais cuidado. As duas coisas não são distinguidas, e dizê-lo é mais útil do que fingir que a
pergunta não se põe.

## Como se articula com as normas existentes

O modelo nomeia o vocabulário dos outros em vez de o reescrever. Um conjunto de valores reescrito é
uma bifurcação, e uma bifurcação afasta-se sem que nada aqui o consiga notar.

| emprestado de | o quê, e como se liga |
|---|---|
| BPMN 2.0 | sequência, gateways e eventos. O `ForeignId` aponta para a mesma operação num modelo BPMN, portanto uma notação de processo e este modelo viajam juntos |
| *Factory Physics* (Hopp e Spearman) | o conjunto de amortecedores de existências, capacidade e tempo, adotado fechado e como está publicado |
| ISO 286 | as três classes de ajustamento — `clearance`, `transition` e `interference` — no sentido mecânico, adotadas fechadas e como estão publicadas |
| normativos contabilísticos | todas as bases de mensuração exceto `nameplate`, que descreve capacidade comprometida e não valor, e por isso não tem definição normativa que citar |

Aquilo por que este modelo responde é a lista curta: `Remainder`, `Holder` e `HolderKind`,
`Divisibility` e `ConstraintOrigin`, as três margens, `Layer` e `Coupling`, `Induction`, `Claim`,
`Absence`, `Provenance`, e `nameplate`.

## Regimes

Um documento declara ao abrigo do que reporta. O `Regime` mantém a jurisdição, o normativo e a
autoridade que codifica o normativo como três eixos separados, porque uma lista que os misture
(`us-gaap`, `us-accrual`, `pt`) não consegue responder a nenhuma das três perguntas que funde.

O `framework` pode ser recusado com uma razão, portanto «reporta ao abrigo de algo ainda não
nomeado» e «não reporta ao abrigo de nada» são documentos diferentes e não uma omissão só. O
`chart` nomeia o plano de contas em que as posições são codificadas e funciona da mesma maneira. É
obrigatório por uma razão: é aquilo contra o que quem recebe confere a posição de uma resposta, e
um branco que não se distinga de uma pergunta não feita desliga a verificação.

**Um plano de contas não é uma taxonomia de reporte**, e confundi-los é o erro que o elemento
existe para apanhar. O PGC espanhol, o BAS sueco e o SNC português são listas de contas onde uma
entidade movimenta lançamentos. O `http://fasb.org/us-gaap` é uma lista de conceitos com que uma
demonstração é etiquetada, e pertence ao `framework`. Declarar uma taxonomia de reporte como plano
de contas declara um plano onde ninguém lança.

**Os Estados Unidos não publicam plano de contas nenhum.** O plano de cada preparador é seu e não
é publicado, o que não é um caso limite mas uma população inteira de declarantes. Um plano de
autoria própria nomeia a entidade como sua própria taxonomia: o preparador é genuinamente a
autoridade sobre a sua própria lista de contas, e nomear-se a si próprio satisfaz a regra
honestamente em vez de a contornar. O `unmeasured` é a resposta errada aí, porque esse plano não é
publicado e não é desconhecido.

**Um código de país não consegue escolher um normativo sozinho.** Todas as jurisdições encontradas
até agora escalonam os seus normativos por dimensão da entidade. Portugal tem NCRF, NCRF-PE e
NC-ME ao lado das NIC, a Espanha tem o PGC com as suas variantes para PME e microentidades, a
Suécia tem K1 a K4. O escalão é um facto sobre a entidade, e é ele que seleciona o normativo.

**O mesmo normativo é também codificado de maneira diferente por autoridades diferentes.** Uma
microentidade portuguesa é `NC-ME` para o `AnexoASNC` da IES e `M` para o referencial do SAF-T, e
como o `S` cobre tanto `NCRF` como `NCRF-PE`, o código mais grosseiro não pode ser convertido de
volta. Declarar os dois regimes é correto e não duplicado, já que nenhuma das declarações diz o
que o par diz.

Um perfil de conformidade está portanto associado a um par `(autoridade, normativo)` e nunca a um
país. Ver [`conformance/README.pt.md`](conformance/README.pt.md).

## Respostas de uma segunda testemunha

O `schema/assertion.xsd` transporta o que uma testemunha afirma sobre um conjunto de perguntas,
mais uma execução promovida a prova. Importa o esquema base para o `BorrowedTerm` e o `Regime`.

As próprias perguntas ficam em cada conjunto, porque formatos de data e casos de instalações são
assuntos diferentes e unificá-los seria fingir o contrário. O que atravessa organizações é a
afirmação. As respostas de um contabilista a um conjunto de perguntas **são** um ficheiro de
cobertura, e ninguém devia ter de executar o código deste projeto para enviar um.

Ambas as coisas que uma resposta transporta são termos emprestados. Um código de recusa vem de um
conjunto de códigos, que é deliberadamente partilhado entre regimes. Uma posição num plano de
contas é nacional, portanto uma testemunha norte-americana cita o plano da própria entidade.
Guardadas como códigos soltos, duas posições de dois países comparar-se-iam como iguais ou
diferentes sem que qualquer dos resultados significasse alguma coisa.

O [`assets/corpus/coverage-us-gaap.xml`](assets/corpus/coverage-us-gaap.xml) e o
[`coverage-pt-ncrf-pe.xml`](assets/corpus/coverage-pt-ncrf-pe.xml) respondem às mesmas perguntas
sob dois regimes, e o `tests/coverage_parse.rs` afirma que a comparabilidade se mantém onde as
autoridades coincidem e quebra onde não coincidem.

Não há aqui nenhum executor, e isso é deliberado. A unificação é por conformidade e não por
dependência: um vocabulário partilhado mais um teste por executor de que ele está conforme, nunca
uma biblioteca que toda a gente importa.

## Uma dependência entre duas declarações pertence a quem leu as duas

O `Coupling` regista uma dependência observada entre duas camadas de uma pilha. A dependência que
interessa é muitas vezes entre duas entidades que declaram em separado e não se conseguem ver uma
à outra, como uma casa-mãe e uma subsidiária, um fornecedor e um cliente, ou dois mutuários do
mesmo financiador.

Alargar o `Coupling` para apontar através dessa fronteira foi considerado e rejeitado. Poria
dentro do documento da entidade A uma afirmação que A não pode atestar, porque A não vê a pilha de
B, e as restrições de identidade não a conseguiriam acompanhar, pelo que a referência validaria
por não ser verificada. Uma referência que parece restringida e não é é pior do que uma lacuna
honesta.

Em vez disso, o `schema/assertion.xsd` transporta o `dependence`, uma observação *sobre* duas
declarações, feita pelo terceiro que leu ambas: um consolidador de grupo, um auditor, um
financiador. Ambas as pontas são externas, sempre, e é isso que faz o desenho funcionar. Nunca há
uma ponta local ao lado de uma externa, portanto nunca há uma referência que tenha de atravessar
uma fronteira e não consiga. O mundo já declara assim, já que uma consolidação é uma demonstração
separada e não uma nota de rodapé nas contas da subsidiária.

O
[`assets/corpus/dependence-group-consolidation.xml`](assets/corpus/dependence-group-consolidation.xml)
declara uma através de dois regimes, e o `tests/dependence_parse.rs` afirma a propriedade para a
qual existe, que é a de que nenhuma das pontas é a declaração da própria testemunha.

## Uma consolidação é uma declaração, e quem compõe assina-a

Um `dependence` comenta duas declarações. Uma `composition` vai um passo mais longe: quem as leu
**declara**. É um documento que transporta uma pilha inteira sua mais o mapeamento que diz de que
camadas de que declarações foi construída cada uma das suas próprias camadas.

O problema que resolve aparece assim que se tem duas declarações reais em mãos. Dois membros de um
grupo declaram honestamente, e nenhum pode ser fundido no outro por regra nenhuma que se consiga
escrever. Juntá-los pelo nome da camada faz de dois contratos de fornecedores sem relação, ambos
chamados `compute`, uma só camada. Juntá-los pelos factos declarados falha o par que é
genuinamente uma só camada, porque um dos membros se instrumenta melhor do que o outro e por isso
os seus números diferem. Duas estratégias, erradas em direções opostas, sobre um par de documentos
honestos.

A reparação não pode viver em nenhum dos membros. Nenhum viu a pilha do outro, nenhum tem
legitimidade para nomear as camadas do outro, e uma declaração não pode citar uma lista publicada
depois dela. Portanto quem compõe fornece o mapeamento no seu próprio documento e assina-o, e três
coisas o transportam:

| | |
|---|---|
| `Fusion` | que camadas declaradas são **uma** só camada, e porquê. **Fundir só o que é fungível**: se uma unidade de oferta de uma parte pode servir a procura da outra, então não suportam os seus restos independentemente e são uma camada. Se não pode, são duas, e um `Coupling` é onde vai parar qualquer interação observada. Esse juízo é de quem compõe, o `observed` é onde o defende, e é a afirmação com que um leitor tem direito a discordar. Uma camada sem fusão nenhuma é o terceiro caso — uma que quem compõe **originou**, como uma escala de serviço ao nível do grupo |
| `Part` | uma camada declarada a entrar, com o `factor` que a põe na unidade da camada composta. `4,4 GPU + 545 GPU-hora` não é uma soma, e quem compõe e multiplica por 720 em silêncio fez exatamente a aritmética não auditada que este documento existe para expor. Um fator é ele próprio uma afirmação de três pontos, porque um mês são `[672, 720, 744]` horas |
| `Elimination` | o que foi retirado, e porque é que a figura fundida **não** é a soma das suas partes. Quando um membro encomenda trabalho a outro, ambos o declaram como procura própria, honestamente, e a procura do grupo é a soma menos a encomenda. Nomeia qual das três quantidades atinge, já que um ajustamento que não o diga é aplicado ao número que o leitor tiver por acaso na mão |

**Se alguém procurou duplicações é ele próprio um facto declarado.** Uma lista vazia dizia
«verificámos e as partes são disjuntas» e «ninguém verificou» nos mesmos bytes, e as duas devem
aritméticas opostas: sob uma procura verificada e limpa a figura composta tem de igualar
exatamente a soma das partes convertidas, e sob `unmeasured` não é devida igualdade nenhuma. É a
diferença entre uma regra exata e um aviso, e é por isso que a procura tem uma ausência tipificada
própria em vez de ser inferida de uma contagem de zero.

**As composições encaixam, e uma regra escapa-se quando isso acontece.** Uma composição é ela
própria uma declaração, portanto um segmento compõe membros e um grupo compõe segmentos sem nada
acrescentado. Dentro de um documento um validador consegue impor que nenhuma camada declarada seja
consolidada duas vezes. Através de dois não consegue, porque o segundo caminho atravessa um
documento que este não contém — portanto «nenhuma camada-folha é alcançável por dois caminhos» é
devida por quem consiga ir buscar a cadeia, e o [`assets/sql/`](assets/sql/) é onde é
verificada de facto.

O [`assets/corpus/merge-us-member.xml`](assets/corpus/merge-us-member.xml) e o
[`merge-pt-member.xml`](assets/corpus/merge-pt-member.xml) são os dois membros; o
[`merge-group-composition.xml`](assets/corpus/merge-group-composition.xml) consolida-os e o
[`merge-holding-composition.xml`](assets/corpus/merge-holding-composition.xml) consolida o grupo,
que é o encaixe. O `tests/composition.rs` afirma as duas falhas de fusão na direção que é
verdadeira, para que continuem a ser demonstrações e não pretensões.

## Pode ser refutado, e a refutação é uma declaração

O [`assets/corpus/refutation.xml`](assets/corpus/refutation.xml) é um documento válido que declara
dois contraexemplos: uma oferta sem quantum cujo preço contínuo não transporta prémio, e um
acoplamento entre os restos de duas camadas com a observação que o produziu. Ambos validam,
portanto o desacordo com o modelo pode ser declarado em vez de apenas discutido.

## O que isto não é

**Não é um desenho de armazenamento.** Os esquemas não declaram tabelas, chaves, índices nem
construções de versionamento, de propósito: uma base de dados sai de normalizar o modelo como deve
ser, e isso é trabalho de quem implementa. O `assets/sql/` contém de facto um DDL de Postgres, e
não é um contraexemplo — existe para VERIFICAR o modelo e não para o armazenar, e di-lo nas suas
primeiras cinco linhas. Nada ali está normalizado para escrita nem indexado para uma carga de
trabalho. Copiem-se as ideias, não a disposição.

**Não é uma API Rust ergonómica.** A biblioteca é os esquemas mais o que o gerador de código fizer
deles, e os tipos gerados leem-se como tipos gerados: sem construtores fluentes, sem auxiliares de
validação, sem construtores de conveniência. Uma interface agradável por cima destes é outro
trabalho e pertence à sua própria biblioteca. O que está aqui é uma tradução fiel do esquema e um
conjunto de testes que o obriga às suas próprias anotações.

**Não é uma notação de processos.** Não há fluxo de sequência, nem gateway, nem evento, nem token.
O BPMN 2.0 modela tudo isso e distribui esquemas públicos para o efeito. Reescrever qualquer coisa
disso dentro deste espaço de nomes seria bifurcá-lo.

## Estado do projeto

Inicial. Os esquemas estão suficientemente completos para se escreverem documentos reais contra
eles, e o conjunto de documentos é verificado de **três maneiras independentes**:

1. um **validador de XSD**, que é o que qualquer adotante vai correr;
2. os testes em Rust, que leem os documentos com os tipos gerados e afirmam os factos que cada um
   existe para demonstrar;
3. o `assets/sql/`, que exprime as regras entre elementos e entre documentos a que o XSD não
   chega, com o `examples/matrices.rs` a recalcular a mesma aritmética em `nalgebra` e a afirmar
   que as duas concordam.

Cada um foi provado capaz de falhar antes de qualquer passagem ser acreditada. O validador por
três defeitos deliberados que produziram três rejeições distintas; os testes em Rust por
perturbação contra uma cópia em memória; o SQL por quatro edições dentro de uma transação
revertida, que produziram seis violações porque duas das regras não são independentes uma da
outra.

O maior e o menor da biblioteca acompanham o `xs:schema/@version` do esquema, e o
`tests/namespace.rs` faz falhar a compilação se se afastarem. O que **não** está decidido são os
URI dos espaços de nomes, que continuam a ser `https://example.invalid/…`. Ainda não existe
nenhum perfil de conformidade, por opção.

Leitura adicional: o [`docs/linear-algebra.pt.md`](docs/linear-algebra.pt.md) reconstrói o
modelo para quem queira as matrizes, em português europeu.

## Licença

Licenciado sob qualquer uma de

- Licença Apache, Versão 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- Licença MIT ([LICENSE-MIT](LICENSE-MIT))

à escolha de quem usa.

Salvo declaração expressa em contrário, qualquer contribuição submetida intencionalmente para
inclusão neste trabalho, tal como definido na licença Apache-2.0, será licenciada em regime duplo
como acima, sem quaisquer termos ou condições adicionais.
