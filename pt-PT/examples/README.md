# `examples/`: os exemplos e a pergunta que cada um faz ao modelo

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`examples/README.md`](../../examples/README.md).

Cada programa desta pasta faz uma pergunta ao modelo e responde-lhe correndo, de modo que o
argumento fica no programa que o calcula e não numa frase que ninguém volta a conferir. O cabeçalho
de cada um são duas páginas, o `README.md` ao lado do seu `main.rs`, em inglês, e a página com o
mesmo caminho debaixo de `pt-PT/`, em português, e o programa inclui as duas:

```rust
#![doc = include_str!("README.md")]
#![doc = include_str!("../../pt-PT/examples/<name>/README.md")]
```

Assim, a página que se lê no repositório e a que o `cargo doc` desenha são o mesmo texto, nas duas
línguas. A primeira linha de cada página é a pergunta que a tabela abaixo repete, e o
`tests/examples.rs` confere uma com a outra nos dois sentidos e nas duas línguas, pelo que um
programa sem linha na tabela, ou uma linha sem programa, faz falhar o teste. A pasta
[`shared/`](shared/) guarda o código que vários programas partilham; como não tem `main.rs`, não é
programa e não entra na tabela.

| exemplo | a pergunta que faz | base de dados |
|---|---|---|
| [`combinatorics`](combinatorics/) | Em que classe cai cada linha, e cada consulta conta mesmo aquilo que diz contar? | sim |
| [`compositions`](compositions/) | Que consulta compõe qual, e se todos os nomes existem, nada se compõe a si próprio e cada expansão acaba. | não |
| [`diagramming`](diagramming/) | Cada declaração desenhada num documento BPMN 2.0, e a verificação de que o desenho diz o mesmo que o modelo. | sim |
| [`generation`](generation/) | Uma execução simulada chega a dar uma declaração que o esquema aceita e regra nenhuma acusa? | sim |
| [`graphs`](graphs/) | Que grafos formam as declarações, e o que quer dizer, em cada um, uma volta fechada? | sim |
| [`observations`](observations/) | O que é que o corpus diz, e onde é que alguém foi de facto ver? | sim |
| [`probes`](probes/) | Cada lei já foi vista a falhar, e cada declaração correta já aguentou uma alteração que não a pode acusar? | sim |
| [`readiness`](readiness/) | Antes das contas: onde é que se pode mesmo calcular, e o que trava o resto? | sim |
| [`rendering`](rendering/) | Um SVG para cada documento BPMN, desenhado a partir do documento e nunca a partir do modelo. | não |
| [`resolution`](resolution/) | Quanto se perde com um instrumento que não vê tudo, contado nas unidades que a declaração usa? | não |
| [`soundness`](soundness/) | Cada consulta calcula o que o seu cabeçalho diz que calcula? | sim |
| [`strain`](strain/) | Onde é que o modelo tem de forçar a realidade para a conseguir declarar? | não |
| [`witnesses`](witnesses/) | Cada regra do rol já foi vista a dizer que não? | sim |

Um `sim` na última coluna quer dizer que o programa lê `DATABASE_URL` e que, sem uma base de dados
carregada com o corpus, como explica a [página principal](../README.md), não corre: falha, em vez de
passar sem ter examinado nada. O `diagramming` e o `graphs` escrevem os documentos BPMN que o
`rendering` depois desenha em SVG, pelo que este corre por último. Cada um corre-se à parte, e as
páginas de todos leem-se já desenhadas:

```text
cargo run --example soundness         # um deles
cargo doc --examples --open           # as páginas de todos, já desenhadas
```
