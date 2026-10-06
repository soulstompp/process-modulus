# `queries/`: o SQL que os programas de exemplo leem

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`README.md`](../../../../assets/sqlc/queries/README.md).

Os programas de exemplo leem as consultas já compostas, pelo caminho do ficheiro, com o
`sqlx::query_file!`, que confere as colunas e os tipos de cada uma quando o programa compila; as
perguntas que cada programa faz por sua conta ficam nesta pasta, compostas em `assets/sql/queries/`,
cada programa com a sua subpasta:

- `readiness/`, do [`readiness`](../../../examples/readiness/), que pergunta, antes de qualquer
  conta, se ali se pode sequer calcular;
- `observations/`, do [`observations`](../../../examples/observations/), que mostra o que o corpus
  diz de facto;
- `soundness/`, do [`soundness`](../../../examples/soundness/), que confere se as consultas fazem o
  que dizem;
- `combinatorics/`, do [`combinatorics`](../../../examples/combinatorics/), que vê onde cai cada
  linha.

A `walk/` guarda os passos do percurso que a [página de cima](../README.md) lê um a um, e que se
correm no `psql`; nesta árvore em português, aliás, é a única subpasta que há, com as perguntas do
percurso e os nomes das colunas em português.

Para correr uma delas à mão, compõe-se e dá-se o ficheiro composto ao `psql`:

```sh
cargo sqlc compose --source assets/sqlc --target assets/sql --with --skip-prepare
psql -d process_modulus -f assets/sql/queries/readiness/1-sites.sql
```

A `readiness/1-sites.sql` dá uma linha por sítio onde o esquema faz contas, com quantas vezes ali se
pode calcular, quantas uma ausência declarada suspende e quantas juntam dois números que não se
comparam, e o que há para ver é a coluna `guarded_by!`, a regra que confere que os dois números são
da mesma espécie: a maior parte vem em branco, e um branco quer dizer que nenhuma regra está ali de
guarda. O `!` no fim do nome é para o sqlx, e diz-lhe que a coluna nunca vem a nulo.

Os programas compilam sem base de dados nenhuma, porque o sqlx lê a cache `.sqlx/` que vem com o
repositório, e quando uma consulta muda é preciso recompô-la e regenerar essa cache. O `cargo sqlc
compose` sabe correr ele próprio o `cargo sqlx prepare`, só que sem o `--all-targets`, que é o que
chega aos programas de exemplo; por isso compõe-se com `--skip-prepare` e prepara-se à parte, contra
a base de dados carregada que a `DATABASE_URL` indicar:

```sh
cargo sqlc compose --source assets/sqlc --target assets/sql --with --skip-prepare
cargo sqlx prepare -- --all-targets
```
