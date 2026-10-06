**Português europeu.** Onde é que o modelo tem de forçar a realidade para a conseguir declarar?

> **Grafia do AO90.** Também disponível em inglês: `examples/strain/README.md`.

Este programa, que não precisa de base de dados, pega em pressupostos do modelo e põe-lhes à frente
casos para que não foram feitos, uns calculados à mão, outros simulados no NeXosim, e em cada caso
diz onde o modelo verga: a regra que passa sobre uma declaração falsa, o facto que não tem elemento
onde caber, as duas declarações corretas que ninguém consegue reconciliar. Uma oferta que vem em
lotes de dois tamanhos só pode declarar um quantum, e todas as maneiras de o escolher são falsas: o
lote pequeno nega que o grande exista, o grande nega o pequeno, e um quantum de uma unidade diz que
a oferta se divide à unidade, que é justamente o que ela não faz, sendo esta a que
`nameplate_not_a_multiple` deixa passar. Uma procura que chega em blocos inteiros não tem onde o
dizer, porque a divisibilidade pertence à capacidade nominal, e trocar os papéis acerta no resto e
erra em quem o suporta.

A mesma transação, declarada pelos dois lados, dá restos quase iguais quando alguém sai prejudicado
e restos que não coincidem de todo quando ninguém sai, já que um resto é um facto sobre a capacidade
nominal de uma das partes e não sobre a transação. E as urgências de um hospital, que medem há
muito, com nomes seus, quem desiste de esperar, reaparecem na simulação de um serviço cuja produção
não se guarda, e não na de uma linha que pode guardar existências, porque, tirado um dos três
amortecedores, o tempo carrega com tudo e mede-se em pessoas que se foram embora.

## Períodos dentro de períodos, que nenhum elemento junta

O modelo declara duas escalas de tempo: o período, no denominador da unidade, por semana ou por dia,
e a janela, a parte desse período em que a oferta está ativa, em `pm:Divisibility/window`. Uma
terceira, a de um período mais curto dentro de outro mais comprido, fica de fora. O programa corta
em quartos de hora a mesma execução de uma linha que trabalha perto da sua capacidade, e a
declaração do conjunto dá `clearance` enquanto vários quartos de hora dão `interference`, sendo as
duas leituras aritmética certa sobre os mesmos acontecimentos; onde um quarto de hora recusa procura
a sério, a sua declaração tem de nomear quem a suporta, `customer` ou `unrealised`, e a regra
`clearance_with_unserved` proíbe a declaração mais longa de nomear qualquer dos dois. Como nenhum
elemento diz que uma declaração é um pedaço da outra, regra nenhuma apanha o par. O mesmo se passa
com um lote que não cabe um número inteiro de vezes na janela: a capacidade nominal tem de ser um
múltiplo inteiro do quantum, a declaração legal arredonda-a para baixo, o que falta vai parar
inteiro ao resto, e o lote que fica a meio, trabalho em curso, não tem elemento nenhum onde se
declarar.

## Um ritmo diário esconde as horas em que a linha trabalha

Uma linha que só trabalha das 02:00 às 05:00, a um bolo de cinco em cinco segundos, tem uma
capacidade nominal de 2 160 bolos por dia, e com uma procura de 2 000 por dia sobra-lhe uma folga de
160 bolos por dia, que é a quantidade que se declara. Lida como tempo de espera, porém, a mesma
folga engana, porque dentro da janela há um bolo de folga a cada 68 segundos e fora dela passam 21
horas sem nenhum, de modo que quem a espalhar pelo dia inteiro está a fazer contas com horas em que
a linha está parada. O ritmo diário guarda a quantidade e perde a duração, e por isso só se pode
declarar a folga de tempo como derivação `clearance` quando a janela ocupa o período inteiro, ou
quando a unidade não tem período nenhum; é o que a regra `derived_slack_over_a_window` verifica, a
partir de `layers/derivation_licensed.sqlc`.

## A janela de uma linha partilhada não se soma

Os dois membros do grupo declaram a mesma linha de turnos, com uma capacidade nominal de 10 turnos
por semana e ativa 5 dias em cada semana, e o grupo, ao compô-los, elimina da capacidade a contagem
a dobrar. A janela, essa, nem se elimina nem se soma, porque é uma propriedade da linha e não uma
quantidade, pelo que o grupo e a holding declaram os mesmos 5 dias, quando somá-los daria semanas de
10 dias. A regra `window_lost_or_summed` apanha tanto a janela que se perde numa fusão como a que se
soma, e é por a janela não ser uma quantidade que `asrt:EliminationAgainst` tem três membros, a
procura, a capacidade nominal e o consumo, e nenhum quarto.

## Correr o programa

Não precisa de base de dados:

```text
cargo run --example strain
```
