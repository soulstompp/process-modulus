# Nota para os revisores de álgebra linear — português europeu

**Atualizada à data do passo dos grãos, de 2026-09-01**, que acrescentou o tipo de documento de
composição, as três margens de amortecedor, a terceira classe de ajustamento da ISO 286 e a nota
de cegueira ao sinal que a acompanha, uma correção à decomposição que consta abaixo — e que um
leitor desta nota teria muito provavelmente apanhado primeiro — e a secção dos grãos,
antes da parte da composição, que é a questão em aberto e não uma peça arrumada.

Objetivo: dar a quem tem álgebra linear sólida o mínimo necessário para reconstruir o modelo
por si próprio, sem ler o README. Termina onde a rede de fluxo se torna óbvia, de propósito.

Convenções: português europeu, grafia do AO90 (*espetro*, *transação*, *seleção*, *exatamente*,
*objeto*, *fator*), termos do XML entre « » com uma glosa portuguesa quando é óbvia.
**procura**, não «demanda»; **ficheiro**, não «arquivo».

Escolhas de tradução que vale a pena rever: «remainder» → *resto* e `(d mod q)` → *resíduo*,
o que mantém em português a mesma distinção que o inglês faz entre *remainder* e *residue*;
«clearance» → *folga* e «interference» → *interferência*, que é o vocabulário da ISO 286 em
português, pelo que o empréstimo continua a ser um empréstimo; «nameplate» → *capacidade
nominal*; *contagem de disparos* para «firing count», vocabulário das redes de Petri, que
este público reconhece de imediato.

⚠️ **E uma do passo de 2026-09-01: «transition», a terceira classe da ISO 286, → *ajustamento
incerto*.** É o termo da norma, e leva uma desambiguação que não é opcional: *incerto* cobre
dois eixos que este modelo mantém separados, e a fronteira entre eles decide o argumento:

```
✅ o sentido que se quer     3. «nunca se sabe como vai reagir»; inconstante; volúvel
                             7. «pode acontecer ou não»; contingente
                             8. «cujo desenrolar é imprevisível»

⛔ o sentido que não se quer  2. que tem dúvidas; que hesita; irresoluto
                             4. duvidoso; dúbio; ambíguo
                             5. vago; impreciso
                             6. que não é possível determinar
```

⭐ O primeiro grupo diz uma propriedade **da coisa**: umas semanas falta, outras sobra. O segundo
diz uma propriedade **de quem declara**. A anotação de `Fit` admite `transition` e recusa um
`indeterminate` exatamente sobre essa fronteira, pelo que ler o segundo grupo inverteria o
argumento — e é por isso que a glosa acompanha o termo em vez de se deixar ao contexto.

⭐⭐ Vale a pena notar que isto **não é uma emenda à tradução**. O inglês precisa da mesma
desambiguação: «transition» é neutro quanto a este eixo e a anotação gasta um parágrafo a
fazê-la à mesma. O português obriga apenas a fazê-la no termo em vez de a fazer na prosa, o que
até se defende como sendo melhor — o leitor português encontra a ambiguidade à cabeça e é
avisado; o inglês pode passar-lhe ao lado sem reparar que houve uma escolha.

⚠️ **Uma escolha nova que merece discussão: «slack» → *margem*, e não *folga*.** Em mecânica
portuguesa *folga* é precisamente a palavra para «slack», mas já está tomada por «clearance»,
que é um termo emprestado à ISO 286 e onde o empréstimo tem de continuar visível. *Margem* fica
livre e lê-se bem («margem de capacidade», «margem de tempo»). ⭐ A colisão é real e não é
acidental: o inglês distingue duas ideias que o português mecânico reúne numa só palavra, e
esta nota escolhe proteger o empréstimo em vez do idiomatismo. «buffer» → *amortecedor*.

⛔ **E o vocabulário da composição, também do passo de 2026-09-01, onde as colisões são com o
direito e não com a mecânica.** É a parte mais recente do modelo e a que se lê pior sem as
palavras inglesas ao lado, pelo que a secção da composição mantém as « » tal como as outras.

| termo | escolha | porquê |
|---|---|---|
| «composition» | *composição* | ⛔ **e nunca *consolidação***. Em contabilidade de grupos a consolidação é um ato jurídico com sentido fixo, e o próprio esquema recusou `Consolidation` como nome pela mesma razão: excluiria o auditor e o financiador, que não consolidam nada. Uma composição é o documento; a consolidação é uma das coisas que se podem fazer com ele |
| «fusion» | *fusão* | ⚠️ a colisão é do mesmo género que a de *folga*: em direito societário português *fusão* é a fusão de **sociedades**. Aqui é entre **camadas** e é parte-para-todo, não entre pessoas coletivas. O termo fica porque é o do esquema, mas lê-se sempre «fusão de camadas» à primeira ocorrência |
| «part» | *parte* | uma camada declarada por outrem que entra numa fusão |
| «elimination» | *eliminação* | ⭐ aqui o empréstimo é ao contrário e é o caso mais fácil: *eliminação de operações intragrupo* já é o termo dos contabilistas portugueses e significa exatamente isto — quantidade contada duas vezes, removida. Não se traduz para outra coisa |
| «fungible» | *fungível* | ⭐ já é termo de arte em português (bens fungíveis) e o sentido bate certo: uma unidade substitui outra. É o teste que decide se duas partes são uma só camada |

⚠️ **Outra, do passo de 2026-09-01: «grain» → *grão*.** Trata-se da escala a que uma quantidade
se transaciona, se reporta ou varia, e *grão* já é o termo corrente em português para a granularidade
de uma medição. *Granularidade* servia, mas as três aparecem juntas e em enumeração, onde a palavra
curta se lê melhor. «duty cycle» → *ciclo de funcionamento*, e não «ciclo de trabalho», que em
eletrónica portuguesa significa outra coisa.

---

Um documento declara um conjunto de «layers» (camadas). Cada camada ℓ transporta três
quantidades, cada uma na sua própria unidade: uma procura «demand» `d`, uma oferta
comprometida «nameplate» `n` (capacidade nominal) e um «quantum» `q`, a unidade indivisível
em que a oferta chega. A oferta vem em unidades inteiras, portanto `n = kq` com `k` inteiro;
a procura não. O «remainder» (resto) é `r = n − d`. Todas as quantidades são intervalos de
três pontos, pelo que isto é aritmética intervalar do princípio ao fim, e tanto a grandeza do
resto como o seu **sinal** são avaliados ao longo de todo o intervalo da procura. ⭐ Essa
uniformidade tem um passo de idade. O sinal era antes lido só na moda, porque `Fit` era uma
enumeração de dois membros e um tipo que toma um valor tem de ser lido num ponto. A ISO 286,
de onde o vocabulário é emprestado, define **três** classes, e a que faltava é exatamente o
caso da sobreposição:

```
folga                 n_low  ≥ d_high     todo o intervalo folga
ajustamento incerto   os intervalos sobrepõem-se
interferência         n_high ≤ d_low      todo o intervalo interfere
```

Onde `n − d` atravessa o zero, o limite inferior da grandeza é legitimamente 0, e agora é o
sinal que o diz em vez de deixar o leitor inferi-lo.

⛔ **Uma consequência merece atenção, por ser uma armadilha de aritmética intervalar e não uma
escolha de modelação.** Sob um ajustamento incerto, `|n − d|` é **cego ao sinal**, pelo que retém
apenas o MAIOR dos dois lados e o menor fica invisível lá dentro. `d = [11.0, 13.2, 16.4]`
contra `n = 16` dá `[0.0, 2.8, 5.0]` — o lado da folga — e os 0,4 de interferência ficam dentro
desse intervalo, indistinguíveis de 0,4 de folga. A exposição à interferência deriva-se por isso
das entradas e nunca da grandeza declarada: `max(0, d_high − n_low)`.

⭐ E os dois lados **nunca podem ser somados**. A folga desce à medida que `d` sobe e a
interferência sobe, pelo que uma soma componente a componente emparelha o excedente da semana
fraca com a recusa da semana cheia e reporta um estado que não ocorre em semana nenhuma — o
mesmo erro de correlação do caso `Φ` mais abaixo, só que aqui o condutor comum é o próprio `d`
e o emparelhamento é exatamente ao contrário. A cura é avaliar num só canto, onde há um valor
de cada. É por isso que `quantity` continua a ser uma única declaração.

**O resto é diagonal.** Nada da camada *a* entra no resto da camada *b*. Vale a pena dizê-lo
explicitamente, porque o resto do modelo são matrizes e a suposição natural é que sejam elas
a fazer o trabalho aqui. Não fazem.

## A decomposição, e a correção

Com `m = k − ⌊d/q⌋`:

```
r = mq − (d mod q)
```

`mq` são quanta inteiros e uma decisão de aquisição — basta deter mais uma unidade e o valor
muda. `(d mod q)` é um resíduo e nenhuma escolha de `k` o elimina; o mais perto que qualquer
decisão chega é `min(d mod q, q − d mod q)`. Como `n` é múltiplo de `q`, `r ≡ −d (mod q)`
sempre: arredondar para cima deixa `(−d) mod q ∈ [0,q)`, arredondar para baixo deixa
`−(d mod q) ∈ (−q,0]`, simétricos em ℝ/qℝ cuja soma é `q`. «clearance» (folga) e
«interference» (interferência) são uma só divisão lida de lados opostos. A tese do modelo é
que o resíduo se conserva e a parte inteira é escolhida, pelo que o documento regista quem
pode alterar cada uma: a origem do quantum (quem fixa o tamanho da unidade) e a origem da
quantidade (quem fixa quantas unidades se detêm), cada uma delas «intrinsic» (intrínseca),
«contractual» (contratual) ou «policy» (política interna).

⛔ **Duas coisas sobre essa identidade que um passo de revisão interna errou e que os
senhores não teriam errado.** Primeira: substituindo `k = n/q`, tudo colapsa —
`r = (n/q − ⌊d/q⌋)q − (d − ⌊d/q⌋q) = n − d`. Os pisos aparecem duas vezes com sinais opostos e
cancelam-se, pelo que `r` é exato para **qualquer** `d` e **qualquer** `n`, intervalar ou não.
Um registo interno que afirmava que a decomposição «pressupõe valores pontuais» estava errado
quanto ao total.

Segunda, e pior: `d mod q` é um **dente de serra**, pelo que, avaliado nos três pontos de um
intervalo, não tem de ficar ordenado. `d = (4,5; 5,2; 6,7)` com `q = 1` dá resíduos
`(0,5; 0,2; 0,7)`, que não é sequer um intervalo de três pontos válido, ao passo que `d` está
perfeitamente bem formado. **Dez das vinte camadas com quantum em `assets/corpus/` estão nesse
estado.** O total é uma identidade; a divisão em duas metades não é representável como dois
intervalos no caso geral. O esquema só transporta o total, pelo que nada está partido — mas
leia-se a decomposição como uma derivação de `r` e nunca como instrução de preenchimento para
as suas duas metades.

## Operações, e porque `DᵀN` não é o que parece

Um documento declara também «operations» (operações). Cada uma consome de uma camada —
«draw» — ou induz um compromisso noutra — «induces» —, o que dá duas matrizes P×L sobre
operações × camadas: `D` para os consumos e `N` para as induções. São deliberadamente tipos
distintos: um «draw» é consumo já ocorrido, uma indução é um compromisso que gera um consumo
futuro sobre uma oferta *diferente*.

Existe, portanto, estrutura genuína entre camadas, e `DᵀN` é a forma óbvia de a reunir. Duas
coisas impedem que seja aquilo que parece. As unidades: cada camada tem a sua — pessoas, GPU,
lançamentos por trimestre —, pelo que as entradas saem em pessoas·lançamentos e não em
lançamentos por pessoa. Os *padrões* de incidência compõem-se e dão alcançabilidade; as
quantidades não. E não há contagem de disparos por operação, deliberadamente, porque a
sequência e o tempo cabem ao BPMN — o que se tem é uma estrutura de taxas, não um fluxo.

Isto importa por causa daquilo que *não* é. Os elementos fora da diagonal de `DᵀN` dizem *o
trabalho consumido aqui compromete trabalho ali*. O «coupling» (acoplamento) é outro objeto:
`C`, L×L, diz *aliviar a restrição desta camada move mensuravelmente o resto daquela*. O
modelo assume `C = 0` — é isso que torna as camadas separáveis, à partida — e exige que
qualquer entrada não nula transporte um registo em prosa de como foi observada. Os dois não
podem ser ligados sem exatamente a contagem de disparos que não existe, pelo que `C` é
observado e nunca derivado. **Zero acoplamentos é a hipótese, não um resultado**; um documento
sem nenhum é um documento onde ninguém procurou. É também aqui que a questão da base se
coloca: uma decomposição em soma direta não é única, e o que fixa esta são as unidades, não um
produto interno — não há norma, espetro nem valores próprios até alguém escolher uma escala
por camada, e essa escolha é um ato de modelação e não um ato matemático.

## Detentores, e as três margens que os limitam

Cada resto é suportado por um ou mais de exatamente cinco «holders» — «booked» (registado),
«counterparty» (contraparte), «customer» (cliente), «people» (pessoas), «unrealised» (não
realizado) —, cada um com uma «share» (parcela) na unidade da camada, somando as parcelas
`|r|`. É a matriz `H`, L×5, uma distribuição e não uma seleção. Quatro dos cinco não têm
transação por trás; a tese substantiva diz respeito a «people», onde o trabalho absorvido não
gera instrumento algum e, por isso, nenhum sistema contabilístico o vê.

Cada camada transporta ainda três **margens**, uma por amortecedor, na unidade da camada:
«capacitySlack» (quanto a oferta corre acima da sua capacidade nominal), «inventorySlack»
(quanto produto se mantém adiantado) e «timeSlack» (quanta procura sobrevive à espera).
Chamemos-lhe `S`, L×3. Cada resto nomeia um amortecedor como «absorber», o que dá uma seleção
`A: L → {1,2,3}`, e a regra é

```
Σ_{j ≠ unrealised} H[ℓ,j]  ≤  S[ℓ, A(ℓ)]     onde r[ℓ] < 0 e S[ℓ,A(ℓ)] está declarado
```

⭐ Três pontos merecem ser assinalados a quem vier à procura de estrutura. **Isto eram valores
booleanos até este passo**, o que tornava a desigualdade indizível — um bit diz que um
amortecedor existe, não quanto ele leva, pelo que qualquer parcela cabia. **«unrealised» está
isento por ser o transbordo**: procura que amortecedor nenhum recebeu. E a restrição é
unilateral — as margens limitam apenas o lado da interferência, já que sob folga o excedente
*é* o resto e não há nada para absorver.

⚠️ A comparação é avaliada na moda, seguindo a convenção do sinal acima. A leitura estrita
(pior parcela contra menor margem) existe e fica deliberadamente entregue a um perfil de
conformidade, porque escolher entre as duas é uma política e não um facto. Em «shift-line»
essa escolha não é cosmética: `1,7 ≤ 2,5` na moda, `2,9 ≤ 1,0` na leitura estrita. A mesma
declaração, veredictos opostos.

⛔ **`S` tem de estar na unidade da camada, e a sua medição natural não está.** O tamanho de um
amortecedor observa-se como uma *duração* — quanto tempo o produto se conserva, quanto tempo o
cliente espera —, ao passo que `H` está na unidade da camada. O declarante deve, portanto,
`quantidade = duração × taxa` antes de declarar. As três margens dimensionadas ou descritas no
corpus foram todas medidas como durações; numa das três a multiplicação parece não ter sido
feita. Saber se `[0, S]` é fechado é uma questão bem menor do que essa — e é fechado: um
amortecedor exatamente cheio ainda não falhou, falha a unidade seguinte. ⭐ O único intervalo
genuinamente semiaberto do modelo é o resíduo, `(−d) mod q ∈ [0, q)`, semiaberto pela razão da
ISO 8601 — em `q` volta a 0 em vez de significar «cheio».

⭐⭐ **A coluna da capacidade de `S` fecha também uma equação, e é o único sítio onde o modelo
mede algo sem instrumento por trás.** Em todo o resto, uma margem limita quotas que alguém já
declarou. Aqui limita uma quantidade derivada das entradas:

```
max(0, d_high − n_low)   ≤   S[ℓ, capacidade]_high  +  Σ_{j ∈ {cliente, não realizado}} H[ℓ,j]_high
```

Lido da esquerda para a direita: o que a procura e a capacidade nominal do próprio documento
dizem que podia ter ficado por servir é, no máximo, o que a oferta consegue absorver mais o que
o documento admite ter recusado. **A diferença é a quantidade interessante** — resto que
aconteceu e que nada registou, que é o assunto deste modelo dito como aritmética em vez de como
argumento. Avaliado num só canto, pela razão da anti-correlação acima.

⚠️ Dois limites, ambos a saber antes de confiar nisto. É um instrumento **só do ajustamento incerto**: sob interferência a exposição É o limite superior de `|n − d|` e a desigualdade
degenera na regra da soma das quotas; sob folga é zero. E está **por exercitar** — nem uma
camada em `assets/corpus/` declara uma margem de capacidade numérica, pelo que fica muda em dezanove
de vinte e uma. Um limite sem nada que limitar é o que passa mais alto, e o repositório di-lo no
próprio teste em vez de se contar como coberto.

## Três grãos, dos quais o modelo declara dois

⚠️ Acrescentado a 2026-09-01, e é provavelmente a parte que mais vale o vosso tempo, porque é
uma pergunta sobre o que os intervalos *significam* e não sobre o que se lhes faz.

Três escalas temporais pesam sobre qualquer quantidade aqui. O **grão de transação** é o quantum
`q` — a unidade indivisível em que a oferta chega, declarada com uma origem que diz quem a fixa.
O **grão de reporte** é o denominador da unidade: «por trimestre», «por semana». O **grão de
variação** — a escala temporal em que a quantidade de facto se move — não é declarado em lado
nenhum.

O primeiro é o próprio objeto do modelo: `r = mq − (d mod q)` é uma afirmação sobre ele. O
terceiro importa porque duas operações dependem dele em silêncio:

- Um **ciclo de funcionamento** dissolve-se numa taxa e desaparece. Uma linha que corre das
  02:00 às 05:00, a uma unidade cada cinco segundos, tem uma capacidade nominal de 2160/dia;
  contra uma procura de 2000/dia, a folga é de 160/dia seja qual for o horário. Mas a *duração*
  correspondente não sobrevive: o ingénuo `q / folga` dá 9 minutos, enquanto a espera real é de
  68 segundos dentro da janela ou de 21 horas fora dela. Nove minutos não ocorre em lado nenhum.
  Daí que uma margem tenha de ser declarada como quantidade — e o exemplo trabalhado do próprio
  modelo declarava a duração até a este passo.
⛔ **Uma segunda consequência foi aqui afirmada e está RETIRADA, e a retirada vale mais do que
valia a afirmação.** Dizia: uma fila absorve um excesso transitório e nunca um permanente, logo
com `ρ > 1` a acumulação cresce sem limite, logo a procura de `[11,0, 12,7, 14,4]` da
«shift-line» contra uma linha de 10 turnos só é coerente sob a leitura de variação. **`ρ > 1` só
dá acumulação sem limite com paciência infinita**, e `timeSlack` É uma paciência — «antes de o
cliente ir a outro lado», declarada como `contractual`. Uma fila com abandono é estável para
qualquer `ρ`: a acumulação cresce até a espera atingir a paciência e depois a procura sai à taxa
a que o excesso entra. Nada aqui precisa da leitura de variação.

⭐ E a aritmética é exata, que é a parte a conferir: uma paciência de `2,5 turnos = 0,25 semana`
com `μ = 10/semana` põe a profundidade de equilíbrio em `μW = 2,5` turnos — a fila assenta NA
paciência — enquanto a taxa de saída é `λ − μ = 2,7/semana` e os detentores declarados são
`cliente 1,7 + não realizado 1,0 = 2,7`. A regra da soma e o equilíbrio da fila concordam.

⭐ `Claim` lê-se como epistémico do princípio ao fim — «mais provável», «o valor que um estimador
pode afirmar honestamente» e `narrowsWhen`, que quer dizer *este intervalo é aquilo que não
sabemos*. Variação genuína não estreita por se medir melhor, e as duas leituras não são
distinguidas. Essa ambiguidade é real; o que ela **não** é é aquilo que faz um amortecedor de
tempo funcionar.

⭐⭐ **A metade do ciclo de funcionamento já tem onde ficar, e chegou como um SEGUNDO EIXO e não
como um terceiro valor.** `Divisibility` era `lumpy | continuous` — uma escolha — e, lidos como
funções da quantidade pedida, `continuous` é uma reta e `lumpy` é uma escada, `q·floor(x/q)`. Um
ciclo de funcionamento é a mesma escada no eixo do *tempo*, uma onda quadrada. Não é um terceiro
membro da escolha, porque nós de oito GPU disponíveis apenas das 02:00 às 05:00 são discretos na
quantidade **e** intermitentes no tempo; o tipo passou a ser uma sequência: a escolha e depois um
«window» opcional. O tamanho é um `LumpyQuantum`, e o *período* vem de graça da regra do
denominador acima.

⛔ «window» obedece a uma regra que mais nada aqui obedece: **é TRANSPORTADA através de uma fusão
e nunca somada.** Dois membros que nomeiam uma só máquina declaram um só calendário entre ambos;
`F Φ` daria dez dias por semana. É uma propriedade e não uma quantidade, e é também por isso que
o vetor de eliminações `e_x` percorre procura, capacidade nominal e consumo, e não tem quarta
componente.

⛔ O grão de variação continua sem elemento. Um «period» em `Claim` toca quinze pontos de
utilização; um sinalizador `ignorância | variação` é uma falsa escolha, já que a resposta honesta
é quase sempre ambas; e qualquer deles é um eixo temporal a entrar num modelo que
deliberadamente não transporta nenhum. **Se virem uma quarta hipótese, é a coisa mais útil que
nos podem devolver.**

## Composição: o único sítio onde aparece uma aplicação linear a sério

Um segundo tipo de documento — «composition» (composição) — consolida ficheiros, e é declarado
por quem os leu e não por nenhum dos declarantes. Dadas camadas-parte «part» indexadas por `p` e
camadas compostas por `ℓ`, uma composição declara uma matriz de incidência `F` (L×P, entradas
em {0,1}, cada parte usada no máximo uma vez) e uma diagonal `Φ = diag(φ_p)` de fatores de
conversão «factor» estritamente positivos que levam cada parte à unidade da camada composta.
Cada linha de `F` é uma «fusion» (fusão de camadas). Para cada quantidade `x ∈ {d, n, draw}`:

```
x_composta = F Φ x_partes − e_x
```

onde `e_x` é um vetor de **eliminações** «elimination» — quantidades contadas em duplicado entre
partes, declaradas uma a uma, com prosa e com o par de ficheiros entre os quais assentam. ⛔ E `e_x`
vazio **não** é `e_x = 0`: um vetor ausente não distingue *«procurámos duplicações e não há»* de
*«ninguém procurou»*, e as duas obrigam a aritméticas opostas — a primeira exige
`x_composta = F Φ x_partes` exatamente, a segunda não exige igualdade nenhuma. O esquema obriga
por isso a declarar qual das duas, e é a diferença entre uma regra exata e um aviso. Três notas:

- As entradas de `Φ` são elas próprias intervalos de três pontos («um mês são `[672, 720, 744]`
  horas»), e o produto é componente a componente, o que só é correto **porque** uma conversão é
  estritamente positiva. O produto intervalar geral, com os quatro cantos, não está implementado
  nem é devido aqui.
- ⛔ `r_composta ≠ n_composta − d_composta` quando `Φ ≠ I`, e isso não é defeito de nenhuma das
  duas figuras. Um mesmo `φ_p` multiplica `n_p` e `d_p`, pelo que esses intervalos convertidos
  ficam correlacionados; subtraí-los com a inversão de extremos que as quantidades
  *independentes* exigem conta duas vezes a dispersão de `φ`. `r` tem de ser convertido
  diretamente: `r_composta = F Φ r_partes + e_d`. No corpus isto lê-se
  `(1092,0; 2857,0; 4198,8)` na versão rederivada contra `(1414,0; 2857,0; 4085,6)` na versão
  convertida, coincidindo apenas na moda.
- As composições encaixam uma na outra, pelo que `F` compõe — e a restrição de unicidade, que
  tem alcance de um só documento, não. A um nível, «nenhuma parte usada duas vezes» é uma
  chave; a dois níveis tem de passar a «nenhuma folha alcançável por dois caminhos», que
  validador nenhum vê, porque o segundo caminho atravessa um documento que o primeiro não
  contém.

`F` é também onde a fungibilidade é afirmada: duas partes são uma só camada composta exatamente
quando a oferta de uma pode servir a procura da outra. É um juízo, é obrigatório transportar
prosa, e **não** é `C` — acoplamento e fungibilidade são eixos independentes, e o corpus povoa
as duas células fora da diagonal.

## Como verificar

`assets/corpus/enterprise-contract.xml` tem L=3, P=2. Duas das três camadas reproduzem `r = n − d`
exatamente, inversão de extremos incluída, pelo que a aritmética se verifica mecanicamente.
`assets/corpus/refutation.xml` regista uma entrada não nula de `C` com a observação que a produziu.
`assets/corpus/merge-holding-composition.xml` exercita `F`, `Φ` e o encaixe em conjunto. Não é
preciso construir nada: `xmllint --noout --schema schema/process-modulus.xsd <ficheiro>` e
`--schema schema/assertion.xsd` para as composições.
