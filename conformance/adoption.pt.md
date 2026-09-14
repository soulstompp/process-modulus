# Reconhecer um conjunto reenunciado num corpus que já se tem

> **Português europeu, grafia do AO90.** A versão inglesa está em [`adoption.md`](adoption.md) e
> é a que o repositório trata como autoritativa quando as duas divergirem. Os nomes dos tipos e
> dos elementos do XSD ficam em inglês, porque são os nomes do esquema.

**Orientação, e não uma alteração ao esquema.** Um adotante não pode agir sobre uma regra
que não se reconhece a infringir, e as regras sobre as quais este esquema é construído são
todas infringidas por trabalho que é localmente correto. Nada do que se segue é um defeito
no projeto onde foi encontrado.

Ver o `BorrowedTerm` e a `Absence` no esquema base para as regras em si. Este ficheiro é só
sobre o aspeto que infringi-las tem visto de dentro.

## A assinatura de um conjunto reenunciado

> Uma coluna com o nome de uma taxonomia, a conter valores, sem URI nenhum em parte alguma do
> ficheiro.

É esse o indício todo, e vale a pena procurá-lo com grep. Um corpus medido trazia uma coluna
chamada literalmente `taxonomy_reference` a conter valores nus ao longo de cerca de mil
linhas, sem autoridade de nomenclatura nenhuma no ficheiro.

### Três autores sem relação entre si cometeram um erro só, e é isso a prova

O mesmo conjunto emprestado de quatro valores foi reenunciado de três maneiras por pessoas
que não se tinham lido umas às outras:

| | o reenunciado |
|---|---|
| uma tabela de referência | uma coluna com o nome de uma taxonomia, a conter valores nus |
| um programa | uma enumeração de quatro variantes do mesmo conjunto |
| um registo | uma forma jurídica nacional e estatutária, em texto livre |

Nenhum dos três é um defeito no projeto de onde vem. Cada um está localmente correto e é
localmente inequívoco. Os valores significam exatamente o que os seus autores quiseram, e
nada dentro desses projetos está errado. A bifurcação só é visível de fora, que é
precisamente o argumento que o `BorrowedTerm` faz, e aqui é uma ocorrência em vez de uma
dedução a partir de princípios.

O que uma bifurcação custa não é imediato. Um conjunto reenunciado não deriva no dia em que é
copiado. Deriva quando a autoridade revê o dela, e nada na cópia o consegue notar.

## A autoridade não está em falta, está inalcançável, e é esse o resultado mais incisivo

Ao lado do maior dos três está uma nota de origem que regista a autoridade por completo: o
diploma legal e os seus anexos, o organismo emissor, três artefactos cada um com a sua soma
de verificação, qual dos três é a lei, os intervalos de páginas, e uma regra explícita sobre
que data citar.

> A autoridade não está em falta. Está em prosa, num ficheiro irmão, e inalcançável a partir do
> valor.

Uma nota de origem ao lado de uma tabela está para o `BorrowedTerm` exatamente como uma nota
explicativa longa está para a `Absence`: excelente, correta, e fora do alcance de uma
consulta. É a regra da própria `Absence`, a de que uma razão que consulta nenhuma alcança
não é uma ausência tipificada, a chegar um tipo ao lado.

Isso torna a reparação pequena, e faz o adotante parecer bom em vez de descuidado. Têm a
autoridade e casa nenhuma onde a pôr. Acrescentar a casa é o género mais barato de lacuna de
adoção que há para fechar.

## A assinatura companheira, para a `Absence`

> Um branco cuja explicação vive numa nota de texto livre em vez de numa coluna irmã por onde
> uma consulta possa ligar.

O espécime mais claro encontrado até agora é um registo que declara uma forma jurídica vazia
de propósito, com um parágrafo excelente ao lado a dizer porquê. Nada consegue ligar por
aquele parágrafo. Quem adote e ponha a razão numa nota cumpriu a letra deste esquema e
perdeu todo o benefício dele.

A ressalva em sentido contrário viaja com ela. Um branco cujo significado é imposto por uma
regra num verificador continua a não ser uma razão alcançável a partir da linha, mas isso
não quer dizer que o adotante não saiba o que os brancos dele significam. Quer dizer que o
conhecimento não está no documento, que é um problema diferente e muito mais fácil de
reparar.

## Uma terceira assinatura, para um papel e não para um valor

> Um elemento repetível cujo vazio tem de significar duas coisas, sem irmão nenhum que diga
> qual.

As duas primeiras assinaturas são sobre um valor: um termo sem autoridade, um branco sem
razão. Esta é sobre um papel. Quem adote e modele um papel como um elemento repetível nu, ou
como uma escolha sem limite na raiz de um perfil, escreveu XSD válido e idiomático, e nada
dentro do projeto está errado. Um documento que não traga nenhum desse papel é vulgar, e
muitas vezes é ele o resultado.

O custo só aparece quando é outra coisa que não quem declara a montar o documento. Um leitor
que vá a fontes que não controla tem três maneiras vulgares de voltar sem nada: a fonte não
estava lá, a fonte não tinha um campo que o papel exige, ou um vocabulário fechado recusou o
valor pelo nome. Cada uma delas emite o mesmo papel vazio que uma fonte que genuinamente não
reportou nada, e essas são afirmações opostas. A assimetria é o que lhe põe o preço: um zero
verdadeiro reportado como falha é um falso alarme e anuncia-se, ao passo que uma falha
reportada como zero verdadeiro é falsa confiança e ninguém vai investigar, porque nada
parece estar mal.

⛔ A reparação não é uma alteração ao esquema. O esquema base demonstra a forma duas vezes,
nas `StatedCouplings` e nas `asrt:StatedEliminations`: uma escolha entre o elemento
repetível e uma `Absence`, cada uma obrigatória no seu pai, para que a casa exista antes de
existirem as linhas. A `Absence` transporta então a razão, e a `provenance` dela separa a
lacuna de um leitor do zero de quem declara, porque quem diz que uma coisa não está medida é
ele próprio informação. «Ninguém foi ver» e «alguém foi ver e não encontrou nada» passam a
ser duas declarações em vez de uma lista vazia.

Exigir o invólucro é barato pela razão que a `AbsenceReason` dá: um elemento só é caro de
exigir quando quem envia tem de inventar um valor para o satisfazer, e uma vez que uma
ausência tipificada seja resposta legítima quem envia pode sempre responder honestamente. O
esquema base já pôs preço à alternativa uma vez, no `Coupling/strength`, onde um elemento
opcional e uma ausência tipificada diziam a mesma coisa de duas maneiras, e a anotação de lá
regista para qual das duas um corpus se virou.

A ressalva em sentido contrário viaja também com esta. Um papel cujo vazio só pode
significar uma coisa não precisa de invólucro nenhum, e um corpus que ninguém monta não tem
o problema de todo: quem escreve o seu próprio documento sabe o que deixou de fora, e o
silêncio dele é uma afirmação. Vale a pena procurar esta assinatura num perfil cujos
documentos são construídos por um programa.

## Sobre as medições por trás disto

As contagens por trás destas assinaturas estão limitadas a registos tabulares, ou seja, a
colunas em ficheiros com forma de CSV, e não se generalizam para além disso. ⛔ Nenhuma
figura é aqui reenunciada, deliberadamente. As assinaturas são a parte transferível, e um
número medido contra as tabelas de um corpus não é um facto sobre o que um adotante qualquer
sabe.

Duas datas, um número e um corpus com nome seriam todos mais precisos e menos verdadeiros. Se
for preciso um número, meça-se o corpus que se tem à frente.
