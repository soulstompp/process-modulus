**Português europeu.** Em que classe cai cada linha, e cada consulta conta mesmo aquilo que diz contar?

> **Grafia do AO90.** Também disponível em inglês: `examples/combinatorics/README.md`.

Quando uma consulta reparte as linhas de uma relação por classes, há duas maneiras de falhar sem dar
erro nenhum: uma classe que o tipo declara e onde nunca cai nada, sem que alguém repare que está
vazia, e uma consulta que diz contar uma coluna e afinal conta outra. Este programa lê da base de
dados carregada todas as classificações que as consultas fazem e todas as perguntas do censo das
ausências, e põe cada uma ao lado daquilo que diz ler; antes disso, porém, confirma que as maneiras
de contar de que o SQL dispõe contam mesmo o que se julga que contam.

## O relatório, secção a secção

A secção 1 não lê nada do repositório. Distribui poucas coisas por poucos lugares e conta as
distribuições de quatro maneiras: as próprias linhas, quantas coisas caem em cada lugar com nome (um
`GROUP BY` com `count(*)`), que coisas partilham um lugar (uma autojunção pelo lugar) e, por fim, só
o perfil das contagens. Cada número sai por três caminhos que nada partilham, a conta direta, a
leitura feita como o SQL a faz e a força bruta, que troca coisas e lugares de todas as maneiras
possíveis, e os três têm de coincidir em todas as células; fica assim assente que um `GROUP BY` sabe
quantas coisas há em cada lugar sem saber quais, que uma autojunção sabe quais andam juntas sem
saber onde, e que nenhum dos dois vê o que o outro deita fora.

As composições de `assets/sqlc/` leem-se da mesma maneira na secção 2, em que cada encaixe feito por
um `:compose` é uma coisa a cair num lugar, o ficheiro encaixado: saem daí os ficheiros que mais
vezes são encaixados, os que ninguém encaixa e que só se encontram percorrendo a pasta, os pais que
compõem exatamente os mesmos filhos e o perfil inteiro das contagens. Um pai que encaixa duas vezes
o mesmo filho não faz mal nenhum, já que uma consulta lida duas vezes dá o mesmo que lida uma, ao
passo que uma oferta somada com `+` contaria a dobrar.

Na secção 3, cada classificação aparece ao lado das classes que declara, com as linhas que caem em
cada uma, e uma classe vazia fica listada como constatação e não como falha; o programa
recusa-se, isso sim, a acabar se algum tipo enumerado de `assets/ddl/schema.ddl` não for lido por
classificação nenhuma, porque então ninguém veria quais das suas classes estão vazias. A secção 3b
conta as mesmas classes duas vezes, uma no corpus e outra nas fixtures.

O censo das ausências percorre-se na secção 4 pergunta a pergunta, e o número que o censo dá a cada
uma tem de ser o número de valores preenchidos na coluna que ela diz ler, contados por uma consulta
que nada partilha com o censo. Duas perguntas que reclamem a mesma coluna, ou uma pergunta repetida,
param o programa; as que não têm nada declarado aparecem à parte, zero contra zero, sem dizerem nada
nem num sentido nem no outro.

Resta a secção 5, com as duas autojunções do modelo, `composition/sibling_parts.sqlc` e
`eliminations/derived.sqlc`: quantas linhas cada uma devolve fica decidido por quantas linhas
partilham cada chave e pela maneira de as emparelhar, com ou sem ordem e com ou sem o par de uma
linha consigo mesma, pelo que o programa calcula esse número antes de o comparar com o que a junção
devolveu.

## O que fica à vista

Um zero numa classe não diz sempre o mesmo. No corpus, quer dizer que nenhuma declaração real chegou
ainda àquele estado, o que é uma constatação sobre aquilo que se sabe; nas fixtures, quer dizer que
nenhuma estipulação o exercita, o que é uma falha na cobertura do próprio repositório. Somadas as
duas colunas, a classe acende-se por qualquer dos lados e nenhuma das duas perguntas fica
respondida, e é por isso que a secção 3b as mantém separadas e que `reports/class_census.sqlc`
recebe o conjunto de documentos num encaixe e se compõe duas vezes, em vez de levar um `WHERE`.
Quanto às listas do que só uma estipulação acende e do que só o corpus acende, não têm de estar
vazias, já que a primeira é uma afirmação sobre o mundo que lei nenhuma decide e a segunda uma
fixture que ainda ninguém escreveu; o que se pode decidir, que cada classe tem uma situação
declarada e que essa situação condiz com a contagem, decide-o `algebra/class_domain.sqlc`.

## Correr o programa

Precisa da base de dados carregada com o corpus:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example combinatorics
```
