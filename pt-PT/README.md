# process-modulus

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`README.md`](../README.md).

Numa empresa, quem decide quase nunca é quem faz o trabalho. A gestão de topo não desce ao terreno,
lê o que as chefias de equipa assumiram e o que lhe reportam, e decide a partir daí; as chefias,
essas, tomam decisões que caem diretamente em cima de quem está sob pressão; e a carga que essas
pessoas levam, a gestão nunca a vê de frente, conhece-a apenas de forma indireta, pelo que sobra das
contas que as chefias já lhe entregaram. São ciclos dentro de ciclos, que voltam a encaixar-se uns
nos outros sempre que uma empresa entra num grupo e o grupo numa holding.

O process-modulus é um esquema para pôr isto por escrito. Cada camada de uma empresa, seja uma
equipa, um parque de máquinas ou uma linha de turnos, declara a oferta de que dispõe e a procura que
lhe chega, e uma oferta que só se compra em unidades inteiras, uma pessoa de cada vez ou um bloco
reservado de cada vez, nunca acerta em cheio numa procura que varia sem saltos, pelo que fica sempre
alguma coisa entre as duas: o resto. Esse resto existe quer alguém o registe quer não, e o que a
gestão escolhe é apenas onde ele vai parar e se fica à vista.

A equipa de plataforma de uma das declarações de exemplo tem 4 pessoas atribuídas, e o trabalho que
lhe chega pede entre 4,5 e 6,0, sendo 5,2 o mais provável. Faltam-lhe portanto 1,2 pessoas no caso
mais provável, só que essa falta não é toda da mesma natureza: uma pessoa inteira é uma decisão de
quadro de pessoal, que uma contratação resolve, ao passo que os 0,2 que sobram nenhuma contratação
os tira, porque ninguém contrata dois décimos de alguém, e quem contratasse duas pessoas para cobrir
a falta ficava com 0,8 de uma pessoa sem trabalho à espera. Quem leva a falta às costas são as
próprias pessoas da equipa, a trabalhar acima do que lhes cabe, e o trabalho que fica em fila até
deixar de valer a pena; quanto vai para cada lado ninguém mediu, e a declaração di-lo tal e qual,
`unmeasured`, em vez de inventar uma divisão para que as contas fechem.

Há em tudo isto dois momentos que convém não confundir: o que se planeou, ou seja, a capacidade
nominal com que alguém se comprometeu, e o que de facto aconteceu, que fica no registo irregular do
que foi consumido. E em cada um deles cabem duas medidas: a quantidade, que vem sempre em unidades
inteiras, e o tempo, que é o período em que a oferta corre e a janela em que está realmente ativa.

## Validar um documento

Cada documento valida-se contra o esquema a que pertence, uma declaração contra o esquema base e uma
cobertura contra o esquema das afirmações:

```sh
xmllint --noout --schema schema/process-modulus.xsd assets/corpus/enterprise-contract.xml
xmllint --noout --schema schema/assertion.xsd       assets/corpus/coverage-us-gaap.xml
```

O XSD 1.0 garante a forma do documento, mas não chega às contas, como a de as quotas somarem o
resto, a de a capacidade nominal ser um múltiplo inteiro da unidade em que a oferta vem ou a de um
ajustamento condizer com os intervalos que compara; essas regras são consultas em SQL, e ficam mais
abaixo.

## O que uma empresa declara

Uma declaração descreve uma pilha de camadas, cada qual com a sua procura, a sua oferta e o resto
que fica entre as duas, e ainda as operações que consomem essas camadas.

### O planeado e o realizado

A oferta de uma camada tem duas faces. A capacidade nominal é a do compromisso: 4 pessoas na equipa
de plataforma, 8 GPU num bloco reservado, 168 horas de engenharia por semana num balcão de suporte
que nunca fecha. A face irregular é a do que se consumiu de facto, e é aí que as camadas se afastam
umas das outras, porque no bloco reservado se consumiram 4,4 das 8 GPU, ao passo que na equipa de
plataforma ninguém regista as horas trabalhadas para lá do quadro, pelo que o consumo fica
`unmeasured`, e tudo o que o documento sabe dizer é que a procura, com 5,2 pessoas como valor mais
provável, passa a capacidade de 4.

### Quanto e quando

Uma oferta chega em unidades inteiras, e a dimensão de cada unidade, o quantum, tem sempre uma
origem declarada: uma pessoa é uma pessoa por natureza, o bloco de 8 GPU é o que o contrato de
reserva fixa, uma vaga de lançamento por trimestre é o que a própria capacidade permite. É o quantum
que parte o resto em duas coisas diferentes, as unidades inteiras, que alguém pode decidir comprar
ou não, e o resíduo, que decisão nenhuma remove.

Quanto ao tempo, uma oferta medida por período corre nesse período, e a janela é a parte dele em
que está de facto ativa. A linha de turnos que dois membros de um grupo partilham compromete-se com
10 turnos por semana e só está ativa 5 dias em cada semana; o balcão de suporte, contratado para
estar aberto a toda a hora, é o único caso em que a janela ocupa o período inteiro, uma semana em
cada semana, e o documento declara-o como a cláusula contratual que é, assinada por alguém que a
pode renegociar. Já uma existência, como pessoas ou GPU, não tem período nenhum, pelo que a sua
janela é `notApplicable`. E quando um grupo compõe os seus membros, as janelas passam para cima tal
como estão, nunca somadas.

### Quem suporta o resto

Um resto cai sempre em cima de alguém, e o esquema distingue cinco possibilidades: fica escriturado
dentro da entidade (`booked`), passa para os livros de outra entidade ao abrigo de um acordo
(`counterparty`), recai sobre um cliente que recebe um serviço pior (`customer`), é absorvido pelas
pessoas (`people`) ou é procura que nunca chegou a ser servida (`unrealised`). Só a primeira é uma
transação dentro da entidade, e é nessa assimetria que está o essencial, porque um cliente que passa
do seu limite pode ser faturado, e um banco cobra juros sobre um descoberto, mas uma pessoa que
trabalha acima do que lhe cabe não passa fatura a ninguém, de modo que o mesmo excesso, que noutros
sítios deixa rasto, ali não deixa rasto nenhum. Contrate-se um prestador de serviços para fazer esse
trabalho e o excesso passa a `counterparty`, com preço e fatura à vista; a invisibilidade, essa, vem
da relação e não do trabalho.

Na equipa de plataforma declaram-se dois que o suportam, as pessoas e a procura que ficou por
servir, ambos com a quota `unmeasured`, e é a divisão entre os dois que importa: saber qual das
partes cresceu exigiria um instrumento que ninguém ali tem.

### Nenhum campo fica simplesmente em branco

Onde um documento não tem valor, diz porquê, e há só três razões possíveis. `none` quer dizer que
alguém foi ver e não há nada, e quem recebe o documento pode contar com isso; `unmeasured` quer
dizer que ali não existe instrumento que o meça, e não afirma nada sobre se é muito ou pouco;
`notApplicable` quer dizer que a pergunta nem se põe, e quem a tratar como lacuna acaba por acusar
uma falha que não existe. Um vazio nunca é um zero: a folga de existências da equipa de plataforma
está declarada como 0 pessoas, porque a capacidade que hoje não se usa perde-se e não se guarda para
a semana seguinte, e isso é uma afirmação, ao passo que o consumo da mesma equipa está `unmeasured`,
e isso é uma lacuna dita com honestidade.

Um valor que se calcula a partir de outros também não fica em branco, declara-se como derivação,
com o nome da identidade que o calcula, e é assim que o resto da equipa de plataforma remete para a
sua magnitude, que quem recebe calcula a partir da procura e da capacidade nominal.

### Documentos assinados por outros

Há factos sobre uma empresa que a própria empresa não pode atestar, e para esses existe um segundo
esquema, o das afirmações. Uma testemunha, um contabilista, por exemplo, responde a um corpus de
perguntas segundo um normativo, e essas respostas formam um documento de cobertura que se envia sem
ter de correr o código de ninguém. Quando duas declarações dependem uma da outra, quem o declara é
um terceiro que leu as duas, como quem consolida as contas de um grupo, uma vez que cada empresa só
atesta a sua própria declaração e não vê a pilha da outra. E uma execução que um relatório cita
segue como registo promovido a prova, datado e fechado, nunca como o registo de trabalho que quem a
correu vai guardando na sua máquina.

### Ao lado do modelo de processos

O process-modulus não descreve a sequência de um processo, nem as decisões nem os eventos que o
fazem avançar, e não vem substituir o modelo de processos que a empresa já tem. Cada operação aponta
para esse modelo pelo identificador da tarefa correspondente, ou declara `none` quando a tarefa fica
abaixo do grão a que o modelo está desenhado, e o que acrescenta é justamente o que lá não está: o
que cada operação consome e o que compromete noutra camada. Fechar um contrato empresarial consome
trabalho da equipa de plataforma, que ninguém regista contra o contrato, e compromete um ou dois
lançamentos na camada de capacidade, por decisão do responsável comercial que assina a proposta; é
ali que se vê uma camada a decidir e outra a pagar, sem que conta alguma registe a passagem.

### Regimes

Cada declaração diz sob que regime reporta, isto é, a jurisdição, o normativo contabilístico e o
plano de contas, cada um como termo emprestado, com a taxonomia que o define e o valor que dela se
tira. O esquema não reescreve vocabulários alheios: os amortecedores são os três da *Factory
Physics*, existências, capacidade e tempo, os ajustamentos vêm da ISO 286, e o normativo vem da
autoridade que o publica. Os Estados Unidos não têm plano de contas nacional, pelo que a empresa
americana do exemplo é a autoridade da sua própria lista de contas; Portugal tem o SNC, e publica
duas listas de códigos para o mesmo normativo, a do AnexoASNC da IES e a do SAF-T, que não
coincidem, porque a do SAF-T é menos detalhada e um código seu não volta a dar um só valor da outra.
O [corpus](assets/corpus/README.md) mostra os regimes um a um.

## A matemática, em SQL

O PostgreSQL lê as declarações tal como estão escritas, sem extensões e sem privilégios especiais,
e cada regra é uma consulta. A partir da raiz do repositório, carrega-se tudo assim, e o `rules.sql`
corre as regras no fim, sendo uma tabela vazia o bom resultado:

```sh
createdb process_modulus
psql -d process_modulus -f assets/ddl/schema.ddl \
                        -f assets/sql/ingest.sql \
                        -f assets/sql/rules.sql
```

A primeira pergunta é a do resto, quanto falta ou sobra a cada camada no pior caso, no mais provável
e no melhor, e com que ajustamento, sabendo que o pior caso junta a menor oferta à maior procura:

```sql
SELECT layer AS camada, d_unit AS unidade,
       n_low  - d_high AS no_pior_caso,
       n_mode - d_mode AS no_mais_provável,
       n_high - d_low  AS no_melhor_caso,
       CASE WHEN n_low  - d_high >= 0 THEN 'clearance'
            WHEN n_high - d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS ajustamento
FROM (
    SELECT * FROM layers_figures
) f
WHERE filing = 'enterprise-contract'
  AND d_low IS NOT NULL
  AND n_low IS NOT NULL;
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/1-what-the-division-leaves.sql
```

Na linha `labour`, os três valores ficam abaixo de zero e o ajustamento é `interference`, o que quer
dizer que falta gente à equipa de plataforma onde quer que a procura caia, e o caso mais provável
traz os 1,2 de que se falou lá em cima.

No fim do percurso está a estrutura inteira, cada regra do rol com as linhas que examinou e as que a
quebraram, e cada classe de cada classificação com o lugar onde fica:

```sql
SELECT r.rule                             AS regra,
       count(c.rule)                      AS examinadas,
       count(*) FILTER (WHERE c.violates) AS quebradas
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT * FROM checks_all
) c ON c.rule = r.rule
GROUP BY r.rule;

SELECT relation AS relação, class AS classe, standing AS situação, reason AS razão
FROM (
    SELECT * FROM epistemics_class_domain
) d;
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/12-every-rule.sql
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/12b-every-class.sql
```

Todas as regras examinam linhas e nenhuma sai quebrada, e cada classe tem o seu lugar, sendo que a
classe onde nada cai traz escrita ao lado a razão por que fica em aberto. O percurso completo, uma
consulta de cada vez, desde o resto de uma camada até à estrutura inteira, está em
[`assets/sqlc/`](assets/sqlc/README.md).

## As páginas

- [`schema/`](schema/): o artefacto em si e os cinco documentos que qualquer pessoa pode escrever com ele
- [`assets/`](assets/): os documentos e as consultas que os leem, mais o que se gera a partir de uns e de outros
- [`conformance/`](conformance/): o que um perfil pode estreitar e as regras a que nenhum validador chega
- [`examples/`](examples/): os exemplos e a pergunta que cada um faz ao modelo

## Licença

Licenciado, à escolha de quem o usa, sob uma destas duas licenças:

- Licença Apache, versão 2.0 ([LICENSE-APACHE](../LICENSE-APACHE))
- Licença MIT ([LICENSE-MIT](../LICENSE-MIT))

Salvo declaração expressa em contrário, qualquer contribuição submetida intencionalmente para
inclusão neste trabalho, tal como definida na licença Apache 2.0, fica licenciada nos mesmos dois
regimes, sem quaisquer termos ou condições adicionais.
