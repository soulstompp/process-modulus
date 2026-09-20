# Módulos partilhados, não programas

> **Grafia do AO90.** A versão inglesa está em [`README.md`](README.md) e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros e dos módulos ficam em
> inglês, porque são os nomes do artefacto.

Nada aqui é um exemplo. Estes são os módulos que os programas um nível acima importam, e esta pasta
deliberadamente não guarda `main.rs`, que é o que impede o cargo de construir um alvo a partir dela
e o que impede o `build.rs` de lhe pôr uma linha na tabela do [`../README.pt.md`](../README.pt.md).

| módulo | o que é | importado por |
|---|---|---|
| `simulation/` | uma bancada sobre o NeXosim: caixas de correio, uma fila de eventos e um relógio, mais o escritor de arquivos que transforma uma execução num documento que este esquema admite | `generation`, `resolution`, `strain` |
| `tree/` | o único leitor de `assets/sqlc/`, que lê as diretivas `:compose()` e percorre o termo | `compositions`, `observations`, `soundness` |
| `sources/` | a única travessia da própria pasta `examples/`, que pergunta que relações é que um programa nomeia | `compositions`, `observations` |
| `database/` | a única maneira de um programa abrir a sua base de dados, com o compilador just-in-time desligado, porque um plano desta profundidade custa mais a compilar do que a executar | `combinatorics`, `diagramming`, `graphs`, `matrices`, `observations`, `readiness`, `soundness` |

Um programa alcança-os por caminho, porque um módulo numa pasta irmã não é filho do alvo que o usa:

```rust
#[path = "../shared/tree/mod.rs"]
mod tree;
```

⭐ **Um só leitor, partilhado, é o que importa e não uma conveniência.** O `compositions` emite o
DAG de composição, o `soundness` volta a derivá-lo para verificar que a cópia emitida está atual, e
o `observations` pergunta o que é que nada alcança. Um segundo leitor das mesmas diretivas poderia
discordar do primeiro e nenhuma lei aqui o veria.
