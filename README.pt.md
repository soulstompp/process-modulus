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

O modelo parte de uma divisão. Uma empresa satisfaz procura que varia de forma suave com oferta
que chega em unidades inteiras: uma pessoa, um turno, um bloco reservado de equipamento, um
lançamento, uma ronda de financiamento. **A unidade inteira por que é preciso dividir é o
módulo**, e a divisão deixa sempre um resto.

Veja-se o caso à volta do qual o conjunto de documentos foi construído. Uma equipa de plataforma
de quatro pessoas a servir uma procura que corre entre 4,5 e 6,0, mais provavelmente 5,2. A falta
é de 1,2 pessoas, e esse 1,2 divide-se uma vez, de forma limpa:

```text
1 pessoa       uma unidade inteira, e UMA DECISÃO.   Contrate mais uma e move-se.
0,2 pessoas    o resíduo, e NÃO uma decisão.         Nenhum efetivo o remove.
```

As duas metades saem da mesma divisão, e é por isso que o nome aponta para a divisão e não para
aquilo que ela deixa. `Remainder` é como o esquema chama ao resultado; o módulo é o que faz com
que exista algum.

⛔ **E a distinção é estrutural, não é preciosismo.** *A gestão escolhe que amortecedor absorve o
resto e quem o suporta; a gestão não escolhe se ele existe* é uma frase verdadeira acerca do 0,2 e
falsa acerca do 1,2, porque o resto inteiro contém uma decisão. Juntando os dois, um modelo ou
lisonjeia a empresa, ao chamar lei da natureza a uma escolha de pessoal, ou acusa-a, ao exigir que
remova aquilo que nada remove.

## Modular é uma escolha, e é por isso que aqui nada é enumerado

A unidade não é dada. A mesma equipa modulada em pessoas e modulada em semanas de piquete são duas
leituras de uma empresa, ambas verdadeiras, com restos diferentes a cair sobre pessoas diferentes.
**Escolher a unidade é o ato de modelação.** Por isso o esquema não lista camadas: o que faz de
algo uma camada é o seu resto poder ser suportado independentemente do de todas as outras, o que é
um teste que se aplica e não uma lista que se recebe.

⭐ E é o mesmo ato a toda a altura. Uma entidade-mãe que funde as camadas de dois membros numa só
está a dividir por uma unidade mais grosseira, e deve a mesma prestação de contas sobre o que a
divisão deixou. É por isso que aqui uma consolidação é um documento que alguém assina e não uma
junção que alguém executa.

## O resíduo que ninguém comprou

Um resto é suportado de cinco maneiras. Quatro delas deixam para trás uma transação ou um cliente
que reparou. A quinta não: a capacidade absorvida pelas pessoas que fazem o trabalho, ao
trabalharem acima da sua classificação. Não se comprou nada, por isso nenhum instrumento o regista,
por isso é invisível a todos os sistemas que partem das transações.

É para isso que este esquema serve, e é por isso que *ninguém mediu isto* tem de ser algo que um
emissor **arquiva** e não uma célula que deixa em branco. ⭐ Uma vez arquivado assim, o tamanho do
resíduo pode mesmo assim ser apurado, a partir de números que o emissor teve de dar de qualquer
maneira, e aquilo que fica genuinamente por saber encolhe para algo muito mais preciso: não o
tamanho da diferença, mas como ela se dividiu entre as pessoas que a absorveram e os clientes que
foram embora em silêncio.

⭐ **A via mais rápida para entrar é essa camada, lida de ponta a ponta**, e há uma secção para
isso mais abaixo.

Isto é uma exigência real, e vale a pena dizer o preço à cabeça. Escrever contra este esquema
significa comprometer-se a dizer que espécie de branco é cada branco, a exprimir quantidades como
intervalos em vez de números únicos, e a nomear a autoridade por trás de cada valor emprestado a
outrem. Os conjuntos de dados que já existem tendem a não fazer nenhuma das três coisas, e é essa
migração que dá trabalho. O que se ganha é um documento que continua verdadeiro depois de
atravessar uma fronteira organizacional, que é o único sítio onde algo disto interessa.

## O que se escreve

- **Um esquema, não uma biblioteca.** O [`schema/`](schema/) é o artefacto, e validar um documento
  não precisa de Rust nem de qualquer dependência deste projeto.
- **Cinco géneros de documento, e quatro deles são assinados por outrem que não a entidade.** Um
  arquivo, uma resposta de cobertura, uma execução promovida, uma dependência entre arquivos e uma
  consolidação. Uma afirmação *sobre* um arquivo não pode viver dentro do arquivo que julga.
- **Ausência tipificada, e alcança também as listas.** Um branco diz que espécie de branco é:
  `none`, `unmeasured` ou `notApplicable`, e uma posição que alguma identidade calcula transporta o
  nome dessa identidade. Por isso uma pilha sem acoplamentos declarados diz se alguém foi
  verificar, porque *estas camadas foram testadas e são independentes* e *ninguém verificou* são
  afirmações opostas que uma lista opcional vazia escreve da mesma maneira.
- **Afirmações de três pontos.** Todas as quantidades são um `low`, um `mostLikely` e um `high` com
  a sua proveniência e data. Não há nenhum tipo numérico simples em todo o modelo.
- **Os valores emprestados trazem a sua autoridade.** Aquilo que este modelo não possui viaja como
  `BorrowedTerm { taxonomy, value }` com a taxonomia obrigatória, para que um valor chegue com a
  autoridade que o define em vez de como um código solto.
- **Os regimes separam-se em eixos distintos.** Jurisdição, referencial e a autoridade que
  codifica o referencial são três perguntas, e uma única enumeração que as misture não responde a
  nenhuma.
- **Uma biblioteca Rust gerada.** Cada tipo e cada comentário de documentação vem dos esquemas,
  por isso o `cargo doc` mostra as anotações do próprio esquema.

## O que se ganha com isto

**Os amortecedores são emprestados e os detentores são nossos.** Os amortecedores são os de Hopp
e Spearman, fechados em três no *Factory Physics*, e este modelo adota-os como estão publicados em
vez de acrescentar um quarto. O que acrescenta é o eixo separado nomeado acima: `booked`,
`counterparty`, `customer`, `unrealised` e `people`.

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

* Os dois esquemas enunciam em prosa regras a que validador nenhum chega, porque o XSD 1.0 não
  tem `xs:assert` e não consegue comparar entre elementos. Quase todas estão marcadas com
  `NOT REACHABLE BY A VALIDATOR` na anotação que as enuncia, de forma que um leitor consiga
  distinguir uma regra vinculativa de uma não verificada. O
  [`conformance/README.pt.md`](conformance/README.pt.md) lista-as, nomeia a consulta que corre
  cada uma das que correm, e diz o que um implementador continua a dever.

* Nenhuma das duas direções da biblioteca é validação, e um único caso concreto cobre as duas. O
  `Operation` é uma sequência com uma escolha repetida lá dentro, que o gerador de código achata
  num único `Vec`, pelo que o `label` deixa de ser um campo singular obrigatório do ponto de vista
  do `rustc`. O XSD continua a impô-lo. A ler, os tipos aceitam um documento que o validador
  recusa; a escrever, a biblioteca emite uma operação sem `label` e reporta sucesso. O
  `tests/roundtrip.rs` obriga todos os documentos daqui a sobreviverem à escrita e à releitura, o
  que é uma afirmação mais fraca do que serem válidos. Valide-se com um validador de XSD.

* Ainda não é distribuído nenhum perfil de conformidade. Um perfil deve seguir um adotante real em
  vez de o preceder, e o raciocínio está em `conformance/`.

* Os URI dos espaços de nomes ainda são marcadores de posição. Mais nada no repositório é.

## Uma camada, lida de ponta a ponta

O [`assets/corpus/README.md`](assets/corpus/README.md) percorre a camada `labour` do
[`enterprise-contract.xml`](assets/corpus/enterprise-contract.xml) elemento a elemento: o que
viaja ao lado de um intervalo e porquê, as duas origens que nunca podem ser fundidas, as duas
ausências que um recetor também não pode fundir, e porque é que o tamanho do resto é calculável
enquanto a quota é a única coisa que nenhum instrumento alcança.

## Onde vive o resto do argumento

Cada linha abaixo é a primeira linha do próprio documento. O documento é onde ela é autoritativa, e
esta tabela é uma porta de entrada e não uma segunda cópia.

| | |
|---|---|
| [`schema/`](schema/) | o próprio artefacto, e os cinco documentos que permite a qualquer um escrever |
| [`assets/`](assets/) | a prova, a maquinaria que a lê, e o que é gerado a partir das duas |
| [`conformance/`](conformance/) | o que um perfil pode estreitar, e que regras nenhum validador alcança |
| [`src/proofs/`](src/proofs/) | As equações que este modelo enuncia, cada uma mostrada válida por um programa que o `cargo test` corre. |
| [`examples/`](examples/) | Os exemplos, e a pergunta que cada um põe ao modelo |

⭐ Nada do que está acima é repetido aqui, de propósito. Um documento que tivesse de ser resumido
no documento que o contém passaria a ser resumido duas vezes assim que alguém o alterasse uma, e as
duas cópias ficariam em desacordo sem que nada o pudesse notar.

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
psql -d process_modulus_proof -f assets/ddl/schema.ddl \
                              -f assets/sql/ingest.sql \
                              -f assets/sql/rules.sql
```

O Postgres lê o próprio conjunto de documentos — sem Rust, sem extensões, sem superutilizador.
Ver [`assets/sqlc/README.pt.md`](assets/sqlc/README.pt.md), que é o documento onde as regras
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
| `ConstraintOrigin` | com quem é preciso falar para alterar alguma coisa: `intrinsic` (ninguém), `contractual` (a contraparte), `policy` (quem declara, unilateralmente). É perguntado duas vezes, sobre duas coisas diferentes: o tamanho de uma unidade, e quantas unidades se detêm |
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
nova não exige alteração ao esquema. É a mesma frase que decide quando duas declarações
sustentam **uma** só camada — ver [uma consolidação é uma
declaração](#uma-consolidação-é-uma-declaração-e-quem-compõe-assina-a). A pilha não tem ordem pela mesma razão: uma ordenação entre
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
modelo lê-se como *aquilo que ninguém sabe* — o `narrowsWhen` diz o que o estreitaria — ao passo
que um intervalo que seja variação genuína de semana para semana não estreita por se medir com
mais cuidado. As duas coisas não são distinguidas, e dizê-lo é mais útil do que fingir que a
pergunta não se põe.

**Apontar para a sua notação de processo é opcional. Dizer se o fez não é.** A maioria das
declarações não nomeia operação nenhuma, e uma declaração que não nomeie nenhuma nada diz sobre
BPMN. Mas uma operação que seja declarada tem de dizer onde fica numa notação de processo, ou dar
a razão tipificada para não nomear nenhuma: `none` quando alguém procurou e ela não está em
notação nenhuma, `unmeasured` quando existe uma notação e ninguém a localizou lá dentro,
`notApplicable` quando não há notação para onde apontar. Eram um só silêncio até o elemento passar
a ser obrigatório, e são a diferença entre um cruzamento que ainda ninguém fez e um cruzamento que
não há que fazer — que é exatamente o que precisa de saber quem recebe e decide se os dois
documentos podem ser postos lado a lado. ⭐ O cruzamento em si não custa nada ao outro documento:
é nomeado por posição, portanto não se acrescenta campo nenhum ao seu BPMN e nenhuma ferramenta
que o leia tem de mudar.

## Como se articula com as normas existentes

O modelo nomeia o vocabulário dos outros em vez de o reescrever. Um conjunto de valores reescrito é
uma bifurcação, e uma bifurcação afasta-se sem que nada aqui o consiga notar.

| emprestado de | o quê, e como se liga |
|---|---|
| BPMN 2.0 | sequência, gateways e eventos. O `ForeignId` aponta para a mesma operação num modelo BPMN, portanto uma notação de processo e este modelo viajam juntos, e a travessia é desenhada em vez de descrita: [abaixo](#a-travessia-é-desenhada-e-cada-frase-nela-diz-o-que-a-afirma) |
| *Factory Physics* (Hopp e Spearman) | o conjunto de amortecedores de existências, capacidade e tempo, adotado fechado e como está publicado |
| ISO 286 | as três classes de ajustamento — `clearance`, `transition` e `interference` — no sentido mecânico, adotadas fechadas e como estão publicadas |
| normativos contabilísticos | todas as bases de mensuração exceto `nameplate`, que descreve capacidade comprometida e não valor, e por isso não tem definição normativa que citar |

Aquilo por que este modelo responde é a lista curta: `Remainder`, `Holder` e `HolderKind`,
`Divisibility` e `ConstraintOrigin`, as três margens, `Layer` e `Coupling`, `Induction`, `Claim`,
`Absence`, `Provenance`, e `nameplate`.

## A travessia é desenhada, e cada frase nela diz o que a afirma

O `ForeignId` aponta *para* um modelo BPMN. Este repositório também percorre o caminho
inverso: representa cada declaração **como** um documento BPMN, para que quem modela processos
possa pôr as duas notações lado a lado em vez de aceitar por confiança a descrição de uma delas.

```bash
cargo run --example diagramming   # um .bpmn por declaração, para assets/bpmn/filings/
cargo run --example graphs        # os grafos do próprio modelo, como os lane sets de uma pool
cargo run --example rendering     # o assets/svg/ a partir do assets/bpmn/, sem ler modelo nenhum
cargo run --example compositions  # o DAG de composição, para assets/dag/edges.sql, sem base de dados
```

O que uma tradução correta deve está escrito e não pressuposto.
O [`assets/sqlc/diagrams/roster.sqlc`](assets/sqlc/diagrams/roster.sqlc) carrega uma lei por
espécie de elemento, e cada lei nomeia a relação que fornece a contagem com que tem de bater
certo. O [`assets/sqlc/diagrams/domain_objects.sqlc`](assets/sqlc/diagrams/domain_objects.sqlc)
diz, para cada tabela do modelo, em que elemento BPMN ela é representada ou a razão tipada para
não haver nenhum, e um mapeamento que perde alguma coisa diz como: `demoted` quer dizer que uma
pessoa ainda consegue ler o facto e uma ferramenta já não o consegue resolver, `absent` quer
dizer que ele não está no artefacto sob forma nenhuma.

⛔ **Um desenho é acreditado de uma maneira que uma tabela não é.** Uma tabela errada é
reconferida; um diagrama errado é citado numa apresentação. Por isso cada frase que um documento
emitido carrega nomeia a relação que a afirma, no ficheiro e na página desenhada, e o
`examples/diagramming/main.rs` volta a lê-las do artefacto depois de o escrever: uma frase sem
origem, uma origem que não é uma relação desta árvore, e uma origem que o emissor nunca
consultou fazem cada uma delas falhar a execução.

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
| `Fusion` | que camadas declaradas são **uma** só camada, e porquê. **Fundir só o que é fungível**: se uma unidade de oferta de uma parte pode servir a procura da outra, então não suportam os seus restos independentemente e são uma camada. Se não pode, são duas, e um `Coupling` é onde vai parar qualquer interação observada. Esse juízo é de quem compõe, o `observed` é onde o defende, e é a afirmação com que um leitor tem direito a discordar. ⚠️ O teste é entre duas equipas *diferentes* por construção, portanto «servem clientes diferentes» não lhe responde — o que o decide é se as pessoas de uma equipa conseguem pegar no trabalho da outra. O [`merge-group-composition.xml`](assets/corpus/merge-group-composition.xml) responde-lhe com prova e mostra a regra a recusar no mesmo fôlego: duas equipas de entrega fundem-se porque qualquer dos lados pegou no trabalho acumulado do outro dentro de uma semana, onze vezes este ano, enquanto o piquete fica camada à parte porque o desfasamento de oito horas o torna não fungível. Uma camada sem fusão nenhuma é o terceiro caso — uma que quem compõe **originou**, como uma escala de serviço ao nível do grupo |
| `Part` | uma camada declarada a entrar, com o `factor` que a põe na unidade da camada composta. `4,4 GPU + 545 GPU-hora` não é uma soma, e quem compõe e multiplica por 720 em silêncio fez exatamente a aritmética não auditada que este documento existe para expor. Um fator é ele próprio uma afirmação de três pontos, porque um mês são `[672, 720, 744]` horas |
| `Elimination` | o que foi retirado, e porque é que a figura fundida **não** é a soma das suas partes. Quando um membro encomenda trabalho a outro, ambos o declaram como procura própria, honestamente, e a procura do grupo é a soma menos a encomenda. Nomeia qual das três quantidades atinge, já que um ajustamento que não o diga é aplicado ao número que o leitor tiver por acaso na mão |

**Se alguém procurou duplicações é ele próprio um facto declarado.** Uma lista vazia diz
«as partes foram verificadas e são disjuntas» e «ninguém verificou» nos mesmos bytes, e as duas devem
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
ser, e isso é trabalho de quem implementa. O `assets/ddl/schema.ddl` é um DDL de Postgres, e não é
um contraexemplo. Segue o esquema XML tão de perto quanto os dois formalismos permitem, para que o
que ali se prova seja provado sobre o modelo e não sobre uma tradução. É sólido e eficiente, e
existe para VERIFICAR o modelo e não para servir uma aplicação. Uma instalação real vai querer
índices, desnormalização e um caminho de escrita sobre o qual isto não tem opinião.

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
   chega, com o `examples/matrices/main.rs` a recalcular a mesma aritmética em `nalgebra` e a afirmar
   que as duas concordam.

Cada um foi provado capaz de falhar antes de qualquer passagem ser acreditada. O validador por
três defeitos deliberados que produziram três rejeições distintas; os testes em Rust por
perturbação contra uma cópia em memória; o SQL por edições deliberadas dentro de uma transação
revertida, cada uma apontada a uma regra diferente, que produzem MAIS violações do que edições
porque as regras não são independentes umas das outras. ⭐ Volte-se a correr em vez de confiar
nesta frase: perturbe-se um sinal, uma quota de detentor, uma procura composta e um valor nominal
com quantum dentro de `BEGIN; ... ROLLBACK;`, e leia-se o `assets/sql/reports/violations.sql`. A
contagem muda à medida que se acrescentam regras; o achado não.

O maior e o menor da biblioteca acompanham o `xs:schema/@version` do esquema, e o
`tests/namespace.rs` faz falhar a compilação se se afastarem. O que **não** está decidido são os
URI dos espaços de nomes, que continuam a ser `https://example.invalid/…`. Ainda não existe
nenhum perfil de conformidade, por opção.

Leitura adicional: o modelo reconstruído para quem queira as matrizes está nos exemplos que o
calculam, e não numa nota ao lado deles. O [`examples/README.pt.md`](examples/README.pt.md) tem
uma pasta por programa, cada uma com o programa e o cabeçalho que defende o seu caso, mais uma
tabela com a pergunta a que cada um responde; nada precisa de ser compilado para o ler. O
`cargo doc --examples --open` compõe os mesmos cabeçalhos, e o
[`examples/matrices/`](examples/matrices/) é o que carrega a aritmética, com o `nalgebra` de um
lado e o `assets/sql/` do outro, e a concordância é afirmada em cada execução.
⭐ Cada cabeçalho existe nas duas línguas, lado a lado na mesma pasta, e o
`tests/examples.rs` falha se um programa argumentar o seu caso só numa delas.

## Licença

Licenciado sob qualquer uma de

- Licença Apache, Versão 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- Licença MIT ([LICENSE-MIT](LICENSE-MIT))

à escolha de quem usa.

Salvo declaração expressa em contrário, qualquer contribuição submetida intencionalmente para
inclusão neste trabalho, tal como definido na licença Apache-2.0, será licenciada em regime duplo
como acima, sem quaisquer termos ou condições adicionais.
