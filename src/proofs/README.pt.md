**Português europeu.** As equações que este modelo enuncia, cada uma mostrada válida por um programa que o `cargo test` corre.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto. O código de cada entrada é o
> mesmo nas duas versões e só o da inglesa corre; aqui mudam apenas os comentários.

## Para que serve esta página

Os esquemas definem cada quantidade que uma declaração transporta, e as consultas em
`assets/sqlc/` calculam o que essas definições implicam. Algures entre os dois fica escrita uma
equação: o resto é a capacidade nominal menos a procura, a exposição é a maior procura contra a
menor oferta. Esta página é onde cada uma dessas equações é mostrada válida, sobre documentos que
qualquer pessoa pode abrir, por código que corre em cada compilação.

Os outros documentos deste repositório apontam para aqui em vez de voltarem a enunciar uma
equação. Os esquemas mantêm as suas definições normativas.

## Como se constrói uma entrada

Cada entrada tem quatro partes.

1. **O enunciado**, num bloco `text`, com os nomes que o esquema e as consultas usam.
2. **O que significa** para uma declaração, com valores trabalhados a partir de documentos reais.
3. **Um bloco em Rust** que lê esses documentos com os tipos do próprio crate e afirma cada valor
   que a entrada menciona. O `cargo test --doc` compila-o e corre-o.
4. **Onde a base de dados o sustenta**: a lei do `assets/sqlc/algebra/roster.sqlc` que recalcula o
   mesmo valor para cada documento carregado, e a regra do `assets/sqlc/checks/roster.sqlc` que
   acusa uma declaração que o contradiga. O `cargo run --example soundness` corre todas as leis.

Um bloco e uma lei provam metades diferentes. O bloco mostra o que a equação significa numa
declaração que um leitor pode verificar à mão; a lei mostra que a base de dados calcula a mesma
coisa para todas.

### O ficheiro partilhado

Todos os blocos começam pela mesma linha:

```text
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));
```

O `support.rs`, ao lado desta página, carrega documentos e lê valores deles, uma função por valor.
Não faz aritmética nenhuma além da tolerância de 1e-9 dentro da qual o `close` e o `close3`
comparam, que é a tolerância que as consultas usam. Cada subtração, limite e grandeza de que uma
prova depende está escrito no próprio bloco.

### Grelhas

Quando uma entrada afirma algo de todas as afirmações possíveis, e não só das declaradas, o seu
bloco verifica cada afirmação ordenada numa pequena grelha de números inteiros. Os inteiros são
exatos em vírgula flutuante, pelo que essas comparações não precisam de tolerância.

## 1. O resto e o seu ajuste

### A subtração cruzada

```text
r = n - d = [n_low - d_high,  n_mode - d_mode,  n_high - d_low]
```

O valor mais baixo do resto emparelha a menor oferta com a maior procura, e o mais alto emparelha a
maior oferta com a menor procura. Subtrair limite a limite descreve a mesma semana duas vezes: o
seu mínimo emparelharia a oferta da semana boa com a procura da semana boa. O emparelhamento cruzado
dá sempre uma afirmação ordenada; limite a limite não.

A camada `compute` da `refutation` declara uma procura de [11,0; 13,2; 16,4] GPU contra uma
capacidade nominal de [16,0; 16,0; 16,0], pelo que o `r` é [-0,4; 2,8; 5,0]: em falta no topo do
intervalo da procura e com sobra na base. A camada `labour` do `enterprise-contract` declara
[4,5; 5,2; 6,0] pessoas contra [4,0; 4,0; 4,0], pelo que o `r` é [-2,0; -1,2; -0,5], em falta de
ponta a ponta. Uma capacidade de [9, 10, 11] contra uma procura de [8, 12, 15] dá [-6, -2, 3];
limite a limite daria [1, -2, -4], cujo mínimo excede o máximo.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // n - d com os limites cruzados.
    let crossed = |n: Triple, d: Triple| (n.0 - d.2, n.1 - d.1, n.2 - d.0);

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    assert!(close3(demand(compute), (11.0, 13.2, 16.4)));
    assert!(close3(nameplate(compute), (16.0, 16.0, 16.0)));
    assert!(close3(crossed(nameplate(compute), demand(compute)), (-0.4, 2.8, 5.0)));

    let contract = filing("corpus/enterprise-contract.xml");
    let labour = layer(&contract, "labour");
    assert!(close3(demand(labour), (4.5, 5.2, 6.0)));
    assert!(close3(nameplate(labour), (4.0, 4.0, 4.0)));
    assert!(close3(crossed(nameplate(labour), demand(labour)), (-2.0, -1.2, -0.5)));

    let (capacity, need) = ((9.0, 10.0, 11.0), (8.0, 12.0, 15.0));
    assert!(close3(crossed(capacity, need), (-6.0, -2.0, 3.0)));
    let bound_by_bound = (capacity.0 - need.0, capacity.1 - need.1, capacity.2 - need.2);
    assert!(close3(bound_by_bound, (1.0, -2.0, -4.0)));
    assert!(bound_by_bound.0 > bound_by_bound.2);

    // Cada capacidade nominal ordenada contra cada procura ordenada, numa grelha de inteiros: o
    // emparelhamento cruzado sai ordenado todas as vezes.
    let mut claims = Vec::new();
    for low in 0..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    for &n in &claims {
        for &d in &claims {
            let r = crossed(n, d);
            assert!(r.0 <= r.1 && r.1 <= r.2);
        }
    }
}
```

**Entrada** `crossed_subtraction` · **Lei** `algebra/crossed_remainder`

### A grandeza

```text
|r| = [0 se r_low <= 0 <= r_high, senão min(|r_low|, |r_high|),  |r_mode|,  max(|r_low|, |r_high|)]
    = [max(r_low, -r_high, 0),  |r_mode|,  max(r_high, -r_low)]
```

A grandeza é quanto resto há, seja qual for o lado da capacidade nominal em que cai. O valor
absoluto não é monótono através do zero, pelo que, quando o `r` atravessa o zero, a menor grandeza
é 0, e não a menor das grandezas das duas pontas. Uma `quantity` declarada é este valor, e a soma
das quotas dos detentores de um resto também. A primeira linha é como o `layers/remainder.sqlc` o
calcula; a segunda é como o `algebra/crossed_remainder.sqlc` o verifica, e as duas concordam em
todo o `r` ordenado.

Para a `compute` da `refutation`, o `r` = [-0,4; 2,8; 5,0] dá `|r|` = [0,0; 2,8; 5,0], que é a
`quantity` que essa declaração enuncia. A grandeza da ponta menor poria um chão de 0,4 debaixo de
um resto que chega a zero. Para a `labour`, [-2,0; -1,2; -0,5] dá [0,5; 1,2; 2,0]. A
`support-cover` do `enterprise-contract` declara uma procura de [92, 118, 147] horas-engenheiro por
semana contra uma capacidade nominal de 168, uma folga cuja grandeza é o próprio `r`,
[21, 50, 76], e a quota do seu único detentor é esse valor.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let crossed = |n: Triple, d: Triple| (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    // Por casos, conforme o r atravesse ou não o zero.
    let by_cases = |r: Triple| {
        let low = if r.0 <= 0.0 && r.2 >= 0.0 { 0.0 } else { r.0.abs().min(r.2.abs()) };
        (low, r.1.abs(), r.0.abs().max(r.2.abs()))
    };
    // Em forma fechada.
    let closed = |r: Triple| (r.0.max(-r.2).max(0.0), r.1.abs(), r.2.max(-r.0));

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let r = crossed(nameplate(compute), demand(compute));
    assert!(close3(by_cases(r), (0.0, 2.8, 5.0)));
    assert!(close3(closed(r), (0.0, 2.8, 5.0)));
    assert!(close3(quantity(compute).expect("refutation states this quantity"), (0.0, 2.8, 5.0)));
    assert!(close(r.0.abs().min(r.2.abs()), 0.4));

    let contract = filing("corpus/enterprise-contract.xml");
    let labour = layer(&contract, "labour");
    let r = crossed(nameplate(labour), demand(labour));
    assert!(close3(by_cases(r), (0.5, 1.2, 2.0)));
    assert!(close3(closed(r), (0.5, 1.2, 2.0)));

    let cover = layer(&contract, "support-cover");
    assert!(close3(demand(cover), (92.0, 118.0, 147.0)));
    assert!(close3(nameplate(cover), (168.0, 168.0, 168.0)));
    let r = crossed(nameplate(cover), demand(cover));
    assert!(close3(r, (21.0, 50.0, 76.0)));
    assert!(close3(by_cases(r), r));
    let held = shares(cover);
    assert_eq!(held.len(), 1);
    assert!(close3(held[0].expect("the share is stated"), by_cases(r)));

    // Cada r ordenado numa grelha de inteiros de um lado e do outro do zero: as duas formas
    // concordam, e a própria grandeza sai ordenada.
    for low in -6..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                let r = (low as f64, mode as f64, high as f64);
                let m = by_cases(r);
                assert_eq!(m, closed(r));
                assert!(m.0 <= m.1 && m.1 <= m.2);
            }
        }
    }
}
```

**Entrada** `magnitude` · **Lei** `algebra/crossed_remainder` · **Regra**
`checks/stated_quantity_is_not_the_magnitude`, `checks/shares_do_not_sum`

### Os critérios de ajuste

```text
clearance     r_low >= 0             n_low >= d_high    a oferta excede a procura em todo o intervalo
interference  r_high <= 0            n_high <= d_low    a procura excede a oferta em todo o intervalo
transition    r_low < 0 < r_high                        os intervalos sobrepõem-se
```

O ajuste compara dois intervalos, e não dois pontos: o critério da própria ISO 286 para um furo e
um veio, emprestado intacto. Cada par de afirmações ordenadas cumpre pelo menos um critério.
Exatamente um tipo de par cumpre dois: uma capacidade nominal pontual igual a uma procura pontual,
em que o `r` é [0, 0, 0] e `clearance` e `interference` se verificam ambos, já que encadear os dois
obriga todos os limites a serem iguais. A sobreposição vem com o critério. A ISO 286-1:1988 define
os dois ajustamentos com «no caso extremo, igual a», nas cláusulas 4.10.1 e 4.10.2, e nunca tem de
escolher, porque as suas tolerâncias têm sempre largura. O `layers/remainder.sqlc` testa
`clearance` primeiro, pelo que esse par se lê como `clearance`: o desempate do modelo, que estende a
folga da ISO para o caso linha a linha, e a leitura sob a qual nada ficou por satisfazer.

Os ajustes declarados no conjunto de documentos leem-se da mesma maneira. A `compute` da
`refutation` sobrepõe-se e está declarada `transition`; a `labour` do `enterprise-contract` fica
toda abaixo da sua procura e está declarada `interference`; a sua `compute`, [3,1; 4,4; 6,0] GPU
contra 8, tem folga e está declarada `clearance`.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Os braços do layers/remainder.sqlc, pela sua ordem.
    let derived = |r_low: f64, r_high: f64| {
        if r_low >= 0.0 {
            "clearance"
        } else if r_high <= 0.0 {
            "interference"
        } else {
            "transition"
        }
    };

    let mut claims = Vec::new();
    for low in 0..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    let mut overlaps = 0;
    for &n in &claims {
        for &d in &claims {
            let (r_low, r_high) = (n.0 - d.2, n.2 - d.0);
            let clearance = r_low >= 0.0;
            let interference = r_high <= 0.0;
            let transition = r_low < 0.0 && r_high > 0.0;
            let met = [clearance, interference, transition].iter().filter(|&&c| c).count();
            assert!(met >= 1);
            if met == 1 {
                let only = if clearance {
                    "clearance"
                } else if interference {
                    "interference"
                } else {
                    "transition"
                };
                assert_eq!(derived(r_low, r_high), only);
            } else {
                assert!(clearance && interference && !transition);
                assert!(n.0 == n.2 && d.0 == d.2 && n.0 == d.0);
                assert_eq!(derived(r_low, r_high), "clearance");
                overlaps += 1;
            }
        }
    }
    // Um par sobreposto por cada valor pontual da grelha, pelo que o caso é exercitado.
    assert_eq!(overlaps, 7);

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    assert_eq!(derived(n.0 - d.2, n.2 - d.0), "transition");
    assert!(matches!(sign(compute), Some(FitType::Transition)));

    let contract = filing("corpus/enterprise-contract.xml");
    let labour = layer(&contract, "labour");
    let (d, n) = (demand(labour), nameplate(labour));
    assert_eq!(derived(n.0 - d.2, n.2 - d.0), "interference");
    assert!(matches!(sign(labour), Some(FitType::Interference)));

    let compute = layer(&contract, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    assert!(close3(d, (3.1, 4.4, 6.0)));
    assert_eq!(derived(n.0 - d.2, n.2 - d.0), "clearance");
    assert!(matches!(sign(compute), Some(FitType::Clearance)));
}
```

**Entrada** `fit_criteria` · **Lei** `algebra/crossed_remainder` · **Regra** `checks/fit_disagrees`

### A exposição

```text
exposure = max(-r_low, 0) = max(d_high - n_low, 0)
```

A exposição é o máximo que pode ter ficado por servir: a maior procura contra a menor oferta, com
chão em zero. Ninguém a mediu. É o teto que os dois valores da própria declaração implicam, e é por
isso que a regra construída sobre ela a compara com o que a declaração admite ter ficado por servir,
e não com uma leitura. É zero exatamente quando o ajuste é `clearance`, e nunca excede a maior
grandeza, `max(r_high, -r_low)`.

Para a `compute` da `refutation` é 16,4 menos 16, 0,4 GPU, o teto que a nota da própria declaração
dá para os pedidos que não conseguiu servir. Para a `labour` do `enterprise-contract` é 2,0
pessoas. A sua `compute` tem folga, e a sua exposição é 0.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let exposure = |n: Triple, d: Triple| (d.2 - n.0).max(0.0);

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    assert!(close(d.2, 16.4));
    assert!(close(exposure(n, d), 0.4));

    let contract = filing("corpus/enterprise-contract.xml");
    let labour = layer(&contract, "labour");
    assert!(close(exposure(nameplate(labour), demand(labour)), 2.0));
    let compute = layer(&contract, "compute");
    assert!(close(exposure(nameplate(compute), demand(compute)), 0.0));

    // Cada capacidade nominal ordenada contra cada procura ordenada numa grelha de inteiros: as
    // duas formas concordam, a exposição é zero exatamente na folga, e nunca excede a maior
    // grandeza.
    let mut claims = Vec::new();
    for low in 0..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    for &n in &claims {
        for &d in &claims {
            let (r_low, r_high) = (n.0 - d.2, n.2 - d.0);
            let e = exposure(n, d);
            assert_eq!(e, (-r_low).max(0.0));
            assert_eq!(e == 0.0, r_low >= 0.0);
            assert!(e <= r_high.max(-r_low));
        }
    }
}
```

**Entrada** `exposure` · **Lei** `algebra/exposure` · **Regra** `checks/exposure_unaccounted`

## 2. O quantum e o dente de serra

### Os pisos anulam-se

```text
k = n / q        m = k - floor(d / q)        residue = d mod q = d - q * floor(d / q)

m * q - residue = (n/q - floor(d/q)) * q - (d - q * floor(d/q)) = n - d
```

Um resto em unidades divide-se em quanta inteiros, `m * q`, que uma decisão de aprovisionamento
move, e num resíduo, que nenhuma escolha de quantos quanta deter remove. O piso aparece duas vezes
com sinais opostos, pelo que a divisão devolve `n - d` exatamente, para qualquer procura e qualquer
capacidade nominal, intervalo ou não.

A camada `compute` da `refutation` detém um quantum de 8 GPU e uma capacidade nominal de 16. No
canto baixo do resto a procura é 16,4: o `m` é 0 e o resíduo 0,4, pelo que o `r` é -0,4. Na moda,
13,2 dá `m` = 1 e um resíduo de 5,2, pelo que o `r` é 2,8. No canto alto, 11,0 dá `m` = 1 e um
resíduo de 3,0, pelo que o `r` é 5,0.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // A divisão, que devolve (m, resíduo, m * q - resíduo).
    let split = |n: f64, d: f64, q: f64| {
        let m = n / q - (d / q).floor();
        let residue = d - q * (d / q).floor();
        (m, residue, m * q - residue)
    };

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    let q = quantum(compute).expect("compute is lumpy").1;
    assert!(close(q, 8.0));

    // Os pares cruzados: o canto baixo emparelha n_low com d_high.
    let (m, residue, r) = split(n.0, d.2, q);
    assert!(close(d.2, 16.4) && close(m, 0.0) && close(residue, 0.4) && close(r, -0.4));
    let (m, residue, r) = split(n.1, d.1, q);
    assert!(close(d.1, 13.2) && close(m, 1.0) && close(residue, 5.2) && close(r, 2.8));
    let (m, residue, r) = split(n.2, d.0, q);
    assert!(close(d.0, 11.0) && close(m, 1.0) && close(residue, 3.0) && close(r, 5.0));

    // Cada capacidade nominal e procura numa grelha de inteiros, para vários quanta, seja ou não
    // a capacidade nominal um múltiplo: a divisão devolve n - d.
    for q in 1..=5 {
        for n in 0..=20 {
            for d in 0..=20 {
                let (_, _, r) = split(n as f64, d as f64, q as f64);
                assert!(close(r, (n - d) as f64));
            }
        }
    }
}
```

**Entrada** `floors_cancel` · **Lei** `algebra/remainder_decomposes`

### A congruência

```text
n = k * q com k inteiro   ==>   r = n - d ≡ -d (mod q)
```

Uma capacidade nominal em unidades é um número inteiro de quanta, pelo que `r + d = n` é um
múltiplo de `q`, e o resto fica no mesmo sítio dentro de um quantum que a procura com o sinal
trocado. Deter mais um quantum move o `r` um quantum inteiro e nunca move esse sítio: o resíduo é
fixado pela procura.

Para a `compute` da `refutation`, `r + d` é 16 nos três cantos: -0,4 + 16,4, 2,8 + 13,2 e
5,0 + 11,0, cada um dois quanta de 8.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    let q = quantum(compute).expect("compute is lumpy").1;
    let r = (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    assert!(close3(r, (-0.4, 2.8, 5.0)));
    for (r, d) in [(r.0, d.2), (r.1, d.1), (r.2, d.0)] {
        assert!(close(r + d, 16.0) && close(r + d, 2.0 * q));
    }
    assert!(close3(d, (11.0, 13.2, 16.4)));

    // Cada número inteiro de quanta contra cada procura inteira: r e -d deixam o mesmo resíduo.
    for q in 1..=5_i64 {
        for k in 0..=6_i64 {
            for d in 0..=30_i64 {
                let r = k * q - d;
                assert_eq!(r.rem_euclid(q), (-d).rem_euclid(q));
            }
        }
    }
}
```

**Entrada** `congruence` · **Regra** `checks/nameplate_not_a_multiple`

### As duas leituras

```text
up   = (-d) mod q     em [0, q)     o que uma capacidade arredondada para cima a um quantum inteiro deixa de sobra
down = -(d mod q)     em (-q, 0]    o que uma capacidade arredondada para baixo a um quantum inteiro deixa em falta

up - down = q, exceto quando q divide d, e aí ambos são 0
```

Folga e interferência são uma só divisão lida de lados opostos: o quantum inteiro mais próximo
acima da procura e o mais próximo abaixo. Os seus tamanhos somam um quantum inteiro, exceto sobre a
própria rede, em que a procura é um número inteiro de quanta e nenhum dos lados fica com nada.

Para uma procura de 13,2 contra um quantum de 8, arredondar para cima até 16 deixa 2,8 de sobra e
arredondar para baixo até 8 deixa 5,2 em falta, e 2,8 + 5,2 é 8. Para uma procura de 16 ambos são 0.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let readings = |d: f64, q: f64| {
        let up = (-d).rem_euclid(q);
        let down = -(d.rem_euclid(q));
        (up, down)
    };

    let (up, down) = readings(13.2, 8.0);
    assert!(close(up, 2.8) && close(down, -5.2) && close(up - down, 8.0));
    let (up, down) = readings(16.0, 8.0);
    assert!(close(up, 0.0) && close(down, 0.0));

    // Cada procura inteira contra vários quanta: os dois tamanhos somam q fora da rede, e
    // anulam-se ambos sobre ela.
    for q in 1..=6 {
        for d in 0..=40 {
            let (up, down) = readings(d as f64, q as f64);
            assert!(up >= 0.0 && up < q as f64 && down <= 0.0 && down > -(q as f64));
            if d % q == 0 {
                assert!(up == 0.0 && down == 0.0);
            } else {
                assert_eq!(up - down, q as f64);
            }
        }
    }
}
```

**Entrada** `two_readings` · **Lei** `none`

### O múltiplo mais próximo

```text
distância de d ao múltiplo inteiro de q mais próximo = min(d mod q, q - d mod q)
```

O mais perto que qualquer decisão sobre quantos quanta deter consegue trazer a oferta à procura.
Escolha-se o que se escolher, esta parte do resto fica, e é o resíduo lido pelo lado mais curto.

Para uma procura de 13,2 contra um quantum de 8 é 2,8: 16 está mais perto do que 8.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let formula = |d: f64, q: f64| d.rem_euclid(q).min(q - d.rem_euclid(q));
    // O múltiplo mais próximo, encontrado experimentando cada número inteiro de quanta até bem
    // depois de d.
    let searched = |d: f64, q: f64| {
        (0..=200)
            .map(|k| (d - k as f64 * q).abs())
            .fold(f64::INFINITY, f64::min)
    };

    assert!(close(formula(13.2, 8.0), 2.8) && close(searched(13.2, 8.0), 2.8));

    for q in 1..=6 {
        for d in 0..=60 {
            let (d, q) = (d as f64, q as f64);
            assert_eq!(formula(d, q), searched(d, q));
        }
    }
}
```

**Entrada** `nearest_multiple` · **Lei** `none`

### O dente de serra

```text
floor(d_low / q) = floor(d_high / q)   ==>   d_low mod q <= d_mode mod q <= d_high mod q

o recíproco falha: (0.2, 1.5, 2.7) com q = 1 dá os resíduos (0.2, 0.5, 0.7), ordenados, atravessando dois dentes
```

O resíduo volta a zero em cada múltiplo do quantum, pelo que, lido nos três pontos de uma procura,
não tem de sair ordenado, e um trio desordenado não é afirmação nenhuma. Dentro de um dente, em que
nenhum múltiplo cai entre o mínimo e o máximo, sai sempre ordenado. O recenseamento conta as
procuras que atravessam um dente, e não os resíduos desordenados, porque um trio ordenado pode
atravessar na mesma. É por isso que o esquema transporta o total do resto e nunca a sua divisão.

A procura da `compute` da `refutation`, [11,0; 13,2; 16,4] contra um quantum de 8, atravessa 16, e
os seus resíduos são (3,0; 5,2; 0,4). Uma procura de (4,5; 5,2; 6,7) contra 1 atravessa dois
dentes e dá (0,5; 0,2; 0,7).

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let residues = |d: Triple, q: f64| (d.0.rem_euclid(q), d.1.rem_euclid(q), d.2.rem_euclid(q));
    let crosses = |d: Triple, q: f64| (d.0 / q).floor() != (d.2 / q).floor();
    let ordered = |r: Triple| r.0 <= r.1 && r.1 <= r.2;

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, q) = (demand(compute), quantum(compute).expect("compute is lumpy").1);
    assert!(close3(d, (11.0, 13.2, 16.4)) && crosses(d, q));
    assert!(close3(residues(d, q), (3.0, 5.2, 0.4)) && !ordered(residues(d, q)));

    let d = (4.5, 5.2, 6.7);
    assert!(crosses(d, 1.0) && close3(residues(d, 1.0), (0.5, 0.2, 0.7)));

    let d = (0.2, 1.5, 2.7);
    assert!(crosses(d, 1.0) && close3(residues(d, 1.0), (0.2, 0.5, 0.7)));
    assert!(ordered(residues(d, 1.0)));

    // Cada procura ordenada numa grelha de inteiros, para vários quanta: dentro de um dente os
    // resíduos saem sempre ordenados.
    for q in 1..=5 {
        for low in 0..=15 {
            for mode in low..=15 {
                for high in mode..=15 {
                    let d = (low as f64, mode as f64, high as f64);
                    if !crosses(d, q as f64) {
                        assert!(ordered(residues(d, q as f64)));
                    }
                }
            }
        }
    }
}
```

**Entrada** `sawtooth` · **Lei** `algebra/sawtooth`

### O quantum composto

```text
g = gcd(q1 * f1, q2 * f2, ...)       o quantum de cada parte convertido pelo seu fator

todo a1 * q1 * f1 + a2 * q2 * f2 + ... com a inteiro >= 0 é múltiplo de g, e g é o maior
nem todo o múltiplo de g é atingível: com quanta de 4 e 6, g = 2 e 2 = 4a + 6b não tem solução
```

Uma oferta composta a partir de partes em unidades continua a chegar em unidades inteiras, e a
maior unidade que divide todos os totais que as partes conseguem fazer é o máximo divisor comum dos
seus quanta, cada um convertido primeiro para a unidade da camada composta. As combinações inteiras
chegam a todos os múltiplos de `g`, mas ninguém detém um número negativo de unidades, pelo que os
totais de facto atingíveis são um semigrupo numérico: múltiplos de `g`, todos a partir de certo
ponto, não todos abaixo dele. Para dois quanta primos entre si, `a` e `b`, o maior total fora de
alcance é `a * b - a - b`, a fórmula de Sylvester.

A `compute` da `merge-holding-composition` funde uma parte de 8 GPU, convertida a um fator de
[672, 720, 744] GPU-hora por GPU, com uma parte de 720 GPU-hora. Na moda do fator o primeiro quantum
é 5760 GPU-hora, o `g` é 720, e a capacidade nominal composta declarada, 6480, são nove deles. Sem
conversão, a dobra daria 8, que também divide 6480: o total declarado sozinho não distingue os dois,
e é por isso que este bloco afirma o valor convertido.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    fn gcd(a: i64, b: i64) -> i64 {
        if b == 0 {
            a
        } else {
            gcd(b, a % b)
        }
    }

    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let us = quantum(layer(&group.process_modulus, "compute-us")).expect("lumpy");
    let pt = quantum(layer(&group.process_modulus, "compute-pt")).expect("lumpy");
    let f = factor(part(fusion(&holding, "compute"), "compute-us")).expect("a stated factor");
    assert!(close(us.1, 8.0) && close(pt.1, 720.0));
    assert!(close3(f, (672.0, 720.0, 744.0)));

    let converted = us.1 * f.1;
    assert!(close(converted, 5760.0));
    let g = gcd(converted as i64, pt.1 as i64);
    assert_eq!(g, 720);
    let filed = nameplate(layer(&holding.process_modulus, "compute")).1;
    assert!(close(filed, 6480.0));
    assert_eq!(filed as i64 % g, 0);
    assert_eq!(filed as i64 / g, 9);
    // Sem conversão, a dobra dá 8, e 8 também divide o total declarado.
    assert_eq!(gcd(us.1 as i64, pt.1 as i64), 8);
    assert_eq!(filed as i64 % 8, 0);

    // Quanta de 4 e 6: todo o total atingível é par, 2 não é atingível, e todo o total par a
    // partir de 4 é.
    let attainable = |t: i64, a: i64, b: i64| (0..=t / a).any(|x| (t - x * a) % b == 0);
    assert_eq!(gcd(4, 6), 2);
    assert!(!attainable(2, 4, 6));
    for t in 0..=60 {
        if attainable(t, 4, 6) {
            assert_eq!(t % 2, 0);
        }
        if t >= 4 && t % 2 == 0 {
            assert!(attainable(t, 4, 6));
        }
    }

    // A fórmula de Sylvester, verificada por busca para pequenos pares primos entre si.
    for a in 2..=9 {
        for b in (a + 1)..=10 {
            if gcd(a, b) != 1 {
                continue;
            }
            let largest_missed = (0..=a * b).filter(|&t| !attainable(t, a, b)).max().unwrap();
            assert_eq!(largest_missed, a * b - a - b);
        }
    }
}
```

**Entrada** `composed_quantum` · **Lei** `algebra/composed_quantum`

## 3. Quotas, margens, exposição e consumo

### As quotas somam a grandeza

```text
Σ share_mode = |r|_mode        Σ share_low >= |r|_low        Σ share_high <= |r|_high
```

Os detentores de um resto são uma distribuição dele por quem o suportou, pelo que as quotas
declaradas dão conta da totalidade dele na moda. Nas pontas uma declaração pode conhecer as suas
quotas com mais precisão do que o intervalo do resto, pelo que a regra pede contenção aí; a
igualdade nas pontas acusaria a declaração mais cuidadosa. Uma quota por declarar suspende a regra,
porque a soma fica então desconhecida, e não curta.

A `support-cover` do `enterprise-contract` tem uma procura de [92, 118, 147] contra 168, um resto
de [21, 50, 76], e uma única quota `booked` exatamente igual. A `every-unserved-excess` tem uma
procura de [12, 14, 16] contra 10, um resto de [-6, -4, -2] cuja grandeza é [2, 4, 6], e duas
quotas, `customer` [1, 3, 4] e `unrealised` [1, 1, 2], que a somam.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let crossed = |n: Triple, d: Triple| (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    let magnitude = |r: Triple| (r.0.max(-r.2).max(0.0), r.1.abs(), r.2.max(-r.0));
    let sum = |shares: &[Triple]| {
        shares.iter().fold((0.0, 0.0, 0.0), |t, s| (t.0 + s.0, t.1 + s.1, t.2 + s.2))
    };
    let within = |s: Triple, m: Triple| close(s.1, m.1) && s.0 >= m.0 - 1e-9 && s.2 <= m.2 + 1e-9;

    let contract = filing("corpus/enterprise-contract.xml");
    let cover = layer(&contract, "support-cover");
    assert!(close3(demand(cover), (92.0, 118.0, 147.0)) && close(nameplate(cover).0, 168.0));
    let r = crossed(nameplate(cover), demand(cover));
    assert!(close3(r, (21.0, 50.0, 76.0)));
    let held: Vec<Triple> = holders(cover).into_iter().map(|(_, s)| s.expect("stated")).collect();
    assert!(close3(sum(&held), magnitude(r)) && within(sum(&held), magnitude(r)));

    let excess = filing("fixtures/every-unserved-excess.xml");
    let line = layer(&excess, "line");
    assert!(close3(demand(line), (12.0, 14.0, 16.0)) && close(nameplate(line).0, 10.0));
    let r = crossed(nameplate(line), demand(line));
    assert!(close3(r, (-6.0, -4.0, -2.0)) && close3(magnitude(r), (2.0, 4.0, 6.0)));
    let held = holders(line);
    assert!(matches!(held[0].0, HolderKindType::Customer) && close3(held[0].1.unwrap(), (1.0, 3.0, 4.0)));
    assert!(matches!(held[1].0, HolderKindType::Unrealised) && close3(held[1].1.unwrap(), (1.0, 1.0, 2.0)));
    let shares: Vec<Triple> = held.iter().map(|(_, s)| s.unwrap()).collect();
    assert!(within(sum(&shares), magnitude(r)));

    // Contenção nas pontas: um par de quotas mais estreito é aceite, um mais largo não.
    assert!(within((2.5, 4.0, 5.5), (2.0, 4.0, 6.0)));
    assert!(!within((1.5, 4.0, 6.0), (2.0, 4.0, 6.0)));
}
```

**Entrada** `share_sum` · **Regra** `checks/shares_do_not_sum`

### As quotas servidas ficam dentro da margem

```text
sob interferência:   Σ share_mode servidas  <=  slack_mode do amortecedor que o absorber nomeia
detentores servidos são booked, counterparty e people; customer e unrealised ficaram sem
```

Um amortecedor limita o que absorveu. Sob interferência o excesso acima da capacidade nominal foi
para algum lado, e um detentor `booked`, `counterparty` ou `people` diz que um amortecedor ficou com
parte dele, pelo que as quotas que esses detentores suportam não podem exceder o espaço que o
amortecedor nomeado pelo resto tinha. Os dois detentores que ficaram sem foram absorvidos por nada,
e o limite não se lhes aplica. Um amortecedor que ninguém dimensionou suspende-o: o seu espaço é
desconhecido, e não zero. O que os detentores suportam divide-se exatamente no que um amortecedor
absorveu e no que ficou por servir, e uma lei sustenta essa divisão em cada execução.

Nenhuma declaração carregada chega ao limite em si: todas as camadas em interferência com um
detentor servido deixam por dimensionar o amortecedor que nomeiam. Uma camada com 3 em falta cujo
amortecedor de capacidade consegue levar [0, 2, 3], com um detentor `people` a suportar [0, 2, 3] e
um detentor `customer` a suportar o resto, está dentro dele; a mesma camada com a quota `people`
numa moda de 2,5 não está.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let served = |k: &str| matches!(k, "booked" | "counterparty" | "people");
    let within = |holders: &[(&str, f64)], slack_mode: f64| {
        let borne: f64 = holders.iter().filter(|(k, _)| served(k)).map(|(_, s)| s).sum();
        borne <= slack_mode + 1e-9
    };

    let slack = (0.0, 2.0, 3.0);
    assert!(within(&[("people", 2.0), ("customer", 1.0)], slack.1));
    assert!(!within(&[("people", 2.5), ("customer", 0.5)], slack.1));
    // Os dois detentores não servidos estão isentos, por maiores que sejam as suas quotas.
    assert!(within(&[("customer", 2.0), ("unrealised", 1.0)], 0.0));

    // O que os detentores da every-unserved-excess suportam divide-se no que um amortecedor
    // absorveu e no que ficou por servir, e aqui nada foi absorvido.
    let excess = filing("fixtures/every-unserved-excess.xml");
    let held = holders(layer(&excess, "line"));
    let total: f64 = held.iter().map(|(_, s)| s.unwrap().1).sum();
    let absorbed: f64 = held
        .iter()
        .filter(|(k, _)| !matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s.unwrap().1)
        .sum();
    let unserved: f64 = held
        .iter()
        .filter(|(k, _)| matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s.unwrap().1)
        .sum();
    assert!(close(total, absorbed + unserved) && close(absorbed, 0.0) && close(unserved, 4.0));
}
```

**Entrada** `served_within_slack` · **Lei** `algebra/borne` · **Regra** `checks/share_exceeds_slack`

### A exposição é contabilizada

```text
exposure = max(0, d_high - n_low)  <=  Σ slack_high dos amortecedores + Σ share_high não servidas      no canto alto
```

A exposição é o máximo que pode ter ficado por servir, e é no máximo o que os três amortecedores
conseguiriam absorver mais o que a declaração admite ter ficado por servir. Os amortecedores são
substitutos, pelo que os três se somam, e um que ninguém dimensionou suspende a verificação. Lê-se
num só canto porque os dois lados de um resto que se sobrepõe à sua capacidade nominal estão
anticorrelacionados: somados ao longo do intervalo descrevem uma semana que nunca aconteceu.

A `every-unserved-excess` expõe 16 menos 10, 6 turnos, com todos os amortecedores a 0, e as suas
quotas não servidas chegam a 4 e a 2 nos máximos: 6, exatamente contabilizados. A `compute` da
`refutation` expõe 0,4 GPU com todos os amortecedores a 0, e declara a sua única quota não servida
como não medida, pelo que a verificação fica aí suspensa em vez de aprovada.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let excess = filing("fixtures/every-unserved-excess.xml");
    let line = layer(&excess, "line");
    let exposure = (demand(line).2 - nameplate(line).0).max(0.0);
    assert!(close(exposure, 6.0) && close(demand(line).2, 16.0));
    let buffers = [
        claim(&line.supply.nameplate.capacity_slack),
        claim(&line.supply.nameplate.inventory_slack),
        claim(&line.time_slack),
    ];
    let absorbable: f64 = buffers.iter().map(|b| b.expect("stated").2).sum();
    assert!(close(absorbable, 0.0));
    let unserved: f64 = holders(line)
        .iter()
        .filter(|(k, _)| matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s.unwrap().2)
        .sum();
    assert!(close(unserved, 6.0));
    assert!(exposure <= absorbable + unserved + 1e-9);

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    assert!(close((demand(compute).2 - nameplate(compute).0).max(0.0), 0.4));
    let unserved: Vec<Option<Triple>> = holders(compute)
        .into_iter()
        .filter(|(k, _)| matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s)
        .collect();
    assert!(unserved.iter().any(|s| s.is_none()));
}
```

**Entrada** `exposure_bound` · **Regra** `checks/exposure_unaccounted`

### Um consumo fica dentro do que a oferta consegue fazer

```text
draw_low  > n_high + capacity_high     o consumo inteiro está acima do que a oferta consegue fazer
draw_high <= n_low + capacity_low      o consumo inteiro fica abaixo
caso contrário                         os intervalos sobrepõem-se, e o documento não o decide

consumo, capacidade nominal e margem de capacidade numa só unidade
```

Uma oferta não consegue servir mais do que o seu valor nominal mais o espaço que tem acima dele. O
consumo é o que saiu, e só um consumo cujo intervalo inteiro está acima de tudo o que a oferta
conseguiria fazer é um erro de declaração; intervalos que se sobrepõem são um documento que não
consegue decidir a sua própria pergunta. O limite é da oferta e nunca da procura: a produção de uma
linha partilhada é em parte procura de outra pessoa.

A `support-cover` do `enterprise-contract` consumiu [92, 118, 147] horas-engenheiro por semana contra
uma capacidade nominal de 168 e uma margem de capacidade que chega a 40, e fica abaixo. Um consumo de
[800, 900, 1000] estaria acima da linha, já que 800 excede 208.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let verdict = |draw: Triple, n: Triple, slack: Triple| {
        if draw.0 > n.2 + slack.2 {
            "over the line"
        } else if draw.2 <= n.0 + slack.0 {
            "clears"
        } else {
            "overlaps"
        }
    };

    let contract = filing("corpus/enterprise-contract.xml");
    let cover = layer(&contract, "support-cover");
    let slack = claim(&cover.supply.nameplate.capacity_slack).expect("stated");
    assert!(close3(draw(cover), (92.0, 118.0, 147.0)) && close(slack.2, 40.0));
    assert!(close3(nameplate(cover), (168.0, 168.0, 168.0)));
    assert_eq!(verdict(draw(cover), nameplate(cover), slack), "clears");
    assert_eq!(verdict((800.0, 900.0, 1000.0), nameplate(cover), slack), "over the line");
    assert!(close(nameplate(cover).2 + slack.2, 208.0));
    assert_eq!(verdict((150.0, 180.0, 200.0), nameplate(cover), slack), "overlaps");
}
```

**Entrada** `draw_bound` · **Regra** `checks/draw_exceeds_the_supply`

## 4. Fusão e eliminações

### A soma da fusão

```text
x_composed = F Φ x_parts - e_x        para x em demand, nameplate, draw
```

O valor de uma camada composta é a soma dos valores das suas partes, cada um convertido para a
unidade da camada composta, menos o que o compositor eliminou por estar contado duas vezes. Vale
para cada quantidade separadamente, e uma eliminação nomeia exatamente uma delas. Só é devida onde
o compositor procurou duplas contagens e conseguiu dimensionar o que encontrou, e onde todas as
camadas que a soma lê declaram a quantidade; em todos os outros casos a soma fica suspensa, e não
aprovada.

O `labour` da `merge-group-composition` funde a procura do membro americano, [4,5; 5,2; 6,0]
pessoas, com a do membro português, [6,4; 7,1; 8,2], convertida a 1, e elimina [0,5; 0,8; 1,2] de
trabalho que ambos os membros declaram: [10,9; 12,3; 14,2] menos isso dá [10,4; 11,5; 13,0], a
procura que o grupo declara. A sua `shift-line` funde duas capacidades nominais de 10 que são a
mesma máquina, elimina 10, e declara 10; os dois consumos de 10 e 4,4 são os mesmos turnos
registados pelas duas pontas, pelo que 14,4 menos 4,4 dá os 10 que o grupo declara.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let sum = |a: Triple, b: Triple| (a.0 + b.0, a.1 + b.1, a.2 + b.2);
    let less = |a: Triple, e: Triple| (a.0 - e.0, a.1 - e.1, a.2 - e.2);

    let us = filing("corpus/merge-us-member.xml");
    let pt = filing("corpus/merge-pt-member.xml");
    let group = composition("corpus/merge-group-composition.xml");

    let labour = fusion(&group, "labour");
    let f = factor(part(labour, "pessoal")).expect("a stated factor");
    assert!(close3(f, (1.0, 1.0, 1.0)));
    let d_us = demand(layer(&us, "labour"));
    let d_pt = demand(layer(&pt, "pessoal"));
    assert!(close3(d_us, (4.5, 5.2, 6.0)) && close3(d_pt, (6.4, 7.1, 8.2)));
    let parts = sum(d_us, (d_pt.0 * f.0, d_pt.1 * f.1, d_pt.2 * f.2));
    assert!(close3(parts, (10.9, 12.3, 14.2)));
    let e = elimination(labour, EliminationAgainstType::Demand).expect("filed");
    assert!(close3(e, (0.5, 0.8, 1.2)));
    assert!(close3(less(parts, e), (10.4, 11.5, 13.0)));
    assert!(close3(demand(layer(&group.process_modulus, "labour")), less(parts, e)));

    let line = fusion(&group, "shift-line");
    let (us_line, pt_line) = (layer(&us, "shift-line"), layer(&pt, "linha-partilhada"));
    let n = sum(nameplate(us_line), nameplate(pt_line));
    let e = elimination(line, EliminationAgainstType::Nameplate).expect("filed");
    assert!(close3(n, (20.0, 20.0, 20.0)) && close3(e, (10.0, 10.0, 10.0)));
    assert!(close3(nameplate(layer(&group.process_modulus, "shift-line")), less(n, e)));

    let d = sum(draw(us_line), draw(pt_line));
    let e = elimination(line, EliminationAgainstType::Draw).expect("filed");
    assert!(close3(d, (14.4, 14.4, 14.4)) && close3(e, (4.4, 4.4, 4.4)));
    assert!(close3(draw(layer(&group.process_modulus, "shift-line")), less(d, e)));
    assert!(close3(less(d, e), (10.0, 10.0, 10.0)));
}
```

**Entrada** `fusion_sum` · **Lei** `algebra/fusion_sum` · **Regra** `checks/fusion_sum_disagrees`

### A eliminação, limite a limite

```text
limite a limite  [Σ low - e_low,  Σ mode - e_mode,  Σ high - e_high]    sempre que sai ordenado
cruzado          [Σ low - e_high, Σ mode - e_mode,  Σ high - e_low]     quando não sai
```

Uma eliminação retira uma componente do valor de onde é tirada, pelo que no canto baixo da soma a
sobreposição está no seu próprio mínimo: a subtração faz-se limite a limite, o contrário da
subtração cruzada de um resto. Esse emparelhamento pressupõe que a soma tem largura para a
sobreposição se mover com ela. Quando tem menos, o resultado limite a limite inverte-se, e o
emparelhamento cruzado é a única leitura ordenada: a maior sobreposição contra o menor total.

⭐ Qual é a condição de ordenação, dita uma vez: uma `Claim` declara o cone
`low ≤ mostLikely ≤ high`, e um valor que uma fusão declara tem de cair dentro dele. Portanto a escolha
entre os dois emparelhamentos não é uma preferência entre duas aritméticas. É aquele que fica dentro do
tipo, e o `eliminations/paired.sqlc` decide-o por eliminação a partir da soma e da sobreposição apenas.

A `every-partial-elimination` declara duas partes pontuais de 10 e um bloco partilhado de 3, pelo
que 20 menos 3 dá 17 de qualquer maneira. A `every-inverting-elimination` declara as mesmas partes
e um bloco partilhado de [2, 3, 5]: limite a limite isso dá [18, 17, 15], que não é afirmação
nenhuma, e a capacidade nominal composta que declara é o cruzado [15, 17, 18].

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let bound_by_bound = |t: Triple, e: Triple| (t.0 - e.0, t.1 - e.1, t.2 - e.2);
    let crossed = |t: Triple, e: Triple| (t.0 - e.2, t.1 - e.1, t.2 - e.0);
    let ordered = |r: Triple| r.0 <= r.1 && r.1 <= r.2;
    let eliminate = |t: Triple, e: Triple| {
        if ordered(bound_by_bound(t, e)) {
            bound_by_bound(t, e)
        } else {
            crossed(t, e)
        }
    };

    let partial = composition("fixtures/every-partial-elimination.xml");
    let e = elimination(fusion(&partial, "shift-capacity"), EliminationAgainstType::Nameplate)
        .expect("filed");
    let stack = &partial.process_modulus;
    let total = (20.0, 20.0, 20.0);
    assert!(close3(nameplate(layer(stack, "team-a")), (10.0, 10.0, 10.0)));
    assert!(close3(nameplate(layer(stack, "team-b")), (10.0, 10.0, 10.0)));
    assert!(close3(e, (3.0, 3.0, 3.0)));
    assert!(close3(eliminate(total, e), (17.0, 17.0, 17.0)));
    assert!(close3(nameplate(layer(stack, "shift-capacity")), eliminate(total, e)));

    let inverting = composition("fixtures/every-inverting-elimination.xml");
    let e = elimination(fusion(&inverting, "shift-capacity"), EliminationAgainstType::Nameplate)
        .expect("filed");
    assert!(close3(e, (2.0, 3.0, 5.0)));
    assert!(close3(bound_by_bound(total, e), (18.0, 17.0, 15.0)));
    assert!(!ordered(bound_by_bound(total, e)));
    assert!(close3(eliminate(total, e), (15.0, 17.0, 18.0)));
    let filed = nameplate(layer(&inverting.process_modulus, "shift-capacity"));
    assert!(close3(filed, eliminate(total, e)));

    // Cada total ordenado contra cada eliminação ordenada numa grelha de inteiros: o
    // emparelhamento cruzado sai sempre ordenado, pelo que a regra dá sempre uma afirmação, e
    // coincide com o limite a limite sempre que este é uma.
    let mut claims = Vec::new();
    for low in 0..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    for &t in &claims {
        for &e in &claims {
            assert!(ordered(crossed(t, e)));
            assert!(ordered(eliminate(t, e)));
            if ordered(bound_by_bound(t, e)) {
                assert_eq!(eliminate(t, e), bound_by_bound(t, e));
            }
        }
    }
}
```

**Entrada** `elimination_componentwise` · **Lei** `algebra/fusion_sum` · **Regra** `checks/fusion_sum_disagrees`

### Alargar uma parte alarga o valor; alargar uma eliminação estreita-o

```text
alargar a soma das partes   o valor composto alarga ou fica igual, em qualquer dos emparelhamentos
alargar uma eliminação      limite a limite, o valor composto ESTREITA.  Cruzado, alarga
```

Todas as larguras deste modelo alargam aquilo que tocam, com uma exceção, e a exceção é a eliminação.
Converter e somar são isótonos para a inclusão: uma parte declarada com menos precisão dá um valor
composto não mais preciso do que antes. Uma eliminação subtraída limite a limite inverte isso na sua
própria largura, porque o seu limite inferior levanta o limite inferior composto enquanto o seu limite
superior baixa o superior, portanto alargá-la nas duas pontas aproxima as duas. Quem compõe e está
menos seguro de quanto foi contado duas vezes declara então um valor composto mais preciso, que é o
único lugar aqui onde menos conhecimento produz uma resposta mais apertada.

⛔ O emparelhamento cruzado é isótono, e não é por isso que é escolhido. O
`eliminations/paired.sqlc` chega a ele só onde subtrair limite a limite deixaria a afirmação
desordenada, portanto a monotonia é uma consequência dessa reparação e não o seu motivo. Qual a leitura
que cada eliminação declarada toma, e portanto em que direção a sua própria largura empurra, é o
`eliminations/monotone.sqlc`.

Uma soma de [10, 12, 14] menos uma eliminação de [1, 1, 2] é [9, 11, 12]. Menos uma mais larga
[0, 1, 3] é [10, 11, 11]: o limite inferior subiu e o superior desceu, e o segundo valor não está
contido no primeiro.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let bb = |s: Triple, e: Triple| (s.0 - e.0, s.1 - e.1, s.2 - e.2);
    let crossed = |s: Triple, e: Triple| (s.0 - e.2, s.1 - e.1, s.2 - e.0);
    // `outer` contém `inner`: a leitura que uma entrada mais larga tem de dar se o operador for
    // isótono.
    let contains = |inner: Triple, outer: Triple| outer.0 <= inner.0 && inner.2 <= outer.2;

    let mut narrowed_by_a_wider_elimination = 0;
    for s0 in 0..6 {
        for s2 in s0..6 {
            for e0 in 0..4 {
                for e2 in e0..4 {
                    for d in 1..3 {
                        let (s0, s2) = (s0 as f64, s2 as f64);
                        let (e0, e2, d) = (e0 as f64, e2 as f64, d as f64);
                        let (s, e) = ((s0, s0, s2), (e0, e0, e2));
                        let wider_part = (s0 - d, s0 - d, s2 + d);
                        let wider_e = (e0 - d, e0 - d, e2 + d);

                        // Isótono na parte, nos dois emparelhamentos.
                        assert!(contains(bb(s, e), bb(wider_part, e)));
                        assert!(contains(crossed(s, e), crossed(wider_part, e)));

                        // Isótono na eliminação sob o emparelhamento cruzado, sempre.
                        assert!(contains(crossed(s, e), crossed(s, wider_e)));

                        // E não sob o limite a limite.
                        if !contains(bb(s, e), bb(s, wider_e)) {
                            narrowed_by_a_wider_elimination += 1;
                        }
                    }
                }
            }
        }
    }
    // Não é um canto da grelha: é o caso corrente de uma eliminação com largura.
    assert!(narrowed_by_a_wider_elimination > 0);

    // A testemunha mais pequena, escrita por extenso.
    let s = (10.0, 12.0, 14.0);
    assert_eq!(bb(s, (1.0, 1.0, 2.0)), (9.0, 11.0, 12.0));
    assert_eq!(bb(s, (0.0, 1.0, 3.0)), (10.0, 11.0, 11.0));
    assert!(!contains(bb(s, (1.0, 1.0, 2.0)), bb(s, (0.0, 1.0, 3.0))));
    assert!(contains(crossed(s, (1.0, 1.0, 2.0)), crossed(s, (0.0, 1.0, 3.0))));
}
```

**Entrada** `isotone_in_parts_not_in_eliminations` · **Lei** `none`

### Um valor derivado calcula-se através das suas partes

```text
x_derived = F Φ x_parts - e_x        uma parte declarada como derivação entra com o seu próprio x_derived
```

Um valor declarado como derivação `fusionSum` não declara valor nenhum: nomeia a identidade que o
calcula, uma saída que o recetor calcula. Numa camada composta calcula-se pela soma da fusão acima,
e uma parte que também declare uma derivação entra nessa soma com o valor que a sua própria fusão
calcula, pelo que o cálculo desce até que todos os caminhos cheguem a uma camada que declara o
valor. Pelo caminho, cada fator multiplica e cada eliminação subtrai. Quando uma camada num caminho
declara o valor ausente por qualquer outra razão, o valor derivado não se pode calcular, e fica sem
valor em vez de ser somado sobre o que se conseguiu encontrar.

O `pair` da `every-derived-quantity` declara a sua procura como derivação `fusionSum` e funde os
[10, 12, 14] da `line-a` com os [20, 24, 30] da `line-b`, menos [1, 2, 3] de encomendas que ambas as
linhas contam: a sua procura é [29, 34, 41]. O `site` funde o `pair` com os [5, 6, 8] da `line-c` e
declara [34, 40, 49], um valor que só se pode verificar através do valor do `pair`. O `single`
declara o seu consumo como derivação `fusionSum` apenas sobre a `line-d`, cujo consumo ninguém
mediu, pelo que não há nada a partir do qual o calcular.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let sum = |a: Triple, b: Triple| (a.0 + b.0, a.1 + b.1, a.2 + b.2);
    let less = |a: Triple, e: Triple| (a.0 - e.0, a.1 - e.1, a.2 - e.2);

    let fixture = composition("fixtures/every-derived-quantity.xml");
    let stack = &fixture.process_modulus;

    let pair = layer(stack, "pair");
    assert_eq!(derivation(&pair.demand.amount), Some(&IdentityType::FusionSum));
    let (a, b) = (demand(layer(stack, "line-a")), demand(layer(stack, "line-b")));
    assert!(close3(a, (10.0, 12.0, 14.0)) && close3(b, (20.0, 24.0, 30.0)));
    let f = fusion(&fixture, "pair");
    assert!(factor(part(f, "line-a")).is_none() && factor(part(f, "line-b")).is_none());
    let e = elimination(f, EliminationAgainstType::Demand).expect("filed");
    assert!(close3(e, (1.0, 2.0, 3.0)));
    let computed = less(sum(a, b), e);
    assert!(close3(computed, (29.0, 34.0, 41.0)));

    let c = demand(layer(stack, "line-c"));
    assert!(close3(c, (5.0, 6.0, 8.0)));
    let f = fusion(&fixture, "site");
    assert!(elimination(f, EliminationAgainstType::Demand).is_none());
    assert!(close3(sum(computed, c), (34.0, 40.0, 49.0)));
    assert!(close3(demand(layer(stack, "site")), sum(computed, c)));

    let single = layer(stack, "single");
    assert_eq!(derivation(&single.supply.jagged.draw), Some(&IdentityType::FusionSum));
    assert_eq!(fusion(&fixture, "single").part.len(), 1);
    let d = layer(stack, "line-d");
    assert_eq!(absence(&d.supply.jagged.draw), Some(&ClaimAbsenceReasonType::Unmeasured));
}
```

**Entrada** `derived_quantity` · **Lei** `algebra/derived_quantities` · **Regra** `checks/fusion_sum_disagrees`

### O produto é uma junção

```text
(F Φ x)[l] = Σ_p F[l, p] * Φ[p] * x[p] = Σ sobre as partes de l de fator * valor
```

O `F` é uma incidência, uma linha por camada composta e uma coluna por parte, com um 1 onde a parte
compõe a camada; o `Φ` é diagonal, um fator por parte. O seu produto por um vetor com os valores
das partes é o mesmo número que juntar cada parte à sua camada composta e somar os valores
convertidos por camada: a matriz e a relação são duas grafias de uma só soma. O
`examples/matrices/main.rs` constrói o produto com uma biblioteca de álgebra linear e afirma que é
igual à soma do SQL para cada camada composta e quantidade.

Para a `compute` da `merge-holding-composition`, a procura da parte americana, [3,1; 4,4; 6,0] GPU,
a um fator de [672, 720, 744] GPU-hora por GPU, mais a da parte portuguesa, [430, 545, 690]
GPU-hora, dá [2513,2; 3713,0; 5154,0], das duas maneiras. O seu `staff` é [10,4; 11,5; 13,0] mais
[2,3; 2,8; 3,4], ou seja [12,7; 14,3; 16,4].

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");

    // As partes, pela ordem das colunas, e as camadas compostas, pela ordem das linhas.
    let mut cols: Vec<(String, String, Triple, Triple)> = Vec::new();
    for f in &holding.fusion {
        for p in &f.part {
            let x = demand(layer(&group.process_modulus, &p.layer.filing.id));
            cols.push((f.name.clone(), p.layer.filing.id.clone(), factor(p).unwrap_or((1.0, 1.0, 1.0)), x));
        }
    }
    let rows: Vec<String> = holding.fusion.iter().map(|f| f.name.clone()).collect();

    for point in 0..3 {
        let at = |t: Triple| [t.0, t.1, t.2][point];

        // Como produto de matrizes: F (linhas x colunas) vezes diag(Φ) vezes x.
        let incidence: Vec<Vec<f64>> = rows
            .iter()
            .map(|r| cols.iter().map(|c| if c.0 == *r { 1.0 } else { 0.0 }).collect())
            .collect();
        let scaled: Vec<f64> = cols.iter().map(|c| at(c.2) * at(c.3)).collect();
        let product: Vec<f64> = incidence
            .iter()
            .map(|row| row.iter().zip(&scaled).map(|(f, x)| f * x).sum())
            .collect();

        // Como junção com GROUP BY: cada parte indexada pela sua camada composta, somada por chave.
        let mut grouped: std::collections::BTreeMap<&str, f64> = Default::default();
        for c in &cols {
            *grouped.entry(c.0.as_str()).or_default() += at(c.2) * at(c.3);
        }

        for (i, r) in rows.iter().enumerate() {
            assert!(close(product[i], grouped[r.as_str()]));
        }
        let compute = rows.iter().position(|r| r == "compute").unwrap();
        assert!(close(product[compute], at((2513.2, 3713.0, 5154.0))));
        let staff = rows.iter().position(|r| r == "staff").unwrap();
        assert!(close(product[staff], at((12.7, 14.3, 16.4))));
    }

    let us = cols.iter().find(|c| c.1 == "compute-us").unwrap();
    assert!(close3(us.2, (672.0, 720.0, 744.0)) && close3(us.3, (3.1, 4.4, 6.0)));
    let pt = cols.iter().find(|c| c.1 == "compute-pt").unwrap();
    assert!(close3(pt.3, (430.0, 545.0, 690.0)));
    let labour = cols.iter().find(|c| c.1 == "labour").unwrap();
    let on_call = cols.iter().find(|c| c.1 == "on-call").unwrap();
    assert!(close3(labour.3, (10.4, 11.5, 13.0)) && close3(on_call.3, (2.3, 2.8, 3.4)));
}
```

**Entrada** `product_is_join` · **Lei** `none`

### Uma parte é transportada

```text
uma fusão de uma parte que nada elimina:   x_composed = Φ x_part    para cada quantidade
```

Com uma só parte não há nada a somar, nada a subtrair e nenhum juízo a fazer, pelo que uma camada
composta que declare outra coisa que não a sua parte, convertida, alterou um valor que apenas
transportava. Vale para cada quantidade que a camada declara, incluindo as folgas dos
amortecedores, e não só para as três que uma fusão soma.

A `shift-line` da `merge-holding-composition` transporta a `shift-line` do grupo, sem fator: a sua
procura de [11,0; 12,7; 14,4] turnos por semana e a sua capacidade nominal e consumo de 10 passam
sem alteração.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let f = fusion(&holding, "shift-line");
    assert_eq!(f.part.len(), 1);
    assert!(elimination(f, EliminationAgainstType::Demand).is_none());
    assert!(elimination(f, EliminationAgainstType::Nameplate).is_none());
    assert!(factor(part(f, "shift-line")).is_none());

    let carried = layer(&group.process_modulus, "shift-line");
    let composed = layer(&holding.process_modulus, "shift-line");
    assert!(close3(demand(carried), (11.0, 12.7, 14.4)));
    assert!(close3(demand(composed), demand(carried)));
    assert!(close3(nameplate(composed), nameplate(carried)));
    assert!(close3(draw(composed), draw(carried)));
    assert!(close3(nameplate(composed), (10.0, 10.0, 10.0)));
    assert!(close3(draw(composed), (10.0, 10.0, 10.0)));
}
```

**Entrada** `one_part_carries` · **Regra** `checks/one_part_fusion_alters_its_part`

### Uma janela é transportada, nunca somada

```text
window_composed = window_part     para cada parte, nunca Σ window_parts
```

Um ciclo de serviço é um calendário, e duas partes que nomeiam uma só máquina declaram um só
calendário entre elas. As quantidades somam-se porque duas ofertas são duas ofertas; um calendário
não, porque é a mesma semana vista duas vezes. Por isso uma camada composta declara a janela que as
suas partes declaram, e somá-las daria uma máquina que trabalha mais dias do que a semana tem.

A `shift-line` da `merge-group-composition` funde duas partes que trabalham cada uma 5 dias por
semana, uma em `days` e outra em `dias`, e declara 5 dias, não 10. A holding transporta os mesmos 5.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let us = filing("corpus/merge-us-member.xml");
    let pt = filing("corpus/merge-pt-member.xml");
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");

    let (w_us, unit_us) = window(layer(&us, "shift-line")).expect("a window");
    let (w_pt, unit_pt) = window(layer(&pt, "linha-partilhada")).expect("a window");
    let (w_group, unit_group) = window(layer(&group.process_modulus, "shift-line")).expect("a window");
    let (w_holding, _) = window(layer(&holding.process_modulus, "shift-line")).expect("a window");
    assert_eq!((unit_us, unit_pt, unit_group), ("days", "dias", "days"));
    assert!(close3(w_us, (5.0, 5.0, 5.0)) && close3(w_pt, w_us));
    assert!(close3(w_group, w_us) && close3(w_holding, w_group));
    let summed = (w_us.0 + w_pt.0, w_us.1 + w_pt.1, w_us.2 + w_pt.2);
    assert!(close3(summed, (10.0, 10.0, 10.0)) && !close3(summed, w_group));
}
```

**Entrada** `window_carried` · **Regra** `checks/window_lost_or_summed`

### Um acoplamento atenua-se

```text
strength_upper <= strength_lower * share      share = max(Φ n_A) / min(n_X)
```

Se A se move com B, e A é fundida numa X maior um nível acima, a dependência sobrevive mas
enfraquece: o alívio aplicado a X pode cair nas outras partes em vez de em A, pelo que no máximo a
quota de A em X se pode mover. A quota é a capacidade nominal de A, convertida para a unidade de
X, sobre a capacidade nominal declarada de X, lida onde é maior, porque o limite acusa quando é
excedido e não pode acusar uma declaração correta.

O grupo declara o `labour` acoplado à `shift-line` a [0,10; 0,22; 0,35]. A holding funde o
`labour`, 10 pessoas, no `staff`, 12, e declara o `staff` acoplado à `shift-line` a
[0,06; 0,15; 0,26]: dentro da força do grupo vezes 10 em 12, em todos os limites.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");

    let lower = coupling(&group.process_modulus, "labour", "shift-line");
    let upper = coupling(&holding.process_modulus, "staff", "shift-line");
    assert!(close3(lower, (0.10, 0.22, 0.35)));
    assert!(close3(upper, (0.06, 0.15, 0.26)));

    let a = nameplate(layer(&group.process_modulus, "labour"));
    let x = nameplate(layer(&holding.process_modulus, "staff"));
    let f = factor(part(fusion(&holding, "staff"), "labour")).unwrap_or((1.0, 1.0, 1.0));
    let share = a.2 * f.2 / x.0;
    assert!(close(a.2, 10.0) && close(x.0, 12.0) && close(share, 10.0 / 12.0));

    let ceiling = (lower.0 * share, lower.1 * share, lower.2 * share);
    assert!(upper.0 <= ceiling.0 && upper.1 <= ceiling.1 && upper.2 <= ceiling.2);
    // A força do próprio grupo não é um teto que a holding possa atingir.
    assert!(upper.2 < lower.2);
}
```

**Entrada** `coupling_attenuates` · **Regra** `checks/coupling_does_not_attenuate`

## 5. Fatores de conversão e ciclos

### Um fator positivo multiplica limite a limite

```text
Φ > 0:   Φ x = [min(φ_low x_low, φ_high x_low),  φ_mode x_mode,  max(φ_low x_high, φ_high x_high)]
         que é [φ_low x_low, φ_mode x_mode, φ_high x_high] sempre que x >= 0
```

Um fator de conversão é estritamente positivo, pelo que o produto nunca reordena os limites de uma
afirmação: o seu mínimo vem do mínimo de `x` e o seu máximo do máximo de `x`, e só o canto do fator
depende do sinal. Para uma procura ou uma capacidade nominal, que não podem ser negativas, isso é o
produto limite a limite. Um resto pode ser negativo, e aí o mínimo toma o máximo do fator: mais
falta, convertida à taxa maior, é o número menor. O produto geral de quatro cantos, em que os dois
operandos atravessam o zero, nunca é preciso.

A `merge-holding-composition` converte a `compute-us` do grupo a [672, 720, 744] GPU-hora por GPU: a
sua capacidade nominal de 8 passa a [5376, 5760, 5952], a sua procura de [3,1; 4,4; 6,0] passa a
[2083,2; 3168; 4464], e o seu resto de [2,0; 3,6; 4,9] passa a [1344; 2592; 3645,6]. Um resto de
[-3,0; -1,5; -0,4] a um fator de [0,5; 1; 2] passa a [-6; -1,5; -0,2], onde limite a limite daria
[-1,5; -1,5; -0,8].

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let convert = |x: Triple, f: Triple| {
        ((x.0 * f.0).min(x.0 * f.2), x.1 * f.1, (x.2 * f.0).max(x.2 * f.2))
    };

    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let us = layer(&group.process_modulus, "compute-us");
    let f = factor(part(fusion(&holding, "compute"), "compute-us")).expect("a stated factor");
    assert!(close3(f, (672.0, 720.0, 744.0)));
    assert!(close3(convert(nameplate(us), f), (5376.0, 5760.0, 5952.0)));
    assert!(close3(demand(us), (3.1, 4.4, 6.0)));
    assert!(close3(convert(demand(us), f), (2083.2, 3168.0, 4464.0)));
    let r = (nameplate(us).0 - demand(us).2, nameplate(us).1 - demand(us).1, nameplate(us).2 - demand(us).0);
    assert!(close3(r, (2.0, 3.6, 4.9)));
    assert!(close3(convert(r, f), (1344.0, 2592.0, 3645.6)));

    let (r, f) = ((-3.0, -1.5, -0.4), (0.5, 1.0, 2.0));
    assert!(close3(convert(r, f), (-6.0, -1.5, -0.2)));
    assert!(close3((r.0 * f.0, r.1 * f.1, r.2 * f.2), (-1.5, -1.5, -0.8)));

    // Cada afirmação numa grelha de inteiros de um lado e do outro do zero, contra cada fator
    // positivo: a fórmula é o menor e o maior produto nos quatro cantos, e sai ordenada.
    let mut xs = Vec::new();
    for low in -4..=4 {
        for mode in low..=4 {
            for high in mode..=4 {
                xs.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    let mut fs = Vec::new();
    for low in 1..=4 {
        for mode in low..=4 {
            for high in mode..=4 {
                fs.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    for &x in &xs {
        for &f in &fs {
            let corners = [x.0 * f.0, x.0 * f.2, x.2 * f.0, x.2 * f.2];
            let lowest = corners.iter().cloned().fold(f64::INFINITY, f64::min);
            let highest = corners.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
            let c = convert(x, f);
            assert_eq!((c.0, c.2), (lowest, highest));
            assert!(c.0 <= c.1 && c.1 <= c.2);
            if x.0 >= 0.0 {
                assert_eq!(c, (x.0 * f.0, x.1 * f.1, x.2 * f.2));
            }
        }
    }
}
```

**Entrada** `positive_factor_componentwise` · **Lei** `algebra/composed_remainder`

### Uma conversão são duas inclinações e um sinal

```text
Φ x num limite = a·max(x, 0) − b·max(−x, 0)
  o inferior toma (a, b) = (φ_low, φ_high);  o superior toma o mesmo par trocado
```

A entrada acima dá a forma dos cantos. Esta diz que a forma dos cantos é o operador todo. Uma função
contínua de uma variável que é positivamente homogénea e linear por pedaços com uma única dobra é
exatamente duas inclinações unidas nessa dobra, portanto uma conversão tem dois graus de liberdade e o
sinal do seu operando, e não há mais nada a declarar sobre uma. O limite inferior e o superior são a
mesma função com as suas duas inclinações trocadas.

⭐ A dobra fica em zero e não pode ser deslocada, porque um operador desta forma não tem termo
independente com que a deslocar. O zero é onde um resto muda de sinal, que é a fronteira entre a folga
e a interferência, portanto o único ponto onde uma conversão muda de comportamento é o único ponto onde
o ajustamento também muda.

Um resto de 2,0 convertido a [672, 720, 744] toma 1344 no seu limite inferior: o limite inferior do
fator vezes a parte positiva, e nada vezes a parte negativa, que está ausente. A sua moda é 3,6 vezes
720, ou 2592. Um resto de -3,0 a [0,5; 1; 2] toma -6 no seu limite inferior: a parte negativa vezes o
limite superior do fator, que é a mesma fórmula a ler o seu outro ramo.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let relu = |x: f64| if x > 0.0 { x } else { 0.0 };
    let corner_low = |x: f64, lo: f64, hi: f64| (x * lo).min(x * hi);
    let corner_high = |x: f64, lo: f64, hi: f64| (x * lo).max(x * hi);
    let slopes = |x: f64, a: f64, b: f64| a * relu(x) - b * relu(-x);

    // A forma dos cantos e a forma das inclinações são uma só função, nos dois limites e em qualquer
    // sinal.
    for x in -40..=40 {
        for lo in 1..=12 {
            for hi in lo..=12 {
                let (x, lo, hi) = (x as f64, lo as f64, hi as f64);
                assert_eq!(corner_low(x, lo, hi), slopes(x, lo, hi));
                assert_eq!(corner_high(x, lo, hi), slopes(x, hi, lo));
            }
        }
    }

    // Duas inclinações são o operador todo: o seu valor é uma delas vezes o operando, nunca uma
    // terceira coisa, porque os dois ramos já cobrem os dois lados da única dobra.
    for x in -40..=40 {
        let x = x as f64;
        assert!(slopes(x, 3.0, 7.0) == 3.0 * x || slopes(x, 3.0, 7.0) == 7.0 * x);
    }

    // Os dois operandos que a entrada acima converte, lidos pela forma das inclinações.
    assert!(close(slopes(2.0, 672.0, 744.0), 1344.0));
    assert!(close(corner_low(2.0, 672.0, 744.0), 1344.0));
    assert!(close(3.6 * 720.0, 2592.0));
    assert!(close(slopes(-3.0, 0.5, 2.0), -6.0));
    assert!(close(corner_low(-3.0, 0.5, 2.0), -6.0));
}
```

**Entrada** `two_slopes` · **Lei** `none`

### Um mês não são 720 horas

```text
um mês = [28, 30, 31] dias × 24 = [672, 720, 744] horas
```

Uma reserva paga ao mês converte-se em horas conforme o mês que foi, pelo que o fator é um
intervalo cujos limites são os do calendário: o mês mais curto e o mais longo. O 720 do meio é um
mês de trinta dias, que é a convenção que um compositor escolheu para a moda, e não a média do ano
nem o comprimento mais comum. Um fator declarado como ponto afirmaria que todos os meses têm o mesmo
número de horas.

A `merge-holding-composition` declara exatamente este intervalo como o fator que converte as GPU do
grupo em GPU-hora.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let holding = composition("corpus/merge-holding-composition.xml");
    let f = factor(part(fusion(&holding, "compute"), "compute-us")).expect("a stated factor");
    assert!(close3(f, (28.0 * 24.0, 30.0 * 24.0, 31.0 * 24.0)));
    assert!(close3(f, (672.0, 720.0, 744.0)));

    // Os meses de um ano comum e de um ano bissexto, em horas: o mais curto e o mais longo são os
    // limites do fator, e 720 é um comprimento que alguns meses têm.
    for february in [28, 29] {
        let days = [31, february, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        let hours: Vec<f64> = days.iter().map(|d| (d * 24) as f64).collect();
        let shortest = hours.iter().cloned().fold(f64::INFINITY, f64::min);
        let longest = hours.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
        assert!(shortest >= f.0 && longest == f.2);
        assert!(hours.contains(&f.1));
    }
}
```

**Entrada** `month_hours` · **Lei** `none`

### Um ciclo de conversões volta ao início

```text
x →(φ1) →(φ2) → ... →(φk) x      exige      1 ∈ φ1 × φ2 × ... × φk
```

Converter uma quantidade ao longo de um ciclo de unidades tem de conseguir devolver aquilo com que
começou. Os fatores são intervalos, pelo que o produto ao longo do ciclo é um intervalo, e o máximo
que um recetor pode exigir é que o 1 esteja dentro dele. O fecho exato na moda está fora do alcance
de qualquer documento que declare decimais: um ciclo que passe por 720 precisa que os outros fatores
multipliquem 1/720, e 720 = 2⁴ × 3² × 5, enquanto um produto de decimais finitos só tem dois e cincos
no denominador. O nove é o obstáculo.

A `every-unit-cycle` converte GPU-hora em nó-hora a 0,125 e nó-hora em GPU a
[0,0108; 0,0112; 0,0116], e a `merge-holding-composition` converte GPU de volta em GPU-hora a
[672, 720, 744]. O produto ao longo do ciclo é [0,9072; 1,008; 1,0788], que contém o 1, e a sua
moda não é 1.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let cycle = composition("fixtures/every-unit-cycle.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let to_node = factor(part(fusion(&cycle, "node-capacity"), "reserved-hours")).expect("stated");
    let to_gpu = factor(part(fusion(&cycle, "cards"), "node-capacity")).expect("stated");
    let to_hours = factor(part(fusion(&holding, "compute"), "compute-us")).expect("stated");
    assert!(close3(to_node, (0.125, 0.125, 0.125)));
    assert!(close3(to_gpu, (0.0108, 0.0112, 0.0116)));
    assert!(close3(to_hours, (672.0, 720.0, 744.0)));

    let product = (
        to_node.0 * to_gpu.0 * to_hours.0,
        to_node.1 * to_gpu.1 * to_hours.1,
        to_node.2 * to_gpu.2 * to_hours.2,
    );
    assert!(close3(product, (0.9072, 1.008, 1.0788)));
    assert!(product.0 <= 1.0 && 1.0 <= product.2);
    assert!(!close(product.1, 1.0));

    // 720 = 2^4 * 3^2 * 5.
    assert_eq!(2_i64.pow(4) * 3_i64.pow(2) * 5, 720);
    // Dois decimais finitos p/10^i e q/10^j que fechassem o ciclo exatamente exigiriam
    // 720 * p * q = 10^(i + j). Nove divide o lado esquerdo e nunca uma potência de dez.
    for k in 0..=18 {
        assert_eq!(10_i64.pow(k) % 9, 1);
    }
    assert_eq!(720 % 9, 0);
}
```

**Entrada** `cycle_closes` · **Regra** `checks/conversion_cycle_does_not_close`

### Um caminho de conversões é uma só conversão

```text
Φ′(Φ x) = (Φ′Φ) x        em qualquer limite e em qualquer sinal, porque um fator positivo não move um sinal
```

Um fator é estritamente positivo, logo o canto que um limite toma é decidido pelo sinal daquilo que
está a ser convertido, e converter não pode mudar esse sinal. O canto é portanto o mesmo em todos os
níveis de um encaixe, e uma cadeia de fatores colapsa no seu produto. É isso que permite a uma descida
de resto transportar um só produto corrente por caminho e ler uma linha por nó estabilizado em vez de
recorrer, e é por isso que encaixar uma composição acrescenta testemunhos e não aritmética: o composto
tem as dobras das suas folhas e nenhuma outra.

⛔ O colapso para numa subtração, não numa profundidade. Um fator distribui-se por uma soma de partes e
não por uma eliminação tirada de uma delas, portanto uma eliminação intermédia com largura debaixo de
um fator com largura é onde o produto já não pode ser empurrado para baixo. É essa a regra de parada
que o `composition/unsettled.sqlc` enuncia e que o `composition/settled_remainders.sqlc` obedece, e é
por isso que a descida para num nó estabilizado e não numa folha.

O `every-nested-conversion` é o caminho de dois níveis deste corpus. O `line-hours` converte o
`line-runs` a [0,8; 1,0; 1,25] e o `line-batches` converte o `line-hours` a [0,5; 1,0; 2,0], portanto o
produto ao longo de todo o caminho é [0,4; 1,0; 2,5]. Um resto de 2 na folha chega a [0,8; 2,0; 5,0]
por qualquer das vias: passo a passo passa por 1,6 no nível intermédio e é dividido ao meio, e numa só
conversão é multiplicado pelo produto.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Uma conversão de um valor com sinal, em cada limite: o canto que o seu sinal escolhe.
    let lo_of = |x: f64, lo: f64, hi: f64| (x * lo).min(x * hi);
    let hi_of = |x: f64, lo: f64, hi: f64| (x * lo).max(x * hi);

    // Dois níveis contra um, sobre todos os operandos inteiros de cada lado da dobra e todos os
    // pares de cantos positivos inteiros.
    for x in -8..=8 {
        for a1 in 1..=4 {
            for a2 in a1..=4 {
                for b1 in 1..=4 {
                    for b2 in b1..=4 {
                        let (x, a1, a2) = (x as f64, a1 as f64, a2 as f64);
                        let (b1, b2) = (b1 as f64, b2 as f64);
                        assert_eq!(lo_of(lo_of(x, a1, a2), b1, b2), lo_of(x, a1 * b1, a2 * b2));
                        assert_eq!(hi_of(hi_of(x, a1, a2), b1, b2), hi_of(x, a1 * b1, a2 * b2));
                    }
                }
            }
        }
    }

    // O caminho encaixado do próprio corpus, lido da declaração e não repetido aqui.
    let nested = composition("fixtures/every-nested-conversion.xml");
    let inner = factor(part(fusion(&nested, "line-hours"), "line-runs")).expect("a stated factor");
    let outer = factor(part(fusion(&nested, "line-batches"), "line-hours")).expect("a stated factor");
    assert!(close3(inner, (0.8, 1.0, 1.25)) && close3(outer, (0.5, 1.0, 2.0)));

    let product = (inner.0 * outer.0, inner.1 * outer.1, inner.2 * outer.2);
    assert!(close3(product, (0.4, 1.0, 2.5)));

    let middle = lo_of(2.0, inner.0, inner.2);
    assert!(close(middle, 1.6));
    let stepwise = (
        lo_of(middle, outer.0, outer.2),
        2.0 * inner.1 * outer.1,
        hi_of(hi_of(2.0, inner.0, inner.2), outer.0, outer.2),
    );
    let at_once = (lo_of(2.0, product.0, product.2), 2.0 * product.1, hi_of(2.0, product.0, product.2));
    assert!(close3(stepwise, (0.8, 2.0, 5.0)) && close3(at_once, (0.8, 2.0, 5.0)));
}
```

**Entrada** `conversion_collapses` · **Lei** `none`

### Os totais convertidos estão correlacionados

```text
n_composed - d_composed, lido cruzado, conta duas vezes a largura de φ; Σ φ r_parts conta-a uma

diferença em cada limite = d_part nesse limite × (φ_high - φ_low) - (e_d_high - e_d_low)
```

Um só fator multiplica a capacidade nominal e a procura de uma parte, pelo que os dois totais
convertidos se movem juntos. Subtraí-los com a inversão de limites que quantidades independentes
exigem emparelha a capacidade nominal convertida no mínimo do fator com a procura convertida no
máximo, um mês que é curto e longo ao mesmo tempo. O pivô através das partes converte o resto de cada
parte e nunca faz esse emparelhamento. Os dois valores são aritmética bem feita; só o pivô é o resto.

Para a `compute` da `merge-holding-composition`, o pivô é [1414; 2857; 4085,6] e os totais
convertidos subtraídos dão [1092; 2857; 4198,8]: iguais na moda, 322,0 mais largos no mínimo e 113,2
no máximo. No mínimo isso é o máximo da procura americana, 6,0, vezes a largura do fator, 72, menos a
largura da eliminação de procura, 110; no máximo é o mínimo da procura, 3,1, vezes 72, menos os
mesmos 110.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let us = layer(&group.process_modulus, "compute-us");
    let compute = layer(&holding.process_modulus, "compute");
    let f = factor(part(fusion(&holding, "compute"), "compute-us")).expect("stated");
    let e_d = elimination(fusion(&holding, "compute"), EliminationAgainstType::Demand).expect("filed");

    let pivot = quantity(compute).expect("stated");
    let (n, d) = (nameplate(compute), demand(compute));
    let differenced = (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    assert!(close3(pivot, (1414.0, 2857.0, 4085.6)));
    assert!(close3(differenced, (1092.0, 2857.0, 4198.8)));
    assert!(close(pivot.1, differenced.1));

    let width = f.2 - f.0;
    let e_width = e_d.2 - e_d.0;
    assert!(close(width, 72.0) && close(e_width, 110.0));
    let d_us = demand(us);
    assert!(close(d_us.2, 6.0) && close(d_us.0, 3.1));
    assert!(close(pivot.0 - differenced.0, 322.0));
    assert!(close(pivot.0 - differenced.0, d_us.2 * width - e_width));
    assert!(close(differenced.2 - pivot.2, 113.2));
    assert!(close(differenced.2 - pivot.2, d_us.0 * width - e_width));
}
```

**Entrada** `phi_correlated` · **Lei** `algebra/composed_remainder` · **Regra** `checks/shares_do_not_sum`

## 6. O resto composto

### O pivô através das partes

```text
r_composed = Σ Φ r_parts - e_n + e_d

o resto de cada parte convertido uma vez; cada eliminação lida no canto da sua própria quantidade
```

O resto de uma camada composta não é a sua capacidade nominal composta menos a sua procura composta
quando um fator de conversão tem largura. Um só fator multiplica a capacidade nominal e a procura de
uma parte, pelo que os dois totais convertidos se movem juntos, e subtraí-los como se fossem
independentes conta duas vezes a largura do fator. Converter o resto de cada parte põe o fator em
cada termo uma vez. Retirar procura contada duas vezes aumenta o resto e retirar capacidade nominal
contada duas vezes diminui-o, cada uma lida onde a quantidade em que foi contada está no canto em
jogo. Quando nenhum fator no caminho para baixo tem largura, o pivô é exatamente a diferença cruzada
dos totais compostos; quando algum tem, fica dentro dela, igual na moda.

A `compute` da `merge-holding-composition` funde a `compute-us` do grupo, um resto de
[2,0; 3,6; 4,9] GPU convertido a [672, 720, 744], com a sua `compute-pt`, [30, 175, 290] GPU-hora:
[1344, 2592, 3645,6] mais [30, 175, 290] dá [1374, 2767, 3935,6], e a eliminação de procura de
[40, 90, 150] leva-o a [1414, 2857, 4085,6], a quantidade que a holding declara. Os seus totais
compostos subtraídos dão [1092, 2857, 4198,8], mais largo nas duas pontas. A `both-views` da
`every-local-part` soma duas partes de [-240, 160, 360], elimina uma capacidade nominal de 2160 e
uma procura de [1800, 2000, 2400], e chega a [-240, 160, 360], exatamente os seus próprios totais
subtraídos. As partes da `every-inverting-elimination` somam [5, 7, 9], e a sua eliminação de
capacidade nominal, que essa soma leu cruzada, sai como 5 no mínimo e 2 no máximo: [0, 4, 7].

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let crossed = |n: Triple, d: Triple| (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    let add = |a: Triple, b: Triple| (a.0 + b.0, a.1 + b.1, a.2 + b.2);
    let inside = |r: Triple, bound: Triple| bound.0 <= r.0 && r.2 <= bound.2;

    // merge-holding-composition/compute: um fator com largura e um resto positivo, pelo que cada
    // limite do produto é o limite do fator com o mesmo nome.
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let us = layer(&group.process_modulus, "compute-us");
    let pt = layer(&group.process_modulus, "compute-pt");
    let fusion_ = fusion(&holding, "compute");
    let f = factor(part(fusion_, "compute-us")).expect("a stated factor");
    let r_us = crossed(nameplate(us), demand(us));
    let r_pt = crossed(nameplate(pt), demand(pt));
    assert!(close3(r_us, (2.0, 3.6, 4.9)) && close3(f, (672.0, 720.0, 744.0)));
    assert!(close3(r_pt, (30.0, 175.0, 290.0)));
    let converted = (r_us.0 * f.0, r_us.1 * f.1, r_us.2 * f.2);
    assert!(close3(converted, (1344.0, 2592.0, 3645.6)));
    let parts = add(converted, r_pt);
    assert!(close3(parts, (1374.0, 2767.0, 3935.6)));
    let e_n = elimination(fusion_, EliminationAgainstType::Nameplate).expect("filed");
    let e_d = elimination(fusion_, EliminationAgainstType::Demand).expect("filed");
    assert!(close3(e_n, (0.0, 0.0, 0.0)) && close3(e_d, (40.0, 90.0, 150.0)));
    // Com um fator com largura e r > 0, as duas quantidades estão no mínimo no mínimo de r.
    let pivot = (parts.0 - e_n.0 + e_d.0, parts.1 - e_n.1 + e_d.1, parts.2 - e_n.2 + e_d.2);
    assert!(close3(pivot, (1414.0, 2857.0, 4085.6)));
    let compute = layer(&holding.process_modulus, "compute");
    assert!(close3(quantity(compute).expect("stated"), pivot));
    let differenced = crossed(nameplate(compute), demand(compute));
    assert!(close3(differenced, (1092.0, 2857.0, 4198.8)));
    assert!(inside(pivot, differenced) && close(pivot.1, differenced.1));

    // every-local-part/both-views: nenhum fator em lado nenhum, pelo que o pivô é a diferença dos totais.
    let local = composition("fixtures/every-local-part.xml");
    let fusion_ = fusion(&local, "both-views");
    let mut parts = (0.0, 0.0, 0.0);
    for p in &fusion_.part {
        let l = layer(&local.process_modulus, &p.layer.filing.id);
        let r = crossed(nameplate(l), demand(l));
        assert!(close3(r, (-240.0, 160.0, 360.0)));
        parts = add(parts, r);
    }
    let e_n = elimination(fusion_, EliminationAgainstType::Nameplate).expect("filed");
    let e_d = elimination(fusion_, EliminationAgainstType::Demand).expect("filed");
    assert!(close3(e_n, (2160.0, 2160.0, 2160.0)) && close3(e_d, (1800.0, 2000.0, 2400.0)));
    // Sem largura: o mínimo de r toma a capacidade nominal no mínimo e a procura no máximo.
    let pivot = (parts.0 - e_n.0 + e_d.2, parts.1 - e_n.1 + e_d.1, parts.2 - e_n.2 + e_d.0);
    assert!(close3(pivot, (-240.0, 160.0, 360.0)));
    let both = layer(&local.process_modulus, "both-views");
    assert!(close3(pivot, crossed(nameplate(both), demand(both))));

    // every-inverting-elimination: a soma da capacidade nominal foi lida cruzada, pelo que a sua
    // eliminação está no máximo onde a capacidade nominal está no mínimo.
    let inverting = composition("fixtures/every-inverting-elimination.xml");
    let fusion_ = fusion(&inverting, "shift-capacity");
    let mut parts = (0.0, 0.0, 0.0);
    for p in &fusion_.part {
        let l = layer(&inverting.process_modulus, &p.layer.filing.id);
        parts = add(parts, crossed(nameplate(l), demand(l)));
    }
    assert!(close3(parts, (5.0, 7.0, 9.0)));
    let e_n = elimination(fusion_, EliminationAgainstType::Nameplate).expect("filed");
    let (n_at_low, n_at_high) = (e_n.2, e_n.0);
    assert!(close(n_at_low, 5.0) && close(n_at_high, 2.0));
    let pivot = (parts.0 - n_at_low, parts.1 - e_n.1, parts.2 - n_at_high);
    assert!(close3(pivot, (0.0, 4.0, 7.0)));
    let composed = layer(&inverting.process_modulus, "shift-capacity");
    assert!(close3(pivot, crossed(nameplate(composed), demand(composed))));

    // Duas partes sem fator, numa grelha de inteiros: com cada eliminação lida nos cantos da sua
    // própria quantidade, o pivô sai sempre ordenado e é sempre a diferença cruzada dos totais
    // compostos.
    let mut claims = Vec::new();
    for low in 0..=2 {
        for mode in low..=2 {
            for high in mode..=2 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    let sum_rule = |t: Triple, e: Triple| {
        let b = (t.0 - e.0, t.1 - e.1, t.2 - e.2);
        if b.0 <= b.1 && b.1 <= b.2 { (b, false) } else { ((t.0 - e.2, t.1 - e.1, t.2 - e.0), true) }
    };
    for &n1 in &claims {
        for &d1 in &claims {
            for &n2 in &claims {
                for &d2 in &claims {
                    for &e_n in &claims {
                        for &e_d in &claims {
                            let (n_c, n_crossed) = sum_rule(add(n1, n2), e_n);
                            let (d_c, d_crossed) = sum_rule(add(d1, d2), e_d);
                            let (n_lo, n_hi) = if n_crossed { (e_n.2, e_n.0) } else { (e_n.0, e_n.2) };
                            let (d_lo, d_hi) = if d_crossed { (e_d.2, e_d.0) } else { (e_d.0, e_d.2) };
                            let parts = add(crossed(n1, d1), crossed(n2, d2));
                            let pivot = (parts.0 - n_lo + d_hi, parts.1 - e_n.1 + e_d.1, parts.2 - n_hi + d_lo);
                            assert_eq!(pivot, crossed(n_c, d_c));
                        }
                    }
                }
            }
        }
    }
}
```

**Entrada** `composed_remainder` · **Lei** `algebra/composed_remainder` · **Regra** `checks/shares_do_not_sum`, `checks/stated_quantity_is_not_the_magnitude`

## 7. Janelas e ciclos de serviço

### Um ciclo de serviço dobra-se numa taxa

```text
entregue por período = taxa enquanto trabalha × janela ÷ período × período = taxa enquanto trabalha × janela
```

Uma oferta que só trabalha parte de cada período declara a sua capacidade nominal por período, e a
janela diz quanto do período trabalha. A taxa enquanto trabalha é a capacidade nominal sobre a
janela, e não sobre o período. O ciclo de serviço desaparece então da capacidade nominal: duas
linhas com a mesma produção diária e horários diferentes declaram o mesmo valor, e só a janela as
distingue.

A linha do próprio esquema trabalha das 02:00 às 05:00 a um muffin a cada cinco segundos: 10800
segundos sobre 5 dá 2160 muffins por dia, e 720 por hora enquanto trabalha. A `shift-line` do
`merge-us-member` trabalha 5 dias por semana e declara 10 turnos por semana, pelo que faz 2 turnos
por dia de trabalho.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let window_seconds = 3.0 * 3600.0;
    assert!(close(window_seconds, 10800.0));
    let per_day = window_seconds / 5.0;
    assert!(close(per_day, 2160.0));
    let per_running_hour = 3600.0 / 5.0;
    assert!(close(per_running_hour, 720.0) && close(per_running_hour * 3.0, per_day));

    let us = filing("corpus/merge-us-member.xml");
    let line = layer(&us, "shift-line");
    let (w, unit) = window(line).expect("a window");
    assert_eq!(unit, "days");
    assert!(close3(w, (5.0, 5.0, 5.0)) && close3(nameplate(line), (10.0, 10.0, 10.0)));
    let per_running_day = nameplate(line).1 / w.1;
    assert!(close(per_running_day, 2.0));
    assert!(close(per_running_day * w.1, nameplate(line).1));
}
```

**Entrada** `duty_cycle` · **Regra** `checks/derived_slack_over_a_window`

### Uma folga não é uma duração

```text
margem de tempo (declarada) = folga = max(n - d, 0)     uma quantidade na unidade da camada
a espera que implica        = q / folga                 uma duração, quando q é uma contagem
```

O `timeSlack` guarda quanta procura sobrevive a ser retida, como quantidade na unidade da camada,
porque é comparado com quotas de detentores nessa unidade. A espera de uma unidade atrasada é outro
valor, noutra dimensão, a descrever a mesma oferta. Declarada como derivação `clearance`, a margem é
a folga, e dividir um quantum por ela dá uma duração só quando o quantum é uma contagem e a folga
uma taxa; dois valores na mesma unidade dividem-se num número puro.

Numa passadeira com cem lugares por hora a levar noventa e cinco muffins a margem é de 5 muffins por
hora, e um muffin atrasado espera 1 sobre 5 de hora, 12 minutos. O forno da `every-absence` declara
a sua margem de tempo como derivação `clearance`: a sua folga na moda é 2160 menos 2000, 160 muffins
por dia, e o seu quantum de 12 muffins por dia sobre isso é 0,075, uma razão e não uma duração.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let (slots, muffins) = (100.0, 95.0);
    let slack_per_hour = slots - muffins;
    assert!(close(slack_per_hour, 5.0));
    let wait_minutes = 1.0 / slack_per_hour * 60.0;
    assert!(close(wait_minutes, 12.0));

    let bakery = filing("fixtures/every-absence.xml");
    let oven = layer(&bakery, "oven");
    assert_eq!(derivation(&oven.time_slack), Some(&IdentityType::Clearance));
    let (n, d) = (nameplate(oven), demand(oven));
    assert!(close(n.1, 2160.0) && close(d.1, 2000.0));
    let clearance = (n.1 - d.1).max(0.0);
    assert!(close(clearance, 160.0));
    let q = quantum(oven).expect("lumpy").1;
    assert!(close(q, 12.0));
    assert_eq!(unit(&oven.supply.nameplate.amount), unit(&oven.demand.amount));
    assert!(close(q / clearance, 0.075));
}
```

**Entrada** `clearance_is_not_a_duration` · **Regra** `checks/derived_slack_over_a_window`

### Uma margem observada como duração

```text
espera × margem = q          portanto          margem = q / espera
```

O tamanho de um amortecedor observa-se naturalmente como duração, e declara-se como quantidade na
unidade da camada, pelo que quem declara deve a conversão antes de declarar. O quantum que espera,
sobre a espera, é a margem. E a conversão não sobrevive a um ciclo de serviço no sentido inverso:
fazer a média de uma folga sobre o período inteiro dá uma espera que não acontece em lado nenhum.

A espera de doze minutos da passadeira para um muffin é uma margem de 5 por hora. A linha do esquema
faz 2160 muffins por dia em três horas contra uma procura de 2000, uma folga de 160 por dia:
espalhada pelo dia inteiro é uma a cada 9 minutos, dentro da janela uma a cada 67,5 segundos, e fora
da janela uma encomenda falhada espera 21 horas. Nove minutos não acontecem em parte nenhuma dessa
linha.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let (q, wait_hours) = (1.0, 12.0 / 60.0);
    let slack = q / wait_hours;
    assert!(close(slack, 5.0) && close(wait_hours * slack, q));

    let clearance = 2160.0 - 2000.0;
    assert!(close(clearance, 160.0));
    let over_the_day_minutes = 24.0 * 60.0 / clearance;
    assert!(close(over_the_day_minutes, 9.0));
    let inside_the_window_seconds = 3.0 * 3600.0 / clearance;
    assert!(close(inside_the_window_seconds, 67.5));
    let outside_the_window_hours = 24.0 - 3.0;
    assert!(close(outside_the_window_hours, 21.0));
}
```

**Entrada** `slack_from_duration` · **Lei** `none`

### A fila estabiliza na sua paciência

```text
paciência W = margem de tempo / taxa de serviço μ
profundidade de equilíbrio = μ W             taxa de saída = λ - μ = a soma das quotas não servidas
```

Uma fila cujos clientes saem depois de uma paciência é estável qualquer que seja a carga: o atraso
acumulado cresce até a espera chegar à paciência, e a partir daí a procura sai à taxa a que o
excesso chega. Esse resultado cita-se abaixo; a aritmética à volta dele verifica-se aqui. A taxa de
saída é a procura menos a taxa de serviço na moda, que é a grandeza do resto, pelo que a regra da
soma e o equilíbrio da fila têm de concordar.

A `shift-line` da `merge-holding-composition` serve 10 turnos por semana contra uma procura cuja moda
é 12,7, com uma margem de tempo cuja moda é 2,5 turnos. A paciência é 2,5 sobre 10, um quarto de
semana, a profundidade de equilíbrio é 10 vezes isso, 2,5, e a taxa de saída é 2,7 por semana:
exatamente a quota `customer` de 1,7 e a quota `unrealised` de 1,0 que a holding declara.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let holding = composition("corpus/merge-holding-composition.xml");
    let line = layer(&holding.process_modulus, "shift-line");
    let mu = nameplate(line).1;
    let lambda = demand(line).1;
    let slack = claim(&line.time_slack).expect("stated").1;
    assert!(close(mu, 10.0) && close(lambda, 12.7) && close(slack, 2.5));

    let patience = slack / mu;
    assert!(close(patience, 0.25));
    assert!(close(mu * patience, 2.5));
    let departing = lambda - mu;
    assert!(close(departing, 2.7));

    let unserved: Vec<f64> = holders(line)
        .into_iter()
        .filter(|(k, _)| matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s.expect("stated").1)
        .collect();
    assert!(close(unserved[0], 1.7) && close(unserved[1], 1.0));
    assert!(close(unserved.iter().sum::<f64>(), departing));
}
```

**Entrada** `queue_arithmetic` · **Regra** `checks/shares_do_not_sum`

### Citado, não provado

Dois resultados de filas em que as entradas acima assentam e que não provam:

- Uma fila com vários servidores cujos clientes desistem depois de uma paciência exponencial é
  estável a qualquer carga, incluindo acima da capacidade. Garnett, Mandelbaum e Reiman, "Designing
  a Call Center with Impatient Customers", *Manufacturing & Service Operations Management* 4(3),
  2002.
- No limite fluido de uma fila assim em sobrecarga, a fila estabiliza onde a espera iguala a
  paciência e os clientes desistem à taxa a que o excesso chega. Whitt, "Fluid Models for
  Multiserver Queues with Abandonments", *Operations Research* 54(1), 2006.

## 8. Contagem

### Os doze caminhos

```text
f: N -> X, |N| = n, |X| = x               qualquer         injetiva           sobrejetiva
com etiquetas                             x^n              x!/(x-n)!          x! S(n, x)
a menos das bolas (N sem etiquetas)       C(x+n-1, n)      C(x, n)            C(n-1, x-1)
a menos das caixas (X sem etiquetas)      Σ_k≤x S(n, k)    [n <= x]           S(n, x)
a menos de ambas                          p_≤x(n)          [n <= x]           p_x(n)
```

Cada classificação que uma consulta faz é uma função das suas linhas para um conjunto de classes, e
estas doze contagens dizem quantas funções dessas há, conforme as linhas e as classes se distinguem
ou não e conforme a função tem de ser injetiva ou sobrejetiva. O `GROUP BY` lê uma função a menos das
suas linhas, um núcleo lê-a a menos das suas classes, e um perfil lê-a a menos de ambas, pelo que as
quatro linhas da tabela são quatro coisas que uma relação pode reportar. A tabela é o *twelvefold
way* de Stanley, em *Enumerative Combinatorics*, volume 1, capítulo 1; o bloco conta cada célula à
força bruta e confronta-a com a fórmula.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    fn binomial(n: i64, k: i64) -> i64 {
        if k < 0 || k > n {
            return 0;
        }
        (0..k).fold(1, |acc, i| acc * (n - i) / (i + 1))
    }
    fn stirling2(n: i64, k: i64) -> i64 {
        match (n, k) {
            (0, 0) => 1,
            (_, 0) | (0, _) => 0,
            _ => k * stirling2(n - 1, k) + stirling2(n - 1, k - 1),
        }
    }
    // Partições de n em exatamente k partes.
    fn parts(n: i64, k: i64) -> i64 {
        match (n, k) {
            (0, 0) => 1,
            _ if n <= 0 || k <= 0 => 0,
            _ => parts(n - 1, k - 1) + parts(n - k, k),
        }
    }
    let factorial = |n: i64| (1..=n).product::<i64>();

    for n in 0..=4_i64 {
        for x in 0..=4_i64 {
            // Todas as funções de n linhas para x classes, como tuplo de imagens.
            let mut functions: Vec<Vec<i64>> = vec![vec![]];
            for _ in 0..n {
                functions = functions
                    .into_iter()
                    .flat_map(|f| (0..x).map(move |c| [f.clone(), vec![c]].concat()))
                    .collect();
            }
            let injective = |f: &Vec<i64>| {
                let mut seen = f.clone();
                seen.sort();
                seen.dedup();
                seen.len() == f.len()
            };
            let surjective = |f: &Vec<i64>| (0..x).all(|c| f.contains(&c));
            // A menos das bolas: o multiconjunto das imagens. A menos das caixas: as imagens
            // renomeadas pela ordem em que aparecem. A menos de ambas: os tamanhos ordenados das
            // classes não vazias.
            let balls = |f: &Vec<i64>| {
                let mut v = f.clone();
                v.sort();
                v
            };
            let boxes = |f: &Vec<i64>| {
                let mut names: Vec<i64> = Vec::new();
                f.iter()
                    .map(|c| match names.iter().position(|m| m == c) {
                        Some(i) => i as i64,
                        None => {
                            names.push(*c);
                            names.len() as i64 - 1
                        }
                    })
                    .collect::<Vec<i64>>()
            };
            let both = |f: &Vec<i64>| {
                let mut sizes: Vec<i64> =
                    (0..x).map(|c| f.iter().filter(|&&i| i == c).count() as i64).filter(|&k| k > 0).collect();
                sizes.sort();
                sizes
            };
            let count = |keep: &dyn Fn(&Vec<i64>) -> bool, key: &dyn Fn(&Vec<i64>) -> Vec<i64>| {
                let mut keys: Vec<Vec<i64>> = functions.iter().filter(|f| keep(f)).map(|f| key(f)).collect();
                keys.sort();
                keys.dedup();
                keys.len() as i64
            };
            let any = |_: &Vec<i64>| true;
            let same = |f: &Vec<i64>| f.clone();
            let fits = if n <= x { 1 } else { 0 };

            assert_eq!(count(&any, &same), x.pow(n as u32));
            assert_eq!(count(&injective, &same), if n <= x { factorial(x) / factorial(x - n) } else { 0 });
            assert_eq!(count(&surjective, &same), factorial(x) * stirling2(n, x));
            assert_eq!(count(&any, &balls), if x == 0 { if n == 0 { 1 } else { 0 } } else { binomial(x + n - 1, n) });
            assert_eq!(count(&injective, &balls), binomial(x, n));
            assert_eq!(count(&surjective, &balls), if n == 0 && x == 0 { 1 } else { binomial(n - 1, x - 1) });
            assert_eq!(count(&any, &boxes), (0..=x).map(|k| stirling2(n, k)).sum::<i64>());
            assert_eq!(count(&injective, &boxes), fits);
            assert_eq!(count(&surjective, &boxes), stirling2(n, x));
            assert_eq!(count(&any, &both), (0..=x).map(|k| parts(n, k)).sum::<i64>());
            assert_eq!(count(&injective, &both), fits);
            assert_eq!(count(&surjective, &both), parts(n, x));
        }
    }
}
```

**Entrada** `twelvefold` · **Lei** `none`

### O tamanho de uma autojunção fica fixado pelos tamanhos dos grupos

```text
numa chave cujos grupos têm tamanhos k:
    pares ordenados, com o reflexivo    Σ k²
    pares ordenados, sem o reflexivo    Σ k(k-1)
    pares não ordenados                 Σ C(k, 2)        = Σ k(k-1) / 2
```

Juntar uma relação consigo mesma numa chave emparelha cada linha com cada linha do seu grupo, pelo
que o tamanho do resultado fica decidido só pelos tamanhos dos grupos, seja o que for que as linhas
transportem. Qual das três uma relação calcula é uma escolha sobre se uma linha se emparelha consigo
própria e se um par conta nas duas ordens, e uma relação que a faça mal reporta uma contagem
plausível.

Em todas as composições carregadas, uma parte é nomeada por algum número de fusões. O forno da
`every-absence` é nomeado por duas, a `baking` da `every-elimination` e a `as-filed` da
`every-local-part`, pelo que contribui com 4 para a primeira soma, 2 para a segunda e 1 para a
terceira: o único par de camadas compostas que contaria duas vezes a sua oferta se alguém as somasse.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let documents = [
        "corpus/merge-group-composition.xml",
        "corpus/merge-holding-composition.xml",
        "fixtures/every-elimination.xml",
        "fixtures/every-local-part.xml",
        "fixtures/every-partial-elimination.xml",
        "fixtures/every-inverting-elimination.xml",
        "fixtures/every-nested-conversion.xml",
        "fixtures/every-unit-cycle.xml",
        "fixtures/every-unsized-conversion.xml",
    ];
    // Quantas entradas de fusão nomeiam cada parte, indexadas pela notação e camada da parte.
    let mut named: std::collections::BTreeMap<(String, String), i64> = Default::default();
    for d in documents {
        let c = composition(d);
        for f in &c.fusion {
            for p in &f.part {
                *named.entry((p.layer.filing.notation.clone(), p.layer.filing.id.clone())).or_default() += 1;
            }
        }
    }
    let k: Vec<i64> = named.values().cloned().collect();
    let squares: i64 = k.iter().map(|k| k * k).sum();
    let ordered: i64 = k.iter().map(|k| k * (k - 1)).sum();
    let unordered: i64 = k.iter().map(|k| k * (k - 1) / 2).sum();
    assert_eq!(squares, k.iter().sum::<i64>() + ordered);
    assert_eq!(2 * unordered, ordered);

    let oven = named
        .iter()
        .find(|((notation, id), _)| notation.ends_with("every-absence") && id == "oven")
        .map(|(_, k)| *k)
        .expect("the oven is a part");
    assert_eq!((oven * oven, oven * (oven - 1), oven * (oven - 1) / 2), (4, 2, 1));
    assert_eq!(unordered, 1);

    // Em cada lista de tamanhos de grupo até um limite pequeno, as três somas mantêm a relação.
    for a in 0..=5_i64 {
        for b in 0..=5_i64 {
            for c in 0..=5_i64 {
                let k = [a, b, c];
                let sq: i64 = k.iter().map(|k| k * k).sum();
                let ord: i64 = k.iter().map(|k| k * (k - 1)).sum();
                let unord: i64 = k.iter().map(|k| k * (k - 1) / 2).sum();
                assert_eq!(sq, k.iter().sum::<i64>() + ord);
                assert_eq!(2 * unord, ord);
            }
        }
    }
}
```

**Entrada** `self_join_sizes` · **Lei** `none`

### O excesso de uma soma sobre a sua imagem

```text
Σ_linhas w(f(linha)) = Σ_classe |f⁻¹(classe)| · w(classe)        excesso sobre a imagem = Σ (k - 1) · w
k - 1 = C(k, 2) só quando k é 1 ou 2
```

Somar um peso sobre linhas conta cada classe uma vez por cada linha que lá cai, pelo que uma classe
atingida k vezes contribui com o seu peso k vezes, e o excesso sobre contar cada classe uma vez é
`(k - 1) · w`. Esse excesso é a eliminação `e` em `x_composed = Σ x_parts - e`: é por isso que uma
consulta pode compor um filho duas vezes e uma fusão não pode chegar duas vezes à mesma camada. Numa
dobra idempotente, uma união, um `max` ou um `EXISTS`, a multiplicidade desaparece e não há excesso. O
excesso não é o número de pares: `k - 1` e `C(k, 2)` só coincidem quando k é 1 ou 2, e em 3 uma
classe é contada a mais duas vezes e forma três pares.

Somar a `baking` da `every-elimination` à `as-filed` da `every-local-part` conta duas vezes o forno
da `every-absence`: a sua capacidade nominal de 2160 muffins por dia entra na soma como 4320, um
excesso de 2160.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let bakery = filing("fixtures/every-absence.xml");
    let w = nameplate(layer(&bakery, "oven")).1;
    assert!(close(w, 2160.0));
    let k = 2.0;
    assert!(close(k * w, 4320.0) && close((k - 1.0) * w, 2160.0));

    for k in 0..=12_i64 {
        let pairs = k * (k - 1) / 2;
        assert_eq!(k - 1 == pairs, k == 1 || k == 2);
    }
    assert_eq!((3 - 1, 3 * 2 / 2), (2, 3));

    // A identidade em cada atribuição de quatro linhas a três classes com pesos 1, 10, 100.
    let weights = [1_i64, 10, 100];
    for code in 0..81 {
        let rows: Vec<usize> = (0..4).map(|i| (code / 3_i64.pow(i)) as usize % 3).collect();
        let by_row: i64 = rows.iter().map(|&c| weights[c]).sum();
        let by_class: i64 = (0..3)
            .map(|c| rows.iter().filter(|&&r| r == c).count() as i64 * weights[c])
            .sum();
        let image: i64 = (0..3).filter(|c| rows.contains(c)).map(|c| weights[c]).sum();
        let excess: i64 = (0..3)
            .map(|c| (rows.iter().filter(|&&r| r == c).count() as i64 - 1).max(0) * weights[c])
            .sum();
        assert_eq!(by_row, by_class);
        assert_eq!(by_row - image, excess);
    }
}
```

**Entrada** `excess` · **Lei** `none`

### O núcleo de uma dobra é o seu excesso

```text
f: N -> X uma função, F a sua incidência com um só 1 por coluna, Phi uma diagonal positiva
  rank(F Phi)    = |imagem f|
  dim ker(F Phi) = |N| - |imagem f| = a soma sobre as caixas de (tamanho da fibra - 1)
```

O excesso que uma soma carrega sobre a sua imagem é a entrada acima, e lido como matriz esse mesmo
número é uma DIMENSÃO. Uma bola movida de uma companheira de caixa para outra, escalada pelos dois
fatores, não muda nada que a dobra consiga ver. Portanto o excesso a um peso é uma magnitude e o
excesso a peso um é a dimensão do espaço de movimentos a que a dobra é cega, e os dois são uma só
soma.

A dimensão não pode depender dos fatores. `Phi` escala cada coluna por um número positivo, o que
não move coluna nenhuma para dentro ou para fora do espaço gerado pelas outras, portanto a
característica fica decidida só pela incidência. A DIREÇÃO de um movimento não fica: um gerador é
uma unidade numa bola contra uma unidade noutra, o que nas unidades próprias de cada uma é o
inverso de cada fator, e carrega a largura que os fatores tiverem. A dimensão é inteira e a direção
é medida.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Rank by elimination with partial pivoting. No decomposition and no magnitudes: the answer
    // must depend only on which balls share a box.
    fn rank(mut a: Vec<Vec<f64>>, rows: usize, cols: usize) -> usize {
        let mut r = 0;
        for c in 0..cols {
            if r == rows {
                break;
            }
            let p = (r..rows)
                .max_by(|&i, &j| a[i][c].abs().partial_cmp(&a[j][c].abs()).expect("finite"))
                .expect("r < rows");
            if a[p][c].abs() < 1e-9 {
                continue;
            }
            a.swap(r, p);
            let piv = a[r][c];
            for i in 0..rows {
                if i != r && a[i][c].abs() > 0.0 {
                    let f = a[i][c] / piv;
                    for j in c..cols {
                        a[i][j] -= f * a[r][j];
                    }
                }
            }
            r += 1;
        }
        r
    }

    // Every function from n labelled balls into x labelled boxes.
    let mut seen = 0;
    for n in 1..=5usize {
        for x in 1..=4usize {
            let mut assign = vec![0usize; n];
            loop {
                // One 1 per column, scaled by a positive factor that differs column by column.
                let mut f = vec![vec![0.0; n]; x];
                for (j, &i) in assign.iter().enumerate() {
                    f[i][j] = 1.0 + (j as f64) * 0.75;
                }
                let image: std::collections::BTreeSet<usize> = assign.iter().copied().collect();
                let excess: usize = image
                    .iter()
                    .map(|&i| assign.iter().filter(|&&a| a == i).count() - 1)
                    .sum();

                // The rank is the image, so the nullity is the excess.
                assert_eq!(rank(f.clone(), x, n), image.len());
                assert_eq!(n - rank(f.clone(), x, n), excess);

                // And the factors moved none of it: the same incidence, every entry at one.
                let mut bare = vec![vec![0.0; n]; x];
                for (j, &i) in assign.iter().enumerate() {
                    bare[i][j] = 1.0;
                }
                assert_eq!(rank(bare, x, n), rank(f, x, n));
                seen += 1;

                let mut k = 0;
                while k < n {
                    assign[k] += 1;
                    if assign[k] < x {
                        break;
                    }
                    assign[k] = 0;
                    k += 1;
                }
                if k == n {
                    break;
                }
            }
        }
    }
    assert!(seen > 0);
}
```

**Entrada** `kernel_is_the_excess` · **Lei** `none`

### Valores decimais não se somam exatamente em vírgula flutuante

```text
10.0 - 10.4 = -0.40000000000000036 em f64
```

Uma `Claim` guarda `f64`, e a maioria dos valores com uma casa decimal não tem forma binária exata,
pelo que uma soma calculada a partir deles pode falhar o valor escrito para a soma. Por isso toda a
comparação que este repositório faz entre um valor calculado e um declarado admite 1e-9. Dos pares
ordenados de valores com uma casa decimal de 0,1 a 19,9, que são 39.601, 7.168 falham uma igualdade
exata com a sua própria soma, e nenhum a falha por tanto como essa tolerância.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    assert_eq!(format!("{}", 10.0_f64 - 10.4), "-0.40000000000000036");
    let (mut pairs, mut inexact) = (0, 0);
    for i in 1..=199 {
        for j in 1..=199 {
            let (a, b, written) = (i as f64 / 10.0, j as f64 / 10.0, (i + j) as f64 / 10.0);
            pairs += 1;
            if a + b != written {
                inexact += 1;
            }
            assert!(close(a + b, written));
        }
    }
    assert_eq!((pairs, inexact), (39601, 7168));
    assert!(close(0.1 * 1.0, 0.1) && close(19.9, 199.0 / 10.0));
}
```

**Entrada** `float_sums` · **Lei** `none`

### As peças em que um valor composto é linear

```text
P partes, cada uma a dobrar onde o seu próprio resto passa por zero:  2^P peças, e a profundidade não as move
  a contagem é 2^P porque cada parte declara a sua própria placa e a sua própria procura, logo as P dobras são independentes
  partes obrigadas a partilhar um valor deixam alguns padrões de sinal inalcançáveis, e a contagem cai
```

Um valor composto é uma soma sobre as suas partes, cada uma convertida, e a conversão de uma parte só
muda de inclinação onde o resto dessa parte passa por zero. As dobras são portanto os `P` hiperplanos
coordenados que passam pela origem, um por parte, e cortam o espaço dos restos das partes nos seus
octantes de sinal. O valor é uma só função linear em cada um, e nenhuma divisão mais grosseira serve,
porque atravessar uma única dobra muda exatamente a inclinação de uma parte e com ela a função.

⭐ A contagem fica fixada pelo número de partes e não pela profundidade a que a composição se encaixa.
Um caminho de conversões colapsa numa só conversão, entrada `conversion_collapses`, portanto uma
composição de qualquer profundidade transporta as dobras das suas folhas e nenhuma outra. Um operador
cujas dobras pudessem ser afastadas da origem multiplicaria as suas peças com a profundidade; este não
pode, porque um fator positivo não move um sinal.

⚠️ **O expoente é uma consequência e não um dado.** `P` dobras cortam um espaço em `2^P` peças só
onde as dobras são independentes, e aqui são porque cada parte declara a sua própria placa e a sua
própria procura, portanto o espaço onde as dobras vivem tem lugar para todos os padrões de sinal.
Partes obrigadas a partilhar um valor deixariam alguns padrões inalcançáveis e a contagem cairia
abaixo de `2^P`. A independência é um facto sobre o que um preenchimento pode dizer, por isso vale
a pena nomeá-la em vez de a assumir.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // O limite inferior de um valor composto sobre P partes: cada parte convertida no canto que o
    // seu próprio sinal escolhe, e depois somadas.
    let low = |rs: &[f64], los: &[f64], his: &[f64]| -> f64 {
        rs.iter()
            .zip(los)
            .zip(his)
            .map(|((r, lo), hi)| (r * lo).min(r * hi))
            .sum()
    };

    for p in 1..=6usize {
        let (los, his) = (vec![2.0; p], vec![5.0; p]);
        let mut pieces = std::collections::BTreeSet::new();
        for mask in 0..(1u32 << p) {
            let rs: Vec<f64> =
                (0..p).map(|i| if mask >> i & 1 == 1 { 3.0 } else { -3.0 }).collect();
            // O padrão de inclinações que este octante usa É a peça.
            let taken: Vec<bool> = rs.iter().map(|r| *r < 0.0).collect();
            pieces.insert(taken.clone());
            // E neste octante a soma é mesmo essa única função linear.
            let expect: f64 = rs
                .iter()
                .zip(&taken)
                .map(|(r, negative)| if *negative { r * 5.0 } else { r * 2.0 })
                .sum();
            assert_eq!(low(&rs, &los, &his), expect);
        }
        assert_eq!(pieces.len(), 1usize << p);
    }

    // Nenhuma divisão mais grosseira serve: atravessar uma dobra muda a função, portanto dois
    // octantes que diferem num só sinal nunca são a mesma peça.
    let (los, his) = (vec![2.0; 3], vec![5.0; 3]);
    let a = [3.0, 3.0, 3.0];
    let b = [3.0, -3.0, 3.0];
    assert!(low(&a, &los, &his) != low(&b, &los, &his));

    // ⛔ E o expoente assenta em as dobras serem independentes. Amarre duas partes a um valor e
    // dois dos quatro padrões de sinal ficam inalcançáveis, portanto as peças caem de quatro
    // para duas.
    let mut tied = std::collections::BTreeSet::new();
    for mask in 0..4u32 {
        let first: f64 = if mask & 1 == 1 { 3.0 } else { -3.0 };
        let second: f64 = if mask >> 1 & 1 == 1 { 3.0 } else { -3.0 };
        // A restrição que um valor partilhado impõe: os dois restos são o mesmo número.
        if (first - second).abs() > 1e-9 {
            continue;
        }
        tied.insert(vec![first < 0.0, second < 0.0]);
    }
    assert_eq!(tied.len(), 2);
    assert!(tied.len() < 1usize << 2);
}
```

**Entrada** `orthants` · **Lei** `none`

## 9. Álgebra de conjuntos

### Uma diferença e a sua semijunção particionam o lado esquerdo

```text
|A| = |A ∖ B| + |A ⋉ B|
```

Cada linha de `A` ou tem correspondência em `B` ou não tem, pelo que as linhas que uma diferença
guarda e as que uma semijunção guarda são a totalidade de `A`, sem nada nas duas. Uma diferença
errada devolve à mesma uma tabela plausível, pelo que esta identidade é o que as leis do
`algebra/roster.sqlc` afirmam para cada diferença de conjuntos da árvore. Vale para um saco só quando
a diferença guarda os duplicados, como faz uma anti-junção; o `EXCEPT` retira-os, e num saco os dois
lados deixam então de somar.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Cada par de subconjuntos de um universo de cinco elementos, como máscaras de bits.
    for a in 0..32_u32 {
        for b in 0..32_u32 {
            let difference = (a & !b).count_ones();
            let semijoin = (a & b).count_ones();
            assert_eq!(a.count_ones(), difference + semijoin);
            assert_eq!((a & !b) & (a & b), 0);
        }
    }

    // Um saco com um duplicado: a anti-junção guarda-o e a partição mantém-se; o EXCEPT larga-o.
    let a = [1, 1, 2, 3];
    let b = [3];
    let anti: Vec<i32> = a.iter().cloned().filter(|x| !b.contains(x)).collect();
    let semi: Vec<i32> = a.iter().cloned().filter(|x| b.contains(x)).collect();
    assert_eq!(a.len(), anti.len() + semi.len());
    let mut except = anti.clone();
    except.dedup();
    assert_eq!(except, vec![1, 2]);
    assert_ne!(a.len(), except.len() + semi.len());
}
```

**Entrada** `difference_partition` · **Lei** `algebra/owed_equality`

### Uma seleção acumula-se

```text
σ_p(σ_q(A)) = σ_{p ∧ q}(A)
```

Filtrar uma relação filtrada é filtrar uma vez pelas duas condições, pelo que uma regra que compõe uma
população herda todos os filtros lá de dentro, incluindo os que o seu autor nunca escreveu. A
população que uma regra examina decide-se nos ficheiros que compõe, e não só no seu.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Cada relação sobre um universo de cinco elementos, contra cada par de predicados sobre ele.
    for a in 0..32_u32 {
        for p in 0..32_u32 {
            for q in 0..32_u32 {
                assert_eq!((a & q) & p, a & (p & q));
            }
        }
    }
}
```

**Entrada** `selection_accumulates` · **Lei** `none`

### Uma projeção não se distribui sobre uma diferença

```text
π(A ∖ B) ≠ π(A) ∖ π(B)        em geral
```

Projetar primeiro e subtrair depois compara menos atributos, pelo que duas linhas que só diferem numa
coluna que a projeção deita fora se anulam uma à outra. Uma diferença tem de ser tomada sobre a chave
e projetada depois.

Com `A = {(1, x)}` e `B = {(1, y)}`, a diferença guarda `(1, x)` e projeta em `{1}`, ao passo que
as projeções são ambas `{1}` e subtraem-se em nada.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let a = [(1, 'x')];
    let b = [(1, 'y')];
    let difference: Vec<(i32, char)> = a.iter().cloned().filter(|r| !b.contains(r)).collect();
    let projected_after: Vec<i32> = difference.iter().map(|r| r.0).collect();
    let pa: Vec<i32> = a.iter().map(|r| r.0).collect();
    let pb: Vec<i32> = b.iter().map(|r| r.0).collect();
    let projected_first: Vec<i32> = pa.iter().cloned().filter(|k| !pb.contains(k)).collect();
    assert_eq!(projected_after, vec![1]);
    assert!(projected_first.is_empty());
}
```

**Entrada** `projection_counterexample` · **Lei** `none`

### Fixar um valor responde pela relação inteira sob duas condições

```text
σ_{c = v}(A) responde por A   ⟺   o v alcança cada chave  ∧  o u é constante na chave
```

Fixar um valor de uma coluna e deitar a coluna fora é como uma relação de grão fino se lê a um grão
grosso. Responde pela relação que fatiou quando as chaves são as mesmas, cada uma carrega um só
valor, e esse valor é o que a relação inteira carrega. As duas condições são precisas e nenhuma
implica a outra: uma chave sem linha em `v` é deitada fora pela fatia e guardada pelo agregado, e
uma chave que carrega dois valores é respondida com um dos dois.

É este o único caso em que um `σπ` e um `γ` são a mesma relação. Em todo o resto têm a mesma chave,
a mesma aridade e uma linha por chave, e nenhuma lei de cardinalidade os separa.

O `units/conversions.sqlc` lê o grafo de conversões inteiro a partir de `quantity = 'nameplate'`. A
unidade que põe num bordo é a unidade da camada só enquanto uma camada nomear uma só unidade em
todas as suas quantidades, e o bordo existe sequer só enquanto cada parte com factor declarado
apresentar um valor nominal. O `algebra/layer_units` são essas duas condições, um sujeito cada.

A busca abaixo é cada relação sobre duas chaves, dois valores da coluna fixada e dois valores
transportados, o que dá 256 delas. Conta as relações que cumprem uma condição e falham a outra, para
que nenhuma das metades seja vazia no universo em que foi demonstrada.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Cada relação sobre duas chaves, dois valores da coluna fixada e dois valores transportados:
    // os subconjuntos das oito células (chave, coluna, valor), como máscaras de bits.
    let holds = |r: u32, k: u32, c: u32, u: u32| r & (1 << (k * 4 + c * 2 + u)) != 0;
    let (mut reach_only, mut constant_only) = (0, 0);
    for r in 0..256_u32 {
        let keys: Vec<u32> =
            (0..2).filter(|&k| (0..2).any(|c| (0..2).any(|u| holds(r, k, c, u)))).collect();
        // A fatia fixa a coluna em v = 0 e deita-a fora. O agregado guarda cada valor.
        let slice = |k: u32| (0..2).filter(|&u| holds(r, k, 0, u)).collect::<Vec<u32>>();
        let whole =
            |k: u32| (0..2).filter(|&u| (0..2).any(|c| holds(r, k, c, u))).collect::<Vec<u32>>();

        let reaches = keys.iter().all(|&k| !slice(k).is_empty());
        let constant = keys.iter().all(|&k| whole(k).len() == 1);
        let answers_for_it = keys.iter().all(|&k| slice(k) == whole(k) && whole(k).len() == 1);

        assert_eq!(answers_for_it, reaches && constant);
        constant_only += i32::from(reaches && !constant);
        reach_only += i32::from(constant && !reaches);
    }
    // Nenhuma das metades implica a outra, portanto uma lei que sustentasse uma delas passaria
    // em relações que a outra rejeita.
    assert!(reach_only > 0 && constant_only > 0);

    // As duas falhas nos termos que a árvore usa, uma por condição.
    let absent_nameplate = [("demand", "hours")];
    let two_units = [("demand", "hours"), ("nameplate", "shifts")];
    let at_the_pin = |rows: &[(&str, &str)]| {
        rows.iter().filter(|r| r.0 == "nameplate").map(|r| r.1.to_string()).collect::<Vec<String>>()
    };
    let every_unit = |rows: &[(&str, &str)]| {
        let mut u = rows.iter().map(|r| r.1.to_string()).collect::<Vec<String>>();
        u.sort();
        u.dedup();
        u
    };
    // Sem valor nominal: o valor fixado não tem nada para ler e a camada nomeia uma unidade na
    // mesma.
    assert!(at_the_pin(&absent_nameplate).is_empty());
    assert_eq!(every_unit(&absent_nameplate), vec!["hours"]);
    // Duas unidades: o valor fixado lê uma delas e não relata desacordo nenhum.
    assert_eq!(at_the_pin(&two_units), vec!["shifts"]);
    assert_eq!(every_unit(&two_units), vec!["hours", "shifts"]);
}
```

**Entrada** `pin_is_the_whole_relation` · **Lei** `algebra/layer_units`

### Um CASE é uma partição, digam os braços o que disserem

```text
Σ |classes| = |candidatos|        para qualquer CASE, com braços sobrepostos ou não
```

Um `CASE` atribui cada linha ao primeiro braço que se verifica, pelo que cada linha cai em exatamente
uma classe e as classes somam sempre os candidatos. É por isso que a contagem não consegue mostrar
dois braços sobrepostos: a sobreposição tem de ser sondada sobre os predicados, contando as linhas em
que dois se verificam ao mesmo tempo. Os braços `clearance` e `interference` do ajuste sobrepõem-se
numa capacidade nominal pontual igual a uma procura pontual, e a ordem dos braços decide essa linha,
o que a entrada `fit_criteria` prova.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Dois predicados sobrepostos nos números de 0 a 9, testados por ordem como um CASE faria.
    let p1 = |x: i32| x >= 3;
    let p2 = |x: i32| x <= 6;
    let rows: Vec<i32> = (0..10).collect();
    let class = |x: i32| if p1(x) { 1 } else if p2(x) { 2 } else { 3 };
    let sizes: Vec<usize> = (1..=3).map(|c| rows.iter().filter(|&&x| class(x) == c).count()).collect();
    assert_eq!(sizes.iter().sum::<usize>(), rows.len());
    // A contagem não vê a sobreposição; os predicados veem.
    let both = rows.iter().filter(|&&x| p1(x) && p2(x)).count();
    assert_eq!(both, 4);
}
```

**Entrada** `case_partition` · **Lei** `algebra/arithmetic_class`

### Uma união disjunta soma

```text
|A ⊎ B| = |A| + |B|          |A ∪ B| = |A| + |B| - |A ∩ B|
```

Um `UNION ALL` guarda todas as linhas dos dois lados, pelo que o seu tamanho é a soma dos deles; um
`UNION` retira as linhas que os dois partilham, e o seu tamanho desce pela interseção. Uma relação que
queira dizer o primeiro e escreva o segundo perde linhas que não consegue reportar.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    for a in 0..32_u32 {
        for b in 0..32_u32 {
            let disjoint_union = a.count_ones() + b.count_ones();
            let union = (a | b).count_ones();
            let intersection = (a & b).count_ones();
            assert_eq!(union, disjoint_union - intersection);
            assert_eq!(disjoint_union, union + intersection);
        }
    }
}
```

**Entrada** `disjoint_union` · **Lei** `algebra/searches`

## 10. A matriz de incidência, os seus subespaços e o seu laplaciano

### As duas regras são complementos ortogonais

```text
B is m x n over a graph with c components: one row per edge, one column per node
  in the edge space, and complements there:  (n - c) + (m - n + c) = m
    cut space   = column space of B   = the gradients      dim  n - c
    cycle space = left nullspace of B = the circulations   dim  m - n + c
  in the node space, and complements there:  (n - c) + c = n
    row space of B                    = the potentials     dim  n - c
    nullspace of B                    = the constants      dim  c
```

⛔ **`B` é `m x n` aqui e em todo este repositório**: uma linha por aresta, uma coluna por nó, `-1`
na cauda e `+1` na cabeça. Cada um daqueles quatro nomes depende dessa escolha e nada mais depende,
portanto é declarada uma vez, aqui, e o resto do repositório aponta para esta entrada em vez de a
repetir. Usar as duas convenções é como se escreve *o espaço de linhas mais o núcleo à esquerda*,
que não decompõe nada: sob qualquer das orientações essas duas parcelas vivem em espaços
diferentes. Esta é a orientação de Gilbert Strang, cujo capítulo de grafos todos os cabeçalhos aqui
citam, e é aquela sob a qual `BᵀB` é o laplaciano do grafo.

Este modelo tem dois grafos e duas regras, e as regras são esses dois subespaços.

A **regra da fusão** é um equilíbrio NUM NÓ: o que uma camada composta declara é igual à soma sobre
as suas partes, cada uma convertida, menos o que foi eliminado. Um equilíbrio num nó é uma condição
do espaço de cortes, que é a lei das correntes de Kirchhoff, e a eliminação é o seu termo de fonte.

A **regra da conversão** é uma soma AO LONGO DE UM CICLO: os fatores multiplicam para um, portanto o
`log phi` telescopa para zero e existe um potencial, um log-tamanho absoluto por unidade cujas
diferenças são os fatores declarados. Uma soma ao longo de um ciclo é uma condição do espaço de
ciclos, que é a lei das tensões de Kirchhoff.

⭐⭐ São complementos ortogonais, pelo que uma declaração pode cumprir uma e violar a outra, e os dois
grafos precisam de duas regras e não de uma. O `checks/jagged_layer` acusa do lado do corte e o
`checks/conversion_cycle_does_not_close` do lado do ciclo.

⛔ **As dimensões são medidas e não estão escritas aqui.** O `assets/sqlc/rank/cycle_space.sqlc`
imprime-as por grafo; uma contagem nesta página apodreceria. O que o bloco prova é a aritmética a que
esses números obedecem, e não precisa de matriz nenhuma: uma floresta de expansão tem exatamente
`n - c` arestas, cada aresta que ela rejeita fecha exatamente um ciclo, e as duas contagens enchem o
`m`. O capítulo de grafos de Gilbert Strang é a referência.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Cada grafo em quatro nós etiquetados: cada uma das seis arestas possíveis presente ou ausente.
    const E: [(usize, usize); 6] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
    const N: usize = 4;
    let up = |root: &[usize; N], mut x: usize| {
        while root[x] != x {
            x = root[x];
        }
        x
    };

    for mask in 0..64u32 {
        let edges: Vec<(usize, usize)> =
            (0..6).filter(|i| mask >> i & 1 == 1).map(|i| E[i]).collect();
        let m = edges.len();

        // Uma floresta de expansão, por union-find. O que aceita é a floresta; o que rejeita é uma corda.
        let mut root = [0usize, 1, 2, 3];
        let (mut forest, mut chords) = (0usize, 0usize);
        for &(a, b) in &edges {
            let (ra, rb) = (up(&root, a), up(&root, b));
            if ra == rb {
                chords += 1;
            } else {
                root[ra] = rb;
                forest += 1;
            }
        }
        let c = (0..N).filter(|&x| up(&root, x) == x).count();

        // Uma floresta de expansão tem exatamente n - c arestas, que é a dimensão do espaço de cortes.
        assert_eq!(forest, N - c);
        // Cada aresta que rejeitou fecha um ciclo, que é a dimensão do espaço de ciclos.
        assert_eq!(chords, m + c - N);
        // E as duas enchem o espaço de arestas, pelo que nada fica fora delas.
        assert_eq!(forest + chords, m);
    }

    // A ortogonalidade é o telescopar: uma diferença de potencial somada ao longo de um passeio
    // fechado é zero, pelo que nenhum gradiente tem componente de ciclo e nenhuma circulação é uma
    // diferença de potencial.
    let potential = [7.0, 2.0, 5.0, 11.0];
    for walk in [
        vec![(0usize, 1usize), (1, 2), (2, 0)],
        vec![(0, 1), (1, 3), (3, 2), (2, 0)],
    ] {
        let round: f64 = walk.iter().map(|&(a, b)| potential[b] - potential[a]).sum();
        assert!(close(round, 0.0));
    }
}
```

**Entrada** `incidence_subspaces` · **Lei** `none`

### O laplaciano é uma junção com um agrupamento

```text
BtB = D - W           degree on the diagonal, negative adjacency off it
  entry (a, b)  =  sum over e of  B[e,a] * B[e,b]    a join on the EDGE index, a group per pair
  rows before the group  =  sum of k_e squared  =  4m
  trace                  =  sum of the degrees   =  2m
  every row sums to zero, so the constants are in the kernel
```

Nada é transposto para lá chegar, porque não há nada a formar. Uma matriz esparsa guardada por
colunas É a sua forma de coordenadas, que é uma relação, portanto `B'` são dois nomes de coluna
trocados e nenhum dado se move. O `examples/matrices/README.md` diz o mesmo de `D'`, onde a
transposição é a reetiquetagem e não uma operação. O que resta é uma auto-junção sobre o índice de
arestas com um agrupamento pelo par de nós, que é a entrada `product_is_join` a chegar a um segundo
produto.

⭐⭐ **O tamanho da junção está fixado antes de ela correr.** Cada aresta tem exatamente dois
extremos, portanto cada fibra do índice de arestas é dois e a auto-junção devolve `4m` linhas, que é
a entrada `self_join_sizes`. Uma junção que devolva outra coisa significa que a incidência não é uma
incidência, e isso é verificável antes de qualquer dimensão ser calculada.

⛔ **O agrupamento é uma SOMA e não um máximo, e é isso que faz da diagonal de fora uma
multiplicidade.** Duas arestas paralelas entre um par contribuem duas vezes; uma dobra idempotente
reportá-las-ia uma só vez. A entrada `excess` é a regra que o decide, e o `examples/columns` é onde
este produto é formado sobre o grafo de composição.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Cada grafo em quatro nós etiquetados, e depois um multigrafo que os simples não alcançam.
    const E: [(usize, usize); 6] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
    const N: usize = 4;

    let mut cases: Vec<Vec<(usize, usize)>> = (0..64u32)
        .map(|mask| (0..6).filter(|i| mask >> i & 1 == 1).map(|i| E[i]).collect())
        .collect();
    // Duas arestas paralelas, para que a diagonal de fora conte multiplicidade e não presença.
    cases.push(vec![(0, 1), (0, 1), (1, 2)]);

    for edges in cases {
        let m = edges.len();

        // B, m x n: uma linha por aresta, -1 na cauda e +1 na cabeça.
        let mut b = vec![vec![0.0_f64; N]; m];
        for (e, &(tail, head)) in edges.iter().enumerate() {
            b[e][tail] -= 1.0;
            b[e][head] += 1.0;
        }

        // O produto como está escrito: uma soma sobre as arestas para cada par de nós.
        let mut written = vec![vec![0.0_f64; N]; N];
        for a in 0..N {
            for d in 0..N {
                for e in 0..m {
                    written[a][d] += b[e][a] * b[e][d];
                }
            }
        }

        // O mesmo como uma junção sobre o índice de arestas e um agrupamento pelo par de nós. A
        // junção visita só os não-nulos, que são os dois extremos de cada aresta.
        let mut triples: Vec<(usize, usize, f64)> = Vec::new();
        for (e, &(tail, head)) in edges.iter().enumerate() {
            triples.push((e, tail, -1.0));
            triples.push((e, head, 1.0));
        }
        let mut joined = 0usize;
        let mut grouped = vec![vec![0.0_f64; N]; N];
        for &(e, a, v) in &triples {
            for &(f, d, w) in &triples {
                if e == f {
                    grouped[a][d] += v * w;
                    joined += 1;
                }
            }
        }

        // Cada fibra do índice de arestas é dois, portanto a junção tem 4m linhas antes do grupo.
        assert_eq!(joined, 4 * m);
        for a in 0..N {
            for d in 0..N {
                assert!(close(grouped[a][d], written[a][d]));
            }
        }

        // Grau na diagonal, adjacência negativa fora dela, contando multiplicidade.
        for a in 0..N {
            let degree = edges.iter().filter(|&&(x, y)| x == a || y == a).count();
            assert!(close(written[a][a], degree as f64));
            for d in 0..N {
                if d != a {
                    let parallel = edges
                        .iter()
                        .filter(|&&(x, y)| (x, y) == (a, d) || (x, y) == (d, a))
                        .count();
                    assert!(close(written[a][d], -(parallel as f64)));
                }
            }
        }

        // O aperto de mão, e as constantes no núcleo.
        let trace: f64 = (0..N).map(|a| written[a][a]).sum();
        assert!(close(trace, 2.0 * m as f64));
        for a in 0..N {
            assert!(close((0..N).map(|d| written[a][d]).sum::<f64>(), 0.0));
        }
    }
}
```

**Entrada** `laplacian_is_a_join` · **Lei** `none`

### O laplaciano compõe-se, e o seu núcleo também

```text
L = sum over the edges of L_e        each term rank one, and the sum owes no correction
  x' L x   =  sum over e of (x_head - x_tail) squared   =  the energy, which is ||Bx|| squared
  ker L    =  ker B  =  the constants                   so rank L = rank B = n - c
  L(G - e) =  L(G) - L_e                                decomposition is subtraction
```

O laplaciano de uma união de grafos é a soma dos laplacianos, um termo de característica um por
aresta, e a soma não deve correção nenhuma. **Esse é o contraste exato com o grafo de camadas.** Ali
a dobra é aditiva sobre um portador conservado, o excesso sobre a imagem é o `sum of (k - 1) w` da
entrada `excess`, e esse excesso É a eliminação. Aqui cada aresta contribui com o seu próprio termo
independentemente do que mais esteja presente, portanto compor dois grafos é somar e decompor um é
subtrair, sem nada a corrigir.

⭐⭐ **E o núcleo compõe-se com ele.** `x' L x` é a soma das diferenças ao quadrado ao longo das
arestas, portanto é `||Bx||` ao quadrado; uma soma de quadrados é zero só quando cada termo o é,
portanto `L x = 0` diz exatamente `B x = 0`, que diz que `x` é constante ao longo de cada aresta. O
núcleo é por isso as constantes, uma dimensão por componente, e acrescentar uma aresta ou fecha um
ciclo e deixa o núcleo quieto ou junta duas componentes e baixa-o em um.

⭐ **É isso que autoriza medir a característica sobre o laplaciano.** `rank L = rank B = n - c`,
portanto um programa pode eliminar sobre o laplaciano `n` por `n` em vez da incidência `m` por `n` e
obter a dimensão do espaço de cortes. O `examples/columns` faz exatamente isso e confronta a
resposta com um percurso que não partilha código nenhum com ela.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Cada grafo em quatro nós etiquetados: cada uma das seis arestas possíveis presente ou ausente.
    const E: [(usize, usize); 6] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
    const N: usize = 4;

    // O laplaciano de uma aresta só, o produto exterior da sua linha de B consigo mesma.
    let term = |tail: usize, head: usize| {
        let mut l = vec![vec![0.0_f64; N]; N];
        for (a, sa) in [(tail, -1.0_f64), (head, 1.0_f64)] {
            for (d, sd) in [(tail, -1.0_f64), (head, 1.0_f64)] {
                l[a][d] += sa * sd;
            }
        }
        l
    };

    for mask in 0..64u32 {
        let edges: Vec<(usize, usize)> =
            (0..6).filter(|i| mask >> i & 1 == 1).map(|i| E[i]).collect();

        // A soma dos termos por aresta, contra grau menos adjacência construído diretamente.
        let mut summed = vec![vec![0.0_f64; N]; N];
        for &(tail, head) in &edges {
            let l = term(tail, head);
            for a in 0..N {
                for d in 0..N {
                    summed[a][d] += l[a][d];
                }
            }
        }
        let mut written = vec![vec![0.0_f64; N]; N];
        for &(tail, head) in &edges {
            written[tail][tail] += 1.0;
            written[head][head] += 1.0;
            written[tail][head] -= 1.0;
            written[head][tail] -= 1.0;
        }
        for a in 0..N {
            for d in 0..N {
                assert!(close(summed[a][d], written[a][d]));
            }
        }

        // Retirar uma aresta subtrai exatamente o termo dessa aresta: decompor é subtrair.
        for &(tail, head) in &edges {
            let rest: Vec<(usize, usize)> = {
                let mut r = edges.clone();
                let at = r.iter().position(|&x| x == (tail, head)).unwrap();
                r.remove(at);
                r
            };
            let l = term(tail, head);
            for a in 0..N {
                for d in 0..N {
                    let without: f64 = rest
                        .iter()
                        .map(|&(t, h)| term(t, h)[a][d])
                        .sum();
                    assert!(close(summed[a][d] - l[a][d], without));
                }
            }
        }

        // As componentes, por union-find, para que o núcleo abaixo tenha em que ser constante.
        let components = {
            let mut root = [0usize, 1, 2, 3];
            let up = |root: &[usize; N], mut x: usize| {
                while root[x] != x {
                    x = root[x];
                }
                x
            };
            for &(tail, head) in &edges {
                let (rt, rh) = (up(&root, tail), up(&root, head));
                if rt != rh {
                    root[rt] = rh;
                }
            }
            (0..N).map(|x| up(&root, x)).collect::<Vec<usize>>()
        };

        // A identidade da energia: x L x é a soma das diferenças ao quadrado ao longo das arestas.
        for x in [
            vec![1.0, 2.0, 3.0, 4.0],
            vec![0.0, 0.0, 1.0, 1.0],
            vec![5.0, 5.0, 5.0, 5.0],
        ] {
            let quadratic: f64 = (0..N)
                .map(|a| (0..N).map(|d| x[a] * summed[a][d] * x[d]).sum::<f64>())
                .sum();
            let energy: f64 = edges
                .iter()
                .map(|&(tail, head)| (x[head] - x[tail]) * (x[head] - x[tail]))
                .sum();
            assert!(close(quadratic, energy));

            // Uma soma de quadrados é zero só quando cada termo o é, portanto uma energia não nula
            // proíbe L x = 0. Isso é ker L = ker B, e a característica das duas segue.
            let l_x: Vec<f64> = (0..N)
                .map(|a| (0..N).map(|d| summed[a][d] * x[d]).sum())
                .collect();
            if energy > 0.0 {
                assert!(l_x.iter().any(|v| !close(*v, 0.0)));
            }
        }

        // Um vetor constante em cada componente tem energia zero e está no núcleo. Os indicadores
        // têm suportes disjuntos, portanto há c deles e são independentes.
        for class in 0..N {
            let indicator: Vec<f64> = (0..N)
                .map(|a| if components[a] == class { 1.0 } else { 0.0 })
                .collect();
            if !indicator.iter().any(|v| *v > 0.0) {
                continue;
            }
            let energy: f64 = edges
                .iter()
                .map(|&(tail, head)| {
                    (indicator[head] - indicator[tail]) * (indicator[head] - indicator[tail])
                })
                .sum();
            assert!(close(energy, 0.0));
            for a in 0..N {
                assert!(close((0..N).map(|d| summed[a][d] * indicator[d]).sum::<f64>(), 0.0));
            }
        }
    }
}
```

**Entrada** `laplacian_decomposes` · **Lei** `none`

### Uma fusão não acrescenta ciclo nenhum, quaisquer que sejam as suas partes

```text
a fusion is one new node and one edge per part
  k parts from k distinct components   dn=+1  dm=+k  dc=-(k-1)   d(m-n+c) =  0
  two parts already in one component   dn=+1  dm=+2  dc= 0       d(m-n+c) = +1
```

Uma fusão acrescenta a camada composta como nó e uma aresta por parte, pelo que **cada parte é uma
corda à espera de acontecer**. Quando as partes vêm de `k` componentes distintas o nó novo une-as
numa só, o `c` desce `k - 1`, e a dimensão não se move: a fusão não acrescenta ciclo nenhum, com
quantas partes tenha. Quando duas das suas partes já estão na mesma componente, a segunda aresta
fecha um laço e a dimensão sobe um.

⭐⭐ Esse laço são dois caminhos a chegar a uma folha sob uma só dobra, que é exactamente o que o
`checks/jagged_layer` acusa, e é por isso que essa regra é sobre uma partição e não sobre uma
contagem: *as partes de uma fusão particionam o que compõem*. Portanto nenhuma declaração legítima
pode mover esta dimensão, e a medição é uma regra e não uma descrição. O `algebra/cycle_space` é essa
regra lida como lei: confronta a dimensão do grafo de camadas com o que o `checks/jagged_layer`
encontrou, em zero contra não-zero, e os dois instrumentos não partilham código nenhum.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // m - n + c sobre uma lista explícita de arestas em `n` nós etiquetados.
    let dim = |n: usize, edges: &[(usize, usize)]| -> i64 {
        let up = |root: &Vec<usize>, mut x: usize| {
            while root[x] != x {
                x = root[x];
            }
            x
        };
        let mut root: Vec<usize> = (0..n).collect();
        for &(a, b) in edges {
            let (ra, rb) = (up(&root, a), up(&root, b));
            if ra != rb {
                root[ra] = rb;
            }
        }
        let c = (0..n).filter(|&x| up(&root, x) == x).count();
        edges.len() as i64 - n as i64 + c as i64
    };

    // k partes, cada uma a sua componente. Fundi-las acrescenta o nó composto e uma aresta por parte.
    for k in 1..=5usize {
        assert_eq!(dim(k, &[]), 0);
        let fused: Vec<(usize, usize)> = (0..k).map(|p| (k, p)).collect();
        assert_eq!(dim(k + 1, &fused), 0);
    }

    // Duas partes que já partilham uma componente: o nó 0 compõe o nó 1 um nível abaixo.
    assert_eq!(dim(2, &[(0, 1)]), 0);
    // Fundir as duas num nó 2 novo. A segunda aresta fecha um laço e a dimensão sobe.
    assert_eq!(dim(3, &[(0, 1), (2, 0), (2, 1)]), 1);
}
```

**Entrada** `fusion_adds_no_cycle` · **Lei** `algebra/cycle_space`

### O núcleo do mapa de composição é o que uma fusão declarou imaterial

```text
F a incidência das partes, Phi os fatores, cada parte numa só fusão
  dim ker(F Phi) = m - |fusões|
  onde o espaço de ciclos é zero, m = n - c, portanto é também |folhas| - c
```

Uma parte é ao mesmo tempo uma coluna de `F` e uma aresta do grafo de camadas, e pertence a uma só
fusão, portanto dobrar as partes sobre as suas fusões dá fibras cuja soma é o número de arestas e
cuja contagem de caixas é a característica. O núcleo é o que sobra. Onde o espaço de ciclos é zero
os nós internos são exatamente as fusões, e a dimensão é a contagem de folhas menos o número de
componentes.

⭐⭐ Um gerador dele tira uma unidade de fornecimento composto de uma parte da fusão e põe-na
noutra, e o valor composto não se mexe. Essa invisibilidade não é um subproduto da aritmética: é a
afirmação que a fusão faz. `pm:Layer` define uma camada como um lugar cujo resto se detém
independentemente do de todas as outras, e `asrt:Fusion` transforma isso em **fundir só o que é
fungível**. Fundir é quocientar, e esta dimensão é quanto foi quocientado.

⛔ Os pares de irmãs não são os geradores. Uma fusão de `k` partes tem `k` sobre dois pares de
irmãs e `k - 1` movimentos independentes, e esses coincidem só enquanto nenhuma fusão tiver três
partes, onde o terceiro par é a soma dos outros dois. Contar pares e reportar o total como uma
dimensão está certo num corpus de fusões binárias e errado na primeira fusão com três.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // A forest of fusions: `sizes[i]` parts hang under fusion `i`, each part a fresh leaf.
    // Every fusion is its own component, so `c` is the number of fusions.
    let measure = |sizes: &[usize]| -> (i64, i64, i64, i64) {
        assert!(sizes.iter().all(|&k| k >= 1));
        let fusions = sizes.len() as i64;
        let parts: i64 = sizes.iter().map(|&k| k as i64).sum();
        let (n, m, c, leaves) = (fusions + parts, parts, fusions, parts);
        let kernel: i64 = sizes.iter().map(|&k| k as i64 - 1).sum();
        (kernel, m - fusions, leaves - c, n - c - fusions)
    };

    // The dimension, the edge count less the fusions, the leaf count less the components, and
    // the rank read off the graph: four routes, one number.
    for a in 1..=4usize {
        for b in 1..=4usize {
            for d in 1..=4usize {
                let (kernel, by_edges, by_leaves, by_rank) = measure(&[a, b, d]);
                assert_eq!(kernel, by_edges);
                assert_eq!(kernel, by_leaves);
                assert_eq!(kernel, by_rank);
            }
        }
    }

    // The sibling pairs are not the generators. They agree while no fusion holds three parts.
    let pairs = |k: i64| k * (k - 1) / 2;
    let generators = |k: i64| k - 1;
    for k in 1..=2i64 {
        assert_eq!(pairs(k), generators(k));
    }
    for k in 3..=6i64 {
        assert!(pairs(k) > generators(k));
    }
}
```

**Entrada** `composition_kernel` · **Lei** `algebra/composition_kernel`


### O dobrar tem quatro subespaços e só um deles é alguma vez uma afirmação

```text
F Phi : R^P -> R^X, cada parte numa só fusão, cada fator estritamente positivo
  dim ker(F Phi)      =  |P| - |X|      os desvios que uma fusão declarou imateriais
  dim row(F Phi)      =  |X|            um funcional positivo por fusão
  dim col(F Phi)      =  |X|            o espaço das fusões inteiro
  dim ker((F Phi)^T)  =  0
  row(F Phi) + ker(F Phi) = R^P, bloco a bloco sobre as mesmas fibras
  v em ker(F Phi) e v >= 0  =>  v = 0
```

Uma parte pertence a uma só fusão, portanto a linha de uma fusão é `Phi` nas partes dessa fusão e
zero em todo o resto, e os suportes das linhas são disjuntos dois a dois. Vetores de suportes
disjuntos, nenhum deles nulo, são independentes, porque o coeficiente de um lê-se em qualquer
coordenada que os outros não tocam. Logo a característica é simplesmente o número de linhas, e isso
decide de uma vez os dois subespaços do lado das fusões: nada sobra, portanto o núcleo à esquerda é
vazio e o espaço das colunas é tudo.

⭐⭐ É por isso que uma fungibilidade declarada tem exatamente um lado deste mapa onde viver. Um
núcleo do lado das partes é a afirmação que a fusão faz, que fornecimento movido entre as suas
partes deixa o valor composto onde estava. Um núcleo do lado das fusões seria um facto de género
oposto, uma combinação de valores compostos que nenhuma atribuição às partes consegue alcançar, e
não há nenhuma. Um mapa, dois núcleos, e só um deles é alguma vez algo que um documento afirma.

⭐⭐ E o fornecimento não se esconde naquele que existe. O bloco do espaço das linhas de uma fusão é
gerado por `Phi` restringido às suas partes, com todas as entradas estritamente positivas, portanto
o espaço das linhas encontra o octante não negativo. O núcleo não: `Phi . v = 0` com `Phi` positivo
obriga qualquer `v` não nulo a levar um mais e um menos. Um desvio tira de uma parte exatamente o
que dá a outra, que é o portador conservado escrito como um subespaço e não como uma regra.

⛔ As dimensões não dependem dos fatores e as direções dependem. Multiplicar uma coluna por um
número positivo não pode mudar que colunas são independentes, portanto todas as dimensões acima
sobrevivem a qualquer fator de conversão. Um gerador não: uma parte cujo fator é uma ausência
tipada deixa o seu bloco a apontar para um sítio que ninguém enunciou, com a dimensão na mesma
exata.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Rank by elimination with partial pivoting. Nothing below may read a magnitude, so the
    // factors are deliberately unequal and every assertion has to survive that.
    let rank = |mut a: Vec<Vec<f64>>| -> usize {
        let (rows, cols) = (a.len(), a.first().map_or(0, Vec::len));
        let mut r = 0;
        for c in 0..cols {
            let pivot = (r..rows)
                .max_by(|&i, &j| a[i][c].abs().total_cmp(&a[j][c].abs()))
                .filter(|&i| a[i][c].abs() > 1e-9);
            if let Some(p) = pivot {
                a.swap(r, p);
                for i in (r + 1)..rows {
                    let f = a[i][c] / a[r][c];
                    for j in c..cols {
                        a[i][j] -= f * a[r][j];
                    }
                }
                r += 1;
            }
        }
        r
    };
    let transpose = |a: &[Vec<f64>]| -> Vec<Vec<f64>> {
        (0..a[0].len()).map(|j| a.iter().map(|row| row[j]).collect()).collect()
    };

    // `F Phi` for a fibre profile: one row per fusion, one column per part, the factors strictly
    // positive and no two alike.
    let fold = |sizes: &[usize]| -> Vec<Vec<f64>> {
        let mut m = vec![vec![0.0; sizes.iter().sum()]; sizes.len()];
        let mut col = 0;
        for (row, &k) in sizes.iter().enumerate() {
            for t in 0..k {
                m[row][col] = 0.25 * (col + 1) as f64 * (t + 2) as f64;
                col += 1;
            }
        }
        m
    };

    for a in 1..=4usize {
        for b in 1..=4usize {
            for d in 1..=4usize {
                let sizes = [a, b, d];
                let m = fold(&sizes);
                let (rows, cols) = (m.len(), m[0].len());
                let r = rank(m.clone());

                // Full row rank, so the left null space is empty and the column space is whole.
                assert_eq!(r, rows);
                assert_eq!(rows - r, 0);
                // Row rank is column rank, which is the row space on the part side.
                assert_eq!(r, rank(transpose(&m)));
                // And the null space is the rest of the part space.
                assert_eq!(cols - r, sizes.iter().map(|&k| k - 1).sum::<usize>());

                // Block by block, over the same fibres: one direction the figure reads,
                // `k - 1` it does not, and nothing of the row outside its own fusion's columns.
                let mut col = 0;
                for (row, &k) in sizes.iter().enumerate() {
                    let block: Vec<Vec<f64>> = vec![m[row][col..col + k].to_vec()];
                    assert_eq!(rank(block.clone()), 1);
                    assert_eq!(k - rank(block), k - 1);
                    assert!(m[row]
                        .iter()
                        .enumerate()
                        .all(|(j, &x)| (col..col + k).contains(&j) || x == 0.0));
                    col += k;
                }
            }
        }
    }

    // A positive generator, and a null space that misses the non-negative orthant: every
    // non-negative offset a fusion cannot see is zero.
    let phi = [0.25, 2.0, 40.0];
    assert!(phi.iter().all(|&x| x > 0.0));
    for i in 0..4 {
        for j in 0..4 {
            for k in 0..4 {
                let v = [f64::from(i), f64::from(j), f64::from(k)];
                let dot: f64 = phi.iter().zip(v).map(|(a, b)| a * b).sum();
                assert_eq!(dot == 0.0, v.iter().all(|&x| x == 0.0));
            }
        }
    }
    // And a generator of the null space carries both signs, which is what an offset is.
    let g = [phi[1], -phi[0], 0.0];
    let dot: f64 = phi.iter().zip(g).map(|(a, b)| a * b).sum();
    assert_eq!(dot, 0.0);
    assert!(g.iter().any(|&x| x > 0.0) && g.iter().any(|&x| x < 0.0));
}
```

**Entrada** `fold_subspaces` · **Lei** `algebra/composition_row_space`, `algebra/composition_image`

### O núcleo de uma descida é a soma dos núcleos que estão dentro dela

```text
Psi = A_1 ... A_d, cada A_i sobrejetiva
  dim ker(Psi) = Σ dim ker(A_i)
sob uma raiz cuja descida é uma árvore, com L folhas e F fusões lá dentro
  partes = L + F - 1    logo    Σ (partes_x - 1) = partes - F = L - 1 = dim ker(Psi)
um segundo caminho até uma folha acrescenta uma parte e nenhuma folha, logo a soma sobe e L - 1 não
```

Cada nível do dobrar é sobrejetivo, portanto a composta desde as camadas-folha sob uma raiz até ao
valor único dessa raiz também o é, e o seu núcleo é tudo menos uma dimensão. Contando pelo outro
lado, cada fusão do fecho contribui com o seu próprio bloco uma vez. Numa árvore as duas coincidem
por contagem de arestas, e a identidade é o que torna o núcleo de um valor composto calculável
nível a nível em vez de só como um todo.

⭐⭐ Portanto o conteúdo da identidade não é a aritmética, é que a descida É uma árvore. Uma folha
alcançada por dois caminhos acrescenta uma parte ao fecho e nenhuma folha, portanto os blocos somam
mais alto enquanto a dimensão da própria composta fica onde estava. Um ciclo tira folhas sem tirar
blocos. Ambos aterram na mesma comparação, de lados opostos.

⛔ E é o núcleo do dobrar que fecha assim, nunca o espaço das linhas. Os espaços das linhas correm
na direção contrária: cada nível composto por cima só pode estreitar o que sobrevive até ao topo,
portanto essa cadeia desce enquanto os núcleos sobem. Ler a direção de uma cadeia pela outra é como
se constrói um fecho que cresce onde devia encolher.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // A descent as a parent per layer: layer 0 is the root and layer `i` hangs under a lower
    // index, which is every rooted tree on `n` labelled layers and nothing that is not one.
    let measure = |parent: &[usize], n: usize| -> (usize, usize, usize) {
        let mut children = vec![0usize; n];
        for &p in parent {
            children[p] += 1;
        }
        let fusions = children.iter().filter(|&&c| c > 0).count();
        let blocks: usize = children.iter().filter(|&&c| c > 0).map(|&c| c - 1).sum();
        (blocks, n - fusions, fusions)
    };

    let mut trees = 0;
    for n in 2..=6usize {
        let total: usize = (1..n).product();
        for code in 0..total {
            let mut c = code;
            let mut parent = vec![0usize; n - 1];
            for (j, slot) in parent.iter_mut().enumerate() {
                *slot = c % (j + 1);
                c /= j + 1;
            }
            let (blocks, leaves, fusions) = measure(&parent, n);
            // The composite is onto one figure, so its null space is the leaves less one, and
            // the blocks below the root sum to the same number.
            assert_eq!(blocks, leaves - 1);
            // The edge count is what forces it: on a tree every layer but the root is one part.
            assert_eq!(parent.len(), leaves + fusions - 1);
            trees += 1;
        }
    }
    assert!(trees > 0);

    // A second path is what parts the two routes. A root over two fusions, and one leaf reached
    // through both: four layers, four parts, and no tree.
    let edges = [(1usize, 0usize), (2, 0), (3, 1), (3, 2)];
    let mut children = vec![0usize; 4];
    for &(_, p) in &edges {
        children[p] += 1;
    }
    let fusions = children.iter().filter(|&&c| c > 0).count();
    let blocks: usize = children.iter().filter(|&&c| c > 0).map(|&c| c - 1).sum();
    let leaves = 4 - fusions;
    assert_eq!(edges.len(), leaves + fusions);
    assert!(blocks > leaves - 1);
}
```

**Entrada** `kernel_closes` · **Lei** `algebra/composition_closure`

### Uma eliminação é uma remoção, e nenhum fluxo a consegue produzir

```text
B a incidência, y um vetor de arestas qualquer, 1 o vetor de nós só com uns
  1' B' y = (B 1)' y = 0        portanto uma divergência soma zero em cada componente
  e >= 0 e positivo nalgum sítio  =>  e não é uma divergência
```

Cada linha de `B` tem um `-1` e um `+1`, portanto `B` envia o vetor só com uns para zero e a
divergência de qualquer fluxo soma zero em cada componente. O espaço dos nós parte-se no espaço das
linhas, que é toda a divergência que um fluxo consegue produzir, e nas constantes, uma por
componente. Uma eliminação é não negativa e não é zero em todo o lado, portanto a sua componente
nas constantes não se anula e nenhuma redistribuição de fornecimento pelas partes a explica.

⭐ É essa a diferença entre uma remoção e um rearranjo, escrita como subespaço. Uma correção
assente no espaço das linhas moveria fornecimento entre camadas e deixaria o total de cada
componente onde estava. O `e` não deixa, e é por isso que é subtraído em vez de transportado, e por
isso que `asrt:Elimination` pergunta contra o quê foi removido.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // B is m x n, one row per edge, -1 at the tail and +1 at the head. Two components.
    let edges: &[(usize, usize)] = &[(0, 1), (1, 2), (3, 4)];
    let component: &[usize] = &[0, 0, 0, 1, 1];
    let sizes = [3.0, 2.0];
    let n = component.len();

    let divergence = |y: &[f64]| -> Vec<f64> {
        let mut d = vec![0.0; n];
        for (e, &(tail, head)) in edges.iter().enumerate() {
            d[tail] -= y[e];
            d[head] += y[e];
        }
        d
    };
    let per_component = |v: &[f64]| -> Vec<f64> {
        let mut t = vec![0.0; sizes.len()];
        for (i, &x) in v.iter().enumerate() {
            t[component[i]] += x;
        }
        t
    };

    // Any flow at all: B times the all-ones vector is zero, so its divergence sums to zero.
    for y in [[1.0, 2.0, 3.0], [-4.0, 0.5, 7.25], [0.0, 0.0, 0.0]] {
        for total in per_component(&divergence(&y)) {
            assert!(close(total, 0.0));
        }
    }

    // An elimination is non-negative and somewhere positive, so it is no flow's divergence.
    let e = [0.0, 1.5, 0.0, 2.0, 0.0];
    assert!(e.iter().all(|&x| x >= 0.0));
    let totals = per_component(&e);
    assert!(close(totals[0], 1.5) && close(totals[1], 2.0));
    assert!(totals.iter().all(|&t| t > 0.0));

    // Split it: the constants carry each component's total, and what is left IS a divergence.
    let constants: Vec<f64> = (0..n).map(|i| totals[component[i]] / sizes[component[i]]).collect();
    let row_part: Vec<f64> = (0..n).map(|i| e[i] - constants[i]).collect();
    for total in per_component(&row_part) {
        assert!(close(total, 0.0));
    }
    assert!(constants.iter().any(|&x| x > 0.0));
}
```

**Entrada** `elimination_leaves` · **Lei** `none`

### Um produto de caminho precisa que haja um caminho

```text
one path to a node   ->  Phi along it is the product of the factors, and it is the only one
two paths to a node  ->  two products, and the arithmetic chooses neither
```

A entrada `conversion_collapses` mostra que um caminho de conversões é uma conversão, o produto dos
seus fatores. Esse resultado é sobre UM caminho. Só é utilizável onde existe O caminho, e essa
condição é exactamente que o espaço de ciclos seja zero: numa floresta cada nó é alcançado de uma só
maneira, pelo que o produto acima dele é um número só.

⛔ Onde chegam dois caminhos, o achatamento tem duas respostas e a aritmética não tem nenhuma. Um
diamante consegue-o com os menores fatores que existem.

⭐ Portanto o achatamento no `composition/derived_quantities.sqlc` e no
`composition/settled_remainders.sqlc` assenta numa medição de grafo e não numa propriedade da
multiplicação. O `assets/sqlc/rank/cycle_space.sqlc` é onde essa medição vive.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // m - n + c sobre uma lista explícita de arestas em `n` nós etiquetados.
    let dim = |n: usize, edges: &[(usize, usize)]| -> i64 {
        let up = |root: &Vec<usize>, mut x: usize| {
            while root[x] != x {
                x = root[x];
            }
            x
        };
        let mut root: Vec<usize> = (0..n).collect();
        for &(a, b) in edges {
            let (ra, rb) = (up(&root, a), up(&root, b));
            if ra != rb {
                root[ra] = rb;
            }
        }
        let c = (0..n).filter(|&x| up(&root, x) == x).count();
        edges.len() as i64 - n as i64 + c as i64
    };

    // Um diamante: a folha é alcançada da raiz de duas maneiras, e as duas escalam de modo diferente.
    let diamond = [(0usize, 1usize), (0, 2), (1, 3), (2, 3)];
    assert_eq!(dim(4, &diamond), 1);

    // O produto dos fatores por cada braço, que é aquilo a que o `conversion_collapses` reduz um caminho.
    let product = |path: &[f64]| path.iter().product::<f64>();
    assert!(close(product(&[2.0, 1.0]), 2.0));
    assert!(close(product(&[1.0, 3.0]), 3.0));
    // Duas respostas, e nada na aritmética escolhe entre elas.
    assert!(!close(product(&[2.0, 1.0]), product(&[1.0, 3.0])));

    // Retirar um dos braços e o espaço de ciclos é zero outra vez, e o produto é o único que há.
    assert_eq!(dim(4, &[(0, 1), (1, 3)]), 0);
    assert!(close(product(&[2.0, 1.0]), 2.0));
}
```

**Entrada** `path_product_needs_one_path` · **Lei** `none`

### Uma conversão de unidades escala as linhas, e só o espaço de colunas dá por isso

```text
D a positive diagonal, A -> DA        each row scaled by its own factor
  rank(DA)      = rank(A)
  null(DA)      = null(A)
  rowspace(DA)  = rowspace(A)
  colspace(DA)  = D . colspace(A)     the dimension survives, the subspace MOVES
  (DA)'(DA)     = A' D-squared A      quadratic in the factor, so the Gram moves too
  and a D exists on a graph of factors exactly when they multiply to one round every loop
```

Converter um arquivamento para uma unidade comum multiplica cada linha pelo seu próprio fator
positivo, que é uma diagonal positiva `D`. **Três dos quatro subespaços não dão por isso.** Escalar
uma linha não move o espaço gerado pelas linhas e não muda que vetores as linhas anulam, portanto o
espaço de linhas e o espaço nulo ficam fixos, e a característica com eles. O espaço de colunas não
fica fixo: move-se para `D` vezes ele próprio. A Gram também se move, e quadraticamente.

⛔ Portanto uma matriz de Gram sobre quantidades arquivadas é uma afirmação sobre as unidades em que
foram arquivadas, e pedir o espaço de colunas a uma matriz de magnitudes é pedir primeiro um `D`.

⭐⭐⭐ **Isso não é o mesmo que não ter espaço de colunas.** Um `D` é um potencial, um log-tamanho
absoluto por unidade, e um potencial existe exatamente quando os fatores não transportam nada à
volta de um ciclo, que é a entrada `cycle_closes` e a regra que o pergunta a cada documento
carregado.

⛔ **Dois espaços encontram-se aqui e é fácil confundi-los.** A condição verificável é sobre
`log phi`, um vetor de ARESTAS, e é que `log phi` viva no espaço de COLUNAS do grafo de unidades.
O `D` é o potencial que essa condição compra, um vetor de NÓS no espaço de LINHAS desse grafo,
fixado a menos de uma constante por componente. Portanto a geometria é real, pertence a um grafo
que a matriz não contém, e é conhecida até à largura que cada fator arquivado deixa. O grafo das composições
não pede nada a essa regra, porque as suas arestas transportam contagens e uma contagem é
adimensional, e é por isso que o `examples/columns` põe a pergunta primeiro a esse grafo.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // A, três linhas por duas colunas, e um fator positivo por linha.
    let a = [[1.0_f64, 2.0], [3.0, 6.0], [2.0, 4.0]];
    let d = [2.0_f64, 1.0, 5.0];
    let da: Vec<Vec<f64>> = (0..3).map(|i| (0..2).map(|j| d[i] * a[i][j]).collect()).collect();

    // Característica, pelos menores dois por dois. Empilhar A sobre DA mantém-nos nulos: um espaço de linhas.
    let minors = |rows: &[Vec<f64>]| -> Vec<f64> {
        let mut out = Vec::new();
        for i in 0..rows.len() {
            for k in (i + 1)..rows.len() {
                out.push(rows[i][0] * rows[k][1] - rows[i][1] * rows[k][0]);
            }
        }
        out
    };
    let rows_a: Vec<Vec<f64>> = a.iter().map(|r| r.to_vec()).collect();
    let mut stacked = rows_a.clone();
    stacked.extend(da.clone());
    for m in minors(&rows_a).iter().chain(&minors(&da)).chain(&minors(&stacked)) {
        assert!(close(*m, 0.0));
    }

    // O espaço nulo não se move: o mesmo vetor é anulado, e um de fora continua de fora.
    let apply = |rows: &[Vec<f64>], x: [f64; 2]| -> Vec<f64> {
        rows.iter().map(|r| r[0] * x[0] + r[1] * x[1]).collect()
    };
    for v in apply(&rows_a, [2.0, -1.0]).iter().chain(&apply(&da, [2.0, -1.0])) {
        assert!(close(*v, 0.0));
    }
    for v in [apply(&rows_a, [1.0, 0.0]), apply(&da, [1.0, 0.0])] {
        assert!(v.iter().any(|x| !close(*x, 0.0)));
    }

    // O espaço de colunas MOVE-SE: a primeira coluna de DA não é múltipla da primeira de A.
    let column = |rows: &[Vec<f64>], j: usize| -> Vec<f64> { rows.iter().map(|r| r[j]).collect() };
    let (u, v) = (column(&rows_a, 0), column(&da, 0));
    let ratio = v[0] / u[0];
    assert!(v.iter().zip(&u).any(|(y, x)| !close(*y, ratio * x)));

    // A Gram é quadrática no fator, e não é a Gram de A.
    let gram = |rows: &[Vec<f64>]| -> [[f64; 2]; 2] {
        let mut g = [[0.0_f64; 2]; 2];
        for j in 0..2 {
            for k in 0..2 {
                g[j][k] = rows.iter().map(|r| r[j] * r[k]).sum();
            }
        }
        g
    };
    let scaled = gram(&da);
    let squared = {
        let mut g = [[0.0_f64; 2]; 2];
        for j in 0..2 {
            for k in 0..2 {
                g[j][k] = (0..3).map(|i| a[i][j] * d[i] * d[i] * a[i][k]).sum();
            }
        }
        g
    };
    let plain = gram(&rows_a);
    for j in 0..2 {
        for k in 0..2 {
            assert!(close(scaled[j][k], squared[j][k]));
        }
    }
    assert!(!close(scaled[0][0], plain[0][0]));

    // De onde vem o D: um potencial num grafo de fatores, cujas diferenças são esses fatores.
    // Existe quando os fatores multiplicam para um à volta do ciclo.
    let factors = [((0usize, 1usize), 2.0_f64), ((1, 2), 3.0), ((0, 2), 6.0)];
    let potential = [0.0_f64, 2.0_f64.ln(), 6.0_f64.ln()];
    for ((tail, head), phi) in factors {
        assert!(close((potential[head] - potential[tail]).exp(), phi));
    }
    let loop_product = 2.0 * 3.0 / 6.0;
    assert!(close(loop_product, 1.0));

    // Mude um fator e o ciclo deixa de fechar. A árvore já fixou o potencial, portanto a corda
    // não tem liberdade nenhuma e nenhum D reproduz os três.
    let open = 2.0 * 3.0 / 5.0;
    assert!(!close(open, 1.0));
    assert!(!close((potential[2] - potential[0]).exp(), 5.0));
}
```

**Entrada** `units_scale_rows` · **Regra** `checks/conversion_cycle_does_not_close`
