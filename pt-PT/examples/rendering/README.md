**Português europeu.** Um SVG para cada documento BPMN, desenhado a partir do documento e nunca a partir do modelo.

> **Grafia do AO90.** Também disponível em inglês: `examples/rendering/README.md`.

Nem toda a gente tem uma ferramenta de BPMN à mão, e um SVG abre-se em qualquer navegador. Este
programa não toca na base de dados: lê os documentos que o `diagramming` e o `graphs` escreveram em
`assets/bpmn/`, cada um na sua pasta, e escreve um SVG por documento, no mesmo caminho, dentro de
`assets/svg/`. As duas origens estão declaradas no programa, pelo que tanto uma que não tenha
corrido como uma terceira que ninguém declarou acabam notadas. Um desenho tirado do modelo seria uma
segunda opinião, ao passo que um desenho tirado do documento é uma cópia que se pode conferir com
ele, e é isso que o programa faz a seguir.

Conta raias, nós, grupos, dependências e notas dos dois lados, e exige que coincidam; desenha cada
tipo de atividade com o seu próprio traço; segue cada ligação de um desenho para outro, das raias
para o grafo das camadas e das chamadas para o documento da outra declaração, sem que nenhuma fique
pendurada; usa apenas SVG normal, com um `id` e um `<title>` em cada grupo, para que qualquer editor
ou leitor de ecrã os saiba nomear; põe cada caixa onde o `bpmndi` do documento diz, sem inventar
coordenadas que outro leitor do ficheiro não teria; mete as raias umas dentro das outras como o BPMN
as declarou; mostra que frases de `documentation` chegam ao desenho e quais ficam só no documento; e
diz o que acontece no desenho a cada tipo de elemento do BPMN. O que se perde é sempre a mesma
coisa, uma referência a outro documento, porque um desenho só liga duas coisas que estejam na mesma
página.

## Correr o programa

Não precisa de base de dados, e corre-se depois do `diagramming` e do `graphs`:

```text
cargo run --example rendering
```
