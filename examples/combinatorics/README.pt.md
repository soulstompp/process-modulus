**Português europeu.** O que se pode ler de uma classificação, e cada lei daqui lê aquilo que se confia que lê?

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

## O que faz

Cada relação em `assets/sqlc/` que arruma linhas em classes é uma função das suas linhas para um
conjunto de classes: um veredicto por sítio aritmético, uma situação por resto, uma pergunta por
ausência, um filho por ponto de composição. O que se pode ler de uma função assim é um problema
fechado, a **via dos doze** (*twelvefold way*, atribuída a Gian-Carlo Rota; Stanley,
*Enumerative Combinatorics* vol. 1, §1.9): três condições sobre a função cruzadas com quatro
leituras dela.

Este programa verifica essa tabela por um caminho que não sabe nada deste repositório, e depois
lê o repositório com ela. O `soundness` pergunta se cada operação de conjuntos calcula o que diz;
este pergunta que parte de uma função cada lei lê de facto, e portanto que falhas não consegue
ver. Nenhum dos dois acusa o arquivo de ninguém.

## A tabela

As bolas são linhas e as caixas são classes: `n` bolas, `x` caixas.

| leitura | em SQL | qualquer | injetiva | sobrejetiva |
|---|---|---|---|---|
| etiquetada | as linhas | `xⁿ` | `x(x−1)…(x−n+1)` | `x!·S(n,x)` |
| a menos das bolas | `GROUP BY caixa, count(*)` | `C(x+n−1, n)` | `C(x, n)` | `C(n−1, x−1)` |
| a menos das caixas | uma autojunção na caixa | `Σ_{k≤x} S(n,k)` | `[n ≤ x]` | `S(n,x)` |
| a menos de ambas | o perfil das contagens | `p_x(n+x)` | `[n ≤ x]` | `p_x(n)` |

- `S(n,k)` conta as partições de um conjunto em `k` blocos.
- `p_k(m)` conta as partições do inteiro `m` em `k` parcelas.
- Injetiva quer dizer no máximo uma linha por classe; sobrejetiva quer dizer todas as classes
  usadas.

### Como a tabela é verificada

A secção 1 do programa verifica cada célula para todos os `n` e `x` de 0 a 4, de três maneiras:

1. a forma fechada;
2. o número de valores distintos da leitura, calculada como o SQL a calcula;
3. o número de órbitas, encontrado aplicando por força bruta todas as permutações das bolas e das
   caixas.

Verifica também, função a função, que cada leitura é constante em cada órbita e separa quaisquer
duas. Portanto um `GROUP BY … count(*)` lê uma função exatamente a menos do nome das suas linhas,
uma autojunção exatamente a menos do nome das suas classes, e nenhum dos dois vê o que o outro
deita fora.

## O que decorre da tabela

### Uma lei de partição não diz nada sobre as classes

«Cada linha em exatamente uma classe» sobrevive a qualquer mudança de nome das classes, incluindo
uma mal escrita. Uma classe mal escrita num ramo passa uma lei assim, e qualquer contagem que
escolha classes pelo nome deixa-a cair. A contagem de `not comparable` que o
`examples/readiness/main.rs` fixa em zero é uma dessas contagens.

O conjunto das classes faz parte da função. As classes em que as consultas arrumam as linhas são
enums no esquema `public`, e um literal convertido para um enum é verificado quando a consulta é
analisada, pelo que uma classe mal escrita falha em todas as execuções, chegue ou não alguma linha
ao seu ramo.

### O `GROUP BY` não consegue mostrar uma classe vazia

O `GROUP BY` enumera as classes que alguma linha tomou, nunca as classes que existem: lê uma função
sobre a sua imagem. Uma classe vazia não tem onde aparecer, e uma classe vazia é muitas vezes a
descoberta. Parta-se do conjunto declarado e faça-se `LEFT JOIN` das linhas, contando uma coluna
das linhas em vez de `*`, e o zero passa a ser uma linha. A secção 3 faz isto para cada
classificação.

### Uma soma precisa de que a função seja injetiva; uma união não

`Σ_linhas w(f(linha)) = Σ_classe |f⁻¹(classe)|·w(classe)`.

- Numa dobra idempotente (uma união, `max`, `bool_or`, `EXISTS`) a multiplicidade de cada classe
  desaparece e só a imagem conta.
- Com `+` conta cada multiplicidade, e o excesso sobre a imagem é `Σ (k − 1)·w`.

Esse excesso é a eliminação `e` em `x_composed = Σ x_parts − e`. É por isso que um modelo que
compõe um filho duas vezes é banal, enquanto uma fusão que chega duas vezes a uma camada é uma
violação: uma consulta é idempotente e uma oferta não é.

### O tamanho de uma autojunção fica fixado pelos tamanhos dos grupos

Numa chave cujos grupos têm tamanhos `k`, uma autojunção devolve:

| emparelhamento | linhas |
|---|---|
| ordenado, com o par reflexivo | `Σ k²` |
| ordenado, sem o par reflexivo | `Σ k(k−1)` |
| não ordenado, cada par uma vez | `Σ C(k,2)` |

Um par não é uma contagem dupla quando um grupo tem três. Somar todos os totais que partilham uma
parte conta-a `k` vezes, um excesso de `k − 1` sobre contá-la uma vez, enquanto os pares são
`C(k,2)`; o excesso e os pares só coincidem quando `k` é 1 ou 2. Provado em `src/proofs/README.md`,
entradas `self_join_sizes` e `excess`.

### Uma reetiquetagem nunca funde

Uma reetiquetagem é uma permutação das classes. Trocar duas classes numa linha que tem ambas troca
as suas palavras e mantém cada valor. Essas linhas são o teste mais exigente de uma afirmação de que
uma regra não pode reparar na palavra, porque são as únicas onde uma regra poderia comparar as
duas.

## As secções

1. **A própria tabela**, de três maneiras. Esta parte não precisa da base de dados.
2. **As composições**: o DAG de composição lido como *ponto de composição → modelo*. Imprime as
   arestas, quantos pontos caem em cada modelo, que pais compõem um conjunto idêntico de filhos, e
   o perfil. Os modelos que nada compõe encontram-se lendo a pasta, porque nenhuma aresta os pode
   nomear.
3. **Cada classificação contra as classes que declara**, incluindo as vazias. Afirma que cada
   conjunto de classes declarado no esquema `public` é lido aqui, tirando essa lista do catálogo.
   Uma classe vazia é impressa como encaminhamento, nunca afirmada.
4. **O censo das ausências, uma pergunta de cada vez.** O `epistemics/absences.sqlc` afirma cada
   ausência tipificada do esquema, e o `reports/integrity.sqlc` confronta a sua lista de perguntas
   com cada coluna do tipo `absence_reason`. Esta secção conta as linhas de cada pergunta contra as
   ausências registadas na coluna que ela nomeia, com uma consulta construída a partir do catálogo
   que não partilha nada com o ramo que verifica. Uma pergunta sem nada registado é zero contra
   zero, e é impressa à parte em vez de contada como concordância.
5. **As duas autojunções de `F`**, contra os tamanhos de grupo que fixam o seu número de linhas.
   As duas relações defendem a sua condição de junção nos cabeçalhos, e esta secção é o que faz
   essas afirmações falharem quando a condição muda.

## Como correr

Precisa da base de dados de prova. Lê essa base de dados e não escreve nada.
