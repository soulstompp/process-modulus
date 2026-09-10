**Português europeu.** O SVG em camadas, que é o `.sqlx` deste pipeline.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do BPMN e do XSD ficam em inglês, porque são os nomes do artefacto.

⭐⭐⭐ LÊ O BPMN E NUNCA O MODELO, E É NISSO QUE ESTÁ TODO O DESENHO. O `.sqlx` são metadados
extraídos do `.sql` GERADO, e não do `.sqlc`, porque uma cache derivada da fonte poderia concordar
com a fonte e discordar do artefacto que diz descrever, que é a definição de uma cache obsoleta.
Portanto este programa abre `assets/bpmn/*.bpmn` e mais nada. **Não tem ligação a base de dados**,
e isso não é uma conveniência: é o que torna «derivado do artefacto» estrutural em vez de uma
promessa.

⭐⭐ *DEVIDAMENTE EM CAMADAS* É A ESPECIFICAÇÃO INTEIRA. O `.sqlx` permite que uma compilação
verifique sem base de dados presente; isto permite que um leitor verifique sem ferramenta de BPMN
presente, e só o consegue fazer se a estrutura sobreviver à viagem. Cada lane torna-se o seu
próprio `<g class="lane">` transportando o nome da camada em `data-layer`. ⛔ Um SVG achatado é um
`.sqlx` que perdeu os tipos das colunas: continua a desenhar, e não verifica nada.

⭐⭐⭐ E *EM CAMADAS* É SÓ METADE DISTO: O ALFABETO É O CONJUNTO DE ÍCONES DO BPMN E MAIS NADA.
O BPMN diz de que espécie é uma atividade pela sua MARGEM, portanto o glifo é o discriminante e
não decoração: um `task` é fino, um `callActivity` é GROSSO porque é o elemento que substitui, um
`subProcess` transporta o marcador ⊞, e um `participant` sem `processRef` é uma POOL VAZIA, que é
a notação para *o que eles fazem não está neste diagrama*.

⛔⛔ ESTE PROGRAMA DESENHOU 65 RETÂNGULOS IDÊNTICOS PARA 38 TASKS, 17 CALL ACTIVITIES E 10
SUB-PROCESSES, E TODAS AS LEIS QUE TEM PASSARAM. A espécie era emparelhada e deitada fora no sítio
da leitura, três linhas acima da caneta. Ambas as leis aqui contam, e um colapso de glifos preserva
a cardinalidade por construção, pelo que `65 == 65` foi verdade de ponta a ponta. ⭐ A reparação é
atribuição e não uma contagem maior, que é a mesma reparação que o `diagrams/ungoverned.sqlc` fez
do lado do modelo.

⛔⛔ A LEI É VERIFICADA CONTRA O BPMN, NÃO CONTRA O `diagrams/expected.sqlc`. Uma cache é
verificada contra aquilo de que é cache. O `examples/diagramming/main.rs` já verificou o BPMN
contra o modelo, pelo que os dois em conjunto levam o SVG de volta ao conjunto de documentos por
transitividade, e cada elo é verificado onde pode de facto ser visto.

```text
cargo run --example rendering        # não precisa de DATABASE_URL, de propósito
```
