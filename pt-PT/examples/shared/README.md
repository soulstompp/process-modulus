# `examples/shared/`: o código que vários programas partilham, e que não é programa nenhum

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`examples/shared/README.md`](../../../examples/shared/README.md).

Para o `cargo`, uma pasta de `examples/` só é programa se tiver um `main.rs`, e esta não tem nenhum,
pelo que não se compila sozinha nem tem linha na tabela dos exemplos. Guarda o código de que mais de
um programa precisa, e cada programa vai buscá-lo pelo caminho:

```rust
#[path = "../shared/tree/mod.rs"]
mod tree;
```

- `database/` abre a ligação à base de dados com o compilador JIT do PostgreSQL desligado, porque
  as instruções destes programas compõem planos tão fundos que compilá-los custa mais do que
  corrê-los; a definição muda o momento em que um plano se compila, nunca aquilo que devolve.
- `simulation/` é a bancada no NeXosim: uma linha de oferta com os três amortecedores,
  existências, capacidade e tempo, os dois instrumentos que a observam e a declaração que cada
  leitura dá. Servem-se dela o `generation`, o `resolution` e o `strain`.
- `sources/` junta numa só cadeia o código de todos os exemplos, para que o `compositions` e o
  `observations` respondam da mesma maneira quando perguntam se um exemplo corre uma dada relação.
- `tree/` lê `assets/sqlc/` como um grafo de quem compõe quem, para que os programas que fazem
  perguntas a esse grafo, o `combinatorics`, o `compositions`, o `observations` e o `soundness`,
  não possam discordar uns dos outros.

Um módulo que nenhum programa importe é código que nada compila, e o `tests/examples.rs` recusa-o; o
mesmo teste nomeia esta pasta como a única de `examples/` que não é programa, de modo que uma
segunda faz falhar o teste e diz o que é. A lista dos programas está na [página dos
exemplos](../README.md).
