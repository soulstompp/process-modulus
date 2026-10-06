**Português europeu.** Cada declaração desenhada num documento BPMN 2.0, e a verificação de que o desenho diz o mesmo que o modelo.

> **Grafia do AO90.** Também disponível em inglês: `examples/diagramming/README.md`.

Uma empresa que já desenha os seus processos em BPMN quer ver as declarações na notação que conhece,
e este programa desenha-as. Lê o corpus carregado através das relações de `assets/sqlc/diagrams/`,
que dizem o que liga a quê e nunca trazem uma grandeza, e escreve em `assets/bpmn/filings/` um
documento de definições BPMN 2.0 por declaração, completo e capaz de se abrir sozinho, depois de
apagar a pasta, já que um documento antigo descreve um modelo que entretanto mudou. Cada declaração
é uma pool e cada camada uma raia, com as partes de uma fusão local em raias dentro da raia
composta; cada operação é uma tarefa na raia da camada de que consome, cada parte vinda de outra
declaração é uma `callActivity` para o documento dessa declaração, e o que um leitor tem de ver no
próprio desenho vai numa `textAnnotation`, com cada frase a citar a relação de onde vem.

A seguir, verifica o que escreveu, lendo-o do disco. Conta cada tipo de elemento nos documentos e
compara-o com o que o modelo diz que lá devia estar (`diagrams/expected.sqlc`); compara a notação
gasta com o vocabulário inteiro do BPMN (`diagrams/notation.sqlc`), donde se vê que nenhum dos dois
contém o outro, porque há eixos inteiros do BPMN que o modelo não usa e factos do modelo que o BPMN
não tem onde pôr; lê as partes de volta a partir dos documentos e encontra-as todas, uma a uma, ao
nível da camada; e lista, com a razão de cada caso, o que fica fora do desenho, como quem suporta o
resto, a capacidade nominal, as três folgas, as ausências e as derivações. Por fim, mostra os níveis
que o corpus contém, desde o consumo das camadas até aos róis que fecham tudo, dos quais só o
primeiro se desenha.

## Correr o programa

Precisa da base de dados carregada; o `rendering` desenha depois estes documentos em SVG:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example diagramming
```
