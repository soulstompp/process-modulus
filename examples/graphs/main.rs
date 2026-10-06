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
#![doc = include_str!("../../pt-PT/examples/graphs/README.md")]

use std::collections::BTreeMap;
use std::fmt::Write as _;
use std::fs;

/// This program owns this directory, and creates it. Writing into `assets/bpmn/` beside
/// `examples/diagramming/main.rs`, which wipes what it owns, would leave these documents
/// surviving only when that example ran first, and this one depending on the other having run at
/// all.
const OUT: &str = "assets/bpmn/graphs";

/// Every row set this program writes out, in a total order that depends only on the rows.
///
/// A tracked generated file must not depend on the plan. Two databases loaded from one corpus by
/// one ingest can return `flowNodeRef` in different orders, and the documents then differ byte for
/// byte while meaning the same thing. `assets/sql/` has `--verify` behind it and these have
/// nothing, so the difference would show only when two machines compared.
///
/// The order is not owed by `assets/sqlc/`. A relation is a set; an `ORDER BY` there is spliced
/// into a subquery at every call site and discarded by the outer query, so it would hold only
/// where the relation happens to be read at the top. Writing a set into a document is where a
/// total order is owed, and that is here.
///
/// Over every column, because a key that is not unique leaves its ties to the planner, which is
/// the same defect one layer down.
fn ordered<T: std::fmt::Debug>(mut v: Vec<T>) -> Vec<T> {
    v.sort_by_cached_key(|r| format!("{r:?}"));
    v
}

fn esc(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}
fn id(prefix: &str, s: &str) -> String {
    let mut o = String::from(prefix);
    o.push('_');
    for c in s.chars() {
        o.push(if c.is_ascii_alphanumeric() || c == '-' || c == '.' { c } else { '_' });
    }
    o
}

#[path = "../shared/database/mod.rs"]
mod database;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL")
        .map_err(|_| "DATABASE_URL is unset, and the graphs are relations.")?;
    let pool = database::connect(&url).await?;

    // The roster is the only place a graph is named. A `VALUES` literal, because derived from the
    // tree it could never report that a declared graph has nothing behind it, and the claimant row
    // is that case.
    let graphs = ordered(sqlx::query_file!("assets/sql/diagrams/graphs.sql").fetch_all(&pool).await?);
    let edges = ordered(sqlx::query_file!("assets/sql/rank/graph_edges.sql").fetch_all(&pool).await?);
    // The nodes are a relation, not a list of endpoints made unique here. Derived here, a node
    // would be a display string with nothing joinable behind it, and the layer graph would draw
    // lanes carrying no fact about a layer except its name. `rank/graph_nodes.sqlc` joins each
    // graph's node facts at their own grain and flattens afterwards, the same concatenation in
    // the order that keeps the key usable.
    let gnodes = ordered(sqlx::query_file!("assets/sql/rank/graph_nodes.sql").fetch_all(&pool).await?);
    let cyc = ordered(sqlx::query_file!("assets/sql/rank/cycle_space.sql").fetch_all(&pool).await?);

    // Which nodes carry a `rank` is a claim, so it is asserted rather than trusted. The join in
    // `rank/graph_nodes.sqlc` is on `(filing, layer)`, and a join that stopped matching would
    // return the same nodes with every `rank` NULL: the node count, the edge count, the measures
    // and the drawing's lane count would all stay right, and the only symptom would be labels
    // quietly missing from a picture nobody diffs. Count the item.
    let (no_rank, wrong_rank): (Vec<_>, Vec<_>) = (
        gnodes.iter().filter(|n| n.graph.as_deref() == Some("layers") && n.rank.is_none())
              .filter_map(|n| n.node.clone()).collect(),
        gnodes.iter().filter(|n| n.graph.as_deref() != Some("layers") && n.rank.is_some())
              .filter_map(|n| n.node.clone()).collect(),
    );
    assert!(
        no_rank.is_empty(),
        "a layer is a node of the layer graph and carries no rank, so its lane will be drawn \
         with no evaluation order while every count stays exact: {no_rank:?}"
    );
    assert!(
        wrong_rank.is_empty(),
        "a node that is not a layer carries a rank. The rank is the deepest a layer sits in the \
         composition, a fact about layers, so this places something with no place in that order: \
         {wrong_rank:?}"
    );
    println!(
        "\n   {} layer-graph nodes, every one with its rank joined at (filing, layer); {} \
         unit nodes, none with a rank, because rank is not a fact about a unit.",
        gnodes.iter().filter(|n| n.graph.as_deref() == Some("layers")).count(),
        gnodes.iter().filter(|n| n.graph.as_deref() == Some("units")).count(),
    );

    println!("The graphs, as lane sets of one pool\n");
    // Wiped, and only this program's own subdirectory. A stale document is a claim about a model
    // that has moved, and wiping a directory another program also writes is how documents vanish:
    // with one parent shared and wiped, these would survive only when this example ran second.
    if std::path::Path::new(OUT).exists() {
        fs::remove_dir_all(OUT)?;
    }
    fs::create_dir_all(OUT)?;

    let mut emitted = 0usize;
    let mut black_boxes: Vec<String> = Vec::new();

    for g in &graphs {
        let name = g.graph.as_deref().unwrap_or("?");
        let mine: Vec<_> = edges.iter().filter(|e| e.graph.as_deref() == Some(name)).collect();
        let mine_nodes: Vec<_> = gnodes.iter().filter(|n| n.graph.as_deref() == Some(name)).collect();
        let rank_of: BTreeMap<&str, i32> = mine_nodes
            .iter()
            .filter_map(|n| Some((n.node.as_deref()?, n.rank?)))
            .collect();
        // What could contradict this node. `rank/layer_reach.sqlc` counts the rules whose
        // population contains the layer, and how many of them said no. A drawing carrying only
        // what was filed is a drawing a reader believes; this is the half that lets them argue
        // with it. On a clean corpus the second number is 0 everywhere, which is why
        // `examples/witnesses/main.rs` has to be run against it before it means anything.
        let cover_of: BTreeMap<&str, (i64, i64)> = mine_nodes
            .iter()
            .filter_map(|n| Some((n.node.as_deref()?, (n.examined_by?, n.violated?))))
            .collect();
        let mut nodes: Vec<&str> = mine_nodes.iter().filter_map(|n| n.node.as_deref()).collect();
        nodes.sort_unstable();
        nodes.dedup();

        let space = cyc.iter().find(|c| c.graph.as_deref().map(|s| s.starts_with(name)) == Some(true));
        println!("  {name}");
        println!("     a node is    {}", g.node_is.as_deref().unwrap_or(""));
        println!("     an edge is   {}", g.edge_is.as_deref().unwrap_or(""));
        println!("     a cycle is   ({}) {}",
                 g.cycle_sense.as_deref().unwrap_or("?"), g.a_cycle_is.as_deref().unwrap_or(""));
        println!("     governed by  {}", g.governed_by.as_deref().unwrap_or("nothing"));
        match space {
            Some(s) => println!(
                "     measured     {} nodes, {} edges, {} pieces, tree edges {}, loops {}",
                s.n_nodes.unwrap_or(0), s.m_edges.unwrap_or(0), s.c_components.unwrap_or(0),
                s.rank_of_incidence.unwrap_or(0), s.cycle_space_dim.unwrap_or(0)),
            None => println!("     measured     nothing to measure: no edges are filed"),
        }

        // ------------------------------------------------------------------
        // One document per filling of the slot. The shape is the same; the graph slides in.
        // ------------------------------------------------------------------
        let mut x = String::new();
        writeln!(x, r#"<?xml version="1.0" encoding="UTF-8"?>"#)?;
        writeln!(x, "<!-- Generated by examples/graphs from the loaded documents. \
                     Do not edit by hand.")?;
        writeln!(x, "     The `{name}` graph of every loaded document, as one pool. The \
                     filing documents")?;
        writeln!(x, "     in assets/bpmn/filings/ are separate pools, and neither contains \
                     the other. -->")?;
        writeln!(x, r#"<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL""#)?;
        writeln!(x, "             xmlns:tns=\"urn:example:process-modulus:graph:{}\"", esc(name))?;
        writeln!(x, "             xmlns:bpmndi=\"http://www.omg.org/spec/BPMN/20100524/DI\"")?;
        writeln!(x, "             xmlns:dc=\"http://www.omg.org/spec/DD/20100524/DC\"")?;
        writeln!(x, "             targetNamespace=\"urn:example:process-modulus:graph:{}\"", esc(name))?;
        writeln!(x, "             id=\"{}\">", id("defs", name))?;
        writeln!(x, "  <collaboration id=\"{}\">", id("collab", name))?;
        if nodes.is_empty() {
            // A black-box participant: no `processRef`, which is BPMN saying a party acts here
            // and what they do is not in this diagram. It is the true rendering of a relation
            // nothing files, not an empty lane set posing as a drawing.
            writeln!(x, "    <participant id=\"{}\" name=\"{}\"/>", id("pool", name), esc(name))?;
            black_boxes.push(name.to_string());
        } else {
            writeln!(x, "    <participant id=\"{}\" name=\"{}\" processRef=\"{}\"/>",
                     id("pool", name), esc(name), id("proc", name))?;
        }
        writeln!(x, "  </collaboration>")?;
        if !nodes.is_empty() {
            writeln!(x, "  <process id=\"{}\" isExecutable=\"false\">", id("proc", name))?;
            // The roster names the rule, so the document carries it. `governed_by` is on
            // `diagrams/graphs.sqlc`, and written into the document it gives a reader holding the
            // drawing a route from what a loop means to the relation that rules on one. A NULL
            // here is not a blank: it is the claimant graph, whose loops nothing judges, and the
            // sentence says so rather than leaving out the clause.
            //
            // The sense goes after the emitter's own clause, never inside it. The SVG stage's fate
            // roster claims this sentence by the literal `; a cycle here is `, and that needle is
            // the emitter's on purpose: one taken from a model value would leave the next graph's
            // sentence unclaimed when one is added. `cycle_sense` is a model value.
            writeln!(x, "    <documentation>{}; a cycle here is {}, in the {} sense. The edges \
                         come from [assets/sqlc/rank/graph_edges.sqlc], and a cycle is checked \
                         by {}</documentation>",
                     esc(g.edge_is.as_deref().unwrap_or("")),
                     esc(g.a_cycle_is.as_deref().unwrap_or("")),
                     esc(g.cycle_sense.as_deref().unwrap_or("")),
                     match g.governed_by.as_deref() {
                         Some(r) => format!("[assets/sqlc/{r}.sqlc]"),
                         None => "no rule in this repository".to_string(),
                     })?;
            writeln!(x, "    <laneSet id=\"{}\" name=\"{}\">", id("lanes", name), esc(name))?;
            for n in &nodes {
                writeln!(x, "      <lane id=\"{}\" name=\"{}\">", id("lane", n), esc(n))?;
                // Only where the graph has one. `rank` is the deepest a layer sits in the
                // composition, a fact about layers, so a unit has no position in that order and
                // none is missing. An emitter that wrote no rank would leave the renderer its own
                // placeholder to draw, putting a number this model cannot produce on the page and
                // making one layer read two different ranks in the two drawings its links connect.
                if let Some(r) = rank_of.get(*n) {
                    writeln!(x, "        <documentation>rank {r}: the number of levels of parts \
                                 beneath this layer. At 0 it waits on nothing; above 0 it waits \
                                 for every part below it to arrive \
                                 [assets/sqlc/rank/evaluation_order.sqlc]</documentation>")?;
                }
                // No row means outside what the rules examine, not zero rules. No rule declares a
                // unit as its subject, so a unit is not thinly checked: the question does not
                // reach it, and a `0` here would say somebody looked.
                if let Some((examined, violated)) = cover_of.get(*n) {
                    writeln!(x, "        <documentation>refutable by {examined} rule(s), \
                                 {violated} of which say no. A high count is not a pass, and a \
                                 low one is not a fault: the count is how many different \
                                 questions this repository can ask of this layer, so a layer \
                                 with a low count is one that a single repair would silence \
                                 [assets/sqlc/rank/layer_reach.sqlc]</documentation>")?;
                }
                for e in mine.iter().filter(|e| e.from_node.as_deref() == Some(*n)) {
                    writeln!(x, "        <flowNodeRef>{}</flowNodeRef>",
                             id("edge", &format!("{}__{}", n, e.to_node.as_deref().unwrap_or(""))))?;
                }
                writeln!(x, "      </lane>")?;
            }
            writeln!(x, "    </laneSet>")?;
            for e in &mine {
                let (f, t) = (e.from_node.as_deref().unwrap_or(""), e.to_node.as_deref().unwrap_or(""));
                writeln!(x, "    <task id=\"{}\" name=\"{} &lt;- {}\"/>",
                         id("edge", &format!("{f}__{t}")), esc(f), esc(t))?;
            }
            writeln!(x, "  </process>")?;
        }
        // The diagram's place goes in this document too. `examples/rendering/main.rs` draws what
        // a document declares rather than inventing coordinates, so a document that declares
        // nothing cannot be drawn: two producers, one contract.
        //
        // Flat, because this graph is flat. One lane per node, one row of boxes; there is no
        // `childLaneSet` here, so there is no nesting for the geometry to recurse through.
        if !nodes.is_empty() {
            let lane_h = 34usize;
            let node_h = 22usize;
            let width = 760usize;
            let mut y = 46usize;
            writeln!(x, "  <bpmndi:BPMNDiagram id=\"{}\">", id("diagram", name))?;
            writeln!(x, "    <bpmndi:BPMNPlane id=\"{}\" bpmnElement=\"tns:{}\">",
                     id("plane", name), id("collab", name))?;
            let mut boxes = String::new();
            for n in &nodes {
                let kids: Vec<String> = mine
                    .iter()
                    .filter(|e| e.from_node.as_deref() == Some(*n))
                    .map(|e| id("edge", &format!("{}__{}", n, e.to_node.as_deref().unwrap_or(""))))
                    .collect();
                let h = lane_h.max(node_h * kids.len() + 12);
                writeln!(boxes, "      <bpmndi:BPMNShape id=\"{}\" bpmnElement=\"tns:{}\">",
                         id("shape", n), id("lane", n))?;
                writeln!(boxes, "        <dc:Bounds x=\"120\" y=\"{y}\" width=\"{}\" height=\"{h}\"/>",
                         width - 140)?;
                writeln!(boxes, "      </bpmndi:BPMNShape>")?;
                let mut ny = y + 6;
                for k in &kids {
                    writeln!(boxes, "      <bpmndi:BPMNShape id=\"{}\" bpmnElement=\"tns:{k}\">",
                             id("shape", k))?;
                    writeln!(boxes, "        <dc:Bounds x=\"290\" y=\"{ny}\" width=\"450\" height=\"18\"/>")?;
                    writeln!(boxes, "      </bpmndi:BPMNShape>")?;
                    ny += node_h;
                }
                y += h + 6;
            }
            writeln!(x, "      <bpmndi:BPMNShape id=\"{}\" bpmnElement=\"tns:{}\" isHorizontal=\"true\">",
                     id("shape", &format!("{name}-pool")), id("pool", name))?;
            writeln!(x, "        <dc:Bounds x=\"8\" y=\"36\" width=\"{}\" height=\"{}\"/>",
                     width - 16, (y - 36).max(48))?;
            writeln!(x, "      </bpmndi:BPMNShape>")?;
            x.push_str(&boxes);
            writeln!(x, "    </bpmndi:BPMNPlane>")?;
            writeln!(x, "  </bpmndi:BPMNDiagram>")?;
        }
        writeln!(x, "</definitions>")?;
        fs::write(format!("{OUT}/model-{name}.bpmn"), x)?;
        emitted += 1;
        println!("     emitted      {OUT}/model-{name}.bpmn  ({} lanes, {} edges)\n",
                 nodes.len(), mine.len());
    }

    // ------------------------------------------------------------------
    // The slot's own property, asserted.
    // ------------------------------------------------------------------
    let named: BTreeMap<&str, ()> =
        graphs.iter().filter_map(|g| g.graph.as_deref().map(|s| (s, ()))).collect();
    let orphan: Vec<&str> = edges
        .iter()
        .filter_map(|e| e.graph.as_deref())
        .filter(|g| !named.contains_key(g))
        .collect();
    assert!(
        orphan.is_empty(),
        "an edge belongs to a graph the roster does not declare, so a filling exists for a slot \
         nobody named: {orphan:?}"
    );
    assert_eq!(emitted, graphs.len(), "one emission per filling, and the roster is the fillings");

    // The same law this program's sibling carries: every row set is ordered before it is written
    // out, asserted on the source. A `CLUSTER` on `pm.part` changes no row and would change these
    // documents, and nothing downstream could tell that from a real edit.
    let own = std::fs::read_to_string(file!())?;
    let needle = concat!("fetch_", "all(&pool)");
    let escaped: Vec<usize> = own
        .match_indices(needle)
        .filter(|(i, _)| {
            let stmt = own[..*i].rfind("let ").unwrap_or(0);
            !own[stmt..*i].contains("ordered(")
        })
        .map(|(i, _)| own[..i].matches('\n').count() + 1)
        .collect();
    assert!(
        escaped.is_empty(),
        "a row set reaches the emission with no total order: line(s) {escaped:?}"
    );

    // The pointer the document carries has to resolve. `governed_by` reaches a reader inside the
    // emitted `documentation`, so a rule renamed away would leave a citation naming a relation
    // nobody can open. A dangling reference in a drawing is worse than none: it reads as a rule
    // that exists.
    let dangling: Vec<String> = graphs
        .iter()
        .filter_map(|g| g.governed_by.as_deref())
        .filter(|r| !std::path::Path::new(&format!("assets/sqlc/{r}.sqlc")).exists())
        .map(str::to_string)
        .collect();
    assert!(
        dangling.is_empty(),
        "a graph cites a rule that is not a relation in this tree, so the emitted document sends \
         a reader to a file that does not exist: {dangling:?}"
    );

    // Resolving is not enough: the cited rule must be the one that holds the count. The check
    // above asks only that the path exist, so a graph could cite any relation in the tree and the
    // emitter would carry it into a reader's document as the rule that governs its loops.
    // `checks/layers_move_together`, for one, rules on loops with direction kept, the classes of
    // layers that reach each other, while the count this program holds at zero ignores direction;
    // a diamond separates the two.
    //
    // The pairs below are the rules this repository uses to decide each graph's loops with
    // direction ignored. `jagged_layer` is the one queried further down;
    // `checks/conversion_cycle_does_not_close` asks the unit graph the same question with ranges.
    for (graph, rule) in [
        ("layers", "checks/jagged_layer"),
        ("units", "checks/conversion_cycle_does_not_close"),
    ] {
        let row = graphs
            .iter()
            .find(|g| g.graph.as_deref() == Some(graph))
            .unwrap_or_else(|| panic!("`{graph}` is not on diagrams/graphs.sqlc"));
        assert_eq!(
            row.cycle_sense.as_deref(),
            Some("undirected"),
            "`{graph}` declares the `{}` sense, and the loops this repository rules on for \
             it are counted with direction ignored",
            row.cycle_sense.as_deref().unwrap_or("?")
        );
        assert_eq!(
            row.governed_by.as_deref(),
            Some(rule),
            "`{graph}` cites `{}` as what governs its loops, and the rule that holds its \
             loops, direction ignored, is `{rule}`. A citation that merely resolves sends a reader \
             to a rule about a different sense of the word",
            row.governed_by.as_deref().unwrap_or("nothing")
        );
    }

    println!("One emission per filling of the slot, and the roster is the only place a graph is");
    println!("   named. An edge belonging to an unnamed graph fails the run: a filling for a slot");
    println!("   nobody declared is exactly what `@scope` refuses in the SQL.");
    if !black_boxes.is_empty() {
        println!("\nBlack box, no processRef: {}", black_boxes.join(", "));
        println!("   That is BPMN for `a party acts here and what they do is not in this diagram`,");
        println!("   and it is the honest rendering of a relation nothing files. Delegation has no");
        println!("   table: `prov_entered_by` and `prov_approved_by` are bare tokens with no");
        println!("   identity to join on, which pm:Provenance's own annotation names as the defect");
        println!("   it did not fix when it split one free-text field into three columns.");
    }
    // ------------------------------------------------------------------
    // Two counts of one fact, required to agree. `checks/jagged_layer` walks every (root, leaf)
    // pair and gives every fusion a verdict. `rank/cycle_space` counts edges, nodes and separate
    // pieces, and from them the loops the layer graph has with direction ignored. They answer the
    // same question: such a loop in the composition is two distinct paths between one pair of
    // layers, which is a layer arriving twice under one total. Neither is derived from the other.
    //
    // The same count tells the two kinds of sharing apart with no special case. Two paths from
    // one layer make a loop, so a jagged partition counts. Two paths from two unconnected roots
    // join two separate trees and add no loop, so `eliminations/derived.sqlc`'s sharing between
    // two roots does not count, which is this repository's position that it is a referral and
    // never a violation.
    //
    // Why a fusion is only sometimes a merge. A fusion whose parts sit in different pieces of the
    // graph joins them and adds no loop; a fusion with two parts inside one piece adds one.
    // Reaching into a piece you already reach is a double count in a merge's shape.
    //
    // So no legitimate filing can make the unit graph's loop appear in the composition. Making
    // the layer graph loop needs a fusion within one piece, which is a violation, and every filing
    // that could hold both ends of the unit loop would be fusing across pieces, which adds none.
    // The unit graph is where that loop lives, and it cannot be moved into the composition.
    //
    // The agreement is on zero against more than zero, never on the two counts. One count is of
    // independent loops, the rule's is of violating fusions, and one loop can accuse more than
    // one fusion, so an `assert_eq!` on the numbers would be a coincidence waiting to break.
    //
    // A probe for it reuses `examples/witnesses/main.rs`'s own mutation: in
    // `assets/fixtures/every-local-part.xml`, make the first `as-contracted` read `both-views`, so
    // a layer is composed from itself, then reload the schema and the ingest. Both counts move on
    // that edit, and neither reads the other, which is what makes their agreement evidence rather
    // than two comments agreeing.
    // ------------------------------------------------------------------
    let jagged = ordered(sqlx::query_file!("assets/sql/checks/jagged_layer.sql").fetch_all(&pool).await?);
    let lay = cyc
        .iter()
        .find(|c| c.graph.as_deref() == Some("layers"))
        .ok_or("the layer graph is not on rank/cycle_space.sqlc, so there is nothing to agree with")?;
    let dim = lay.cycle_space_dim.unwrap_or(-1);
    let violations = jagged.iter().filter(|j| j.violates == Some(true)).count();
    let examined = jagged.iter().filter(|j| j.violates.is_some()).count();

    println!("\nThe same fact, counted two ways");
    println!("   rank/cycle_space   layers: {dim} loops over {} nodes and {} edges in {} pieces",
             lay.n_nodes.unwrap_or(-1), lay.m_edges.unwrap_or(-1), lay.c_components.unwrap_or(-1));
    println!("   checks/jagged_layer        {violations} violation(s) of {examined} fusions examined");

    // Something must have been examined first, because `0 == 0` is true of an empty graph and of
    // a rule never run. Two counts that both examined nothing agreeing is two comments agreeing.
    assert!(
        lay.n_nodes.unwrap_or(0) > 0 && lay.m_edges.unwrap_or(0) > 0,
        "the layer graph is empty, so its count of loops is 0 for the wrong reason"
    );
    assert!(examined > 0, "checks/jagged_layer examined nothing, so its 0 is a vacuum");

    assert_eq!(
        dim == 0,
        violations == 0,
        "the loop count and the jagged-partition rule disagree about the same corpus: a loop \
         in the composition is two paths under one total, so {dim} loops and {violations} \
         violation(s) cannot both be right"
    );
    println!("   A loop in the composition is a layer arriving twice under one total, so these");
    println!("      two are one statement. The two-root sharing in eliminations/derived joins two");
    println!("      unconnected trees and correctly moves neither.");

    // ------------------------------------------------------------------
    // The citation contract for this directory. `examples/diagramming/main.rs` holds it over
    // `assets/bpmn/filings/` and reads only its own directory, so this program holds it over its
    // own: every sentence these documents carry, the loop gloss, the rank and the coverage, is
    // checked here. Two emitters, one contract.
    //
    // A sentence about a filing is the model's voice and comes from a relation. The check has
    // three arms: the cited file exists, this program queried it, and no sentence is
    // unattributed. `query_file!` takes a literal, so what was queried can be read out of this
    // program's own source.
    // ------------------------------------------------------------------
    // `queried` has to mean everything composed beneath what is queried, which is where this law
    // differs from `examples/diagramming/main.rs`'s. That program reads the relation that states
    // each fact directly, so the set of direct queries is enough there. This one reads
    // `rank/graph_nodes.sqlc` and gets the rank and the coverage through it, so citing
    // `rank/evaluation_order.sqlc` is the true pointer, and a test of direct queries alone would
    // call it decorative. A citation names where a fact is stated, not where it was fetched.
    let mut queried: std::collections::BTreeSet<String> = std::collections::BTreeSet::new();
    let own = fs::read_to_string(file!())?;
    let mut rest = own.as_str();
    while let Some(i) = rest.find("query_file!(\"assets/sql/") {
        rest = &rest[i + 24..];
        if let Some(j) = rest.find(".sql\"") {
            queried.insert(format!("assets/sqlc/{}.sqlc", &rest[..j]));
            rest = &rest[j..];
        } else {
            break;
        }
    }
    assert!(!queried.is_empty(), "the query scan found nothing, so the citation law below is vacuous");
    // The closure comes from the relation, not from a scan in this file. An inline `:compose(`
    // reader here would duplicate `examples/shared/tree` in a program that has a database open
    // the whole time. `public.compose_edge` is that fact as a relation, so the closure is a walk
    // over rows, and the source tree is read once, by the program whose job that is.
    let seeded = queried.len();
    let dag = ordered(sqlx::query_file!("assets/sql/rank/compose_edges.sql").fetch_all(&pool).await?);
    let mut frontier: Vec<String> = queried.iter().cloned().collect();
    while let Some(f) = frontier.pop() {
        let parent = f.trim_start_matches("assets/sqlc/").to_string();
        for e in dag.iter().filter(|e| e.parent == parent) {
            let child = format!("assets/sqlc/{}", e.child);
            if queried.insert(child.clone()) {
                frontier.push(child);
            }
        }
    }
    // A roster's own data is the second route. `diagrams/graphs.sqlc` carries the rule that judges
    // each graph's loops as a value, and the emitter writes that value into the document so a
    // reader can reach the rule. Nothing composes it, and nothing should: it is a pointer the
    // roster states, and the true test is that the emitter read it.
    for g in &graphs {
        if let Some(r) = g.governed_by.as_deref() {
            queried.insert(format!("assets/sqlc/{r}.sqlc"));
        }
    }
    println!("\n   {seeded} relations queried directly, {} in their compose closure plus the",
             queried.len() - seeded);
    println!("      rules the graph roster names as data. A citation points at where a fact is");
    println!("      stated, and this emitter reaches most of its facts through composition.");
    let (mut sentences, mut unattributed, mut dangling, mut unread) = (0usize, vec![], vec![], vec![]);
    for e in fs::read_dir(OUT)?.flatten() {
        let path = e.path();
        if path.extension().and_then(|x| x.to_str()) != Some("bpmn") {
            continue;
        }
        let doc = fs::read_to_string(&path)?;
        let who = path.file_name().unwrap_or_default().to_string_lossy().to_string();
        for (open, close) in [("<documentation>", "</documentation>"), ("<text>", "</text>")] {
            let mut rest = doc.as_str();
            while let Some(i) = rest.find(open) {
                rest = &rest[i + open.len()..];
                let Some(end) = rest.find(close) else { break };
                let body = &rest[..end];
                rest = &rest[end..];
                sentences += 1;
                let mut cited = 0usize;
                let mut b = body;
                while let Some(i) = b.find("[assets/sqlc/") {
                    b = &b[i + 1..];
                    let Some(j) = b.find(']') else { break };
                    let c = b[..j].to_string();
                    cited += 1;
                    if !std::path::Path::new(&c).exists() {
                        dangling.push(format!("{who}: {c}"));
                    } else if !queried.contains(&c) {
                        unread.push(format!("{who}: {c}"));
                    }
                    b = &b[j..];
                }
                if cited == 0 {
                    unattributed.push(format!("{who}: {}", body.chars().take(60).collect::<String>()));
                }
            }
        }
    }
    assert!(
        unattributed.is_empty(),
        "a sentence is in an emitted graph document with nothing naming the relation that states \
         it, so a reader who wants to argue with it has no route back: {unattributed:?}"
    );
    assert!(
        dangling.is_empty(),
        "a sentence cites a relation that is not in this tree: {dangling:?}"
    );
    assert!(
        unread.is_empty(),
        "a sentence cites a relation this program never queried, so the citation is decorative \
         and the sentence is still the emitter's own claim: {unread:?}"
    );
    println!("\n   {sentences} sentences across these documents, 0 unattributed. This directory");
    println!("      has its own citation law: diagramming.rs holds one and reads only its own");
    println!("      directory, so this emitter's sentences are checked here.");

    println!("\nAll checks passed.");
    Ok(())
}
