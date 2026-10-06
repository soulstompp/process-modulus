# `assets/`: os documentos e as consultas que os leem, mais o que se gera a partir de uns e de outros

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`README.md`](../../assets/README.md).

Aqui está tudo o que põe o esquema a trabalhar, dividido conforme quem o faz: os documentos e as
consultas escreve-os alguém, à mão, e o resto gera-o um programa a partir deles, pelo que um
ficheiro gerado nunca se corrige onde está; corrige-se a origem e gera-se de novo.

## O que alguém escreve

| pasta | o que lá está |
|---|---|
| [`corpus/`](corpus/) | `assets/corpus/`: como é uma declaração, e uma camada lida do princípio ao fim |
| [`fixtures/`](fixtures/) | `assets/fixtures/`: os estados a que o corpus não chega, escritos de propósito |
| [`sqlc/`](sqlc/) | `assets/sqlc/`: as consultas, e o percurso que vai do resto de uma camada à estrutura inteira |

Os documentos do corpus contam o que alguém viu, as fixtures foram inventadas para levar o modelo
aos estados que o corpus não alcança, e as consultas, escritas em ficheiros `.sqlc` do sql-composer,
leem uns e outras. Também se escreve à mão o `ddl/schema.ddl`, as relações em que o `ingest.sql`
carrega os documentos, desenhadas para verificar o que o XSD não verifica e não para servir de
modelo à base de dados de uma aplicação.

## O que um programa gera

| pasta | quem a gera | o que lá está |
|---|---|---|
| `sql/` | `cargo sqlc compose`, a partir de [`sqlc/`](sqlc/) | cada consulta composta por inteiro, pronta a correr no `psql` |
| `dag/` | [`compositions`](../examples/compositions/) | que consulta compõe qual, em linhas que o `ingest.sql` carrega para a base de dados |
| `bpmn/` | [`diagramming`](../examples/diagramming/) e [`graphs`](../examples/graphs/) | cada declaração desenhada em BPMN 2.0, em `bpmn/filings/`, e os três grafos que as declarações formam, em `bpmn/graphs/` |
| `svg/` | [`rendering`](../examples/rendering/) | os mesmos desenhos em SVG, lidos do BPMN e nunca do modelo |

Os ficheiros gerados ficam no repositório, para que quem o clona os tenha sem correr nada, e os de
`dag/`, `bpmn/` e `svg/` dizem logo no topo que programa os gerou e que não se editam; quanto a um
`.sql` mexido à mão, perde-se na composição seguinte, que o reescreve inteiro. Os dois programas
que desenham as declarações vão buscá-las à base de dados carregada, ao passo que o `rendering` e o
`compositions` trabalham sobre ficheiros, um a partir do BPMN e o outro a partir dos `.sqlc`.
