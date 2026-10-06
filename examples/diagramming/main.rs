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
#![doc = include_str!("../../pt-PT/examples/diagramming/README.md")]

use std::collections::BTreeMap;
use std::fmt::Write as _;
use std::fs;
use std::path::Path;

/// This program owns this directory and wipes it, which is why it is a subdirectory. Sharing
/// `assets/bpmn/` with `examples/graphs/main.rs` would put the wipe below over that program's
/// documents whenever this one ran second. Both orders would pass every law, and `rendering` would
/// silently cover more or fewer documents depending on which example ran last. A directory per
/// owner makes the order stop mattering.
///
/// The split also says what the two emitters are. These are one document per filing, at layer
/// grain; `graphs` emits one per graph filling, corpus-wide. The two do not nest, because a
/// `participant` cannot contain a `participant`. Two collaborations, two directories.
const OUT: &str = "assets/bpmn/filings";
const BPMN_NS: &str = "http://www.omg.org/spec/BPMN/20100524/MODEL";
const DI_NS: &str = "http://www.omg.org/spec/BPMN/20100524/DI";
/// The DI namespace proper, which is where a `waypoint` lives. `bpmndi` is the BPMN-specific
/// diagram interchange and `dc` is the shared graphics primitives; an edge's waypoints are
/// `di:waypoint`, in neither of those, and an association could not be given a route without it.
const DI_BASE_NS: &str = "http://www.omg.org/spec/DD/20100524/DI";
const DC_NS: &str = "http://www.omg.org/spec/DD/20100524/DC";

/// The layout lives here because `bpmndi:BPMNDiagram` lives in `tDefinitions`. BPMN has a place
/// for a document's own picture, and `examples/rendering/main.rs` draws from it rather than
/// inventing coordinates: a drawing whose geometry has no original is a second opinion rather
/// than a cache, which is why `.sqlx` is extracted from the generated file and not the source.
///
/// `diagrams/notation.sqlc`'s roster covers both halves of the standard, `Semantic.xsd` and
/// `BPMNDI.xsd`, and the DI half is the half about drawing.
const LANE_H: usize = 34;
const NODE_H: usize = 22;
const WIDTH: usize = 760;

/// A lane is as tall as what it holds: its own flow nodes, or its children and their children.
fn lane_height(kids: &BTreeMap<String, Vec<String>>, nodes: &BTreeMap<String, Vec<String>>,
               layer: &str) -> usize {
    match kids.get(layer) {
        Some(cs) if !cs.is_empty() =>
            22 + cs.iter().map(|c| lane_height(kids, nodes, c) + 4).sum::<usize>() + 6,
        _ => LANE_H.max(NODE_H * nodes.get(layer).map_or(0, |v| v.len()) + 12),
    }
}

/// One lane's box and everything under it, appended to `out` as `(id, x, y, w, h)`. Lanes nest,
/// so the geometry recurses with them.
#[allow(clippy::too_many_arguments)]
fn place(out: &mut Vec<(String, usize, usize, usize, usize)>,
         kids: &BTreeMap<String, Vec<String>>, nodes: &BTreeMap<String, Vec<String>>,
         filing: &str, layer: &str, x: usize, y: usize, w: usize) {
    let h = lane_height(kids, nodes, layer);
    out.push((id("lane", &[filing, layer]), x, y, w, h));
    match kids.get(layer) {
        Some(cs) if !cs.is_empty() => {
            let mut ky = y + 22;
            for c in cs {
                place(out, kids, nodes, filing, c, x + 14, ky, w.saturating_sub(20));
                ky += lane_height(kids, nodes, c) + 4;
            }
        }
        _ => {
            let mut ny = y + 6;
            for n in nodes.get(layer).into_iter().flatten() {
                out.push((n.clone(), x + 170, ny, w.saturating_sub(180).max(60), 18));
                ny += NODE_H;
            }
        }
    }
}

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

/// An `xsd:ID` is an NCName: it may not start with a digit and may not contain most punctuation.
/// Layer and filing names here are domain text, not identifiers, so they are sanitised into an id
/// and kept verbatim in `name`. Losing the original in the id is fine; losing it in the name would
/// be the emitter quietly renaming the model.
fn id(prefix: &str, parts: &[&str]) -> String {
    let mut s = String::from(prefix);
    for p in parts {
        s.push('_');
        for c in p.chars() {
            s.push(if c.is_ascii_alphanumeric() || c == '-' || c == '.' { c } else { '_' });
        }
    }
    s
}

/// One lane and everything under it. Lanes nest, which is why this function recurses. `Lane`
/// carries an optional `childLaneSet` for sub-partitions, and *a fusion's parts partition what
/// they compose* is that sentence in BPMN's own words. A local fusion written as a `subProcess`
/// would say it is an activity inside a lane rather than a partition of one, and lose layer grain
/// on the way out.
///
/// A lane holding a `childLaneSet` writes no `flowNodeRef` of its own. No local fusion in this
/// corpus carries a draw or a foreign part, so no parent owes both; `diagrams/nestings.sqlc` says
/// what to do when one does.
fn lane(
    x: &mut String,
    ind: usize,
    filing: &str,
    layer: &str,
    kids: &BTreeMap<String, Vec<String>>,
    ranks: &BTreeMap<String, i32>,
    nodes: &BTreeMap<String, Vec<String>>,
    cited: &str,
) -> std::fmt::Result {
    let p = " ".repeat(ind);
    writeln!(x, "{p}<lane id=\"{}\" name=\"{}\">", id("lane", &[filing, layer]), esc(layer))?;
    writeln!(x, "{p}  <documentation>rank {}: the number of levels of parts beneath this layer. \
                 At 0 it waits on nothing; above 0 it waits for every part below it to \
                 arrive{cited}</documentation>",
             ranks.get(layer).copied().unwrap_or(0))?;
    match kids.get(layer) {
        Some(cs) if !cs.is_empty() => {
            writeln!(x, "{p}  <childLaneSet id=\"{}\" name=\"parts\">",
                     id("kids", &[filing, layer]))?;
            for c in cs {
                lane(x, ind + 4, filing, c, kids, ranks, nodes, cited)?;
            }
            writeln!(x, "{p}  </childLaneSet>")?;
        }
        _ => {
            for n in nodes.get(layer).into_iter().flatten() {
                writeln!(x, "{p}  <flowNodeRef>{n}</flowNodeRef>")?;
            }
        }
    }
    writeln!(x, "{p}</lane>")
}

#[path = "../shared/database/mod.rs"]
mod database;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example translates the loaded corpus and cannot do that \
         without the rows."
    })?;
    let pool = database::connect(&url).await?;

    // ------------------------------------------------------------------
    // The model. Every relation here is composed; none is spelled inline.
    // ------------------------------------------------------------------
    // The projections under `diagrams/` carry links only, no figures, so this program cannot read
    // a magnitude even by accident. And they are not the relations `diagrams/expected.sqlc`
    // counts, on purpose: expected reads the wide relation and the emitter the narrow one composed
    // from it, so a filter added to a projection makes a law fire.
    let filings = ordered(sqlx::query_file!("assets/sql/diagrams/pools.sql").fetch_all(&pool).await?);
    let layers = ordered(sqlx::query_file!("assets/sql/layers/every_layer.sql").fetch_all(&pool).await?);
    let ops = ordered(sqlx::query_file!("assets/sql/entries/operations.sql").fetch_all(&pool).await?);
    // The operation's pm:ForeignId, the only one that points out of the model rather than at
    // another filing. Read as its own relation, so the sentence on the task cites the file that
    // states it rather than a dimension that merely carries the column.
    let crossings =
        ordered(sqlx::query_file!("assets/sql/entries/notation_references.sql").fetch_all(&pool).await?);
    let draws = ordered(sqlx::query_file!("assets/sql/diagrams/lane_members.sql").fetch_all(&pool).await?);
    let parts = ordered(sqlx::query_file!("assets/sql/diagrams/calls.sql").fetch_all(&pool).await?);
    let notations = ordered(sqlx::query_file!("assets/sql/diagrams/imports.sql").fetch_all(&pool).await?);
    // Induction, which nothing else here carries. A `categoryValue` per layer something is
    // induced into, a `categoryValueRef` per induction, and a `group` to draw each.
    // `tFlowElement` carries `categoryValueRef` with `maxOccurs="unbounded"`, so these groups may
    // overlap where a lane set may not, and they add no lane: a second `laneSet` would give every
    // induced layer a second `lane` element, with only a matching name to say it is the same
    // layer.
    let categories = ordered(sqlx::query_file!("assets/sql/diagrams/categories.sql").fetch_all(&pool).await?);
    let cat_members =
        ordered(sqlx::query_file!("assets/sql/diagrams/category_members.sql").fetch_all(&pool).await?);
    // Coupling and its search, one fact filed as two relations. A coupling is the one fact that
    // would show the model wrong, so a document that cannot state it cannot say so; and drawing the
    // couplings alone is worse than drawing neither, because most filings state no coupling and a
    // reader resolves a blank page as independence. The search says which blank it is.
    let deps = ordered(sqlx::query_file!("assets/sql/diagrams/dependences.sql").fetch_all(&pool).await?);
    let searches = ordered(sqlx::query_file!("assets/sql/diagrams/searches.sql").fetch_all(&pool).await?);
    // The extent is read, never asserted. Writing *a partition of layers claimed exhaustive* onto
    // every document would say `complete` of filings that do not claim it. A string literal about
    // a filing is a claim this program made up, and no count can reach one. If a sentence here
    // says something about a filing, it comes from a relation.
    let scopes = ordered(sqlx::query_file!("assets/sql/diagrams/scopes.sql").fetch_all(&pool).await?);
    // A mapping that names an element already spent renders nothing, and no law sees it. Declared
    // against `documentation`, which the pools and the lanes already use, this one would emit
    // nothing and count as covered.
    let citations = ordered(sqlx::query_file!("assets/sql/diagrams/citations.sql").fetch_all(&pool).await?);
    // The composition at layer grain. `calledElement` names a process, so the part edges collapse
    // to document pairs and the layer survives only inside `@name`. `tRelationship` takes QNames at
    // both ends and a required `type`, which is what an `association` lacks.
    let descents = ordered(sqlx::query_file!("assets/sql/diagrams/descents.sql").fetch_all(&pool).await?);
    // Which relation each sentence states: the `--` line a generated file owes. A
    // `documentation` element carrying a sentence and no route back to the relation that produced
    // it is a generated `.sql` file without its one `--` line. Read from here rather than written
    // as a literal beside each `writeln!`: a pointer this program made up is a claim about the
    // model that no law can reach, which is the `invents` state `diagrams/domain_objects.sqlc`
    // names.
    let annotated = ordered(sqlx::query_file!("assets/sql/diagrams/annotated.sql").fetch_all(&pool).await?);
    // The notes a document owes on its own face. `documentation` is invisible in every rendering,
    // so a fact filed there alone is in the file and on no page. `textAnnotation` is the only
    // element in BPMN that puts words on the canvas, and withholding it because *documentation is
    // spent instead* would rest on a true statement about the wrong property.
    let legends = ordered(sqlx::query_file!("assets/sql/diagrams/legends.sql").fetch_all(&pool).await?);
    // The elimination's `pm:ForeignId`, and the only place it is drawn as a reference. A
    // `between` says which layer of which other document the double counting runs against, in the
    // same reference shape as a part. Only the resolved ones can be emitted: a QName needs a
    // prefix and a prefix needs an import, so a `between` naming a document nobody filed cannot
    // be referenced here, and the schema calls that filing ordinary.
    let attributions = ordered(sqlx::query_file!("assets/sql/diagrams/attributions.sql").fetch_all(&pool).await?);
    let induction_count: i64 = sqlx::query_scalar("SELECT count(*) FROM pm.induction")
        .fetch_one(&pool).await?;
    let draw_count: i64 = sqlx::query_scalar("SELECT count(*) FROM pm.draw").fetch_one(&pool).await?;
    let expected = ordered(sqlx::query_file!("assets/sql/diagrams/expected.sql").fetch_all(&pool).await?);
    let grain = ordered(sqlx::query_file!("assets/sql/diagrams/lane_grain.sql").fetch_all(&pool).await?);
    let elims = ordered(sqlx::query_file!("assets/sql/diagrams/eliminations.sql").fetch_all(&pool).await?);
    let levels = ordered(sqlx::query_file!("assets/sql/diagrams/levels.sql").fetch_all(&pool).await?);
    // Each layer's `rank`, carried into the file. `examples/rendering/main.rs` reads only the BPMN,
    // because a cache derived from the source rather than the file is a stale cache, and the rank
    // cannot be recovered from what BPMN can express: `calledElement` names a process, so the call
    // graph links filing to filing while the composition links layer to layer.
    //
    // `documentation` is the only home the schema allows, and it is untyped text. It carries the
    // words and not the claim, as `diagrams/domain_objects.sqlc` says of it. A tool cannot act on
    // this; a reader can. `extensionElements` would look like structure and be none, which that
    // roster refuses by name.
    let ranks = ordered(sqlx::query_file!("assets/sql/rank/evaluation_order.sql").fetch_all(&pool).await?);
    let objects = ordered(sqlx::query_file!("assets/sql/diagrams/domain_objects.sql").fetch_all(&pool).await?);
    // Which graph this program draws, declared, and the measurement that allows it. Three graphs
    // compose in this model and only one grouping can be a diagram's nesting, so
    // `examples/graphs/main.rs` makes the graph a slot. This program cannot: it emits one document
    // per filing, and cutting a graph by filing is not free.
    let decomposition = ordered(sqlx::query_file!("assets/sql/rank/decomposition.sql").fetch_all(&pool).await?);
    let governance = ordered(sqlx::query_file!("assets/sql/diagrams/ungoverned.sql").fetch_all(&pool).await?);

    // notation -> filing, which is what an `import` resolves.
    // The notation is nullable in `assets/ddl/schema.ddl`, because a filing may decline to name
    // itself and say why, so sqlx types it `Option<String>`. That makes this program say what it
    // means by the absence: a filing with no notation is nothing an `import` can name, so it has
    // no entry here.
    let by_notation: BTreeMap<&str, &str> = notations
        .iter()
        .filter_map(|n| Some((n.notation.as_deref()?, n.filing.as_str())))
        .collect();
    let notation_of: BTreeMap<&str, &str> =
        by_notation.iter().map(|(n, f)| (*f, *n)).collect();

    // The pointer every sentence carries, keyed by the thing it is about. A `documentation`
    // element is untyped text, and BPMN gives it no provenance attribute, so the citation goes in
    // the prose, as `assets/sql/*.sql` carries its `--` line in a comment.
    //
    // It panics rather than leaving the pointer out. A missing pointer is a sentence in the file
    // that nothing attributes, and writing the sentence anyway would leave facts in these
    // documents with no page and no source.
    let states: BTreeMap<&str, &str> = annotated
        .iter()
        .filter_map(|a| Some((a.annotated.as_deref()?, a.states.as_deref()?)))
        .collect();
    let cite = |kind: &str| -> String {
        format!(
            " [assets/sqlc/{}]",
            states.get(kind).unwrap_or_else(|| panic!(
                "diagrams/annotated.sqlc names no source for `{kind}`, so this sentence would \
                 reach the artifact with nothing to attribute it to"
            ))
        )
    };

    // ------------------------------------------------------------------
    // Wiped, as `assets/sql/` is wiped. A stale document is worse than none: it is a claim about
    // a model that has moved.
    // ------------------------------------------------------------------
    if Path::new(OUT).exists() {
        fs::remove_dir_all(OUT)?;
    }
    fs::create_dir_all(OUT)?;

    for f in &filings {
        let filing = f.filing.as_str();

        // The imports this document owes: every notation it reaches through a part or through an
        // elimination. Two references reach out of a filing, not one: a part, and an
        // `asrt:Elimination/between`. In this corpus every document a `between` names is already
        // reached by a part, so the union changes no count; that is luck rather than
        // construction, and a count cannot tell the two apart.
        let mut imports: Vec<&str> = parts
            .iter()
            .filter(|p| p.composition == filing)
            .map(|p| p.part_notation.as_str())
            .chain(
                attributions
                    .iter()
                    .filter(|b| b.composition == filing)
                    .map(|b| b.notation.as_str()),
            )
            .filter(|n| by_notation.get(n).copied() != Some(filing))
            .collect();
        imports.sort_unstable();
        imports.dedup();

        let mut x = String::new();
        writeln!(x, r#"<?xml version="1.0" encoding="UTF-8"?>"#)?;
        // The provenance line, and it is a comment on purpose: the `--` line that survives into
        // generated SQL is a comment too. It is for the reader of the file, and a schema element
        // would be this emitter inventing a field.
        writeln!(x, "<!-- Generated by examples/diagramming from the loaded documents. \
                     Do not edit by hand.")?;
        writeln!(x, "     Source: the filing `{}`. Change the filing, not this file.",
                 esc(filing))?;
        writeln!(x, "     Laws: assets/sqlc/diagrams/roster.sqlc -->")?;
        let target = notation_of.get(filing).copied().unwrap_or(filing);
        write!(x, r#"<definitions xmlns="{BPMN_NS}""#)?;
        // A QName with no prefix resolves to the default namespace, which here is BPMN's own.
        // `association/@sourceRef` is a QName, so a same-document reference to a lane needs a
        // prefix bound to this document's targetNamespace, or it names a BPMN element instead. The
        // foreign prefixes f0..fN do this for `calledElement`; `tns` is the same binding for a
        // reference that stays inside the document, which is what a coupling needs.
        write!(x, "\n             xmlns:tns=\"{}\"", esc(target))?;
        write!(x, "\n             xmlns:bpmndi=\"{DI_NS}\"\n             xmlns:dc=\"{DC_NS}\"")?;
        write!(x, "\n             xmlns:di=\"{DI_BASE_NS}\"")?;
        for (i, n) in imports.iter().enumerate() {
            write!(x, "\n             xmlns:f{i}=\"{}\"", esc(n))?;
        }
        writeln!(x, "\n             targetNamespace=\"{}\"\n             id=\"{}\">",
                 esc(target), id("defs", &[filing]))?;

        for n in &imports {
            writeln!(x, r#"  <import importType="{BPMN_NS}" namespace="{}" location="{}.bpmn"/>"#,
                     esc(n), esc(by_notation[n]))?;
            }

        // A `category` is a `rootElement`, so it sits beside the collaboration and the process
        // rather than inside either, and its values are addressable by QName from any document
        // that imports this one. Nothing here crosses a document; the addressability is BPMN's.
        let mine_cats: Vec<&str> =
            categories.iter().filter(|c| c.filing == filing).map(|c| c.layer.as_str()).collect();
        if !mine_cats.is_empty() {
            writeln!(x, "  <category id=\"{}\" name=\"induction\">", id("cat", &[filing]))?;
            writeln!(x, "    <documentation>pm:Induction: which layers each operation induces \
                         demand into. These groups may overlap: an operation that induces demand \
                         into several layers is in the group of each.{}</documentation>",
                     cite("category"))?;
            for layer in &mine_cats {
                writeln!(x, "    <categoryValue id=\"{}\" value=\"{}\"/>",
                         id("cv", &[filing, layer]), esc(layer))?;
            }
            writeln!(x, "  </category>")?;
        }

        let proc_id = id("proc", &[filing]);
        writeln!(x, "  <collaboration id=\"{}\">", id("collab", &[filing]))?;
        writeln!(x, "    <participant id=\"{}\" name=\"{}\" processRef=\"{proc_id}\"/>",
                 id("pool", &[filing]), esc(filing))?;
        writeln!(x, "  </collaboration>")?;

        writeln!(x, "  <process id=\"{proc_id}\" isExecutable=\"false\">")?;
        writeln!(x, "    <documentation>pm:Stack of `{}`. This document shows how the stack's \
                     layers and operations connect, and none of its figures. How much of the \
                     system the stack holds is stated on the laneSet.{}</documentation>",
                 esc(filing), cite("document"))?;
        for c in citations.iter().filter(|c| c.composition == filing) {
            writeln!(x, "    <documentation>filed under: {}. The four typed fields (taxonomy, \
                         instrument, clause, version) arrive here as one string: a reader can \
                         follow the citation, and a tool cannot resolve it.{}</documentation>",
                     esc(c.cited.as_deref().unwrap_or("")), cite("process, the citation"))?;
        }

        // One lane set, and the choice is the finding. The draw and the induction both relate
        // operations to layers over one process, and BPMN would hold each as a `laneSet`.
        // Emitting both would give every layer two lane elements with nothing but a matching
        // `name` to say they are the same layer, so the shared key `(filing, layer)` would be lost
        // in the rendering. One lane set is what a modeller files: it is the draw, and the
        // induction is what falls off. The list at the end carries it, with `decider`.
        let mine: Vec<&str> =
            layers.iter().filter(|l| l.filing == filing).map(|l| l.layer.as_str()).collect();

        // The nesting, keyed by layer within this filing. A local part makes its target a child
        // lane; a foreign one stays a flow node, because a lane cannot live in another document.
        let mut kids: BTreeMap<String, Vec<String>> = BTreeMap::new();
        let mut nested: std::collections::BTreeSet<&str> = std::collections::BTreeSet::new();
        for p in parts.iter().filter(|p| p.composition == filing && p.part_filing == filing) {
            kids.entry(p.composed_layer.clone()).or_default().push(p.part_layer.clone());
            nested.insert(p.part_layer.as_str());
        }
        let rank_of: BTreeMap<String, i32> = ranks
            .iter()
            .filter(|r| r.filing == filing)
            .map(|r| (r.layer.clone(), r.rank.unwrap_or(0)))
            .collect();
        let mut nodes: BTreeMap<String, Vec<String>> = BTreeMap::new();
        for d in draws.iter().filter(|d| d.filing == filing) {
            nodes.entry(d.layer.clone()).or_default().push(id("task", &[filing, &d.operation]));
        }
        for p in parts.iter().filter(|p| p.composition == filing && p.part_filing != filing) {
            nodes.entry(p.composed_layer.clone()).or_default().push(
                id("call", &[filing, &p.composed_layer, &p.part_filing, &p.part_layer]));
        }

        // The search sits on the `laneSet`, because the lane set is the partition the search is
        // about. *Did anybody test whether these layers move together* is a question about the
        // stack and not about any one lane, and `tLaneSet` extends `tBaseElement`, so
        // `documentation` is available and already spent. No new element is owed for this.
        let answer = searches
            .iter()
            .find(|s| s.filing == filing)
            .and_then(|s| s.answer.as_deref())
            .unwrap_or("stated");
        writeln!(x, "    <laneSet id=\"{}\" name=\"draw\">", id("lanes", &[filing]))?;
        // Two documentation elements, one per fact, because `tBaseElement/documentation` is
        // `maxOccurs="unbounded"`. A stack states its scope and its coupling search, two different
        // answers about the same partition, so folding them into one string would make each
        // unreadable and neither countable.
        let sc = scopes.iter().find(|s| s.filing == filing);
        writeln!(x, "      <documentation>scope: {}. `complete` says there are no other layers \
                     of this system, `scoped` says somebody established what lies outside and \
                     left it out, `unbounded` says nobody looked. A lane set has no way to say \
                     which, so this sentence is the only place it is said. The filing's \
                     reason: {}{}</documentation>",
                 sc.and_then(|s| s.extent.as_deref()).unwrap_or("typed absent"),
                 esc(sc.and_then(|s| s.basis.as_deref()).unwrap_or("not stated")),
                 cite("lane set, the scope"))?;
        writeln!(x, "      <documentation>coupling search: {answer}. `unmeasured` means nobody \
                     looked, `none` means somebody looked and found no dependence, \
                     `notApplicable` means there is no pair to couple, and `stated` means the \
                     dependences drawn here. An absent line is not independence.{}</documentation>",
                 cite("lane set, the coupling search"))?;
        for layer in mine.iter().filter(|l| !nested.contains(*l)) {
            lane(&mut x, 6, filing, layer, &kids, &rank_of, &nodes, &cite("lane"))?;
        }
        writeln!(x, "    </laneSet>")?;

        // The member declares the groups it is in, which is why this fits. A lane collects its
        // members and can collect each one once; a `categoryValue` collects nobody, so the flow
        // node says which categories it is in and may say it as many times as it likes.
        // `tFlowElement`'s sequence puts `categoryValueRef` first, before any activity content.
        for o in ops.iter().filter(|o| o.filing == filing) {
            let refs: Vec<&str> = cat_members
                .iter()
                .filter(|m| m.filing == filing && m.operation == o.label)
                .map(|m| m.layer.as_str())
                .collect();
            // `tBaseElement` puts `documentation` first, before `categoryValueRef` on
            // `tFlowElement`, so the notation position is written above the categories, and the
            // element is self-closing only when it owes neither.
            let crossing = crossings
                .iter()
                .find(|c| c.filing == filing && c.label == o.label);
            // Both arms reach the page, because `notationPosition` is required and the absence is
            // the ordinary answer. A task carrying nothing would read as *this model does not
            // reach the notation*, where the filing says which of three things it means. The same
            // argument as the coupling search on the lane set.
            let unstated = o.foreign_absent.as_deref();
            if refs.is_empty() && crossing.is_none() && unstated.is_none() {
                writeln!(x, "    <task id=\"{}\" name=\"{}\"/>",
                         id("task", &[filing, &o.label]), esc(&o.label))?;
            } else {
                writeln!(x, "    <task id=\"{}\" name=\"{}\">",
                         id("task", &[filing, &o.label]), esc(&o.label))?;
                if let Some((notation, node)) = crossing.and_then(|c| {
                    // The relation restricts to the operations that filed one, so a NULL here
                    // would mean the restriction stopped restricting, not that this operation
                    // names nothing. Dropping the sentence silently is how a fact comes to be in
                    // the model and on no page.
                    Some((c.foreign_notation.as_deref()?, c.foreign_id.as_deref()?))
                }) {
                    writeln!(x, "      <documentation>notation position: {} / {}. The id names \
                                 a node in the filer's own process document, written in that \
                                 notation, and not an element of this one. No authority \
                                 publishes that document, so the id resolves by agreement, \
                                 never by lookup.{}</documentation>",
                             esc(notation), esc(node),
                             cite("task, the notation position"))?;
                } else if let Some(reason) = unstated {
                    // The reason is the model's voice, and the gloss is the emitter's. The word
                    // comes from the filing; the sentence saying what the three words mean is true
                    // of this schema whatever any corpus holds, so it may be a literal.
                    writeln!(x, "      <documentation>notation position: none stated, and the \
                                 filing says why: {}. `none` means somebody looked and this \
                                 operation is in no process notation, `unmeasured` means a \
                                 notation exists and nobody has found this operation in it, \
                                 `notApplicable` means this filing has no notation to point \
                                 into. An absent position is not a gap in the filing: the filing \
                                 says which of the three it is.{}</documentation>",
                             esc(reason), cite("task, no notation position"))?;
                }
                for layer in refs {
                    writeln!(x, "      <categoryValueRef>{}</categoryValueRef>",
                             id("cv", &[filing, layer]))?;
                }
                writeln!(x, "    </task>")?;
            }
        }

        for p in parts.iter().filter(|p| p.composition == filing) {
            let (cl, pf, pl, pn) = (
                p.composed_layer.as_str(), p.part_filing.as_str(),
                p.part_layer.as_str(), p.part_notation.as_str(),
            );
            // A foreign part is a call. It crosses a document, which is why it needs an import,
            // and the QName prefix is what makes `calledElement` resolvable at all.
            //
            // A local part is not a flow node at all. It is a nested lane, written by `lane()`
            // above, because a fusion's parts partition the composed layer rather than sitting
            // inside it as activities. That is what keeps it at layer grain.
            if pf == filing {
                let _ = (cl, pl);
            } else {
                let i = imports.iter().position(|n| *n == pn).expect("a foreign part imports");
                writeln!(x, "    <callActivity id=\"{}\" name=\"{} &lt;- {}/{}\" calledElement=\"f{i}:{}\"/>",
                         id("call", &[filing, cl, pf, pl]), esc(cl), esc(pf), esc(pl),
                         id("proc", &[pf]))?;
            }
        }

        // The legend, floating and unattached. A `textAnnotation` is an artifact in BPMN's sense
        // and may stand alone; attaching it would spend `association` a second way, the collision
        // that rules that element out for the composition. The two consolidation filings carry
        // coupling lines, and a reader could not tell which dotted line was which.
        //
        // A note is owed wherever the notation's default reading is wrong, and nowhere else. A
        // pool reads as *the system*, an absent line reads as independence, a dotted arrow reads as
        // flow, a dashed box reads as a container, and an empty lane reads as an idle part of it. A
        // legend for a glyph the page does not carry is noise.
        //
        // The fifth is the one a correct drawing produces by being complete. The other four come
        // from a glyph meaning something else here; that one comes from there being no glyph, so
        // the emitter cannot prevent it and can only say what it means.
        for l in legends.iter().filter(|l| l.filing.as_deref() == Some(filing)) {
            let body = match l.note.as_deref().unwrap_or("") {
                "scope" => format!(
                    "Scope: {}. The pool is the whole system only when the filing says `complete`.",
                    sc.and_then(|s| s.extent.as_deref()).unwrap_or("typed absent")),
                "search" => format!(
                    "Coupling search: {answer}. An absent dependence line is not independence."),
                // The continuations are escaped, and that is not a matter of style. Without the
                // `\\` a wrapped literal keeps its own indentation, and the sentence reaches the
                // page with a run of spaces in the middle, invisible in the source and in the
                // BPMN, and drawn.
                "dependence" => "A dotted arrow between two lanes is a dependence somebody \
                                 observed: not a supply edge, and never evidence for a \
                                 fusion.".to_string(),
                "cover" => "A dashed box is a group, not a container: it gathers the operations \
                            that induce demand into one layer, and an operation may be in \
                            several.".to_string(),
                "lane" => "An empty lane is a layer nothing draws on, not an idle one: every \
                           layer carries figures, and BPMN has no glyph to show them.".to_string(),
                other => format!("{other}"),
            };
            // The one place the pointer is read off the row rather than the kind. A legend is the
            // only sentence here a person reads off the picture, so the relation it states travels
            // with it: `diagrams/legends.sqlc` unions one arm per note, and each names its own.
            let body = format!("{body} [assets/sqlc/{}]",
                               l.states.as_deref().expect("a legend names the relation it states"));
            writeln!(x, "    <textAnnotation id=\"{}\">", id("note", &[filing, l.note.as_deref().unwrap_or("")]))?;
            writeln!(x, "      <text>{}</text>", esc(&body))?;
            writeln!(x, "    </textAnnotation>")?;
        }

        // The glyph, and it comes last because `tProcess` puts `artifact` after `flowElement`. A
        // `group` is to `categoryValueRef` what a `lane` is to `flowNodeRef`: the drawn shape of a
        // membership held elsewhere. Without it the induction is readable and invisible, which in
        // this pipeline is the same as not being emitted.
        for layer in &mine_cats {
            writeln!(x, "    <group id=\"{}\" categoryValueRef=\"{}\"/>",
                     id("grp", &[filing, layer]), id("cv", &[filing, layer]))?;
        }

        // The coupling, the fact that would show the model wrong. `tAssociation` extends `tArtifact` with `sourceRef`
        // and `targetRef` as required, unconstrained QNames, so it is a general typed edge and two
        // lanes are a legal pair. That it attaches a `textAnnotation` is what an association is
        // for, not all it can hold.
        //
        // Direction `One`, and the arrowhead is safe here for a reason that can be checked. BPMN
        // glosses it as a direction of flow, and a coupling is a dependence, so the risk is a
        // reader taking it for a supply edge. The composition is drawn as containment and as
        // nodes and never as an edge, so this is the only line between two things in the whole
        // emitted notation, and there is nothing for it to be confused with. If the composition is
        // ever drawn as an edge, this argument no longer holds and the direction has to be
        // reconsidered.
        for d in deps.iter().filter(|d| d.filing == filing) {
            writeln!(x, "    <association id=\"{}\" sourceRef=\"tns:{}\" targetRef=\"tns:{}\" \
                         associationDirection=\"One\">",
                     id("dep", &[filing, &d.from_layer, &d.to_layer]),
                     id("lane", &[filing, &d.from_layer]), id("lane", &[filing, &d.to_layer]))?;
            writeln!(x, "      <documentation>an observed dependence: relieving `{}` moved `{}`. \
                         It is not a supply edge, and never evidence for a fusion. What was \
                         observed, and how strongly, is not in this document.{}</documentation>",
                     esc(&d.from_layer), esc(&d.to_layer), cite("dependence"))?;
            writeln!(x, "    </association>")?;
        }

        writeln!(x, "  </process>")?;

        // The diagram's own place in the document. `tDefinitions` puts `bpmndi:BPMNDiagram` last,
        // after the root elements, and a document that declared nothing here would leave the SVG
        // stage to invent coordinates: the same model laid out two ways, with nothing tying them.
        //
        // The document declares its layout, and the SVG draws what is declared, as
        // `examples/rendering/main.rs`'s own header says of itself: drawn from the generated file
        // rather than computed beside it.
        //
        // Every drawn element needs one, not only the basic shapes. Declaring a shape per pool,
        // lane and flow node and nothing else would leave every `group`, `association` and
        // `textAnnotation` with no interchange at all, lost to anybody but the renderer beside
        // this program: absent DI is not an error, it is nothing drawn.
        //
        // Filing a derived coordinate in a relation is what `diagrams/shapes.sqlc` refuses, which
        // is why it carries no x or y for anything; deriving one into a generated file is what
        // both stages do for every box here. So the derivation belongs upstream of the document
        // that carries it, and the same numbers reach both stages instead of one recomputing them
        // from the other's output. Nothing new is filed.
        //
        // The geometry is `examples/rendering/main.rs`'s own, on purpose, so the picture does not
        // move: a group is the bounding box of its members widened by 6, a dependence runs out of
        // the source lane to a gutter 26 left of the leftmost of the pair and back in, and the
        // notes stack under the pool at 30 apiece.
        let mut shapes: Vec<(String, usize, usize, usize, usize)> = Vec::new();
        let mut ly = 46usize;
        for layer in mine.iter().filter(|l| !nested.contains(*l)) {
            place(&mut shapes, &kids, &nodes, filing, layer, 120, ly, WIDTH - 140);
            ly += lane_height(&kids, &nodes, layer) + 6;
        }
        let pool_h = (ly - 36).max(48);
        writeln!(x, "  <bpmndi:BPMNDiagram id=\"{}\">", id("diagram", &[filing]))?;
        writeln!(x, "    <bpmndi:BPMNPlane id=\"{}\" bpmnElement=\"tns:{}\">",
                 id("plane", &[filing]), id("collab", &[filing]))?;
        writeln!(x, "      <bpmndi:BPMNShape id=\"{}\" bpmnElement=\"tns:{}\" isHorizontal=\"true\">",
                 id("shape", &[filing, "pool"]), id("pool", &[filing]))?;
        writeln!(x, "        <dc:Bounds x=\"8\" y=\"36\" width=\"{}\" height=\"{pool_h}\"/>", WIDTH - 16)?;
        writeln!(x, "      </bpmndi:BPMNShape>")?;
        for (sid, sx, sy, sw, sh) in &shapes {
            writeln!(x, "      <bpmndi:BPMNShape id=\"{}\" bpmnElement=\"tns:{sid}\">",
                     id("shape", &[filing, sid]))?;
            writeln!(x, "        <dc:Bounds x=\"{sx}\" y=\"{sy}\" width=\"{sw}\" height=\"{sh}\"/>")?;
            writeln!(x, "      </bpmndi:BPMNShape>")?;
        }

        // The group, as the box around what it holds. A `group` carries no membership itself: the
        // flow nodes name it through `categoryValueRef`, so its box is the union of theirs.
        let box_of = |wanted: &str| -> Option<(usize, usize, usize, usize)> {
            shapes.iter().find(|(sid, ..)| sid == wanted).map(|&(_, a, b, c, d)| (a, b, c, d))
        };
        for layer in &mine_cats {
            let ms: Vec<(usize, usize, usize, usize)> = cat_members
                .iter()
                .filter(|m| m.filing == filing && &m.layer == *layer)
                .map(|m| box_of(&id("task", &[filing, &m.operation])))
                .flatten()
                .collect();
            if ms.is_empty() {
                continue;
            }
            let x0 = ms.iter().map(|b| b.0).min().unwrap().saturating_sub(6);
            let y0 = ms.iter().map(|b| b.1).min().unwrap().saturating_sub(6);
            let x1 = ms.iter().map(|b| b.0 + b.2).max().unwrap() + 6;
            let y1 = ms.iter().map(|b| b.1 + b.3).max().unwrap() + 6;
            writeln!(x, "      <bpmndi:BPMNShape id=\"{}\" bpmnElement=\"tns:{}\">",
                     id("shape", &[filing, &id("grp", &[filing, layer])]),
                     id("grp", &[filing, layer]))?;
            writeln!(x, "        <dc:Bounds x=\"{x0}\" y=\"{y0}\" width=\"{}\" height=\"{}\"/>",
                     x1 - x0, y1 - y0)?;
            writeln!(x, "      </bpmndi:BPMNShape>")?;
        }

        // The notes, in a band under the pool. An artifact may sit outside a participant, and
        // these belong outside it: each says how the picture above must not be read.
        for (i, l) in legends.iter().filter(|l| l.filing.as_deref() == Some(filing)).enumerate() {
            let ny = 44 + pool_h + i * 30;
            writeln!(x, "      <bpmndi:BPMNShape id=\"{}\" bpmnElement=\"tns:{}\">",
                     id("shape", &[filing, &id("note", &[filing, l.note.as_deref().unwrap_or("")])]),
                     id("note", &[filing, l.note.as_deref().unwrap_or("")]))?;
            writeln!(x, "        <dc:Bounds x=\"20\" y=\"{ny}\" width=\"{}\" height=\"28\"/>",
                     WIDTH - 40)?;
            writeln!(x, "      </bpmndi:BPMNShape>")?;
        }

        // Every shape first, then every edge, though `di:Plane` does not require it. Its content
        // model is one repeated `di:DiagramElement` substitution group, so a shape and an edge may
        // legally interleave. No tool emits them that way, and a document that only looks legal
        // is a doubt worth removing when grouping them costs nothing.
        //
        // The dependence, as a route rather than a box. `bpmndi:BPMNEdge` takes `di:waypoint`, two
        // at minimum; four describe the gutter run, which keeps the line outside both lanes so a
        // reader cannot mistake it for something inside one.
        for d in deps.iter().filter(|d| d.filing == filing) {
            let (Some((ax, ay, _, ah)), Some((bx, by, _, bh))) =
                (box_of(&id("lane", &[filing, &d.from_layer])),
                 box_of(&id("lane", &[filing, &d.to_layer]))) else { continue };
            let (y0, y1) = (ay + ah / 2, by + bh / 2);
            let gx = ax.min(bx).saturating_sub(26);
            writeln!(x, "      <bpmndi:BPMNEdge id=\"{}\" bpmnElement=\"tns:{}\">",
                     id("edge", &[filing, &d.from_layer, &d.to_layer]),
                     id("dep", &[filing, &d.from_layer, &d.to_layer]))?;
            for (wx, wy) in [(ax, y0), (gx, y0), (gx, y1), (bx, y1)] {
                writeln!(x, "        <di:waypoint x=\"{wx}\" y=\"{wy}\"/>")?;
            }
            writeln!(x, "      </bpmndi:BPMNEdge>")?;
        }
        writeln!(x, "    </bpmndi:BPMNPlane>")?;
        writeln!(x, "  </bpmndi:BPMNDiagram>")?;

        // Emitted here, after the diagram, because `tDefinitions` is an `xsd:sequence`: import*,
        // extension*, rootElement*, bpmndi:BPMNDiagram*, relationship*. The order is normative, so
        // a `relationship` ahead of the diagram is a document a schema processor refuses.
        //
        // No count in this repository would notice a wrong order: `roster.sqlc` counts elements,
        // and the read-back laws below find the elements wherever they sit, so only validating
        // the output against the OMG schemas sees it. The documents that emit a `relationship`
        // are also the ones carrying a `callActivity`, so a processor that stopped at an ordering
        // error would never reach a cross-document call.
        //
        // The composition at layer grain, as a reference rather than a name. `tDefinitions` puts
        // `relationship` last, after the root elements and the diagrams, which is where a fact
        // about the document rather than about its contents belongs. It is not a glyph and never
        // will be: no diagram shows it, so this gives the fact to a tool and leaves the reader the
        // `callActivity` name it already had.
        //
        // `type` is required, and that is the difference from an `association`. An association
        // carries no name and no type, so a second use of it would make a dependence and a
        // composition indistinguishable in the documents that hold both.
        for d in descents.iter().filter(|d| d.composition == filing) {
            let i = imports.iter().position(|n| *n == d.part_notation).expect("a foreign part imports");
            writeln!(x, "  <relationship type=\"process-modulus:part\" direction=\"Forward\">")?;
            writeln!(x, "    <documentation>a composed layer and the layer it is composed from. \
                         `calledElement` names a process, so the call beside this one is at \
                         document grain; this is the same fact at layer grain.{}</documentation>",
                     cite("relationship"))?;
            writeln!(x, "    <source>tns:{}</source>", id("lane", &[filing, &d.composed_layer]))?;
            writeln!(x, "    <target>f{i}:{}</target>", id("lane", &[&d.part_filing, &d.part_layer]))?;
            writeln!(x, "  </relationship>")?;
        }

        // The second type, which justifies the choice of element. `association` is ruled out for
        // the composition because it carries no type, and a second use would make two facts
        // indistinguishable. `tRelationship/@type` is required, so a second relation costs nothing
        // but a different string, and the laws filter on it.
        for b in attributions.iter().filter(|b| b.composition == filing) {
            let i = imports.iter().position(|n| *n == b.notation).expect("a between imports");
            writeln!(x, "  <relationship type=\"process-modulus:elimination-between\" direction=\"Forward\">")?;
            writeln!(x, "      <documentation>a composed layer, and a layer of another document \
                         that the composer says the double counting runs against. It is not a \
                         part: nothing is composed from it, and the size of the overlap is not \
                         in this document.{}</documentation>",
                     cite("relationship, an attribution"))?;
            writeln!(x, "    <source>tns:{}</source>", id("lane", &[filing, &b.composed_layer]))?;
            writeln!(x, "    <target>f{i}:{}</target>",
                     id("lane", &[&b.resolved_filing, &b.layer]))?;
            writeln!(x, "  </relationship>")?;
        }
        writeln!(x, "</definitions>")?;
        fs::write(format!("{OUT}/{filing}.bpmn"), x)?;
    }

    // ------------------------------------------------------------------
    // The precondition of the whole mapping, checked before anything is written. A layer is a
    // lane only because `(filing, layer)` is the coarsest key nothing refines. Every reference
    // into the layer dimension names the whole layer; one that named a piece of a layer would move
    // the partition down a level, and every lane below would be wrong.
    // ------------------------------------------------------------------
    let refines: Vec<&str> = grain
        .iter()
        .filter(|g| g.whole != Some(true))
        .map(|g| g.referrer.as_deref().unwrap_or("?"))
        .collect();
    // ------------------------------------------------------------------
    // This program draws the layer graph, and that is a measured choice: cut by filing, the layer
    // graph loses none of its loops, and `rank/decomposition.sqlc` is the measurement.
    //
    // The unit graph's only loop spans two filings. `GPU-hour -> node-hour` and
    // `node-hour -> GPU` are filed in `every-unit-cycle`; the edge closing them,
    // `GPU -> GPU-hour`, is filed in `merge-holding-composition`. So the fixture named
    // `every-unit-cycle` holds no loop on its own, and a per-filing unit diagram would show two
    // edges, no loop, and nothing for `checks/conversion_cycle_does_not_close` to be about: well
    // formed, valid, and quietly missing the one property it was drawn to show.
    //
    // So the choice is stated and checked rather than hardcoded. Making the graph a slot without
    // this measurement would let somebody pick a graph that lies. Surviving the cut is a
    // precondition and never a reason: `claimants` survives trivially, with no edges at all.
    // ------------------------------------------------------------------
    const EMITS_GRAPH: &str = "layers";
    let licensed = decomposition
        .iter()
        .find(|d| d.graph.as_deref() == Some(EMITS_GRAPH))
        .ok_or("rank/decomposition.sqlc does not measure the graph this program draws")?;
    println!("The graph this program draws, and whether cutting it by filing is free");
    for d in &decomposition {
        println!("   {:<7} loops corpus-wide {}   summed per filing {}   {}",
                 d.graph.as_deref().unwrap_or("?"),
                 d.corpus_wide.unwrap_or(-1), d.summed_per_filing.unwrap_or(-1),
                 if d.survives_the_cut == Some(true) { "survives the cut" }
                 else { "the cut breaks a loop" });
    }
    assert!(
        decomposition.len() > 1,
        "only one graph is measured, so this law cannot discriminate between a graph that \
         survives the cut and one that does not"
    );
    assert!(
        licensed.survives_the_cut == Some(true),
        "this program emits one document per filing and draws `{EMITS_GRAPH}`, which has {} loops \
         corpus-wide and {} summed per filing: cutting it by filing breaks a loop, so \
         every document would validate and none would carry the property the graph is for",
        licensed.corpus_wide.unwrap_or(-1), licensed.summed_per_filing.unwrap_or(-1)
    );
    println!("   `{EMITS_GRAPH}` survives the cut, and that is why this");
    println!("      program does not offer the graph as a slot the way examples/graphs/main.rs does.\n");

    println!("The partition, before anything is drawn");
    println!("   {} references into the layer dimension, {} of them naming a piece of a layer",
             grain.len(), refines.len());
    assert!(
        refines.is_empty(),
        "something refines a layer, so a lane is not a layer and the mapping moves down a \
         level: {refines:?}"
    );

    println!("\nEmitted into {OUT}/");
    println!("   {} definitions documents, each complete and openable alone", filings.len());

    // ------------------------------------------------------------------
    // Count the file, not the intention. A counter incremented beside each `writeln!` counts what
    // this program meant to write. Reading the files back counts what is on disk, and the two
    // differ whenever a write lands in the wrong document, a branch is skipped, or the emitter is
    // edited without its counter. It is the reason a number in prose rots: only a program that
    // reads the file is reporting on the file.
    // ------------------------------------------------------------------
    let mut written = String::new();
    let mut docs = 0;
    for e in fs::read_dir(OUT)?.flatten() {
        written.push_str(&fs::read_to_string(e.path())?);
        docs += 1;
    }
    let count = |needle: &str| written.matches(needle).count() as i64;
    let emitted: BTreeMap<&str, i64> = BTreeMap::from([
        ("pools", count("<participant ")),
        ("lanes", count("<lane ")),
        ("tasks", count("<task ")),
        ("calls", count("<callActivity ")),
        ("nestings", count("<childLaneSet ")),
        ("categories", count("<category ")),
        ("category_values", count("<categoryValue ")),
        ("groups", count("<group ")),
        ("induced_into", count("<categoryValueRef>")),
        ("dependences", count("<association ")),
        ("descents", count("type=\"process-modulus:part\"")),
        ("attributions", count("type=\"process-modulus:elimination-between\"")),
        ("legends", count("<textAnnotation ")),
        ("diagrams", count("<bpmndi:BPMNDiagram ")),
        ("planes", count("<bpmndi:BPMNPlane ")),
        ("shapes", count("<bpmndi:BPMNShape ")),
        ("edges", count("<bpmndi:BPMNEdge ")),
        ("scopes", count("scope: ")),
        ("citations", count("filed under: ")),
        ("namespaces", count("targetNamespace=\"")),
        ("imports", count("<import ")),
        ("in_a_lane", count("<flowNodeRef>")),
        // The containers, each counted on its own. The laws above count the leaves of the
        // rendering, so without these the emitter could write two `laneSet`s per process and
        // every one of them would still pass. One law per container, because they are different
        // defects: a single law over the smallest of them could see a container appearing too few
        // times and never too many.
        ("definitions", count("<definitions ")),
        ("collaboration", count("<collaboration ")),
        ("process", count("<process ")),
        ("lane_set", count("<laneSet ")),
        ("documentation", count("<documentation>")),
    ]);

    // The closure: every element kind on disk is either counted by a law or is a container. A
    // law that counts some elements says nothing about the ones nobody listed, and "nothing
    // appears that is not in the model" cannot be checked one element at a time. This is the only
    // assertion here that grows when the emitter does.
    let containers = ["definitions", "collaboration", "process", "laneSet", "documentation",
                      "BPMNDiagram", "BPMNPlane", "BPMNEdge"];
    let counted = ["participant", "lane", "task", "callActivity", "childLaneSet", "import",
                   "flowNodeRef", "category", "categoryValue", "group", "categoryValueRef",
                   "association", "relationship", "source", "target", "textAnnotation", "text",
                   "BPMNShape", "Bounds", "waypoint"];
    let mut written_kinds: Vec<&str> = Vec::new();
    let mut rest = written.as_str();
    while let Some(i) = rest.find('<') {
        rest = &rest[i + 1..];
        // The local name, not the prefix. Stopping at the first character that is not a letter or
        // a digit would report `bpmndi` and `dc` as element kinds in a namespaced document. A
        // closure over element kinds has to know what an element kind is.
        let end = rest
            .find(|c: char| !c.is_ascii_alphanumeric() && c != ':')
            .unwrap_or(rest.len());
        let kind = rest[..end].rsplit(':').next().unwrap_or("");
        if !kind.is_empty() && !written_kinds.contains(&kind) {
            written_kinds.push(kind);
        }
    }
    let ungoverned: Vec<&&str> = written_kinds
        .iter()
        .filter(|k| !containers.contains(k) && !counted.contains(k))
        .collect();
    assert!(
        ungoverned.is_empty(),
        "an element kind is on disk that no law counts and no container list names, so it could \
         appear any number of times and nothing would notice: {ungoverned:?}"
    );
    println!("   {} element kinds written, {} counted by a law, {} containers, 0 ungoverned",
             written_kinds.len(), counted.len(), containers.len());
    assert_eq!(docs, filings.len(), "one document per filing, counted on disk");

    // ------------------------------------------------------------------
    // The attribution law, and it is not a count, because it cannot be one. Every law above asks
    // how many of an element the file carries, and a sentence is not that kind of fact: every
    // document can carry exactly the right number of `documentation` elements, each saying
    // something no relation states, with the count exact the whole way. The only question worth
    // asking of prose in a generated file is what states it.
    //
    // Three obligations, and the third is the one with teeth. A pointer must be there, it must
    // resolve to a relation in this tree, and it must name a relation this program read. Without
    // the third a citation is decorative: an emitter free to cite anything cites what sounds
    // right, which is the `invents` state with a file name on it. Reading the program's own source
    // makes the file's provenance checkable against the thing that produced it, rather than
    // against a second list that drifts beside it; it is `examples/compositions/main.rs`'s idiom:
    // the source tree is a fact.
    //
    // It governs `text` as well as `documentation`, and the `text` sentences matter most. A
    // `documentation` element is read by a tool that could have opened the database anyway; a
    // `textAnnotation` is read by a person holding a picture, who has no other route back.
    // ------------------------------------------------------------------
    let cited_in = |text: &str| -> Vec<String> {
        let mut out = Vec::new();
        let mut rest = text;
        while let Some(i) = rest.find("[assets/sqlc/") {
            rest = &rest[i + 1..];
            match rest.find(']') {
                Some(j) => {
                    out.push(rest[..j].to_string());
                    rest = &rest[j..];
                }
                None => break,
            }
        }
        out
    };
    // The relations this program reads, from its own source. `query_file!` takes a literal, so a
    // query the emitter runs is visible here and a query it does not run is not.
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
    assert!(
        !queried.is_empty(),
        "this program could not read its own source, so the attribution law would pass by \
         examining nothing"
    );

    // Every row set this program reads goes through `ordered`, asserted on the source rather than
    // trusted. A `fetch_all` that escaped it would write in the order the planner returned, and
    // the file would then depend on the physical layout of a table: a `CLUSTER` on `pm.part`
    // changes no row and would change the emitted document. `assets/sql/` has `--verify` behind
    // it and these documents have nothing, so this line is what stands between a fresh clone and
    // a diff nobody can read.
    //
    // The needle is split so this line is not its own counterexample, and the whole statement is
    // inspected rather than a fixed window, because a wrapped fetch is often two lines away from
    // the `ordered(` around it.
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
        "a row set reaches the emission with no total order, so the bytes on disk follow the \
         query plan rather than the rows: line(s) {escaped:?}"
    );
    println!("   {} row set(s) read, every one ordered before it is serialized",
             own.matches(needle).count());

    let mut unattributed: Vec<String> = Vec::new();
    let mut dangling: Vec<String> = Vec::new();
    let mut unread: Vec<String> = Vec::new();
    let mut found: std::collections::BTreeSet<String> = std::collections::BTreeSet::new();
    let mut sentences = 0usize;
    for e in fs::read_dir(OUT)?.flatten() {
        let path = e.path();
        let doc = fs::read_to_string(&path)?;
        let who = path.file_name().unwrap_or_default().to_string_lossy().to_string();
        for (open, close) in [("<documentation>", "</documentation>"), ("<text>", "</text>")] {
            let mut rest = doc.as_str();
            while let Some(i) = rest.find(open) {
                rest = &rest[i + open.len()..];
                let end = match rest.find(close) {
                    Some(j) => j,
                    None => break,
                };
                let body = &rest[..end];
                rest = &rest[end..];
                sentences += 1;
                let cites = cited_in(body);
                if cites.is_empty() {
                    unattributed.push(format!("{who}: {}", body.chars().take(60).collect::<String>()));
                }
                for c in cites {
                    if !Path::new(&c).exists() {
                        dangling.push(format!("{who}: {c}"));
                    } else if !queried.contains(&c) {
                        unread.push(format!("{who}: {c}"));
                    }
                    found.insert(c);
                }
            }
        }
    }
    assert!(
        unattributed.is_empty(),
        "a sentence is in an emitted document with nothing naming the relation that states it, \
         so a reader who wants to argue with it has no route back into the model: {unattributed:?}"
    );
    assert!(
        dangling.is_empty(),
        "a sentence cites a relation that is not in this tree, which sends a reader to a file \
         that does not exist and reads as a relation that does: {dangling:?}"
    );
    assert!(
        unread.is_empty(),
        "a sentence cites a relation this program never queried, so the citation is decorative \
         and the sentence is still the emitter's own claim: {unread:?}"
    );

    // ------------------------------------------------------------------
    // `tDefinitions` is an `xsd:sequence`, so the order of its children is normative: import*,
    // extension*, rootElement*, bpmndi:BPMNDiagram*, relationship*. No other law here would catch
    // a `relationship` ahead of the diagram: the counts do not move, the read-back laws find an
    // element wherever it sits, and the OMG schemas are not kept here, so nothing validates the
    // output against them.
    //
    // So this checks what the right order leaves behind, the same repair the SVG staleness needs:
    // a position cannot be asserted from inside the thing being positioned, but the result can be
    // read off the file. Every `relationship` must open after the diagram closes. It cannot stand
    // in for a schema processor and is not meant to; it holds the one ordering this emitter has
    // to get right by hand.
    // ------------------------------------------------------------------
    let mut misordered = Vec::new();
    let mut ordered_checked = 0usize;
    for e in fs::read_dir(OUT)?.flatten() {
        let path = e.path();
        if path.extension().and_then(|x| x.to_str()) != Some("bpmn") {
            continue;
        }
        let doc = fs::read_to_string(&path)?;
        let who = path.file_name().unwrap_or_default().to_string_lossy().to_string();
        let Some(first_rel) = doc.find("<relationship ") else { continue };
        ordered_checked += 1;
        match doc.find("</bpmndi:BPMNDiagram>") {
            Some(diag) if diag < first_rel => {}
            Some(_) => misordered.push(format!("{who}: a relationship opens before the diagram closes")),
            None => misordered.push(format!("{who}: emits a relationship and declares no diagram")),
        }
    }
    assert!(
        ordered_checked > 0,
        "no emitted document carries a relationship, so the tDefinitions ordering law examined \
         nothing, and a misordered document would be refused by a schema processor unseen"
    );
    assert!(
        misordered.is_empty(),
        "tDefinitions is an xsd:sequence and puts `relationship` after `bpmndi:BPMNDiagram`, so \
         these documents are well formed, correct in every count here, and refused by a schema \
         processor: {misordered:?}"
    );
    println!("   {ordered_checked} documents emit a relationship, every one after the diagram");
    println!("      closes. `tDefinitions` is a sequence, so that order is the difference between");
    println!("      a document a third-party reader opens and one it refuses.");

    // The other direction: a source declared and never reaching the file is a pointer nobody can
    // follow, because nothing carries it. `diagrams/annotated.sqlc` and `diagrams/legends.sqlc`
    // are where the declaration lives, so the two sets are required to be the same set.
    let declared: std::collections::BTreeSet<String> = annotated
        .iter()
        .filter_map(|a| a.states.as_deref())
        .chain(legends.iter().filter_map(|l| l.states.as_deref()))
        .map(|r| format!("assets/sqlc/{r}"))
        .collect();
    let unspent: Vec<&String> = declared.difference(&found).collect();
    assert!(
        unspent.is_empty(),
        "a relation is declared as the source of a sentence and no sentence on disk cites it: \
         {unspent:?}"
    );
    println!("   {sentences} sentences on disk, {} of them citing {} relations, 0 unattributed",
             sentences, found.len());


    // ------------------------------------------------------------------
    // The other half of the closure, which cannot be derived from the file. Everything above
    // reads the element kinds off disk, so it can report an element this program drew and never
    // decided about, and never one BPMN has that this program ignored: an unused glyph leaves no
    // trace to read. `diagrams/notation.sqlc` is the icon set as a literal, so the unused half of
    // the notation can be counted, and *gateways are not drawn here* stops being the same
    // sentence as *gateways were forgotten*.
    // ------------------------------------------------------------------
    let notation = ordered(sqlx::query_file!("assets/sql/diagrams/notation.sql").fetch_all(&pool).await?);

    let mut undeclared = Vec::new();
    for k in &written_kinds {
        match notation.iter().find(|n| n.element.as_deref() == Some(*k)) {
            None => undeclared.push(format!("{k}: on no roster row at all")),
            Some(n) if n.emitted != Some(true) => {
                undeclared.push(format!("{k}: the roster says it is withheld"))
            }
            _ => {}
        }
    }
    assert!(
        undeclared.is_empty(),
        "a glyph is on the page that nobody decided to spend, so an analyst reads notation this \
         repository never assigned a meaning: {undeclared:?}"
    );

    // The reverse: a roster row claiming to be spent must be findable in the file. A row that
    // declared a mapping and emitted nothing would be invisible to every count, because element
    // kinds are not one to one.
    let phantom: Vec<&str> = notation
        .iter()
        .filter(|n| n.emitted == Some(true))
        .filter_map(|n| n.element.as_deref())
        .filter(|e| !written_kinds.contains(e))
        .collect();
    assert!(
        phantom.is_empty(),
        "a roster row says this element is spent and the artifact does not contain it: {phantom:?}"
    );

    // The `<>` idiom, in a roster. Exactly one of the two columns, never a blank and never both,
    // so a glyph nobody classified cannot sit here looking classified.
    for n in &notation {
        let e = n.element.as_deref().unwrap_or("?");
        let spent = n.emitted == Some(true);
        assert_eq!(
            n.stands_for.is_some(),
            spent,
            "{e}: a spent glyph owes what it stands for, and only a spent one may say"
        );
        assert_eq!(
            n.withheld_because.is_some(),
            !spent,
            "{e}: a withheld glyph owes a reason, and a spent one may not carry an excuse"
        );
    }

    // The law that makes the claim to cover BPMN's composition testable. Every axis of the
    // notation is withheld whole except one, and on `composition` this model claims to cover BPMN
    // completely. So a compositional glyph in the withheld column is not a scoping decision but a
    // gap in the only axis where both notations speak.
    //
    // The claim is about facts, not elements: every compositional fact is covered. An element
    // can be withheld because a better element covers its fact, as `childLaneSet` covers what
    // `subProcess` would. So a withheld one is admitted only when `diagrams/admitted.sqlc` names
    // its replacement in `superseded_by`, and the replacement must itself be spent, or the
    // relation would turn a gap into a citation.
    let admitted = ordered(sqlx::query_file!("assets/sql/diagrams/admitted.sql").fetch_all(&pool).await?);
    let spent: std::collections::BTreeSet<&str> = notation
        .iter()
        .filter(|n| n.emitted == Some(true))
        .filter_map(|n| n.element.as_deref())
        .collect();
    // The `<>` idiom again: one ground or the other, never both and never neither. A row with
    // both would say the fact is carried and does not exist.
    for r in &admitted {
        let was = r.element.as_deref().unwrap_or("?");
        assert_eq!(
            r.superseded_by.is_some(), r.no_such_fact != Some(true),
            "{was}: exactly one ground, and this row states both or neither"
        );
        match (r.superseded_by.as_deref(), r.no_such_fact) {
            (Some(now), _) => {
                assert!(
                    spent.contains(now),
                    "{was} is excused by {now}, and {now} is not spent either: that is a gap \
                     wearing a citation rather than a replacement"
                );
                println!("   {was} → {now}, so the fact it carried is still carried");
            }
            // Not an excuse. This is the boundary claim shrinking and saying so: BPMN offers a
            // compositional element this model has no fact for, so at that point BPMN is the
            // wider of the two, and *this model is the finer* holds everywhere else and not here.
            _ => println!("   {was} no such fact in this model, so BPMN is wider here"),
        }
    }
    let wider = admitted.iter().filter(|r| r.no_such_fact == Some(true)).count();
    let replaced: std::collections::BTreeSet<&str> =
        admitted.iter().filter_map(|r| r.element.as_deref()).collect();
    let ceded: Vec<&str> = notation
        .iter()
        .filter(|n| n.axis.as_deref() == Some("composition") && n.emitted != Some(true))
        .filter_map(|n| n.element.as_deref())
        .filter(|e| !replaced.contains(e))
        .collect();
    assert!(
        ceded.is_empty(),
        "a compositional element of BPMN is withheld and nothing on diagrams/admitted.sqlc \
         covers what it carried, which is a gap in the one axis this model claims to cover whole \
         rather than a boundary it drew: {ceded:?}"
    );

    // ------------------------------------------------------------------
    // The flattening must not invent a loop, and this is the one law here that catches the file
    // saying something the model does not. Every other law asks whether the emission lost
    // something. `calledElement` is a QName of a process and lanes are not callable, so the
    // composition's layer-to-layer edges collapse to filing-to-filing ones, and collapsing merges
    // nodes: two layers of one filing become one node, and two edges that ran between different
    // layers become a round trip between two documents.
    //
    // So a completely correct filing could render as BPMN documents calling each other in a
    // loop. One legitimate part running back from a called document into a different layer of
    // its caller leaves the composition with no loop, no jagged partition and no co-movement,
    // while the emitted call graph gains a loop, and a reader sees two documents calling each
    // other. The model does not say that. Nothing else here can see it: the number of
    // `callActivity` elements still equals the number of parts, so every count passes.
    //
    // The comparison runs one way only. Merging nodes cannot remove a loop that was there, so
    // the emitted count is never below the composition's; the whole risk is above it.
    // ------------------------------------------------------------------
    let mut call_edges: BTreeMap<(String, String), ()> = BTreeMap::new();
    for e in fs::read_dir(OUT)?.flatten() {
        let path = e.path();
        if path.extension().is_none_or(|x| x != "bpmn") { continue; }
        let doc = fs::read_to_string(&path)?;
        let own = path.file_stem().unwrap().to_string_lossy().to_string();
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("calledElement=\"") {
            rest = &rest[i + 15..];
            let end = rest.find('"').unwrap_or(0);
            let target = rest[..end].rsplit(':').next().unwrap_or("").to_string();
            let target = target.strip_prefix("proc_").unwrap_or(&target).to_string();
            if target != own {
                call_edges.insert((own.clone(), target), ());
            }
        }
    }
    let cnodes: std::collections::BTreeSet<&str> = call_edges
        .keys()
        .flat_map(|(a, b)| [a.as_str(), b.as_str()])
        .collect();
    let mut adj: BTreeMap<&str, Vec<&str>> = BTreeMap::new();
    for (a, b) in call_edges.keys() {
        adj.entry(a).or_default().push(b);
        adj.entry(b).or_default().push(a);
    }
    let mut seen: std::collections::BTreeSet<&str> = std::collections::BTreeSet::new();
    let mut comps = 0usize;
    for u in &cnodes {
        if seen.contains(u) { continue; }
        comps += 1;
        let mut st = vec![*u];
        while let Some(v) = st.pop() {
            if !seen.insert(v) { continue; }
            for w in adj.get(v).into_iter().flatten() {
                if !seen.contains(w) { st.push(w); }
            }
        }
    }
    let emitted_dim = call_edges.len() as i64 - cnodes.len() as i64 + comps as i64;
    let f_dim = ordered(sqlx::query_file!("assets/sql/rank/cycle_space.sql")
        .fetch_all(&pool)
        .await?)
        .into_iter()
        .find(|c| c.graph.as_deref() == Some("layers"))
        .and_then(|c| c.cycle_space_dim)
        .ok_or("rank/cycle_space.sqlc does not carry the layer graph")?;

    println!("\nThe flattening, and whether it invented a loop");
    println!("   layer grain, composition  loops {f_dim}");
    println!("   filing grain, emitted     loops {emitted_dim}, {} nodes, {} edges, {comps} pieces",
             cnodes.len(), call_edges.len());
    assert!(
        !cnodes.is_empty(),
        "no calledElement was emitted at all, so this law examined nothing"
    );
    assert_eq!(
        emitted_dim, f_dim,
        "the emitted call graph has {emitted_dim} independent loops and the composition {f_dim}: \
         collapsing layer to filing has put a recursion in the diagram that the model does not \
         state, and an analyst reading it would be right to believe the documents call each other"
    );
    println!("   Equal, so no reader can see a loop the model does not state. This is the");
    println!("      one law here about what the drawing adds rather than what it lost.");

    let mut by_axis: BTreeMap<&str, (usize, usize)> = BTreeMap::new();
    for n in &notation {
        let a = by_axis.entry(n.axis.as_deref().unwrap_or("?")).or_default();
        if n.emitted == Some(true) { a.0 += 1 } else { a.1 += 1 }
    }
    let spent: usize = by_axis.values().map(|a| a.0).sum();
    println!("\nThe notation, spent and withheld, against assets/sqlc/diagrams/notation.sqlc");
    for (axis, (s, w)) in &by_axis {
        println!("   {:<15} {s:>2} spent {w:>3} withheld{}", axis,
                 if *w == 0 { "   the whole axis" } else { "" });
    }
    // The summary is computed, because a fixed one rots exactly like a number. A fixed *BPMN is
    // withheld whole on every axis but one* is true of a roster with one mixed axis and false of a
    // roster with four, and no rule notices, because a sentence is not a count. *A number in prose
    // rots* is not about numbers: it is about any claim a program could print and does not.
    let whole: Vec<&str> = by_axis.iter().filter(|(_, a)| a.0 == 0).map(|(k, _)| *k).collect();
    let mixed: Vec<&str> =
        by_axis.iter().filter(|(_, a)| a.0 > 0 && a.1 > 0).map(|(k, _)| *k).collect();
    println!("   {spent} of {} elements spent. Not a cover of BPMN: {} {} ceded whole ({}), and {} {} \
              partly spent ({}).",
             notation.len(),
             whole.len(), if whole.len() == 1 { "axis is" } else { "axes are" }, whole.join(", "),
             mixed.len(), if mixed.len() == 1 { "axis is" } else { "axes are" }, mixed.join(", "));
    println!("   On `composition`, the one axis both notations speak, this model is the finer at \
              every point but {wider}.");

    // ------------------------------------------------------------------
    // The laws. The expected side is computed by relations this program did not write.
    // ------------------------------------------------------------------
    println!("\nThe laws, counted on disk, against assets/sqlc/diagrams/expected.sqlc");
    let mut broken = Vec::new();
    for e in &expected {
        let want = e.expected.unwrap_or(-1);
        let got = emitted.get(e.slug.as_deref().unwrap_or("")).copied().unwrap_or(-1);
        let ok = want == got;
        println!("   {} {:<9} model {want:>4}   emitted {got:>4}",
                 if ok { "  " } else { "no" }, e.slug.as_deref().unwrap_or("?"));
        if !ok {
            broken.push(format!("{}: model {want}, emitted {got}", e.slug.as_deref().unwrap_or("?")));
        }
    }
    assert!(broken.is_empty(), "the emission does not agree with the model: {broken:?}");
    assert_eq!(
        emitted.len(), expected.len(),
        "every law on diagrams/roster.sqlc must be counted here, and nothing else may be"
    );

    // ------------------------------------------------------------------
    // The scope each document states, against the scope its filing claims, which no count in this
    // file can check. An emitter writing *a partition of layers claimed exhaustive* into every
    // document from a string literal would say it of every filing, while most of the corpus files
    // `scoped` or `unbounded`. One scope sentence reaches one document either way, so the number
    // of scope sentences equals the number of filings whichever word the sentence holds, however
    // the corpus grows. The census below prints the split; it is not written here, because the
    // point survives the numbers and the numbers do not.
    //
    // Attribution is the repair here, not a bigger count, as it is in `diagrams/ungoverned.sqlc`
    // for a table declared and never rendered, and in the per-kind law in
    // `examples/rendering/main.rs`. A defect that puts the right number of the wrong thing on the
    // page is invisible to counting by construction, and a fixed sentence about a filing is that
    // defect in prose.
    // ------------------------------------------------------------------
    let mut misstated = Vec::new();
    let mut checked = 0usize;
    for f in &filings {
        let doc = fs::read_to_string(format!("{OUT}/{}.bpmn", f.filing))?;
        let said = doc
            .split_once("scope: ")
            .and_then(|(_, r)| r.split_once('.'))
            .map(|(w, _)| w.trim().to_string());
        let claims = scopes
            .iter()
            .find(|s| s.filing == f.filing)
            .and_then(|s| s.extent.clone());
        checked += 1;
        if said.as_deref() != claims.as_deref() {
            misstated.push(format!(
                "{}: the document says `{}` and the filing claims `{}`",
                f.filing, said.as_deref().unwrap_or("nothing"),
                claims.as_deref().unwrap_or("nothing")
            ));
        }
    }
    // The same shape reaches more than the scope. Which other model values does a document state
    // that only a count would check? The coupling search answer, the citations a composition is
    // filed under, and the two lanes an association joins. Each could be wrong in every document
    // with its count still exact.
    for f in &filings {
        let doc = fs::read_to_string(format!("{OUT}/{}.bpmn", f.filing))?;
        let said = doc
            .split_once("coupling search: ")
            .and_then(|(_, r)| r.split_once('.'))
            .map(|(w, _)| w.trim().to_string());
        let claims = searches.iter().find(|s| s.filing == f.filing).and_then(|s| s.answer.clone());
        if said.as_deref() != claims.as_deref() {
            misstated.push(format!(
                "{}: the document says the coupling search answered `{}` and the filing says `{}`",
                f.filing, said.as_deref().unwrap_or("nothing"),
                claims.as_deref().unwrap_or("nothing")
            ));
        }

        let mut cited: Vec<String> = doc
            .match_indices("filed under: ")
            .filter_map(|(i, _)| doc[i + 13..].split_once('.').map(|(v, _)| v.trim().to_string()))
            .collect();
        cited.sort();
        let mut owed_cites: Vec<String> = citations
            .iter()
            .filter(|c| c.composition == f.filing)
            .filter_map(|c| c.cited.clone())
            .collect();
        owed_cites.sort();
        if cited != owed_cites {
            misstated.push(format!("{}: the document cites {cited:?} and the filing cites {owed_cites:?}", f.filing));
        }

        // The endpoints, which are the whole claim. The number of associations equals the number
        // of couplings whichever two lanes each one joins, so a dependence drawn between the
        // wrong pair would state that the wrong layers move together and pass every count.
        let mut drawn: Vec<(String, String)> = Vec::new();
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("<association ") {
            rest = &rest[i..];
            let end = rest.find('>').unwrap_or(rest.len());
            let tag = &rest[..end];
            let get = |k: &str| -> String {
                tag.split_once(&format!("{k}=\"tns:"))
                    .and_then(|(_, r)| r.split_once('"'))
                    .map(|(v, _)| v.to_string())
                    .unwrap_or_default()
            };
            drawn.push((get("sourceRef"), get("targetRef")));
            rest = &rest[end..];
        }
        drawn.sort();
        let mut owed: Vec<(String, String)> = deps
            .iter()
            .filter(|d| d.filing == f.filing)
            .map(|d| (id("lane", &[&f.filing, &d.from_layer]), id("lane", &[&f.filing, &d.to_layer])))
            .collect();
        owed.sort();
        if drawn != owed {
            misstated.push(format!(
                "{}: the associations join {drawn:?} and the couplings run {owed:?}",
                f.filing
            ));
        }
    }

    println!("\nThe facts each document states, against what its filing claims");
    let mut seen: BTreeMap<&str, usize> = BTreeMap::new();
    for sc in &scopes {
        *seen.entry(sc.extent.as_deref().unwrap_or("typed absent")).or_default() += 1;
    }
    for (e, n) in &seen {
        println!("   {e:<14} {n:>2}");
    }
    assert!(checked > 0, "no document was read, so the scope attribution law examined nothing");
    assert!(seen.len() > 1, "every filing claims the same extent, so this law cannot discriminate");
    assert!(
        misstated.is_empty(),
        "a document states an extent its filing did not claim, which is the artifact asserting a \
         boundary rather than losing one: {misstated:?}"
    );
    println!("   {checked} documents. Facts checked per document and not counted: the scope,");
    println!("      the coupling search, the citations, and the two lanes each association joins.");
    println!("      Every one of them is a model value written into prose or into a reference,");
    println!("      and every one has a count beside it that stays true when it is wrong.");

    // ------------------------------------------------------------------
    // Every declared mapping is governed, or says why not. The laws above count element kinds,
    // and two tables can name one kind, so a law counting that kind could pass while reading
    // neither. Counting kinds cannot verify attribution, and this is the check that does.
    // ------------------------------------------------------------------
    let dangling: Vec<&str> = governance
        .iter()
        .filter(|g| g.names_a_law_that_is_not_there == Some(true))
        .map(|g| g.object.as_deref().unwrap_or("?"))
        .collect();
    let silent: Vec<&str> = governance
        .iter()
        .filter(|g| g.ungoverned_and_unexplained == Some(true))
        .map(|g| g.object.as_deref().unwrap_or("?"))
        .collect();
    let ungoverned = governance.iter().filter(|g| g.governed_by.is_none()).count();
    println!("\nGovernance of the mapping, which counting element kinds cannot give you");
    println!("   {} declared mappings, {} governed by a named law, {} declared and not rendered",
             governance.len(), governance.len() - ungoverned, ungoverned);
    for g in governance.iter().filter(|g| g.governed_by.is_none()) {
        println!("      {:<22} {}", g.object.as_deref().unwrap_or("?"),
                 g.loses.as_deref().unwrap_or(""));
    }
    assert!(dangling.is_empty(), "a mapping names a law that is not on the roster: {dangling:?}");
    assert!(
        silent.is_empty(),
        "a mapping names no law and does not say what it loses, so an element could be declared, \
         never rendered, and no count would ever see it: {silent:?}"
    );

    // ------------------------------------------------------------------
    // The composition read back out of the file, as a set of layer-to-layer edges, and compared
    // with the composition itself. This is the strongest law in this file, and the only one that
    // compares the edges themselves rather than a count. The loop law above compares the merged
    // call graph's loops with the composition's, a shadow of a shadow: equal counts do not mean
    // equal graphs, and the merging is where a defect hides.
    //
    // Relationships joining the wrong pairs would pass a count of relationships against parts
    // exactly, the same blind spot that would let a reversed coupling through. The endpoints are
    // the claim, so the endpoints are what is checked.
    // ------------------------------------------------------------------
    let mut read_back: Vec<(String, String, String, String)> = Vec::new();
    let want_type = "process-modulus:part";
    for f in &filings {
        let doc = fs::read_to_string(format!("{OUT}/{}.bpmn", f.filing))?;
        // prefix -> the filing that namespace names, which is what `import` declares.
        let mut prefix: BTreeMap<String, String> = BTreeMap::new();
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("xmlns:f") {
            rest = &rest[i + 7..];
            let (n, r) = rest.split_once("=\"").unwrap_or(("", ""));
            let uri = r.split_once('"').map(|(u, _)| u).unwrap_or("");
            if let Some(target) = by_notation.get(uri) {
                prefix.insert(format!("f{n}"), (*target).to_string());
            }
            rest = r;
        }
        let mut rest = doc.as_str();
        // Filtered by type, which is the point of choosing this element. Two relations share
        // `relationship`, and reading them together would compare the composition against the
        // composition plus the eliminations and fail on a correct document. An `association` could
        // not be filtered at all, which is why it is ruled out.
        while let Some(i) = rest.find(&format!("<relationship type=\"{want_type}\"")) {
            rest = &rest[i..];
            let end = rest.find("</relationship>").unwrap_or(rest.len());
            let block = &rest[..end];
            let pick = |tag: &str| -> String {
                block
                    .split_once(&format!("<{tag}>"))
                    .and_then(|(_, r)| r.split_once(&format!("</{tag}>")))
                    .map(|(v, _)| v.trim().to_string())
                    .unwrap_or_default()
            };
            let (src, tgt) = (pick("source"), pick("target"));
            let strip = |q: &str| -> (String, String) {
                let (p, local) = q.split_once(':').unwrap_or(("", q));
                let owner = if p == "tns" {
                    f.filing.clone()
                } else {
                    prefix.get(p).cloned().unwrap_or_default()
                };
                let layer = local
                    .strip_prefix(&id("lane", &[&owner]))
                    .and_then(|r| r.strip_prefix('_'))
                    .unwrap_or(local)
                    .to_string();
                (owner, layer)
            };
            let (_, cl) = strip(&src);
            let (pf, pl) = strip(&tgt);
            read_back.push((f.filing.clone(), cl, pf, pl));
            rest = &rest[end..];
        }
    }
    read_back.sort();
    // The layer names were sanitised into NCNames on the way out, so the model side is sanitised
    // the same way on the way back, rather than the file being un-sanitised. A round trip through
    // a lossy encoding is compared in the encoding.
    let mut owed_f: Vec<(String, String, String, String)> = descents
        .iter()
        .map(|d| {
            (
                d.composition.clone(),
                id("x", &[&d.composed_layer])[2..].to_string(),
                d.part_filing.clone(),
                id("x", &[&d.part_layer])[2..].to_string(),
            )
        })
        .collect();
    owed_f.sort();
    println!("\nThe composition read back out of the documents, at layer grain");
    println!("   {} relationship edges recovered, {} edges to parts in other filings",
             read_back.len(), owed_f.len());
    assert!(!read_back.is_empty(), "no relationship was emitted, so the read-back law examined nothing");
    assert_eq!(
        read_back, owed_f,
        "the layer-grain graph in the documents is not the composition: a tool reading them would \
         reconstruct a different composition than the model states"
    );
    println!("   The same, edge for edge. `calledElement` names a process and collapses the");
    println!("      edges onto document pairs; this is the same fact at layer grain, so the");
    println!("      widest `demoted` in the mapping is a reference again and not a name.");

    // The second type, read back the same way. The endpoints are the claim here too:
    // relationships joining the wrong pairs would pass a count of relationships against `between`
    // references exactly, and a `between` pointing at the wrong layer says the composer removed a
    // number on account of a double count that is not there. Filtered by `@type`, which is why
    // this element is chosen over `association`: two relations, one element, and the laws can
    // still tell them apart.
    let mut read_attrs: Vec<(String, String, String, String)> = Vec::new();
    for f in &filings {
        let doc = fs::read_to_string(format!("{OUT}/{}.bpmn", f.filing))?;
        let mut prefix: BTreeMap<String, String> = BTreeMap::new();
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("xmlns:f") {
            rest = &rest[i + 7..];
            let (n, r) = rest.split_once("=\"").unwrap_or(("", ""));
            let uri = r.split_once('"').map(|(u, _)| u).unwrap_or("");
            if let Some(target) = by_notation.get(uri) {
                prefix.insert(format!("f{n}"), (*target).to_string());
            }
            rest = r;
        }
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("<relationship type=\"process-modulus:elimination-between\"") {
            rest = &rest[i..];
            let end = rest.find("</relationship>").unwrap_or(rest.len());
            let block = &rest[..end];
            let pick = |tag: &str| -> String {
                block
                    .split_once(&format!("<{tag}>"))
                    .and_then(|(_, r)| r.split_once(&format!("</{tag}>")))
                    .map(|(v, _)| v.trim().to_string())
                    .unwrap_or_default()
            };
            let strip = |q: &str| -> (String, String) {
                let (p, local) = q.split_once(':').unwrap_or(("", q));
                let owner = if p == "tns" { f.filing.clone() } else { prefix.get(p).cloned().unwrap_or_default() };
                let layer = local
                    .strip_prefix(&id("lane", &[&owner]))
                    .and_then(|r| r.strip_prefix('_'))
                    .unwrap_or(local)
                    .to_string();
                (owner, layer)
            };
            let (_, cl) = strip(&pick("source"));
            let (pf, pl) = strip(&pick("target"));
            read_attrs.push((f.filing.clone(), cl, pf, pl));
            rest = &rest[end..];
        }
    }
    read_attrs.sort();
    let mut owed_attrs: Vec<(String, String, String, String)> = attributions
        .iter()
        .map(|b| {
            (
                b.composition.clone(),
                id("x", &[&b.composed_layer])[2..].to_string(),
                b.resolved_filing.clone(),
                id("x", &[&b.layer])[2..].to_string(),
            )
        })
        .collect();
    owed_attrs.sort();
    println!("   {} attribution edges recovered, {} resolved `between` references",
             read_attrs.len(), owed_attrs.len());
    assert!(!read_attrs.is_empty(), "no attribution relationship, so this law examined nothing");
    assert_eq!(
        read_attrs, owed_attrs,
        "an elimination points at a different layer in the artifact than in the model: the \
         document would say a number was removed on account of a double count that is not there"
    );
    println!("   The same, edge for edge. Two relations on one element, told apart by `@type`,");
    println!("      which `association` cannot do, and why it is ruled out for the composition.");

    // ------------------------------------------------------------------
    // `demoted` is a claim about the file, so it can be checked, which is why `loses` is split in
    // two. Saying a fact survives as text is worth nothing if nobody looks for the text. The
    // biggest case is the composition: `calledElement` is a QName of a process, so the target
    // layer is not a reference anywhere in the document, and it is there in `callActivity/@name`
    // as `labour <- merge-us-member/labour`.
    //
    // So the boundary claim changes shape. Almost everything this mapping loses is demoted rather
    // than absent: a person can reconstruct it and a tool cannot. For a notation whose declared
    // reader is a human analyst, that is the right failure to have, and it can be said only
    // because the two are counted apart.
    // ------------------------------------------------------------------
    for o in &objects {
        assert_eq!(
            o.loses.is_some(), o.loses_kind.is_some(),
            "{}: a `loses` owes a kind and a kind owes a `loses`",
            o.object.as_deref().unwrap_or("?")
        );
        if let Some(k) = o.loses_kind.as_deref() {
            assert!(
                k == "demoted" || k == "absent",
                "{}: `{k}` is not one of the two kinds",
                o.object.as_deref().unwrap_or("?")
            );
        }
    }
    let mut vanished = Vec::new();
    let mut demoted_checked = 0usize;
    // Read the `name`, not the document. A search of the whole document would be weaker than the
    // claim it checks: `id("call", ...)` embeds the layer, so a layer deleted from the name would
    // still be found in the id. An id is a mangled NCName nobody reads, and `demoted` claims a
    // reader can recover the fact. Dropping the layer from the name fires this law, where a search
    // of the document would not.
    let mut names_in: BTreeMap<String, String> = BTreeMap::new();
    for f in &filings {
        let doc = fs::read_to_string(format!("{OUT}/{}.bpmn", f.filing))?;
        let mut joined = String::new();
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("<callActivity ") {
            rest = &rest[i..];
            let end = rest.find('>').unwrap_or(rest.len());
            if let Some((_, r)) = rest[..end].split_once("name=\"") {
                if let Some((v, _)) = r.split_once('"') {
                    joined.push_str(v);
                    joined.push('\n');
                }
            }
            rest = &rest[end..];
        }
        names_in.insert(f.filing.clone(), joined);
    }
    for p in parts.iter().filter(|p| !p.is_local.unwrap_or(false)) {
        demoted_checked += 1;
        let seen = names_in.get(&p.composition).map(String::as_str).unwrap_or("");
        if !seen.contains(&esc(&p.part_layer)) {
            vanished.push(format!("{}: no callActivity names the part layer `{}`",
                                  p.composition, p.part_layer));
        }
    }
    let (dem, abs_) = (
        objects.iter().filter(|o| o.loses_kind.as_deref() == Some("demoted")).count(),
        objects.iter().filter(|o| o.loses_kind.as_deref() == Some("absent")).count(),
    );
    println!("\nWhat is lost, and the two kinds are not one kind");
    println!("   demoted {dem:>2}   the fact is in the document as text: readable, unresolvable");
    println!("   absent  {abs_:>2}   the fact is not in the document in any form");
    assert!(demoted_checked > 0, "no foreign part, so the demotion law examined nothing");
    assert!(
        vanished.is_empty(),
        "a mapping is filed as `demoted`, which claims the fact survives as text, and the text \
         is not in the document: {vanished:?}"
    );
    println!("   {demoted_checked} foreign parts, and every target layer is in its document as a");
    println!("      name as well as in a relationship. Two readers, two paths: a person reads the");
    println!("      callActivity label, a tool resolves the QName, and each has its own law.");

    // The operation's `pm:ForeignId` owes the same law, which no count could stand in for. The
    // `documentation` count reads diagrams/annotated.sqlc and stays exact with every sentence hung
    // on the wrong task, and for a reference that is the entire fact: an id against the wrong node
    // is a crossing that points somewhere real and wrong, a reversed dependence at the one place a
    // reader would act on it.
    //
    // Read the task, not the document. A search of the document passes on a sentence attached to
    // any task in the file, the weakness the callActivity law above avoids. Moving one sentence to
    // another task, or changing one character of the id, fires this law while the documentation
    // count stays exact.
    let mut misattributed = Vec::new();
    let mut crossings_checked = 0usize;
    for c in &crossings {
        let (notation, node) = match (c.foreign_notation.as_deref(), c.foreign_id.as_deref()) {
            (Some(n), Some(i)) => (n, i),
            _ => continue,
        };
        crossings_checked += 1;
        let doc = fs::read_to_string(format!("{OUT}/{}.bpmn", c.filing))?;
        let open = format!("<task id=\"{}\"", id("task", &[&c.filing, &c.label]));
        let body = match doc.split_once(&open) {
            // A self-closing task has no `</task>`, so a body taken to the next one would run
            // through every task in between, and the law would read a sentence that belongs to
            // another. It stops at whichever boundary comes first.
            Some((_, rest)) => {
                let end = [rest.find("</task>"), rest.find("<task ")]
                    .into_iter()
                    .flatten()
                    .min()
                    .unwrap_or(rest.len());
                rest[..end].to_string()
            }
            None => {
                misattributed.push(format!(
                    "{}: no task is emitted for the operation `{}`, which files a notation position",
                    c.filing, c.label
                ));
                continue;
            }
        };
        if !body.contains(&esc(node)) || !body.contains(&esc(notation)) {
            misattributed.push(format!(
                "{}: the task for `{}` does not carry its filed position {notation} / {node}",
                c.filing, c.label
            ));
        }
    }
    assert!(
        crossings_checked > 0,
        "no operation in this corpus files a pm:ForeignId, so the crossing law examined nothing \
         and the BPMN interface is asserted by a rule that never ran"
    );
    assert!(
        misattributed.is_empty(),
        "an operation files a position in a process notation and its own task does not carry it, \
         so the one thing that crosses out of this model is missing from the artifact that exists \
         to show the crossing: {misattributed:?}"
    );
    println!("   {crossings_checked} operations file a notation position, and each one is on its");
    println!("      own task. That id is the whole BPMN interface: nothing is added to the filer's");
    println!("      diagram, so the crossing costs that document nothing and survives wherever it goes.");

    // ------------------------------------------------------------------
    // What cannot be drawn, listed. A blank diagram and a diagram of nothing look the same from
    // outside, so the absence is filed rather than left to inference.
    // ------------------------------------------------------------------
    println!("\nWhat BPMN has no home for, and the three reasons are three different facts");
    for reason in ["misreads", "notApplicable", "none"] {
        let rows: Vec<_> = objects.iter().filter(|o| o.absent.as_deref() == Some(reason)).collect();
        println!("   {reason}  ({})", rows.len());
        for o in rows {
            println!("      {:<20} {}", o.object.as_deref().unwrap_or("?"), o.why.as_deref().unwrap_or(""));
        }
    }
    println!("\nThe eliminations, and every overlap is derived rather than filed");
    for e in &elims {
        println!("   {:<13} {:<32} over {}",
                 e.elimination.as_deref().unwrap_or("?"),
                 e.the_sum.as_deref().unwrap_or(""),
                 e.the_overlap.as_deref().unwrap_or(""));
        println!("   {:<13} named by {}", "", e.named_by.as_deref().unwrap_or(""));
    }
    println!("   The composed figure is the parts added up less the overlap, and the overlap is");
    println!("      itself a named relation, the pivot eliminations/derived.sqlc turns on.");

    println!("\n   One thing is lost that no table names: the induction's `decider`. Induction is");
    println!("      drawn as groups, not a second lane set, which would give every layer two lane");
    println!("      elements with nothing but a matching name to say they are one layer, so the");
    println!("      shared key (filing, layer) would not survive the rendering. The lanes are the");
    println!("      draw, which is what a modeller files, and `decider` has nowhere to go.");
    println!("      In this corpus: {draw_count} draws, {induction_count} inductions.");

    println!("\nThe levels this corpus holds, and only the first is emitted");
    for l in &levels {
        println!("   L{}  {:<9} {}", l.level.unwrap_or(-1),
                 l.process.as_deref().unwrap_or("?"),
                 if l.emitted == Some(true) { "emitted" } else { "not emitted" });
        println!("       actor    {}", l.actor.as_deref().unwrap_or(""));
        println!("       subject  {}", l.subject.as_deref().unwrap_or(""));
        println!("       outcome  {}", l.outcome.as_deref().unwrap_or(""));
    }
    println!("   Each level's outcome is the next level's subject, and the last one is required");
    println!("      to be empty. That is why the recursion stops rather than being stopped.");
    assert_eq!(
        levels.iter().filter(|l| l.emitted == Some(true)).count(), 1,
        "exactly one level is rendered here; a second would need its own laws and its own \
         collaboration, and claiming to draw it without them is the failure this file exists for"
    );

    println!("\nAll checks passed.");
    Ok(())
}
