**Português europeu.** O que o conjunto de documentos diz de facto, e se alguma coisa está a olhar.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

O `examples/matrices/main.rs` prova que a aritmética concorda consigo mesma. O
`examples/readiness/main.rs` pergunta se pode ser efetuada. Este faz perguntas ao conjunto de
documentos e imprime as respostas, porque uma relação cujo produto é conhecimento e não um
veredicto não tem outro sítio onde aterrar e acaba escrita e lida por ninguém.

⭐⭐⭐ CADA NÚMERO QUE UM COMENTÁRIO DESTE REPOSITÓRIO CITA DEVIA SER IMPRESSO POR UM PROGRAMA. Uma
figura escrita num cabeçalho está correta no dia em que é escrita e depois não responde a nada: o
conjunto de documentos move-se e a frase não. É aqui que são impressas as que de outro modo
ficariam em prosa.

⛔⛔ OS DENTES ESTÃO NA PERGUNTA QUE NÃO FOI FEITA, NUNCA NA RESPOSTA. Duas afirmações: que nenhuma
relação e nenhum documento é alcançado por nada, e que a cada resto já foi posta a pergunta do
fecho. Nenhuma julga um arquivo. `unbounded` é o estado honesto para um documento escrito para
discutir três camadas, e um transbordo é um ENCAMINHAMENTO, um arquivo não é o sistema, e a
observação de um segundo documento é uma projeção sobre este e não uma acusação contra ele.

# Elementos neutros, e onde uma ausência se pode fazer passar por um

A §14 abaixo pergunta quais das quatro razões de ausência cada pergunta já tomou. Esta é a regra
que decide quais delas uma posição do esquema pode sequer oferecer.

Cada quantidade neste modelo entra numa soma ou num produto. As três folgas de amortecedor são
substitutas e somam-se: `inventory + capacity + time`, neutro 0. Um ciclo de serviço multiplica:
`entregue = taxa × janela ÷ período`, neutro 1. Um fator de conversão e um quantum também
multiplicam.

Onde uma gramática admite tanto um valor como uma ausência tipada numa posição, e a ausência pode
ser lida como o neutro dessa operação, as duas são duas grafias de um só facto. **A ausência é a
grafia com perdas.** Não transporta unidade, nem autor da exatidão, nem origem, pelo que quem
recebe não a consegue comparar como aritmética com quem arquivou um número.

⭐⭐ **A regra que se segue: onde o braço do valor nomeia o caso degenerado, o braço da ausência
não pode conseguir dizer a mesma coisa.** Uma folga de zero é a menor folga e é arquivada
`[0, 0, 0]` na unidade em que é zero. Uma oferta que corre continuamente tem fração de serviço de
um e é arquivada como um período inteiro, citado na unidade do próprio período, transportando a
origem que diz quem o poderia encurtar. Um resto de zero é um ajuste de folga, arquivado com sinal
e quantidade `[0, 0, 0]`, porque o caso linha-a-linha da ISO 286 é uma folga cuja folga mínima é
zero.

Um elemento neutro pode viver numa ausência, mas só quando o neutro é **forçado**. Duas condições,
e ambas exigidas: o neutro tem de decorrer de estrutura que o documento já declara, para que não
haja autor a nomear nem nada para alguém assinar; e a ausência não pode deitar fora mais nada que
o valor transportaria. Um fator de conversão entre duas unidades idênticas é forçado, porque é a
igualdade das unidades que o torna um, e um fator não transporta mais nada. Uma fração de serviço
de um **não** é forçada: uma linha pode correr continuamente porque não pode parar, porque alguém
o prometeu, ou porque alguém a guarneceu, e a ausência perde qual. Um resto de zero é forçado por
um valor nominal igual a uma procura, e ainda assim não pode ser uma ausência, porque a ausência
deita fora o sinal e os detentores.

⛔ E «forçado» é uma afirmação sobre que documentos conseguem ALCANÇAR a ausência, pelo que só é
verdade onde uma regra a torna verdade. Uma conversão é exigida sempre que as unidades diferem, o
que deixa um fator omitido a significar uma coisa só: as unidades já concordam. Onde nenhuma regra
confina uma ausência ao caso forçado, o valor pertence ao documento.

⭐ **O resíduo é o caso honesto, e é uma terceira operação e não uma exceção.** Uma seleção de um
conjunto fechado tem neutro ∅: nenhum amortecedor absorveu o resto, ninguém fixa este limite,
alguém procurou acoplamentos e as camadas movem-se independentemente. Nada disso tem tamanho,
unidade ou autor, pelo que nada se perde ao recusar o elemento, e essas posições mantêm o
vocabulário de ausência de quatro membros por inteiro. A §14 é onde se vê quais é que de facto o
mantêm.

Correr com uma base de dados carregada:

```text
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example observations
```
