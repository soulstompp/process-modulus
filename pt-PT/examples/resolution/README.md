**Português europeu.** Quanto se perde com um instrumento que não vê tudo, contado nas unidades que a declaração usa?

> **Grafia do AO90.** Também disponível em inglês: `examples/resolution/README.md`.

Uma declaração só pode dizer o que o seu instrumento registou, e um registo vê menos do que aquilo
que aconteceu. Este programa, sem base de dados, simula no NeXosim uma linha de oferta em três
situações, com folga, curta e a recusar procura, e curta com a procura à espera até desistir, cada
uma com várias sementes, e lê cada execução de três maneiras: o histórico inteiro, o registo de
existências e fluxos com o tamanho declarado de um pedido, e o registo sozinho. Para cada grandeza,
a procura, o que se fez, a capacidade nominal, o resto, o que se serviu, o que ficou por servir e as
quotas de quem o suporta, põe as três leituras lado a lado e exige que as mais pobres contenham a
verdadeira; iguais não têm de ser, porque um instrumento que devolvesse a verdade exata não teria
perdido nada.

Com o tamanho declarado, a procura, o resto e o que ficou por servir passam intactos na linha com
folga e custam, nas linhas curtas, um intervalo cuja largura o programa imprime nas unidades da
declaração; com o registo sozinho, ficam `unmeasured` em todas. A repartição do que ficou por servir
entre `customer` e `unrealised` fica `unmeasured` nas duas leituras pobres, com a soma fixada. No
fim, duas histórias diferentes dão o mesmo registo: numa, a procura esperou e desistiu, e é
`customer`; na outra, foi recusada logo à chegada, e é `unrealised`. O registo não as distingue, as
duas declaram-se de maneira diferente e a soma é a mesma nas duas, e medir outra vez não estreita
esta largura, que foi o instrumento a criar; é exatamente o que declara um `narrowsWhen` do tipo
`instrument`.

## Correr o programa

Não precisa de base de dados:

```text
cargo run --example resolution
```
