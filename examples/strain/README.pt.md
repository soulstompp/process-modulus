**Português europeu.** O que é que o modelo tem de ser torcido para dizer?

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

Todos os outros exemplos perguntam se a maquinaria está certa. Este assume que está e vai procurar
os sítios a que ela não chega: situações comuns, de empresas comuns, que o esquema não tem maneira
honesta de exprimir. Um campo que tem de ser torcido para receber um facto é um achado acerca do
campo, e vale mais do que outro documento que encaixa.

⭐⭐⭐ O MÉTODO É GENERALIZAR UM PRESSUPOSTO DE CADA VEZ E VER O QUE SOBREVIVE. Cada sonda abaixo
muda exatamente uma coisa que o modelo dá por certa, mantém todo o resto, e reporta o que o arquivo
passa então a ter de afirmar. Dois dos três pressupostos revelam-se estruturais de maneiras que as
anotações não dizem.

⛔ NADA AQUI ACUSA UM ARQUIVO. Estas são perguntas sobre o ESQUEMA, portanto correm sem base de
dados e imprimem em vez de afirmar, exceto onde uma afirmação aritmética pode ser confrontada com
um crivo.

# Três grãos, dos quais o modelo arquiva dois

⚠️ A parte com mais probabilidade de valer o tempo de quem revê, porque é uma pergunta sobre o que
os intervalos SIGNIFICAM e não sobre o que lhes é feito.

Três escalas de tempo pesam sobre qualquer quantidade aqui. O **grão da transação** é o quantum
`q`, a unidade indivisível em que a oferta chega, arquivada com uma origem que diz quem a fixa.
O **grão do relato** é o denominador da unidade: `por trimestre`, `por semana`. O **grão da
variação**, a escala de tempo em que a quantidade de facto se move, não é arquivado em sítio
nenhum.

O primeiro é o próprio assunto do modelo: `r = mq − (d mod q)`, que a §6 do
`examples/matrices/main.rs` avalia. O terceiro importa porque duas operações dependem dele em
silêncio.

**Um ciclo de serviço dobra-se numa taxa e desaparece.** Uma linha a correr das 02:00 às 05:00 a
uma unidade por cinco segundos tem valor nominal de 2160/dia; contra 2000/dia de procura, a folga é
160/dia qualquer que seja o horário. Mas a *duração* a que essa folga corresponde não sobrevive: o
ingénuo `q / folga` dá 9 minutos, enquanto a espera real é de 68 segundos dentro da janela ou de 21
horas fora dela. Nove minutos não ocorre em sítio nenhum. Portanto uma folga é arquivada como
quantidade na unidade da camada, nunca como a duração em que foi observada, e quem arquiva deve a
conversão. A sonda 3 e a sonda 4 são esse pressuposto generalizado.

⛔ **Uma segunda consequência parece seguir-se daqui e não se segue, e a razão por que falha vale
mais do que a afirmação teria valido.** Ela corre assim: uma fila absorve um transiente e nunca um
excesso permanente, portanto em `ρ > 1` a acumulação cresce sem limite, portanto a procura de
`[11.0, 12.7, 14.4]` do `shift-line` contra uma linha de 10 turnos precisa que a leitura da
variação seja coerente. **`ρ > 1` só dá acumulação sem limite com paciência infinita**, e o
`timeSlack` É uma paciência, *«antes de quem chama ir a outro sítio»*, arquivada como
`contractual`. Uma fila com desistência é estável a qualquer `ρ`: a acumulação cresce até a espera
alcançar a paciência, e depois a procura parte à taxa a que o excesso chega. Nada aqui precisa da
leitura da variação.

⭐ E a aritmética é exata, que é a parte a verificar: paciência `2,5 turnos = 0,25 semana` a
`μ = 10/semana` põe a profundidade de equilíbrio em `μW = 2,5` itens, a espera fica À paciência,
enquanto a taxa de partida é `λ − μ = 2,7/semana` e os detentores arquivados são
`cliente 1,7 + não realizado 1,0 = 2,7`. A regra da soma e o equilíbrio da fila concordam.

⛔⛔ ESSE ÚLTIMO PARÁGRAFO É A ÚNICA AFIRMAÇÃO DESTE FICHEIRO QUE NADA AVALIA. As suas quatro
figuras estão todas em `assets/corpus/merge-holding-composition.xml`; o `entries/borne.sqlc`
transporta a metade `1,7 + 1,0` como comentário e nenhuma relação calcula `μW` contra `λ − μ`. É
exatamente a forma que este repositório recusa noutros sítios: uma identidade a partir da qual um
leitor reconstrói o modelo, apoiada na aritmética de alguém e não numa execução.

⭐ O `Claim` continua a ler-se como epistémico do princípio ao fim: «mais provável», «o valor que
um estimador consegue honestamente declarar», e o `narrowsWhen`, que significa *este intervalo é
aquilo que ninguém sabe*. A variação genuína não estreita quando se mede com mais afinco, e as duas
leituras não são distinguidas. Essa ambiguidade é real; o que ela NÃO é é a coisa que faz um
amortecedor de tempo funcionar.

⭐⭐ **A metade do ciclo de serviço disto é um segundo eixo e não um terceiro valor.** A escolha do
`Divisibility` é `lumpy | continuous`, e lidas como funções da quantidade pedida, `continuous` é uma
reta e `lumpy` é uma escada `q·floor(x/q)`. Um ciclo de serviço é a mesma escada no eixo do *tempo*,
uma onda quadrada. Não é um terceiro membro da escolha, porque nós de oito GPU disponíveis só das
02:00 às 05:00 são grosseiros em quantidade **e** intermitentes no tempo, pelo que o tipo é uma
sequência: a escolha, e depois um `window` opcional. O seu tamanho é um `LumpyQuantum`, e o
*período* vem de graça da regra do denominador acima.

O `window` obedece a uma regra a que mais nada aqui obedece: **é transportado através de uma fusão
e nunca somado.** Dois membros que nomeiam a mesma máquina arquivam um só calendário entre si; o
`F Φ` daria dez dias por semana. É uma propriedade e não uma quantidade, que é também a razão pela
qual o vetor de eliminação `e_x` corre sobre procura, valor nominal e draw e não tem quarta
componente. O `checks/window_lost_or_summed` é a regra; a sonda 3 é a razão pela qual existe.

⛔ **O grão da variação em si continua sem elemento, e esta é a pergunta aberta.** Um `period` no
`Claim` toca cada sítio que lê a largura de uma afirmação; uma marca `ignorance | variation` é
uma falsa escolha, já
que a resposta honesta é normalmente ambas; e qualquer das duas é um eixo de tempo a entrar num
modelo que deliberadamente não transporta nenhum. **Se vê uma quarta opção, é a coisa mais útil que
nos pode devolver.**
