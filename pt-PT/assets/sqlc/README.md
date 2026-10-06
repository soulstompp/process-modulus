# `assets/sqlc/`: as consultas, e o percurso que vai do resto de uma camada à estrutura inteira

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`README.md`](../../../assets/sqlc/README.md).

Cada regra que o esquema enuncia é aqui uma consulta, e cada consulta vive num ficheiro `.sqlc` que
nomeia uma só relação; quando precisa de outra, compõe-na pelo caminho do ficheiro em vez de a
escrever de novo, de modo que o que uma relação diz se diz num sítio só. O `cargo sqlc compose`
junta tudo e escreve em `assets/sql/` cada consulta composta por inteiro, pronta a correr no `psql`.
Esta página lê-as uma de cada vez, desde o resto de uma camada até à estrutura inteira, com todas as
regras e todas as classes, e em cada passo quem lê pode parar com uma resposta inteira na mão.

## Pôr os documentos numa base de dados

O PostgreSQL lê os documentos tal como estão escritos, sem extensões nem privilégios especiais: o
`schema.ddl` cria as tabelas, o `ingest.sql` pega em cada documento do corpus e de
`assets/fixtures/`, que o próprio `psql` lê do disco, e reparte-o pelas tabelas, e o `rules.sql`
corre as regras no fim, sendo uma tabela de violações vazia o bom resultado. A partir da raiz do
repositório:

```sh
createdb process_modulus
psql -d process_modulus -f assets/ddl/schema.ddl \
                        -f assets/sql/ingest.sql \
                        -f assets/sql/rules.sql
```

## O percurso, passo a passo

Os passos vão pela ordem em que as contas assentam umas nas outras: o resto e o seu ajustamento, as
unidades inteiras e o resíduo, as quotas e as folgas, a composição de uma entidade-mãe e o que ela
retira, as conversões entre unidades, as janelas, a contagem, o que se guarda e o que fica de fora,
os grafos que as declarações formam e, por fim, a estrutura inteira. Cada passo mostra a pergunta
com que o seu ficheiro termina, depois das relações que compõe, e a linha que corre esse ficheiro
sobre a base carregada; os ficheiros em português fazem as mesmas perguntas que os ingleses, sobre
as mesmas relações, só que com os nomes das colunas em português.

### 1. O que a divisão deixa

A primeira pergunta é a de quanto falta, ou sobra, a cada camada da declaração
`enterprise-contract`, e se lhe falta onde quer que a procura caia. O resto lê-se em três cantos,
cada um com o seu nome: o pior junta a menor oferta à maior procura, o mais provável junta os dois
valores mais prováveis e o melhor junta a maior oferta à menor procura; o ajustamento diz de que
lado do zero ficam os três.

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

Na linha `labour` os três cantos ficam abaixo de zero e o ajustamento é `interference`, o que quer
dizer que falta gente à equipa de plataforma onde quer que a procura caia, 1,2 pessoas no caso mais
provável; a `capability` está na mesma situação, ao passo que a `compute` e o `support-cover`, com
os três cantos acima de zero, são `clearance`. Uma camada cujos cantos ficassem um de cada lado
seria `transition`, e tanto lhe podia faltar como sobrar, conforme o sítio onde a procura caísse. O
que o resto não diz é que parte da falta se resolve com uma decisão, e é isso que o passo seguinte
vai buscar à unidade em que a oferta chega.

### 2. Unidades inteiras e resíduo

Uma oferta chega em unidades inteiras, e a pergunta agora é quantas cada camada compromete, quantas
a procura lhe pede e o que sobra da procura que nenhuma unidade inteira cobre, que é o resíduo.

```sql
SELECT layer AS camada, quantum_mode AS unidade_inteira,
       round(n_mode / quantum_mode, 2) AS unidades_comprometidas,
       floor(d_mode / quantum_mode)    AS unidades_pedidas,
       mod(d_low,  quantum_mode)       AS resíduo_na_procura_mínima,
       mod(d_mode, quantum_mode)       AS resíduo_na_procura_mais_provável,
       mod(d_high, quantum_mode)       AS resíduo_na_procura_máxima
FROM (
    SELECT * FROM layers_lumpy
) l
WHERE filing = 'enterprise-contract'
  AND d_low IS NOT NULL;
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/2-whole-units-and-the-residue.sql
```

A `unidade_inteira` é o quantum, o tamanho de uma unidade tal como a declaração o fixa. Na `labour`
é uma pessoa, e o resíduo mais provável é de 0,2: as pessoas inteiras que faltam resolvem-se com uma
contratação, que é uma decisão de quadro de pessoal, mas esses 0,2 nenhuma contratação os tira. Os
três resíduos seguem os cantos da procura, pelo que na `labour` o da procura mínima vale 0,5 e o da
procura máxima vale 0,0, porque seis pessoas certas são só pessoas inteiras. Na `capability` não há
resíduo nenhum, uma vez que se pedem lançamentos inteiros, e na `compute` e no `support-cover` a
procura nem chega a encher uma unidade, pelo que o resíduo é a procura toda. Até aqui tudo é o planeado; o passo
seguinte põe ao lado do compromisso o que de facto aconteceu.

### 3. O que aconteceu

O planeado é a capacidade nominal, e o que aconteceu fica no registo irregular do que se consumiu; a
pergunta é o que cada camada comprometeu, ao lado do que consumiu.

```sql
SELECT layer AS camada, n_mode AS comprometido,
       draw_low  AS consumo_mínimo,
       draw_mode AS consumo_mais_provável,
       draw_high AS consumo_máximo
FROM (
    SELECT * FROM layers_drawn
) d
WHERE filing = 'enterprise-contract';
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/3-what-happened.sql
```

A `labour` não tem aqui linha, e essa ausência já é a resposta: ninguém regista as horas que a
equipa de plataforma trabalha para lá do quadro, o consumo dela está declarado `unmeasured`, e uma
camada sem consumo declarado não aparece. Nas outras o consumo fica dentro do compromisso, e o
consumo não é a procura: a `capability`, cuja procura, como se viu no passo 1, passava a capacidade,
consumiu exatamente o que tinha comprometido. Uma falta que o consumo não cobre cai em cima de
alguém, e o passo seguinte pergunta em cima de quem.

### 4. Quem suporta a falta

Um resto cai sempre em cima de alguém, e cada um que o suporta declara a sua quota; a pergunta é se
as quotas declaradas dão o resto.

```sql
SELECT r.layer AS camada,
       r.m_low  AS resto_mínimo,
       r.m_mode AS resto_mais_provável,
       r.m_high AS resto_máximo,
       h.shares_low  AS quotas_mínimas,
       h.shares_mode AS quotas_mais_prováveis,
       h.shares_high AS quotas_máximas,
       h.unstated    AS por_declarar
FROM      (
    SELECT * FROM layers_remainder
) r
LEFT JOIN (
    SELECT * FROM entries_holder_totals
) h USING (filing, layer)
WHERE r.filing = 'enterprise-contract';
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/4-who-carries-the-gap.sql
```

O resto aparece sem sinal, nos seus três cantos, ao lado da soma das quotas e de `por_declarar`, que
conta as quotas que ninguém declarou. Na `capability`, na `compute` e no `support-cover` todas as
quotas estão declaradas e a soma dá o resto, canto a canto. Na `labour` o resto vai de 0,5 a 2,0
pessoas e as quotas vêm em branco, porque os dois que o suportam, as pessoas da equipa e a procura
que ficou por servir, declararam ambos a quota `unmeasured`; o `por_declarar` conta os dois, e a
conta das quotas fica suspensa nessa camada, em vez de dar pela falta de uma coisa que ninguém
mediu. Uma quota diz quem suporta a falta, mas não se havia folga onde a pôr, e é para aí que vai o
passo seguinte.

### 5. A folga e o pior caso

No pior caso, com a maior procura contra a menor oferta, a pergunta é quanto a procura passa a
capacidade, se havia folga onde pôr esse excesso e quanto dele ficou por servir.

```sql
SELECT e.layer         AS camada,
       e.exposure      AS exposição,
       s.high          AS folga_de_capacidade,
       u.unserved_high AS por_servir_máximo
FROM      (
    SELECT * FROM layers_exposure_scope
) e
LEFT JOIN (
    SELECT * FROM entries_slacks
) s ON s.filing = e.filing AND s.layer = e.layer AND s.buffer = 'capacity'
LEFT JOIN (
    SELECT * FROM entries_unserved_totals
) u ON u.filing = e.filing AND u.layer = e.layer
WHERE e.filing = 'enterprise-contract';
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/5-the-slack-and-the-worst-case.sql
```

Só aparecem as camadas expostas, aquelas cuja maior procura passa a menor oferta, e a exposição é
esse excesso. Na `capability` a folga de capacidade está declarada vazia, e o máximo por servir
chega à exposição inteira: o que a capacidade não podia absorver está todo nomeado como procura que
ficou por servir. Na `labour` as duas colunas vêm em branco, uma vez que ninguém mediu a folga de
capacidade da equipa nem quanto da falta ficou por servir, e esse branco, ninguém o deve ler como um
zero. Até aqui tudo se passa dentro de uma declaração só; o passo seguinte sobe a quem compõe
várias.

### 6. A composição de uma entidade-mãe

Quando o grupo `merge-group-composition` compõe os seus dois membros, soma as partes de cada camada,
retira o que estaria contado duas vezes e declara o que fica; a pergunta é quanto dá cada uma dessas
três coisas, quantidade a quantidade, na `labour` e na `shift-line`.

```sql
SELECT f.composed_layer AS camada_composta, f.quantity AS quantidade,
       f.sum_low    AS soma_mínima,
       f.sum_mode   AS soma_mais_provável,
       f.sum_high   AS soma_máxima,
       e.low        AS retirado_mínimo,
       e.mode       AS retirado_mais_provável,
       e.high       AS retirado_máximo,
       f.filed_low  AS declarado_mínimo,
       f.filed_mode AS declarado_mais_provável,
       f.filed_high AS declarado_máximo
FROM      (
    SELECT * FROM composition_fused
) f
LEFT JOIN (
    SELECT * FROM eliminations_filed
) e USING (composition, composed_layer, quantity)
WHERE f.composition = 'merge-group-composition'
  AND f.composed_layer IN ('labour', 'shift-line');
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/6-a-parents-composition.sql
```

Nas duas camadas, o grupo retira em quantidades opostas. Na `labour` retira na procura e não toca na
capacidade nominal, uma vez que parte da procura de cada membro é trabalho do outro, contado nas
duas declarações, ao passo que as pessoas de um não são as pessoas do outro. Na `shift-line` é ao
contrário: retira na capacidade nominal e no consumo, porque os dois membros declaram a mesma linha,
uma máquina só, e deixa a procura inteira, porque cada membro pede o seu próprio trabalho. Uma regra
única de eliminação acertaria numa das camadas e falharia a outra, e é por isso que quem compõe
declara o que retira, quantidade a quantidade. Aqui as partes contam-se todas na mesma unidade, e o
passo seguinte mostra o que acontece quando não contam.

### 7. Conversões entre unidades

Na holding, a camada `compute` junta duas partes que não contam na mesma unidade, e a pergunta é com
que fator entra cada uma e que números dá depois de convertida.

```sql
SELECT p.part_layer  AS camada_da_parte,
       p.factor_low  AS fator_mínimo,
       p.factor_mode AS fator_mais_provável,
       p.factor_high AS fator_máximo,
       c.quantity    AS quantidade,
       c.low         AS mínimo,
       c.mode        AS mais_provável,
       c.high        AS máximo
FROM (
    SELECT * FROM composition_parts
) p
JOIN (
    SELECT * FROM composition_converted
) c ON c.composition = p.composition AND c.composed_layer = p.composed_layer
   AND c.part_filing = p.part_filing AND c.part_layer = p.part_layer
WHERE p.composition = 'merge-holding-composition'
  AND p.composed_layer = 'compute'
ORDER BY c.quantity, p.part_layer;
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/7-conversions-between-units.sql
```

A `compute-us` conta em `GPU` e entra com um fator em `GPU-hour per GPU` que vai de 672 a 744, as
horas de um mês, que mudam conforme o mês; uma conversão é ela própria incerta, e por isso o fator
declara-se como intervalo. A `compute-pt` já conta em `GPU-hour`, a unidade da camada composta, pelo
que não declara fator nenhum e as colunas do fator vêm em branco; um fator de 1 diria outra coisa,
que se fez uma conversão e que ela deu um para um, quando o que a parte diz é que nenhuma conversão
era precisa. Depois de convertidas, as duas partes ficam, quantidade a
quantidade, na mesma unidade, e só então se somam. Uma conversão muda a unidade de uma quantidade,
mas não diz em que parte do tempo a oferta está ativa, e é disso que trata o passo seguinte.

### 8. Janelas

A linha de turnos que os dois membros partilham compromete-se com 10 turnos por semana e está ativa
5 dias em cada semana; a pergunta é que janela leva essa linha em cada documento que a declara, os
dois membros e os dois níveis que a compõem.

```sql
SELECT filing      AS declaração,
       layer       AS camada,
       window_mode AS janela,
       window_unit AS unidade_da_janela,
       amount_unit AS unidade_da_quantidade
FROM (
    SELECT * FROM layers_windows
) w
WHERE layer IN ('shift-line', 'linha-partilhada')
  AND window_mode IS NOT NULL;
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/8-windows.sql
```

Em todas as linhas a janela é de 5 dias. O membro português declara a linha como `linha-partilhada`,
em `dias` e `turnos por semana`, o outro em `days` e `shifts per week`, e o grupo e a holding levam
a janela tal como a receberam, 5 dias, e nunca a soma das janelas das partes. Uma janela passa por
uma composição sem se somar, porque dizer em que dias a linha está ativa não é dizer quanto ela
produz. Até aqui os passos leram as camadas uma a uma, e o passo seguinte conta-as todas de uma vez.

### 9. Contar onde cai cada coisa

Cada resto do corpus cai numa das classes do ajustamento, e a pergunta é quantas camadas caem em
cada uma.

```sql
SELECT relation AS relação, class AS classe, subject AS o_que_se_conta, balls AS quantos
FROM (
    SELECT * FROM epistemics_classes
) c
WHERE relation = 'layers/remainder.sqlc'
ORDER BY ord;
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/9-counting-what-lands-where.sql
```

Há uma linha por classe, `clearance`, `transition` e `interference`, com o que se conta, camadas, e
quantas lá caem. O que importa é que nenhuma classe fica vazia: uma classe onde nada cai é uma
classe que documento nenhum exercita, e uma regra sobre ela nunca foi vista a trabalhar. O passo
12 faz esta pergunta a todas as classificações de uma vez. Contar camadas é contar o que as
declarações têm, e o passo seguinte conta o que uma entidade-mãe faz com o que as partes lhe trazem.

### 10. O que se guarda e o que fica de fora

Cada parte traz as suas quantidades, a procura, a capacidade nominal e as três folgas, e a
entidade-mãe declara as suas na camada composta; a pergunta é quantas das quantidades das partes têm
ao lado uma quantidade da mesma espécie na camada composta, e quantas ficam de fora.

```sql
SELECT count(*) FILTER (WHERE c.layer IS NULL)     AS não_compostas,
       count(*) FILTER (WHERE c.layer IS NOT NULL) AS postas_ao_lado,
       count(*)                                    AS todas_as_quantidades
FROM (
    SELECT * FROM composition_parts
) p
JOIN (
    SELECT * FROM layers_quantities
) q ON q.filing = p.part_filing AND q.layer = p.part_layer
LEFT JOIN (
    SELECT * FROM layers_quantities
) c ON c.filing = p.composition AND c.layer = p.composed_layer AND c.quantity = q.quantity;
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/10-what-is-kept.sql
```

A resposta é uma linha só, com três contagens: as quantidades das partes que ficam sem par na camada
composta, as que ficam ao lado de uma quantidade da mesma espécie, e todas. Uma quantidade sem
número declarado não entra na conta, porque não há nada para pôr ao lado. No corpus, fica de fora a
folga de tempo de `on-call`, uma das partes da `staff` da holding: as partes discordam, uma aguenta
a fila e a outra não, e a holding deixou a folga de tempo da `staff` `unmeasured` em vez de inventar
um número composto. Partes e unidades ligam-se umas às outras e desenham caminhos, e o passo
seguinte pergunta se algum desses caminhos volta ao ponto de partida.

### 11. Os grafos que as declarações formam

As partes ligam cada camada à camada composta que a recebe, e as conversões ligam as unidades umas
às outras; são dois grafos, e a pergunta é se algum dos seus caminhos volta ao ponto de partida.

```sql
SELECT graph AS grafo, n_nodes AS nós, m_edges AS arestas, c_components AS componentes,
       cycle_space_dim
FROM (
    SELECT * FROM rank_graph_measures
) g
WHERE filing IS NULL;
```

```sh
psql -d process_modulus -f pt-PT/assets/sql/queries/walk/11-the-graphs-the-filings-make.sql
```

Cada linha mede um grafo, tomado em todo o corpus, pelos nós, pelas arestas e pelos pedaços que não
se tocam, e a última coluna conta as voltas que o grafo fecha. No das camadas é 0: nenhuma camada
chega duas vezes ao mesmo total, que é o que diz a regra de que as partes de uma fusão repartem o
que compõem, aqui contado de outra maneira. No das unidades é 1: o documento `every-unit-cycle.xml`,
de `assets/fixtures/`, declara as conversões de `GPU-hour` para `node-hour` e de `node-hour` para
`GPU`, que, juntas à de `GPU` para `GPU-hour` do passo 7, fecham uma volta e regressam ao ponto de
partida; dar essa volta tem de devolver o que se tinha no início, e há uma regra no rol que o
confere. Daqui só falta juntar tudo.

### 12. A estrutura inteira

No fim do percurso as perguntas são duas: se cada regra do rol examinou linhas e alguma a quebrou, e
onde fica cada classe de cada classificação.

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

A primeira dá uma linha por regra, com as linhas que examinou e as que a quebraram, e todas examinam
alguma coisa sem que nenhuma saia quebrada. Uma regra que não tivesse nada para examinar não
desapareceria da lista, apareceria com zero examinadas, e é por isso que o rol vem primeiro e as
verificações se lhe juntam: um resultado limpo só diz alguma coisa quando houve o que examinar. A
segunda dá cada classe com a sua situação, `exercised` onde algum documento lá cai e `open` onde
nada cai, e nesse caso com a razão escrita ao lado. É esta a estrutura inteira, cada regra com o que
examinou e o que a quebrou, e cada classe com o lugar onde fica.

## As consultas por dentro

As consultas arrumam-se em pastas, pelo assunto de que tratam: `layers/` as camadas e os seus
números, `entries/` quem suporta o resto, as folgas e os consumos, `composition/` e `eliminations/`
o que uma entidade-mãe compõe e o que retira, `units/` as conversões, `epistemics/` as classes e as
ausências, `checks/` as regras, uma por ficheiro, com o rol em `checks/roster.sqlc`, `algebra/` as
leis, `rank/` os grafos, `reports/` o que o `rules.sql` imprime, `diagrams/` o que um desenho em
BPMN 2.0 tem de cumprir para dizer o mesmo que os documentos, e [`queries/`](queries/) as perguntas
que os programas de exemplo fazem. O `cargo sqlc compose` lê-as e escreve as consultas compostas em
`assets/sql/`:

```sh
cargo sqlc compose --source assets/sqlc --target assets/sql --with
```

Com `--with`, cada relação que uma consulta lê fica escrita uma vez só, com nome, à cabeça da
consulta, e cada uma vem depois das relações que ela própria lê, ficando a pergunta para o fim; o
nome vem do caminho do ficheiro, e `layers/figures.sqlc` chama-se `layers_figures`. É essa pergunta
final que cada passo do percurso mostra. O percurso em português compõe-se de `pt-PT/assets/sqlc`, e
as relações que lá não estão vai buscá-las a `assets/sqlc`, pelo que as perguntas em português
assentam nas mesmas relações que as inglesas:

```sh
cargo sqlc compose --source pt-PT/assets/sqlc --target pt-PT/assets/sql \
                  --search-path assets/sqlc --with
```

### As diretivas

Um ficheiro `.sqlc` é SQL com poucas diretivas a mais. O `:compose(layers/figures.sqlc)` põe ali a
relação desse ficheiro, nomeada pelo caminho dentro de `assets/sqlc/`, e o `:union(ALL …)` junta
várias relações da mesma forma, que é como o `checks/all.sqlc` junta as regras todas, cada uma no
seu ficheiro. Uma relação pode deixar uma vaga, `:compose(@scope)`, que quem a compõe preenche, como
em `:compose(reports/slack_census.sqlc, @scope = scope/every_filing.sqlc)`, e um ficheiro com uma
vaga por preencher não dá `.sql` nenhum, porque é uma forma à espera de quem a preencha. Um `#` abre
uma nota que vai até ao fim da linha e nunca chega ao SQL, esteja onde estiver, mesmo dentro de uma
cadeia de caracteres; já a linha `--` que abre cada relação, e que diz o que ela é, passa para a
consulta composta.

### Quem compõe quem

O `examples/compositions` lê todos os ficheiros `.sqlc` e escreve em `assets/dag/edges.sql` que
ficheiro compõe qual e quantas vezes o faz, e o `ingest.sql` carrega-o na tabela
`public.compose_edge`, de modo que a própria forma das consultas é uma relação, que se consulta como
as outras e que outras relações leem. Já o `examples/observations` confere que nenhum ficheiro fica
sem leitor: cada um é composto por outro, ou corre por si no `psql`, como o `ingest`, o `rules`, o
`matrices` e o `invariance`, ou é um passo do percurso, ou é lido por um programa de exemplo.

### A mesma falta, dita de outra maneira

O `invariance.sql` diz cada falta de outra maneira e volta a correr todas as regras, trocando as
palavras e deixando os números todos onde estavam. As reescritas são três, e o
`relabellings/roster.sqlc` lista-as com o que se espera de cada uma. A primeira passa a folga vazia
da capacidade para o tempo, nas camadas cuja falta ninguém podia servir, e diz assim que a mesma
procura ficou sem resposta, não porque a oferta não tivesse por onde crescer, mas porque a procura
não aguentou a espera; a segunda troca entre si `customer` e `unrealised`, procura que chegou e foi
mal servida e procura que nunca chegou a ser experiência de ninguém. Em nenhuma das duas um
veredicto se pode mexer, porque nenhuma regra tem de decidir qual das coisas aconteceu. A terceira
faz do cliente que ficou sem nada uma pessoa que absorveu a falta, passando `customer` a `people`, e
nessa os veredictos têm de se mexer, porque ficar por servir e absorver são coisas de natureza
diferente, que as regras leem de propósito; se também aí ficassem parados, a comparação estaria cega
e as duas primeiras não diriam nada. Cada reescrita corre dentro de uma transação que acaba em
`ROLLBACK`, pelo que a base de dados fica como estava:

```sh
psql -d process_modulus -f assets/sql/invariance.sql
```
