// ⛔ THE HEADER OF THIS PROGRAM IS `README.md` BESIDE IT, AND THERE IS ONE COPY OF IT.
// GitHub renders a directory's README and renders no `//!` block at all, so an argument
// kept only in the source is unreadable from the one place this repository is published.
// `include_str!` makes that same file rustdoc's page, so the two renderings cannot disagree
// and a missing header is a compile error rather than a blank row on the front page.
//
// ⭐⭐ BOTH LANGUAGES ARE INCLUDED, WHICH IS WHAT THE SCHEMAS ALREADY DO. An `xs:annotation`
// holds an `xml:lang="en"` block and an `xml:lang="pt"` block and the generator concatenates
// them into one Rust doc comment; these two files are the same arrangement one directory over.
// A Portuguese page rendered nowhere would be a translation nobody reads, which is the
// second-class citizenship `tests/translation.rs` exists to refuse.
#![doc = include_str!("README.md")]
#![doc = include_str!("README.pt.md")]

use std::collections::BTreeMap;
use std::fmt::Write as _;
use std::fs;
use std::path::Path;

/// ⛔⛔⛔ THIS PROGRAM OWNS THIS DIRECTORY AND WIPES IT, WHICH IS WHY IT IS A SUBDIRECTORY.
/// Sharing `assets/bpmn/` with `examples/graphs/main.rs` puts the wipe below over that program's
/// three documents whenever this one runs second. Both orders pass every law: `rendering` then
/// covers 18 documents or 15 depending on which example was invoked last, silently, and the
/// battery holds only because `d` sorts before `g`. A per-owner subdirectory is what makes the
/// order stop mattering.
///
/// ⭐ AND THE SPLIT SAYS WHAT THE TWO EMITTERS ALREADY ARE. These are one document per FILING, at layer
/// grain; `graphs` emits one per GRAPH FILLING, corpus-wide. §8 already says the two do not nest,
/// because a `participant` cannot contain a `participant`. Two collaborations, two directories.
const OUT: &str = "assets/bpmn/filings";
const BPMN_NS: &str = "http://www.omg.org/spec/BPMN/20100524/MODEL";
const DI_NS: &str = "http://www.omg.org/spec/BPMN/20100524/DI";
/// The DI namespace proper, which is where a `waypoint` lives. `bpmndi` is the BPMN-specific
/// diagram interchange and `dc` is the shared graphics primitives; an edge's waypoints are
/// `di:waypoint`, in neither of those, and an association could not be given a route without it.
const DI_BASE_NS: &str = "http://www.omg.org/spec/DD/20100524/DI";
const DC_NS: &str = "http://www.omg.org/spec/DD/20100524/DC";

/// ⭐⭐⭐ THE LAYOUT LIVES HERE BECAUSE `bpmndi:BPMNDiagram` LIVES IN `tDefinitions`. BPMN has a
/// designated place for a document's own picture and this emitter left it empty, so the SVG's
/// geometry was derived from NOTHING: `examples/rendering/main.rs` invented coordinates, and a cache
/// whose content has no original is a second opinion rather than a cache. Its own header says
/// `.sqlx` is extracted from the GENERATED artifact for exactly that reason.
///
/// ⛔ AND THE ROSTER MISSED THE WHOLE HALF OF THE STANDARD THIS COMES FROM. `notation.sqlc` was
/// diffed against `Semantic.xsd` and never against `BPMNDI.xsd`, so **zero of the six DI elements
/// were on a roster whose header calls itself BPMN's closed drawable vocabulary** -- and the DI
/// half is the half that is about drawing.
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

/// ⭐ One lane's box and everything under it, appended to `out` as `(id, x, y, w, h)`. The
/// recursion is the partition's, so the geometry recurses with it.
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

/// An `xsd:ID` is an NCName: it may not start with a digit and may not contain most punctuation.
/// ⛔ Layer and filing names here are domain text, not identifiers, so they are sanitised into an
/// id and kept VERBATIM in `name`. Losing the original in the id would be fine; losing it in the
/// name would be the emitter quietly renaming the model.
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

/// One lane and everything under it. ⭐⭐⭐ THE PARTITION RECURSES, WHICH IS WHY THIS FUNCTION
/// DOES. `Lane` carries an optional `childLaneSet` for sub-partitions, and *a fusion's parts
/// partition what they compose* is that sentence in BPMN's own words. ⛔ A local fusion written
/// as a `subProcess` says it is an ACTIVITY inside a lane rather than a PARTITION of one, and
/// loses layer grain on the way out.
///
/// ⛔ A LANE HOLDING A `childLaneSet` WRITES NO `flowNodeRef` OF ITS OWN. Measured: no local
///   fusion in this corpus carries a draw or a foreign part, so no parent owes both.
///   `diagrams/nestings.sqlc` says what to do on the day one does.
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
    writeln!(x, "{p}  <documentation>rank {}; nothing beneath this layer needs evaluating first \
                 at rank 0, and a higher rank waits on every arrival below it{cited}</documentation>",
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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example translates the loaded corpus and cannot do that \
         without the rows."
    })?;
    let pool = sqlx::postgres::PgPool::connect(&url).await?;

    // ------------------------------------------------------------------
    // The model. Every relation here is composed; none is spelled inline.
    // ------------------------------------------------------------------
    // ⭐⭐ The four projections under `diagrams/` are INCIDENCE ONLY, so this program cannot read
    //   a magnitude even by accident. ⭐ And they are deliberately NOT the relations
    //   `diagrams/expected.sqlc` counts: expected reads the wide relation, the emitter reads the
    //   narrow one composed from it, so a filter added to a projection makes a law fire.
    let filings = ordered(sqlx::query_file!("assets/sql/diagrams/pools.sql").fetch_all(&pool).await?);
    let layers = ordered(sqlx::query_file!("assets/sql/layers/every_layer.sql").fetch_all(&pool).await?);
    let ops = ordered(sqlx::query_file!("assets/sql/entries/operations.sql").fetch_all(&pool).await?);
    // The third pm:ForeignId, and the only one that points OUT of the model rather than at
    // another filing. Read as its own relation so the sentence on the task cites the file that
    // states it, rather than a dimension that merely carries the column.
    let crossings =
        ordered(sqlx::query_file!("assets/sql/entries/notation_references.sql").fetch_all(&pool).await?);
    let draws = ordered(sqlx::query_file!("assets/sql/diagrams/lane_members.sql").fetch_all(&pool).await?);
    let parts = ordered(sqlx::query_file!("assets/sql/diagrams/calls.sql").fetch_all(&pool).await?);
    let notations = ordered(sqlx::query_file!("assets/sql/diagrams/imports.sql").fetch_all(&pool).await?);
    // ⭐⭐⭐ N, WHICH NOTHING ELSE HERE CARRIES. A `categoryValue` per induced-into layer, a
    //   `categoryValueRef` per induction, and a `group` to draw each. `tFlowElement` carries
    //   `categoryValueRef` with `maxOccurs="unbounded"`, so this cover may overlap where a lane
    //   set may not, and it adds NO lane: a second `laneSet` would have given every induced layer
    //   a second `lane` element with only a matching name to say it was the same layer.
    let categories = ordered(sqlx::query_file!("assets/sql/diagrams/categories.sql").fetch_all(&pool).await?);
    let cat_members =
        ordered(sqlx::query_file!("assets/sql/diagrams/category_members.sql").fetch_all(&pool).await?);
    // ⭐⭐⭐ C AND ITS SEARCH, WHICH ARE ONE FACT FILED AS TWO RELATIONS. A coupling is the
    //   model's own falsifier, so a document that cannot state it cannot carry the refutation;
    //   and drawing the matrix alone is worse than drawing neither, because 12 of 15 filings state no coupling
    //   and a reader resolves a blank page as independence. The search says which blank it is.
    let deps = ordered(sqlx::query_file!("assets/sql/diagrams/dependences.sql").fetch_all(&pool).await?);
    let searches = ordered(sqlx::query_file!("assets/sql/diagrams/searches.sql").fetch_all(&pool).await?);
    // ⛔⛔⛔ THE EXTENT IS READ AND NEVER ASSERTED. Hardcoding *a partition of layers claimed
    //   exhaustive* onto every document says `complete` of fourteen filings that do not claim
    //   it. A string literal about a filing is a claim this program made up, and no cardinality
    //   law can reach one. If a sentence here says something ABOUT a filing, it comes from a
    //   relation.
    let scopes = ordered(sqlx::query_file!("assets/sql/diagrams/scopes.sql").fetch_all(&pool).await?);
    // ⛔ A MAPPING THAT NAMES AN ALREADY-SPENT ELEMENT RENDERS NOTHING AND NO LAW SEES IT.
    //   Declaring this one against `documentation`, which the pools and the lanes already use,
    //   emits none and counts as covered.
    let citations = ordered(sqlx::query_file!("assets/sql/diagrams/citations.sql").fetch_all(&pool).await?);
    // ⭐⭐⭐ `F` AT LAYER GRAIN. `calledElement` names a PROCESS, so 17 edges collapse to 5
    //   document pairs and the layer survives only inside `@name`. `tRelationship` takes QNames
    //   at both ends and a REQUIRED `type`, which is exactly what an `association` lacks.
    let descents = ordered(sqlx::query_file!("assets/sql/diagrams/descents.sql").fetch_all(&pool).await?);
    // ⭐⭐⭐ WHICH RELATION EACH SENTENCE STATES, WHICH IS THE `--` LINE OWED BY AN ARTIFACT.
    //   A `documentation` element carrying a sentence and no route back to the relation that
    //   produced it is a generated `.sql` file without its one `--` line. ⛔ Read from here
    //   rather than written as a literal beside each `writeln!`: a pointer this program made up
    //   is a claim about the model that no law can reach, which is the `invents` state
    //   `diagrams/domain_objects.sqlc` names.
    let annotated = ordered(sqlx::query_file!("assets/sql/diagrams/annotated.sql").fetch_all(&pool).await?);
    // ⭐⭐⭐ THE NOTES A DOCUMENT OWES ON ITS OWN FACE. `documentation` is INVISIBLE in every
    //   rendering, so a fact filed there alone is in the artifact and on no page.
    //   `textAnnotation` is the only element in BPMN that puts words on the canvas, and
    //   *documentation is spent instead* withholds it on a true statement about the wrong
    //   property.
    let legends = ordered(sqlx::query_file!("assets/sql/diagrams/legends.sql").fetch_all(&pool).await?);
    // ⭐⭐⭐ THE SECOND `pm:ForeignId`, AND THE ONLY PLACE IT IS DRAWN AS A REFERENCE. A `between`
    //   says which layer of which OTHER document the double counting runs against, and it is the
    //   same reference shape as a part. ⛔ Only the RESOLVED ones can be emitted: a QName needs a
    //   prefix and a prefix needs an import, so a `between` naming a document nobody filed is
    //   unreferenceable here, and the schema calls that filing ORDINARY.
    let attributions = ordered(sqlx::query_file!("assets/sql/eliminations/resolved.sql").fetch_all(&pool).await?);
    let induction_count: i64 = sqlx::query_scalar("SELECT count(*) FROM pm.induction")
        .fetch_one(&pool).await?;
    let draw_count: i64 = sqlx::query_scalar("SELECT count(*) FROM pm.draw").fetch_one(&pool).await?;
    let expected = ordered(sqlx::query_file!("assets/sql/diagrams/expected.sql").fetch_all(&pool).await?);
    let grain = ordered(sqlx::query_file!("assets/sql/diagrams/lane_grain.sql").fetch_all(&pool).await?);
    let elims = ordered(sqlx::query_file!("assets/sql/diagrams/eliminations.sql").fetch_all(&pool).await?);
    let levels = ordered(sqlx::query_file!("assets/sql/diagrams/levels.sql").fetch_all(&pool).await?);
    // ⭐⭐ THE ORDINAL RANK OF EACH LAYER, CARRIED INTO THE ARTIFACT. `examples/rendering/main.rs` reads
    //   only the BPMN, because a cache derived from the source rather than the artifact is a
    //   stale cache, and the rank is NOT recoverable from what BPMN can express:
    //   `calledElement` names a PROCESS, so the emitted call graph links filing to filing while
    //   `F` links layer to layer. Measured NOW, because that sentence carried `10 pairs against
    //   27` from before local and foreign parts were split: 17 foreign part edges at layer grain
    //   collapse to 5 document pairs.
    //   ⛔ `documentation` is the only schema-legal home and it is untyped text. It carries the
    //   WORDS and not the claim, exactly as `diagrams/domain_objects.sqlc` says of it. A tool
    //   cannot act on this; a reader can. `extensionElements` would look like structure and be
    //   none, which that roster refuses by name.
    let ranks = ordered(sqlx::query_file!("assets/sql/rank/evaluation_order.sql").fetch_all(&pool).await?);
    let objects = ordered(sqlx::query_file!("assets/sql/diagrams/domain_objects.sql").fetch_all(&pool).await?);
    // ⭐⭐⭐ WHICH GRAPH THIS PROGRAM DRAWS, DECLARED, AND THE MEASUREMENT THAT LICENSES IT.
    //   Three graphs compose in this model and only one clustering can be a diagram's nesting,
    //   so `examples/graphs/main.rs` makes the graph a SLOT. This program cannot: it emits one document
    //   per FILING, and cutting a graph by filing is not free.
    let decomposition = ordered(sqlx::query_file!("assets/sql/rank/decomposition.sql").fetch_all(&pool).await?);
    let governance = ordered(sqlx::query_file!("assets/sql/diagrams/ungoverned.sql").fetch_all(&pool).await?);

    // notation -> filing, which is what an `import` resolves.
    // ⭐ Every column read here is NOT NULL in `assets/ddl/schema.ddl`, so sqlx types them
    //   `String` rather than `Option<String>`. That is the DDL's typed-absence discipline paying
    //   out in a second language: a nullable column would arrive as an `Option` and force this
    //   program to say what it meant by the absence.
    let by_notation: BTreeMap<&str, &str> =
        notations.iter().map(|n| (n.notation.as_str(), n.filing.as_str())).collect();
    let notation_of: BTreeMap<&str, &str> =
        by_notation.iter().map(|(n, f)| (*f, *n)).collect();

    // ⭐⭐⭐ THE POINTER EVERY SENTENCE CARRIES, KEYED BY THE THING IT IS ABOUT. A `documentation`
    //   element is untyped text and BPMN gives it no provenance attribute, so the citation goes
    //   in the prose, the way `assets/sql/*.sql` carries its `--` line in a comment.
    // ⛔ IT PANICS RATHER THAN OMITTING. A missing pointer is a sentence in the artifact that
    //   nothing attributes, and silently writing the sentence anyway is how 71 facts came to sit
    //   in these documents with no page and no source.
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
    // ⛔ Wiped, exactly as `assets/sql/` is wiped. A stale document is worse than none: it is a
    //    claim about a model that has moved.
    // ------------------------------------------------------------------
    if Path::new(OUT).exists() {
        fs::remove_dir_all(OUT)?;
    }
    fs::create_dir_all(OUT)?;

    for f in &filings {
        let filing = f.filing.as_str();

        // The imports this document owes: every notation it reaches through a part.
        // ⛔ TWO REFERENCES REACH OUT OF A FILING, NOT ONE. This read the parts alone, and
        //   `diagrams/cross_document.sqlc` said so in prose: *the only place this model reaches
        //   out of a filing at all*. An `asrt:Elimination/between` is the other, and in this
        //   corpus all 3 documents it names are already reached by a part, so the union changes
        //   no count. Luck, not construction, and a count cannot tell the two apart.
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
        // ⭐ The provenance line, and it is a COMMENT on purpose: the `--` line that survives into
        //   generated SQL is a comment too. It is for the reader of the artifact, and a schema
        //   element would be this emitter inventing a field.
        writeln!(x, "<!-- GENERATED from process-modulus by examples/diagramming/main.rs. DO NOT EDIT.")?;
        writeln!(x, "     source: the filing `{}`; change the model, not this file.", esc(filing))?;
        writeln!(x, "     laws:   assets/sqlc/diagrams/roster.sqlc -->")?;
        let target = notation_of.get(filing).copied().unwrap_or(filing);
        write!(x, r#"<definitions xmlns="{BPMN_NS}""#)?;
        // ⛔ A QName WITH NO PREFIX RESOLVES TO THE DEFAULT NAMESPACE, WHICH HERE IS BPMN'S OWN.
        //   `association/@sourceRef` is a QName, so a same-document reference to a lane needs a
        //   prefix bound to THIS document's targetNamespace or it names a BPMN element instead.
        //   The foreign prefixes f0..fN do this for `calledElement`; `tns` is the same binding
        //   for a reference that stays inside the document, which is what a coupling needs.
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

        // ⭐ A `category` IS A `rootElement`, so it sits beside the collaboration and the process
        //   rather than inside either, and its values are QName addressable from any document
        //   that imports this one. Nothing crosses a document yet; the addressability is BPMN's.
        let mine_cats: Vec<&str> =
            categories.iter().filter(|c| c.filing == filing).map(|c| c.layer.as_str()).collect();
        if !mine_cats.is_empty() {
            writeln!(x, "  <category id=\"{}\" name=\"induction\">", id("cat", &[filing]))?;
            writeln!(x, "    <documentation>pm:Induction: which layers each operation induces \
                         demand into. A COVER and not a partition, so an operation may appear in \
                         several of these and in exactly one lane.{}</documentation>",
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
        writeln!(x, "    <documentation>pm:Stack of `{}`. Rendered from process-modulus; the \
                     arithmetic is not here, and how much of the system this stack holds is on \
                     the laneSet.{}</documentation>", esc(filing), cite("document"))?;
        for c in citations.iter().filter(|c| c.composition == filing) {
            writeln!(x, "    <documentation>filed under: {}. ⛔ Four typed fields (taxonomy, \
                         instrument, clause, version) arrive here as one string, so a reader can \
                         follow the citation and a tool cannot resolve it.{}</documentation>",
                     esc(c.cited.as_deref().unwrap_or("")), cite("process, the citation"))?;
        }

        // ⛔⛔ ONE LANE SET, AND THE CHOICE IS THE FINDING. D and N are both P x L over one
        //    process and BPMN would hold each as a `laneSet`. Emitting BOTH gives every layer TWO
        //    lane elements with nothing but a matching `name` to say they are the same layer, so
        //    the conformed key `(filing, layer)` is lost in the rendering. One lane set is what a
        //    modeller files, it is the DRAW, and the induction is what falls off. See the
        //    enumeration at the end: N is on it, carrying `decider`.
        let mine: Vec<&str> =
            layers.iter().filter(|l| l.filing == filing).map(|l| l.layer.as_str()).collect();

        // ⭐ THE NESTING, KEYED BY LAYER WITHIN THIS FILING. A LOCAL part makes its target a CHILD
        //   lane; a FOREIGN one stays a flow node, because a lane cannot live in another document.
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

        // ⭐⭐ THE SEARCH SITS ON THE `laneSet`, BECAUSE THE laneSet IS THE PARTITION THE SEARCH
        //   IS ABOUT. *Did anybody test whether these layers move together* is a question about
        //   the stack and not about any one lane, and `tLaneSet` extends `tBaseElement`, so
        //   `documentation` is available and already spent. No new element is owed for this.
        let answer = searches
            .iter()
            .find(|s| s.filing == filing)
            .and_then(|s| s.answer.as_deref())
            .unwrap_or("stated");
        writeln!(x, "    <laneSet id=\"{}\" name=\"draw\">", id("lanes", &[filing]))?;
        // ⭐⭐ TWO DOCUMENTATION ELEMENTS, ONE PER FACT, BECAUSE `tBaseElement/documentation` IS
        //   `maxOccurs="unbounded"`. A stack states its SCOPE and its coupling SEARCH, and they
        //   are two different answers about the same partition, so folding them into one string
        //   would make each unreadable and neither countable.
        let sc = scopes.iter().find(|s| s.filing == filing);
        writeln!(x, "      <documentation>scope: {}. `complete` asserts there are no other layers \
                     of this system, `scoped` says somebody established what lies outside and \
                     excluded it, `unbounded` says nobody looked. ⛔ A LANE SET CANNOT SAY WHICH, \
                     so this sentence is the only place it is said. Basis: {}{}</documentation>",
                 sc.and_then(|s| s.extent.as_deref()).unwrap_or("typed absent"),
                 esc(sc.and_then(|s| s.basis.as_deref()).unwrap_or("not stated")),
                 cite("lane set, the scope"))?;
        writeln!(x, "      <documentation>coupling search: {answer}. `unmeasured` is nobody \
                     looked, `none` is somebody looked and found no dependence, `notApplicable` \
                     is there is no pair to couple, `stated` is the dependences drawn here. An \
                     absent line is not independence.{}</documentation>",
                 cite("lane set, the coupling search"))?;
        for layer in mine.iter().filter(|l| !nested.contains(*l)) {
            lane(&mut x, 6, filing, layer, &kids, &rank_of, &nodes, &cite("lane"))?;
        }
        writeln!(x, "    </laneSet>")?;

        // ⛔ THE MEMBER DECLARES THE COVER, WHICH IS THE WHOLE REASON THIS FITS. A lane collects
        //   its members and can collect each one once; a `categoryValue` collects nobody, so the
        //   flow node says which categories it is in and may say it as many times as it likes.
        //   `tFlowElement`'s sequence puts `categoryValueRef` first, before any activity content.
        for o in ops.iter().filter(|o| o.filing == filing) {
            let refs: Vec<&str> = cat_members
                .iter()
                .filter(|m| m.filing == filing && m.operation == o.label)
                .map(|m| m.layer.as_str())
                .collect();
            // ⛔ `tBaseElement` puts `documentation` FIRST, before `categoryValueRef` on
            //   `tFlowElement`, so the notation position is written above the cover and the
            //   element is only self-closing when it owes neither.
            let crossing = crossings
                .iter()
                .find(|c| c.filing == filing && c.label == o.label);
            // ⭐⭐ BOTH ARMS REACH THE PAGE, because `notationPosition` is required and the
            //   absence is the ordinary answer. A task carrying nothing would read as *this
            //   model does not reach the notation*, where the filing actually says which of
            //   three things it means. Same argument as the coupling search on the laneSet.
            let unstated = o.foreign_absent.as_deref();
            if refs.is_empty() && crossing.is_none() && unstated.is_none() {
                writeln!(x, "    <task id=\"{}\" name=\"{}\"/>",
                         id("task", &[filing, &o.label]), esc(&o.label))?;
            } else {
                writeln!(x, "    <task id=\"{}\" name=\"{}\">",
                         id("task", &[filing, &o.label]), esc(&o.label))?;
                if let Some((notation, node)) = crossing.and_then(|c| {
                    // ⛔ The relation restricts to the operations that filed one, so a NULL here
                    //   would mean the restriction stopped restricting rather than that this
                    //   operation names nothing. Dropping the sentence silently is how a fact
                    //   comes to be in the model and on no page.
                    Some((c.foreign_notation.as_deref()?, c.foreign_id.as_deref()?))
                }) {
                    writeln!(x, "      <documentation>notation position: {} / {}. ⛔ THAT ID IS IN \
                                 ANOTHER DOCUMENT, not in this one: this file renders the model, \
                                 and the id names the node in the process notation the filer was \
                                 reading. No authority publishes it, so it resolves by agreement \
                                 and never by lookup.{}</documentation>",
                             esc(notation), esc(node),
                             cite("task, the notation position"))?;
                } else if let Some(reason) = unstated {
                    // ⛔ THE REASON IS THE MODEL'S VOICE AND THE GLOSS IS THE EMITTER'S. The word
                    //   comes from the filing; the sentence saying what the three words mean is
                    //   true of this schema whatever any corpus holds, so it may be a literal.
                    writeln!(x, "      <documentation>notation position: none stated, and the \
                                 filing says why: {}. `none` is somebody looked and this operation \
                                 is in no process notation, `unmeasured` is a notation exists and \
                                 nobody has located it there, `notApplicable` is this filing has \
                                 no notation to point into. ⛔ AN ABSENT POSITION IS NOT A GAP IN \
                                 THE MODEL: most operations file one of these.{}</documentation>",
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
            // ⭐ A local part is an embedded subProcess and a foreign one is a call. Both are
            //   substitution; only the second crosses a document, which is why only it needs an
            //   import. The QName prefix is what makes `calledElement` resolvable at all.
            // ⛔⛔ A LOCAL PART IS NOT A FLOW NODE AT ALL. It is a nested LANE, written
            //   by `lane()` above, because a fusion's parts PARTITION the composed layer rather
            //   than sitting inside it as activities. That is what keeps it at layer grain.
            if pf == filing {
                let _ = (cl, pl);
            } else {
                let i = imports.iter().position(|n| *n == pn).expect("a foreign part imports");
                writeln!(x, "    <callActivity id=\"{}\" name=\"{} &lt;- {}/{}\" calledElement=\"f{i}:{}\"/>",
                         id("call", &[filing, cl, pf, pl]), esc(cl), esc(pf), esc(pl),
                         id("proc", &[pf]))?;
            }
        }

        // ⭐⭐⭐ THE LEGEND, FLOATING AND UNATTACHED. A `textAnnotation` is an artifact and may
        //    stand alone; attaching it would spend `association` a SECOND way, which is exactly
        //    the collision that ruled that element out for `F`. The two consolidation filings
        //    already carry coupling lines and a reader could not tell which dotted line was which.
        //
        // ⛔ A NOTE IS OWED WHEREVER THE NOTATION'S DEFAULT READING IS WRONG, and nowhere else. A
        //   pool reads as *the system*, an absent line reads as INDEPENDENCE, a dotted arrow reads
        //   as FLOW, a dashed box reads as a CONTAINER. Four wrong readings, four notes, and a
        //   legend for a glyph the page does not carry is noise.
        for l in legends.iter().filter(|l| l.filing.as_deref() == Some(filing)) {
            let body = match l.note.as_deref().unwrap_or("") {
                "scope" => format!(
                    "SCOPE: {}. This pool is a PROJECTION of one system and not the system.",
                    sc.and_then(|s| s.extent.as_deref()).unwrap_or("typed absent")),
                "search" => format!(
                    "COUPLING SEARCH: {answer}. An absent dependence line is NOT independence."),
                // ⛔ THE CONTINUATIONS ARE ESCAPED, AND THAT IS NOT A STYLE POINT. Without the
                //   `\\` a wrapped literal keeps its own INDENTATION, so both of these reached
                //   the page with fifty spaces in the middle of the sentence. It was invisible in
                //   the source, invisible in the BPMN, and drawn.
                "dependence" => "A DOTTED ARROW between two lanes is an observed DEPENDENCE, \
                                 not a supply edge, and never evidence for a fusion.".to_string(),
                "cover" => "A DASHED BOX is a COVER, not a container: an operation may be in \
                            several and is in exactly one lane.".to_string(),
                other => format!("{other}"),
            };
            // ⛔ THE ONE PLACE THE POINTER IS READ OFF THE ROW RATHER THAN THE KIND. A legend is
            //   the only sentence here a person reads off the PICTURE, so the relation it states
            //   travels with it: `diagrams/legends.sqlc` unions four arms and each names its own.
            let body = format!("{body} [assets/sqlc/{}]",
                               l.states.as_deref().expect("a legend names the relation it states"));
            writeln!(x, "    <textAnnotation id=\"{}\">", id("note", &[filing, l.note.as_deref().unwrap_or("")]))?;
            writeln!(x, "      <text>{}</text>", esc(&body))?;
            writeln!(x, "    </textAnnotation>")?;
        }

        // ⭐⭐ THE GLYPH, AND IT COMES LAST BECAUSE `tProcess` PUTS `artifact` AFTER `flowElement`.
        //   A `group` is to `categoryValueRef` what a `lane` is to `flowNodeRef`: the drawn shape
        //   of an incidence held elsewhere. Without it the cover is readable and invisible, which
        //   in this pipeline is the same as not being emitted.
        for layer in &mine_cats {
            writeln!(x, "    <group id=\"{}\" categoryValueRef=\"{}\"/>",
                     id("grp", &[filing, layer]), id("cv", &[filing, layer]))?;
        }

        // ⭐⭐⭐ C, THE MODEL'S FALSIFIER, DRAWN FOR THE FIRST TIME. `tAssociation` extends
        //    `tArtifact` with `sourceRef` and `targetRef` as REQUIRED unconstrained QNames, so it
        //    is a general typed edge and two LANES are a legal pair. It was withheld on the
        //    reason *it attaches a textAnnotation*, which is what an association is FOR and not
        //    what it can HOLD.
        //
        // ⭐⭐ DIRECTION `One`, AND THE ARROWHEAD IS SAFE HERE FOR A MEASURABLE REASON. BPMN
        //    glosses it as a direction of flow, and a coupling is a DEPENDENCE, so the risk is a
        //    reader taking it for a supply edge. `F` is drawn as CONTAINMENT and as nodes and
        //    never as an edge, so this is the only line between two things in the whole emitted
        //    notation and there is nothing for it to be confused with. ⚠️ The day `F` is drawn as
        //    an edge, this argument expires and the direction has to be reconsidered.
        for d in deps.iter().filter(|d| d.filing == filing) {
            writeln!(x, "    <association id=\"{}\" sourceRef=\"tns:{}\" targetRef=\"tns:{}\" \
                         associationDirection=\"One\">",
                     id("dep", &[filing, &d.from_layer, &d.to_layer]),
                     id("lane", &[filing, &d.from_layer]), id("lane", &[filing, &d.to_layer]))?;
            writeln!(x, "      <documentation>an observed dependence: relieving `{}` moved `{}`. \
                         NOT a supply edge and never evidence for a fusion. ⛔ What was observed, \
                         and how strongly, is not here.{}</documentation>",
                     esc(&d.from_layer), esc(&d.to_layer), cite("dependence"))?;
            writeln!(x, "    </association>")?;
        }

        writeln!(x, "  </process>")?;

        // ⭐⭐⭐ THE DIAGRAM'S OWN PLACE IN THE DOCUMENT. `tDefinitions` puts `bpmndi:BPMNDiagram`
        //    last, after the root elements, and a document that declares nothing here leaves the
        //    SVG stage to invent coordinates: the same model laid out two ways, with nothing
        //    tying them and the shipped one derivable from nothing.
        //
        // ⭐⭐ THE DOCUMENT DECLARES ITS LAYOUT AND THE SVG RENDERS WHAT IS DECLARED, which is
        //    what `rendering.rs`'s own header claims for itself: a cache extracted from the
        //    GENERATED artifact rather than computed beside it.
        //
        // ⛔⛔⛔ AND EVERY DRAWN ELEMENT NEEDS ONE, NOT ONLY THE PRIMITIVES. Declaring a shape per
        //    pool, lane and flow node and nothing else leaves a `group`, an `association` and a
        //    `textAnnotation` with no interchange at all, which is 42 elements lost to anybody
        //    who is not the renderer beside this program: absent DI is not an error, it is
        //    nothing drawn.
        //
        // ⭐⭐ AND THE ARGUMENT AGAINST DECLARING THEM IS ABOUT THE WRONG STAGE. Filing a derived
        //    coordinate in a RELATION is what `diagrams/shapes.sqlc` refuses, which is why it
        //    carries no x or y for anything; DERIVING one into an artifact is what both stages do
        //    for every box here. So the derivation belongs upstream of the document that carries
        //    it, and the same numbers reach both stages instead of one recomputing them from the
        //    other's output. Nothing new is filed. docs/plans/FINDINGS-2026-09-10 finding 2.
        //
        // ⚠️ THE MATH IS `rendering.rs`'s OWN, ON PURPOSE, so the picture does not move: a cover
        //   is the bounding box of its members inflated by 6, a dependence runs out of the source
        //   lane to a gutter 26 left of the leftmost of the pair and back in, and the notes stack
        //   under the pool at 30 apiece.
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

        // ⭐ THE COVER, AS THE HULL OF WHAT IT COVERS. A `group` carries no membership itself:
        //   the flow nodes name it through `categoryValueRef`, so its box is the union of theirs.
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

        // ⭐ THE NOTES, IN A BAND UNDER THE POOL. An artifact may sit outside a participant, and
        //   these belong outside it: each one says how the picture ABOVE must not be read.
        for (i, l) in legends.iter().filter(|l| l.filing.as_deref() == Some(filing)).enumerate() {
            let ny = 44 + pool_h + i * 30;
            writeln!(x, "      <bpmndi:BPMNShape id=\"{}\" bpmnElement=\"tns:{}\">",
                     id("shape", &[filing, &id("note", &[filing, l.note.as_deref().unwrap_or("")])]),
                     id("note", &[filing, l.note.as_deref().unwrap_or("")]))?;
            writeln!(x, "        <dc:Bounds x=\"20\" y=\"{ny}\" width=\"{}\" height=\"28\"/>",
                     WIDTH - 40)?;
            writeln!(x, "      </bpmndi:BPMNShape>")?;
        }

        // ⚠️ EVERY SHAPE FIRST, THEN EVERY EDGE, AND `di:Plane` DOES NOT REQUIRE IT. Its content
        //    model is one repeated `di:DiagramElement` substitution group, so a shape and an edge
        //    may interleave and the documents that did were legal. ⛔ No tool emits them that way,
        //    and finding 1 was a document that looked legal and was refused, so removing the
        //    doubt is worth more than the interleaving: grouping them costs nothing.
        // ⭐ THE DEPENDENCE, AS A ROUTE RATHER THAN A BOX. `bpmndi:BPMNEdge` takes `di:waypoint`,
        //   two at minimum; four describe the gutter run, which is what keeps the line outside
        //   both lanes so a reader cannot mistake it for something inside one.
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

        // ⛔⛔⛔ AND IT IS EMITTED HERE, AFTER THE DIAGRAM, BECAUSE `tDefinitions` IS AN
        //    `xsd:sequence`: import*, extension*, rootElement*, bpmndi:BPMNDiagram*,
        //    relationship*. The order is normative, so a `relationship` ahead of the diagram is
        //    a document a schema processor REFUSES. ⭐ The comment above stated that rule and
        //    the code three lines under it did the opposite, which is the sharpest shape a
        //    defect takes here: the emitter knew the constraint and wrote it down.
        // ⛔ NOTHING IN THIS REPOSITORY COULD SEE IT. `roster.sqlc` counts elements and this
        //    changes no count; the read-back laws below find the elements wherever they sit;
        //    `xmllint` is never run on the output. It took a BPMN 2.0 reader in another
        //    checkout, deserializing against the OMG schemas, and the four documents it refused
        //    are exactly the four that emit a `relationship`.
        // ⚠️ Those four are also the only four carrying a `callActivity`, so no cross-document
        //    call in this corpus had ever reached that reader's semantic checks: it stopped at
        //    the ordering error and never ran them. docs/plans/FINDINGS-2026-09-10.
        // ⭐⭐⭐ `F`, AT LAYER GRAIN, AS A REFERENCE RATHER THAN AS A NAME. `tDefinitions` puts
        //    `relationship` LAST, after the root elements and the diagrams, which is where a
        //    fact about the document rather than about its contents belongs. ⛔ It is not a
        //    glyph and never will be: no diagram shows it, so this promotes the fact for a TOOL
        //    and leaves the reader with the `callActivity` name it already had.
        //
        // ⭐⭐ `type` IS REQUIRED, AND THAT IS THE DIFFERENCE FROM AN `association`. An
        //    association carries no name and no type, so a second use of it would make a
        //    dependence and a composition indistinguishable in the two documents that hold both.
        for d in descents.iter().filter(|d| d.composition == filing) {
            let i = imports.iter().position(|n| *n == d.part_notation).expect("a foreign part imports");
            writeln!(x, "  <relationship type=\"process-modulus:part\" direction=\"Forward\">")?;
            writeln!(x, "    <documentation>a composed layer and the layer it is composed FROM. \
                         `calledElement` names a process, so the call beside this one is at \
                         document grain; this is the same fact at layer grain.{}</documentation>",
                     cite("relationship"))?;
            writeln!(x, "    <source>tns:{}</source>", id("lane", &[filing, &d.composed_layer]))?;
            writeln!(x, "    <target>f{i}:{}</target>", id("lane", &[&d.part_filing, &d.part_layer]))?;
            writeln!(x, "  </relationship>")?;
        }

        // ⭐⭐⭐ THE SECOND TYPE, WHICH IS THE ELEMENT EARNING ITS CHOICE. `association` was
        //    refused for `F` because it carries no type and a second use would make two facts
        //    indistinguishable. `tRelationship/@type` is REQUIRED, so a second relation costs
        //    nothing but a different string, and the laws filter on it. This is that argument
        //    being spent rather than merely stated.
        for b in attributions.iter().filter(|b| b.composition == filing) {
            let i = imports.iter().position(|n| *n == b.notation).expect("a between imports");
            writeln!(x, "  <relationship type=\"process-modulus:elimination-between\" direction=\"Forward\">")?;
            writeln!(x, "      <documentation>a composed layer, and a layer of another document \
                         the composer states the double counting runs against. ⛔ NOT a part: \
                         nothing is composed from this, and the SIZE of the overlap is not \
                         here.{}</documentation>", cite("relationship, an attribution"))?;
            writeln!(x, "    <source>tns:{}</source>", id("lane", &[filing, &b.composed_layer]))?;
            writeln!(x, "    <target>f{i}:{}</target>",
                     id("lane", &[&b.resolved_filing, &b.layer]))?;
            writeln!(x, "  </relationship>")?;
        }
        writeln!(x, "</definitions>")?;
        fs::write(format!("{OUT}/{filing}.bpmn"), x)?;
    }

    // ------------------------------------------------------------------
    // ⭐⭐⭐ THE PRECONDITION OF THE WHOLE MAPPING, CHECKED BEFORE ANYTHING IS WRITTEN. A layer is
    //    a lane only because `(filing, layer)` is the coarsest key nothing refines. Every
    //    reference into the layer dimension names the layer ENTIRE; one that named a piece of a
    //    layer would move the partition down a level and every lane below would be wrong.
    // ------------------------------------------------------------------
    let refines: Vec<&str> = grain
        .iter()
        .filter(|g| g.whole != Some(true))
        .map(|g| g.referrer.as_deref().unwrap_or("?"))
        .collect();
    // ------------------------------------------------------------------
    // ⛔⛔⛔ THIS PROGRAM DRAWS THE LAYER GRAPH, AND THAT WAS RECORDED AS A SILENT PICK AMONG
    //    THREE EQUALS. IT IS NOT. It is the only one of the three whose per-filing projection
    //    preserves the graph's CYCLE SPACE, and `rank/decomposition.sqlc` is the measurement.
    //
    // ⛔⛔ THE UNIT GRAPH'S ONLY CYCLE SPANS TWO FILINGS. `GPU-hour -> node-hour` and
    //    `node-hour -> GPU` are filed in `every-unit-cycle`; the edge closing them,
    //    `GPU -> GPU-hour`, is filed in `merge-holding-composition`. So the fixture NAMED
    //    `every-unit-cycle` contains no unit cycle on its own, and a per-filing unit diagram
    //    would show two edges, no loop, and nothing for
    //    `checks/conversion_cycle_does_not_close` to be about: well formed, validating, and
    //    quietly missing the one property it was drawn to show.
    //
    // ⭐ SO THE CHOICE IS STATED AND LICENSED RATHER THAN HARDCODED. Making the graph a slot
    //   without this measurement would have let somebody pick a graph that lies.
    // ⚠️ Surviving is a PRECONDITION and never a reason: `claimants` survives trivially, with no
    //   edges at all.
    // ------------------------------------------------------------------
    const EMITS_GRAPH: &str = "layers";
    let licensed = decomposition
        .iter()
        .find(|d| d.graph.as_deref() == Some(EMITS_GRAPH))
        .ok_or("rank/decomposition.sqlc does not measure the graph this program draws")?;
    println!("THE GRAPH THIS PROGRAM DRAWS, and whether cutting it by filing is free");
    for d in &decomposition {
        println!("   {:<7} corpus-wide dim {}   summed per filing {}   {}",
                 d.graph.as_deref().unwrap_or("?"),
                 d.corpus_wide.unwrap_or(-1), d.summed_per_filing.unwrap_or(-1),
                 if d.survives_the_cut == Some(true) { "survives the cut" }
                 else { "⛔ the cut DESTROYS a cycle" });
    }
    assert!(
        decomposition.len() > 1,
        "only one graph is measured, so this law cannot discriminate between a graph that \
         survives the cut and one that does not"
    );
    assert!(
        licensed.survives_the_cut == Some(true),
        "this program emits one document per FILING and draws `{EMITS_GRAPH}`, whose cycle space \
         is {} corpus-wide and {} summed per filing: cutting it by filing destroys a cycle, so \
         every document would validate and none would carry the property the graph is for",
        licensed.corpus_wide.unwrap_or(-1), licensed.summed_per_filing.unwrap_or(-1)
    );
    println!("   ⭐ `{EMITS_GRAPH}` is the only one of the three that survives, which is why this");
    println!("      program does not offer the graph as a slot the way examples/graphs/main.rs does.\n");

    println!("THE PARTITION, before anything is drawn");
    println!("   {} references into the layer dimension, {} of them naming a piece of a layer",
             grain.len(), refines.len());
    assert!(
        refines.is_empty(),
        "something refines a layer, so a lane is not a layer and the mapping moves down a \
         level: {refines:?}"
    );

    println!("\nEMITTED into {OUT}/");
    println!("   {} definitions documents, each complete and openable alone", filings.len());

    // ------------------------------------------------------------------
    // ⭐⭐⭐ COUNT THE ARTIFACT, NOT THE INTENTION. A counter incremented beside each `writeln!`
    //    counts what this program MEANT to write. Reading the files back counts what is actually
    //    on disk, and the two differ whenever a write lands in the wrong document, a branch is
    //    skipped, or the emitter is edited without its counter. The same reason a number in prose
    //    rots: only a program that reads the artifact is reporting on the artifact.
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
        // ⛔⛔ THE CONTAINERS WERE UNGOVERNED AND THAT WAS 75 OF 208 EMITTED ELEMENTS. Every law
        //   above counts a LEAF of the rendering, so this emitter could have written two
        //   `laneSet`s per process and every one of them would still have passed.
        //   ⛔⛔⛔ AND THE FIRST FIX WAS ITSELF THE BUG IT WAS CATCHING: written as one law over
        //   `min` of the five, it could only see a container appearing too FEW times. Probed with
        //   a second lane set, `lanes` fired at 102 and this stayed a comfortable 15. FIVE laws,
        //   because they are five different defects and one number cannot fail five ways.
        ("definitions", count("<definitions ")),
        ("collaboration", count("<collaboration ")),
        ("process", count("<process ")),
        ("lane_set", count("<laneSet ")),
        ("documentation", count("<documentation>")),
    ]);

    // ⛔⛔⛔ AND THE CLOSURE: every element kind on disk is either counted by a law or is a
    //    container. A law that counts SOME elements says nothing about the ones nobody listed,
    //    and "nothing appears that is not in the model" cannot be checked one element at a time.
    //    This is the only assertion here that grows when the emitter does.
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
        // ⛔ THE LOCAL NAME, NOT THE PREFIX. This stopped at the first non-alphanumeric, which
        //   was fine while nothing in the document was namespaced and reported `bpmndi` and `dc`
        //   as element kinds the moment the diagram interchange arrived. A closure over element
        //   kinds has to know what an element kind IS.
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
    // ⛔⛔⛔ THE ATTRIBUTION LAW, AND IT IS NOT A COUNT BECAUSE IT CANNOT BE ONE. Every law above
    //    asks HOW MANY of an element the artifact carries, and a sentence is not that kind of
    //    fact: fifteen documents can carry fifteen correctly counted `documentation` elements and
    //    each of them say something no relation states, with the count exact the whole way. The
    //    only question worth asking of prose in an artifact is WHAT STATES IT.
    //
    // ⭐⭐⭐ THREE OBLIGATIONS, AND THE THIRD IS THE ONE WITH TEETH. A pointer must be THERE, it
    //    must RESOLVE to a relation in this tree, and it must name a relation THIS PROGRAM
    //    ACTUALLY READ. Without the third a citation is decorative: an emitter free to cite
    //    anything cites what sounds right, which is the `invents` state with a filename on it.
    //    Reading the program's own source is what makes the artifact's provenance checkable
    //    against the thing that produced it rather than against a second list that drifts beside
    //    it, and it is `examples/compositions/main.rs`'s idiom: the source tree is a fact.
    //
    // ⚠️ IT GOVERNS `text` AS WELL AS `documentation`, AND THOSE ARE THE ONES THAT MATTER MOST. A
    //   `documentation` element is read by a tool that could have opened the database anyway. A
    //   `textAnnotation` is read by a person holding a picture, who has no other route back.
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
    // The relations this program reads, from its own source. ⛔ `query_file!` takes a literal, so
    // a query the emitter runs is visible here and a query it does not run is not.
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

    // ⛔⛔⛔ AND EVERY ROW SET THIS PROGRAM READS GOES THROUGH `ordered`, ASSERTED ON THE SOURCE
    //    RATHER THAN TRUSTED. A `fetch_all` that escapes it serializes in the order the planner
    //    returned, and the artifact then depends on the physical layout of a table: measured, a
    //    `CLUSTER` on `pm.part` changes no row and changes the emitted document. `assets/sql/`
    //    has `--verify` behind it and these documents have nothing, so the only thing standing
    //    between a fresh clone and a diff nobody can read is this line.
    // ⛔ THE NEEDLE IS SPLIT SO THIS LINE IS NOT ITS OWN COUNTEREXAMPLE, and the statement is
    //   what is inspected rather than a fixed window, because a wrapped fetch is often two lines
    //   away from the `ordered(` that wraps it.
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
    // ⛔⛔⛔ `tDefinitions` IS AN `xsd:sequence`, SO THE ORDER OF ITS CHILDREN IS NORMATIVE, AND
    //    NOTHING HERE COULD CHECK IT. import*, extension*, rootElement*, bpmndi:BPMNDiagram*,
    //    relationship*. This emitter put `relationship` ahead of the diagram, and four
    //    documents were refused by a schema processor while every law in this file passed: the
    //    counts do not move, the read-back laws find an element wherever it sits, and the OMG
    //    schemas are not vendored here so nothing validates the output against them.
    //
    // ⭐⭐ SO CHECK THE INVARIANT THE ORDER WOULD PRODUCE, which is the same repair the SVG
    //    staleness needed: a position is not assertable from inside the thing being positioned,
    //    but the RESULT is readable off the artifact. Every `relationship` must open after the
    //    diagram closes. ⚠️ It cannot stand in for a schema processor and is not meant to; it
    //    holds the one ordering this emitter has been wrong about. docs/plans/FINDINGS-2026-09-10.
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
         nothing and the four documents a schema processor refused would be refused again"
    );
    assert!(
        misordered.is_empty(),
        "tDefinitions is an xsd:sequence and puts `relationship` after `bpmndi:BPMNDiagram`, so \
         these documents are well formed, correct in every count here, and refused by a schema \
         processor: {misordered:?}"
    );
    println!("   ⭐ {ordered_checked} documents emit a relationship, every one after the diagram");
    println!("      closes. `tDefinitions` is a sequence, so that order is the difference between");
    println!("      a document a third-party reader opens and one it refuses at byte 5867.");

    // ⛔ AND THE OTHER DIRECTION, WHICH IS THE `composition_citation` DEFECT IN A NEW PLACE: a
    //   source declared and never reaching the artifact is a pointer nobody can follow because
    //   nothing carries it. `diagrams/annotated.sqlc` and `diagrams/legends.sqlc` are where the
    //   declaration lives, so the two sets are required to be the same set.
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
    // ⛔⛔⛔ THE OTHER HALF OF THE CLOSURE, AND IT CANNOT BE DERIVED FROM THE ARTIFACT. Everything
    //    above reads the element kinds off disk, so it can report an element this program DREW
    //    and never decided about, and it can never report an element BPMN HAS that this program
    //    ignored: an unused glyph leaves no trace to read. `diagrams/notation.sqlc` is the icon
    //    set as a literal, so the unused half of the notation becomes countable, and *gateways
    //    are not drawn here* stops being the same sentence as *gateways were forgotten*.
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

    // ⛔ AND THE REVERSE, WHICH IS §2's `composition_citation` DEFECT AS A LAW. That row declared a
    //   mapping, emitted nothing, and was invisible to every cardinality law because element kinds
    //   are not one to one. A roster row claiming to be spent must be findable in the artifact.
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

    // ⛔ THE `<>` IDIOM, IN A ROSTER. Exactly one of the two columns, never a blank and never both,
    //   so a glyph nobody classified cannot sit here looking classified.
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

    // ⭐⭐⭐ AND THIS IS THE LAW THAT MAKES THE SUPERSET CLAIM FALSIFIABLE. Every axis of the
    //    notation is withheld whole except one, and on `composition` this model claims to cover
    //    BPMN completely. So a compositional glyph appearing in the withheld column is not a
    //    scoping decision, it is a GAP in the only axis where both notations speak.
    // ⛔⛔⛔ AND THE LAW ABOVE HAD TO BE CORRECTED THE FIRST TIME THE MAPPING IMPROVED, WHICH IS
    //    THE MOST USEFUL THING IT HAS DONE. Written as *every compositional element is spent*, it
    //    could not tell a withholding with nothing behind it from a withholding because a BETTER
    //    element covers the fact. Withdrawing `subProcess` in favour of `childLaneSet` made the
    //    mapping strictly better and the law called it a gap. ⭐ The claim was never about
    //    ELEMENTS: it is that every compositional FACT is covered. So a withheld one is admitted
    //    only when `diagrams/admitted.sqlc` names its replacement in `superseded_by`, and the
    //    replacement must itself be spent, or the relation would launder a gap into a citation.
    let admitted = ordered(sqlx::query_file!("assets/sql/diagrams/admitted.sql").fetch_all(&pool).await?);
    let spent: std::collections::BTreeSet<&str> = notation
        .iter()
        .filter(|n| n.emitted == Some(true))
        .filter_map(|n| n.element.as_deref())
        .collect();
    // ⛔ THE `<>` IDIOM AGAIN: a ground or the other, never both and never neither. A row with
    //   both would say the fact is carried AND does not exist.
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
            // ⭐⭐⭐ NOT AN EXCUSE. This is the boundary claim shrinking and reporting that it
            //    shrank: BPMN offers a compositional element this model has no fact for, so at
            //    that point BPMN is the wider of the two and *this model is the finer* is true
            //    everywhere else and not here.
            _ => println!("   {was} ⛔ no such fact in this model, so BPMN is wider here"),
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
        "a COMPOSITIONAL element of BPMN is withheld and nothing on diagrams/admitted.sqlc \
         covers what it carried, which is a gap in the one axis this model claims to cover whole \
         rather than a boundary it drew: {ceded:?}"
    );

    // ------------------------------------------------------------------
    // ⛔⛔⛔ THE FLATTENING MUST NOT INVENT A CYCLE, AND THIS IS THE ONLY LAW HERE THAT CATCHES
    //    THE ARTIFACT SAYING SOMETHING THE MODEL DOES NOT. Every other law asks whether the
    //    emission LOST something. `calledElement` is a QName of a PROCESS and lanes are not
    //    callable, so `F`'s layer-to-layer edges collapse to filing-to-filing ones, and merging
    //    nodes IDENTIFIES them: two layers of one filing become one node, and two edges that ran
    //    between different layers become a round trip between two documents.
    //
    // ⭐⭐⭐ SO A COMPLETELY CORRECT FILING CAN RENDER AS A CYCLIC BPMN DOCUMENT. Probed: add one
    //    legitimate part running back from a called document into a DIFFERENT layer of its caller.
    //    `F` stays acyclic, dim 0, with no jagged partition and no co-movement. The emitted call
    //    graph goes to dim 1, and a reader sees two documents calling each other. The model does
    //    not say that. Nothing else here can see it: `|callActivity| = |part|` still holds exactly,
    //    so every cardinality law passes, which is the blind spot in its third and worst form.
    //
    // ⛔ AND THE INEQUALITY ONLY RUNS ONE WAY. Contraction cannot destroy a cycle that was there,
    //   so the emitted dimension is never BELOW `F`'s; the whole risk is above it.
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

    println!("\nTHE FLATTENING, AND WHETHER IT INVENTED A RECURSION");
    println!("   F, layer grain        dim {f_dim}");
    println!("   emitted, filing grain dim {emitted_dim}   over {} nodes, {} edges, {comps} components",
             cnodes.len(), call_edges.len());
    assert!(
        !cnodes.is_empty(),
        "no calledElement was emitted at all, so this law examined nothing"
    );
    assert_eq!(
        emitted_dim, f_dim,
        "the emitted call graph carries {emitted_dim} independent cycles and F carries {f_dim}: \
         collapsing layer to filing has put a recursion in the diagram that the model does not \
         state, and an analyst reading it would be right to believe the documents call each other"
    );
    println!("   ⭐ Equal, so no reader can see a recursion the model does not state. This is the");
    println!("      one law here about what the artifact ADDS rather than what it lost.");

    let mut by_axis: BTreeMap<&str, (usize, usize)> = BTreeMap::new();
    for n in &notation {
        let a = by_axis.entry(n.axis.as_deref().unwrap_or("?")).or_default();
        if n.emitted == Some(true) { a.0 += 1 } else { a.1 += 1 }
    }
    let spent: usize = by_axis.values().map(|a| a.0).sum();
    println!("\nTHE NOTATION, SPENT AND WITHHELD, against assets/sqlc/diagrams/notation.sqlc");
    for (axis, (s, w)) in &by_axis {
        println!("   {:<15} {s:>2} spent {w:>3} withheld{}", axis,
                 if *w == 0 { "   ⭐ the whole axis" } else { "" });
    }
    // ⛔⛔⛔ THE SUMMARY IS COMPUTED, BECAUSE THE HARDCODED ONE ROTTED EXACTLY LIKE A NUMBER.
    //    A hardcoded *BPMN is withheld whole on every axis but one* is true of a roster with
    //    one mixed axis and false of a roster with four, and no rule notices, because a
    //    SENTENCE is not a count. `a number in prose rots` is not about numbers: it is about any
    //    claim a program could print and does not.
    let whole: Vec<&str> = by_axis.iter().filter(|(_, a)| a.0 == 0).map(|(k, _)| *k).collect();
    let mixed: Vec<&str> =
        by_axis.iter().filter(|(_, a)| a.0 > 0 && a.1 > 0).map(|(k, _)| *k).collect();
    println!("   {spent} of {} elements spent. NOT a superset: {} {} ceded WHOLE ({}), and {} {} \
              partly spent ({}).",
             notation.len(),
             whole.len(), if whole.len() == 1 { "axis is" } else { "axes are" }, whole.join(", "),
             mixed.len(), if mixed.len() == 1 { "axis is" } else { "axes are" }, mixed.join(", "));
    println!("   On `composition`, the one axis both notations speak, this model is the finer at \
              every point but {wider}.");

    // ------------------------------------------------------------------
    // The laws. The expected side is computed by relations this program did not write.
    // ------------------------------------------------------------------
    println!("\nTHE LAWS, counted on disk, against assets/sqlc/diagrams/expected.sqlc");
    let mut broken = Vec::new();
    for e in &expected {
        let want = e.expected.unwrap_or(-1);
        let got = emitted.get(e.slug.as_deref().unwrap_or("")).copied().unwrap_or(-1);
        let ok = want == got;
        println!("   {} {:<9} model {want:>4}   emitted {got:>4}",
                 if ok { "  " } else { "⛔" }, e.slug.as_deref().unwrap_or("?"));
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
    // ⛔⛔⛔ THE SCOPE EACH DOCUMENT STATES, AGAINST THE SCOPE ITS FILING CLAIMS. THE COUNT ABOVE
    //    CANNOT DO THIS AND NEITHER CAN ANY OTHER LAW IN THIS FILE. An emitter writing *a
    //    partition of layers claimed exhaustive* into all 15 documents from a string literal
    //    says it of 14 that decline to, because the corpus holds 1 `complete`, 9 `scoped` and 5
    //    `unbounded`. Fifteen scope sentences reach fifteen documents either way, so
    //    `|scopes| = |filing|` is 15 = 15 and true
    //    throughout.
    //
    // ⭐⭐ THE THIRD TIME ATTRIBUTION HAS BEEN THE REPAIR AND A BIGGER COUNT HAS NOT.
    //    `diagrams/ungoverned.sqlc` for a table declared and never rendered, the per-kind law in
    //    `examples/rendering/main.rs` for 65 identical rectangles, and this. ⭐ A defect that puts the
    //    RIGHT NUMBER of the WRONG THING on the page is invisible to cardinality by construction,
    //    and a hardcoded sentence about a filing is exactly that defect in prose.
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
    // ⛔⛔ AND THE SWEEP THAT REACHES TWO MORE OF THE SAME SHAPE. *A claim in prose is
    //   unreachable by every law here* generalises past scope: which OTHER model value does a
    //   document state that only a count checks? The coupling SEARCH answer, and the two lanes
    //   an association joins. Each can be wrong in every document with its count still exact.
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

        // ⛔⛔⛔ THE ENDPOINTS, WHICH ARE THE WHOLE CLAIM. `|association| = |coupling|` is exact
        //   whichever two lanes each one joins, so a dependence drawn between the wrong pair is a
        //   statement that the wrong layers move together, passing every count.
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

    println!("\nTHE FACTS EACH DOCUMENT STATES, AGAINST WHAT ITS FILING CLAIMS");
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
    println!("   ⭐ {checked} documents. Three facts checked per document and not counted: the");
    println!("      SCOPE, the coupling SEARCH answer, and the two lanes each association joins.");
    println!("      Every one of them is a model value written into prose or into a reference,");
    println!("      and every one has a cardinality law beside it that stays true when it is wrong.");

    // ------------------------------------------------------------------
    // ⭐⭐⭐ EVERY DECLARED MAPPING IS GOVERNED, OR SAYS WHY NOT. The laws above count element
    //    KINDS, and two tables can name one kind: `draw` and `induction` both say `laneSet`, so
    //    the law counting lane sets passed while reading neither. Counting kinds cannot verify
    //    attribution, and this is the check that does.
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
    println!("\nGOVERNANCE OF THE MAPPING, which counting element kinds cannot give you");
    println!("   {} declared mappings, {} governed by a named law, {} declared and NOT rendered",
             governance.len(), governance.len() - ungoverned, ungoverned);
    for g in governance.iter().filter(|g| g.governed_by.is_none()) {
        println!("      {:<22} {}", g.object.as_deref().unwrap_or("?"),
                 g.loses.as_deref().unwrap_or(""));
    }
    assert!(dangling.is_empty(), "a mapping names a law that is not on the roster: {dangling:?}");
    assert!(
        silent.is_empty(),
        "a mapping names no law and does not say what it loses, so an element could be declared, \
         never rendered, and no cardinality law would ever see it: {silent:?}"
    );

    // ------------------------------------------------------------------
    // ⭐⭐⭐ `F` READ BACK OUT OF THE ARTIFACT, AS A SET OF LAYER-TO-LAYER EDGES, AND COMPARED TO
    //    `F` ITSELF. This is the strongest law in this file and it is the only one that is an
    //    ISOMORPHISM rather than a count or a dimension. The cycle-space law above compares the
    //    CONTRACTED call graph's dimension to F's, which is a shadow of a shadow: equal
    //    dimensions do not mean equal graphs, and the contraction is where the defect hides.
    //
    // ⛔⛔ 17 RELATIONSHIPS JOINING THE WRONG 17 PAIRS PASSES `|relationship| = |part|` EXACTLY,
    //    which is the same blind spot that let a reversed coupling through. The endpoints are the
    //    claim, so the endpoints are what gets checked.
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
        // ⛔ FILTERED BY TYPE, WHICH IS THE POINT OF HAVING CHOSEN THIS ELEMENT. Two relations
        //   share `relationship` now, and reading them together would compare F against F plus
        //   the eliminations and fail on a correct document. An `association` could not have been
        //   filtered at all, which is why it was refused.
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
    // ⛔ The layer names were sanitised into NCNames on the way out, so the model side is
    //   sanitised the same way on the way back rather than the artifact being un-sanitised. A
    //   round trip through a lossy encoding is compared IN the encoding.
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
    println!("\n`F` READ BACK OUT OF THE ARTIFACT, AT LAYER GRAIN");
    println!("   {} relationship edges recovered, {} foreign part edges in F",
             read_back.len(), owed_f.len());
    assert!(!read_back.is_empty(), "no relationship was emitted, so the isomorphism law examined nothing");
    assert_eq!(
        read_back, owed_f,
        "the layer-grain graph in the artifact is not F: a tool reading these documents would \
         reconstruct a different composition than the model states"
    );
    println!("   ⭐ Isomorphic, edge for edge. `calledElement` names a PROCESS and collapses 17");
    println!("      edges onto 5 document pairs; this is the same fact at the grain F has, so the");
    println!("      widest `demoted` in the mapping is a reference again and not a name.");

    // ⭐⭐⭐ AND THE SECOND TYPE, READ BACK THE SAME WAY. The endpoints are the claim here too: 8
    //    relationships joining the wrong 8 pairs passes `|relationship| = |between|` exactly, and
    //    a `between` pointing at the wrong layer says the composer removed a number on account of
    //    a double count that is not there. ⛔ Filtered by `@type`, which is the whole reason this
    //    element was chosen over `association`: two relations, one element, and the laws can
    //    still tell them apart.
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
    println!("   ⭐ Also isomorphic. Two relations on ONE element, told apart by `@type`, which is");
    println!("      exactly what `association` could not have done and why it was refused for F.");

    // ------------------------------------------------------------------
    // ⭐⭐⭐ `demoted` IS A CLAIM ABOUT THE ARTIFACT AND THEREFORE CHECKABLE, WHICH IS THE WHOLE
    //    REASON `loses` WAS SPLIT. Saying a fact survives as TEXT is worth nothing if nobody
    //    looks for the text. The biggest case is `F`: `calledElement` is a QName of a PROCESS, so
    //    the target LAYER is not a reference anywhere in the document, and it is right there in
    //    `callActivity/@name` as `labour <- merge-us-member/labour`.
    //
    // ⭐⭐ SO THE BOUNDARY CLAIM CHANGES SHAPE. Almost everything this mapping loses is DEMOTED
    //    rather than ABSENT: a person can reconstruct it and a tool cannot. For a notation whose
    //    declared reader is a brilliant human analyst that is the right failure to have, and it
    //    only became sayable once the two were counted apart.
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
    // ⛔⛔ READ THE `name`, NOT THE DOCUMENT. Written as `doc.contains(part_layer)` this law was
    //   weaker than the claim it was checking: `id("call", ...)` already embeds the layer, so
    //   deleting it from the NAME left it in the id and the search still found it. An id is a
    //   mangled NCName that nobody reads, and `demoted` claims a READER can recover the fact. ⭐
    //   Probed by dropping the layer from the name, which this fires on and a search does not.
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
            vanished.push(format!("{}: no callActivity NAMES the part layer `{}`",
                                  p.composition, p.part_layer));
        }
    }
    let (dem, abs_) = (
        objects.iter().filter(|o| o.loses_kind.as_deref() == Some("demoted")).count(),
        objects.iter().filter(|o| o.loses_kind.as_deref() == Some("absent")).count(),
    );
    println!("\nWHAT IS LOST, AND THE TWO KINDS ARE NOT ONE KIND");
    println!("   demoted {dem:>2}   the fact is in the artifact as TEXT: readable, unresolvable");
    println!("   absent  {abs_:>2}   the fact is not in the artifact in any form");
    assert!(demoted_checked > 0, "no foreign part, so the demotion law examined nothing");
    assert!(
        vanished.is_empty(),
        "a mapping is filed as `demoted`, which claims the fact survives as text, and the text \
         is not in the document: {vanished:?}"
    );
    println!("   ⭐ {demoted_checked} foreign parts, and every target LAYER is in its document as a");
    println!("      NAME as well as in a relationship. Two readers, two paths: a person reads the");
    println!("      callActivity label, a tool resolves the QName, and each has its own law.");

    // ⛔⛔⛔ AND THE THIRD `pm:ForeignId` OWES THE SAME LAW, WHICH NO COUNT COULD EVER STAND IN
    //   FOR. The `documentation` count reads diagrams/annotated.sqlc and stays exact with every
    //   sentence hung on the WRONG task, and for a REFERENCE that is the entire fact: an id
    //   against the wrong node is a crossing that points somewhere real and wrong, which is the
    //   reversed-dependence defect at the one place a reader would act on it.
    // ⚠️ READ THE TASK, NOT THE DOCUMENT. `doc.contains(node)` passes on a sentence attached to
    //   any task in the file, which is the same weaker-than-its-claim shape the callActivity law
    //   above has to avoid. Probed by moving one sentence to the other task and by changing one
    //   character of the id: both fire, and the documentation count stays exact.
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
            // ⛔ A self-closing task has no `</task>`, so a body taken to the next one would run
            //   through every task between here and it, and the law would read a sentence that
            //   belongs to somebody else. Stop at whichever boundary comes first.
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
    println!("   ⭐ {crossings_checked} operations file a notation position, and each one is on its");
    println!("      OWN task. That id is the whole BPMN interface: nothing is added to the filer's");
    println!("      diagram, so the crossing costs that document nothing and survives wherever it goes.");

    // ------------------------------------------------------------------
    // ⛔ What could NOT be drawn, enumerated. A blank diagram and a diagram of nothing are
    //    indistinguishable from outside, so the absence is filed rather than left to inference.
    // ------------------------------------------------------------------
    println!("\nWHAT BPMN HAS NO HOME FOR, and the three reasons are three different facts");
    for reason in ["misreads", "notApplicable", "none"] {
        let rows: Vec<_> = objects.iter().filter(|o| o.absent.as_deref() == Some(reason)).collect();
        println!("   {reason}  ({})", rows.len());
        for o in rows {
            println!("      {:<20} {}", o.object.as_deref().unwrap_or("?"), o.why.as_deref().unwrap_or(""));
        }
    }
    println!("\nTHE THREE ELIMINATIONS, and every overlap is DERIVED rather than filed");
    for e in &elims {
        println!("   {:<13} {:<32} over {}",
                 e.elimination.as_deref().unwrap_or("?"),
                 e.the_sum.as_deref().unwrap_or(""),
                 e.the_overlap.as_deref().unwrap_or(""));
        println!("   {:<13} named by {}", "", e.named_by.as_deref().unwrap_or(""));
    }
    println!("   ⭐ x = Σ parts - e, with e derivable because the overlap is itself a named");
    println!("      relation. That is the same pivot eliminations/derived.sqlc turns on.");

    println!("\n   ⛔ AND ONE THING IS LOST THAT NO TABLE NAMES. `induction` maps to a laneSet and is");
    println!("      not emitted, because a SECOND lane set gives every layer two lane elements with");
    println!("      nothing but a matching name to say they are one layer. The conformed key");
    println!("      (filing, layer) does not survive the rendering, so the emitter files the DRAW,");
    println!("      which is what a modeller files, and the induction falls off carrying `decider`.");
    println!("      Measured in this corpus: {draw_count} draws, {induction_count} inductions.");

    println!("\nTHE LEVELS THIS CORPUS HOLDS, and only the first is emitted");
    for l in &levels {
        println!("   L{}  {:<9} {}", l.level.unwrap_or(-1),
                 l.process.as_deref().unwrap_or("?"),
                 if l.emitted == Some(true) { "EMITTED" } else { "not emitted" });
        println!("       actor    {}", l.actor.as_deref().unwrap_or(""));
        println!("       subject  {}", l.subject.as_deref().unwrap_or(""));
        println!("       outcome  {}", l.outcome.as_deref().unwrap_or(""));
    }
    println!("   ⭐ Each level's OUTCOME is the next level's SUBJECT, and the last one is required");
    println!("      to be empty. That is why the recursion stops rather than being stopped.");
    assert_eq!(
        levels.iter().filter(|l| l.emitted == Some(true)).count(), 1,
        "exactly one level is rendered here; a second would need its own laws and its own \
         collaboration, and claiming to draw it without them is the failure this file exists for"
    );

    println!("\nAll checks passed.");
    Ok(())
}
