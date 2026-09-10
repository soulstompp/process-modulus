**Português europeu.** A maquinaria faz o que afirma?

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

Os outros exemplos perguntam pela aritmética, pelos dados, pelo conjunto de documentos, e por
aquilo que se consegue fazer uma execução gerada dizer. Este pergunta pelas **próprias consultas**,
se cada relação calcula a operação que diz calcular. É o único que não pode acusar o arquivo de
ninguém.

⭐⭐⭐ EXISTE PORQUE UMA DIFERENÇA DE CONJUNTOS FALHA PARA UMA TABELA PLAUSÍVEL, NUNCA PARA UM
ERRO. O `EXCEPT` e o `LEFT JOIN … IS NULL` devolvem a forma certa, os nomes de coluna certos e uma
contagem credível quando estão errados. Escrito uma vez com os parênteses no sítio errado, o
`reports/integrity.sqlc` devolveu 227 linhas onde 0 era o correto, e 227 linhas bem formadas não
são coisa que alguém leia duas vezes.

⭐⭐ E A LEI É VERIFICÁVEL SEM TOCAR NUM FICHEIRO. |A ∖ B| = |A| − |A ⋉ B|, portanto uma diferença
e a sua semijunção têm de particionar o operando esquerdo. Como sonda manual isso é editar o
modelo, recompor, observar, reverter: um procedimento que nada repete, e no qual um `sed` que
silenciosamente não emparelha nada reporta um achado falso. Cada lei é uma consulta em vez disso.

⛔ A SEGUNDA AFIRMAÇÃO É A QUE MAIS IMPORTA. Cada diferença de conjuntos em `assets/sqlc/` tem de
constar do `algebra/roster.sqlc`. Uma diferença para a qual ninguém declarou uma lei é o
`unclaimed` do `asrt:Verdict`, uma guarda que se acredita estar lá e que nunca foi verificada.

⛔⛔ E UMA DAS LEIS NÃO É UMA CONSULTA, PORQUE NÃO PODIA SER. A §6 pergunta se alguma regra ainda
reporta que examinou NADA, e isso só é visível onde a população é nada, pelo que esvazia o conjunto
de documentos: um `TRUNCATE` dentro de uma transação que é revertida, o idioma que o
`examples/generation/main.rs` e o `assets/sqlc/invariance.sqlc` já usam. A base de dados que isto
lê é a base de dados que isto deixa.

⛔ É A ÚNICA ESCRITA QUE ESTE EXEMPLO FAZ, E TOMA UM BLOQUEIO `ACCESS EXCLUSIVE` ENQUANTO CORRE.
Portanto não é um exemplo para apontar a uma base de dados que outra pessoa esteja a ler, o que
faz parte do que custa correr e não apenas do que verifica.

# Cinco sítios onde as duas álgebras genuinamente diferem

O modelo é calculado duas vezes, como matrizes no `examples/matrices/main.rs` e como relações em
`assets/sql/`, e os dois são afirmados iguais em cada execução. ⚠️ Estes cinco são os sítios onde
o lado relacional NÃO se comporta como a intuição matricial espera, e cada um deles custou a alguém
um defeito aqui antes de ser escrito.

- O `σ` **acumula.** `σ_p(σ_q(A)) = σ_{p∧q}(A)`, que é a razão pela qual uma regra herda filtros
  que nunca escreveu e pela qual a sua população real vive em ficheiros que o seu autor não abriu.
- O `π` **não** distribui sobre `∖`. Projete-se primeiro e subtrai-se sobre menos atributos,
  portanto uma diferença tem de ser tomada sobre a chave.
- **Sacos não são conjuntos.** O `composition/descent` é um saco de propósito; deduplicá-lo
  destruiria o próprio facto que o `jagged_layer` existe para encontrar.
- ⛔ **O `γ`, e o `σ` seguido de `π`, são indistinguíveis por cardinalidade, e respondem a
  perguntas opostas.** O `S` tem chave `(filing, layer, buffer)` e o sujeito de cada regra tem
  chave `(filing, layer)`, pelo que o índice do amortecedor tem de ser colapsado. Agregá-lo lê a
  linha inteira; filtrar a um amortecedor e deitar fora a coluna lê uma célula. **Ambos dão a mesma
  chave, a mesma aridade e uma linha por camada**, pelo que cada lei do roster passa com qualquer
  dos dois, e nenhuma contagem em sítio nenhum os separa. Duas regras concluíram que a procura
  ficou não servida a partir de uma premissa sobre a coluna da capacidade apenas, que é uma
  afirmação sobre um de três amortecedores substituíveis. O sinal nunca está no SQL: está em que a
  prosa quantifica sobre a dimensão que a consulta deitou fora.
- ⛔ **Um `CASE` é uma partição por construção, pelo que a lei da partição não consegue ver
  predicados que se sobrepõem.** `Σ|classes| = |candidatos|` mantém-se qualquer que seja o
  comportamento dos braços, porque cada tupla cai em exatamente um deles faça o `p₁` e o `p₂` o
  que fizerem. A disjunção tem de ser sondada sobre os **predicados**, contando as linhas onde dois
  braços se verificam ao mesmo tempo. O `Fit` publica três critérios e chama-lhes mutuamente
  exclusivos; `clearance` e `interference` verificam-se ambos quando um valor nominal pontual
  iguala uma procura pontual, e o `layers/remainder.sqlc` resolve-o pela ordem dos braços.

⚠️ E um custo, medido e não assumido: **o `EXCEPT` é uma barreira de otimização.** Perguntar ao
`composition/owed_equality` por uma única camada composta avalia a árvore inteira e deita fora
tudo menos uma linha, porque uma diferença de conjuntos tem de materializar ambos os lados antes de
poder subtrair. A anti-junção de que foi convertido empurra o predicado da chave para dentro dos
três braços. A conversão foi feita por legibilidade, que é um ganho real; este é o seu preço.

Correr com uma base de dados carregada:

```text
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example soundness
```
