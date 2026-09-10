**Português europeu.** Antes da aritmética: pode-se sequer calcular aqui?

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

O `xmllint` diz que um arquivo está bem formado. O `assets/sql/checks/` diz que não contradiz o
modelo. Nenhum dos dois responde à pergunta que este programa faz, que é se os números que estão
à frente de alguém podem sequer ser postos juntos, se ambos os operandos foram declarados, e se
são números da mesma coisa.

⭐⭐⭐ A COLUNA QUE IMPORTA É A QUE ESTÁ VAZIA. O `arithmetic/roster.sqlc` nomeia cada sítio onde
este modelo combina duas magnitudes e, ao lado de cada um, a regra que verifica se são
comensuráveis. Seis dos nove estão em branco, um sétimo é `(forbidden)`, e dois nomeiam uma regra.
O `r = n − d` é um dos que estão em branco: trinta e nove camadas de profundidade, e o
`layers/remainder.sqlc` transporta `d_unit` e `n_unit` como duas colunas separadas e subtrai de
uma à outra sem predicado nenhum em sítio nenhum.

⛔ UMA GUARDA EM BRANCO AO LADO DE UM ZERO NÃO É UMA PASSAGEM. Cada sítio sem guarda está hoje
limpo neste conjunto de documentos, que é precisamente o estado que se lê como seguro e não é.
O `NOT CHECKED` é impresso como `not checked`, nunca como `ok`, e essa distinção é a razão inteira
pela qual este exemplo existe.

⭐⭐ SUSPENSO É UM TERCEIRO DESFECHO AO LADO DE PASSOU E FALHOU. Noventa e uma instâncias não
podem ser calculadas porque alguém se recusou a medir um operando. Isso não é um defeito do
documento e também não é uma passagem, e as relações com filtro não o conseguem reportar: uma
linha deitada fora por um `WHERE` não consegue dizer porque é que se foi.

Correr com uma base de dados carregada:

```text
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example readiness
```

⛔ Não há salto silencioso. Sem base de dados, falha em vez de correr.
