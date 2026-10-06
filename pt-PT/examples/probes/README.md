**Português europeu.** Cada lei já foi vista a falhar, e cada declaração correta já aguentou uma alteração que não a pode acusar?

> **Grafia do AO90.** Também disponível em inglês: `examples/probes/README.md`.

Uma lei que nunca ninguém viu falhar é só uma frase, e uma absolvição que nunca ninguém pôs à prova
também. Este programa aplica, uma a uma, alterações pequenas e conhecidas, cada qual dentro de uma
transação que no fim se desfaz, e exige de cada uma exatamente o resultado anunciado. São de três
tipos:

- a alteração de uma lei, em que se muda o texto da relação que ela governa, ou se apaga uma linha
  carregada, e a lei tem de falhar onde se espera e manter-se no resto, sendo que uma lei que não
  devolve linha nenhuma não examinou nada e conta como errada;
- a absolvição, em que se altera uma declaração correta de maneira que continue correta, e, de
  todas as regras e de todas as leis, só podem disparar as previstas, que quase sempre são
  nenhuma;
- a recusa, em que a alteração dá um documento bem formado que o esquema rejeita, e o `xmllint`
  tem de o recusar antes que alguém o tenha de julgar.

Depois diz quantas leis do rol já foram vistas a falhar e quais ainda não, lidas do próprio rol e
não de uma lista sua, para que uma lei nova chegue por testar em vez de passar despercebida. E mede
cada instrução que um programa ou um teste lê com `query_file!`, porque o plano que o PostgreSQL faz
dela não pode ser mais fundo do que aquilo que o sqlx consegue ler de volta.

## Correr o programa

As alterações fazem-se sobre a composição com cada instrução por extenso, em `target/sql-inline/`,
que tem de ser mais recente do que `assets/sqlc/`, pelo que primeiro se compõe e só depois se corre:

```text
cargo sqlc compose --source assets/sqlc --target target/sql-inline --skip-prepare
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example probes
```
