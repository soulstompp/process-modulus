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

use quick_xml::events::Event;
use quick_xml::Reader;
use std::collections::BTreeMap;
use std::fmt::Write as _;
use std::fs;

const DIR: &str = "assets/bpmn";

/// ⭐⭐⭐ THE SVG IS ITS OWN ARTIFACT, IN ITS OWN TREE, FOR THE REASON `assets/sql/` AND `.sqlx/`
/// ARE TWO TREES. It sat beside each `.bpmn` and that made it look like a companion file of the
/// document, which is exactly the reading this pipeline had to give up: the SVG is not a second
/// half of the BPMN, it is a PROOF whose witness happens to be a picture.
///
/// ⭐⭐ AND SEPARATING THEM REPAIRS THE ORDER DEPENDENCE PROPERLY. The emitters wipe the
/// directories they own, so while the drawings lived inside `assets/bpmn/` a re-run of an emitter
/// DELETED them and the pipeline check could only see them go missing. Out here they survive, and
/// a drawing that is older than its document is caught by AGE, which is how a stale `.sqlx` is
/// caught too.
const SVG: &str = "assets/svg";
/// ⭐⭐⭐ *PROPERLY LAYERED* HAS TO SURVIVE INTO A DRAWING TOOL OR IT IS A CLAIM ABOUT NOTHING,
/// AND IT HAS TO DO SO IN STANDARD SVG. Every group here was anonymous: no `id`, no name, so an
/// editor listed untitled groups and a reader could not tell one from another.
///
/// ⛔⛔ AND THE FIX IS NOT `inkscape:groupmode`. SVG HAS NO LAYERS; a layer IS a group, and the
/// layer flag is one vendor's extension. Taking it would put this drawing inside that editor the
/// way `extensionElements` would put the model inside a BPMN document, which this repository
/// refuses by name. What SVG does define is `id` and a `<title>` child, which is the element's
/// accessible NAME: every editor, every browser and every screen reader reads it.
///
/// ⭐⭐ AND THE LAYERING IS THE MODEL'S OWN SHAPE. The containment is a TREE, so lanes are
/// nested groups; the cover, the dependences and the legend CROSS the containment, so each is a
/// group of its own on top. Hiding them one at a time is how a reader checks an overlay is one.
/// The emitter's own id rule, repeated here so a link resolves to the element it names. ⛔ Two
/// programs agreeing on an identifier by writing the same function twice is a place they can
/// drift; the law below is what catches it, by resolving every link against what is on disk.
fn id_of(prefix: &str, parts: &[&str]) -> String {
    let mut o = String::from(prefix);
    for p in parts {
        o.push('_');
        for c in p.chars() {
            o.push(if c.is_ascii_alphanumeric() || c == '-' || c == '.' { c } else { '_' });
        }
    }
    o
}

/// How many lanes will link into the layer graph, counted from the documents rather than from a
/// number written down beside them.
fn lane_links_expected(files: &[std::path::PathBuf],
                       in_graph: &std::collections::BTreeSet<String>) -> usize {
    files
        .iter()
        .filter(|p| !p.to_string_lossy().contains("/graphs/"))
        .filter_map(|p| fs::read_to_string(p).ok())
        .map(|d| {
            d.match_indices("<lane id=\"")
                .filter(|(i, _)| d[i + 10..].split_once('"').is_some_and(|(v, _)| in_graph.contains(v)))
                .count()
        })
        .sum()
}

fn sanitise(s: &str) -> String {
    s.chars().map(|c| if c.is_ascii_alphanumeric() || c == '-' { c } else { '_' }).collect()
}

/// Where a document's drawing lives: the same relative path, under the other tree.
fn drawing_of(bpmn: &std::path::Path) -> std::path::PathBuf {
    let rel = bpmn.strip_prefix(DIR).unwrap_or(bpmn);
    std::path::Path::new(SVG).join(rel).with_extension("svg")
}

/// ⛔⛔⛔ THE EMITTERS THIS STAGE CONSUMES, DECLARED, BECAUSE READING THE DIRECTORY CANNOT REPORT
/// ONE THAT DID NOT RUN. A missing emitter leaves no file to notice, so its absence is
/// unreachable from the artifact exactly as an unused glyph is, and the answer is the same one
/// `diagrams/notation.sqlc` and `scope/documents_on_disk.sqlc` reach for: declare the outside set.
///
/// ⭐⭐ AND THE LAW IS TWO-WAY. A declared emitter that produced nothing is one that did not run,
/// and an undeclared subdirectory is a THIRD emitter nobody told this stage about. Before the
/// split there was one shared directory, `diagramming` wiped it, and `graphs` survived only when
/// it ran second: **both orders rendered cleanly, one over 18 documents and one over 15.**
const EMITTERS: &[(&str, &str)] = &[
    ("filings", "examples/diagramming/main.rs, one document per FILING at layer grain"),
    ("graphs", "examples/graphs/main.rs, one document per GRAPH FILLING, corpus-wide"),
];
const LANE_H: usize = 34;
const NODE_H: usize = 22;
const WIDTH: usize = 760;

fn esc(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}

/// One lane as the BPMN filed it: its name, its rank, and the ids it says belong to it.
///
/// ⭐ The rank is READ, never computed. It is not derivable from this artifact: `calledElement`
/// names a PROCESS, so the emitted call graph links filing to filing while `F` links layer to
/// layer, ten pairs against twenty-seven. `examples/diagramming/main.rs` writes it into the lane's
/// `documentation`, which is untyped text carrying the words and not the claim.
struct Lane {
    name: String,
    /// ⛔⛔ `Option`, AND NEVER AN `i64` WITH A SENTINEL. A lane whose document files no rank is
    /// not a lane at rank minus one: rank is `max(depth)` over `F`, a relation on LAYERS, and
    /// `rank/evaluation_order.sqlc` is `coalesce(max(depth), 0)`, so any negative value is one
    /// the model cannot produce. ⛔ A sentinel here reaches the page: the graph documents' lanes
    /// include units, which have no position in that order at all.
    /// ⭐ The typed absence belongs here for the same reason it belongs in the schema: *nobody
    /// wrote one* and *the question does not arise* are different, and a number is neither.
    rank: Option<i64>,
    /// ⭐⭐⭐ HOW MUCH OF THE CHECKER CAN SPEAK ABOUT THIS LAYER, and how much of it says no.
    /// A drawing carrying only what was filed is a drawing a reader BELIEVES; this is the half
    /// that lets them argue with it. ⛔ `None` is not zero: no rule declares a unit as its
    /// subject, so a unit is outside the checker's dimension rather than thinly checked.
    examined: Option<i64>,
    violated: Option<i64>,
    nodes: Vec<String>,
    /// ⭐⭐⭐ THE PARTITION RECURSES, SO THE CACHE MUST TOO. The BPMN nests a local fusion's parts
    ///    in the parent lane's `childLaneSet`, and a flat read of `<lane>` throws that away in the
    ///    ONE format where nesting is native. `<g>` contains `<g>` for free.
    kids: Vec<usize>,
    parent: Option<usize>,
    /// ⭐ THE BPMN `id`, WHICH ONLY A CROSS-LANE EDGE NEEDS. A law that reaches a lane by NAME
    /// needs no id, because nothing points AT one. An `association` does: its `sourceRef` is a
    /// QName whose local part is this id, and a name cannot stand in for it.
    id: String,
}

/// A lane is as tall as what it holds: its own flow nodes, or its children and their children.
fn lane_height(lanes: &[Lane], i: usize) -> usize {
    let l = &lanes[i];
    if l.kids.is_empty() {
        LANE_H.max(NODE_H * l.nodes.len() + 12)
    } else {
        22 + l.kids.iter().map(|k| lane_height(lanes, *k) + 4).sum::<usize>() + 6
    }
}

/// ⭐ ONE LANE AND EVERYTHING INSIDE IT. The recursion is the partition's, not the drawing's: a
/// fusion's parts partition the composed layer, BPMN says that with `childLaneSet`, and `<g>`
/// inside `<g>` is the SVG for it. A flat emission is the containment thrown away in the one
/// format that gets nesting for nothing.
#[allow(clippy::too_many_arguments)]
fn emit_lane(
    body: &mut String,
    lanes: &[Lane],
    names: &std::collections::BTreeMap<String, (String, String)>,
    i: usize,
    bounds: &std::collections::BTreeMap<String, (usize, usize, usize, usize)>,
    from_graphs: bool,
    in_layer_graph: &std::collections::BTreeSet<String>,
    unlinked: &mut Vec<String>,
    svg_lanes: &mut usize,
    svg_nodes: &mut usize,
    boxes: &mut std::collections::BTreeMap<String, (usize, usize, usize, usize)>,
    lane_boxes: &mut std::collections::BTreeMap<String, (usize, usize, usize, usize)>,
) -> std::fmt::Result {
    let l = &lanes[i];
    // ⛔ READ, NEVER COMPUTED. If the document declares no box for a lane the run fails rather
    //   than inventing one, because inventing one is what this stage did before.
    let &(x, y, w, h) = bounds
        .get(&l.id)
        .unwrap_or_else(|| panic!("the document declares no bpmndi:BPMNShape for lane {}", l.id));
    lane_boxes.insert(l.id.clone(), (x, y, w, h));
    // ⛔ NO ATTRIBUTE RATHER THAN AN EMPTY ONE. `data-rank=""` is a stylesheet's problem and a
    //   reader's puzzle; an absent attribute is what a selector already knows how to miss.
    let rank_attr = match l.rank {
        Some(r) => format!(r#" data-rank="{r}""#),
        None => String::new(),
    };
    let cover_attr = match (l.examined, l.violated) {
        (Some(e), Some(v)) => format!(r#" data-examined="{e}" data-violated="{v}""#),
        _ => String::new(),
    };
    writeln!(body, r#"  <g class="lane" data-layer="{}"{}{} id="{}"><title>lane: {}</title>"#,
             esc(&l.name), rank_attr, cover_attr, esc(&l.id), esc(&l.name))?;
    // ⚠️ THE NAME IS HORIZONTAL AND NOT IN A ROTATED BAND, WHICH WAS TRIED AND MEASURED OUT.
    //   A pool's name rotates because a pool is tall; a lane here is 34px at the median and the
    //   longest layer name needs about 290px of height, so 98 of 98 lanes were too short for it.
    // ⛔ EVERY LEAF CARRIES AN ID TOO, NOT ONLY THE GROUP. A tool that finds no `id` invents one,
    //   so a reader opening the drawing saw `text20` and `text22` where the box, the name and the
    //   rank should have been. An invented id is stable for nobody: it renumbers when the file is
    //   re-emitted, so an annotation or a stylesheet written against it silently moves.
    // ⛔⛔ THE MARK IS ON `violated` AND NEVER ON A BAND OF `examined`. A threshold would be
    //   this stage inventing the number `rank/layer_cover.sqlc` explicitly refuses to state:
    //   a layer under few rules is not a defect, it is a layer few questions reach. A rule
    //   SAYING NO is a fact, so it is the only thing that gets ink.
    let box_class = if l.violated.unwrap_or(0) > 0 { "laneBox refuted" } else { "laneBox" };
    writeln!(body, r#"    <rect id="{}-box" x="{x}" y="{y}" width="{w}" height="{h}" class="{box_class}"/>"#, esc(&l.id))?;
    // ⭐⭐⭐ THE SAME LAYER IN TWO DRAWINGS CARRIES THE SAME `id`, SO IT CAN BE LINKED. A filing's
    //    lane and its row in the layer graph are one layer under one key, `(filing, layer)`, and
    //    the drawing says so with an `<a>` rather than by looking alike. ⛔ Following the links is
    //    a TRAVERSAL: a reader who can walk from a lane to the graph and back has checked the
    //    conformed key by hand, which no count can do for them.
    // ⛔ ONLY THE LAYER GRAPH LINKS BOTH WAYS. The unit graph's lanes are UNITS, which have no
    //   filing, so a back link from one would name a document that does not exist.
    //
    // ⭐⭐⭐ AND A LANE WITH NO LINK IS SAYING SOMETHING, WHICH IS WHY THE ABSENCE IS NOT PATCHED.
    //   The layer graph is `F`, so it is the COMPOSITION. A layer that is in no part, in either
    //   direction, is in no composition: it is correctly not a node there, and a reader who
    //   clicks its name and finds nothing has learned that. Measured: 37 of the 51 filed layers
    //   are in the composition and 14 are not, and 37 + 14 is every one of them.
    //   ⚠️ Making every lane link would draw a graph that is not `F` and would say that every
    //   layer takes part in a composition, which is the drawing asserting what the model denies.
    let linked = if from_graphs {
        None
    } else if in_layer_graph.contains(&l.id) {
        Some(format!("../graphs/model-layers.svg#{}", esc(&l.id)))
    } else {
        unlinked.push(l.id.clone());
        None
    };
    match &linked {
        Some(href) => writeln!(body, r#"    <a href="{href}"><text id="{}-name" x="{}" y="{}" class="laneName">{}</text></a>"#,
                               esc(&l.id), x + 8, y + 16, esc(&l.name))?,
        None => writeln!(body, r#"    <text id="{}-name" x="{}" y="{}" class="laneName">{}</text>"#,
                         esc(&l.id), x + 8, y + 16, esc(&l.name))?,
    }
    if let Some(r) = l.rank {
        writeln!(body, r#"    <text id="{}-rank" x="{}" y="{}" class="rankName" text-anchor="end">rank {}</text>"#,
                 esc(&l.id), x + w - 8, y + 16, r)?;
    }
    // ⭐ THE COUNT AS A NUMBER AND NOT AS A SHADE. `rank/layer_cover.sqlc` states outright that
    //   there is no threshold at which a layer is under-checked, so a band would be ink asserting
    //   what the relation declines to say. A reader comparing 6 against 19 across the page is
    //   doing the comparison the number supports.
    if let Some(e) = l.examined {
        let says_no = l.violated.unwrap_or(0);
        writeln!(body, r#"    <text id="{}-cover" x="{}" y="{}" class="coverName" text-anchor="end">refutable by {}{}</text>"#,
                 esc(&l.id), x + w - 8, y + 28, e,
                 if says_no > 0 { format!(", {says_no} say no") } else { String::new() })?;
        let _ = says_no;
    }
    *svg_lanes += 1;
    if l.kids.is_empty() {
        // ⭐⭐⭐ THE GLYPH IS THE DISCRIMINATOR, NOT A DECORATION. BPMN says which KIND an activity
        //    is with its border: a task is thin and a `callActivity` is THICK, and the thick one
        //    is the notation for *this one substitutes*. Drawing them alike discards the single
        //    distinction the pipeline rests on while leaving the file perfectly well formed.
        for id in &l.nodes {
            let (kind, label) = names
                .get(id)
                .cloned()
                .unwrap_or_else(|| ("task".to_string(), id.clone()));
            let &(nx, ny2, nw, nh) = bounds
                .get(id)
                .unwrap_or_else(|| panic!("the document declares no bpmndi:BPMNShape for node {id}"));
            let ny = ny2;
            boxes.insert(id.clone(), (nx, ny, nw, nh));
            writeln!(body, r#"    <g class="node" data-id="{}" data-kind="{}" id="{}"><title>{} {}</title>"#,
                     esc(id), esc(&kind), esc(id), esc(&kind), esc(&label))?;
            writeln!(body, r#"      <rect id="{}-box" x="{nx}" y="{ny}" width="{nw}" height="{nh}" rx="4" class="activity {kind}"/>"#, esc(id))?;
            // ⭐⭐ A CALL LINKS TO THE LAYER IT CALLS, IN THE OTHER DOCUMENT. `calledElement`
            //   names a PROCESS and the label carries `composed <- filing/layer`, so the drawing
            //   can reach what the BPMN attribute cannot: the target LANE.
            let target = label.split_once(" <- ").and_then(|(_, r)| r.split_once('/'))
                .map(|(f, ly)| (f.to_string(), ly.to_string()));
            match (&kind[..], &target) {
                ("callActivity", Some((f, ly))) => {
                    let lane_id = id_of("lane", &[f, ly]);
                    writeln!(body, r#"      <a href="../filings/{f}.svg#{lane_id}"><text id="{}-name" x="{}" y="{}" class="nodeName">{}</text></a>"#,
                             esc(id), nx + 6, ny + 13, esc(&label))?;
                }
                _ => writeln!(body, r#"      <text id="{}-name" x="{}" y="{}" class="nodeName">{}</text>"#,
                              esc(id), nx + 6, ny + 13, esc(&label))?,
            }
            writeln!(body, "    </g>")?;
            *svg_nodes += 1;
        }
    } else {
        for k in &l.kids {
            emit_lane(body, lanes, names, *k, bounds, from_graphs, in_layer_graph, unlinked,
                      svg_lanes, svg_nodes, boxes, lane_boxes)?;
        }
    }
    writeln!(body, "  </g>")
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // ⛔ WIPED, like every generated tree here. A drawing of a document that no longer exists is
    //   a claim about a model that has moved.
    if std::path::Path::new(SVG).exists() {
        fs::remove_dir_all(SVG)?;
    }
    fs::create_dir_all(SVG)?;

    // ⭐ THE LAYER GRAPH'S NODES, READ BEFORE ANYTHING IS DRAWN, so a link is only written where
    //   it resolves. Read from the BPMN rather than the SVG, because the drawing may not exist yet.
    let in_layer_graph: std::collections::BTreeSet<String> =
        fs::read_to_string(format!("{DIR}/graphs/model-layers.bpmn"))
            .unwrap_or_default()
            .match_indices("<lane id=\"")
            .filter_map(|(i, _)| {
                let r = &fs::read_to_string(format!("{DIR}/graphs/model-layers.bpmn")).ok()?[i + 10..];
                r.split_once('"').map(|(v, _)| v.to_string())
            })
            .collect();
    let mut unlinked: Vec<String> = Vec::new();

    let mut files: Vec<_> = Vec::new();
    let mut from: std::collections::BTreeMap<&str, usize> = Default::default();
    for (dir, _) in EMITTERS {
        let n = files.len();
        for e in fs::read_dir(format!("{DIR}/{dir}"))
            .map_err(|_| format!("{DIR}/{dir} is not there, so its emitter has not run"))?
            .flatten()
        {
            let p = e.path();
            if p.extension().is_some_and(|x| x == "bpmn") { files.push(p); }
        }
        from.insert(dir, files.len() - n);
    }
    files.sort();
    let stray: Vec<String> = fs::read_dir(DIR)?
        .flatten()
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .filter(|n| !EMITTERS.iter().any(|(d, _)| d == n))
        .collect();
    assert!(
        stray.is_empty(),
        "an emitter is writing into {DIR} and this stage has never been told about it, so its \
         documents are rendered under laws written for somebody else's: {stray:?}"
    );
    let idle: Vec<&str> = EMITTERS
        .iter()
        .map(|(d, _)| *d)
        .filter(|d| from.get(d).copied().unwrap_or(0) == 0)
        .collect();
    assert!(
        idle.is_empty(),
        "a declared emitter produced no document, so this stage is about to render a partial \
         pipeline and pass: {idle:?}"
    );
    println!("READING {} documents from {} emitters", files.len(), EMITTERS.len());
    for (d, why) in EMITTERS {
        println!("   {:<9} {:>3}   {why}", d, from.get(d).copied().unwrap_or(0));
    }
    assert!(
        !files.is_empty(),
        "no BPMN to render. This stage caches an artifact, so run `cargo run --example \
         diagramming` first; a cache with no artifact is not empty, it is wrong."
    );

    let (mut bpmn_lanes, mut svg_lanes, mut bpmn_refs, mut svg_nodes) = (0, 0, 0, 0);
    // ⭐ THE COVER, COUNTED ACROSS EVERY DOCUMENT. `bpmn_cvrefs` is N's incidence and
    //   `bpmn_groups` is its glyph; the SVG owes one dashed shape per group and must place every
    //   member inside it, which a count of nodes could never see.
    let (mut bpmn_groups, mut bpmn_cvrefs, mut _svg_groups, mut svg_grouped) = (0usize, 0usize, 0usize, 0usize);
    let (mut bpmn_deps, mut svg_deps) = (0usize, 0usize);
    let (mut bpmn_notes, mut svg_notes) = (0usize, 0usize);
    // ⛔⛔⛔ THE PAIRS, NOT THE COUNT. `svg_deps == bpmn_deps` is exact whichever two lanes each
    //   line joins, and a dependence drawn between the wrong pair says the wrong layers move
    //   together. Probed one stage down by reversing every coupling: the cardinality law stayed
    //   green and only the endpoint law spoke. A count is blind to what it is a count OF.
    let mut bpmn_pairs: Vec<(String, String, String)> = Vec::new();
    let mut svg_pairs: Vec<(String, String, String)> = Vec::new();
    // ⛔⛔ A COUNT CANNOT SEE A GLYPH COLLAPSE, WHICH IS WHY THIS IS KEYED BY KIND. 38 tasks, 17
    //   call activities and 10 sub-processes drew 65 identical rectangles and every cardinality
    //   law passed, because 65 = 65. Attribution is a different law from cardinality, and this is
    //   the same repair `diagrams/ungoverned.sqlc` made on the model side.
    let mut bpmn_kinds: std::collections::BTreeMap<String, usize> = std::collections::BTreeMap::new();
    // ⛔ EVERY ELEMENT KIND ANY DOCUMENT CONTAINS, so the fate roster at the end can be closed
    //   against the artifact in both directions rather than against this program's memory of it.
    let mut bpmn_kinds_seen: std::collections::BTreeSet<String> = Default::default();

    for path in &files {
        let doc_name = path.file_stem().unwrap_or_default().to_string_lossy().into_owned();
        let xml = fs::read_to_string(path)?;
        let mut reader = Reader::from_str(&xml);
        let mut buf = Vec::new();
        let dec = reader.decoder();
        // ⛔ THE OPEN STACK IS WHAT MAKES `childLaneSet` LEGIBLE. Without it every lane in the
        //   document reads as a sibling, which is precisely the containment the BPMN just gained.
        let mut open: Vec<usize> = Vec::new();
        let mut pool = String::new();
        let mut lanes: Vec<Lane> = Vec::new();
        let mut in_ref = false;
        let mut in_doc = false;
        // node id -> display name, so a lane's flowNodeRef can be shown as what it IS.
        // ⛔⛔ THE KIND TRAVELS WITH THE NAME. Match it and drop it, and a `callActivity` and a
        //   `task` arrive here indistinguishable and leave as one rectangle.
        let mut names: std::collections::BTreeMap<String, (String, String)> =
            std::collections::BTreeMap::new();
        // ⭐⭐⭐ THE COVER, WHICH THE BPMN CARRIES AND THIS STAGE MUST NOT DROP IN SILENCE. A
        //    `categoryValue` is a label, a `categoryValueRef` on a flow node is a membership, and
        //    a `group` is the glyph. Nothing here is a container: the MEMBER declares the tie, so
        //    an operation may be in several of these and is in exactly one lane.
        let mut cat_label: std::collections::BTreeMap<String, String> = Default::default();
        let mut cat_members: std::collections::BTreeMap<String, Vec<String>> = Default::default();
        let mut groups: Vec<String> = Vec::new();
        // ⭐ THE GROUP'S OWN ID, BECAUSE ITS BOX IS DECLARED AGAINST THAT AND NOT AGAINST THE
        //   CATEGORY IT POINTS AT. Captured in parallel so the hull can be READ instead of
        //   recomputed from the members this stage happens to have parsed.
        let mut group_ids: Vec<String> = Vec::new();
        let mut edge_pts: BTreeMap<String, Vec<(usize, usize)>> = BTreeMap::new();
        let mut note_ids: Vec<String> = Vec::new();
        let mut last_edge = String::new();
        // ⭐⭐⭐ C, THE ONLY EDGE IN THIS NOTATION. `F` is drawn as containment and as nodes, so
        //    a line between two lanes has nothing to be confused with, which is the entire reason
        //    the arrowhead is safe: BPMN glosses it as a direction of flow and a coupling is a
        //    DEPENDENCE. ⚠️ Draw `F` as an edge one day and that argument expires.
        let mut deps: Vec<(String, String)> = Vec::new();
        // ⭐ THE PAIR TO THE ELEMENT'S OWN ID, because the declared route is keyed on the
        //   `association` and this stage draws by the two lanes it joins.
        let mut dep_edge_of: BTreeMap<(String, String), String> = BTreeMap::new();
        // ⭐⭐⭐ THE GEOMETRY THE DOCUMENT DECLARES, READ AND NEVER INVENTED. A program that
        //    invents coordinates derives the SVG's layout from nothing, and its own header's
        //    claim -- a cache extracted from the GENERATED artifact -- is then false of the one
        //    thing a picture is mostly made of. `bpmndi:BPMNShape` is where BPMN puts a box.
        let mut bounds: BTreeMap<String, (usize, usize, usize, usize)> = Default::default();
        let mut last_shape = String::new();
        // ⭐⭐⭐ THE LEGEND. `documentation` is invisible in every rendering and a `textAnnotation`
        //    is the only element in BPMN that puts words on a canvas, so these are the four facts
        //    a correct reading needs and could not get: what the pool's scope is, whether anybody
        //    looked for a dependence, that a dotted arrow is not flow, and that a dashed box is
        //    not a container. Each one is a place the notation's DEFAULT reading is wrong.
        let mut notes: Vec<String> = Vec::new();
        let mut in_text = false;
        let mut in_cvref = false;
        let mut this_node = String::new();

        loop {
            match reader.read_event_into(&mut buf)? {
                Event::Eof => break,
                Event::Start(e) | Event::Empty(e) => {
                    let tag = String::from_utf8_lossy(e.local_name().as_ref()).into_owned();
                    bpmn_kinds_seen.insert(tag.clone());
                    // ⛔ UNESCAPED HERE, BECAUSE `esc` RUNS ON THE WAY OUT. `a.value` is the
                    //   RAW attribute text, so a name the BPMN filed as `&lt;-` arrives holding
                    //   five characters and `esc` turns its `&` into `&amp;`. Every edge label in
                    //   every emitted SVG read `&lt;-` on screen. A round trip is escape ONCE.
                    let attr = |k: &str| {
                        e.attributes().flatten().find(|a| a.key.local_name().as_ref() == k.as_bytes())
                            .and_then(|a| a.decode_and_unescape_value(dec).ok().map(|v| v.into_owned()))
                    };
                    match tag.as_str() {
                        "participant" => pool = attr("name").unwrap_or_default(),
                        "lane" => {
                            let this = lanes.len();
                            let parent = open.last().copied();
                            lanes.push(Lane {
                                id: attr("id").unwrap_or_default(),
                                name: attr("name").unwrap_or_default(),
                                rank: None,
                                examined: None,
                                violated: None,
                                nodes: Vec::new(),
                                kids: Vec::new(),
                                parent,
                            });
                            if let Some(p) = parent { lanes[p].kids.push(this); }
                            open.push(this);
                            bpmn_lanes += 1;
                        }
                        "documentation" => in_doc = true,
                        "flowNodeRef" => in_ref = true,
                        kind @ ("task" | "callActivity" | "subProcess") => {
                            if let (Some(id), Some(n)) = (attr("id"), attr("name")) {
                                this_node = id.clone();
                                names.insert(id, (kind.to_string(), n));
                                *bpmn_kinds.entry(kind.to_string()).or_default() += 1;
                            }
                        }
                        "categoryValue" => {
                            if let (Some(id), Some(v)) = (attr("id"), attr("value")) {
                                cat_label.insert(id, v);
                            }
                        }
                        "categoryValueRef" => in_cvref = true,
                        "text" => in_text = true,
                        "BPMNShape" => {
                            last_shape = attr("bpmnElement")
                                .map(|q| q.rsplit(':').next().unwrap_or("").to_string())
                                .unwrap_or_default();
                        }
                        "Bounds" => {
                            let num = |k: &str| -> usize {
                                attr(k).and_then(|v| v.parse().ok()).unwrap_or(0)
                            };
                            if !last_shape.is_empty() {
                                bounds.insert(last_shape.clone(),
                                              (num("x"), num("y"), num("width"), num("height")));
                            }
                        }
                        "group" => {
                            if let Some(c) = attr("categoryValueRef") {
                                groups.push(c);
                                group_ids.push(attr("id").unwrap_or_default());
                            }
                        }
                        "BPMNEdge" => {
                            last_edge = attr("bpmnElement")
                                .map(|q| q.rsplit(':').next().unwrap_or("").to_string())
                                .unwrap_or_default();
                        }
                        "waypoint" => {
                            let num = |k: &str| -> usize {
                                attr(k).and_then(|v| v.parse().ok()).unwrap_or(0)
                            };
                            if !last_edge.is_empty() {
                                edge_pts.entry(last_edge.clone()).or_default()
                                        .push((num("x"), num("y")));
                            }
                        }
                        "textAnnotation" => {
                            note_ids.push(attr("id").unwrap_or_default());
                        }
                        "association" => {
                            let q = |v: Option<String>| {
                                v.map(|t| t.rsplit(':').next().unwrap_or("").to_string())
                            };
                            if let (Some(a), Some(b)) = (q(attr("sourceRef")), q(attr("targetRef"))) {
                                dep_edge_of.insert((a.clone(), b.clone()),
                                                   attr("id").unwrap_or_default());
                                deps.push((a, b));
                            }
                            bpmn_deps += 1;
                        }
                        _ => {}
                    }
                }
                // ⛔ A lane's documentation, and ONLY a lane's. A process carries one too and it
                //   says something else; reading whichever came last would put a filing's
                //   provenance where a layer's rank belongs.
                Event::Text(t) if in_doc => {
                    if let Some(l) = open.last().copied().and_then(|i| lanes.get_mut(i)) {
                        if l.rank.is_none() {
                            let txt = String::from_utf8_lossy(&t);
                            if let Some(r) = txt.strip_prefix("rank ") {
                                l.rank = r
                                    .split(|c: char| !c.is_ascii_digit())
                                    .next()
                                    .and_then(|d| d.parse().ok());
                            }
                        }
                        // ⛔ READ, NEVER COMPUTED, exactly as the rank is. This stage holds no
                        //   model by design, so the coverage is a fact the document carries or
                        //   a fact this drawing does not have.
                        if l.examined.is_none() {
                            let txt = String::from_utf8_lossy(&t);
                            if let Some(r) = txt.strip_prefix("refutable by ") {
                                let num = |x: &str| -> Option<i64> {
                                    x.split(|c: char| !c.is_ascii_digit()).find(|d| !d.is_empty())?.parse().ok()
                                };
                                l.examined = num(r);
                                l.violated = r.split_once("rule(s), ").and_then(|(_, m)| num(m));
                            }
                        }
                    }
                }
                Event::Text(t) if in_text => {
                    // ⛔ UNESCAPE ONCE, ON THE WAY IN. `esc` runs on the way out, so reading the
                    //   raw bytes and re-escaping turns a note's `&` into `&amp;` -- the same
                    //   round-trip bug that put `&lt;-` on every edge label in this repository.
                    let raw = String::from_utf8_lossy(&t).into_owned();
                    notes.push(quick_xml::escape::unescape(&raw)
                        .map(|v| v.into_owned()).unwrap_or(raw));
                    bpmn_notes += 1;
                }
                Event::Text(t) if in_cvref => {
                    let cv = String::from_utf8_lossy(&t).trim().to_string();
                    cat_members.entry(cv).or_default().push(this_node.clone());
                    bpmn_cvrefs += 1;
                }
                Event::Text(t) if in_ref => {
                    let id = String::from_utf8_lossy(&t).trim().to_string();
                    if let Some(l) = open.last().copied().and_then(|i| lanes.get_mut(i)) {
                        l.nodes.push(id);
                    }
                    bpmn_refs += 1;
                }
                Event::End(e) => {
                    if e.local_name().as_ref() == b"lane" { open.pop(); }
                    in_ref = false;
                    in_doc = false;
                    in_cvref = false;
                    in_text = false;
                }
                _ => {}
            }
            buf.clear();
        }

        // ⭐ The height follows the content: a lane with three nodes is taller than one with none.
        //   Nothing is dropped to make the picture fit, which is the one thing a renderer must
        //   never do here. `planner.md` transfers: do not pre-digest the diagram.
        let mut y = 46;
        let mut body = String::new();
        // ⭐⭐⭐ THE OUTERMOST GROUP IS THE CONTAINMENT AND NEVER THE RANK. The rank can hold
        //    that slot only while the BPMN is flat: once a local fusion is a `childLaneSet` the
        //    two compete for one slot and only one can be the nesting, which is §8's
        //    inclusion-tree constraint arriving at the SVG stage.
        //
        // ⛔⛔ CONTAINMENT WINS BECAUSE IT IS A TREE AND RANK IS AN ORDER. A lane really does sit
        //    inside its parent, and `<g>` nests for free, so drawing it costs nothing and losing
        //    it is the widest `loses` a rendering can have. The rank is a NUMBER ABOUT a lane, so
        //    it stays where a number belongs: `data-rank`, plus a label on the lane itself.
        //    ⚠️ Grouping by rank while the BPMN nested by containment showed three peers where the
        //    document said one contains the other two. `pm:Stack` still refuses to say A sits
        //    ABOVE B, and nothing here does: containment is *is composed from*, not *is higher*.
        let roots: Vec<usize> =
            (0..lanes.len()).filter(|i| lanes[*i].parent.is_none()).collect();
        let from_graphs = path.to_string_lossy().contains("/graphs/");
        let mut boxes: std::collections::BTreeMap<String, (usize, usize, usize, usize)> =
            Default::default();
        let mut lane_boxes: std::collections::BTreeMap<String, (usize, usize, usize, usize)> =
            Default::default();
        for r in &roots {
            let h = lane_height(&lanes, *r);
            emit_lane(&mut body, &lanes, &names, *r, &bounds, from_graphs, &in_layer_graph,
                      &mut unlinked, &mut svg_lanes, &mut svg_nodes, &mut boxes, &mut lane_boxes)?;
            y += h + 6;
        }

        // ⭐⭐⭐ THE GROUPS, DRAWN LAST AND OVER EVERYTHING, WHICH IS WHAT A GROUP IS. BPMN says a
        //    group implies NO containment and MAY cross lanes and pools, so it cannot be a child
        //    of any lane in the drawing: it is an OVERLAY on the union of its members' boxes. That
        //    is the visual difference between a cover and a partition, and it is the only one.
        //
        // ⛔⛔ AND IT IS DASHED BECAUSE THAT IS THE ENTIRE DISCRIMINATOR. A solid rectangle around
        //    the same nodes is a lane, and a reader who takes a group for a lane has read an
        //    overlapping cover as a partition, which is `pm:Layer`'s falsifier drawn by accident.
        //    The dash is doing the work the thick border does for a `callActivity`.
        for (gi, cv) in groups.iter().enumerate() {
            let ms: Vec<&(usize, usize, usize, usize)> = cat_members
                .get(cv).into_iter().flatten()
                .filter_map(|n| boxes.get(n)).collect();
            _svg_groups += 1;
            if ms.is_empty() { continue; }
            // ⭐⭐⭐ READ, NOT RECOMPUTED. The emitter derives this hull from the same member boxes
            //    and declares it, so taking it from the document is what stops the two stages
            //    being two pictures. ⛔ A cover with no declared shape is a finding rather than
            //    something to fall back from: it means the emitter stopped declaring one.
            let gid = group_ids.get(gi).cloned().unwrap_or_default();
            let &(x0, y0, gw, gh) = bounds.get(&gid).unwrap_or_else(|| panic!(
                "the document declares no bpmndi:BPMNShape for group {gid}"));
            let (x1, y1) = (x0 + gw, y0 + gh);
            let label = cat_label.get(cv).cloned().unwrap_or_else(|| cv.clone());
            writeln!(body, r#"  <g class="group" data-category="{}" id="cover-{}"><title>cover: induces into {}</title>"#,
                     esc(&label), sanitise(&label), esc(&label))?;
            writeln!(body, r#"    <rect id="cover-{}-box" x="{x0}" y="{y0}" width="{}" height="{}" rx="6" class="groupBox"/>"#,
                     sanitise(&label), x1 - x0, y1 - y0)?;
            writeln!(body, r#"    <text id="cover-{}-name" x="{}" y="{}" class="groupName">induces into {}</text>"#,
                     sanitise(&label), x0 + 4, y0 - 3, esc(&label))?;
            writeln!(body, "  </g>")?;
            svg_grouped += ms.len();
        }
        bpmn_groups += groups.len();

        // ⭐⭐ THE DEPENDENCE, DRAWN OUTSIDE THE LANES IT JOINS. It routes into the left gutter
        //    rather than through the bands, because a coupling is not INSIDE either layer: it is
        //    an observation about the pair. Dotted, with an arrowhead, and both are the notation:
        //    a solid line here would be a flow and this model has none.
        let layer_name = |id: &str| -> String {
            lanes.iter().find(|l| l.id == id).map(|l| l.name.clone()).unwrap_or_else(|| id.to_string())
        };
        for (a, b) in &deps {
            bpmn_pairs.push((doc_name.clone(), a.clone(), b.clone()));
            // ⭐⭐⭐ THE ROUTE IS READ FROM `di:waypoint`, NOT COMPUTED FROM THE TWO LANE BOXES.
            //    The emitter runs that arithmetic and declares the result, so a third party
            //    opening the document gets the line and this stage is not a second opinion
            //    about where it goes.
            let Some(pts) = dep_edge_of.get(&(a.clone(), b.clone())).and_then(|k| edge_pts.get(k))
            else { continue };
            let (Some(&(ax, y0)), Some(&(bx, y1))) = (pts.first(), pts.last()) else { continue };
            let gx = pts.get(1).map(|p| p.0).unwrap_or(ax);
            writeln!(body, r#"  <g class="dependence" data-from="{}" data-to="{}" id="dep-{}-{}"><title>dependence: {} moves {}</title>"#,
                     esc(a), esc(b), sanitise(a), sanitise(b),
                     esc(&layer_name(a)), esc(&layer_name(b)))?;
            writeln!(body, r#"    <path id="dep-{}-{}-line" d="M{ax} {y0} H{gx} V{y1} H{bx}" class="depLine" marker-end="url(#depArrow)"/>"#,
                     sanitise(a), sanitise(b))?;
            writeln!(body, "  </g>")?;
            svg_deps += 1;
            svg_pairs.push((doc_name.clone(), a.clone(), b.clone()));
        }

        let mut svg = String::new();
        writeln!(svg, r#"<?xml version="1.0" encoding="UTF-8"?>"#)?;
        writeln!(svg, "<!-- GENERATED from {} by examples/rendering/main.rs. DO NOT EDIT.", path.display())?;
        writeln!(svg, "     Every lane is its own group carrying the layer name; every activity is drawn")?;
        writeln!(svg, "     with the BPMN glyph for its kind, thin for a task and thick for a call. That is")?;
        writeln!(svg, "     what *properly layered* means, and it is what lets a reader check the partition")?;
        writeln!(svg, "     and the call graph with no BPMN tool present. -->")?;
        // ⭐⭐ A POOL IS A BAND, AND DRAWING IT AS A CAPTION COST THE ONE FILING THAT NEEDED IT.
        //    `model-claimants` files a `participant` with no `processRef`, which is BPMN for a
        //    BLACK BOX: a party acts here and what they do is not in this diagram. It has no
        //    lanes, so as a caption it rendered as a word floating over nothing, indistinguishable
        //    from a diagram that failed to draw. As a band it is the correct glyph for free, and
        //    an empty pool is the notation SAYING that the contents are withheld.
        // ⭐ THE PAGE GROWS FOR THE LEGEND RATHER THAN THE LEGEND BEING TRIMMED TO FIT. `planner.md`
        //   transfers: do not pre-digest the diagram, and a note dropped to make a picture tidy is
        //   the one thing a renderer here must never do.
        // ⭐⭐ TWO LINES PER NOTE, BECAUSE A NOTE NOW CARRIES A SENTENCE AND ITS SOURCE. Set on
        //   one line the longest of them runs past the page: 151 characters at 11px is about 830
        //   against a 760 page, and an SVG does not clip, it just draws off the edge where
        //   nothing in this program would ever see it.
        let note_h = if notes.is_empty() { 0 } else { 14 + notes.len() * 30 };
        // ⛔ THE POOL BAND WAS THE LAST INVENTED COORDINATE, and it is declared too. `y` is still
        //   accumulated for the note block below, which hangs UNDER the pool and is derived.
        let pool_box = bounds
            .iter()
            .find(|(k, _)| k.starts_with("pool_"))
            .map(|(_, v)| *v)
            .unwrap_or((8, 36, WIDTH - 16, (y - 36).max(48)));
        let pool_h = pool_box.3;
        writeln!(svg, r#"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {}" width="{WIDTH}">"#, 44 + pool_h + note_h)?;
        writeln!(svg, "  <style>.poolBox{{fill:none;stroke:#333;stroke-width:1.5}} \
                       .laneBox{{fill:none;stroke:#888}} \
                       .activity{{fill:#f4f4f4;stroke:#555}} \
                       .task{{stroke-width:1}} \
                       .callActivity{{stroke-width:3.5}} \
                       .subProcess{{stroke-width:1}} \
                       .marker{{fill:none;stroke:#555;stroke-width:1}} \
                       .laneName{{font:12px sans-serif;font-weight:600}} \
                       .nodeName{{font:11px sans-serif}} \
                       .poolName{{font:13px sans-serif;font-weight:700}} \
                       .rankName{{font:10px sans-serif;fill:#666;letter-spacing:.5px}} \
                       .refuted{{stroke:#b00;stroke-width:2.5}} \
                       .coverName{{font:10px sans-serif;fill:#888}} \
                       .groupBox{{fill:none;stroke:#555;stroke-width:1.5;stroke-dasharray:6 4}} \
                       .groupName{{font:10px sans-serif;fill:#555;font-style:italic}} \
                       .depLine{{fill:none;stroke:#555;stroke-width:1.2;stroke-dasharray:3 3}} \
                       .noteBox{{fill:none;stroke:#555;stroke-width:1}} \
                       .noteText{{font:11px sans-serif;fill:#333}} \
                       .noteCite{{font:9px monospace;fill:#777}}</style>")?;
        // ⛔ `r#"..."#` ENDS AT THE FIRST `"#`, AND A HEX COLOUR IS `"#555"`. Two hashes.
        writeln!(svg, r##"  <defs><marker id="depArrow" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" orient="auto"><path d="M0 0 L8 4 L0 8" fill="none" stroke="#555"/></marker></defs>"##)?;
        writeln!(svg, r#"  <g class="pool" data-filing="{}" id="pool-{}"><title>pool: {}</title>"#,
                 esc(&pool), sanitise(&pool), esc(&pool))?;
        writeln!(svg, r#"    <rect id="pool-{}-box" x="{}" y="{}" width="{}" height="{pool_h}" class="poolBox"/>"#,
                 sanitise(&pool), pool_box.0, pool_box.1, pool_box.2)?;
        writeln!(svg, r#"    <path id="pool-{}-band" d="M{} {} v{pool_h}" class="poolBox"/>"#,
                 sanitise(&pool), pool_box.0 + 28, pool_box.1)?;
        writeln!(svg, r#"    <text id="pool-{}-name" transform="translate({},{}) rotate(-90)" text-anchor="middle" class="poolName">{}</text>"#,
                 sanitise(&pool), pool_box.0 + 18, pool_box.1 + pool_h / 2, esc(&pool))?;
        writeln!(svg, "  </g>")?;
        svg.push_str(&body);
        // ⛔ BPMN DRAWS A textAnnotation AS AN OPEN BRACKET, not a closed box, and the bracket IS
        //   the glyph: it says *these words are commentary and not a container*. A rectangle here
        //   would be one more box on a page whose whole difficulty is which box means what.
        if !notes.is_empty() {
            // ⭐⭐⭐ EACH NOTE SITS WHERE THE DOCUMENT PUTS IT. The emitter declares a
            //    `bpmndi:BPMNShape` per `textAnnotation` now, so these positions are READ, and
            //    the band is the union of what was read rather than a height computed from a
            //    count. ⛔ A note whose annotation declares no shape is a finding: it means the
            //    emitter stopped declaring one and this stage would silently place it by guess.
            let note_boxes: Vec<(usize, usize, usize, usize)> = note_ids
                .iter()
                .map(|nid| *bounds.get(nid).unwrap_or_else(|| panic!(
                    "the document declares no bpmndi:BPMNShape for textAnnotation {nid}")))
                .collect();
            let ny = note_boxes.iter().map(|b| b.1).min().unwrap_or(44 + pool_h);
            let band = note_boxes.iter().map(|b| b.1 + b.3).max().unwrap_or(ny) - ny;
            writeln!(svg, r#"  <g class="note" id="legend"><title>legend</title>"#)?;
            writeln!(svg, r#"    <path id="legend-bracket" d="M20 {} h-8 v{} h8" class="noteBox"/>"#, ny, band)?;
            // ⭐⭐⭐ THE SENTENCE AND WHAT STATES IT ARE TWO LINES, FOR TWO READERS. The note is
            //   the reason the default reading of this page is wrong; the line under it is where
            //   to go and argue. A reader who accepts the note never needs the second line, and a
            //   reader who does not is the only one this repository is built for.
            // ⛔ AND THE SOURCE IS SET IN MONOSPACE BECAUSE IT IS A PATH AND NOT PROSE. Rendered
            //   in the note's own face it reads as the end of the sentence, which is exactly the
            //   confusion `documentation` already causes between a fact and a gloss on one.
            for (i, n) in notes.iter().enumerate() {
                let (says, from) = match n.split_once(" [assets/sqlc/") {
                    Some((a, b)) => (a, Some(b.trim_end_matches(']'))),
                    None => (n.as_str(), None),
                };
                let (bx, by) = note_boxes.get(i).map(|b| (b.0, b.1)).unwrap_or((20, ny));
                writeln!(svg, r#"    <text id="legend-{i}-says" x="{}" y="{}" class="noteText">{}</text>"#,
                         bx + 6, by + 12, esc(says))?;
                if let Some(f) = from {
                    writeln!(svg, r#"    <text id="legend-{i}-source" x="{}" y="{}" class="noteCite">assets/sqlc/{}</text>"#,
                             bx + 6, by + 24, esc(f))?;
                }
                svg_notes += 1;
            }
            writeln!(svg, "  </g>")?;
        }
        writeln!(svg, "</svg>")?;
        {
            let out = drawing_of(path);
            if let Some(d) = out.parent() { fs::create_dir_all(d)?; }
            fs::write(out, svg)?;
        }
    }

    println!("RENDERED {} SVG from {} BPMN, reading no model at all", files.len(), files.len());

    // ------------------------------------------------------------------
    // ⛔⛔ COUNTED ON DISK, AND PARSED RATHER THAN SEARCHED. A counter beside each `writeln!`
    //    counts what this program MEANT to write. A string search over the file counts the
    //    PROSE too: written that way, this found 66 lanes against the BPMN's 51, and the extra
    //    fifteen were the provenance comment at the top of each SVG, which contains the literal
    //    `<g class="lane">` because it explains the law. ⭐ The artifact has to be counted AS
    //    WHAT IT IS. The same slip cost a wrong number once already in this repository, where
    //    `pm.` inside a stripped `#` header was counted as a table read.
    // ------------------------------------------------------------------
    let on_disk = |class: &str| -> usize {
        let mut n = 0;
        for path in &files {
            let svg = fs::read_to_string(drawing_of(path)).unwrap_or_default();
            let mut r = Reader::from_str(&svg);
            let mut b = Vec::new();
            loop {
                match r.read_event_into(&mut b) {
                    Ok(Event::Eof) | Err(_) => break,
                    Ok(Event::Start(e)) | Ok(Event::Empty(e)) => {
                        if e.local_name().as_ref() == b"g"
                            && e.attributes().flatten().any(|a| {
                                a.key.local_name().as_ref() == b"class" && a.value.as_ref() == class.as_bytes()
                            })
                        {
                            n += 1;
                        }
                    }
                    _ => {}
                }
                b.clear();
            }
        }
        n
    };

    println!("\nTHE CACHE AGAINST THE ARTIFACT IT CACHES");
    for (what, bpmn, svg) in [
        ("lanes", bpmn_lanes, on_disk("lane")),
        ("flow nodes in a lane", bpmn_refs, on_disk("node")),
        ("groups", bpmn_groups, on_disk("group")),
        ("dependences", bpmn_deps, on_disk("dependence")),
        ("legend notes", bpmn_notes, svg_notes),
    ] {
        let ok = bpmn == svg;
        println!("   {} {:<22} bpmn {bpmn:>4}   svg {svg:>4}", if ok { "  " } else { "⛔" }, what);
        assert_eq!(bpmn, svg, "the SVG does not carry what the BPMN filed: {what}");
    }
    assert_eq!(svg_lanes, bpmn_lanes, "a lane was emitted that the BPMN did not file");
    assert_eq!(svg_nodes, bpmn_refs, "a node was placed in no lane, which is the orphan again");

    // ⛔⛔ THE COVER'S OWN ORPHAN LAW, AND IT IS NOT THE SAME AS THE GROUP COUNT. A `group` is
    //   drawn from the UNION of its members' boxes, so a document could draw every group it was
    //   given and still enclose nothing, and `|group| = |group|` would pass. What has to hold is
    //   that every `categoryValueRef` the BPMN filed is a node the drawing put INSIDE a dashed
    //   box, which is the membership surviving rather than the container surviving.
    assert_eq!(
        svg_grouped, bpmn_cvrefs,
        "the BPMN files {bpmn_cvrefs} category memberships and the SVG encloses {svg_grouped}: an \
         operation induces into a layer and the picture does not say so"
    );
    assert!(
        bpmn_groups > 0 && bpmn_cvrefs > 0,
        "no group and no categoryValueRef in any document, so both cover laws examined nothing"
    );

    // ⛔⛔⛔ AND THE ONE THAT WOULD HAVE CAUGHT A SILENT DROP HERE. `svg_deps` counts only the
    //   edges this program actually drew, and it `continue`s past any association whose two ends
    //   it could not find a box for. A lane it cannot resolve is a coupling that vanishes, and
    //   the model's falsifier vanishing quietly is the worst thing this pipeline can do.
    assert_eq!(
        svg_deps, bpmn_deps,
        "the BPMN files {bpmn_deps} dependences and the SVG drew {svg_deps}: an association \
         pointed at a lane this stage could not place, so a coupling left the page in silence"
    );
    assert!(bpmn_deps > 0, "no association in any document, so the dependence law examined nothing");
    bpmn_pairs.sort();
    svg_pairs.sort();
    assert_eq!(
        bpmn_pairs, svg_pairs,
        "a dependence in the SVG joins a different pair of lanes than the BPMN filed, so the \
         picture says the wrong layers move together while every count stays exact"
    );
    println!("   ⭐ {bpmn_cvrefs} memberships, all enclosed. A group is DASHED and a lane is not,");
    println!("      which is the whole visual difference between a cover and a partition.");

    // ------------------------------------------------------------------
    // ⛔⛔⛔ ATTRIBUTION, WHICH NO CARDINALITY LAW ABOVE CAN STAND IN FOR. Every law in this file
    //    counts, and a count is blind to a glyph collapse by construction: 38 tasks, 17 call
    //    activities and 10 sub-processes drew 65 identical rectangles and `65 == 65` passed. The
    //    kind has to be checked WHERE IT IS SPENT, so this asks the artifact which kind each node
    //    says it is, and then asks the stylesheet whether it draws them differently.
    // ------------------------------------------------------------------
    let mut svg_kinds: std::collections::BTreeMap<String, usize> = std::collections::BTreeMap::new();
    let mut markers = 0usize;
    for path in &files {
        let svg = fs::read_to_string(drawing_of(path)).unwrap_or_default();
        let mut r = Reader::from_str(&svg);
        let mut b = Vec::new();
        loop {
            match r.read_event_into(&mut b) {
                Ok(Event::Eof) | Err(_) => break,
                Ok(Event::Start(e)) | Ok(Event::Empty(e)) => {
                    if e.local_name().as_ref() == b"g" {
                        if let Some(k) = e.attributes().flatten().find(|a| {
                            a.key.local_name().as_ref() == b"data-kind"
                        }) {
                            *svg_kinds
                                .entry(String::from_utf8_lossy(&k.value).into_owned())
                                .or_default() += 1;
                        }
                    }
                    if e.attributes().flatten().any(|a| {
                        a.key.local_name().as_ref() == b"class" && a.value.as_ref() == b"marker"
                    }) {
                        markers += 1;
                    }
                }
                _ => {}
            }
            b.clear();
        }
    }

    println!("\nEVERY ACTIVITY KIND, DRAWN AS ITSELF");
    assert_eq!(
        bpmn_kinds.keys().collect::<Vec<_>>(),
        svg_kinds.keys().collect::<Vec<_>>(),
        "the SVG draws a different set of activity kinds than the BPMN files"
    );
    for (kind, n) in &bpmn_kinds {
        let drawn = svg_kinds.get(kind).copied().unwrap_or(0);
        println!("      {kind:<14} bpmn {n:>4}   svg {drawn:>4}");
        assert_eq!(*n, drawn, "the SVG lost the kind of an activity: {kind}");
    }

    // ⛔ AND CARRYING THE KIND IS NOT DRAWING IT. A `data-kind` every node holds and no rule
    //   paints is the collapse again with a label on it, so the stylesheet is read too: each kind
    //   must have a rule, and the three must not all say the same thing.
    let style = fs::read_to_string(drawing_of(&files[0])).unwrap_or_default();
    let decl = |k: &str| -> Option<String> {
        let needle = format!(".{k}{{");
        let i = style.find(&needle)? + needle.len();
        let j = style[i..].find('}')? + i;
        Some(style[i..j].trim().to_string())
    };
    let mut painted: Vec<String> = Vec::new();
    for kind in bpmn_kinds.keys() {
        let d = decl(kind).unwrap_or_else(|| panic!("no glyph rule for {kind}: it draws as its neighbours"));
        println!("      {kind:<14} .{kind}{{{d}}}");
        painted.push(d);
    }
    painted.sort();
    let distinct = { let mut p = painted.clone(); p.dedup(); p.len() };
    assert!(
        distinct > 1,
        "every activity kind is painted identically, so the diagram carries the kind and shows none of it"
    );

    // ⛔⛔ AND THE RULE ABOVE IS NOT ENOUGH ON ITS OWN, WHICH IS WORTH SAYING RATHER THAN LEAVING
    //   FOR SOMEBODY TO FIND. `.subProcess` and `.task` carry the SAME stroke and that is correct
    //   BPMN: a sub-process is a thin border plus the ⊞ marker, so its discriminator is an
    //   ELEMENT and not a declaration, and `distinct > 1` above is satisfied by the call activity
    //   alone. Drop the marker and that assertion would still pass. This is the one that fires.
    // ⛔⛔⛔ AND THIS LAW IS VACUOUS, WHICH IT MUST SAY RATHER THAN PASS. A local fusion is a
    //    `childLaneSet`, so the kind this law guards is emitted nowhere and `0 == 0` is true for
    //    the wrong reason. A rule that examines nothing reporting a pass is the single failure
    //    `checks/all.sqlc` is assembled to prevent, and a law in an example owes the same
    //    verdict a rule in the corpus does.
    match svg_kinds.get("subProcess").copied() {
        None | Some(0) => println!(
            "      {:<14} ⛔ VACUOUS: a local fusion is a childLaneSet, so no sub-process is emitted",
            "⊞ marker"
        ),
        Some(subs) => {
            println!("      {:<14} {markers} marker parts for {subs} sub-processes", "⊞ marker");
            assert_eq!(
                markers, subs * 2,
                "a sub-process lost its ⊞ marker, which is the only thing distinguishing it from a task"
            );
        }
    }

    // ------------------------------------------------------------------
    // ⛔⛔⛔ A LANE COUNT IS BLIND TO CONTAINMENT, AND `lanes 98 = 98` PASSED BEFORE ANY LANE WAS
    //    NESTED AT ALL. Nesting MOVES a lane; it does not add or remove one, so every cardinality
    //    law here is true either way. This is the same blind spot as the glyph collapse and the
    //    invented recursion, and it wants the same repair: check the ATTRIBUTION, which is each
    //    lane's PARENT, and not the population.
    // ------------------------------------------------------------------
    // ⛔⛔⛔ AN EDGE LIST, NOT A MAP, AND THE DIFFERENCE IS A LAW THE MAP COULD NOT STATE.
    //    `BTreeMap<node, parent>` holds ONE parent per node, so a node with TWO is not something
    //    it reports, it is something it cannot REPRESENT: the second insert overwrites the first,
    //    and the tree property is ENFORCED by the container instead of CHECKED. The colliding key
    //    hid in exactly that overwrite.
    //
    // ⭐⭐⭐ PIVOT THE LIST BOTH WAYS AND BOTH FACTS FALL OUT. Grouped by CHILD, a count above one
    //    is a node with two parents, which is *not a tree*. Grouped by PARENT it is the branching,
    //    which is the partition. A map can answer the second and is structurally incapable of
    //    asking the first.
    let parents = |ext: &str, cls: bool| -> Vec<(String, String)> {
        let mut out: Vec<(String, String)> = Vec::new();
        for path in &files {
            // ⛔⛔⛔ KEYED BY `(document, layer)`, WHICH IS THE MODEL'S CONFORMED KEY AND WAS
            //   THROWN AWAY HERE. Written keyed on the layer NAME alone, one map held every
            //   document at once: `labour` is a layer in three filings, 51 lanes collapsed to 37
            //   keys, and 14 lanes' parents were never checked. ⭐ And it passed, because BOTH
            //   sides collapse the same way, so a collision on one is a collision on the other
            //   and the equality survives it. The blind spot again: this defect does not change
            //   a count, it changes what the count is OF, and `nested > 0` cannot see that.
            let doc_key = path.file_stem().unwrap_or_default().to_string_lossy().into_owned();
            let doc = if ext == "svg" {
                fs::read_to_string(drawing_of(path)).unwrap_or_default()
            } else {
                fs::read_to_string(path).unwrap_or_default()
            };
            let mut r = Reader::from_str(&doc);
            let mut b = Vec::new();
            let mut open: Vec<String> = Vec::new();
            let dec = r.decoder();
            loop {
                match r.read_event_into(&mut b) {
                    Ok(Event::Eof) | Err(_) => break,
                    Ok(Event::Start(e)) => {
                        let key: &[u8] = if cls { b"data-layer" } else { b"name" };
                        let is_lane = if cls {
                            e.attributes().flatten().any(|a| {
                                a.key.local_name().as_ref() == b"class" && a.value.as_ref() == b"lane"
                            })
                        } else {
                            e.local_name().as_ref() == b"lane"
                        };
                        if is_lane {
                            let n = e
                                .attributes()
                                .flatten()
                                .find(|a| a.key.local_name().as_ref() == key)
                                .and_then(|a| a.decode_and_unescape_value(dec).ok())
                                .map(|v| v.into_owned())
                                .unwrap_or_default();
                            out.push((format!("{doc_key}/{n}"),
                                      open.last().cloned().unwrap_or_default()));
                            open.push(n);
                        } else if cls && e.local_name().as_ref() == b"g" {
                            // ⛔ ONLY `<g>` PUSHES, BECAUSE ONLY `</g>` POPS. Written to push on
                            //   every start element, `<text>` went on the stack and never came
                            //   off, so every lane read as a child of a text node and the law
                            //   accused a correct rendering.
                            open.push(String::new());
                        }
                    }
                    Ok(Event::End(e)) => {
                        if cls {
                            if e.local_name().as_ref() == b"g" { open.pop(); }
                        } else if e.local_name().as_ref() == b"lane" {
                            open.pop();
                        }
                    }
                    _ => {}
                }
                b.clear();
            }
        }
        out
    };
    let bpmn_parents = parents("bpmn", false);
    let svg_parents = parents("svg", true);
    // ⭐⭐ PIVOT BY CHILD. The count per node is 1 for a tree; anything higher is a node with
    //   two parents, and a map keyed the other way cannot hold one. ⛔ Under the colliding key
    //   `labour` is a layer in three filings, so this is the direct route to that defect: it is
    //   not a lost row, it is a node whose parent depends on which document you read last.
    let by_child = |es: &Vec<(String, String)>| -> BTreeMap<String, Vec<String>> {
        let mut m: BTreeMap<String, Vec<String>> = BTreeMap::new();
        for (c, p) in es { m.entry(c.clone()).or_default().push(p.clone()); }
        m
    };
    // ⭐⭐ PIVOT BY PARENT. The children of each node: the branching, which is the partition.
    let by_parent = |es: &Vec<(String, String)>| -> BTreeMap<String, Vec<String>> {
        let mut m: BTreeMap<String, Vec<String>> = BTreeMap::new();
        for (c, p) in es.iter().filter(|(_, p)| !p.is_empty()) {
            m.entry(p.clone()).or_default().push(c.clone());
        }
        m
    };
    let child_pivot = by_child(&bpmn_parents);
    let two_parents: Vec<&String> =
        child_pivot.iter().filter(|(_, ps)| ps.len() > 1).map(|(k, _)| k).collect();
    let nested = bpmn_parents.iter().filter(|(_, v)| !v.is_empty()).count();
    // ------------------------------------------------------------------
    // ⛔⛔⛔ EVERY BOX THE DOCUMENT DECLARES IS DRAWN AT EXACTLY THOSE COORDINATES. Before
    //    `bpmndi:BPMNDiagram` was emitted this stage INVENTED its geometry, so the SVG's layout
    //    was derived from nothing and this file's own header -- *a cache extracted from the
    //    GENERATED artifact* -- was false of the one thing a picture is mostly made of. The
    //    document declares its own picture now, and this is the law that the SVG is a rendering
    //    of that declaration rather than a second opinion beside it.
    // ------------------------------------------------------------------
    // ⛔⛔⛔ THE EXPECTED TRACE IS PER ELEMENT KIND, BECAUSE NOT EVERY DECLARED SHAPE IS A BOX.
    //    A pool, a lane and a flow node are each drawn as a `rect` carrying
    //    `x`/`y`/`width`/`height`, so one literal string proves the bounds was honoured. BPMN's
    //    glyph for a `textAnnotation` is an OPEN BRACKET, and a rect there would be one more box
    //    on a page whose whole difficulty is which box means what.
    // ⭐⭐ So a declared bounds is honoured by the mark THAT KIND takes: a rect kind owes the
    //    literal bounds, an annotation owes its text inside the box it is given. ⚠️ Getting this
    //    wrong in the lenient direction is the whole risk, so the two forms are counted apart and
    //    printed: a law that accepted anything for the second kind would be no law.
    let mut misplaced = Vec::new();
    let mut placed = 0usize;
    let mut placed_as_text = 0usize;
    for path in &files {
        let doc = fs::read_to_string(path)?;
        let svg = fs::read_to_string(drawing_of(path)).unwrap_or_default();
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("<dc:Bounds ") {
            // ⭐ The element the bounds belongs to is the `bpmnElement` of the shape that opened
            //   just before it, which is the nearest one behind this position.
            // ⛔ THE OFFSET MUST INCLUDE `i`, so the slice ends at the bounds tag and not at the
            //   start of `rest`. Taken from `rest` it stops at the PREVIOUS match and attributes
            //   every box to whichever element was declared before it, silently.
            let abs = doc.len() - rest.len() + i;
            let subject = doc[..abs]
                .rmatch_indices("bpmnElement=\"")
                .next()
                .map(|(j, m)| doc[j + m.len()..].split('"').next().unwrap_or("").to_string())
                .unwrap_or_default();
            rest = &rest[i + 11..];
            let end = rest.find("/>").unwrap_or(rest.len());
            let tag = &rest[..end];
            let g = |k: &str| -> String {
                tag.split_once(&format!("{k}=\""))
                    .and_then(|(_, r)| r.split_once('"'))
                    .map(|(v, _)| v.to_string())
                    .unwrap_or_default()
            };
            let is_note = subject.rsplit(':').next().unwrap_or("").starts_with("note_");
            let want = if is_note {
                // the annotation's text, placed inside the box the document gave it
                let y: usize = g("y").parse().unwrap_or(0);
                format!("y=\"{}\" class=\"noteText\"", y + 12)
            } else {
                format!("x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\"",
                        g("x"), g("y"), g("width"), g("height"))
            };
            placed += 1;
            if is_note { placed_as_text += 1 }
            if !svg.contains(&want) {
                misplaced.push(format!("{}: {} {want}", path.display(), subject));
            }
            rest = &rest[end..];
        }
    }
    // ------------------------------------------------------------------
    // ⛔⛔⛔ *PROPERLY LAYERED* IS THE WHOLE SPEC AND EVERY GROUP WAS ANONYMOUS. No `id` and no
    //    name, so an editor listed untitled groups and a reader could not tell one from another.
    //    ⛔ The fix is NOT a vendor layer flag: SVG has no layers, a layer IS a group, and taking
    //    one editor's extension would put this drawing inside that editor exactly as
    //    `extensionElements` would put the model inside a BPMN document. `id` and `<title>` are
    //    what SVG itself defines, and `<title>` is the element's accessible name.
    //
    // ⭐⭐ AND THE LAYERING IS THE MODEL'S SHAPE, WHICH IS WHY IT IS CHECKABLE. The containment
    //    is a tree, so lanes are nested SUBLAYERS. The cover, each dependence and the legend
    //    CROSS the containment, so each is its own layer on top and can be switched off one at a
    //    time, which is how a reader confirms an overlay is an overlay.
    // ------------------------------------------------------------------
    let mut unlayered = Vec::new();
    let (mut layers, mut labelled) = (0usize, 0usize);
    for path in &files {
        let doc = fs::read_to_string(drawing_of(path)).unwrap_or_default();
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("<g ") {
            rest = &rest[i..];
            let end = rest.find('>').unwrap_or(rest.len());
            let tag = &rest[..end];
            let structural = ["class=\"pool\"", "class=\"lane\"", "class=\"group\"",
                              "class=\"dependence\"", "class=\"note\""]
                .iter().any(|c| tag.contains(c));
            if structural {
                let named = tag.contains("id=\"") && rest[end..].starts_with("><title>");
                if named { layers += 1 }
                else { unlayered.push(format!("{}: {}", path.display(), &tag[..tag.len().min(46)])) }
            }
            if rest[end..].starts_with("><title>") { labelled += 1 }
            rest = &rest[end..];
        }
    }
    // ⛔⛔ AND THE LEAVES TOO, WHICH IS WHERE A TOOL INVENTS NAMES. A `<rect>` or a `<text>` with
    //   no `id` is listed as `rect14` or `text20`, a number assigned by position, so it renumbers
    //   the moment anything above it changes. Anything written against such a name, an
    //   annotation, a stylesheet, a script, silently points somewhere else on the next emission.
    let mut anonymous = Vec::new();
    let mut collided: Vec<String> = Vec::new();
    let mut drawn = 0usize;
    let mut shared: BTreeMap<String, usize> = BTreeMap::new();
    for path in &files {
        let doc = fs::read_to_string(drawing_of(path)).unwrap_or_default();
        let body = doc.split_once("</defs>").map(|(_, b)| b).unwrap_or(&doc);
        // ⛔⛔ UNIQUE WITHIN A DOCUMENT, WHICH IS ALL AN `id` PROMISES, so a law checking it
        //   across all of them at once accuses every lane. A REPEAT
        //   ACROSS DOCUMENTS IS THE MECHANISM RATHER THAN THE DEFECT: `lane_every-absence_mixer`
        //   is the same lane in the filing's drawing and in the layer graph's, and that is what
        //   makes `href="...#lane_every-absence_mixer"` resolve to the same layer in both.
        let mut here: BTreeMap<String, usize> = BTreeMap::new();
        for tag in ["<rect ", "<text ", "<path "] {
            let mut rest = body;
            while let Some(i) = rest.find(tag) {
                rest = &rest[i..];
                let end = rest.find('>').unwrap_or(rest.len());
                let el = &rest[..end];
                drawn += 1;
                match el.split_once("id=\"").and_then(|(_, r)| r.split_once('"')) {
                    Some((id, _)) => {
                        *here.entry(id.to_string()).or_default() += 1;
                        *shared.entry(id.to_string()).or_default() += 1;
                    }
                    None => anonymous.push(format!("{}: {}", path.display(), &el[..el.len().min(44)])),
                }
                rest = &rest[end..];
            }
        }
        collided.extend(here.into_iter().filter(|(_, n)| *n > 1).map(|(k, _)| format!("{}: {k}", path.display())));
    }
    assert!(
        anonymous.is_empty(),
        "a drawn element carries no id, so a tool names it by position and that name renumbers on \
         the next emission: {anonymous:?}"
    );
    assert!(
        collided.is_empty(),
        "two elements in ONE document share an id, so a reference resolves to whichever came \
         first: {collided:?}"
    );

    // ------------------------------------------------------------------
    // ⛔⛔⛔ EVERY LINK RESOLVES, AND THE LINK GRAPH IS `F`. A drawing that points at a document
    //    that is not there, or at an id inside it that is not there, is worse than one that does
    //    not point at all: it looks traversable and stops. So each `href` is opened and the
    //    fragment looked for in the file it names.
    //
    // ⭐⭐⭐ AND FOLLOWING THEM IS A GEOMETRIC CHECK OF THE COMPOSITION. A call's link goes to the
    //    LAYER it calls, which is the grain `calledElement` cannot carry, so the set of call
    //    links read out of the drawings must be exactly `F`'s foreign edges. A reader who walks
    //    them by hand has traced the composition with no model and no database present, which is
    //    what *verifies with no tool* was always supposed to mean.
    // ------------------------------------------------------------------
    let mut dangling = Vec::new();
    let mut call_links: Vec<(String, String, String)> = Vec::new();
    let mut lane_links = 0usize;
    for path in &files {
        let here = drawing_of(path);
        let doc = fs::read_to_string(&here).unwrap_or_default();
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("<a href=\"") {
            rest = &rest[i + 9..];
            let (href, tail) = rest.split_once('"').unwrap_or(("", ""));
            let (file, frag) = href.split_once('#').unwrap_or((href, ""));
            let target = here.parent().map(|d| d.join(file)).unwrap_or_default();
            match fs::read_to_string(&target) {
                Ok(t) if t.contains(&format!("id=\"{frag}\"")) => {
                    if file.contains("model-layers") { lane_links += 1 } else {
                        let from = path.file_stem().unwrap_or_default().to_string_lossy().into_owned();
                        let to = std::path::Path::new(file).file_stem()
                            .unwrap_or_default().to_string_lossy().into_owned();
                        call_links.push((from, to, frag.to_string()));
                    }
                }
                _ => dangling.push(format!("{}: {href}", here.display())),
            }
            rest = tail;
        }
    }
    unlinked.sort();
    unlinked.dedup();
    println!("\nTHE LINKS BETWEEN DRAWINGS, FOLLOWED");
    println!("   ⭐ {} lanes link into the layer graph and {} do not, which is the graph being",
             lane_links_expected(&files, &in_layer_graph), unlinked.len());
    println!("      about COMPOSITION. A layer in no part, in either direction, is in no");
    println!("      composition, so it is correctly not a node there and the drawing says so by");
    println!("      not linking. The missing link is the fact, not a gap in the drawing.");
    println!("   {} lane links into the layer graph, {} call links into another filing, {} dangling",
             lane_links, call_links.len(), dangling.len());
    assert!(
        dangling.is_empty(),
        "a link points at a document or an id that is not there, so the drawing looks traversable \
         and stops: {dangling:?}"
    );
    assert!(lane_links > 0 && !call_links.is_empty(), "no link was followed, so this law examined nothing");
    // ⭐⭐⭐ AND THE CALL LINKS ARE `F`, WHICH IS THE CHECK WALKING THEM PERFORMS. The BPMN
    //    declares `F` at layer grain in its `relationship` elements, because `calledElement` names
    //    a PROCESS and cannot. The drawing links at layer grain for the same reason. So the two
    //    must be the same edge set, and a reader who follows the links by hand has traced the
    //    composition with no model, no database and no BPMN tool present.
    let mut declared: Vec<(String, String, String)> = Vec::new();
    for path in &files {
        let doc = fs::read_to_string(path)?;
        let from = path.file_stem().unwrap_or_default().to_string_lossy().into_owned();
        let mut rest = doc.as_str();
        while let Some(i) = rest.find("<relationship type=\"process-modulus:part\"") {
            rest = &rest[i..];
            let end = rest.find("</relationship>").unwrap_or(rest.len());
            let blk = &rest[..end];
            let tgt = blk.split_once("<target>").and_then(|(_, r)| r.split_once("</target>"))
                .map(|(v, _)| v.trim().to_string()).unwrap_or_default();
            let local = tgt.rsplit(':').next().unwrap_or("").to_string();
            let owner = local.strip_prefix("lane_").and_then(|r| {
                doc.match_indices("location=\"").find_map(|(j, _)| {
                    let f = doc[j + 10..].split_once('"').map(|(v, _)| v.trim_end_matches(".bpmn").to_string())?;
                    r.strip_prefix(&format!("{f}_")).map(|_| f)
                })
            }).unwrap_or_default();
            declared.push((from.clone(), owner, local));
            rest = &rest[end..];
        }
    }
    declared.sort();
    let mut walked = call_links.clone();
    walked.sort();
    println!("   ⭐ {} call links walked, {} `relationship` edges declared in the BPMN",
             walked.len(), declared.len());
    assert_eq!(
        walked, declared,
        "the links a reader can walk are not the edges the documents declare, so tracing the \
         drawings by hand reconstructs a different composition than the model states"
    );
    println!("      Identical. A call links to the LAYER it calls, which is the grain");
    println!("      `calledElement` cannot carry, so walking them traces the composition by hand.");

    println!("\nWHAT A DRAWING TOOL SEES, IN STANDARD SVG");
    println!("   {layers} named structural groups, {labelled} titled elements, {} anonymous",
             unlayered.len());
    println!("   {drawn} drawn elements, each with an id unique in its own document");
    assert!(layers > 0, "no group carries a name, so *properly layered* is a claim about nothing");
    assert!(
        unlayered.is_empty(),
        "a structural group has no id and no <title>, so an editor lists it untitled and the \
         drawing cannot be read apart: {unlayered:?}"
    );
    println!("   ⭐ `id` and `<title>` and nothing vendor specific. Lanes nest because the");
    println!("      containment is a tree; the cover, each dependence and the legend are separate");
    println!("      groups because they CROSS it, so a reader can hide them one at a time.");

    // ------------------------------------------------------------------
    // ⛔⛔⛔ EVERY MARK'S GEOMETRY IS DECLARED READ OR COMPUTED, AND THREE KINDS WERE EXEMPT IN
    //    SILENCE. `misplaced` compares each mark against the `bpmndi:BPMNShape` for it, so it
    //    is a statement about the marks that HAVE one, and `placed` reads as a completeness
    //    figure while three kinds sit outside it: the cover box is the union of its members', a
    //    dependence line is routed through the gutter, and the legend band is sized from the
    //    notes it holds. Measured: **no** `bpmnElement` beginning `grp_`, `assoc_` or `note_`
    //    is ever the subject of a declared shape, in any of the 18 documents.
    //
    // ⛔ AND THE FATE ROSTER SAYS THE OPPOSITE IN THIS FILE. `BPMNShape` is filed as *READ and
    //    never computed*, which is true of a pool, a lane and a flow node and false of the other
    //    three. A claim narrower than it reads, in the stage whose own comment says it stopped
    //    inventing coordinates the moment it could read them.
    //
    // ⭐⭐⭐ AND THE REASON IS NOT THIS FILE'S TO GIVE. `diagrams/shapes.sqlc` names these three
    //    and says why: *filing a box for a derived shape would file a value that can disagree
    //    with the thing that computes it*, which is the same test `eliminations/derived.sqlc`
    //    passes one algebra over. A derivable coordinate must not be FILED, exactly as a
    //    derivable magnitude must not be. ⛔ A row here saying *no shape is declared for a group*
    //    would be a fact about the artifact standing where a principle belongs, and it would make
    //    a decision look settled that this stage does not get to make.
    //
    // ⚠️ AND THE PRINCIPLE DOES NOT SAY WHAT IT LOOKS LIKE IT SAYS. It forbids FILING a derived
    //    coordinate in a relation; it says nothing against DERIVING one into an artifact, which
    //    is what the three lines below already do into the SVG. So whether the emitter should
    //    derive them into `bpmndi` as well is open, and the answer would move all six of these
    //    rows to `read`. `diagrams/shapes.sqlc` carries no coordinates for anything, so that is
    //    a question about the EMITTER and not a missing relation.
    //
    // ⭐⭐ WHAT THIS ROSTER IS FOR, THEN: a fourth kind cannot join the three without somebody
    //    saying so, and the shortfall is a printed figure rather than something an outside
    //    reader has to find. Closed both ways, like the two rosters above.
    //    docs/plans/FINDINGS-2026-09-10.
    // ------------------------------------------------------------------
    // ⚠️ AND THE MARK COUNT IS NOT THE ELEMENT COUNT, WHICH IS THIS SESSION'S OWN LESSON ARRIVING
    //   HERE. One legend bracket holds every annotation in its document, so `noteBox` is 15 marks
    //   over 35 `textAnnotation` elements. Reporting 15 would read as fifteen annotations. Each
    //   row carries the element it stands for and both numbers are printed.
    let geometry: &[(&str, &str, &str, &str)] = &[
        ("poolBox",  "participant",    "read",    "bpmndi:BPMNShape for the participant"),
        ("laneBox",  "lane",           "read",    "bpmndi:BPMNShape for the lane"),
        ("activity", "task",           "read",    "bpmndi:BPMNShape for the flow node"),
        ("groupBox", "group",          "read",    "bpmndi:BPMNShape for the group, whose hull the emitter derives from its members"),
        ("depLine",  "association",    "read",    "bpmndi:BPMNEdge, four di:waypoints describing the gutter run"),
        // ⭐⭐⭐ `derived` IS THE THIRD STATE AND IT IS NOT A SOFTER `computed`. This bracket is
        //    the only mark on the page that is not any BPMN element's glyph: it groups the
        //    annotation boxes, and those ARE read. So there is no shape for it to honour and
        //    nothing being thrown away. ⛔ `computed` means placed from geometry the document
        //    does not carry, and after this pass NOTHING is in that state, which is the whole
        //    of finding 2. A row arriving there again is the regression.
        ("noteBox",  "",               "derived", "a bracket around the annotation boxes, which are read; it is no element's own glyph, so no shape declares it"),
    ];
    let svg_all_marks: String = files
        .iter()
        .filter_map(|p| fs::read_to_string(drawing_of(p)).ok())
        .collect();
    let bpmn_all_docs: String = files.iter().filter_map(|p| fs::read_to_string(p).ok()).collect();
    let mark_count = |class: &str| -> usize {
        svg_all_marks.matches(&format!("class=\"{class}")).count()
    };
    // ⛔⛔⛔ THE DRAWN KINDS COME OFF THE ARTIFACT, NOT OFF A LIST BESIDE THE ROSTER. Written as a
    //    literal checked against a literal this arm could never report a kind nobody declared,
    //    which is the contract-derived-from-what-it-governs defect and the exact shape of the
    //    hole it exists to close. Every `class` on a `rect` or a `path` in every drawing must be
    //    on the roster above, so a new mark added to this stage fails the run.
    let mut drawn_kinds: std::collections::BTreeSet<String> = std::collections::BTreeSet::new();
    let mut rest = svg_all_marks.as_str();
    // ⛔ THE MINIMUM OF THE TWO, NOT `or_else`. `or_else` only looks for a path when there is no
    //   rect left in the whole remainder, so every path before the last rect was skipped and this
    //   arm found four kinds of six. A scan that silently sees less than the page is the defect
    //   this roster is for, one level down.
    while let Some(i) = [rest.find("<rect "), rest.find("<path ")].into_iter().flatten().min() {
        rest = &rest[i + 6..];
        let Some(gt) = rest.find('>') else { break };
        if let Some((_, after)) = rest[..gt].split_once("class=\"") {
            if let Some((v, _)) = after.split_once('"') {
                if let Some(first) = v.split_whitespace().next() {
                    drawn_kinds.insert(first.to_string());
                }
            }
        }
        rest = &rest[gt..];
    }
    let undeclared: Vec<&String> = drawn_kinds
        .iter()
        .filter(|k| !geometry.iter().any(|g| g.0 == k.as_str()))
        .collect();
    let stale_geom: Vec<&str> = geometry.iter().map(|g| g.0).filter(|c| mark_count(c) == 0).collect();
    let element_count = |el: &str| -> usize {
        bpmn_all_docs.matches(&format!("<{el} ")).count() + bpmn_all_docs.matches(&format!("<{el}>")).count()
    };
    // ⛔ THE CONVERSE ARM, AND IT IS THE ONE THAT WOULD CATCH THE REPAIR GOING HALF WAY. A kind
    //   declared `computed` whose element DOES have a declared shape is a document offering
    //   geometry this stage throws away, which is the same disagreement pointing the other way.
    let ignored: Vec<&str> = geometry
        .iter()
        .filter(|g| g.2 == "computed")
        .map(|g| g.0)
        .filter(|c| {
            let prefix = match *c { "groupBox" => "grp_", "depLine" => "dep_", _ => "note_" };
            bpmn_all_docs.contains(&format!("bpmnElement=\"tns:{prefix}"))
                || bpmn_all_docs.contains(&format!("bpmnElement=\"{prefix}"))
        })
        .collect();

    println!("\nTHE DECLARED GEOMETRY, AGAINST WHAT THE SVG DREW");
    let (mut computed_marks, mut computed_els) = (0usize, 0usize);
    for (class, el, source, why) in geometry {
        let (n, e) = (mark_count(class), element_count(el));
        if *source == "computed" { computed_marks += n; computed_els += e }
        println!("   {source:<8} {class:<9} {n:>3} marks / {e:>2} <{el}>   {why}");
    }
    println!("   {placed} bpmndi:BPMNShape bounds read, {placed_as_text} of them honoured by an \
              annotation's text rather than by a rect, {} drawn somewhere else, {computed_marks} \
              marks placed by this stage for {computed_els} elements",
             misplaced.len());
    println!("   {} mark kinds on the page, every one declared read, derived or computed", drawn_kinds.len());
    assert!(placed > 0, "no document declares a box, so this stage is inventing geometry again");
    // ⛔ THE LENIENT FORM NEEDS A POSITIVE CONTROL, because it is the one that could accept
    //   anything. At zero it has never run and the strict form is the only form there is; at all
    //   of them the strict form has never run and every box is checked by the weaker test.
    assert!(
        placed_as_text > 0 && placed_as_text < placed,
        "the lenient arm of this law, a bounds honoured by an annotation's text, covers \
         {placed_as_text} of {placed} declared boxes, so one of the two arms is doing no work"
    );
    assert!(
        misplaced.is_empty(),
        "the SVG draws a shape at coordinates the document does not declare, so the picture and \
         the document are two pictures of one model: {misplaced:?}"
    );
    assert!(
        undeclared.is_empty(),
        "the SVG draws a mark whose geometry this roster does not declare as read or computed, \
         so a fourth kind can be placed by guesswork in silence exactly as three already were: \
         {undeclared:?}"
    );
    assert!(
        stale_geom.is_empty(),
        "this roster declares a geometry source for a mark no drawing carries, so it describes a \
         renderer that no longer exists: {stale_geom:?}"
    );
    let mis_stated: Vec<&str> = geometry
        .iter()
        .filter(|g| (g.2 == "derived") != g.1.is_empty())
        .map(|g| g.0)
        .collect();
    assert!(
        mis_stated.is_empty(),
        "a mark declares `derived` and names an element, or declares read/computed and names \
         none. `derived` means it is no element's glyph, which is exactly why it owes no shape: \
         {mis_stated:?}"
    );
    assert!(
        ignored.is_empty(),
        "a mark is declared `computed` and its element HAS a bpmndi shape in the document, so \
         this stage is throwing away geometry a document offered: {ignored:?}"
    );
    println!("   ⭐ Every box declared in the document is where the document says, and this stage");
    println!("      places nothing a document could have declared. A cover, a dependence line and");
    println!("      an annotation each owe a bpmndi shape for that reason: a coordinate computed");
    println!("      here is a coordinate no other reader of the file has, so a third party opening");
    println!("      the file gets the pools, the lanes and the tasks and loses the rest silently.");
    println!("   ⛔ `derived` is the one row that is read from nothing, and it is not a softer");
    println!("      `computed`: the legend bracket is no BPMN element's glyph, so no shape exists");
    println!("      for it to honour.");

    println!("\nTHE CONTAINMENT, WHICH NO LANE COUNT CAN SEE");
    println!("   {nested} of {} lanes sit inside another", bpmn_parents.len());

    assert!(
        two_parents.is_empty(),
        "a lane has more than one parent, so the containment is not a tree and each of these \
         nodes sits wherever the last document read put it: {two_parents:?}"
    );
    assert_eq!(
        bpmn_parents.len(), bpmn_lanes,
        "the edge list holds {} entries and the documents filed {bpmn_lanes} lanes, so the \
         containment law is comparing a population that is missing some of them",
        bpmn_parents.len()
    );

    // ⭐⭐⭐ SELF-JOIN ON `parent = child`, ITERATED, WHICH IS THE CLOSURE. Depth is then a fold
    //    over the closure rather than a second walk, exactly as `rank/evaluation_order.sqlc`
    //    takes the rank as a WINDOW over `composition/descent.sqlc` instead of walking twice.
    //    ⛔ Hand-walking upward per node was what this file did first, and it is the move the
    //    repository already refuses on the model side.
    let parent_of: BTreeMap<&str, &str> = bpmn_parents
        .iter()
        .filter(|(_, p)| !p.is_empty())
        .map(|(c, p)| (c.as_str(), p.as_str()))
        .collect();
    let mut reach: Vec<(String, String, usize)> = parent_of
        .iter()
        .map(|(c, p)| ((*c).to_string(), (*p).to_string(), 1usize))
        .collect();
    let mut frontier = reach.clone();
    for _ in 0..bpmn_parents.len() {
        let mut next = Vec::new();
        for (c, a, d) in &frontier {
            let doc = c.split_once('/').map(|(x, _)| x).unwrap_or("");
            if let Some(up) = parent_of.get(format!("{doc}/{a}").as_str()) {
                next.push((c.clone(), (*up).to_string(), d + 1));
            }
        }
        if next.is_empty() { break; }
        reach.extend(next.iter().cloned());
        frontier = next;
    }
    let mut deepest_of: BTreeMap<&str, usize> = BTreeMap::new();
    for (c, _, d) in &reach {
        let e = deepest_of.entry(c.as_str()).or_default();
        if d > e { *e = *d; }
    }
    let deepest = deepest_of.values().copied().max().unwrap_or(0);
    let parent_pivot = by_parent(&bpmn_parents);
    let widest = parent_pivot.values().map(|v| v.len()).max().unwrap_or(0);
    let mut profile: BTreeMap<usize, usize> = BTreeMap::new();
    for (c, _) in &bpmn_parents {
        *profile.entry(deepest_of.get(c.as_str()).copied().unwrap_or(0)).or_default() += 1;
    }
    println!("   depth      {profile:?}   deepest {deepest}   ancestor pairs {}", reach.len());
    println!("   branching  {} parents, widest holds {widest}", parent_pivot.len());
    assert!(nested > 0, "no lane is nested, so this law examined nothing");
    assert!(
        deepest >= 2,
        "every nesting is one level deep, so a `childLaneSet` inside a `childLaneSet` is \
         unexercised and the recursion this element exists for has never been drawn"
    );
    assert!(
        widest >= 2,
        "no parent lane holds more than one child, so a sub-PARTITION with more than one part is \
         unexercised and every nesting here is indistinguishable from a rename"
    );
    let mut b = bpmn_parents.clone(); b.sort();
    let mut v = svg_parents.clone(); v.sort();
    assert_eq!(
        b, v,
        "the SVG puts a lane under a different parent than the BPMN filed, so the partition a \
         reader sees is not the partition the document states"
    );
    println!("   ⭐ Every lane sits under the parent the BPMN filed. `childLaneSet` is the");
    println!("      partition recursing, and `<g>` inside `<g>` is the SVG for it, so the one");
    println!("      format that nests for free stopped throwing the containment away.");

    println!("   ⭐ Checked against the BPMN and not against the model, because a cache is");
    println!("      verified against the thing it caches. `diagramming` carries the other link.");

    // ------------------------------------------------------------------
    // ⛔⛔⛔ WHAT THIS STAGE DOES WITH EVERY ELEMENT BPMN FILED, DECLARED RATHER THAN INFERRED.
    //    This is `diagrams/notation.sqlc`'s argument arriving one stage later, and it arrived
    //    because the argument was RIGHT and the stage did not have it. `induction` was given a
    //    notation, the BPMN grew `category`, `categoryValue`, `categoryValueRef` and `group`, the
    //    SVG carried NONE of them, and every law in this file stayed green: they count lanes and
    //    nodes, and the cover is neither. A count cannot report an element it was never told to
    //    look for, which is the same hole one stage down.
    //
    // ⭐⭐ A LITERAL, FOR THE REASON `notation.sqlc` IS A LITERAL. Derived from what the SVG
    //    draws, this could report a shape this stage drew and never decided about, and never a
    //    BPMN element it ignored. Nothing this stage silently drops leaves a trace in the SVG.
    //
    // ⭐ THREE FATES, AND THE SECOND IS THE ONE THAT NEEDS SAYING. `glyph` means a shape is
    //   drawn. `geometry` means the element became POSITION rather than ink, which is a faithful
    //   translation and not a loss: a `laneSet` IS the subdivision, so it is the arrangement of
    //   the lanes and never a mark. `dropped` is a finding and must carry what was lost.
    // ------------------------------------------------------------------
    let fate: &[(&str, &str, &str)] = &[
        ("definitions",    "geometry", "the document is the file; one SVG per BPMN is the mapping"),
        ("collaboration",  "geometry", "the frame the pool sits in, and the pool is the band"),
        ("process",        "geometry", "the pool's contents, so it is everything inside the band"),
        ("import",         "dropped",  "⛔ a document reached through a part, and the SVG shows no edge leaving the page. The call is drawn as a node and its TARGET is a name in the label"),
        ("participant",    "glyph",    "the pool band, and an empty one is BPMN saying the contents are withheld"),
        ("laneSet",        "geometry", "it IS the subdivision, so it is the arrangement of the lanes"),
        ("lane",           "glyph",    "a titled box, and its nesting is <g> inside <g>"),
        ("childLaneSet",   "geometry", "the recursion, carried by the nesting rather than by a mark"),
        ("flowNodeRef",    "geometry", "membership, drawn by putting the node inside the lane"),
        ("task",           "glyph",    "a thin rounded rectangle"),
        ("callActivity",   "glyph",    "a THICK rounded rectangle, and the thickness is the notation for substitution"),
        // ⛔⛔⛔ THIS ROW IS AT THE WRONG GRAIN AND ANSWERS FOR ONE USE OUT OF SIX. See the
        //   per-USE roster below: `documentation` is an ANNOTATION, admitted on any base element,
        //   and it carries as many different facts as the `uses` roster below has rows, each with
        //   its own fate. Calling the KIND `geometry`
        //   on the strength of the rank is the fate roster's own blind spot: 20 kinds, 20 fates,
        //   0 undecided, and 37 facts falling off the page.
        ("documentation",  "geometry", "⚠️ SPLIT BY USE below; the kind alone cannot answer"),
        ("textAnnotation", "glyph",    "an OPEN BRACKET under the pool, which is BPMN's own glyph and says these words are commentary rather than a container"),
        ("text",           "glyph",    "the words themselves, one line each"),
        // ⭐⭐⭐ THE ONE PLACE `geometry` IS LITERAL RATHER THAN A METAPHOR. Everywhere else it
        //   means *this element became position rather than ink*; here the element IS the
        //   position, and this stage stopped inventing coordinates the moment it could read them.
        ("BPMNDiagram",    "geometry", "the picture itself, which becomes the <svg> element"),
        ("BPMNPlane",      "geometry", "the surface, which becomes the viewBox"),
        ("BPMNShape",      "geometry", "⭐ the box of a pool, lane or flow node, READ and never computed: one with no declared shape fails the run rather than being placed by guesswork. ⛔ THAT IS THREE KINDS AND NOT ALL OF THEM, and this row read as all of them until a reader outside this repository refused four documents. The cover, the dependence line and the legend are placed by this stage, and `THE DECLARED GEOMETRY` below is where each mark says which"),
        ("Bounds",         "geometry", "x, y, width, height. The one number this pipeline draws, because a coordinate is not a magnitude"),
        ("BPMNEdge",       "geometry", "⭐ the route of the one edge in the notation, READ now rather than recomputed here from the two lane boxes"),
        ("waypoint",       "geometry", "a corner of that route, from the DI namespace proper. Four of them describe the gutter run that keeps the line outside both lanes"),
        ("category",       "geometry", "the scheme; its VALUES are what get drawn"),
        ("categoryValue",  "glyph",    "the dashed box's label, which is the layer induced into"),
        ("categoryValueRef", "geometry", "membership again, drawn by enclosing the node in the dashed box"),
        ("group",          "glyph",    "a DASHED rounded rectangle, overlaid because a cover may cross lanes"),
        ("association",    "glyph",    "a DOTTED line with an arrowhead, routed through the gutter because a coupling is not inside either layer. The only edge in the whole notation"),
        ("relationship",   "dropped",  "⛔ F AT LAYER GRAIN, AND IT IS EXACT IN THE BPMN AND ABSENT HERE. Its far end is a lane in ANOTHER document, and a drawing can only join two things on the page. The same wall `import` hits"),
        ("source",         "dropped",  "⛔ the near end of that edge, which has nowhere to go without the far one"),
        ("target",         "dropped",  "⛔ the far end: a QName into an imported document, and no SVG shows a second document"),
    ];
    let mut undecided: Vec<&str> = Vec::new();
    for k in bpmn_kinds_seen.iter() {
        if !fate.iter().any(|f| f.0 == k) { undecided.push(k); }
    }
    assert!(
        undecided.is_empty(),
        "the BPMN carries an element kind and this stage has never said what it does with it, so \
         it can be dropped in silence exactly as the cover was: {undecided:?}"
    );
    let stale: Vec<&str> = fate
        .iter()
        .map(|f| f.0)
        .filter(|k| !bpmn_kinds_seen.iter().any(|s| s == k))
        .collect();
    assert!(
        stale.is_empty(),
        "this stage declares a fate for an element no BPMN document contains, so the roster is \
         describing a pipeline that no longer exists: {stale:?}"
    );
    // ------------------------------------------------------------------
    // ⛔⛔⛔ AND THE FATE ROSTER'S OWN BLIND SPOT, WHICH IS THE ONE IT WAS BUILT TO CATCH ONE
    //    LEVEL UP. It is keyed by ELEMENT KIND, and `documentation` is not a kind of fact: it is
    //    an annotation BPMN admits on any base element, so it carries as many facts here as the
    //    roster below has rows, and that number has grown three times since. One fate row said
    //    `geometry, the rank`, which was true of 51 uses out of 88, and the other 37 fell off the
    //    page with `20 kinds, 20 fates, 0 undecided` printing underneath.
    //
    // ⭐⭐ SO THE USES GET THEIR OWN ROSTER, AND EACH IS COUNTED IN BOTH ARTIFACTS. It is the
    //    repair for every blind count of this shape: the population is right and the
    //    ATTRIBUTION is not.
    // ------------------------------------------------------------------
    let uses: &[(&str, &str, &str)] = &[
        ("rank ",                  "drawn",   "a label on the lane and `data-rank` on its group"),
        ("scope: ",                "unseen",  "⛔ how much of the system the stack holds, on the laneSet"),
        ("coupling search: ",      "unseen",  "⛔ whether anybody looked for a dependence. An absent line is not independence, and this is the sentence that says so"),
        ("filed under: ",          "unseen",  "⛔ the instrument the composition is filed under"),
        ("an observed dependence", "unseen",  "⛔ what a dotted arrow between two lanes MEANS, and that it is not a supply edge"),
        ("pm:Induction:",          "unseen",  "⛔ that a group is a COVER and not a partition, which is the only thing separating it from a lane"),
        ("pm:Stack of",            "unseen",  "provenance: which filing this came from"),
        ("a composed layer and",   "unseen",  "the relationship's own gloss, and it is dropped with the relationship"),
        ("notation position: ",    "unseen",  "⛔ the node in the filer's OWN process notation that this operation is filed against, which is the whole BPMN interface and is the one sentence here pointing OUT of the model"),
        // ⛔⛔ AND A NEEDLE CAN MATCH A SIBLING AND BE DECLARED FOR IT. `a composed layer and` is
        //   the descent's gloss; the attribution's reads `a composed layer, and`. One matches 17
        //   sentences, `b > 0` passes, and the other 8 are unclaimed. ⭐ A one-directional roster
        //   cannot see that, because the arm it has is satisfied by the sibling that DID match.
        ("a composed layer, and a layer of another document",
                                   "unseen",  "⛔ the attribution relationship's gloss: which composed layer an overlap sits between, and the other document's layer. Dropped with the relationship, for the same reason"),
        // ⚠️ AND THE NEEDLE IS THE EMITTER'S LITERAL, NEVER THE MODEL'S VALUE. This one sentence
        //   is emitted once per graph and its opening words come from `diagrams/graphs.sqlc`, so
        //   a needle taken from the layer graph's wording would leave a fourth graph's sentence
        //   unclaimed the day one is added. The semicolon clause is the emitter's own.
        ("; a cycle here is ",     "unseen",  "⛔ what a cycle MEANS in the graph this document draws, and the rule that judges one, which is the sentence separating a misfiled partition from a conversion that is required to close"),
        // ⭐⭐⭐ THE ONLY USE ON THIS ROSTER THAT IS ABOUT WHAT COULD CONTRADICT THE DRAWING
        //   RATHER THAN ABOUT WHAT IT SHOWS. Every other sentence here states a filed fact; this
        //   one states how many of this repository's rules can speak about that layer, so the
        //   picture carries its own refutability. ⛔ It is `drawn` and the `b == v` arm holds it
        //   to one mark per fact, because a coverage number that reaches half the boxes is worse
        //   than one that reaches none: a reader compares what is on the page.
        ("refutable by ",          "drawn",   "⭐ how many rules can say anything about this layer, and how many of them say no. The count is ink and the THRESHOLD is not: `rank/layer_cover.sqlc` refuses to name an N below which a layer is under-checked, so a shaded band would be this stage asserting what the relation declines to"),
    ];
    // ⛔⛔⛔ COUNT THE FACT, NOT THE SUBSTRING, AND THIS ROSTER DID THE SECOND WHILE SAYING THE
    //   FIRST. `bpmn_all.matches("rank ")` returned 153 over 51 lanes, because the sentence a
    //   lane carries says the word three times, and the summary underneath called that number
    //   *documentation facts*. The skill's own rule, one line long: COUNT THE ARTIFACT AS WHAT
    //   IT IS. A `documentation` element is one fact whatever its prose repeats, so parse the
    //   elements and attribute each body once.
    // ⚠️ It is also why a raw scan is unsafe here at all: every SVG carries a provenance comment
    //   that quotes the markup it explains, which is how this file once counted 66 lanes.
    let element_bodies = |src: &str, tag: &str| -> Vec<String> {
        let (mut out, mut rest) = (Vec::new(), src);
        let open = format!("<{tag}");
        while let Some(i) = rest.find(&open) {
            rest = &rest[i + open.len()..];
            // ⛔ `<text` must not match `<textAnnotation`: the next character decides whether
            //   this is the tag or a longer name that starts with it.
            if !rest.starts_with('>') && !rest.starts_with(' ') {
                continue;
            }
            let Some(gt) = rest.find('>') else { break };
            rest = &rest[gt + 1..];
            let Some(end) = rest.find(&format!("</{tag}>")) else { break };
            out.push(rest[..end].to_string());
            rest = &rest[end..];
        }
        out
    };
    let bpmn_facts: Vec<String> = files
        .iter()
        .filter_map(|p| fs::read_to_string(p).ok())
        .flat_map(|d| element_bodies(&d, "documentation"))
        .collect();
    let svg_facts: Vec<String> = files
        .iter()
        .filter_map(|p| fs::read_to_string(drawing_of(p)).ok())
        .flat_map(|d| element_bodies(&d, "text"))
        .collect();
    // ⭐⭐⭐ AND THE ROSTER IS CLOSED IN BOTH DIRECTIONS NOW, WHICH IS THE HALF THAT WAS MISSING.
    //    `b > 0` catches a use nothing carries. Nothing caught a documentation body no use
    //    DECLARES, so a seventh use could be added to the emitter and fall off this page in
    //    silence, which is the exact defect this roster exists to have caught one level up.
    //    The element-kind roster above has both arms; this one now does too.
    let attributed = |body: &str| -> Vec<&str> {
        uses.iter().map(|u| u.0).filter(|n| body.contains(n)).collect()
    };
    let mut unclaimed = Vec::new();
    let mut ambiguous = Vec::new();
    for body in &bpmn_facts {
        match attributed(body).len() {
            1 => {}
            0 => unclaimed.push(body.chars().take(70).collect::<String>()),
            _ => ambiguous.push(body.chars().take(70).collect::<String>()),
        }
    }
    assert!(
        unclaimed.is_empty(),
        "a `documentation` element is in the BPMN and no use on this roster claims it, so its \
         fate is undeclared and it can fall off the page exactly as 71 facts once did: {unclaimed:?}"
    );
    assert!(
        ambiguous.is_empty(),
        "a `documentation` body matches two uses on this roster, so the attribution is a guess \
         and every count under it is of something nobody can name: {ambiguous:?}"
    );
    println!("\nWHAT `documentation` CARRIES, USE BY USE, BECAUSE THE KIND CANNOT ANSWER");
    println!("   {} declared uses of one element kind, which is why a fate per KIND cannot answer",
             uses.len());
    let (mut seen_total, mut unseen_total) = (0usize, 0usize);
    for (needle, want, why) in uses {
        let b = bpmn_facts.iter().filter(|f| f.contains(needle)).count();
        let v = svg_facts.iter().filter(|f| f.contains(needle)).count();
        assert!(b > 0, "no document carries `{needle}`, so its fate row describes nothing");
        assert_eq!(
            *want == "drawn", v > 0,
            "`{needle}` is filed as `{want}` and the SVG carries it {v} times: a documentation use \
             either reaches the page or is declared not to, and this row says the wrong one"
        );
        // ⛔⛔ ONCE PER FACT, NOT MERELY AT ALL. `v > 0` above is satisfied by ONE label
        //   surviving out of 88, which is exactly what a partial loss looks like: the layer
        //   graph's ranks arrive through a join in `rank/graph_nodes.sqlc`, and a join that
        //   quietly stopped matching would drop 37 of them and leave this row still true.
        assert!(
            *want != "drawn" || b == v,
            "`{needle}` is filed as drawn: the BPMN carries it {b} times and the SVG {v}. A fact \
             declared drawn owes a mark per fact, and a count that only has to be nonzero cannot \
             tell a whole use from the one member of it that survived"
        );
        if *want == "drawn" { seen_total += b } else { unseen_total += b }
        println!("   {:<9} {:<24} bpmn {b:>3}   svg {v:>3}   {}", want, needle.trim(), why);
    }
    assert_eq!(
        seen_total + unseen_total,
        bpmn_facts.len(),
        "the uses do not partition the documentation elements, so the two totals below are \
         about a different population than the one on disk"
    );
    // ⛔⛔⛔ AND THIS SUMMARY IS COMPUTED, BECAUSE THE HARDCODED ONE WAS FALSE WITHIN THE HOUR. It
    //   read *`textAnnotation` is the element that would fix this and it is withheld*, written
    //   while that was true and left standing after the element was spent and the notes drawn.
    //   A claim in prose is ungoverned; that is the finding this whole pass is about, and it
    //   reappeared inside the paragraph reporting it.
    println!("   ⛔ {unseen_total} documentation facts are in the BPMN and not on the page, \
              against {seen_total} that are.");
    println!("      That is not the whole story: a `documentation` is for the TOOL, attached");
    println!("      to the element it is about. {svg_notes} of them are ALSO drawn as \
              `textAnnotation` notes, which");
    println!("      is the carrier for the READER, and the four chosen are the four places the \
              notation's");
    println!("      own default reading is wrong: a pool reads as the system, an absent line as \
              independence,");
    println!("      a dotted arrow as flow, a dashed box as a container.");

    let dropped: Vec<&(&str, &str, &str)> = fate.iter().filter(|f| f.1 == "dropped").collect();
    println!("\nWHAT THE SVG DOES WITH EVERY ELEMENT THE BPMN FILED");
    for want in ["glyph", "geometry", "dropped"] {
        let n = fate.iter().filter(|f| f.1 == want).count();
        println!("   {want:<9} {n:>2}");
    }
    println!("   {} element kinds in the BPMN, {} with a fate, 0 undecided",
             bpmn_kinds_seen.len(), fate.len());
    for d in &dropped {
        println!("   ⛔ {:<16} {}", d.0, d.2);
    }
    println!("   ⭐ `geometry` is not a loss: a laneSet IS the arrangement of its lanes, so it is");
    println!("      carried by position. `dropped` is a finding and owes what went missing.");
    println!("   ⛔⛔ AND EVERY DROPPED ROW IS THE SAME WALL: a cross-document reference. A drawing");
    println!("      joins two things ON THE PAGE, and the far end is in another file. So the two");
    println!("      stages now lose DIFFERENT things: the BPMN carries F at layer grain exactly");
    println!("      and cannot draw it; the SVG draws what it has and cannot leave the page.");

    println!("\nAll checks passed.");
    Ok(())
}
