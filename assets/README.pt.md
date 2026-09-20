# `assets/`: a prova, a maquinaria que a lê, e o que é gerado a partir das duas

> **Grafia do AO90.** A versão inglesa está em [`README.md`](README.md), nesta pasta, e é a que o
> repositório trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das
> tabelas e dos elementos do XSD ficam em inglês, porque são os nomes do artefacto.

Vivem aqui dois géneros de coisa, e o género de cada pasta decide se lhe pode mexer.

## Escritos à mão, e cada um argumenta por si

| pasta | o que responde |
|---|---|
| [`corpus/`](corpus/) | `assets/corpus/`: o aspeto de um arquivo, e a camada por causa da qual o modelo existe |
| [`fixtures/`](fixtures/) | `assets/fixtures/`: um documento por estado, e NÃO um segundo conjunto de documentos |
| [`sqlc/`](sqlc/) | O mesmo modelo, duas vezes: como tabelas e como matrizes |

Cada entrada acima é a primeira linha da própria pasta. A pasta é onde ela é autoritativa, e esta
tabela é uma porta de entrada e não uma segunda cópia.

O `ddl/schema.ddl` é a quarta coisa escrita à mão aqui e não tem pasta própria. É o esquema
relacional, que segue o esquema XML tão de perto quanto os dois formalismos permitem, para que uma
afirmação provada contra ele seja uma afirmação sobre o modelo e não sobre uma tradução. Não é
composto de propósito: o `sqlc` compõe instruções e CTE, e uma expressão `CHECK` não é nem uma nem
outra.

## Gerados, e apagados por aquilo que os produz

⛔⛔ **NENHUM DESTES É EDITADO À MÃO, E NENHUM TEM README**, porque nenhum tem um argumento que não
seja o de quem o produz. Uma alteração aqui sobrevive até à execução seguinte e depois desaparece
sem nada que o avise.

| pasta | escrita por | e guarda |
|---|---|---|
| `sql/` | `cargo sqlc compose`, a partir de [`sqlc/`](sqlc/) | cada modelo como uma consulta completa e executável |
| `dag/` | [`examples/compositions`](../examples/compositions/) | o grafo de composição em linhas, para que a forma da própria árvore seja consultável |
| `bpmn/` | [`examples/diagramming`](../examples/diagramming/) e [`examples/graphs`](../examples/graphs/) | o modelo traduzido para BPMN 2.0, um documento por arquivo e um por grafo |
| `svg/` | [`examples/rendering`](../examples/rendering/) | a imagem em camadas, que é uma prova que um leitor pode verificar sem ferramenta nenhuma |

⚠️ O `bpmn/` e o `svg/` são gerados **e** versionados, pela mesma razão que o `sql/` o é: quem
percorre o repositório deve ver o que a cadeia produziu sem ter de a executar primeiro. Estar
versionado não é o mesmo que ser editável.
