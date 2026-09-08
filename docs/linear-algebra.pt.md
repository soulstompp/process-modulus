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
resto como o seu **sinal** são avaliados ao longo de todo o intervalo da procura. ⭐ Ambos são
lidos ao longo do intervalo porque a classificação tem três membros e não dois. Um `Fit` de dois
valores não tem onde pôr a sobreposição, pelo que só pode ser lido num ponto. A ISO 286,
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
perfeitamente bem formado. **Quinze das vinte e três camadas com quantum em `assets/corpus/` estão nesse
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
Chame-se a isso `S`, L×3. Cada resto nomeia um amortecedor como «absorber», o que dá uma seleção
`A: L → {1,2,3}`, e a regra é

```
Σ_{j ∉ {customer, unrealised}} H[ℓ,j]  ≤  S[ℓ, A(ℓ)]   onde r[ℓ] < 0 e S[ℓ,A(ℓ)] está declarado
```

⭐ Três pontos merecem ser assinalados a quem vier à procura de estrutura. **As folgas são
quantidades e não sinalizadores, e esta desigualdade é a razão**: um bit diz que um amortecedor
existe, não quanto ele leva, pelo que contra um bit cabe qualquer parcela e nada fica
limitado. **OS DOIS detentores
por servir estão isentos, por serem ambos o transbordo**: o «customer» e o «unrealised» nomeiam
ambos procura que ninguém satisfez, e isso não é carga que o amortecedor tenha levado. Isentar só
o «unrealised» somava à carga do amortecedor a degradação suportada por um cliente, e o `Fit`
chama a esse mesmo par uma violação sob uma folga. E a restrição é unilateral — as margens limitam apenas o lado da interferência, já que sob folga o excedente
*é* o resto e não há nada para absorver.

⚠️ A comparação é avaliada na moda, seguindo a convenção do sinal acima. A leitura estrita
(pior parcela contra menor margem) existe e fica deliberadamente entregue a um perfil de
conformidade, porque escolher entre as duas é uma política e não um facto. Em «shift-line»
as duas leituras divergem bastante: `1,7 ≤ 2,5` na moda contra `2,9 ≤ 1,0` na estrita. ⚠️ Repare-se
no que esse exemplo passou a ser: a «shift-line» não chega sequer a esta desigualdade, porque os
seus dois detentores são «customer» e «unrealised» e o lado esquerdo fica, portanto, vazio. A
questão de política é real; foi o corpus que deixou de a ilustrar.

⛔⛔ **E o lado esquerdo está vazio em TODAS as camadas do corpus que chegam à regra, o que é um
achado sobre a prova e não uma lacuna nela.** Em todas as camadas de interferência que dimensionam
o amortecedor que absorve, todos os detentores são de uma das duas espécies por servir: não se
absorveu coisa nenhuma, a procura foi recusada. O `Σ quotas servidas ≤ S` tem o lado esquerdo
vazio porque o conjunto servido é vazio, o `checks/share_exceeds_slack` reporta ⛔ VACUOUS, e o
`algebra/borne.sqlc` imprime `suportado = absorvido + por servir` por camada em cada execução, em
vez de deixar isso a um comentário.

⛔ **`S` tem de estar na unidade da camada, e a sua medição natural não está.** O tamanho de um
amortecedor observa-se como uma *duração* — quanto tempo o produto se conserva, quanto tempo o
cliente espera —, ao passo que `H` está na unidade da camada. O declarante deve, portanto,
`quantidade = duração × taxa` antes de declarar. As margens do corpus que trazem um tamanho
acima de zero foram todas medidas como durações; numa delas a multiplicação parece não ter sido
feita. O `cargo run --example matrices` imprime o recenseamento das margens, dimensionadas contra
ausentes, uma linha por amortecedor. Saber se `[0, S]` é fechado é uma questão bem menor do que
essa — e é fechado: um
amortecedor exatamente cheio ainda não falhou, falha a unidade seguinte. ⭐ O único intervalo
genuinamente semiaberto do modelo é o resíduo, `(−d) mod q ∈ [0, q)`, semiaberto pela razão da
ISO 8601 — em `q` volta a 0 em vez de significar «cheio».

⭐⭐ **A coluna da capacidade de `S` fecha também uma equação, e é o único sítio onde o modelo
mede algo sem instrumento por trás.** Em todo o resto, uma margem limita quotas que alguém já
declarou. Aqui limita uma quantidade derivada das entradas:

```
max(0, d_high − n_low)   ≤   Σ_j S[ℓ,j]_high  +  Σ_{j ∈ {customer, unrealised}} H[ℓ,j]_high

                             e apenas onde todos os S[ℓ,j] estão declarados
```

Lido da esquerda para a direita: o que a procura e a capacidade nominal do próprio documento
dizem que podia ter ficado por servir é, no máximo, o que a oferta consegue absorver mais o que
o documento admite ter recusado. **A diferença é a quantidade interessante** — resto que
aconteceu e que nada registou, que é o assunto deste modelo dito como aritmética em vez de como
argumento. Avaliado num só canto, pela razão da anti-correlação acima.

⛔⛔ **O limite é sobre a LINHA inteira de `S`, e lido apenas na coluna da capacidade diz outra
coisa.** Os três amortecedores são substitutos: um excesso acima da capacidade nominal pode
ser absorvido correndo acima do regime, recorrendo ao stock, ou pondo a procura à espera. Uma
coluna fechada é UM CAMINHO fechado, o que não implica que alguma coisa tenha ficado por servir, e
duas regras tiravam daí essa conclusão. ⭐ Uma margem não declarada SUSPENDE a desigualdade em vez
de contribuir com zero, porque reduzir uma ausência a zero transforma *ninguém olhou* em *não há
espaço* e fabrica uma falha a partir de uma lacuna.

⚠️ Dois limites, ambos a saber antes de confiar nisto. É um instrumento **só do ajustamento incerto**: sob interferência a exposição É o limite superior de `|n − d|` e a desigualdade
degenera na regra da soma das quotas; sob folga é zero. E fica **muda em quase todas as camadas
expostas, pela razão que o próprio modelo prevê**: o `layers/exposure_scope.sqlc` arruma-as pelos
três estados e o `algebra/exposure_standing.sqlc` obriga esses três a uma partição, portanto
execute-se e leiam-se as contagens. Quase todas têm um amortecedor que ninguém dimensionou, e NEM
UMA tem um amortecedor com espaço dentro. A suspensão nunca é o caso inofensivo; é sempre um
caminho por medir, que é a mesma frase que o «people» diz sobre instrumentos. Um limite sem nada
que limitar é o que passa mais alto, e a tabela de cobertura diz ⛔ VACUOUS em vez de se contar
como coberto.

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
  Daí que uma margem seja declarada como quantidade na unidade da camada, nunca como a duração
  em que foi observada, e quem declara deve a conversão.
⛔ **Uma segunda consequência parece seguir-se aqui e não se segue, e a razão por que falha vale
mais do que valeria a afirmação.** Diz: uma fila absorve um excesso transitório e nunca um
permanente, logo
com `ρ > 1` a acumulação cresce sem limite, logo a procura de `[11,0, 12,7, 14,4]` da
«shift-line» contra uma linha de 10 turnos só é coerente sob a leitura de variação. **`ρ > 1` só
dá acumulação sem limite com paciência infinita**, e `timeSlack` É uma paciência — «antes de o
cliente ir a outro lado», declarada como `contractual`. Uma fila com abandono é estável para
qualquer `ρ`: a acumulação cresce até a espera atingir a paciência e depois a procura sai à taxa
a que o excesso entra. Nada aqui precisa da leitura de variação.

⭐ E a aritmética é exata, que é a parte a conferir: uma paciência de `2,5 turnos = 0,25 semana`
com `μ = 10/semana` põe a profundidade de equilíbrio em `μW = 2,5` itens — a espera assenta NA
paciência — enquanto a taxa de saída é `λ − μ = 2,7/semana` e os detentores declarados são
`cliente 1,7 + não realizado 1,0 = 2,7`. A regra da soma e o equilíbrio da fila concordam.

⭐ `Claim` lê-se como epistémico do princípio ao fim — «mais provável», «o valor que um estimador
pode afirmar honestamente» e `narrowsWhen`, que quer dizer *este intervalo é aquilo que ninguém
sabe*. Variação genuína não estreita por se medir melhor, e as duas leituras não são
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
vazio **não** é `e_x = 0`: um vetor ausente não distingue *«alguém procurou duplicações e não há»* de
*«ninguém procurou»*, e as duas obrigam a aritméticas opostas — a primeira exige
`x_composta = F Φ x_partes` exatamente, a segunda não exige igualdade nenhuma. O esquema obriga
por isso a declarar qual das duas, e é a diferença entre uma regra exata e um aviso. Três notas:

- As entradas de `Φ` são elas próprias intervalos de três pontos («um mês são `[672, 720, 744]`
  horas»), e o produto é componente a componente sempre que a quantidade convertida é não
  negativa, o que cobre uma procura e uma capacidade nominal. Não cobre um resto: `r` tem sinal,
  e sob interferência o fator maior dá o produto menor, pelo que componente a componente
  devolveria um intervalo cujo mínimo excede o máximo.
  `composition/settled_remainders.sqlc` toma por isso o canto de cada lado. O produto
  intervalar geral, com os quatro cantos, onde AMBOS os operandos atravessam o zero, não está
  implementado nem é devido: uma conversão é estritamente positiva.
- ⛔ `r_composta ≠ n_composta − d_composta` quando `Φ ≠ I`, e isso não é defeito de nenhuma das
  duas figuras. Um mesmo `φ_p` multiplica `n_p` e `d_p`, pelo que esses intervalos convertidos
  ficam correlacionados; subtraí-los com a inversão de extremos que as quantidades
  *independentes* exigem conta duas vezes a dispersão de `φ`. `r` tem de ser convertido
  diretamente: `r_composta = F Φ r_partes − e_n + e_d`, e AMBAS as eliminações aparecem porque
  agem sobre `r` em sentidos opostos: retirar procura contada duas vezes sobe o resto, retirar
  capacidade nominal contada duas vezes baixa-o. ⛔ Uma identidade escrita em prosa e avaliada em
  lado nenhum pode perder um termo inteiro sem que nada dê por isso.
  `composition/fused_remainders.sqlc` avalia esta, e a observação 13 de
  `cargo run --example observations` imprime-a ao lado da figura que `layers/remainder` deriva
  dos totais compostos. No corpus isto lê-se
  `(1092,0; 2857,0; 4198,8)` na versão rederivada contra `(1414,0; 2857,0; 4085,6)` na versão
  convertida, coincidindo apenas na moda.
- As composições encaixam uma na outra, pelo que `F` compõe — e a restrição de unicidade, que
  tem alcance de um só documento, não. A um nível, «nenhuma parte usada duas vezes» é uma
  chave; a dois níveis tem de passar a «nenhuma folha alcançável por dois caminhos», que
  validador nenhum vê, porque o segundo caminho atravessa um documento que o primeiro não
  contém.
- ⭐ **E uma composição encaixada tem dois fundos diferentes, um por quantidade, no mesmo
  grafo.** Uma SOMA sobre as partes acaba nas camadas de que `F` já não desce, porque abaixo
  delas não há nada para somar. Um RESTO acaba mais cedo: na primeira camada cuja procura e
  capacidade nominal não foram ambas escaladas por um mesmo fator de conversão com largura. Aí
  `n − d` é legítimo e o par declarado é uma afirmação que o seu compositor assina, pelo que
  descer para lá dela deita fora essa afirmação e todas as correções que esse compositor já
  aplicou, que têm depois de ser reconstruídas de baixo e podem falhar por razões que a figura
  declarada já tinha resolvido. Uma camada sem partes satisfaz a segunda condição
  trivialmente, e é por isso que os dois fundos se confundem com um só.

  ⛔ **O terminal do grafo desloca-se portanto com a quantidade que se dobra**, o que não é
  verdade nos dois sistemas de composição a que este modelo é de resto análogo. Os terminais de
  um grafo de chamadas são os seus terminais; as folhas de uma consulta são as suas folhas, seja
  o que for que se selecione. Aqui um nó intermédio carrega uma figura que alguém assinou, e é
  isso que faz dele um sítio onde parar.

`F` é também onde a fungibilidade é afirmada: duas partes são uma só camada composta exatamente
quando a oferta de uma pode servir a procura da outra. É um juízo, é obrigatório transportar
prosa, e **não** é `C` — acoplamento e fungibilidade são eixos independentes, e o corpus povoa
as duas células fora da diagonal.

⛔ **Também não é `e`, e esse é um erro de tipo e não uma confusão de vocabulário.** O
`F ∈ {0,1}^{L×P}` transporta o juízo de fungibilidade; o `e ∈ ℝ^L` transporta o que duas partes
contaram duas vezes. O `e` não é função do `F`: uma fusão de dois estabelecimentos disjuntos tem
`e = 0` e é perfeitamente fungível, enquanto uma fusão de dois pretendentes a uma máquina tem `e`
igual à capacidade nominal de uma parte inteira e é igualmente fungível. O
`assets/fixtures/every-partial-elimination.xml` declara o meio dessa escala — `e = 3` contra partes
de 10 — e concilia sob a mesma regra. Ler a operação a partir do `e` — agrupamento aqui, agregação
ali — quantiza uma grandeza e infere um juízo a partir de um ajustamento. Não há parâmetro nenhum com valor de operador em `x = F Φ x − e`, nem etiqueta de tipo
numa linha do `F`; a equação é a mesma equação em todos os casos.

⭐ **Uma camada que quem compõe originou é uma linha de zeros do `F`** — uma camada composta sem
partes, cujas figuras são de quem compõe. Nada na aritmética o proíbe, e o modelo precisa disso: uma
escala ao nível do grupo pertence à casa-mãe e não veio de membro nenhum.

## O mesmo modelo em álgebra relacional, e porque se calculam os dois

Tudo o que vem acima é uma formulação matricial. O repositório transporta também uma formulação
relacional, e as duas são calculadas de forma independente e afirmadas iguais em cada execução.
Isso não é ornamento. É a única razão pela qual qualquer uma delas merece confiança, e o lado
relacional consegue dizer três coisas que o lado matricial estruturalmente não consegue.

⛔⛔ **Este documento é o único sítio onde os dois registos são ARGUMENTADOS em conjunto, e isso é
deliberado.** As relações esparsas NOMEIAM, sim, a matriz de que cada uma é a forma esparsa, logo
na primeira linha, porque quem lê deve saber que objeto tem à frente: o `entries/holders.sqlc`
abre com *«H, THE HOLDER MATRIX»* e o `entries/slacks.sqlc` com *«S, THE SLACK MATRIX»*. O que
nenhum cabeçalho `#` faz é RACIOCINAR nesse registo. O que mais perto chega,
`entries/cross_layer_edges.sqlc`, diz que *«um índice partilhado é o que um produto matricial É»* e
argumenta em junções no resto do ficheiro, o que é a fronteira e não uma exceção a ela. **Portanto
os nomes são partilhados e os operadores não**, e quem chega a uma consulta nunca tem de segurar um
segundo formalismo para a seguir. Esta secção é onde os operadores ficam lado a lado, portanto quem
quiser passar de um registo ao outro usa-a como dicionário e o resto do ficheiro como um dos seus
lados.

### O dicionário

Cada objeto acima tem uma relação com nome. ⛔ As contagens de linhas não se escrevem aqui de
propósito: uma contagem em prosa é certa até o corpus voltar a mexer-se, e depois é silenciosa a
esse respeito. Execute-se qualquer relação e leia-se a contagem no rodapé do próprio psql:

```
psql -d process_modulus_proof -c 'SET search_path TO pm, public' -f assets/sql/layers/remainder.sql
```

O `cargo sqlc compose` regenera-as todas a partir de `assets/sqlc/`.

| na nota | relação |
|---|---|
| `d`, `n`, `draw` | `layers/demand`, `layers/nameplate`, `layers/drawn` |
| `r = n − d` | `layers/remainder` |
| `F` (incidência) | `composition/parts` |
| `Φ x` (partes convertidas) | `composition/converted` |
| `F Φ x − e` | `composition/fused` |
| `e` | `eliminations/filed` |
| `H`, `S`, `C` | `entries/holders`, `entries/slacks`, `entries/couplings` |
| `D`, `N` | `entries/draws`, `entries/inductions` |

### As operações, que são a parte que merece a atenção de quem revê

**Um produto matriz-vetor é uma junção com um `GROUP BY`.** Não por analogia. O `F Φ x` é
calculado em dois ficheiros, e a diferença entre eles é toda a diferença entre uma matriz diagonal
e uma matriz geral:

```
Φ x    composition/converted.sqlc    partes ⋈ procura, vezes um escalar   23 linhas para 23
F (·)  composition/fused.sqlc        a mesma junção, mais γ_soma          23 linhas para 11
```

⭐⭐⭐ **Uma matriz diagonal é uma junção sem agregação. Uma matriz geral é a mesma junção com
ela.** O `Φ` não pode misturar linhas, portanto não precisa de `GROUP BY`; o `F` soma partes numa
camada composta, portanto é exatamente um `γ` sobre a incidência. Em tudo o resto são idênticos.

O resto do conjunto de operadores traduz-se com a mesma clareza:

| operação | relacional | nota |
|---|---|---|
| transposta `Dᵀ` | `ρ`, renomeação | nenhum dado se move; `Dᵀ` é o `D` com duas colunas renomeadas |
| `−e` | `⟕` e depois um `coalesce` guardado | o preenchimento só é sólido depois de `σ` retirar as linhas que nada devem |
| uma linha nula de `F` | uma camada composta sem linha de parte | uma anti-junção, com a forma de `composition/leaves` |
| `DᵀN` | uma junção sobre o índice de operação partilhado | os padrões compõem-se; as quantidades não, por causa das unidades |

### Esparsidade, e a única coisa que a matriz não consegue dizer

O `F` é **14 × 22**. Densa, isso são 308 entradas; a relação guarda **23**. Sete vírgula cinco por
cento.

⛔⛔⛔ **Na matriz, uma entrada nula e uma entrada ausente são o mesmo valor. Na relação são uma
linha que diz zero e nenhuma linha, e a diferença entre as duas é todo o assunto deste modelo.**
Um `0` em `F` diz que quem compôs considerou estas duas camadas e as julgou não fungíveis. Uma
linha em falta não diz coisa nenhuma. A álgebra linear tem um só símbolo para as duas.

A mesma lacuna atravessa todas as quantidades. Uma entrada de matriz vem de `ℝ`. Uma célula de
relação aqui vem de

```
ℝ  ⊎  {none, unmeasured, notApplicable, derived}
```

um coproduto, e não um número com uma sentinela. E o conjunto da direita não é fixo: numa posição
`pm:StatedClaim` estreita-se para o subconjunto de três membros sem o `none`, porque um zero
medido transporta unidade, observador e proveniência, e o ramo da ausência não tem lugar para
nenhum dos três. Um zero ali é uma afirmação de `[0, 0, 0]`. Essa distinção é irrepresentável em
`ℝ`, é a razão de o `NULL` ser recusado em todo o lado, e nove restrições `CHECK` seguram-na na
base de dados.

### A regra da composição é a inclusão-exclusão

```
x_composto = Σ x_partes − e            |A ∪ B| = |A| + |B| − |A ∩ B|
```

São a mesma identidade, com o `e` no lugar de `|A ∩ B|`. Esse enquadramento responde à pergunta
que a nota deixa em aberto acima, que é porque tem o `e` de ser declarado:

⛔ **De `|A|` e `|B|` nada recupera `|A ∩ B|`.** Uma camada transporta uma grandeza, nunca o
conjunto que a grandeza conta, portanto a correção não é uma função dos operandos. É esse todo o
argumento para a `asrt:Elimination` ser uma observação com um ramo `unmeasured`.

⭐⭐ **A não ser que se pivote para uma incidência cujos elementos transportem grandezas próprias,
e os do `F` transportam.** Uma parte É uma camada, e uma camada transporta a sua própria procura e
capacidade nominal. Exprima-se então uma sobreposição na base das partes e a correção sai
completa, sem nada declarado: o `eliminations/derived.sqlc` calcula-a. O teste é se os elementos
da incidência são eles próprios objetos medidos. Os do `F` são; os do `D` e do `N` não são, e o
mesmo pivô não compra ali nada.

⛔ O que o pivô não consegue nomear é o resíduo: uma sobreposição que é uma fatia de uma parte e
não uma parte inteira também não tem elemento na base pivotada. Esse caso, e só esse, é para o que
serve o elemento declarado.

### O quantum, e a aritmética da divisibilidade

A oferta chega em unidades inteiras, portanto `n mod q = 0`. Duas consequências que a formulação
matricial não tem maneira de enunciar.

**Existe um quantum composto, e é o máximo divisor comum.** Se as partes transportam `q₁` e `q₂` na
mesma unidade, então `n₁ = a q₁` e `n₂ = b q₂`, e toda a soma atingível `a q₁ + b q₂` é divisível
por `g = mdc(q₁, q₂)`, que é o maior número de que isso é verdade. ⚠️ Nem todo o múltiplo de `g`
é atingível: a identidade de Bézout é um enunciado sobre ℤ, e aqui `a` e `b` são contagens de
unidades inteiras. Sobre ℕ o conjunto atingível é o semigrupo numérico, pelo que `q₁ = 3, q₂ = 5`
dá `g = 1` enquanto 1, 2, 4 e 7 não se conseguem formar. Só o sentido direto é usado abaixo, e só
o sentido direto se verifica. O `mdc` exige ainda que os dois quanta sejam comensuráveis, o que é
uma condição viva porque são reais. Pedir um quantum "melhor" dentro de uma só camada é a
pergunta errada: ali
o quantum é OBSERVADO, e escolher o maior divisor de `n` seria inferir o facto a partir da figura.

⭐⭐⭐ **E por isso a eliminação tem de ser ela própria um múltiplo inteiro do quantum composto.**
`n_composto = n₁ + n₂ − e`, e o `g` divide a soma, portanto `g | n_composto` exige `g | e`. **Não
se pode eliminar meia máquina.** Verifica-se em todos os casos do conjunto onde é verificável: o
`every-local-part/both-views` elimina 2160 contra `q = 12`, que são 180 fornos inteiros.

⛔ **Entre unidades não há quantum composto nenhum, e a razão é mais estreita do que parece.** O
mdc é uma operação de uma só unidade. O `merge-holding-composition/compute` funde `720 GPU-hour`
com `8 GPU` e número nenhum divide os dois. Isso não são dados incómodos; é a mesma parede do `Φ`,
que é o que atravessa unidades, e um fator de conversão multiplica também um quantum. O `g = 1` é
o outro caso degenerado, onde a granularidade se dissolve e a oferta composta é, para todos os
efeitos, contínua.

### Elementos neutros, e onde uma ausência se pode fazer passar por um

Todas as quantidades deste modelo entram numa soma ou num produto. As três margens de
amortecedor são substitutas e somam-se: `inventory + capacity + time`, elemento neutro 0. Um
ciclo de serviço multiplica: `entregue = taxa × janela ÷ período`, elemento neutro 1. Um fator de
conversão e um quantum também multiplicam.

Onde uma gramática admite ao mesmo tempo um valor e uma ausência tipada na mesma posição, e a
ausência se pode ler como o elemento neutro dessa operação, as duas são duas grafias de um só
facto. A ausência é a grafia que perde. Não transporta unidade, nem autor da exatidão, nem
origem, portanto quem recebe não a consegue comparar aritmeticamente com quem escreveu um número.

**A regra que daí decorre: onde o ramo do valor nomeia o caso degenerado, o ramo da ausência não
pode poder dizer o mesmo.** Uma folga de zero é a menor folga e declara-se `[0, 0, 0]` na unidade
em que é zero. Uma oferta que corre continuamente tem uma fração de serviço de um e declara-se
como um período inteiro, cotado na unidade do próprio período, com a origem que diz quem a
poderia encurtar. Um resto de zero é uma folga, declarada com um sinal e uma quantidade de
`[0, 0, 0]`, porque o caso linha a linha da ISO 286 é uma folga cuja folga mínima é zero.

Um elemento neutro pode assentar numa ausência, mas só quando o neutro é **forçado**. São duas
condições e ambas são necessárias: o neutro tem de decorrer de estrutura que o documento já
declara, de modo que não haja autor a nomear nem nada que alguém assine; e a ausência não pode
deitar fora mais nada que o valor transportaria. Um fator de conversão entre duas unidades
idênticas é forçado, porque é a igualdade das unidades que o faz um, e um fator não transporta
mais nada. Uma fração de serviço de um não é forçada: uma linha pode correr continuamente porque
não se pode parar, porque alguém a prometeu ou porque alguém a guarneceu, e a ausência perde qual
delas. Um resto de zero é forçado por uma placa igual a uma procura, e ainda assim não pode ser
uma ausência, porque a ausência deita fora o sinal e os detentores.

E «forçado» é uma afirmação sobre que documentos conseguem alcançar a ausência, portanto só é
verdade onde uma regra a torna verdadeira. Uma conversão é obrigatória sempre que as unidades
diferem, o que deixa um fator omitido a significar uma só coisa: as unidades já concordam. Onde
nenhuma regra confina a ausência ao caso forçado, o valor pertence ao documento.

O resíduo é o caso honesto, e é uma terceira operação e não uma exceção. Uma seleção de um
conjunto fechado tem elemento neutro ∅: nenhum amortecedor absorveu o resto, nada fixa este
limite, alguém procurou acoplamentos e as camadas movem-se independentemente. Nada aí tem
tamanho, unidade nem autor, portanto nada se perde ao recusar o elemento, e essas posições
mantêm o vocabulário de ausência com os quatro membros.

### As leis são afirmadas, não presumidas

O `algebra/roster.sqlc` transporta uma linha por cada lei de álgebra de conjuntos que esta árvore
reivindica, e o `examples/soundness.rs` afirma cada uma em cada execução. **Uma diferença de
conjuntos em qualquer ponto da árvore sem lei nesse roster falha a construção.** As leis
substituem o que de outro modo seria uma sondagem à mão: o `|A| = |A∖B| + |A⋉B|` é verificado ao
vivo em vez de argumentado num comentário.

⚠️ Cinco sítios onde as duas álgebras divergem mesmo, e todos eles custaram aqui um defeito a
alguém antes de terem sido escritos:

- O `σ` acumula. `σ_p(σ_q(A)) = σ_{p∧q}(A)`, que é a razão de uma regra herdar filtros que nunca
  escreveu e de a sua população real viver em ficheiros que o autor não abriu.
- O `π` **não** distribui sobre o `∖`. Projete-se primeiro e subtrai-se sobre menos atributos,
  portanto uma diferença tem de ser tomada sobre a chave.
- Sacos não são conjuntos. O `composition/descent` é um saco de propósito; desduplicá-lo destruiria
  exatamente o facto que o `jagged_layer` existe para encontrar.
- ⛔ **O `γ` e um `σ` seguido de `π` são indistinguíveis pela cardinalidade, e respondem a perguntas
  opostas.** O `S` tem chave `(filing, layer, buffer)` e o assunto de qualquer regra tem chave
  `(filing, layer)`, portanto o índice do amortecedor tem de ser colapsado. Agregá-lo lê a linha
  inteira; filtrar por um amortecedor e deixar cair a coluna lê uma célula só. **Ambos dão a mesma
  chave, a mesma aridade e uma linha por camada**, pelo que qualquer lei da lista passa nos dois e
  contagem nenhuma os separa. Duas regras concluíram que houve procura por servir a partir de uma
  premissa apenas sobre a coluna da capacidade, que é uma afirmação sobre um de três amortecedores
  substituíveis. O indício nunca está no SQL: está em a prosa quantificar sobre a dimensão que a
  consulta deixou cair.
- ⛔ **Um `CASE` é uma partição por construção, pelo que a lei da partição não consegue ver
  predicados sobrepostos.** O `Σ|classes| = |candidatos|` verifica-se seja qual for o comportamento
  dos ramos, porque cada tuplo cai exatamente num deles façam o `p₁` e o `p₂` o que fizerem. A
  disjunção tem de ser sondada nos **predicados**, contando as linhas em que dois ramos se
  verificam ao mesmo tempo. O `Fit` publica três critérios e chama-lhes mutuamente exclusivos; o
  `clearance` e o `interference` verificam-se ambos quando uma capacidade nominal pontual iguala
  uma procura pontual, e o `layers/remainder.sqlc` resolve-o pela ordem dos ramos.

⚠️ E um custo, medido e não presumido: o `EXCEPT` é uma barreira de otimização. Perguntar ao
`composition/owed_equality` por uma só camada composta avalia a árvore inteira e deita fora dez de
onze linhas, porque uma diferença de conjuntos tem de materializar os dois lados antes de poder
subtrair. A anti-junção de que foi convertido empurra o predicado da chave para dentro dos três
ramos. A conversão foi feita por legibilidade, que é um ganho real; isto é o seu preço.

### Calculam-se os dois, e a concordância é a afirmação

O `examples/matrices.rs` constrói o `F`, o `Φ` e o `x` em `nalgebra` e avalia três produtos
matriciais. O `assets/sql/` avalia a mesma expressão como junções e `GROUP BY`. Nenhum deriva do
outro, e o exemplo afirma que concordam até `1e-9` sobre as onze camadas compostas que devem a
igualdade. O `checks/fusion_sum_disagrees` faz disso depois uma regra de conformidade e não um
teste.

⭐ É esse o sentido de transportar os dois. Uma formulação matricial é fácil de raciocinar e fácil
de errar em silêncio, porque qualquer erro de forma continua a produzir um número. Uma formulação
relacional é mais difícil de ler e falha alto. Correr as duas e afirmar a concordância é como uma
afirmação neste repositório ganha a palavra «verificado».

## Como verificar

`assets/corpus/enterprise-contract.xml` tem L=3, P=2. Duas das três camadas reproduzem `r = n − d`
exatamente, inversão de extremos incluída, pelo que a aritmética se verifica mecanicamente.
`assets/corpus/refutation.xml` regista uma entrada não nula de `C` com a observação que a produziu.
`assets/corpus/merge-holding-composition.xml` exercita `F`, `Φ` e o encaixe em conjunto. Não é
preciso construir nada: `xmllint --noout --schema schema/process-modulus.xsd <ficheiro>` e
`--schema schema/assertion.xsd` para as composições.
