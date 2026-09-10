# Os exemplos, e a pergunta que cada um põe ao modelo

> **Grafia do AO90.** A versão inglesa está em [`README.md`](README.md) e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

Cada afirmação que este repositório faz sobre a sua própria aritmética é feita dentro de um
programa que a avalia. Esta pasta é esses programas. Uma pasta por programa, e o `README.md` de
cada um **é** o seu cabeçalho: o `main.rs` abre com

```rust
#![doc = include_str!("README.md")]
#![doc = include_str!("README.pt.md")]
```

pelo que a página que aqui se lê, a página que o `cargo doc --examples` compõe e a página que quem
lê o código vê são os mesmos ficheiros, nas duas línguas. Um programa sem cabeçalho não compila, e
um programa sem cabeçalho português também não.

A pasta `shared/` não é um programa. Guarda os módulos que vários destes importam, e
deliberadamente não guarda `main.rs`, que é exatamente como o cargo decide o que é um exemplo e
como o `build.rs` decide o que entra na tabela abaixo.

| exemplo | a pergunta a que responde | base de dados |
|---|---|---|
| [`compositions`](compositions/) | As composições que este repositório tem, e as três precondições que fazem delas uma álgebra. | não |
| [`diagramming`](diagramming/) | O modelo, traduzido para BPMN 2.0, e as leis que dizem que a tradução foi fiel. | sim |
| [`generation`](generation/) | Uma execução do modelo chega sequer a arquivar? | sim |
| [`graphs`](graphs/) | Os três grafos que este modelo compõe, como os lane sets de uma só pool. | sim |
| [`matrices`](matrices/) | A segunda testemunha: a mesma aritmética, calculada por outra via. | sim |
| [`observations`](observations/) | O que o conjunto de documentos diz de facto, e se alguma coisa está a olhar. | sim |
| [`readiness`](readiness/) | Antes da aritmética: pode-se sequer calcular aqui? | sim |
| [`rendering`](rendering/) | O SVG em camadas, que é o `.sqlx` deste pipeline. | não |
| [`resolution`](resolution/) | Quanto custa um instrumento com perdas, nas unidades em que o esquema arquiva? | não |
| [`soundness`](soundness/) | A maquinaria faz o que afirma? | sim |
| [`strain`](strain/) | O que é que o modelo tem de ser torcido para dizer? | não |
| [`witnesses`](witnesses/) | Se cada regra já foi VISTA A DIZER NÃO. | sim |

Um `sim` ali não é uma sugestão. Nenhum destes programas salta quando a base de dados falta: uma
prova que passa por não ter executado é a vacuidade que este repositório não se cansa de nomear,
portanto falham em vez de correr. O [`README.pt.md`](../README.pt.md) da raiz tem os passos que
constroem a base de dados.

```text
cargo run --example matrices          # um deles
cargo doc --examples --open           # os cabeçalhos de todos, compostos
```

Esta tabela não é mantida à mão. O `build.rs` lê a mesma pasta em cada compilação e gera a cópia
que aparece na primeira página do crate, e o `tests/examples.rs` falha se uma linha daqui e a
primeira linha de um programa discordarem, se um programa não tiver linha, ou se uma linha não
nomear programa nenhum. As duas tabelas são verificadas do mesmo modo, uma por língua.
