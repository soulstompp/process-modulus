//! The three graphs this model composes, as the lane sets of one pool.
//!
//! ⭐⭐⭐ THE BIG POOL IS THE MODEL, AND THE THREE GRAPHS ARE LANE SETS OVER IT. The fifteen
//! filing-pools `examples/diagramming.rs` emits sit INSIDE this one. A `laneSet` is a partition
//! claimed exhaustive, and three LANES would put every composition in exactly one; measured, 169
//! of 220 compositions touch more than one graph, because a relation reading a part AND its factor
//! is in the layer graph and the unit graph and that is what a factor IS. BPMN permits several
//! lane sets over one process for exactly this reason.
//!
//! ⛔⛔ AND THREE LANE SETS CANNOT ALL BE THE CONTAINMENT. An inclusion tree gives each node ONE
//! parent, so only one of them can be the nesting a diagram draws. That is why the graph is a
//! SLOT here rather than a silent pick: `entries/coupling_presence.sqlc` is asked of the corpus by
//! one caller and of every filing by another, both are right, and a caller supplying no `@scope`
//! DOES NOT COMPOSE. The choice moves from a habit into the structure.
//!
//! ⭐⭐ THE BPMN WORD FOR A SLOT IS ALREADY IN THE SPEC. A `participant` has an OPTIONAL
//! `processRef`: supply it and the pool has contents, omit it and you have a BLACK BOX POOL, which
//! is first-class BPMN for *a party acts here and what they do is not in this diagram*. An
//! unfilled slot IS a black-box participant, and this example emits one for the graph that has no
//! edges, rather than pretending it drew something.
//!
//! ```text
//! DATABASE_URL=... cargo run --example graphs
//! ```

use std::collections::BTreeMap;
use std::fmt::Write as _;
use std::fs;

/// ⛔ THIS PROGRAM OWNS THIS DIRECTORY, AND CREATES IT. Writing into `assets/bpmn/` beside
/// `examples/diagramming.rs`, which WIPES what it owns, leaves these three documents surviving
/// only when that example runs first, and leaves this one depending on the other having run at
/// all.
const OUT: &str = "assets/bpmn/graphs";

/// Every row set this program serializes, in a total order that is a function of the ROWS.
///
/// ⛔⛔⛆ A TRACKED GENERATED ARTIFACT MUST NOT DEPEND ON THE PLAN. Two databases loaded from one
///   corpus by one ingest returned `flowNodeRef` in different orders, so the emitted documents
///   differed byte for byte while meaning the same thing. `assets/sql/` has `--verify` behind it
///   and these have nothing, so the difference was invisible until two machines compared.
///
/// ⭐⭐ AND THE ORDER IS NOT OWED BY `assets/sqlc/`. A relation is a SET; an `ORDER BY` there is
///   spliced into a subquery at every call site and discarded by the outer query, so it would be
///   a claim that holds only where the relation happens to be read at the top. Serializing a set
///   into a document is where a total order is owed, and that is here.
///
/// ⛔ OVER EVERY COLUMN, because a key that is not unique leaves its ties to the planner, which
///   is the same defect one layer down.
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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL")
        .map_err(|_| "DATABASE_URL is unset, and the graphs are relations.")?;
    let pool = sqlx::postgres::PgPool::connect(&url).await?;

    // ⛔ THE ROSTER IS THE ONLY PLACE A GRAPH IS NAMED. A `VALUES` literal, because derived from
    //   the tree it could never report that a declared graph has nothing behind it, and the
    //   claimant row is precisely that case.
    let graphs = ordered(sqlx::query_file!("assets/sql/diagrams/graphs.sql").fetch_all(&pool).await?);
    let edges = ordered(sqlx::query_file!("assets/sql/diagrams/graph_edges.sql").fetch_all(&pool).await?);
    let cyc = ordered(sqlx::query_file!("assets/sql/rank/cycle_space.sql").fetch_all(&pool).await?);

    println!("THE THREE GRAPHS, AS LANE SETS OF ONE POOL\n");
    // ⛔ WIPED, and only this program's own subdirectory. A stale document is a claim about a
    //   model that has moved, and wiping a directory ANOTHER program also writes is how these
    //   three vanish: `examples/diagramming.rs` wipes a shared parent, leaving them only when
    //   this example runs second.
    if std::path::Path::new(OUT).exists() {
        fs::remove_dir_all(OUT)?;
    }
    fs::create_dir_all(OUT)?;

    let mut emitted = 0usize;
    let mut black_boxes: Vec<String> = Vec::new();

    for g in &graphs {
        let name = g.graph.as_deref().unwrap_or("?");
        let mine: Vec<_> = edges.iter().filter(|e| e.graph.as_deref() == Some(name)).collect();
        let mut nodes: Vec<&str> = mine
            .iter()
            .flat_map(|e| [e.from_node.as_deref().unwrap_or(""), e.to_node.as_deref().unwrap_or("")])
            .collect();
        nodes.sort_unstable();
        nodes.dedup();

        let space = cyc.iter().find(|c| c.graph.as_deref().map(|s| s.starts_with(name)) == Some(true));
        println!("  {name}");
        println!("     a node is    {}", g.node_is.as_deref().unwrap_or(""));
        println!("     an edge is   {}", g.edge_is.as_deref().unwrap_or(""));
        println!("     a cycle is   {}", g.a_cycle_is.as_deref().unwrap_or(""));
        println!("     governed by  {}", g.governed_by.as_deref().unwrap_or("⛔ nothing"));
        match space {
            Some(s) => println!(
                "     measured     {} nodes, {} edges, {} components, rank {}, cycle space {}",
                s.n_nodes.unwrap_or(0), s.m_edges.unwrap_or(0), s.c_components.unwrap_or(0),
                s.rank_of_incidence.unwrap_or(0), s.cycle_space_dim.unwrap_or(0)),
            None => println!("     measured     ⛔ nothing to measure: no edges are filed"),
        }

        // ------------------------------------------------------------------
        // One document per FILLING of the slot. The shape is the same; the graph slides in.
        // ------------------------------------------------------------------
        let mut x = String::new();
        writeln!(x, r#"<?xml version="1.0" encoding="UTF-8"?>"#)?;
        writeln!(x, "<!-- GENERATED by examples/graphs.rs. DO NOT EDIT.")?;
        writeln!(x, "     The big pool, with the `{name}` graph filling the slot. The fifteen")?;
        writeln!(x, "     filing-pools of examples/diagramming.rs sit inside this one. -->")?;
        writeln!(x, r#"<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL""#)?;
        writeln!(x, "             xmlns:tns=\"urn:example:process-modulus:graph:{}\"", esc(name))?;
        writeln!(x, "             xmlns:bpmndi=\"http://www.omg.org/spec/BPMN/20100524/DI\"")?;
        writeln!(x, "             xmlns:dc=\"http://www.omg.org/spec/DD/20100524/DC\"")?;
        writeln!(x, "             targetNamespace=\"urn:example:process-modulus:graph:{}\"", esc(name))?;
        writeln!(x, "             id=\"{}\">", id("defs", name))?;
        writeln!(x, "  <collaboration id=\"{}\">", id("collab", name))?;
        if nodes.is_empty() {
            // ⛔⛔ A BLACK BOX PARTICIPANT: no `processRef`, which is BPMN saying a party acts
            //    here and what they do is not in this diagram. It is the honest rendering of a
            //    relation nothing files, and it is NOT an empty lane set pretending to be a
            //    drawing.
            writeln!(x, "    <participant id=\"{}\" name=\"{}\"/>", id("pool", name), esc(name))?;
            black_boxes.push(name.to_string());
        } else {
            writeln!(x, "    <participant id=\"{}\" name=\"{}\" processRef=\"{}\"/>",
                     id("pool", name), esc(name), id("proc", name))?;
        }
        writeln!(x, "  </collaboration>")?;
        if !nodes.is_empty() {
            writeln!(x, "  <process id=\"{}\" isExecutable=\"false\">", id("proc", name))?;
            // ⭐⭐ THE ROSTER ALREADY NAMED THE RULE AND THE EMISSION DROPPED IT. `governed_by`
            //   is on `diagrams/graphs.sqlc` and reached the terminal and no artifact, so a
            //   reader holding the drawing had the cycle's MEANING and no route to the relation
            //   that rules on one. ⛔ A NULL here is not a blank: it is the claimant graph, whose
            //   cycles nothing judges, and the sentence says so rather than omitting the clause.
            writeln!(x, "    <documentation>{}; a cycle here is {}. The edges: \
                         [assets/sqlc/diagrams/graph_edges.sqlc]; a cycle is ruled on by {}\
                         </documentation>",
                     esc(g.edge_is.as_deref().unwrap_or("")),
                     esc(g.a_cycle_is.as_deref().unwrap_or("")),
                     match g.governed_by.as_deref() {
                         Some(r) => format!("[assets/sqlc/{r}.sqlc]"),
                         None => "⛔ NOTHING; no rule in this repository examines one".to_string(),
                     })?;
            writeln!(x, "    <laneSet id=\"{}\" name=\"{}\">", id("lanes", name), esc(name))?;
            for n in &nodes {
                writeln!(x, "      <lane id=\"{}\" name=\"{}\">", id("lane", n), esc(n))?;
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
        // ⭐⭐⭐ THE DIAGRAM'S PLACE IN THIS DOCUMENT TOO, AND THE SECOND EMITTER OWED IT AS SOON
        //    AS THE FIRST DECLARED ONE. `examples/rendering.rs` now DRAWS what a document
        //    declares rather than inventing coordinates, so a document that declares nothing
        //    cannot be drawn -- and it refused these three by name, which is the emitter roster
        //    from the previous pass paying out: two producers, one contract.
        //
        // ⛔ FLAT, BECAUSE THIS GRAPH IS FLAT. One lane per node, one row of boxes; there is no
        //   `childLaneSet` here, so there is no nesting for the geometry to recurse through.
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

    // ⛔⛔ THE SAME LAW THIS PROGRAM'S SIBLING CARRIES: every row set is ordered before it is
    //    serialized, asserted on the source. Measured, a `CLUSTER` on `pm.part` changes no row
    //    and changes these documents, and nothing downstream could tell that from a real edit.
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

    // ⛔⛔ AND THE POINTER THE ARTIFACT NOW CARRIES HAS TO RESOLVE. `governed_by` reaches a
    //   reader inside the emitted `documentation`, so a rule that was renamed away leaves a
    //   citation in an artifact naming a relation nobody can open. A dangling reference in a
    //   drawing is worse than none: it reads as a rule that exists.
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

    println!("⭐ One emission per FILLING of the slot, and the roster is the only place a graph is");
    println!("   named. An edge belonging to an unnamed graph fails the run: a filling for a slot");
    println!("   nobody declared is exactly what `@scope` refuses in the SQL.");
    if !black_boxes.is_empty() {
        println!("\n⛔ BLACK BOX, no processRef: {}", black_boxes.join(", "));
        println!("   That is BPMN for `a party acts here and what they do is not in this diagram`,");
        println!("   and it is the honest rendering of a relation nothing files. Delegation has no");
        println!("   table: `prov_entered_by` and `prov_approved_by` are bare tokens with no");
        println!("   identity to join on, which pm:Provenance's own annotation names as the defect");
        println!("   it did not fix when it split one free-text field into three columns.");
    }
    // ------------------------------------------------------------------
    // ⭐⭐⭐ TWO INSTRUMENTS, ONE FACT, AND THEY ARE REQUIRED TO AGREE. `checks/jagged_layer`
    //    walks (root, leaf) pairs and gives every fusion a verdict. `rank/cycle_space` counts
    //    edges, nodes and components. They are computing the same thing: an undirected cycle in
    //    `F` IS two distinct paths between one pair, which is a layer arriving twice under one
    //    fold. Eighteen verdicts and one number, and neither is derived from the other.
    //
    // ⭐⭐ AND THE CYCLE SPACE MAKES §4's DISCRIMINATOR FOR FREE, WITH NO SPECIAL CASE. Two paths
    //    from ONE node is a cycle, so a jagged partition counts. Two paths from two UNCONNECTED
    //    nodes is a tree JOIN and contributes nothing, so `eliminations/derived.sqlc`'s two-root
    //    sharing does not count, which is exactly this repository's position that it is a REFERRAL
    //    and never a violation. The corpus carries one of those and the cycle space stays flat.
    //
    // ⛔⛔ THE ARITHMETIC BEHIND IT, WHICH IS WHY A FUSION IS ONLY SOMETIMES A MERGE. Adding a
    //    fusion with `k` parts moves `m - n + c`. Across `k` DIFFERENT components:
    //    `dn=+1, dm=+k, dc=-(k-1)`, so the dimension is UNCHANGED and the wrap is free. With two
    //    parts inside ONE component: `dn=+1, dm=+2, dc=0`, so the dimension RISES BY ONE. Reaching
    //    into a component you already reach is a double count wearing a merge's shape.
    //
    // ⚠️ SO NO LEGITIMATE FILING CAN MAKE THE UNIT CYCLE APPEAR IN `F`. Making the layer graph
    //   cyclic requires a within-component fusion, which is a violation, and every filing that
    //   could hold both ends of the unit cycle would be fusing ACROSS components, which is free.
    //   The overlay is where that cycle lives, and it is irreducible rather than a convenience.
    //
    // ⛔⛔ AND THE EQUIVALENCE IS ON ZERO VERSUS NONZERO, NEVER ON THE TWO COUNTS. The cycle
    //   space counts INDEPENDENT cycles; the rule counts VIOLATING FUSIONS, and one cycle can
    //   accuse more than one fusion. The probe below returns 1 and 2, which is the equivalence
    //   holding rather than failing, and an `assert_eq!` on the numbers would have been a
    //   coincidence waiting to break.
    //
    // ⭐ THE PROBE, AND IT REUSES `examples/witnesses.rs`'s OWN MUTATION rather than inventing
    //   one: in `assets/fixtures/every-local-part.xml` make the first `as-contracted` read
    //   `both-views`, so a layer is composed from ITSELF, then reload the schema and the ingest.
    //
    //       variant                cycle_space   jagged_violations
    //       as filed                        0                   0
    //       composed from itself            1                   2
    //       restored                        0                   0
    //
    //   Both instruments move on the same edit and neither reads the other, which is what makes
    //   a green agreement here evidence instead of two comments agreeing.
    // ------------------------------------------------------------------
    let jagged = ordered(sqlx::query_file!("assets/sql/checks/jagged_layer.sql").fetch_all(&pool).await?);
    let lay = cyc
        .iter()
        .find(|c| c.graph.as_deref() == Some("layers"))
        .ok_or("the layer graph is not on rank/cycle_space.sqlc, so there is nothing to agree with")?;
    let dim = lay.cycle_space_dim.unwrap_or(-1);
    let violations = jagged.iter().filter(|j| j.violates == Some(true)).count();
    let examined = jagged.iter().filter(|j| j.violates.is_some()).count();

    println!("\nTHE SAME FACT, COUNTED TWO WAYS");
    println!("   rank/cycle_space   layers: dim {dim} over {} nodes and {} edges in {} components",
             lay.n_nodes.unwrap_or(-1), lay.m_edges.unwrap_or(-1), lay.c_components.unwrap_or(-1));
    println!("   checks/jagged_layer        {violations} violation(s) of {examined} fusions examined");

    // ⛔ NON-VACUITY FIRST, BECAUSE `0 == 0` IS TRUE OF AN EMPTY GRAPH AND AN UNRUN RULE. A green
    //   equivalence between two instruments that both examined nothing is two comments agreeing.
    assert!(
        lay.n_nodes.unwrap_or(0) > 0 && lay.m_edges.unwrap_or(0) > 0,
        "the layer graph is empty, so its cycle space is 0 for the wrong reason"
    );
    assert!(examined > 0, "checks/jagged_layer examined nothing, so its 0 is a vacuum");

    assert_eq!(
        dim == 0,
        violations == 0,
        "the cycle space and the jagged-partition rule disagree about the same corpus: an \
         undirected cycle in F is two paths under one fold, so dim {dim} and {violations} \
         violation(s) cannot both be right"
    );
    println!("   ⭐ An undirected cycle in F IS a layer arriving twice under one fold, so these");
    println!("      two are one statement. The two-root sharing in eliminations/derived is a tree");
    println!("      JOIN between unconnected roots and correctly moves neither.");

    println!("\nAll checks passed.");
    Ok(())
}
