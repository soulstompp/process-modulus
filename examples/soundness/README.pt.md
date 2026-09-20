**Português europeu.** A maquinaria faz o que afirma?

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

## O que faz

Os outros exemplos perguntam pela aritmética, pelos dados, pelo conjunto de documentos, e por
aquilo que se consegue fazer uma execução gerada dizer. Este pergunta pelas **próprias consultas**:
se cada relação calcula a operação que diz calcular. As suas leis não acusam declaração nenhuma,
com uma exceção no fim: se os documentos carregados obedecem de todo às regras.

## Porque existe

Uma diferença de conjuntos falha para uma tabela plausível, nunca para um erro. O `EXCEPT` e o
`LEFT JOIN … IS NULL` devolvem a forma certa, os nomes de coluna certos e uma contagem credível
quando estão errados. Um par de parênteses no sítio errado em `reports/integrity.sqlc` produz
centenas de linhas bem formadas onde a resposta certa é nenhuma, e nada nelas convida a uma
segunda leitura.

## O que verifica

### Cada diferença cumpre a sua lei

`|A ∖ B| = |A| − |A ⋉ B|`, portanto uma diferença e a sua semijunção têm de particionar o operando
esquerdo. Verificado à mão, isso é editar o modelo, recompor, observar e reverter: um procedimento
que nada repete, e no qual um `sed` que silenciosamente não emparelhou nada reporta um achado
falso. Aqui cada lei é uma consulta.

### Cada diferença tem uma lei

Cada diferença de conjuntos em `assets/sqlc/` tem de constar do `algebra/roster.sqlc`. Uma
diferença para a qual ninguém declarou uma lei é o `unclaimed` do `asrt:Verdict`: uma guarda que se
acredita estar lá e que nunca foi verificada. Esta é a afirmação que mais importa.

### Cada conversão lê o sinal de uma só maneira

Onde um fator de conversão multiplica algo, o operador é sempre o mesmo:
`least(x · φ_low, x · φ_high)` no limite inferior, o seu gémeo `greatest` no superior, e a moda um
produto simples. O sinal do operando escolhe o canto, e a lista `CONVERSIONS` neste programa declara
o que cada sítio faz com ele e porquê. A árvore é confrontada com essa lista nos **dois** sentidos:
um modelo que comece a multiplicar falha a compilação até dizer que leitura toma, e um sítio
declarado que deixe de multiplicar também falha.

⛔ Contar sítios não encontra uma segunda leitura, porque cada grafia é um sítio só.
`composition/converted.sqlc` lia o canto enquanto `algebra/fusion_sum.sqlc`, a lei escrita para o
corroborar por uma segunda via, multiplicava limite a limite. São duas funções diferentes. Concordam
em todos os operandos não negativos, nenhum operando declarado é negativo, e por isso todas as leis
aqui ficaram verdes durante uma passagem inteira enquanto a lei e a relação que ela verifica
discordavam sobre a aritmética. **Uma lei que calcula a função errada não é independente da relação,
está errada sobre ela**, e o que mantém as duas vias separadas é o que leem e não como multiplicam.

### Cada valor recalculado coincide

Algumas leis comparam valores e não linhas. Uma lei de valor recalcula um valor a partir dos totais
declarados e confronta com o resultado a relação que o calcula, sujeito a sujeito: o resto cruzado,
a sua grandeza e o seu ajuste, a exposição, a divisão de um resto em unidades, a soma de uma fusão
por quantidade, o quantum composto e o resto composto. A aritmética em que cada uma assenta está
provada na página das provas, `src/proofs/README.md`, com os mesmos valores, e a página nomeia a lei
ao lado de cada entrada.

### O espaço de ciclos do grafo de camadas concorda com a regra
O grafo de composição `F` e o grafo de unidades `Φ` ficam em lados opostos de uma só decomposição.
O espaço de arestas de um grafo é o seu espaço de cortes mais o seu espaço de ciclos, e este
modelo põe uma regra em cada um: um equilíbrio num nó é a regra da fusão, uma soma ao longo de um
ciclo é a regra da conversão. Portanto o `F` não pode ter nada na sua metade de ciclos, enquanto
se espera que o grafo de unidades tenha algo na dele.

⭐ Um ciclo não dirigido no `F` **é** uma camada a chegar duas vezes sob uma só dobra, pelo que o
`rank/cycle_space` e o `checks/jagged_layer` não podem discordar, e não partilham código nenhum. A
lei confronta-os um com o outro em zero contra não-zero e nunca nas duas contagens: o espaço de
ciclos conta ciclos independentes, a regra conta fusões em infração, e um ciclo pode acusar mais
do que uma. A sua própria não-vacuidade é uma coluna, porque `0 = 0` é verdade de um grafo vazio e
de uma regra que não examinou nada.

### O conjunto de documentos é sujeito às suas próprias regras
O `algebra/conforms` pergunta a cada regra do `checks/roster.sqlc` se algum documento carregado a
viola, e a execução falha quando algum viola. As regras reportam e não fazem falhar nada por si,
pelo que é aqui que um documento em infração para a compilação. É a única lei aqui sobre a
evidência e não sobre a maquinaria, e está no mesmo roster porque uma violação impressa e aprovada
na mesma é o
mesmo verde que não queria dizer nada.

### Uma regra sem nada para examinar continua a dizê-lo

Uma das leis não pode ser uma consulta. A secção 6 pergunta se uma regra ainda reporta que não
examinou nada, o que só é visível onde a população está vazia, pelo que esvazia o conjunto de
documentos com um `TRUNCATE` dentro de uma transação que é revertida. O
`examples/generation/main.rs` e o `assets/sqlc/invariance.sqlc` usam o mesmo idioma. A base de
dados que lê é a base de dados que deixa.

⚠️ Esse `TRUNCATE` é a única escrita que este exemplo faz, e toma um bloqueio `ACCESS EXCLUSIVE`
enquanto corre. Não aponte este exemplo a uma base de dados que outra pessoa esteja a ler.

## Cinco sítios onde as duas álgebras diferem

O modelo é calculado duas vezes, como matrizes no `examples/matrices/main.rs` e como relações em
`assets/sql/`, e os dois são afirmados iguais em cada execução. Estes cinco são os sítios onde o
lado relacional não se comporta como a intuição matricial espera, e cada um causou aqui um
defeito.

### O `σ` acumula

`σ_p(σ_q(A)) = σ_{p∧q}(A)`. É por isso que uma regra herda filtros que nunca escreveu, e que a sua
população real vive em ficheiros que o seu autor não abriu.

### O `π` não distribui sobre `∖`

Projete-se primeiro e subtrai-se sobre menos atributos, portanto uma diferença tem de ser tomada
sobre a chave.

### Sacos não são conjuntos

O `composition/descent` é um saco de propósito. Deduplicá-lo destruiria o próprio facto que o
`jagged_layer` existe para encontrar.

### O `γ` e o `σπ` parecem iguais e respondem a perguntas opostas

O `S` tem chave `(filing, layer, buffer)` e o sujeito de cada regra tem chave `(filing, layer)`,
pelo que o índice do amortecedor tem de ser colapsado. Agregá-lo lê a linha inteira; filtrar a um
amortecedor e deitar fora a coluna lê uma célula. Ambos dão a mesma chave, a mesma aridade e uma
linha por camada, pelo que cada lei do roster passa com qualquer dos dois e nenhuma contagem os
separa. Uma regra que conclui que a procura ficou por servir a partir da coluna da capacidade
apenas fez uma afirmação sobre um de três amortecedores substituíveis. O sinal nunca está no SQL:
está em que a prosa quantifica sobre a dimensão que a consulta deitou fora.

⭐ **Há um caso legítimo, e é demonstrável em vez de discutível.** Onde a dimensão deitada fora é
CONSTANTE NA CHAVE, a fatia e o agregado são a mesma relação, pelo que a pergunta toda é se ela é
constante. O `units/conversions.sqlc` lê o grafo de conversões inteiro a partir de
`quantity = 'nameplate'`, o que é sólido exactamente enquanto uma camada nomear uma só unidade em
todas as suas quantidades. O `algebra/layer_units` sustenta-o como dependência funcional,
`|π(layer, unit)| = |π(layer)|`, que é o que `form = 'dependency'` no roster quer dizer: uma licença
que corre sempre que as leis correm, em vez de uma frase no cabeçalho do ficheiro que fixa o valor a
dizer ao leitor que corra uma consulta. Uma dimensão que ninguém consegue mostrar constante deixa o
`σπ` exactamente onde o parágrafo acima o deixa.

### Um `CASE` não consegue mostrar braços que se sobrepõem

Um `CASE` é uma partição por construção, pelo que `Σ|classes| = |candidatos|` se mantém qualquer
que seja o comportamento dos braços: cada tupla cai em exatamente um braço, faça o `p₁` e o `p₂` o
que fizerem. A disjunção tem de ser sondada sobre os predicados, contando as linhas onde dois braços
se verificam ao mesmo tempo. O `Fit` publica três critérios e chama-lhes mutuamente exclusivos, mas
`clearance` e `interference` verificam-se ambos quando um valor nominal pontual iguala uma procura
pontual; o `layers/remainder.sqlc` resolve-o pela ordem dos braços.

## Um custo: o `EXCEPT` é uma barreira de otimização

Perguntar ao `composition/owed_equality` por uma única camada composta avalia a árvore inteira e
deita fora tudo menos uma linha, porque uma diferença de conjuntos tem de materializar ambos os
lados antes de poder subtrair. A anti-junção que substituiu empurra o predicado da chave para
dentro dos três braços. A conversão foi feita por legibilidade, que é um ganho real, e este é o
seu preço.

## Como correr

Precisa de uma base de dados carregada:

```text
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example soundness
```
