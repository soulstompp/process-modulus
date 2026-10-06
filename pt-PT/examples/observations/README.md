**Português europeu.** O que é que o corpus diz, e onde é que alguém foi de facto ver?

> **Grafia do AO90.** Também disponível em inglês: `examples/observations/README.md`.

Uma regra que passa diz apenas que nada a contradisse, e não diz se alguém mediu, se perguntou ou se
preferiu não responder. Este programa não acusa nem absolve ninguém, relata o que o corpus carregado
diz quando se lhe pergunta, e a maior parte dos seus números relata-se sem nunca se fixar, porque
descreve declarações que podem mudar. Há uma exceção, e é por ela que o programa existe: nada no
repositório pode ficar sem ser alcançado. Cada ficheiro `.sqlc` tem de ser composto por outro,
corrido pelo `psql` como ponto de entrada, como o `ingest.sqlc`, o `rules.sqlc` e os passos do
percurso, ou lido por um exemplo; e cada documento de `assets/corpus/` e de `assets/fixtures/` tem
de ser carregado pelo `ingest`, ou então lido por um teste em Rust, com a razão escrita numa lista
que o próprio programa guarda. O que ninguém lê é invisível, e o invisível, visto de fora, é igual
ao que não existe.

O resto são perguntas, uma por secção: quem atesta cada documento, de onde dizem vir as afirmações,
que denominadores e que paciências se declaram, que amortecedores estão dimensionados, se cada resto
diz até onde pode passar para outras camadas, que constatações só uma pessoa pode decidir, se alguém
foi procurar acoplamentos entre camadas ou contagens a dobrar entre partes, o que nomeia cada
eliminação, que razões de ausência cada pergunta já recebeu e quantas regras podem dizer alguma
coisa sobre cada camada. As fixtures recusam muitas perguntas de propósito, que é para isso que
serve uma estipulação, e não contam como prova em sítio nenhum.

## Folga zero não é folga em branco

Na contagem dos amortecedores, cada folga cai numa de três colunas: dimensionada, dimensionada a
zero, ou ausente. Uma folga declarada como 0 é o limite mais apertado que se pode dar, a afirmação
de que não sobra margem nenhuma, e nada tem de lacuna; uma folga ausente traz a sua razão, `none`,
`unmeasured` ou `notApplicable`, e não afirma valor nenhum. A contagem separa ainda o que foi
observado do que foi estipulado, porque uma fixture que declara zero para exercitar um estado nada
diz sobre empresa alguma.

## Correr o programa

Precisa da base de dados carregada com o corpus:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example observations
```
