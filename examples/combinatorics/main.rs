// This program's header is `README.md` beside it, and there is one copy of it. GitHub renders a
// directory's README and no `//!` block, so a header kept only in the source cannot be read where
// the repository is published. `include_str!` makes the same file rustdoc's page, so the two
// renderings cannot disagree, and a missing header is a compile error rather than a blank row.
//
// Both languages are included, as in the schemas: an `xs:annotation` holds an `xml:lang="en"`
// block and an `xml:lang="pt"` block, and the generated Rust carries both in one doc comment.
// These two files are the same arrangement for a program, so the Portuguese page is rendered
// wherever the English one is, as `tests/translation.rs` requires.
#![doc = include_str!("README.md")]
#![doc = include_str!("../../pt-PT/examples/combinatorics/README.md")]

use std::collections::{BTreeMap, BTreeSet};
use std::path::Path;

// `shared/` holds no `main.rs` on purpose, which is how cargo decides it is not an example, and
// `#[path]` is how a target reaches into it.
#[path = "../shared/tree/mod.rs"]
mod tree;
use tree::templates;

// ----------------------------------------------------------------------
// Balls into boxes, as data: three conditions on where the balls may land, four ways to read it.
// ----------------------------------------------------------------------

#[derive(Clone, Copy, PartialEq)]
enum Condition {
    Any,
    Injective,
    Surjective,
}

#[derive(Clone, Copy, PartialEq)]
enum Reading {
    /// Where each ball landed: the rows.
    Labelled,
    /// Which balls they are is ignored: how many land in each named box, a
    /// `GROUP BY … count(*)`.
    FibreSizes,
    /// Which boxes they are is ignored: which balls share a box, a self-join on the box.
    Kernel,
    /// Both are ignored: how many boxes hold one ball, how many hold two and so on, a `GROUP BY`
    /// over a `GROUP BY`.
    Shape,
}

const CONDITIONS: [(Condition, &str); 3] = [
    (Condition::Any, "any"),
    (Condition::Injective, "at most one per box"),
    (Condition::Surjective, "no box empty"),
];

const READINGS: [(Reading, &str, &str); 4] = [
    (Reading::Labelled, "labelled", "the rows"),
    (Reading::FibreSizes, "up to the balls", "GROUP BY box, count(*)"),
    (Reading::Kernel, "up to the boxes", "self-join on the box"),
    (Reading::Shape, "up to both", "the profile of the counts"),
];

/// How many ways there are to choose `b` things out of `a`. Choosing none is one way whatever
/// `a` is, which keeps the `surjective` column right with no balls and no boxes.
fn binom(a: i64, b: i64) -> i64 {
    if b < 0 {
        return 0;
    }
    if b == 0 {
        return 1;
    }
    if a < b {
        return 0;
    }
    (0..b).fold(1, |acc, i| acc * (a - i) / (i + 1))
}

/// How many ways `n` balls split into exactly `k` groups, none empty and the groups unnamed. No
/// balls in no groups is one way.
fn stirling(n: usize, k: usize) -> i64 {
    let mut s = vec![vec![0i64; k.max(n) + 1]; n + 1];
    s[0][0] = 1;
    for i in 1..=n {
        for j in 1..=k.max(n) {
            s[i][j] = j as i64 * s[i - 1][j] + s[i - 1][j - 1];
        }
    }
    s[n][k]
}

/// How many ways the whole number `m` splits into exactly `k` whole parts, none zero and their
/// order ignored. Zero in no parts is one way.
fn parts(m: usize, k: usize) -> i64 {
    let mut p = vec![vec![0i64; k + 1]; m + 1];
    p[0][0] = 1;
    for i in 1..=m {
        for j in 1..=k.min(i) {
            p[i][j] = p[i - 1][j - 1] + p[i - j][j];
        }
    }
    p[m][k]
}

/// The count for one cell of the table, by formula. The first of three ways to the same count.
fn formula(c: Condition, r: Reading, n: usize, x: usize) -> i64 {
    let (ni, xi) = (n as i64, x as i64);
    let at_most = i64::from(n <= x);
    match (r, c) {
        (Reading::Labelled, Condition::Any) => xi.pow(n as u32),
        (Reading::Labelled, Condition::Injective) => (0..ni).map(|i| xi - i).product(),
        (Reading::Labelled, Condition::Surjective) => (1..=xi).product::<i64>() * stirling(n, x),
        (Reading::FibreSizes, Condition::Any) => binom(xi + ni - 1, ni),
        (Reading::FibreSizes, Condition::Injective) => binom(xi, ni),
        (Reading::FibreSizes, Condition::Surjective) => binom(ni - 1, ni - xi),
        (Reading::Kernel, Condition::Any) => (0..=x).map(|k| stirling(n, k)).sum(),
        (Reading::Kernel, Condition::Injective) => at_most,
        (Reading::Kernel, Condition::Surjective) => stirling(n, x),
        (Reading::Shape, Condition::Any) => parts(n + x, x),
        (Reading::Shape, Condition::Injective) => at_most,
        (Reading::Shape, Condition::Surjective) => parts(n, x),
    }
}

/// Every way `n` balls can land in `x` boxes, each as the list of the box each ball lands in. With
/// no balls there is exactly one.
fn functions(n: usize, x: usize) -> Vec<Vec<usize>> {
    let mut out = vec![Vec::new()];
    for _ in 0..n {
        out = out
            .into_iter()
            .flat_map(|f| {
                (0..x).map(move |v| {
                    let mut g = f.clone();
                    g.push(v);
                    g
                })
            })
            .collect();
    }
    out
}

fn permutations(m: usize) -> Vec<Vec<usize>> {
    if m == 0 {
        return vec![Vec::new()];
    }
    let mut out = Vec::new();
    for p in permutations(m - 1) {
        for at in 0..=p.len() {
            let mut q = p.clone();
            q.insert(at, m - 1);
            out.push(q);
        }
    }
    out
}

fn holds(c: Condition, f: &[usize], x: usize) -> bool {
    let image: BTreeSet<usize> = f.iter().copied().collect();
    match c {
        Condition::Any => true,
        Condition::Injective => image.len() == f.len(),
        Condition::Surjective => image.len() == x,
    }
}

/// The reading itself, computed the way the SQL computes it. The second of the three ways.
fn read(r: Reading, f: &[usize], x: usize) -> Vec<usize> {
    let mut fibres = vec![0usize; x];
    for &v in f {
        fibres[v] += 1;
    }
    match r {
        Reading::Labelled => f.to_vec(),
        Reading::FibreSizes => fibres,
        // Each group is named by its least ball, which is what `min(…) OVER (PARTITION BY box)`
        // does: the boxes' own names are dropped, and nothing that renaming them changes is kept.
        Reading::Kernel => {
            let mut first: BTreeMap<usize, usize> = BTreeMap::new();
            f.iter()
                .enumerate()
                .map(|(ball, &b)| *first.entry(b).or_insert(ball))
                .collect()
        }
        Reading::Shape => {
            let mut s: Vec<usize> = fibres.into_iter().filter(|&k| k > 0).collect();
            s.sort_unstable();
            s
        }
    }
}

/// By brute force: reorder the balls, the boxes or both, as far as the reading ignores them, and
/// keep the least result. The third of the three ways, and it knows nothing about counts per box,
/// shared boxes or profiles.
fn orbit(r: Reading, f: &[usize], balls: &[Vec<usize>], boxes: &[Vec<usize>]) -> Vec<usize> {
    let identity_n = vec![(0..f.len()).collect::<Vec<_>>()];
    let identity_x = vec![(0..boxes.first().map_or(0, Vec::len)).collect::<Vec<_>>()];
    let (sigmas, taus): (&[Vec<usize>], &[Vec<usize>]) = match r {
        Reading::Labelled => (&identity_n, &identity_x),
        Reading::FibreSizes => (balls, &identity_x),
        Reading::Kernel => (&identity_n, boxes),
        Reading::Shape => (balls, boxes),
    };
    let mut least: Option<Vec<usize>> = None;
    for s in sigmas.iter() {
        for t in taus.iter() {
            // Move the balls by one reordering and rename the boxes by the other.
            let g: Vec<usize> = (0..f.len()).map(|i| t.get(f[s[i]]).copied().unwrap_or(f[s[i]])).collect();
            if least.as_ref().is_none_or(|l| g < *l) {
                least = Some(g);
            }
        }
    }
    least.expect("the group has an identity")
}

#[path = "../shared/database/mod.rs"]
mod database;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example reads the classifications the model's queries make, \
         and it cannot do that without the rows. Load them with assets/ddl/schema.ddl and ingest.sql."
    })?;
    let pool = database::connect(&url).await?;

    // ------------------------------------------------------------------
    // 1. The table itself, three ways, before anything in this repository is read by it.
    // ------------------------------------------------------------------
    // The second way against the third is what everything below rests on. A reading is computed
    // the way the SQL computes it; the brute force reorders whatever the reading is meant to
    // ignore. Two assignments the brute force finds the same must read the same, and two it tells
    // apart must read differently. Both are asserted for each assignment rather than for each
    // count, because two groupings with the same number of groups are not the same grouping.
    const UPTO: usize = 4;
    let mut cells = 0usize;
    for n in 0..=UPTO {
        let balls = permutations(n);
        for x in 0..=UPTO {
            let boxes = permutations(x);
            let all = functions(n, x);
            for &(c, cname) in &CONDITIONS {
                for &(r, rname, _) in &READINGS {
                    let mut by_orbit: BTreeMap<Vec<usize>, Vec<usize>> = BTreeMap::new();
                    let mut by_reading: BTreeMap<Vec<usize>, Vec<usize>> = BTreeMap::new();
                    for f in all.iter().filter(|f| holds(c, f, x)) {
                        let (o, v) = (orbit(r, f, &balls, &boxes), read(r, f, x));
                        let seen = by_orbit.entry(o.clone()).or_insert_with(|| v.clone());
                        assert_eq!(
                            *seen, v,
                            "n={n} x={x} {cname} {rname}: two assignments alike read \
                             differently, so this reading keeps something it should ignore"
                        );
                        let back = by_reading.entry(v).or_insert_with(|| o.clone());
                        assert_eq!(
                            *back, o,
                            "n={n} x={x} {cname} {rname}: two different assignments read the \
                             same, so this reading ignores something it should keep"
                        );
                    }
                    let want = formula(c, r, n, x);
                    assert_eq!(
                        by_orbit.len() as i64,
                        want,
                        "n={n} x={x} {cname} {rname}: {} by brute force, {want} by formula",
                        by_orbit.len()
                    );
                    cells += 1;
                }
            }
        }
    }
    let (n, x) = (4usize, 3usize);
    println!("1. every way to count balls into boxes, for {n} balls and {x} boxes\n");
    println!("   {:<17} {:<27} {:>6} {:>12} {:>12}", "", "in SQL", "any", "at most 1", "no empty");
    for &(r, rname, sql) in &READINGS {
        println!(
            "   {:<17} {:<27} {:>6} {:>12} {:>12}",
            rname,
            sql,
            formula(Condition::Any, r, n, x),
            formula(Condition::Injective, r, n, x),
            formula(Condition::Surjective, r, n, x)
        );
    }
    println!(
        "\n   {cells} cells, every count from 0 to {UPTO}: the formula, the number of distinct \
         readings and the\n   number found by brute force agree, and each reading keeps exactly \
         what the brute force keeps."
    );
    println!("   So a GROUP BY count ignores which balls, a self-join ignores which boxes,");
    println!("      and neither can see what the other throws away.");

    // ------------------------------------------------------------------
    // 2. The compositions, read the four ways: splice site -> template.
    // ------------------------------------------------------------------
    let edges = sqlx::query_file!("assets/sql/queries/combinatorics/2-compositions.sql")
        .fetch_all(&pool)
        .await?;
    let mut on_disk = Vec::new();
    templates(Path::new("assets/sqlc"), Path::new("assets/sqlc"), &mut on_disk);
    let on_disk: BTreeSet<String> = on_disk.into_iter().map(|(n, _)| n).collect();

    let mut fibre: BTreeMap<&str, i64> = BTreeMap::new();
    let mut children_of: BTreeMap<&str, BTreeSet<&str>> = BTreeMap::new();
    for e in &edges {
        *fibre.entry(e.child.as_str()).or_default() += e.splices;
        children_of.entry(e.parent.as_str()).or_default().insert(e.child.as_str());
    }
    let sites: i64 = edges.iter().map(|e| e.splices).sum();
    let repeated = edges.iter().filter(|e| e.splices > 1).count();
    let roots = on_disk.iter().filter(|t| !fibre.contains_key(t.as_str())).count();
    let mut shape: BTreeMap<i64, usize> = BTreeMap::new();
    for k in fibre.values() {
        *shape.entry(*k).or_default() += 1;
    }
    let mut kernel: BTreeMap<&BTreeSet<&str>, Vec<&str>> = BTreeMap::new();
    for (p, cs) in &children_of {
        kernel.entry(cs).or_default().push(*p);
    }
    let shared = kernel.values().filter(|ps| ps.len() > 1).count();
    let mut widest: Vec<(&str, i64)> = fibre.iter().map(|(c, k)| (*c, *k)).collect();
    widest.sort_by(|a, b| b.1.cmp(&a.1).then(a.0.cmp(b.0)));

    println!("\n2. the compositions, as balls into boxes: every splice site, the template it lands in");
    println!("   labelled         {} edges carrying {sites} splice sites", edges.len());
    println!(
        "   up to the balls  {} templates receive a splice; the widest: {}",
        fibre.len(),
        widest.iter().take(3).map(|(c, k)| format!("{c} {k}")).collect::<Vec<_>>().join(", ")
    );
    println!("                    {roots} of {} templates on disk receive none, seen only by driving from the directory", on_disk.len());
    println!("   up to the boxes  {shared} groups of parents compose an identical set of children");
    println!(
        "   up to both       {}",
        shape.iter().map(|(k, t)| format!("{t} of {k}")).collect::<Vec<_>>().join(", ")
    );
    println!("   spliced twice    {repeated} edges splice one child more than once, harmlessly:");
    println!("      a query's copies agree in a union, a join or a scalar subquery,");
    println!("      and a tagged UNION ALL keeps them apart. A supply is folded with +, and is not.");
    // The counts per template and their profile are two summaries of the same rows, so they must
    // cover the same splice sites. A step here that lost an edge would print a plausible profile
    // over fewer sites.
    let from_shape: i64 = shape.iter().map(|(k, t)| k * *t as i64).sum();
    assert!(!edges.is_empty(), "no template composes another, so this section read nothing");
    assert_eq!(from_shape, sites, "the shape does not sum to the splice sites it was read from");

    // ------------------------------------------------------------------
    // 3. Every classification, against the classes it declares.
    // ------------------------------------------------------------------
    let classes = sqlx::query_file!("assets/sql/queries/combinatorics/3-classifications.sql")
        .fetch_all(&pool)
        .await?;
    // The declared class sets are read by the catalog's bare name, not `regtype`. `regtype`
    // renders through the session's `search_path`, so it spells the same type two ways depending
    // on who is connected, and the census it is compared with is read by clients on both paths.
    // `typname` is what assets/ddl/schema.ddl wrote, and `epistemics/class_cells.sqlc` reads the
    // same column.
    let declared: Vec<String> = sqlx::query_scalar(
        "SELECT t.typname::text FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace \
         WHERE n.nspname = 'public' AND t.typtype = 'e' ORDER BY 1",
    )
    .fetch_all(&pool)
    .await?;
    let mut by_relation: BTreeMap<&str, Vec<(&str, &str, i64)>> = BTreeMap::new();
    for c in &classes {
        by_relation
            .entry(c.relation.as_str())
            .or_default()
            .push((c.codomain.as_str(), c.class.as_str(), c.balls));
    }
    println!("\n3. every classification, against the classes it declares");
    let mut empties = Vec::new();
    for (relation, rows) in &by_relation {
        let codomains: BTreeSet<&str> = rows.iter().map(|r| r.0).collect();
        assert_eq!(
            codomains.len(),
            1,
            "{relation} sorts into classes of more than one type, so it is not one classification"
        );
        let total: i64 = rows.iter().map(|r| r.2).sum();
        println!("   {relation}  ({} rows into {})", total, rows[0].0);
        for (_, class, balls) in rows {
            println!("      {class:<32} {balls:>4}");
            if *balls == 0 {
                empties.push(format!("{relation}: {class}"));
            }
        }
    }
    let reached: BTreeSet<&str> = classes.iter().map(|c| c.codomain.as_str()).collect();
    let unread: Vec<&String> = declared.iter().filter(|d| !reached.contains(d.as_str())).collect();
    assert!(!declared.is_empty(), "schema public declares no class set, so this law examined nothing");
    assert!(
        unread.is_empty(),
        "a class set is declared in schema.ddl and no classification here reads it, so nobody can \
         see which of its classes are empty: {unread:?}"
    );
    println!("\n   empty, and a referral rather than a failure:");
    for e in &empties {
        println!("      {e}");
    }

    // ------------------------------------------------------------------
    // 3b. The same classes over each scope, which the pooled count cannot be filtered into.
    // A census counts, so the set of documents it counted over is part of its result rather than
    // an input a reader still holds. Restricting §3's rows chooses which totals to look at, never
    // what each total counted, which is why `reports/class_census.sqlc` takes the document set as
    // a slot and is composed twice, and why these two columns exist instead of a WHERE clause.
    //
    // The two zeros mean opposite things. Empty in the corpus is a state no real filing has
    // produced, which is a finding about the evidence. Empty in the fixtures is a state no
    // stipulation exercises, which is a gap in this repository's own coverage. Pooled, a class
    // lit from either side answers neither question.
    // ------------------------------------------------------------------
    let scoped = sqlx::query_file!("assets/sql/queries/combinatorics/3b-classifications-by-scope.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n3b. the filed classifications, counted apart");
    println!("   {:<44} {:>8} {:>10}", "relation / class", "corpus", "fixtures");
    let mut findings = Vec::new();
    let mut gaps = Vec::new();
    for r in &scoped {
        let corpus = r.corpus;
        let fixtures = r.fixtures.unwrap_or(0);
        let cell = format!("{} {}", r.relation, r.class);
        println!("   {cell:<44} {corpus:>8} {fixtures:>10}");
        if corpus == 0 && fixtures > 0 {
            findings.push(cell.clone());
        }
        if fixtures == 0 && corpus > 0 {
            gaps.push(cell);
        }
    }
    assert!(!scoped.is_empty(), "the scoped census is empty, so this section read nothing");
    // Neither list is asserted empty, and neither should be. A finding is a claim about the world
    // that no law can settle, and a gap is a fixture somebody has not written yet.
    // `algebra/class_domain.sqlc` asserts the part that can be settled: that every class has a
    // declared standing, and the standing agrees with the pooled count.
    println!("\n   lit only by a stipulation, so the corpus has never shown it:");
    for f in &findings {
        println!("      {f}");
    }
    println!("\n   lit only by the corpus, so no fixture pins it:");
    for g in &gaps {
        println!("      {g}");
    }

    // ------------------------------------------------------------------
    // 4. The absence census, one question at a time, counted against its own column.
    // ------------------------------------------------------------------
    let census = sqlx::query_file!("assets/sql/queries/combinatorics/4-census.sql")
        .fetch_all(&pool)
        .await?;
    let filed = sqlx::query_file!("assets/sql/queries/combinatorics/4b-census-questions.sql")
        .fetch_all(&pool)
        .await?;
    let questions: BTreeSet<&str> = census.iter().map(|c| c.question.as_str()).collect();
    let columns: BTreeSet<(&str, &str)> =
        census.iter().map(|c| (c.table_name.as_str(), c.column_name.as_str())).collect();
    assert!(!census.is_empty(), "the census roster is empty, so this law examined nothing");
    assert_eq!(questions.len(), census.len(), "one question is on the roster twice");
    assert_eq!(columns.len(), census.len(), "two questions claim to read one column");
    let undeclared: Vec<&str> = filed
        .iter()
        .map(|f| f.question.as_str())
        .filter(|q| !questions.contains(q))
        .collect();
    assert!(
        undeclared.is_empty(),
        "the census files rows under a question epistemics/absence_questions.sqlc does not name, so \
         they count toward no column: {undeclared:?}"
    );

    let mut wrong = Vec::new();
    let mut empty = Vec::new();
    for c in &census {
        // This count shares nothing with the arm it checks. Postgres quotes both identifiers
        // itself, they come from a roster `reports/integrity.sqlc` holds against the catalog,
        // and the statement only counts. `AssertSqlSafe` is the audit sqlx asks for.
        let sql: String =
            sqlx::query_scalar("SELECT format('SELECT count(*) FROM pm.%I WHERE %I IS NOT NULL', $1, $2)")
                .bind(c.table_name.as_str())
                .bind(c.column_name.as_str())
                .fetch_one(&pool)
                .await?;
        let in_column: i64 = sqlx::query_scalar(sqlx::AssertSqlSafe(sql)).fetch_one(&pool).await?;
        if in_column != c.census {
            wrong.push(format!(
                "{}: {} in the census, {} in {}.{}",
                c.question, c.census, in_column, c.table_name, c.column_name
            ));
        } else if in_column == 0 {
            empty.push(c.question.as_str());
        }
    }
    println!("\n4. the absence census, each question against the column it claims to read");
    println!(
        "   {} questions, {} columns, {} agree with rows to count",
        census.len(),
        columns.len(),
        census.len() - wrong.len() - empty.len()
    );
    println!("   nothing filed, so zero against zero and no evidence either way: {}", empty.join(", "));
    assert!(
        wrong.is_empty(),
        "an arm of epistemics/absences.sqlc does not read the column its question names: {wrong:#?}"
    );

    // ------------------------------------------------------------------
    // 5. The two self-joins of the parts, against the group sizes that fix how many rows return.
    // ------------------------------------------------------------------
    let kernels = sqlx::query_file!("assets/sql/queries/combinatorics/5-kernels.sql")
        .fetch_all(&pool)
        .await?;
    let mut per: BTreeMap<&str, (&str, i64, Vec<(i64, i64)>)> = BTreeMap::new();
    for k in &kernels {
        per.entry(k.relation.as_str())
            .or_insert((k.pairing.as_str(), k.joined, Vec::new()))
            .2
            .push((k.k, k.fibres));
    }
    println!("\n5. the two pairings of parts, against the group sizes that fix their row counts");
    assert!(!per.is_empty(), "no self-join was profiled, so this law examined nothing");
    for (relation, (pairing, joined, profile)) in &per {
        let pairs = |k: i64| match *pairing {
            "ordered, reflexive kept" => k * k,
            "ordered, reflexive dropped" => k * (k - 1),
            "unordered, reflexive dropped" => k * (k - 1) / 2,
            other => panic!("{relation} declares a pairing this program has no count for: {other}"),
        };
        let expected: i64 = profile.iter().map(|(k, t)| pairs(*k) * t).sum();
        println!(
            "   {relation:<32} {pairing:<30} groups {}  ->  {expected} expected, {joined} joined",
            profile.iter().map(|(k, t)| format!("{t} of {k}")).collect::<Vec<_>>().join(", ")
        );
        assert_eq!(
            expected, *joined,
            "{relation} returned a number of rows its group sizes do not allow, so its join key \
             or its pairing is not the one its header argues for"
        );
        // Once three composed layers share a part, its pairs no longer measure its double count.
        // A sum over the layers counts the part once more for each layer past the first, while
        // the pairs among those layers grow faster; the two agree only when two layers share it.
        if pairing.starts_with("unordered") && profile.iter().any(|(k, _)| *k >= 3) {
            let excess: i64 = profile.iter().map(|(k, t)| (k - 1) * t).sum();
            println!("      note: a part feeds three totals: {expected} pairs, but a sum would double count {excess}");
        }
    }

    Ok(())
}
