# Como se reconhece uma lista alheia reescrita num corpus que já existe

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`conformance/adoption.md`](../../conformance/adoption.md).

Quem adota o modelo raramente parte do zero: traz consigo um corpus, com tabelas, registos e
programas que já funcionam, e o que o esquema lhe pede, antes de mais, é que reconheça nesses
ficheiros as formas que ele recusa. Esta página não pede alteração nenhuma ao esquema, descreve
antes três sinais que se procuram num corpus existente, cada qual com o seu remédio, e os três têm
isto em comum: o que está escrito está certo dentro do projeto que o escreveu, e o defeito só se vê
de fora, quando outra pessoa tem de ler aqueles dados ao lado dos seus.

## O sinal de uma lista reescrita

Uma coluna com nome de taxonomia, que guarda valores e nenhum URI, eis o sinal. Os valores vêm de
uma lista que outra autoridade publica, um normativo, uma forma jurídica, um escalão de entidade, e
entraram no corpus sem a autoridade que os define, de modo que o corpus fica com a sua própria cópia
da lista; e uma cópia, essa, é uma bifurcação, que se afasta da original à primeira revisão sem que
nada no corpus dê por isso, ao passo que quem recebe um desses valores não sabe de que lista vem nem
que edição dela se leu. O remédio é o termo emprestado, em que cada valor leva ao lado a taxonomia
de onde veio, o `taxonomy` junto do `value`, e a lista fica onde a autoridade a publica.

### Três autores que não se leram

O mesmo engano aparece em três autores que não se leram uns aos outros, cada um a escrever à sua
maneira o mesmo conjunto emprestado, sem a autoridade:

| | a reescrita |
|---|---|
| uma tabela de referência | uma coluna chamada, à letra, `taxonomy_reference`, com os valores nus e nenhum URI em todo o ficheiro |
| um programa | uma enumeração com as quatro variantes do mesmo conjunto |
| um registo | uma forma jurídica estatutária nacional, em texto livre |

Nenhum dos três é um erro dentro do seu próprio projeto, cada um está certo e sem ambiguidade onde
vive, e a bifurcação só aparece quando dois corpora que reescreveram a mesma lista têm de ser lidos
juntos e nada neles diz que a lista é uma só. É por isso que o sinal vale mais do que a regra, uma
vez que ninguém corrige um engano que não reconhece em si próprio.

## A autoridade está ao lado, onde nenhuma consulta chega

A tabela de referência, essa, não está sem autoridade. Ao lado dela há um ficheiro de prosa que a
regista por inteiro e com todo o cuidado, o diploma e os seus anexos, a autoridade emissora como
autora, três artefactos cada um com o seu `sha256`, qual dos três é a lei, os intervalos de páginas
e uma regra de citação explícita, a de citar a data do diploma e nunca a do ficheiro; e nada
consegue ligar por ali, porque uma nota de fonte ao lado de uma tabela não se junta a valor nenhum
dela. Uma taxonomia que nenhuma consulta alcança não é uma autoridade transportada.

Quem adota não tem nisto uma acusação, antes pelo contrário: conhece a autoridade e não tem onde a
pôr, e uma casa em falta é a lacuna de adoção mais barata de fechar,
pois basta levar o URI da autoridade para o lado de cada valor, num `BorrowedTerm`, para que a nota
de fonte deixe de ser a única a sabê-lo.

## Num campo em branco, o mesmo sinal: a `Absence`

Um campo em branco cuja razão vive numa nota em texto livre é o sinal que acompanha o primeiro. A
medição pergunta se cada coluna em branco tem uma coluna irmã com a razão, uma por onde uma consulta
possa ligar, e uma razão escrita numa nota longa conta como ausente, de propósito. O espécime mais
claro é um registo que deixa vazia, por querer, uma forma jurídica, com um parágrafo excelente ao
lado a explicar porquê, e nada consegue ligar por esse parágrafo: uma razão que nenhuma consulta
alcança não é uma ausência tipificada, e quem a põe numa nota cumpre a letra do esquema e perde-lhe
o benefício todo.

Com o sinal vem uma ressalva. Há brancos cujo sentido é imposto por uma regra num verificador, o que
continua a não ser uma razão que se alcance a partir da linha, mas também não quer dizer que quem
adota não saiba o que os seus brancos significam; quer dizer que esse saber não está no documento,
que é um problema diferente e muito mais fácil de resolver. O remédio é a `Absence`, com o `reason`
a dizer `none`, `unmeasured` ou `notApplicable`, e a `note` ao lado da razão, nunca em vez dela.

## Quando o que falta é um papel inteiro

O terceiro sinal já não está num valor mas num papel: um elemento que se repete e cujo vazio tem de
querer dizer duas coisas, «ninguém foi ver» e «alguém foi ver e não há nada», sem irmão nenhum que
diga qual delas. Vê-se num perfil cuja raiz é uma escolha sem limite sobre os seus papéis, um
`xs:choice` com `minOccurs="0"` e `maxOccurs="unbounded"`, ou em qualquer repetição cuja ausência
não tem para onde ir, e também aqui nada está errado no projeto de quem o escreveu, já que é XSD
válido e corrente. O custo só aparece quando um leitor que não conseguiu preencher um papel tem de
emitir um documento e encontra o vazio desse papel já tomado pelo outro sentido, de modo que a fonte
que o leitor não pôde usar e a fonte que de facto não reportou nada saem iguais, byte a byte.

O remédio é o invólucro que o esquema base já mostra duas vezes, as `StatedCouplings` no `couplings`
de cada `Stack` e as `asrt:StatedEliminations` no `eliminations` de cada `Fusion`, ambos
obrigatórios no elemento de cima, para que a posição exista antes das linhas e um papel que ninguém
preencheu tenha onde dizer porquê. A fonte que o leitor não pôde usar declara-se então `unmeasured`,
com o `Absence/provenance/party` a nomear o leitor, e a que nada reportou declara-se `none`, em nome
de quem declara, e uma consulta separa as duas sem ler nota nenhuma. A anotação do
`Coupling/strength` diz o mesmo de um elemento opcional, que diria as duas coisas exatamente da
mesma maneira.

Regra nenhuma consegue fazer pressão aqui, porque as regras correm sobre as relações do modelo base
e o modelo de conteúdo de um perfil não está no corpus, pelo que isto fica como orientação e não
como verificação. Também este sinal traz a sua ressalva: um papel cujo vazio só pode querer dizer
uma coisa não precisa de invólucro, e um corpus que ninguém monta a partir de outras fontes não tem
o problema, de maneira que vale sobretudo a pena procurá-lo num perfil cujos documentos são
construídos por um programa.

## De onde vêm as medições

As medições por trás destes sinais são de um corpus que não foi escrito para este esquema, contadas
pela própria parte, só em leitura e num commit identificado, e este repositório não vê esse corpus,
pelo que as reporta e não as reproduz. Contam colunas em tabelas, e dizem por isso o que um
documento leva e não o que quem adota sabe, que é a razão de a tabela de referência contar como sem
autoridade apesar da nota de fonte ao lado, e de essa contagem continuar certa. Os números que
importam estão escritos onde o esquema os declara, na anotação da `Absence`, e esta página não
repete nenhum, porque uma figura copiada para aqui seria uma segunda cópia que ninguém volta a
contar.
