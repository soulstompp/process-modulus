//! ⭐⭐⭐ EVERY STATE A DOCUMENT CAN BE IN, AT EVERY PLACE THE GRAMMAR LETS IT BE, WITH ONE VERDICT.
//!
//! A document is in one state at every element it reaches: which arm of a choice it took (a value,
//! an absence, a derivation), which member of an enumeration it named, the reason it gave, the
//! identity it named, that it left an optional element out, or that it stated a plain value. The
//! universe of those states is generated from both schemas, never listed: every element path from
//! every root, cut where a type repeats, because the grammar is recursive (an absence carries a
//! provenance whose standing may itself be absent). A path is its own key. Keying by anything
//! shorter merges places that mean different things, and every gap this file has ever had was one
//! such merge, or a hand list that missed a place.
//!
//! Every state gets exactly one verdict:
//!
//!   handled by    a relation under `assets/sqlc/` that reads the column the state lands in
//!   incoherent    the grammar admits it and it means nothing there; no document files it, and the
//!                 argument is the part a reader is entitled to disagree with
//!   not stored    ingest keeps no column for the element; checked against ingest itself
//!
//! and four are given rather than declared: a path past a cycle has the states of the place its
//! type first opened; a state under a root ingest does not load is not loaded, per
//! `scope/documents_on_disk.sqlc`; a derivation's identity takes its verdict from
//! `identities/roster.sqlc`; and a choice's arm, or an optional complex element left out, is
//! stated through what it holds. How many documents file each state is printed and never required:
//! that is a fact about the corpus, and what the model owes a state is a verdict.

use std::collections::{BTreeMap, BTreeSet};
use std::fs;


/// Every document in both directories, with the local name of its root element.
///
/// ⛔ Read from the directories, never listed. A hand list here once held sixteen of
/// twenty-three documents: `contrato-empresarial`, four composition fixtures and both documents
/// rooted at `dependence` and `run` were never walked, so every state they file was checked by
/// nothing, and a document added later would have been unwalked the same way.
fn documents() -> Vec<(String, String)> {
    let mut docs = Vec::new();
    for dir in ["corpus", "fixtures"] {
        let path = format!("{}/assets/{dir}", env!("CARGO_MANIFEST_DIR"));
        let mut names: Vec<String> = fs::read_dir(&path)
            .unwrap_or_else(|e| panic!("{path}: {e}"))
            .filter_map(|e| e.ok()?.file_name().into_string().ok())
            .filter(|n| n.ends_with(".xml"))
            .collect();
        names.sort();
        for n in names {
            let rel = format!("{dir}/{n}");
            let root = root_of(&read(&rel));
            docs.push((rel, root));
        }
    }
    docs
}

/// The local name of a document's root element.
fn root_of(xml: &str) -> String {
    let mut rd = quick_xml::Reader::from_str(xml);
    loop {
        match rd.read_event() {
            Ok(quick_xml::events::Event::Start(e)) | Ok(quick_xml::events::Event::Empty(e)) => {
                return String::from_utf8_lossy(e.local_name().as_ref()).into_owned();
            }
            Ok(quick_xml::events::Event::Eof) => panic!("a document with no root element"),
            Err(e) => panic!("{e}"),
            _ => {}
        }
    }
}

fn read(rel: &str) -> String {
    let path = format!("{}/assets/{rel}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

/// The two schemas, read as text. ⚠️ Not `read()` above: that one is rooted at `assets/`.
fn schema(name: &str) -> String {
    let path = format!("{}/schema/{name}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

/// Both schemas, as one text to search for a named type.
fn schemas() -> String {
    schema("process-modulus.xsd") + &schema("assertion.xsd")
}

/// The text of the top-level type `kind` (`complexType` or `simpleType`) named `name`.
fn type_body<'a>(src: &'a str, kind: &str, name: &str) -> &'a str {
    let open = format!(r#"<xs:{kind} name="{name}""#);
    let at = src.find(&open).unwrap_or_else(|| panic!("no {kind} named {name}"));
    let end = src[at..]
        .find(&format!("</xs:{kind}>"))
        .unwrap_or_else(|| panic!("{kind} {name} is not closed"));
    &src[at..at + end]
}

/// The type of the element named `element` inside a type's text, without its namespace prefix.
fn element_type(body: &str, element: &str) -> String {
    let open = format!(r#"<xs:element name="{element}""#);
    let at = body.find(&open).unwrap_or_else(|| panic!("no element {element}"));
    let rest = &body[at..];
    let t = rest.find("type=\"").expect("an element with a type") + 6;
    let typed = &rest[t..t + rest[t..].find('"').unwrap()];
    typed.split(':').next_back().unwrap().to_string()
}

// ---------------------------------------------------------------------------
// ⭐⭐⭐ A DERIVATION IS THE WRAPPER'S THIRD ARM, AND ITS CELLS ARE THE IDENTITY CATALOGUE'S.
//
// A figure filed as a derivation names the identity that computes it, and a stated claim may say
// the same of its edge or of what would narrow it. So a derivation cell is (identity, position,
// element): the element is the position itself for a figure, and `claim/boundOrigin` or
// `claim/narrowsWhen` for a claim's edge or narrowing, whose position is the claim's own. The
// schemas give a figure's cells per wrapper. A claim's two arms are one type wherever a claim
// sits, so their cells are each claim position times the identities that compute it, plus the two
// sibling origins for an edge. `identities/roster.sqlc` is that expansion as rows, held to the
// schemas in both directions below, and every row names the relation that handles a filing there.
// Whether a document files a cell is printed and not required: it is a fact about the corpus, and
// what the model owes a cell is a relation that handles it.
// ---------------------------------------------------------------------------

/// The two identities that name a bound's author rather than compute the claim, each pointing at a
/// sibling element the claim's holder declares: (identity, holder type, the sibling element, the
/// claim's element in that type). They are admitted for a claim's `boundOrigin` only.
const SIBLINGS: &[(&str, &str, &str, &str)] = &[
    ("amountOrigin", "Nameplate", "amountOrigin", "amount"),
    ("quantumOrigin", "LumpyQuantum", "origin", "size"),
];

/// One row of `identities/roster.sqlc`.
struct Cell {
    identity: String,
    owns: String,
    element: String,
    table: String,
    column: String,
    handled_by: String,
}

/// The roster's rows, read from its `VALUES` list.
fn roster() -> Vec<Cell> {
    let path = format!("{}/assets/sqlc/identities/roster.sqlc", env!("CARGO_MANIFEST_DIR"));
    let src = fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"));
    let cells: Vec<Cell> = src
        .lines()
        .map(str::trim)
        .filter(|l| l.starts_with("('"))
        .map(|l| {
            let row = l.trim_end_matches(',').trim_start_matches('(').trim_end_matches(')');
            let f: Vec<&str> = row.split(',').map(str::trim).collect();
            assert_eq!(f.len(), 8, "{path}: a row that is not eight columns: {l}");
            assert_ne!(f[7], "NULL", "{path}: a cell that names no relation handling it: {l}");
            let text = |v: &str| v.trim_matches('\'').to_string();
            Cell {
                identity: text(f[0]),
                owns: text(f[1]),
                element: text(f[2]),
                table: text(f[3]),
                column: text(f[4]),
                handled_by: text(f[7]),
            }
        })
        .collect();
    assert!(!cells.is_empty(), "{path}: no rows read, so every comparison below proves nothing");
    cells
}

/// The name of the top-level complexType enclosing position `i`. Every named type in both schemas
/// is top level.
fn enclosing_type(src: &str, i: usize) -> &str {
    let d = src[..i].rfind(r#"<xs:complexType name=""#).expect("an enclosing complexType") + 22;
    &src[d..d + src[d..].find('"').unwrap()]
}

/// Every element typed `type_ref` in either schema: the schema's prefix, where it sits, its name.
fn elements_typed<'a>(files: &'a [(&str, String)], type_ref: &str) -> Vec<(&'a str, usize, &'a str)> {
    let mut found = Vec::new();
    for (prefix, src) in files {
        let open = r#"<xs:element name=""#;
        for (i, _) in src.match_indices(open) {
            let rest = &src[i + open.len()..];
            let name = &rest[..rest.find('"').unwrap()];
            let tag = &rest[..rest.find('>').unwrap()];
            if tag.contains(&format!(r#"type="{type_ref}""#)) {
                found.push((*prefix, i, name));
            }
        }
    }
    found
}

/// The values an enumeration in a type's text admits.
fn enumerations(body: &str) -> Vec<String> {
    body.match_indices(r#"<xs:enumeration value=""#)
        .map(|(j, _)| {
            let v = &body[j + 23..];
            v[..v.find('"').unwrap()].to_string()
        })
        .collect()
}

/// The schema prefix that declares a top-level complexType.
fn prefix_of<'a>(files: &'a [(&str, String)], name: &str) -> &'a str {
    files
        .iter()
        .find(|(_, src)| src.contains(&format!(r#"<xs:complexType name="{name}""#)))
        .map(|(p, _)| *p)
        .unwrap_or_else(|| panic!("no complexType named {name}"))
}

/// Every (identity, position, element) the schemas admit.
fn admitted_derivations() -> BTreeSet<(String, String, String)> {
    let files = [("pm", schema("process-modulus.xsd")), ("asrt", schema("assertion.xsd"))];
    let all = schemas();
    let mut cells = BTreeSet::new();
    // The positions each identity computes where the wrapper can also hold a stated claim.
    let mut computes: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    // A claim's own wrappers with a derivation arm: the element, and the identities admitted.
    let mut claim_arms: Vec<(String, Vec<String>)> = Vec::new();

    for (_, src) in &files {
        for (i, _) in src.match_indices(r#"<xs:element name="derivation""#) {
            let wrapper = enclosing_type(src, i);
            let restriction = element_type(type_body(src, "complexType", wrapper), "derivation");
            let ids = enumerations(type_body(&all, "complexType", &restriction));
            assert!(!ids.is_empty(), "{restriction} admits no identity");
            let holds_a_claim =
                type_body(&all, "complexType", wrapper).contains(r#"<xs:element name="claim""#);
            for (prefix, at, element) in elements_typed(&files, &format!("pm:{wrapper}")) {
                let src_of = &files.iter().find(|(p, _)| *p == prefix).unwrap().1;
                let holder_type = enclosing_type(src_of, at);
                if holder_type == "Claim" {
                    claim_arms.push((format!("{prefix}:claim/{prefix}:{element}"), ids.clone()));
                    continue;
                }
                let holders: BTreeSet<&str> = elements_typed(&files, &format!("{prefix}:{holder_type}"))
                    .into_iter()
                    .map(|(_, _, n)| n)
                    .collect();
                assert_eq!(
                    holders.len(),
                    1,
                    "{prefix}:{holder_type} is the type of {holders:?}, so the position of its \
                     `{element}` has no single spelling"
                );
                let holder = holders.into_iter().next().unwrap();
                let owns = format!("{prefix}:{holder}/{prefix}:{element}");
                for id in &ids {
                    cells.insert((id.clone(), owns.clone(), owns.clone()));
                    if holds_a_claim {
                        computes.entry(id.clone()).or_default().insert(owns.clone());
                    }
                }
            }
        }
    }

    let mut sibling_at: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    for (id, holder_type, sibling, claim_element) in SIBLINGS {
        let body = type_body(&all, "complexType", holder_type);
        for e in [sibling, claim_element] {
            assert!(
                body.contains(&format!(r#"<xs:element name="{e}""#)),
                "{holder_type} declares no `{e}`, so `{id}` points at nothing"
            );
        }
        let prefix = prefix_of(&files, holder_type);
        for (_, _, name) in elements_typed(&files, &format!("{prefix}:{holder_type}")) {
            sibling_at
                .entry(id.to_string())
                .or_default()
                .insert(format!("{prefix}:{name}/{prefix}:{claim_element}"));
        }
    }

    assert!(!claim_arms.is_empty(), "no claim wrapper has a derivation arm, so the arms below prove nothing");
    for (element, ids) in &claim_arms {
        let is_edge = element.ends_with(":boundOrigin");
        let admitted: BTreeSet<&str> = ids.iter().map(String::as_str).collect();
        let owed: BTreeSet<&str> = computes
            .keys()
            .map(String::as_str)
            .chain(SIBLINGS.iter().filter(|_| is_edge).map(|(id, ..)| *id))
            .collect();
        assert_eq!(
            admitted, owed,
            "{element} admits a different set of identities from the ones that compute a claim's \
             position{}: its derivation type and the positions have drifted apart",
            if is_edge { ", with the sibling origins" } else { "" }
        );
        for id in ids {
            let positions = computes.get(id).or_else(|| sibling_at.get(id)).unwrap();
            for owns in positions {
                cells.insert((id.clone(), owns.clone(), element.clone()));
            }
        }
    }
    cells
}

/// ⭐⭐ THE ROSTER IS THE SCHEMAS' DERIVATION ARMS, BOTH WAYS. A cell the schemas admit with no
/// roster row is a derivation nothing here knows how to handle; a roster row the schemas do not
/// admit is a derivation nobody can file.
#[test]
fn the_identity_roster_is_the_schemas_derivation_arms() {
    let rows = roster();
    let listed: BTreeSet<(String, String, String)> = rows
        .iter()
        .map(|c| (c.identity.clone(), c.owns.clone(), c.element.clone()))
        .collect();
    assert_eq!(listed.len(), rows.len(), "identities/roster.sqlc lists a cell twice");
    let admitted = admitted_derivations();
    let missing: Vec<_> = admitted.difference(&listed).collect();
    let stray: Vec<_> = listed.difference(&admitted).collect();
    assert!(
        missing.is_empty() && stray.is_empty(),
        "identities/roster.sqlc and the schemas' derivation arms disagree.\n  admitted and not \
         listed: {missing:?}\n  listed and not admitted: {stray:?}"
    );
}

/// The lines of a statement that are SQL, without the `#` argument or the `--` provenance.
fn code(src: &str) -> String {
    src.lines()
        .filter(|l| {
            let t = l.trim_start();
            !t.starts_with('#') && !t.starts_with("--")
        })
        .collect::<Vec<_>>()
        .join("\n")
}

/// Whether `word` occurs in `text` with no identifier character on either side.
fn has_word(text: &str, word: &str) -> bool {
    let ident = |c: char| c.is_ascii_alphanumeric() || c == '_';
    text.match_indices(word).any(|(i, _)| {
        !text[..i].chars().next_back().is_some_and(ident)
            && !text[i + word.len()..].chars().next().is_some_and(ident)
    })
}

/// Every statement under `assets/sqlc/` that `rel` composes, itself included: every `.sqlc` path its
/// SQL lines name, whether in `:compose`, in `:union` or as a slot's filling, followed down.
fn closure(rel: &str) -> BTreeSet<String> {
    let mut seen = BTreeSet::new();
    let mut todo = vec![format!("{rel}.sqlc")];
    while let Some(p) = todo.pop() {
        if !seen.insert(p.clone()) {
            continue;
        }
        let path = format!("{}/assets/sqlc/{p}", env!("CARGO_MANIFEST_DIR"));
        let src = fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"));
        let sql = code(&src);
        for (i, _) in sql.match_indices(".sqlc") {
            let start = sql[..i]
                .rfind(|c: char| !(c.is_ascii_alphanumeric() || matches!(c, '_' | '/' | '-')))
                .map_or(0, |j| j + 1);
            todo.push(sql[start..i + 5].to_string());
        }
    }
    seen
}

// ---------------------------------------------------------------------------
// ⭐⭐⭐ THE UNIVERSE, GENERATED: EVERY STATE A DOCUMENT CAN BE IN, AT EVERY PATH THE GRAMMAR ALLOWS.
//
// A document is in one state at every element the grammar lets it reach: which arm of a choice it
// took (the value arm included), which member of an enumeration it named, that it omitted an
// optional element, or, for a plain value, that it stated one. The grammar is recursive (an
// absence carries a provenance whose standing may be absent, which carries a provenance), so the
// paths are cut where a type repeats, and a document nested deeper is folded back onto the first
// occurrence. A filing embedded in a composition is the same filing, so its paths are the root's.
// ---------------------------------------------------------------------------

/// A schema element read as a tree: its local tag name, its attributes and its children.
#[derive(Debug)]
struct Xs {
    tag: String,
    attrs: Vec<(String, String)>,
    kids: Vec<Xs>,
}

impl Xs {
    fn attr(&self, k: &str) -> Option<&str> {
        self.attrs.iter().find(|(a, _)| a == k).map(|(_, v)| v.as_str())
    }
}

fn xs_node(e: &quick_xml::events::BytesStart) -> Xs {
    Xs {
        tag: String::from_utf8_lossy(e.local_name().as_ref()).into_owned(),
        attrs: e
            .attributes()
            .filter_map(Result::ok)
            .map(|a| {
                (
                    String::from_utf8_lossy(a.key.as_ref()).into_owned(),
                    String::from_utf8_lossy(&a.value).into_owned(),
                )
            })
            .collect(),
        kids: Vec::new(),
    }
}

/// A schema's `xs:schema` element, as a tree.
fn parse_schema(src: &str) -> Xs {
    use quick_xml::events::Event;
    let mut rd = quick_xml::Reader::from_str(src);
    let mut stack = vec![Xs { tag: String::new(), attrs: Vec::new(), kids: Vec::new() }];
    loop {
        match rd.read_event().unwrap_or_else(|e| panic!("{e}")) {
            Event::Start(e) => stack.push(xs_node(&e)),
            Event::Empty(e) => {
                let n = xs_node(&e);
                stack.last_mut().unwrap().kids.push(n);
            }
            Event::End(_) => {
                let n = stack.pop().unwrap();
                stack.last_mut().unwrap().kids.push(n);
            }
            Event::Eof => break,
            _ => {}
        }
    }
    stack.pop().unwrap().kids.into_iter().find(|n| n.tag == "schema").expect("an xs:schema")
}

/// A type as the schemas name it: the prefix of the schema that declares it, and its name. An
/// anonymous type is named by the path of the element that declares it.
type TypeKey = (String, String);

/// Both schemas' top-level declarations, by prefix and name.
struct Grammar {
    complex: BTreeMap<TypeKey, Xs>,
    simple: BTreeMap<TypeKey, Xs>,
    roots: BTreeMap<TypeKey, Xs>,
}

fn grammar() -> Grammar {
    let mut g = Grammar { complex: BTreeMap::new(), simple: BTreeMap::new(), roots: BTreeMap::new() };
    for (prefix, file) in [("pm", "process-modulus.xsd"), ("asrt", "assertion.xsd")] {
        for n in parse_schema(&schema(file)).kids {
            let key = (prefix.to_string(), n.attr("name").unwrap_or_default().to_string());
            match n.tag.as_str() {
                "complexType" => g.complex.insert(key, n),
                "simpleType" => g.simple.insert(key, n),
                "element" => g.roots.insert(key, n),
                _ => None,
            };
        }
    }
    g
}

fn split_ref(r: &str) -> TypeKey {
    let (p, n) = r.split_once(':').unwrap_or(("xs", r));
    (p.to_string(), n.to_string())
}

/// Every `xs:enumeration` value under a node.
fn enumerated(n: &Xs) -> Vec<String> {
    let mut out = Vec::new();
    if n.tag == "enumeration" {
        out.push(n.attr("value").unwrap().to_string());
    }
    for k in &n.kids {
        out.extend(enumerated(k));
    }
    out
}

/// What an element holds: a simple value, with its enumeration if it has one, or a complex type.
enum Shape<'a> {
    Simple(Vec<String>),
    Complex(&'a Xs, TypeKey),
}

fn shape<'a>(g: &'a Grammar, prefix: &str, el: &'a Xs, path: &str) -> Shape<'a> {
    if let Some(t) = el.attr("type") {
        let key = split_ref(t);
        if key.0 == "xs" {
            return Shape::Simple(Vec::new());
        }
        if let Some(ct) = g.complex.get(&key) {
            return Shape::Complex(ct, key);
        }
        let st = g.simple.get(&key).unwrap_or_else(|| panic!("{t} is declared in neither schema"));
        return Shape::Simple(enumerated(st));
    }
    if let Some(ct) = el.kids.iter().find(|k| k.tag == "complexType") {
        return Shape::Complex(ct, (prefix.to_string(), format!("anonymous at {path}")));
    }
    Shape::Simple(el.kids.iter().find(|k| k.tag == "simpleType").map(enumerated).unwrap_or_default())
}

/// A type's content, flattened into the choices it makes and the elements it declares.
enum Particle<'a> {
    Choice(Vec<&'a str>),
    Element(&'a Xs),
}

fn particles<'a>(n: &'a Xs, out: &mut Vec<Particle<'a>>) {
    for k in &n.kids {
        match k.tag.as_str() {
            "sequence" => particles(k, out),
            "choice" => {
                let arms: Vec<&str> = k
                    .kids
                    .iter()
                    .filter(|a| a.tag != "annotation")
                    .map(|a| {
                        assert_eq!(a.tag, "element", "a choice arm that is not an element");
                        a.attr("name").expect("a named arm")
                    })
                    .collect();
                out.push(Particle::Choice(arms));
                particles(k, out);
            }
            "element" => out.push(Particle::Element(k)),
            "complexContent" | "simpleContent" | "group" | "all" | "any" => {
                panic!("the schemas use `{}`, which this walk does not read", k.tag)
            }
            _ => {}
        }
    }
}

/// The states a document can be in, keyed by full element path, with what reading one needs.
#[derive(Default)]
struct Universe {
    /// (path, state): `choice:ARM` at the holder, `value` or `value:MEMBER` at a simple element,
    /// `omitted` at an optional one, `cycle` where a type repeats.
    cells: BTreeSet<(String, String)>,
    /// Every element path, whether or not a state sits at it.
    paths: BTreeSet<String>,
    /// The optional children of each path, which a document omits by not writing them.
    optional: BTreeMap<String, Vec<String>>,
    /// Where a type repeats, the path at which it was first opened.
    cycles: BTreeMap<String, String>,
    /// Where a root is embedded by reference, the root's own path.
    embeds: BTreeMap<String, String>,
}

fn walk_type(g: &Grammar, u: &mut Universe, ct: &Xs, prefix: &str, path: &str, open: &mut Vec<(TypeKey, String)>) {
    let mut ps = Vec::new();
    particles(ct, &mut ps);
    for p in ps {
        let el = match p {
            Particle::Choice(arms) => {
                for a in arms {
                    u.cells.insert((path.to_string(), format!("choice:{a}")));
                }
                continue;
            }
            Particle::Element(el) => el,
        };
        if let Some(r) = el.attr("ref") {
            let key = split_ref(r);
            assert!(g.roots.contains_key(&key), "{r} refers to no root");
            u.embeds.insert(format!("{path}/{}:{}", key.0, key.1), format!("{}:{}", key.0, key.1));
            continue;
        }
        let name = format!("{prefix}:{}", el.attr("name").expect("a named element"));
        let here = format!("{path}/{name}");
        u.paths.insert(here.clone());
        if el.attr("minOccurs") == Some("0") {
            u.cells.insert((here.clone(), "omitted".into()));
            u.optional.entry(path.to_string()).or_default().push(name.clone());
        }
        match shape(g, prefix, el, &here) {
            Shape::Simple(members) if members.is_empty() => {
                u.cells.insert((here, "value".into()));
            }
            Shape::Simple(members) => {
                for m in members {
                    u.cells.insert((here.clone(), format!("value:{m}")));
                }
            }
            Shape::Complex(inner, key) => {
                if let Some((_, first)) = open.iter().find(|(k, _)| *k == key) {
                    u.cells.insert((here.clone(), "cycle".into()));
                    u.cycles.insert(here, first.clone());
                } else {
                    open.push((key.clone(), here.clone()));
                    walk_type(g, u, inner, &key.0, &here, open);
                    open.pop();
                }
            }
        }
    }
}

/// Every state both schemas admit, from each root.
fn universe() -> Universe {
    let g = grammar();
    let mut u = Universe::default();
    for ((prefix, name), el) in &g.roots {
        let root = format!("{prefix}:{name}");
        u.paths.insert(root.clone());
        match shape(&g, prefix, el, &root) {
            Shape::Complex(ct, key) => {
                let mut open = vec![(key.clone(), root.clone())];
                walk_type(&g, &mut u, ct, &key.0, &root, &mut open);
            }
            Shape::Simple(_) => panic!("a root element {root} with a simple type"),
        }
    }
    u
}

#[test]
fn the_grammar_generates_the_universe() {
    let u = universe();
    let mut by_root: BTreeMap<&str, usize> = BTreeMap::new();
    for (p, _) in &u.cells {
        *by_root.entry(p.split('/').next().unwrap()).or_default() += 1;
    }
    println!(
        "{} states over {} paths; {} cycles cut; {} embedded roots; by root {by_root:?}",
        u.cells.len(),
        u.paths.len(),
        u.cycles.len(),
        u.embeds.len()
    );
    assert!(!u.cells.is_empty());
}

/// The schema prefix a document's namespace stands for.
fn prefix_of_namespace(ns: &[u8]) -> &'static str {
    match ns {
        b"https://example.invalid/process-flow/1.0" => "pm",
        b"https://example.invalid/assertion/1.0" => "asrt",
        other => panic!("an element in a namespace neither schema declares: {}", String::from_utf8_lossy(other)),
    }
}

impl Universe {
    /// A document's element path as the universe spells it: an embedded root is the root, and a
    /// path past a cycle is folded back onto where its type was first opened.
    fn fold(&self, path: &str) -> String {
        let mut p = path.to_string();
        for (at, root) in &self.embeds {
            if let Some(rest) = p.strip_prefix(at.as_str()) {
                p = format!("{root}{rest}");
            }
        }
        while !self.paths.contains(&p) {
            let Some((cut, first)) = self
                .cycles
                .iter()
                .filter(|(cut, _)| p.starts_with(&format!("{cut}/")) || p == **cut)
                .max_by_key(|(cut, _)| cut.len())
            else {
                break;
            };
            p = format!("{first}{}", &p[cut.len()..]);
        }
        p
    }

    /// Every state every document files, counted per cell. A document element at a path the
    /// grammar does not reach, or a value outside its enumeration, fails: the documents and the
    /// schemas disagree.
    fn filings(&self) -> BTreeMap<(String, String), usize> {
        use quick_xml::events::Event;
        use quick_xml::name::ResolveResult;
        let mut filed: BTreeMap<(String, String), usize> = BTreeMap::new();
        let bump = |cell: (String, String), filed: &mut BTreeMap<(String, String), usize>| {
            *filed.entry(cell).or_default() += 1;
        };
        for (doc, _) in documents() {
            let xml = read(&doc);
            let mut rd = quick_xml::NsReader::from_str(&xml);
            // (the folded path, the children seen under it)
            let mut stack: Vec<(String, BTreeSet<String>)> = Vec::new();
            loop {
                let (ns, ev) = rd.read_resolved_event().unwrap_or_else(|e| panic!("{doc}: {e}"));
                match ev {
                    Event::Start(ref e) | Event::Empty(ref e) => {
                        let ResolveResult::Bound(ns) = ns else { panic!("{doc}: an unqualified element") };
                        let name = format!(
                            "{}:{}",
                            prefix_of_namespace(ns.as_ref()),
                            String::from_utf8_lossy(e.local_name().as_ref())
                        );
                        let raw = match stack.last() {
                            Some((parent, _)) => format!("{parent}/{name}"),
                            None => name.clone(),
                        };
                        let path = self.fold(&raw);
                        assert!(
                            self.paths.contains(&path),
                            "{doc}: `{raw}` is an element path the schemas do not reach"
                        );
                        if let Some((parent, seen)) = stack.last_mut() {
                            seen.insert(name.clone());
                            let arm = (parent.clone(), format!("choice:{}", e.local_name().as_ref().iter().map(|&b| b as char).collect::<String>()));
                            if self.cells.contains(&arm) {
                                bump(arm, &mut filed);
                            }
                        }
                        let empty = matches!(ev, Event::Empty(_));
                        stack.push((path, BTreeSet::new()));
                        if empty {
                            self.close(stack.pop().unwrap(), &mut filed, &doc);
                        }
                    }
                    Event::Text(t) => {
                        let text = String::from_utf8_lossy(&t).trim().to_string();
                        if text.is_empty() {
                            continue;
                        }
                        let (path, _) = stack.last().expect("text outside any element");
                        let member = (path.clone(), format!("value:{text}"));
                        let plain = (path.clone(), "value".to_string());
                        if self.cells.contains(&member) {
                            bump(member, &mut filed);
                        } else if self.cells.contains(&plain) {
                            bump(plain, &mut filed);
                        } else {
                            panic!("{doc}: `{text}` at {path}, which admits no such value");
                        }
                    }
                    Event::End(_) => {
                        let top = stack.pop().unwrap();
                        self.close(top, &mut filed, &doc);
                    }
                    Event::Eof => break,
                    _ => {}
                }
            }
        }
        filed
    }

    /// An element closing: every optional child it did not write is omitted.
    fn close(&self, (path, seen): (String, BTreeSet<String>), filed: &mut BTreeMap<(String, String), usize>, _doc: &str) {
        for child in self.optional.get(&path).into_iter().flatten() {
            if !seen.contains(child) {
                *filed.entry((format!("{path}/{child}"), "omitted".to_string())).or_default() += 1;
            }
        }
    }
}

#[test]
fn every_document_path_is_one_the_grammar_reaches() {
    let u = universe();
    let filed = u.filings();
    let missing: Vec<_> = filed.keys().filter(|c| !u.cells.contains(c)).collect();
    assert!(missing.is_empty(), "filed states the universe does not hold: {missing:?}");
    println!("{} cells filed at least once, {} filings", filed.len(), filed.values().sum::<usize>());
}

// ---------------------------------------------------------------------------
// ⭐⭐⭐ THE VERDICTS. A declaration is a path suffix and a state; the longest suffix that matches a
// state gives its verdict, and at equal length a named state beats `*`. ⛔ `*` covers a plain value
// and an omission and never a member of an enumeration: a member added to the schema is a new state,
// and it gets a verdict of its own or the build fails. A short suffix speaks for a shared type wherever it sits (`pm:claim/pm:low` for every
// claim); a longer one is the exception a place makes (`pm:demand/pm:amount/pm:absent/pm:reason`).
// ---------------------------------------------------------------------------

#[derive(Clone, Copy, Debug)]
enum Verdict {
    /// The grammar admits it and it means nothing at this place. No document may file it.
    Incoherent(&'static str),
    /// A relation reads it: the relation, the table, the column the state lands in.
    Handled(&'static str, &'static str, &'static str),
    /// Ingest keeps no column for it: the table its holder is ingested into, and why that is so.
    NotStored(&'static str, &'static str),
}
use Verdict::{Handled, Incoherent, NotStored};

const CLAIMS: &str = "epistemics/claims";
const ABSENCES: &str = "epistemics/filed_absences";
const DERIVATIONS: &str = "epistemics/filed_derivations";

const DECLARED: &[(&str, &str, Verdict)] = &[
    // ---- a claim, wherever it sits ----
    ("pm:claim/pm:low", "*", Handled(CLAIMS, "claim", "low")),
    ("pm:claim/pm:mostLikely", "*", Handled(CLAIMS, "claim", "mode")),
    ("pm:claim/pm:high", "*", Handled(CLAIMS, "claim", "high")),
    ("pm:claim/pm:unit", "*", Handled(CLAIMS, "claim", "unit")),
    ("pm:claim/pm:asOf", "*", Handled(CLAIMS, "claim", "as_of")),
    ("pm:claim/pm:denominator/pm:period", "*", Handled(CLAIMS, "claim", "denominator")),
    ("pm:claim/pm:denominator/pm:each", "*", Handled(CLAIMS, "claim", "denominator")),
    ("pm:claim/pm:narrowsWhen/pm:narrowing/pm:condition", "*", Handled(CLAIMS, "narrowing", "condition")),
    ("pm:claim/pm:narrowsWhen/pm:narrowing/pm:kind", "value:instrument", Handled(CLAIMS, "narrowing", "kind")),
    ("pm:claim/pm:narrowsWhen/pm:narrowing/pm:kind", "value:intervention", Handled(CLAIMS, "narrowing", "kind")),
    ("pm:claim/pm:narrowsWhen/pm:narrowing/pm:kind", "value:experiment", Handled(CLAIMS, "narrowing", "kind")),
    ("pm:claim/pm:boundOrigin/pm:origin", "value:intrinsic", Handled(CLAIMS, "bound_origin", "origin")),
    ("pm:claim/pm:boundOrigin/pm:origin", "value:contractual", Handled(CLAIMS, "bound_origin", "origin")),
    ("pm:claim/pm:boundOrigin/pm:origin", "value:policy", Handled(CLAIMS, "bound_origin", "origin")),
    ("pm:claim/pm:provenance/pm:party", "*", Handled(CLAIMS, "claim", "prov_party")),
    ("pm:claim/pm:provenance/pm:enteredBy", "*", Handled(CLAIMS, "claim", "prov_entered_by")),
    ("pm:claim/pm:provenance/pm:approvedBy", "*", Handled(CLAIMS, "claim", "prov_approved_by")),
    ("pm:claim/pm:provenance/pm:note", "*", Handled(CLAIMS, "claim", "prov_note")),
    ("pm:claim/pm:provenance/pm:standing/pm:term/pm:taxonomy", "*", Handled(CLAIMS, "claim", "prov_standing_taxonomy")),
    ("pm:claim/pm:provenance/pm:standing/pm:term/pm:value", "*", Handled(CLAIMS, "claim", "prov_standing_value")),
    // ---- an absence, wherever it sits: every `absent` element lands in the tall table ----
    ("pm:absent/pm:reason", "value:none", Handled(ABSENCES, "absence", "reason")),
    ("pm:absent/pm:reason", "value:unmeasured", Handled(ABSENCES, "absence", "reason")),
    ("pm:absent/pm:reason", "value:notApplicable", Handled(ABSENCES, "absence", "reason")),
    ("pm:absent/pm:note", "*", Handled(ABSENCES, "absence", "note")),
    ("pm:absent/pm:asOf", "*", Handled(ABSENCES, "absence", "as_of")),
    ("pm:absent/pm:provenance/pm:party", "*", Handled(ABSENCES, "absence", "prov_party")),
    ("pm:absent/pm:provenance/pm:enteredBy", "*", Handled(ABSENCES, "absence", "prov_entered_by")),
    ("pm:absent/pm:provenance/pm:approvedBy", "*", Handled(ABSENCES, "absence", "prov_approved_by")),
    ("pm:absent/pm:provenance/pm:note", "*", Handled(ABSENCES, "absence", "prov_note")),
    ("pm:absent/pm:provenance/pm:standing/pm:term/pm:taxonomy", "*", Handled(ABSENCES, "absence", "prov_standing_taxonomy")),
    ("pm:absent/pm:provenance/pm:standing/pm:term/pm:value", "*", Handled(ABSENCES, "absence", "prov_standing_value")),
    ("asrt:absent/pm:reason", "value:none", Handled(ABSENCES, "absence", "reason")),
    ("asrt:absent/pm:reason", "value:unmeasured", Handled(ABSENCES, "absence", "reason")),
    ("asrt:absent/pm:reason", "value:notApplicable", Handled(ABSENCES, "absence", "reason")),
    ("asrt:absent/pm:note", "*", Handled(ABSENCES, "absence", "note")),
    ("asrt:absent/pm:asOf", "*", Handled(ABSENCES, "absence", "as_of")),
    ("asrt:absent/pm:provenance/pm:party", "*", Handled(ABSENCES, "absence", "prov_party")),
    ("asrt:absent/pm:provenance/pm:enteredBy", "*", Handled(ABSENCES, "absence", "prov_entered_by")),
    ("asrt:absent/pm:provenance/pm:approvedBy", "*", Handled(ABSENCES, "absence", "prov_approved_by")),
    ("asrt:absent/pm:provenance/pm:note", "*", Handled(ABSENCES, "absence", "prov_note")),
    ("asrt:absent/pm:provenance/pm:standing/pm:term/pm:taxonomy", "*", Handled(ABSENCES, "absence", "prov_standing_taxonomy")),
    ("asrt:absent/pm:provenance/pm:standing/pm:term/pm:value", "*", Handled(ABSENCES, "absence", "prov_standing_value")),
    // ---- a derivation, wherever it sits ----
    ("pm:derivation/pm:note", "*", Handled(DERIVATIONS, "derivation", "note")),
    ("pm:derivation/pm:asOf", "*", Handled(DERIVATIONS, "derivation", "as_of")),
    ("pm:derivation/pm:provenance/pm:party", "*", Handled(DERIVATIONS, "derivation", "prov_party")),
    ("pm:derivation/pm:provenance/pm:enteredBy", "*", Handled(DERIVATIONS, "derivation", "prov_entered_by")),
    ("pm:derivation/pm:provenance/pm:approvedBy", "*", Handled(DERIVATIONS, "derivation", "prov_approved_by")),
    ("pm:derivation/pm:provenance/pm:note", "*", Handled(DERIVATIONS, "derivation", "prov_note")),
    ("pm:derivation/pm:provenance/pm:standing/pm:term/pm:taxonomy", "*", Handled(DERIVATIONS, "derivation", "prov_standing_taxonomy")),
    ("pm:derivation/pm:provenance/pm:standing/pm:term/pm:value", "*", Handled(DERIVATIONS, "derivation", "prov_standing_value")),
    // ---- the filing itself ----
    ("pm:processModulus/pm:notation/pm:uri", "*", Handled("composition/notations", "filing_identity", "notation")),
    ("pm:processModulus/pm:evidence/pm:attests", "value:observation", Handled("scope/every_filing", "filing", "evidence")),
    ("pm:processModulus/pm:evidence/pm:attests", "value:stipulation", Handled("scope/every_filing", "filing", "evidence")),
    ("pm:regime/pm:id", "*", Handled("composition/regimes", "regime", "id")),
    ("pm:regime/pm:jurisdiction", "*", Handled("composition/regimes", "regime", "jurisdiction")),
    ("pm:regime/pm:framework/pm:term/pm:taxonomy", "*", Handled("composition/regimes", "regime", "framework_taxonomy")),
    ("pm:regime/pm:framework/pm:term/pm:value", "*", Handled("composition/regimes", "regime", "framework_value")),
    ("pm:regime/pm:chart/pm:term/pm:taxonomy", "*", Handled("composition/regimes", "regime", "chart_taxonomy")),
    ("pm:regime/pm:chart/pm:term/pm:value", "*", Handled("composition/regimes", "regime", "chart_value")),
    ("pm:regime/pm:note", "*", NotStored("regime", "a regime's note is prose about the frame the figures were computed under, and no relation reads prose")),
    ("pm:stack/pm:scope/pm:scope/pm:extent", "value:complete", Handled("epistemics/scopes", "stack_scope", "extent")),
    ("pm:stack/pm:scope/pm:scope/pm:extent", "value:scoped", Handled("epistemics/scopes", "stack_scope", "extent")),
    ("pm:stack/pm:scope/pm:scope/pm:extent", "value:unbounded", Handled("epistemics/scopes", "stack_scope", "extent")),
    ("pm:stack/pm:scope/pm:scope/pm:basis", "*", Handled("epistemics/scopes", "stack_scope", "basis")),
    // ---- a layer ----
    ("pm:layer/pm:name", "*", Handled("layers/every_layer", "layer", "layer")),
    ("pm:supply/pm:label", "*", Handled("layers/facilities", "nameplate", "facility_label")),
    ("pm:remainder/pm:sign/pm:fit", "value:clearance", Handled("layers/filed_remainders", "layer", "sign")),
    ("pm:remainder/pm:sign/pm:fit", "value:transition", Handled("layers/filed_remainders", "layer", "sign")),
    ("pm:remainder/pm:sign/pm:fit", "value:interference", Handled("layers/filed_remainders", "layer", "sign")),
    ("pm:remainder/pm:absorber/pm:term/pm:taxonomy", "*", Handled("layers/absorber", "layer", "absorber_taxonomy")),
    ("pm:remainder/pm:absorber/pm:term/pm:value", "*", Handled("layers/absorber", "layer", "absorber_value")),
    ("pm:holder/pm:holder/pm:kind", "value:booked", Handled("entries/holders", "holder", "kind")),
    ("pm:holder/pm:holder/pm:kind", "value:counterparty", Handled("entries/holders", "holder", "kind")),
    ("pm:holder/pm:holder/pm:kind", "value:customer", Handled("entries/holders", "holder", "kind")),
    ("pm:holder/pm:holder/pm:kind", "value:people", Handled("entries/holders", "holder", "kind")),
    ("pm:holder/pm:holder/pm:kind", "value:unrealised", Handled("entries/holders", "holder", "kind")),
    ("pm:holder/pm:holder/pm:party", "*", Handled("entries/holders", "holder", "party")),
    ("pm:holder/pm:holder/pm:asOf", "*", Handled("entries/holders", "holder", "as_of")),
    ("pm:nameplate/pm:amountOrigin/pm:origin", "value:intrinsic", Handled("layers/facilities", "nameplate", "amount_origin")),
    ("pm:nameplate/pm:amountOrigin/pm:origin", "value:contractual", Handled("layers/facilities", "nameplate", "amount_origin")),
    ("pm:nameplate/pm:amountOrigin/pm:origin", "value:policy", Handled("layers/facilities", "nameplate", "amount_origin")),
    ("pm:lumpy/pm:origin", "value:intrinsic", Handled("layers/facilities", "nameplate", "quantum_origin")),
    ("pm:lumpy/pm:origin", "value:contractual", Handled("layers/facilities", "nameplate", "quantum_origin")),
    ("pm:lumpy/pm:origin", "value:policy", Handled("layers/facilities", "nameplate", "quantum_origin")),
    ("pm:quantum/pm:origin", "value:intrinsic", Handled("layers/facilities", "nameplate", "window_origin")),
    ("pm:quantum/pm:origin", "value:contractual", Handled("layers/facilities", "nameplate", "window_origin")),
    ("pm:quantum/pm:origin", "value:policy", Handled("layers/facilities", "nameplate", "window_origin")),
    ("pm:basis/pm:contributed", "value:nameplate", Handled("layers/facilities", "nameplate", "measurement_basis_contributed")),
    ("pm:basis/pm:borrowed/pm:taxonomy", "*", Handled("layers/facilities", "nameplate", "measurement_basis_taxonomy")),
    ("pm:basis/pm:borrowed/pm:value", "*", Handled("layers/facilities", "nameplate", "measurement_basis_value")),
    // ---- operations and couplings ----
    ("pm:operation/pm:label", "*", Handled("entries/operations", "operation", "label")),
    ("pm:foreignId/pm:notation", "*", Handled("entries/operations", "operation", "foreign_notation")),
    ("pm:foreignId/pm:id", "*", Handled("entries/operations", "operation", "foreign_id")),
    ("pm:draw/pm:layer", "*", Handled("entries/draws", "draw", "layer")),
    ("pm:induces/pm:layer", "*", Handled("entries/inductions", "induction", "layer")),
    ("pm:induces/pm:decidedBy", "*", Handled("entries/inductions", "induction", "decider")),
    ("pm:coupling/pm:from", "*", Handled("entries/couplings", "coupling", "from_layer")),
    ("pm:coupling/pm:to", "*", Handled("entries/couplings", "coupling", "to_layer")),
    ("pm:coupling/pm:observed", "*", Handled("entries/couplings", "coupling", "observation")),
    // ---- a composition ----
    ("asrt:composition/asrt:witness", "*", NotStored("filing", "the composer is named by the filing's provenance, which is stored; the witness token is the name across this file's documents and nothing joins on it")),
    ("asrt:composition/asrt:observedAt", "*", NotStored("filing", "no relation compares a composition's date with anything, so ingest keeps none")),
    ("asrt:provenance/pm:party", "*", Handled("scope/every_filing", "filing", "prov_party")),
    ("asrt:provenance/pm:enteredBy", "*", Handled("scope/every_filing", "filing", "prov_entered_by")),
    ("asrt:provenance/pm:approvedBy", "*", Handled("scope/every_filing", "filing", "prov_approved_by")),
    ("asrt:provenance/pm:note", "*", Handled("scope/every_filing", "filing", "prov_note")),
    ("asrt:provenance/pm:standing/pm:term/pm:taxonomy", "*", Handled("scope/every_filing", "filing", "prov_standing_taxonomy")),
    ("asrt:provenance/pm:standing/pm:term/pm:value", "*", Handled("scope/every_filing", "filing", "prov_standing_value")),
    ("asrt:regime/pm:id", "*", Handled("composition/composer_regimes", "composition_regime", "id")),
    ("asrt:regime/pm:jurisdiction", "*", Handled("composition/composer_regimes", "composition_regime", "jurisdiction")),
    ("asrt:regime/pm:framework/pm:term/pm:taxonomy", "*", Handled("composition/composer_regimes", "composition_regime", "framework_taxonomy")),
    ("asrt:regime/pm:framework/pm:term/pm:value", "*", Handled("composition/composer_regimes", "composition_regime", "framework_value")),
    ("asrt:regime/pm:chart/pm:term/pm:taxonomy", "*", Handled("composition/composer_regimes", "composition_regime", "chart_taxonomy")),
    ("asrt:regime/pm:chart/pm:term/pm:value", "*", Handled("composition/composer_regimes", "composition_regime", "chart_value")),
    ("asrt:regime/pm:note", "*", NotStored("composition_regime", "a regime's note is prose about the frame the figures were computed under, and no relation reads prose")),
    ("asrt:citation/asrt:instrument/pm:taxonomy", "*", Handled("composition/citations", "composition_citation", "taxonomy")),
    ("asrt:citation/asrt:instrument/pm:value", "*", Handled("composition/citations", "composition_citation", "instrument")),
    ("asrt:citation/asrt:clause", "*", Handled("composition/citations", "composition_citation", "clause")),
    ("asrt:citation/asrt:version", "*", Handled("composition/citations", "composition_citation", "version")),
    ("asrt:fusion/asrt:name", "*", Handled("composition/fusions", "fusion", "composed_layer")),
    ("asrt:fusion/asrt:observed", "*", Handled("composition/fusions", "fusion", "observed")),
    ("asrt:part/asrt:layer/asrt:filing/pm:notation", "*", Handled("composition/part_references", "part", "part_filing")),
    ("asrt:part/asrt:layer/asrt:filing/pm:id", "*", Handled("composition/part_references", "part", "part_layer")),
    ("asrt:part/asrt:layer/asrt:party", "*", Handled("composition/part_references", "part", "part_party")),
    ("asrt:part/asrt:layer/asrt:version", "*", Handled("composition/part_references", "part", "part_version")),
    ("asrt:part/asrt:layer/asrt:regime", "*", Handled("composition/part_references", "part", "part_regime")),
    ("asrt:part/asrt:layer/asrt:registration/pm:taxonomy", "*", Handled("composition/part_references", "part", "part_registration_taxonomy")),
    ("asrt:part/asrt:layer/asrt:registration/pm:value", "*", Handled("composition/part_references", "part", "part_registration_value")),
    ("asrt:part/asrt:factor", "omitted", Handled("composition/part_references", "part", "factor_low")),
    ("asrt:elimination/asrt:against", "value:demand", Handled("eliminations/filed", "elimination", "quantity")),
    ("asrt:elimination/asrt:against", "value:nameplate", Handled("eliminations/filed", "elimination", "quantity")),
    ("asrt:elimination/asrt:against", "value:draw", Handled("eliminations/filed", "elimination", "quantity")),
    ("asrt:elimination/asrt:observed", "*", Handled("eliminations/filed", "elimination", "reason")),
    ("asrt:between/asrt:party", "*", Handled("eliminations/between", "elimination_between", "party")),
    ("asrt:between/asrt:filing/pm:notation", "*", Handled("eliminations/between", "elimination_between", "notation")),
    ("asrt:between/asrt:filing/pm:id", "*", Handled("eliminations/between", "elimination_between", "layer")),
    ("asrt:between/asrt:version", "*", Handled("eliminations/between", "elimination_between", "version")),
    ("asrt:between/asrt:regime", "*", Handled("eliminations/between", "elimination_between", "regime")),
    ("asrt:between/asrt:registration/pm:taxonomy", "*", Handled("eliminations/between", "elimination_between", "registration_taxonomy")),
    ("asrt:between/asrt:registration/pm:value", "*", Handled("eliminations/between", "elimination_between", "registration_value")),
    // ---- ⛔ WHAT A REASON MEANS AT ONE PLACE: the absences the grammar admits and the place refuses ----
    ("pm:nameplate/pm:divisibility/pm:absent/pm:reason", "value:none", Incoherent(
        "`continuous` IS the value that says there is no quantum, so `none` is a second spelling of a \
         member the choice already has. `StatedDivisibility`'s annotation makes this argument for \
         `notApplicable` and stops one short of it",
    )),
    ("pm:claim/pm:denominator/pm:absent/pm:reason", "value:none", Incoherent(
        "⛔ \"somebody looked and there is no denominator\" is precisely what `notApplicable` says at \
         this place. Two spellings of one state is the collapse the wrapper exists to prevent",
    )),
    ("pm:processModulus/pm:evidence/pm:absent/pm:reason", "value:none", Incoherent(
        "⛔ \"somebody looked and there is nothing to report\" does not parse. A document that exists \
         was written by somebody who knew whether they were observing or stipulating, and unlike a \
         `notation` that knowledge is not external, there is no registry to be waiting on",
    )),
    ("pm:processModulus/pm:evidence/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "⛔ there is no document the question fails to reach. Every document either reports something \
         somebody saw, or it does not, and a document claiming the question is malformed is claiming \
         to be outside the only distinction that decides whether it may be quoted",
    )),
    ("pm:processModulus/pm:notation/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "⛔ a document nobody may reference cannot be composed into anything, and this model exists to \
         be composed. `none` is the state for a document with no identifier; claiming the QUESTION is \
         malformed claims the document is outside the population of things that can be cited, which \
         is a stronger thing than not having a name",
    )),
    ("pm:stack/pm:scope/pm:absent/pm:reason", "value:none", Incoherent(
        "⭐ a stack has at least one layer, so \"there is no scope\" is not a state a document can be \
         in. The three extents cover the axis and `none` would be a fourth spelling of `complete`",
    )),
    ("pm:stack/pm:scope/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "every stack has an extent. There is no filing for which the question of how much of the \
         system it holds is malformed",
    )),
    ("pm:provenance/pm:standing/pm:absent/pm:reason", "value:none", Incoherent(
        "`Provenance` gives `notApplicable` to 'an assertion nobody is standing behind in any formal \
         sense'; `none` would be a second door to it",
    )),
    ("pm:jagged/pm:measurementBasis/pm:absent/pm:reason", "value:none", Incoherent(
        "every figure is some kind of figure. A physical quantity with no valuation is \
         `notApplicable`, which `enterprise-contract` argues, and `none` would be a second door to it",
    )),
    ("pm:remainder/pm:absorber/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "a remainder filed as a claim was taken by some buffer or by none, and `Remainder` gives \
         `none` that case in as many words; `notApplicable` would be a second door to it",
    )),
    ("pm:draw/pm:quantity/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "an operation that does not draw on a layer files no `draw` for it; `notApplicable` would be \
         a second door to the omission",
    )),
    ("pm:demand/pm:patience/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "every demand survives being held for some time, zero included, which `Demand` files as \
         [0, 0, 0], or nobody knows; there is no demand the question fails to reach",
    )),
    ("pm:continuous/pm:premium/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "`premium` is asked only of a supply filed `continuous`, and `Continuity`'s scale (above 0, \
         at 0, below 0) covers every such supply; `notApplicable` has nothing left to mean",
    )),
    ("pm:coupling/pm:strength/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "a coupling that was observed has a strength, known or not, and `unmeasured` says the second",
    )),
    ("pm:demand/pm:amount/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "a layer is where `n - d` is held, so every layer has a demand to ask about. Zero demand is \
         [0, 0, 0], and a layer whose remainder question is malformed says so once, at \
         `StatedRemainder`",
    )),
    ("asrt:elimination/asrt:quantity/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "an entry exists because the composer found an overlap against this quantity; how much is \
         never malformed for a found overlap. The malformed case is the search's own \
         `notApplicable`, a one-part fusion",
    )),
    ("asrt:part/asrt:factor/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "`Part` says an absent factor means ONE, exactly: a conversion that does not apply is the \
         omitted element, and `notApplicable` would be a second door to it",
    )),
    ("pm:remainder/pm:quantity/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "a remainder filed as a claim has a magnitude to ask about; a layer whose remainder question \
         is malformed says so at `StatedRemainder` itself",
    )),
    ("pm:holder/pm:share/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "a holder is named because it bears some of the remainder; how much is never malformed for a \
         party that bears it",
    )),
    ("pm:lumpy/pm:size/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "if how big one unit is cannot be asked, the supply is not lumpy: `continuous` is the branch \
         that says there is no quantum, so this would be a second door to it",
    )),
    ("pm:quantum/pm:size/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "`StatedLumpyQuantum` has its own `notApplicable` for a unit with no period, so a window's \
         size filed `notApplicable` is a second door to it, and one `window_not_applicable_on_a_rate` \
         does not read",
    )),
    ("pm:quantum/pm:size/pm:absent/pm:reason", "value:unmeasured", Incoherent(
        "`StatedLumpyQuantum` has its own `unmeasured` for a period whose live part nobody measured, \
         and every reader treats the two alike: a window filed with an unmeasured size is a second \
         door to it",
    )),
    ("pm:induces/pm:commitment/pm:absent/pm:reason", "value:notApplicable", Incoherent(
        "an induction is filed because a commitment was made; how much is never malformed for a \
         commitment that exists",
    )),
];

/// The roots ingest does not load, from `scope/documents_on_disk.sqlc`: a document kind is loaded
/// when any document of that kind is.
fn unloaded_roots() -> BTreeSet<String> {
    let path = format!("{}/assets/sqlc/scope/documents_on_disk.sqlc", env!("CARGO_MANIFEST_DIR"));
    let src = fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"));
    let mut loaded: BTreeMap<String, bool> = BTreeMap::new();
    for l in src.lines().map(str::trim).filter(|l| l.starts_with("('")) {
        let f: Vec<&str> = l.splitn(4, ',').map(str::trim).collect();
        let kind = f[1].split("::").next().unwrap().trim_matches('\'').to_string();
        let is = f[2] == "true";
        *loaded.entry(kind).or_default() |= is;
    }
    assert!(!loaded.is_empty(), "{path}: no rows read");
    loaded
        .into_iter()
        .filter(|(_, l)| !l)
        .map(|(k, _)| if k == "processModulus" { format!("pm:{k}") } else { format!("asrt:{k}") })
        .collect()
}

/// How a state got its verdict.
#[derive(Debug)]
enum Standing {
    /// Past a cycle: the states of the place where its type was first opened.
    Recurs,
    /// Under a root ingest does not load.
    NotLoaded,
    /// A derivation's identity: the roster row that admits it, or none, when the identity does not
    /// compute the claim it is filed on.
    Roster(Option<usize>),
    /// Declared: the index into `DECLARED`.
    Declared(usize),
    /// A choice's arm, or an optional complex element left out: stated through what it holds.
    Contents,
}

fn segments(s: &str) -> usize {
    s.split('/').count()
}

fn resolve(u: &Universe, (path, state): &(String, String), unloaded: &BTreeSet<String>, rows: &[Cell]) -> Option<Standing> {
    if state == "cycle" || u.cycles.contains_key(path) {
        return Some(Standing::Recurs);
    }
    if unloaded.contains(path.split('/').next().unwrap()) {
        return Some(Standing::NotLoaded);
    }
    if let (Some(id), Some(head)) = (state.strip_prefix("value:"), path.strip_suffix("/pm:derivation/pm:identity")) {
        let s: Vec<&str> = head.split('/').collect();
        let n = s.len();
        let (owns, element) = if n >= 4 && s[n - 2] == "pm:claim" {
            (format!("{}/{}", s[n - 4], s[n - 3]), format!("{}/{}", s[n - 2], s[n - 1]))
        } else {
            let o = format!("{}/{}", s[n - 2], s[n - 1]);
            (o.clone(), o)
        };
        return Some(Standing::Roster(
            rows.iter().position(|c| c.identity == id && c.owns == owns && c.element == element),
        ));
    }
    let best = DECLARED
        .iter()
        .enumerate()
        .filter(|(_, (sfx, st, _))| {
            (path == sfx || path.ends_with(&format!("/{sfx}")))
                && (st == state || (*st == "*" && !state.starts_with("value:")))
        })
        .max_by_key(|(_, (sfx, st, _))| (segments(sfx), *st != "*"));
    if let Some((i, _)) = best {
        return Some(Standing::Declared(i));
    }
    let complex = u.paths.range(format!("{path}/")..).next().is_some_and(|p| p.starts_with(&format!("{path}/")));
    if state.starts_with("choice:") || (state == "omitted" && complex) {
        return Some(Standing::Contents);
    }
    None
}

/// Every state with its standing, or the ones that have none.
fn standings() -> (Universe, BTreeMap<(String, String), Standing>, Vec<(String, String)>) {
    let u = universe();
    let unloaded = unloaded_roots();
    let rows = roster();
    let mut got = BTreeMap::new();
    let mut none = Vec::new();
    for cell in &u.cells {
        match resolve(&u, cell, &unloaded, &rows) {
            Some(s) => {
                got.insert(cell.clone(), s);
            }
            None => none.push(cell.clone()),
        }
    }
    (u, got, none)
}

/// ⭐⭐⭐ EVERY STATE HAS EXACTLY ONE VERDICT, AND EVERY DECLARATION GIVES ONE.
#[test]
fn every_state_the_grammar_admits_has_one_verdict() {
    let (_, got, none) = standings();
    let mut grouped: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    for (p, s) in &none {
        let tail: Vec<&str> = p.rsplitn(3, '/').collect();
        grouped.entry(format!("{}/{}", tail.get(1).unwrap_or(&""), tail[0])).or_default().insert(s.clone());
    }
    assert!(
        none.is_empty(),
        "{} state(s) have no verdict. Each is a state a document can be in that nothing here has \
         decided about, grouped by the last two elements of its path:\n  {}",
        none.len(),
        grouped.iter().map(|(k, v)| format!("{k}: {v:?}")).collect::<Vec<_>>().join("\n  ")
    );

    let mut keys = BTreeSet::new();
    for (sfx, st, _) in DECLARED {
        assert!(keys.insert((sfx, st)), "`{sfx}` / `{st}` is declared twice");
    }
    let used: BTreeSet<usize> = got
        .values()
        .filter_map(|s| match s {
            Standing::Declared(i) => Some(*i),
            _ => None,
        })
        .collect();
    let dead: Vec<String> = DECLARED
        .iter()
        .enumerate()
        .filter(|(i, _)| !used.contains(i))
        .map(|(_, (sfx, st, _))| format!("{sfx} / {st}"))
        .collect();
    assert!(dead.is_empty(), "declarations that give no state its verdict:\n  {}", dead.join("\n  "));

    let rows = roster();
    let admitted: BTreeSet<usize> = got
        .values()
        .filter_map(|s| match s {
            Standing::Roster(Some(i)) => Some(*i),
            _ => None,
        })
        .collect();
    for (i, c) in rows.iter().enumerate() {
        assert!(
            admitted.contains(&i),
            "identities/roster.sqlc lists `{}` at {} {}, which no place in the grammar reaches",
            c.identity, c.element, c.owns
        );
    }

    let mut tally: BTreeMap<&str, usize> = BTreeMap::new();
    for s in got.values() {
        *tally
            .entry(match s {
                Standing::Recurs => "recurs",
                Standing::NotLoaded => "not loaded",
                Standing::Roster(Some(_)) => "handled, per the roster",
                Standing::Roster(None) => "incoherent, per the roster",
                Standing::Contents => "stated through its contents",
                Standing::Declared(i) => match DECLARED[*i].2 {
                    Handled(..) => "handled",
                    Incoherent(_) => "incoherent",
                    NotStored(..) => "not stored",
                },
            })
            .or_default() += 1;
    }
    println!("{} states: {tally:?}", got.len());
}

/// ⛔⛔ NO DOCUMENT FILES A STATE THE MODEL CALLS INCOHERENT.
#[test]
fn no_document_files_an_incoherent_state() {
    let (u, got, _) = standings();
    let filed = u.filings();
    let mut wrong = Vec::new();
    for (cell, n) in &filed {
        let why = match got.get(cell) {
            Some(Standing::Declared(i)) => match DECLARED[*i].2 {
                Incoherent(why) => Some(why),
                _ => None,
            },
            Some(Standing::Roster(None)) => Some("the identity does not compute the claim's own position"),
            _ => None,
        };
        if let Some(why) = why {
            wrong.push(format!("{} / {} filed {n} time(s): {why}", cell.0, cell.1));
        }
    }
    assert!(
        wrong.is_empty(),
        "documents file states this model calls incoherent. Either the document is wrong or the \
         argument is:\n  {}",
        wrong.join("\n  ")
    );
    let states: usize = got.len();
    let filed_states = filed.keys().filter(|c| got.contains_key(*c)).count();
    println!("{filed_states} of {states} states are filed by some document");
}

/// ⭐⭐ EVERY HANDLED STATE IS READ BY THE RELATION NAMED FOR IT: the relation exists, and its
/// composition reaches a statement that reads the table and the column the state lands in.
#[test]
fn every_handler_reads_the_column_its_state_lands_in() {
    let rows = roster();
    let mut handlers: BTreeSet<(String, String, String)> = DECLARED
        .iter()
        .filter_map(|(_, _, v)| match v {
            Handled(r, t, c) => Some((r.to_string(), t.to_string(), c.to_string())),
            _ => None,
        })
        .collect();
    handlers.extend(rows.iter().map(|c| (c.handled_by.clone(), c.table.clone(), c.column.clone())));
    for (rel, table, column) in handlers {
        let path = format!("{}/assets/sqlc/{rel}.sqlc", env!("CARGO_MANIFEST_DIR"));
        assert!(fs::metadata(&path).is_ok(), "{rel} is no relation under assets/sqlc");
        let reads = closure(&rel).into_iter().any(|p| {
            let src = fs::read_to_string(format!("{}/assets/sqlc/{p}", env!("CARGO_MANIFEST_DIR"))).unwrap();
            let sql = code(&src);
            has_word(&sql, &format!("pm.{table}")) && has_word(&sql, &column)
        });
        assert!(reads, "{rel} is named as reading pm.{table}.{column}, and nothing it composes does");
    }
}

/// ⛔ `not stored` IS A FACT ABOUT INGEST, SO INGEST IS WHAT IT IS CHECKED AGAINST: the insert into
/// the holder's table reads no path ending at the element.
#[test]
fn what_is_declared_not_stored_is_not_stored() {
    let ingest = fs::read_to_string(format!("{}/assets/sqlc/ingest.sqlc", env!("CARGO_MANIFEST_DIR"))).unwrap();
    for (sfx, _, v) in DECLARED {
        let NotStored(table, why) = v else { continue };
        assert!(!why.is_empty(), "`{sfx}` is declared not stored with no reason");
        let element = sfx.rsplit('/').next().unwrap();
        let statements: Vec<&str> = ingest
            .split("INSERT INTO ")
            .skip(1)
            .filter(|s| s.starts_with(&format!("{table}\n")) || s.starts_with(&format!("{table} ")))
            .collect();
        assert!(!statements.is_empty(), "ingest has no insert into {table}, the table `{sfx}` is said to miss");
        for s in statements {
            let body = &s[..s.find(";\n").unwrap_or(s.len())];
            assert!(
                !body.contains(&format!("{element}'")),
                "`{sfx}` is declared not stored, and ingest's insert into {table} reads a path ending at {element}"
            );
        }
    }
}
