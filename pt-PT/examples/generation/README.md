**Português europeu.** Uma execução simulada chega a dar uma declaração que o esquema aceita e regra nenhuma acusa?

> **Grafia do AO90.** Também disponível em inglês: `examples/generation/README.md`.

Uma declaração não é aquilo que aconteceu, é o que um instrumento conseguiu registar ao longo de uma
janela, e este programa tem as duas coisas na mão ao mesmo tempo. Simula no NeXosim uma linha de
oferta em várias situações, com folga, a recusar procura, a deixar a procura à espera, a recorrer a
horas extraordinárias e sem amortecedor nenhum, e lê cada execução com dois instrumentos, um que vê
o histórico inteiro e outro que só vê o que um registo de existências e fluxos guarda, tendo ao lado
o tamanho declarado de um pedido. Cada leitura dá uma declaração, escrita em `target/simulation/`,
e a pergunta é se uma empresa simulada, lida assim, chega a declarar-se como o corpus se declara.

Cada uma passa primeiro pelo `xmllint`, contra `schema/process-modulus.xsd`, e basta que o esquema
recuse uma para o programa parar aí, porque as regras não correm sobre um documento inválido. Depois
entram todas pelo mesmo `ingest.sql` que o corpus, numa transação que no fim se desfaz, e correm as
regras de `assets/sql/checks/all.sql`. O programa exige três coisas: que nenhuma regra seja violada;
que cada declaração dê às regras linhas para examinar, já que uma declaração vazia passaria em tudo
sem ter sido examinada; e que a leitura do instrumento mais pobre não seja acusada de nada por dizer
menos, porque faltar-lhe um instrumento não é contradizer-se. No fim, lista as regras que algum
documento real exercita e que nenhum gerado alcança, que é a outra metade, a honesta, de uma
execução limpa.

## Correr o programa

Precisa de uma base de dados carregada, que fica como estava:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example generation
```
