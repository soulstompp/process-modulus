**Português europeu.** Antes das contas: onde é que se pode mesmo calcular, e o que trava o resto?

> **Grafia do AO90.** Também disponível em inglês: `examples/readiness/README.md`.

O modelo faz contas num número fechado de sítios, como a subtração que dá o resto, a verificação de
que a capacidade nominal é um múltiplo inteiro do quantum ou a soma das quotas de quem suporta o
resto, e todos eles estão no rol `arithmetic/roster.sqlc`. Este programa lê esse rol da base de
dados carregada e diz, para cada sítio, quantas contas se podem fazer, quantas ficam suspensas por
uma ausência declarada, quantas juntariam números de coisas diferentes, e que regra confirma que os
operandos estão na mesma unidade; um sítio sem essa regra mostra `not checked`, nunca um espaço em
branco nem um visto, para que quem lê a coluna veja o buraco sem ter de contar.

Uma conta que junte unidades diferentes dá um número com ótimo aspeto e sentido nenhum, pelo que
essa coluna tem de dar zero em todos os sítios, e o programa para se não der. As suspensas, essas,
listam-se uma a uma, por sítio, declaração e camada, com o que as travou, e o seu número relata-se
sem nunca se fixar: cada uma é alguém a dizer que não mediu uma coisa e o modelo a confiar na
palavra dessa pessoa, e no dia em que alguém a medir sai da lista, que é o modelo a funcionar. Por
fim, o programa confirma que cada rol do repositório está de acordo com a população que declara e,
se não estiver, para, uma vez que um relatório sobre o que se pode calcular nada vale se o
verificador em que assenta estiver partido.

## Correr o programa

Precisa da base de dados carregada com o corpus:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example readiness
```
