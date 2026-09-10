# `queries/`, o SQL dos exemplos, como modelos

> **Grafia do AO90.** A versão inglesa está em [`README.md`](README.md) e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

**Uma subpasta por exemplo, um ficheiro por consulta.** Postas de fora para poderem ser lidas e
corridas sem Rust; cada uma é uma única instrução.

| pasta | exemplo | a pergunta que faz |
|---|---|---|
| `matrices/` | [`examples/matrices/main.rs`](../../../examples/matrices/main.rs) | a aritmética concorda consigo mesma? |
| `readiness/` | [`examples/readiness/main.rs`](../../../examples/readiness/main.rs) | pode-se sequer calcular aqui? |
| `observations/` | [`examples/observations/main.rs`](../../../examples/observations/main.rs) | o que diz o conjunto de documentos? |
| `soundness/` | [`examples/soundness/main.rs`](../../../examples/soundness/main.rs) | a maquinaria faz o que afirma? |

⭐ **A pasta é a correspondência, em vez de ser coisa que um leitor tem de se lembrar.** Uma
consulta acrescentada a `readiness/` e nunca lida pelo `examples/readiness/main.rs` aparece como
órfã no `examples/observations/main.rs`, que afirma que nada em `assets/sqlc/` é alcançado por nada.

⚠️ O `matrices/` responde às secções numeradas do [`../README.pt.md`](../README.pt.md). As outras
três não lhe correspondem: o `readiness/` é uma vista sobre `arithmetic/all.sqlc`, o
`observations/` é um passeio por relações cujo produto é conhecimento e não um veredicto, e o
`soundness/` é o que lê várias: as leis de álgebra de conjuntos em `algebra/all.sqlc`, os contratos
de roster em `reports/integrity.sqlc`, e o que a população de cada roster emite quando o conjunto de
documentos está vazio.

⭐⭐ **O `soundness/` é o único que não pode acusar o arquivo de ninguém.** As outras três perguntam
pela aritmética, pelos dados e pelo conjunto de documentos; essa pergunta se as CONSULTAS calculam o
que dizem. É onde uma diferença que falha para uma tabela plausível é apanhada.

⭐ **Cada uma compõe as mesmas relações que as regras compõem**, em vez de repetir as junções. O
`1-fit-from-ranges` compõe `layers/signed.sqlc`, que é também a população que a regra do sinal
examina; o `3b-composed-demand` faz anti-junção com `composition/suspended_fusions.sqlc`, que é
também aquilo com que o `matrices.sql` faz anti-junção. Portanto o exemplo e o verificador correm
sobre as mesmas linhas por construção e não por dois autores estarem de acordo, e se quiser ver de
que é feita uma destas consultas, siga-lhe as linhas `:compose()`.

Estes são modelos `.sqlc`. O `cargo sqlc compose` escreve o SQL executável em
`assets/sql/queries/`, e é isso que o `psql` e o `sqlx` leem:

```
cargo sqlc compose --source assets/sqlc --target assets/sql --skip-prepare
psql -d process_modulus_proof -f assets/sql/queries/matrices/1-fit-from-ranges.sql
```

⚠️ **O `#` é retirado, o `--` não.** Uma linha `#` é um comentário de modelo: existe para quem lê o
modelo e nunca chega à base de dados. Uma linha `--` é SQL comum e viaja com a consulta, para dentro
da instrução que o Postgres analisa, para o `pg_stat_statements`, e para a cache `.sqlx/` que está
no repositório, cuja chave é o texto da consulta. Portanto o argumento vai em `#` e o `--` guarda
apenas o marcador `§` que nomeia a consulta no fio. Antes da divisão, 62% dos bytes desta pasta eram
prosa a ser enviada para o servidor.

⚠️ **O `!` e o `::float8` nos alias das colunas são para o sqlx, não para quem lê.** O
`AS "layer!"` afirma à macro do Rust que a coluna nunca é NULL, e o `::float8` fixa um numérico a um
tipo que a macro consegue mapear. O Postgres trata ambos como um alias comum e uma conversão comum,
pelo que estes ficheiros correm sem alterações no `psql`, a coluna é que volta chamada `layer!`.

⛔ **Editar um destes ficheiros muda um contrato de tempo de compilação.** O
`examples/matrices/main.rs` lê a saída composta com `sqlx::query_file!`, que verifica as colunas e
os seus tipos contra uma base de dados viva no momento da compilação. Depois de editar um modelo,
recompor e regenerar:

```
cargo sqlc compose --source assets/sqlc --target assets/sql --skip-prepare
cargo sqlx prepare -- --all-targets   # cada exemplo lê query_file!; um só alvo poda os outros
```

⛔ **O `assets/sql/` é gerado e apagado em cada composição.** Nada escrito à mão sobrevive lá. O
`cargo sqlc compose --verify` compara a saída no repositório com os modelos e sai com código não
nulo se houver desvio.
