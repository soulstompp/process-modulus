// ⛔ THE HEADER OF THIS PROGRAM IS `README.md` BESIDE IT, AND THERE IS ONE COPY OF IT.
// GitHub renders a directory's README and renders no `//!` block at all, so an argument kept only
// in the source is unreadable from the one place this repository is published.
#![doc = include_str!("README.md")]
#![doc = include_str!("README.pt.md")]

use std::collections::{BTreeMap, BTreeSet};
use std::path::Path;

use polars::prelude::*;

#[path = "../shared/tree/mod.rs"]
mod tree;

/// One edge of the compose graph: a parent template splices a child, some number of times.
struct Edge {
    parent: String,
    child: String,
    /// How many `:compose` directives in the parent name the child.
    ///
    /// ⭐ AN EDGE VECTOR, NEVER AN EDGE WEIGHT. The fold over this graph is a query, which is
    /// idempotent, so multiplicity costs nothing and the graph itself is unweighted. `splices`
    /// is therefore a vector ON the edge space to decompose AGAINST the Laplacian. Weighting the
    /// Laplacian by it would assert the opposite, which is the rule the LAYER graph obeys and
    /// this one does not.
    splices: u32,
}

/// The compose graph, re-derived from `assets/sqlc/` through the one scanner.
///
/// ⭐⭐ THE SAME MODULE `compositions`, `soundness` AND `observations` READ. Three programs ask
/// three questions of this graph and a fourth must not answer a fourth question about a
/// different graph. `examples/shared/tree/mod.rs` says why it is one parser, and `emitted` is
/// the input a graph question owes: it is what `sql-composer` itself sees.
fn compose_graph() -> Vec<Edge> {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("assets/sqlc");
    let mut templates = Vec::new();
    tree::templates(&root, &root, &mut templates);
    templates.sort();

    let mut counted: BTreeMap<(String, String), u32> = BTreeMap::new();
    for (name, body) in &templates {
        for child in tree::references(&tree::emitted(body)) {
            *counted.entry((name.clone(), child)).or_default() += 1;
        }
    }

    counted
        .into_iter()
        .map(|((parent, child), splices)| Edge {
            parent,
            child,
            splices,
        })
        .collect()
}

/// `assets/dag/edges.sql`, the emitter's own copy, parsed back.
///
/// ⭐ READ AS A SECOND ROUTE, NOT AS THE SOURCE. The topology and the splice counts above are
/// re-derived from the tree, so comparing them here is the staleness check `examples/soundness`
/// already makes for its own question. What only the emitter computes is `inner_joins`, which is
/// a judgement about SQL TEXT rather than about the graph, so it is taken rather than forked.
fn emitted_edges() -> BTreeMap<(String, String), (u32, u32)> {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("assets/dag/edges.sql");
    let text = std::fs::read_to_string(&path).unwrap_or_else(|e| panic!("{}: {e}", path.display()));

    let mut out = BTreeMap::new();
    for line in text.lines() {
        let line = line.trim();
        let Some(inner) = line.strip_prefix('(') else { continue };
        let Some(inner) = inner.split(')').next() else { continue };
        let f: Vec<&str> = inner.split(',').map(str::trim).collect();
        if f.len() != 4 {
            continue;
        }
        let unquote = |s: &str| s.trim_matches('\'').to_string();
        out.insert(
            (unquote(f[0]), unquote(f[1])),
            (
                f[2].parse().expect("a splice count"),
                f[3].parse().expect("an inner-join count"),
            ),
        );
    }
    out
}

/// The components of the underlying UNDIRECTED graph, and the spanning forest that finds them.
///
/// Returns a class per node, and per edge whether the walk ACCEPTED it into the forest.
///
/// ⛔ UNDIRECTED, AND THE DIRECTION IS WHAT MUST BE DROPPED. `n − c` and `m − n + c` are facts
/// about the underlying undirected graph; reading them off the directed edges gives a different
/// and wrong `c`. `assets/sqlc/rank/cycle_space.sqlc` states the same thing for the model's own
/// graphs and symmetrises before counting.
///
/// ⭐⭐ WHAT IT ACCEPTS IS THE FOREST AND WHAT IT REJECTS IS A CHORD, which is the third route to
/// both dimensions and the only constructive one: the forest has `n − c` edges and every chord
/// closes exactly one cycle, so counting the two is a basis rather than an arithmetic identity.
/// `src/proofs/README.md`, entry `incidence_subspaces`, proves it on every graph on four nodes.
fn walk(nodes: &[String], edges: &[Edge]) -> (Vec<usize>, Vec<bool>) {
    let index: BTreeMap<&str, usize> = nodes.iter().enumerate().map(|(i, n)| (n.as_str(), i)).collect();
    let mut parent: Vec<usize> = (0..nodes.len()).collect();

    fn find(parent: &mut Vec<usize>, mut x: usize) -> usize {
        while parent[x] != x {
            parent[x] = parent[parent[x]];
            x = parent[x];
        }
        x
    }

    let mut accepted = Vec::with_capacity(edges.len());
    for e in edges {
        let (a, b) = (index[e.parent.as_str()], index[e.child.as_str()]);
        let (ra, rb) = (find(&mut parent, a), find(&mut parent, b));
        accepted.push(ra != rb);
        if ra != rb {
            parent[ra] = rb;
        }
    }
    let class = (0..nodes.len()).map(|i| find(&mut parent, i)).collect();
    (class, accepted)
}

/// Solve `a x = b` by elimination with partial pivoting.
///
/// ⛔ THE LAPLACIAN IS SINGULAR AND THAT IS NOT A DEFECT TO WORK AROUND: its kernel is the
/// constants, one dimension per component, which is the statement that a potential is only ever
/// determined up to an additive constant per component. Pinning one node per component is
/// choosing that constant, and it is the only choice this program makes.
fn solve(mut a: Vec<Vec<f64>>, mut b: Vec<f64>, pinned: &[usize]) -> Vec<f64> {
    let n = a.len();
    for &p in pinned {
        a[p] = vec![0.0; n];
        a[p][p] = 1.0;
        b[p] = 0.0;
    }
    for col in 0..n {
        let pivot = (col..n)
            .max_by(|&i, &j| a[i][col].abs().partial_cmp(&a[j][col].abs()).expect("finite"))
            .expect("a row");
        a.swap(col, pivot);
        b.swap(col, pivot);
        let p = a[col][col];
        assert!(
            p.abs() > 1e-12,
            "the pinned Laplacian is singular at column {col}, which cannot happen once one \
             node per component is pinned"
        );
        for i in 0..n {
            if i != col && a[i][col] != 0.0 {
                let f = a[i][col] / p;
                for j in col..n {
                    a[i][j] -= f * a[col][j];
                }
                b[i] -= f * b[col];
            }
        }
    }
    (0..n).map(|i| b[i] / a[i][i]).collect()
}

/// The rank of a symmetric matrix by elimination with partial pivoting.
///
/// ⭐ A SECOND ROUTE TO `n − c`, WHICH IS THE POINT OF COMPUTING IT AT ALL. The component walk
/// above and this elimination share no code and no idea; `rank(L) = n − c` is an identity, so
/// two routes agreeing is evidence and one route is a definition restated.
fn rank(mut a: Vec<Vec<f64>>) -> usize {
    let n = a.len();
    let mut rank = 0;
    for col in 0..n {
        let Some(pivot) = (rank..n).max_by(|&i, &j| {
            a[i][col].abs().partial_cmp(&a[j][col].abs()).expect("finite")
        }) else {
            break;
        };
        if a[pivot][col].abs() < 1e-9 {
            continue;
        }
        a.swap(rank, pivot);
        let p = a[rank][col];
        for i in 0..n {
            if i != rank && a[i][col].abs() > 0.0 {
                let f = a[i][col] / p;
                for j in col..n {
                    a[i][j] -= f * a[rank][j];
                }
            }
        }
        rank += 1;
    }
    rank
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let edges = compose_graph();
    let emitted = emitted_edges();

    // ------------------------------------------------------------------
    // 1. The graph, re-derived, against the copy the emitter left.
    // ------------------------------------------------------------------
    let derived: BTreeMap<(&str, &str), u32> = edges
        .iter()
        .map(|e| ((e.parent.as_str(), e.child.as_str()), e.splices))
        .collect();
    let stored: BTreeMap<(&str, &str), u32> = emitted
        .iter()
        .map(|((p, c), (s, _))| ((p.as_str(), c.as_str()), *s))
        .collect();
    assert_eq!(
        derived, stored,
        "the compose DAG re-derived from assets/sqlc/ is not the one assets/dag/edges.sql holds, \
         so one of the two is stale. Re-run `cargo run --example compositions`."
    );

    let nodes: Vec<String> = edges
        .iter()
        .flat_map(|e| [e.parent.clone(), e.child.clone()])
        .collect::<BTreeSet<String>>()
        .into_iter()
        .collect();
    let index: BTreeMap<&str, usize> = nodes.iter().enumerate().map(|(i, n)| (n.as_str(), i)).collect();

    let (n, m) = (nodes.len(), edges.len());
    let (class, in_forest) = walk(&nodes, &edges);
    let c = class.iter().collect::<BTreeSet<_>>().len();

    println!("1. the compose graph: {n} templates, {m} edges, {c} component(s)");

    // ------------------------------------------------------------------
    // 2. B, column-wise and sparse, which is the edge list with a sign.
    //
    // ⭐⭐⭐ A SPARSE MATRIX DONE COLUMN-WISE PROPERLY IS ITS COORDINATE FORM, AND THAT IS A
    //    RELATION. Every column of B holds two non-zeros, so materialising 337 dense columns
    //    would be writing 290,000 numbers to carry 1,722. The triples below ARE the columns,
    //    and Arrow stores them the one way that lets the product below be a join.
    //
    // ⛔ AND Bᵀ IS NEVER FORMED, BECAUSE THERE IS NOTHING TO FORM. Transposing this is renaming
    //    two columns, which `examples/matrices/README.md` already says of Dᵀ: `ρ`, and no data
    //    moves.
    // ------------------------------------------------------------------
    let mut edge_id: Vec<u32> = Vec::with_capacity(2 * m);
    let mut node_id: Vec<u32> = Vec::with_capacity(2 * m);
    let mut value: Vec<f64> = Vec::with_capacity(2 * m);
    for (e, edge) in edges.iter().enumerate() {
        edge_id.push(e as u32);
        node_id.push(index[edge.parent.as_str()] as u32);
        value.push(-1.0);
        edge_id.push(e as u32);
        node_id.push(index[edge.child.as_str()] as u32);
        value.push(1.0);
    }
    let incidence = df!["edge" => edge_id, "node" => node_id, "value" => value]?;
    println!("2. B is {m} x {n}, held as {} non-zeros", incidence.height());

    // ------------------------------------------------------------------
    // 3. L = BᵀB, which is one join and one GROUP BY.
    //
    // ⭐⭐⭐ A MATRIX PRODUCT IS A JOIN WITH A `GROUP BY`, and this is that sentence executed
    //    rather than quoted. `src/proofs/README.md`'s `product_is_join` proves it for `F Φ x`;
    //    here the join key is the EDGE index, the group is the pair of nodes, and what falls out
    //    is degree on the diagonal and negative adjacency off it. That is the graph Laplacian.
    //
    // ⭐⭐ THE SELF-JOIN'S SIZE IS A FREE LAW. `references/twelvefold.md` §5: a self-join on a
    //    key has `Σ_b k_b²` rows. Every edge has exactly two endpoints, so every fibre is 2 and
    //    the join must return `4m` rows before grouping. A join returning anything else means
    //    the incidence is not an incidence.
    // ------------------------------------------------------------------
    let product = incidence
        .clone()
        .lazy()
        .join(
            incidence.clone().lazy(),
            [col("edge")],
            [col("edge")],
            JoinArgs::new(JoinType::Inner),
        )
        .collect()?;
    assert_eq!(
        product.height(),
        4 * m,
        "the self-join over the edge index returned {} rows where the fibre profile says {}: \
         every edge has two endpoints, so every fibre is 2 and the size is Σk² = 4m",
        product.height(),
        4 * m
    );

    let laplacian = product
        .lazy()
        .group_by([col("node"), col("node_right")])
        .agg([(col("value") * col("value_right")).sum().alias("w")])
        .filter(col("w").neq(lit(0.0)))
        .sort(["node", "node_right"], Default::default())
        .collect()?;
    println!(
        "3. L = BtB: {} non-zero entries over {n}x{n}",
        laplacian.height()
    );

    // ------------------------------------------------------------------
    // 4. The identities the Laplacian owes, each with two routes.
    // ------------------------------------------------------------------
    let node_l = laplacian.column("node")?.u32()?;
    let node_r = laplacian.column("node_right")?.u32()?;
    let w = laplacian.column("w")?.f64()?;

    let mut dense = vec![vec![0.0_f64; n]; n];
    let mut trace = 0.0;
    let mut row_sum = vec![0.0_f64; n];
    for i in 0..laplacian.height() {
        let (a, b, v) = (
            node_l.get(i).expect("a node") as usize,
            node_r.get(i).expect("a node") as usize,
            w.get(i).expect("a weight"),
        );
        dense[a][b] = v;
        row_sum[a] += v;
        if a == b {
            trace += v;
        }
    }

    assert_eq!(
        trace as usize,
        2 * m,
        "trace(L) is the sum of the degrees and must be 2m: the handshake"
    );
    assert!(
        row_sum.iter().all(|s| s.abs() < 1e-9),
        "a Laplacian's rows sum to zero, so the all-ones vector is in its kernel"
    );

    let rank_l = rank(dense.clone());
    assert_eq!(
        rank_l,
        n - c,
        "rank(L) must be n - c. The elimination says {rank_l}; the component walk says {}",
        n - c
    );

    let cycle = m - n + c;
    assert_eq!(
        rank_l + cycle,
        m,
        "the cut space and the cycle space are orthogonal complements in the edge space, \
         so their dimensions fill it: {rank_l} + {cycle} must be {m}"
    );

    println!("4. trace(L) = {} = 2m, and every row sums to zero", trace as usize);
    println!("   cut space   (rank, n - c)     {rank_l}");
    println!("   cycle space (m - n + c)       {cycle}");
    println!("   kernel      (constants, c)    {c}");
    println!("   and the two fill the edge space: {rank_l} + {cycle} = {m}");

    // ------------------------------------------------------------------
    // 5. A BASIS for the cycle space, which is the null space written out.
    //
    // ⭐⭐⭐ A DIMENSION IS A NUMBER AND A BASIS IS AN OBJECT, AND ONLY THE SECOND COMPOSES. The
    //    forest accepts `n − c` edges and rejects `m − n + c`, and each rejected edge closes
    //    exactly one cycle: itself, plus the one path through the forest that joins its ends.
    //    Those vectors are the fundamental cycle basis, and building them is a third route to
    //    the dimension, constructive where the other two are arithmetic.
    //
    // ⭐⭐ INDEPENDENCE IS FREE AND IS ASSERTED RATHER THAN ARGUED. Every other edge of a
    //    fundamental cycle is a forest edge, so the chord-indexed rows of the basis are the
    //    identity matrix and no cycle is a combination of the others.
    // ------------------------------------------------------------------
    let mut adjacent: Vec<Vec<(usize, usize)>> = vec![Vec::new(); n];
    for (i, e) in edges.iter().enumerate() {
        if in_forest[i] {
            let (a, b) = (index[e.parent.as_str()], index[e.child.as_str()]);
            adjacent[a].push((b, i));
            adjacent[b].push((a, i));
        }
    }

    // One rooted tree per component, so a path between any two nodes is two climbs to their
    // meeting point. The root of each component is where the climb stops.
    let (mut depth, mut up_node, mut up_edge) = (vec![usize::MAX; n], vec![usize::MAX; n], vec![usize::MAX; n]);
    for start in 0..n {
        if depth[start] != usize::MAX {
            continue;
        }
        depth[start] = 0;
        let mut queue = std::collections::VecDeque::from([start]);
        while let Some(x) = queue.pop_front() {
            for &(y, e) in &adjacent[x] {
                if depth[y] == usize::MAX {
                    (depth[y], up_node[y], up_edge[y]) = (depth[x] + 1, x, e);
                    queue.push_back(y);
                }
            }
        }
    }

    let (mut cycle_id, mut cycle_edge, mut cycle_sign) = (Vec::new(), Vec::new(), Vec::new());
    let mut lengths: BTreeMap<usize, usize> = BTreeMap::new();
    let mut basis = 0_u32;
    for (i, e) in edges.iter().enumerate() {
        if in_forest[i] {
            continue;
        }
        let (u, v) = (index[e.parent.as_str()], index[e.child.as_str()]);

        // The chord runs u -> v; the forest path runs v back to u, and the two close a loop.
        let (mut a, mut b) = (v, u);
        let (mut from_v, mut from_u) = (Vec::new(), Vec::new());
        while depth[a] > depth[b] {
            from_v.push((up_edge[a], a, up_node[a]));
            a = up_node[a];
        }
        while depth[b] > depth[a] {
            from_u.push((up_edge[b], b, up_node[b]));
            b = up_node[b];
        }
        while a != b {
            from_v.push((up_edge[a], a, up_node[a]));
            a = up_node[a];
            from_u.push((up_edge[b], b, up_node[b]));
            b = up_node[b];
        }

        let mut steps = vec![(i, u, v)];
        steps.extend(from_v);
        steps.extend(from_u.into_iter().rev().map(|(f, x, y)| (f, y, x)));

        // ⛔ THE SIGN IS THE DIRECTION OF TRAVEL AGAINST THE EDGE'S OWN, and getting it wrong is
        //    caught below rather than reasoned about: a vector with a sign error has a non-zero
        //    net somewhere and is not in the cycle space at all.
        let mut net: BTreeMap<usize, f64> = BTreeMap::new();
        for &(f, from, _) in &steps {
            let sign = if index[edges[f].parent.as_str()] == from { 1.0 } else { -1.0 };
            *net.entry(index[edges[f].parent.as_str()]).or_default() -= sign;
            *net.entry(index[edges[f].child.as_str()]).or_default() += sign;
            cycle_id.push(basis);
            cycle_edge.push(f as u32);
            cycle_sign.push(sign);
            assert!(
                f == i || in_forest[f],
                "a fundamental cycle reached a second chord, so the chord-indexed rows are not \
                 the identity and the basis is not independent by construction"
            );
        }
        assert!(
            net.values().all(|x| x.abs() < 1e-9),
            "cycle {basis} has a non-zero net at some node, so it is not in the cycle space"
        );
        *lengths.entry(steps.len()).or_default() += 1;
        basis += 1;
    }

    assert_eq!(
        basis as usize, cycle,
        "the forest rejected {basis} edges where m - n + c says {cycle}: a spanning forest's \
         chords are the cycle space's dimension, counted rather than derived"
    );
    assert_eq!(
        in_forest.iter().filter(|x| **x).count(),
        rank_l,
        "the forest accepted a number of edges that is not rank(L) = n - c"
    );

    println!("\n5. a basis for the cycle space: {basis} fundamental cycles");
    print!("   lengths ");
    for (len, count) in &lengths {
        print!("{len}:{count} ");
    }
    println!();

    // ------------------------------------------------------------------
    // 6. Every edge vector splits into a gradient and a circulation.
    //
    // ⭐⭐⭐ A VANISHING CIRCULATION MEANS A POTENTIAL EXISTS: one number per template whose
    //    differences ARE the filed edge weights. That is exactly what
    //    `checks/conversion_cycle_does_not_close` asks of the unit graph, where the potential is
    //    an absolute log-size per unit. The circulation is the part no per-template number can
    //    account for, and it is a fact about PAIRS rather than about endpoints.
    //
    // ⭐ The split is orthogonal, so the two pieces' squares add to the whole's. That is one
    //    identity with two sides and it is asserted rather than described.
    // ------------------------------------------------------------------
    let mut pinned: BTreeMap<usize, usize> = BTreeMap::new();
    for (i, &k) in class.iter().enumerate() {
        pinned.entry(k).or_insert(i);
    }
    let pinned: Vec<usize> = pinned.into_values().collect();

    // `class` carries a component's ROOT NODE, which is an index into the nodes and not a slot in
    // a vector of length `c`. Everything below totals per component, so it needs the dense form.
    let slot: BTreeMap<usize, usize> = {
        let mut roots: Vec<usize> = class.iter().copied().collect();
        roots.sort_unstable();
        roots.dedup();
        roots.into_iter().enumerate().map(|(i, r)| (r, i)).collect()
    };
    assert_eq!(slot.len(), c, "the dense component index disagrees with the component count");

    let mut per_node: Vec<(String, Vec<f64>)> = Vec::new();
    let mut per_edge: Vec<(String, Vec<f64>)> = Vec::new();

    println!("\n6. every edge vector as a gradient plus a circulation");
    for (what, w) in [
        ("ones", edges.iter().map(|_| 1.0).collect::<Vec<f64>>()),
        ("splices", edges.iter().map(|e| e.splices as f64).collect()),
        (
            "inner_joins",
            edges
                .iter()
                .map(|e| emitted[&(e.parent.clone(), e.child.clone())].1 as f64)
                .collect(),
        ),
    ] {
        // Bᵀw: a signed fold of the edge vector onto the nodes, which is the net at each node.
        let mut rhs = vec![0.0_f64; n];
        for (i, e) in edges.iter().enumerate() {
            rhs[index[e.parent.as_str()]] -= w[i];
            rhs[index[e.child.as_str()]] += w[i];
        }

        // ⭐⭐ A DIVERGENCE SUMS TO ZERO ON EVERY COMPONENT, AND IT IS FREE TO SAY SO HERE.
        //    Every row of `B` holds one −1 and one +1, so `B` sends the all-ones vector to zero
        //    and `1ᵀBᵀw = (B1)ᵀw = 0` on each component separately. That is what makes the node
        //    space split into the divergences a flow can produce and the constants no flow can:
        //    a node vector whose component totals are not zero is reachable by no edge vector at
        //    all. `src/proofs/README.md`, entry `elimination_leaves`, is where that is proved and
        //    what it is for.
        let mut net = vec![0.0_f64; c];
        for (i, v) in rhs.iter().enumerate() {
            net[slot[&class[i]]] += v;
        }
        assert!(
            net.iter().all(|t| t.abs() < 1e-9),
            "{what}: Bᵀw has a non-zero total on some component, so it is the divergence of no \
             flow and the split below is being asked of the wrong kind of vector"
        );

        let p = solve(dense.clone(), rhs, &pinned);
        let grad: Vec<f64> = edges
            .iter()
            .map(|e| p[index[e.child.as_str()]] - p[index[e.parent.as_str()]])
            .collect();
        let circ: Vec<f64> = (0..m).map(|i| w[i] - grad[i]).collect();

        let sq = |v: &[f64]| v.iter().map(|x| x * x).sum::<f64>();
        assert!(
            (sq(&w) - sq(&grad) - sq(&circ)).abs() < 1e-6 * sq(&w).max(1.0),
            "{what}: the gradient and the circulation are orthogonal complements, so their \
             squares must add to the vector's"
        );
        assert!(
            grad.iter().zip(&circ).map(|(a, b)| a * b).sum::<f64>().abs() < 1e-6 * sq(&w).max(1.0),
            "{what}: a gradient and a circulation are orthogonal"
        );

        // ⛔ A CIRCULATION IS DIVERGENCE-FREE, WHICH IS THE OTHER HALF OF THE SAME STATEMENT.
        //    Bᵀ circ = 0 says the net at every node is zero, so nothing in it is explained by
        //    any potential whatsoever.
        let mut net = vec![0.0_f64; n];
        for (i, e) in edges.iter().enumerate() {
            net[index[e.parent.as_str()]] -= circ[i];
            net[index[e.child.as_str()]] += circ[i];
        }
        assert!(
            net.iter().all(|x| x.abs() < 1e-6),
            "{what}: the circulation must have zero net at every node, or it is not in the \
             cycle space"
        );

        let (gs, cs) = (sq(&grad), sq(&circ));
        println!(
            "   {what:<12} gradient {gs:>10.2}   circulation {cs:>10.2}   of {:>10.2}",
            sq(&w)
        );

        per_node.push((format!("potential_{what}"), p));
        per_edge.push((what.to_string(), w.clone()));
        per_edge.push((format!("{what}_gradient"), grad.clone()));
        per_edge.push((format!("{what}_circulation"), circ.clone()));

        if cs < 1e-9 {
            println!("   {:<12} a potential EXISTS: one number per template explains it", "");
        } else {
            let mut worst: Vec<(f64, &Edge)> =
                circ.iter().copied().zip(edges.iter()).map(|(v, e)| (v.abs(), e)).collect();
            worst.sort_by(|a, b| b.0.partial_cmp(&a.0).expect("finite"));
            for (v, e) in worst.iter().take(3) {
                println!("   {:<12} {v:>6.3}  {} -> {}", "", e.parent, e.child);
            }
        }
    }

    // ------------------------------------------------------------------
    // 6b. And the NODE space splits too, which is the half nothing here had ever written out.
    //
    // ⭐⭐⭐ EVERY SPLIT ABOVE IS OF AN EDGE VECTOR. The node space has its own, into the ROW
    //    space of `B`, which is every divergence some flow produces, and the NULLSPACE, which is
    //    the constants, one per component. They are orthogonal complements exactly as the cut
    //    and cycle spaces are, and the constants part of a node vector is the part no
    //    redistribution along the edges can ever account for.
    //
    // ⚠️ The gauge above is a PIN and this is a PROJECTION, and they are different acts. Pinning
    //    a node picks one representative out of the coset; projecting measures how far the vector
    //    is from the subspace. A potential is only ever defined up to the pin, so it has no
    //    constants part worth reporting; a vector that arrives from outside, like the degree, has
    //    one and it is a number about the vector rather than about the choice.
    // ------------------------------------------------------------------
    let mut degree = vec![0_u32; n];
    for e in &edges {
        degree[index[e.parent.as_str()]] += 1;
        degree[index[e.child.as_str()]] += 1;
    }

    let mut size = vec![0.0_f64; c];
    let mut total = vec![0.0_f64; c];
    for (i, d) in degree.iter().enumerate() {
        size[slot[&class[i]]] += 1.0;
        total[slot[&class[i]]] += f64::from(*d);
    }
    let constant: Vec<f64> = (0..n).map(|i| total[slot[&class[i]]] / size[slot[&class[i]]]).collect();
    let deviation: Vec<f64> = (0..n).map(|i| f64::from(degree[i]) - constant[i]).collect();

    let sqn = |v: &[f64]| v.iter().map(|x| x * x).sum::<f64>();
    let whole: Vec<f64> = degree.iter().map(|d| f64::from(*d)).collect();
    assert!(
        (sqn(&whole) - sqn(&constant) - sqn(&deviation)).abs() < 1e-6 * sqn(&whole).max(1.0),
        "the constants and the deviation are orthogonal complements in the node space, so their \
         squares must add to the vector's"
    );
    assert!(
        constant.iter().zip(&deviation).map(|(a, b)| a * b).sum::<f64>().abs()
            < 1e-6 * sqn(&whole).max(1.0),
        "a constant per component and a vector summing to zero on each are orthogonal"
    );
    // ⛔ THE DEVIATION IS A DIVERGENCE AND THE CONSTANT IS NOT, WHICH IS THE WHOLE POINT. The
    //    handshake `Σ degree = 2m` puts the constants part strictly above zero on any graph with
    //    an edge, so the degree vector is reachable by no flow: it is a fact about the nodes
    //    rather than about anything moving along the edges. An elimination sits in exactly that
    //    position, which is why it is subtracted rather than carried.
    let mut residual = vec![0.0_f64; c];
    for (i, v) in deviation.iter().enumerate() {
        residual[slot[&class[i]]] += v;
    }
    assert!(
        residual.iter().all(|t| t.abs() < 1e-9),
        "the deviation has a non-zero total on some component, so it is not in the row space"
    );
    assert!(
        constant.iter().any(|&x| x > 0.0),
        "every component's degree total is zero, so the graph has no edges and the split is \
         about nothing"
    );
    println!(
        "\n6b. the node space splits too: degree {:>10.2} = constants {:>10.2} + deviation {:>10.2}",
        sqn(&whole),
        sqn(&constant),
        sqn(&deviation)
    );
    println!(
        "   {:<12} the constants part is non-zero, so no edge vector has the degree as its net",
        ""
    );
    per_node.push(("degree_constant".to_string(), constant));
    per_node.push(("degree_deviation".to_string(), deviation));

    // ------------------------------------------------------------------
    // 7. Every subspace written where somebody who does not run Rust can open it.
    //
    // ⚠️ ARROW IPC BECAUSE NEITHER AUDIENCE RUNS RUST. `pl.read_ipc` in Python,
    //    `arrow::read_ipc_file` in R, no conversion step and no code from here. `assets/bpmn/`
    //    and `assets/svg/` are the same arrangement: generated, and tracked because the
    //    published surface is GitHub rather than a local build.
    //
    // ⭐⭐ FIVE RELATIONS, NOT TWO MATRICES, AND EVERY ONE OF THEM IS A COORDINATE FORM. The
    //    incidence is `B`, the Laplacian is `BᵀB`, `cycles` is a basis of the cycle space, and
    //    the two rosters carry what a potential assigns to a node and what the split leaves on
    //    an edge. They join on `node` and `edge`, which is what makes the subspaces composable
    //    outside this program rather than only inside it.
    // ------------------------------------------------------------------
    let dir = Path::new(env!("CARGO_MANIFEST_DIR")).join("assets/arrow");
    std::fs::create_dir_all(&dir)?;

    let mut roster = df![
        "node" => (0..n as u32).collect::<Vec<u32>>(),
        "component" => class.iter().map(|k| *k as u32).collect::<Vec<u32>>(),
        "degree" => degree,
    ]?;
    roster.with_column(
        Series::new("template".into(), nodes.iter().map(String::as_str).collect::<Vec<_>>()).into(),
    )?;
    for (name, values) in &per_node {
        roster.with_column(Series::new(name.as_str().into(), values.clone()).into())?;
    }

    let mut edge_roster = df![
        "edge" => (0..m as u32).collect::<Vec<u32>>(),
        "in_forest" => in_forest.clone(),
    ]?;
    for (name, values) in [
        ("parent", edges.iter().map(|e| e.parent.as_str()).collect::<Vec<_>>()),
        ("child", edges.iter().map(|e| e.child.as_str()).collect::<Vec<_>>()),
    ] {
        edge_roster.with_column(Series::new(name.into(), values).into())?;
    }
    for (name, values) in &per_edge {
        edge_roster.with_column(Series::new(name.as_str().into(), values.clone()).into())?;
    }

    let mut cycles = df![
        "cycle" => cycle_id,
        "edge" => cycle_edge,
        "sign" => cycle_sign,
    ]?;

    // ⚠️ TWO FORMATS, AND THE SECOND IS NOT A PREFERENCE. Arrow IPC is what a reader already
    //    holding polars or the R arrow package opens with no conversion, which is the audience
    //    this directory exists for. Parquet is what a reader holding NOTHING opens: `duckdb` reads
    //    it out of the box and reads Arrow IPC only with an extension installed first. Writing
    //    both costs one line each because `parquet` is already in the feature list, forced there
    //    by an upstream gating bug, so the code is compiled in whether or not it is called.
    for (stem, frame) in [
        ("incidence", &mut incidence.clone()),
        ("laplacian", &mut laplacian.clone()),
        ("templates", &mut roster),
        ("edges", &mut edge_roster),
        ("cycles", &mut cycles),
    ] {
        IpcWriter::new(std::fs::File::create(dir.join(format!("{stem}.arrow")))?).finish(frame)?;
        ParquetWriter::new(std::fs::File::create(dir.join(format!("{stem}.parquet")))?)
            .finish(frame)?;
    }
    println!("\n7. wrote assets/arrow/, as .arrow and .parquet: incidence, laplacian, templates,");
    println!("   edges, cycles");

    // ------------------------------------------------------------------
    // 8. Population floors, so that nothing above can pass by having nothing to check.
    // ------------------------------------------------------------------
    assert!(
        cycle > 0,
        "the compose graph has no chords, so every statement here about a cycle space is about \
         an empty subspace and demonstrates nothing"
    );
    assert!(
        edges.iter().any(|e| e.splices > 1),
        "no parent composes a child twice, so `splices` is the all-ones vector and the claim \
         that multiplicity is free here has nothing to be free about"
    );
    assert!(
        emitted.values().any(|(_, j)| *j > 0),
        "no compose edge reads as an inner join, so the second edge vector is zero"
    );

    println!("\nAll checks passed.");
    Ok(())
}
