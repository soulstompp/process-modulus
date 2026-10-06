**Português europeu.** Que grafos formam as declarações, e o que quer dizer, em cada um, uma volta fechada?

> **Grafia do AO90.** Também disponível em inglês: `examples/graphs/README.md`.

As declarações ligam coisas umas às outras de três maneiras: quem assina em nome de quem, que camada
se compõe de que camadas, e que unidade se converte em que unidade. Este programa lê da base de
dados o rol desses grafos, `diagrams/graphs.sqlc`, que é um literal e o único sítio onde um grafo
tem nome, junto com as arestas e os nós de cada um, e escreve cada grafo num documento BPMN à parte,
`assets/bpmn/graphs/model-<grafo>.bpmn`, em que os nós são as raias de uma única pool.

## Três documentos, cada um com as suas raias

Os três grafos não cabem num só desenho, porque uma raia só pode estar dentro de outra de uma
maneira e cada grafo agrupa as coisas à sua; cada um é, por isso, o preenchimento de um encaixe, e
uma aresta de um grafo que o rol não nomeia faz parar a execução, tal como o SQL recusa preencher um
encaixe que ninguém declarou. No grafo das camadas, cada nó traz a ordem pela qual a sua fusão pode
ser avaliada, juntada pela chave (declaração, camada), e o programa confirma que nenhuma camada a
perdeu e que nenhuma unidade a tem, porque essa ordem não é facto nenhum sobre unidades. O grafo de
quem assina por quem fica sem arestas, uma vez que nada as declara, e desenha-se como uma pool
fechada, sem processo, que é a maneira de o BPMN dizer que alguém atua ali e que o que faz não está
no desenho. Cada frase que os documentos levam cita a relação de onde vem.

## Uma volta fechada não quer dizer o mesmo nos três

Entre quem assina, uma volta é coisa que se desconhece, e não quer dizer que ninguém responda por
nada, porque dois responsáveis com poderes de assinatura um sobre o outro formam uma volta legítima.
Entre camadas, uma volta é uma parte que chega duas vezes à mesma fusão por dois ramos, ou seja,
contar a dobrar, e quem a apanha é `checks/jagged_layer`; o programa conta as voltas do grafo das
camadas e corre essa regra, e as duas contagens são a mesma afirmação vista de dois lados. Entre
unidades, uma volta é esperada e tem de fechar, já que dar a volta às conversões tem de devolver a
mesma quantidade de que se partiu, e é `checks/conversion_cycle_does_not_close` que o verifica.

## Correr o programa

Precisa da base de dados carregada; o `rendering` desenha depois estes documentos em SVG:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example graphs
```
