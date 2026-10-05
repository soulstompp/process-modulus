-- diagrams/roster.sqlc against diagrams/expected.sqlc, one row per diagram law.
WITH diagrams_roster AS (
-- the cardinality identities a BPMN emission owes, against the relation supplying each expected count.
SELECT * FROM (VALUES
  ('pools',   '|participant| = |filing|',      'epistemics/documents',     'participant',
              'a document rendered as two pools, or two rendered as one'),
  ('lanes',   '|lane| = |layer|',              'layers/every_layer',       'lane',
              'a partition rendered as an overlap: the falsifier, drawn'),
  ('tasks',   '|task| = |operation|',          'entries/operations',       'task',
              'an operation dropped, or a flow node invented to make the picture read'),
  ('calls',   '|callActivity| = |part crossing a document|', 'diagrams/foreign_calls', 'callActivity',
              'One law over two elements would let a local part be rendered as an activity. A local fusion is a partition of the composed layer, not a node inside it. Splitting the law is also what makes the flattening measurable: only these parts go through `calledElement`, so this is the population exposed to the invented-cycle defect'),
  ('nestings', '|childLaneSet| = |layer with a local part|', 'diagrams/nestings', 'childLaneSet',
              'The recursion equivalence, and BPMN already had the element. A fusion''s parts partition what they compose, and `Lane/childLaneSet` is a sub-partition. A nested lane is still keyed `(filing, layer)`, so unlike a call it collapses nothing and can invent nothing'),
  ('categories', '|category| = |filing with an induction|', 'diagrams/categories', 'category',
              'a classification scheme emitted into a document that has nothing to classify, or a document with inductions and no scheme to hang them on'),
  ('category_values', '|categoryValue| = |layer induced into|', 'diagrams/categories', 'categoryValue',
              'N getting a notation. The route that does not work is a second `laneSet`, which gives every layer two `lane` elements. BPMN''s other mechanism adds no lane at all: `tFlowElement/categoryValueRef` is `maxOccurs="unbounded"`, so the member declares the cover and no container grows'),
  ('groups',     '|group| = |categoryValue|',    'diagrams/categories', 'group',
              'The glyph against the fact, and the pair is the answer to what a group is. `group` is to `categoryValueRef` what `lane` is to `flowNodeRef`: the drawn shape of an incidence held elsewhere. A categoryValue with no group is a classification nobody drew; a group with no categoryValue is a dashed box that means nothing'),
  ('induced_into', '|categoryValueRef| = |induction|', 'diagrams/category_members', 'categoryValueRef',
              'An induction dropped, which `|lane| = |layer|` cannot see. One operation here draws from `labour` and induces into `capability`; a lane set holds it in one place, so holding it in the draw alone leaves the second incidence out of every emitted document while the layer count still agrees'),
  ('diagrams', '|BPMNDiagram| = |filing|', 'diagrams/pools', 'BPMNDiagram',
              'The SVG''s proper place in the document. `bpmndi:BPMNDiagram` is in `tDefinitions`''s own sequence, and a document without one leaves the SVG stage to invent its coordinates while any tool that opens the file lays it out differently: two pictures of one model with nothing tying them'),
  ('planes', '|BPMNPlane| = |filing|', 'diagrams/pools', 'BPMNPlane',
              'one surface per document, naming the collaboration it is a picture of. A second plane would be a second picture of one model with no way to say which is meant'),
  ('shapes', '|BPMNShape| = every element that owes a box', 'diagrams/shapes', 'BPMNShape',
              'The primitives are not all of it, and the tempting answer is that a `group`, an `association` and a `textAnnotation` are derived from these boxes, so filing a derived coordinate files a value that can disagree with whatever computes it. That argument holds and it is about the wrong column: `diagrams/shapes.sqlc` carries no coordinate for anything, so a row there says which elements owe a box and never where it is, and the derivation belongs in the emitter. An element drawn from geometry the document does not declare is an element every other reader of the file loses, without an error'),
  ('edges', '|BPMNEdge| = |association|', 'diagrams/shapes', 'BPMNEdge',
              'The one route in the notation, and it needs a different carrier from every box here: `bpmndi:BPMNEdge` with `di:waypoint`s, in a third namespace. Counting it with the shapes would make `|BPMNShape|` a number that matches nothing in the document, which is why `diagrams/shapes.sqlc` declares `di` per row'),
  ('legends', '|textAnnotation| = |note a document owes on its face|', 'diagrams/legends', 'textAnnotation',
              'A fact present and invisible, which is what this law catches. `documentation` is admitted on any base element and drawn in no rendering, so a scope, a coupling search, a dependence''s meaning and a cover''s meaning can all be in the artifact and on no page. `textAnnotation` is the only element in BPMN that puts words on the canvas, and *documentation is spent instead* is true and about the wrong property'),
  ('attributions', '|relationship type=elimination-between| = |between that resolves|', 'eliminations/resolved', 'relationship',
              'The second `pm:ForeignId`, and the element''s type earning its keep. `association` was refused for F because it has no type and a second use makes two facts indistinguishable; `tRelationship/@type` is required, so a second relation costs a different string and the laws filter on it. The population is the resolved references and not all of them: a QName needs a prefix and a prefix needs an import, so a `between` naming a document nobody filed cannot be pointed at, and the schema calls that filing ordinary'),
  ('descents', '|relationship| = |part crossing a document|', 'diagrams/descents', 'relationship',
              'The mapping''s widest demotion, promoted. `calledElement` names a process, so 17 layer-grain edges collapsed to 5 document pairs and the layer survived only inside `@name`. The count is the weak half: 17 relationships joining the wrong 17 pairs passes it, which is why the isomorphism law in examples/diagramming/main.rs reads the endpoints back and compares the edge set to F'),
  ('citations', '|citation rendered| = |citation filed|', 'diagrams/citations', 'documentation',
              'A table declared as mapping and rendered nowhere, which no count of elements can see. Element kinds are not one to one: the pools and the lanes spend `documentation` too, so a count of that element is exact while this table''s share of it is zero, and `diagrams/ungoverned.sqlc` is the law that checks attribution instead'),
  ('scopes', '|scope stated| = |filing|', 'diagrams/scopes', 'documentation',
              'The `invents` state, caught in the emitter''s own prose. A sentence about a filing, hardcoded in the emitter, says one thing about every document where the filings differ, and `diagrams/scopes.sqlc` is what each one claims. That is not something a reader infers: the artifact says it. A count is not the law that matters here, the attribution one below it is: this only checks that a scope reached every document, and a wrong scope in every document would pass it'),
  ('dependences', '|association| = |coupling|', 'diagrams/dependences', 'association',
              'The model''s own falsifier, which no emitted document could state. `pm:Coupling` exists so the model can be refuted in its own format, and the reason that rules out `messageFlow` says nothing about `association`, whose `sourceRef` and `targetRef` are unconstrained QNames. The law is worth as much for what it cannot check: an association carries no magnitude and no observation, so |association| = |coupling| passes while the evidence and the strength are both gone'),
  ('namespaces', '|targetNamespace| = |notation|', 'composition/notations', 'targetNamespace',
              'a document that does not declare the uri it is, so nothing can reference it'),
  ('imports', '|import| = |document a composition reaches by a part or an elimination|', 'diagrams/cross_document', 'import',
              'a reference invented by the emitter, or a document reached without being imported'),
  ('in_a_lane', '|flowNodeRef| = |draw| + |part crossing a document|', 'diagrams/lane_membership', 'flowNodeRef',
              'an orphan flow node: emitted, counted, and in no lane, so the incidence that put it there is gone from the rendering while every cardinality law still passes'),
  ('definitions',   '|definitions| = |filing|',   'diagrams/pools', 'definitions',
              'a filing emitted twice, or one skipped, which no leaf count would show'),
  ('collaboration', '|collaboration| = |filing|', 'diagrams/pools', 'collaboration',
              'one filing split across two collaborations, so its pool has no single home'),
  ('process',       '|process| = |filing|',       'diagrams/pools', 'process',
              'one filing split into two processes, which makes its layers two partitions'),
  ('lane_set',      '|laneSet| = |filing|',       'diagrams/pools', 'laneSet',
              'The one that governs the elimination: a second lane set is how D and N would both be rendered, and every layer then has two lane elements with nothing but a matching name to say they are one layer'),
  ('documentation', '|documentation| = |sentence a relation states|', 'diagrams/annotated', 'documentation',
              'Documentation is not a container, which is what separates this row from the other four. They frame a document and must appear once; this is an annotation and may sit on any base element, so one per document fires the moment a lane is annotated, which is a law right about a fact and wrong about a kind. And the identity beside it is prose where the model side is a relation, so `diagrams/annotated.sqlc` can grow an arm with this count staying exact and the sentence describing it going stale. A count is also the wrong instrument here and always was, which is what `states` is for: every document can carry the right number of sentences and each say something no relation states, with the count exact for any corpus size. examples/diagramming/main.rs reads every one back and asks what states it')
) AS l(slug, law, model_side, element, catches)
),
composition_notations AS (
-- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi
),
scope_every_filing AS (
-- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f
),
epistemics_documents AS (
-- The five top-level declarations: pm:processModulus and asrt:composition/dependence/coverage/run.
SELECT s.name AS filing,
       x.root, x.ns,
       fi.notation, fi.absent AS notation_absent,
       f.evidence, f.evidence_absent,
       x.witness, x.observed_at, x.ran_at
FROM      pm.source s
CROSS JOIN XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '/*' PASSING s.body
       COLUMNS root        text PATH 'local-name(.)',
               ns          text PATH 'namespace-uri(.)',
               witness     text PATH 'asrt:witness',
               observed_at text PATH 'asrt:observedAt',
               ran_at      text PATH 'asrt:ranAt') x
LEFT JOIN (
    SELECT * FROM composition_notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM scope_every_filing
) f ON f.filing = s.name
),
layers_every_layer AS (
-- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l
),
entries_operations AS (
-- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o
),
composition_part_references AS (
-- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       CASE WHEN p.factor_low        IS NOT NULL THEN 'stated'::public.factor_state
            WHEN p.factor_absent     IS NOT NULL THEN 'absent'::public.factor_state
            WHEN p.factor_derivation IS NOT NULL THEN 'derivation'::public.factor_state
            ELSE                                      'omitted'::public.factor_state END AS factor_state,
       p.part_party, p.part_registration_taxonomy, p.part_registration_value, p.part_version
FROM pm.part p
),
composition_parts AS (
-- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM composition_part_references
) p
JOIN      (
    SELECT * FROM composition_notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer
),
diagrams_calls AS (
-- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM composition_parts
) p
),
diagrams_foreign_calls AS (
-- diagrams/calls.sqlc pinned to the parts that leave their own document.
SELECT c.composition, c.composed_layer, c.part_notation, c.part_filing, c.part_layer
FROM (
    SELECT * FROM diagrams_calls
) c
WHERE NOT c.is_local
),
diagrams_nestings AS (
-- diagrams/calls.sqlc pinned to local parts, folded to the parent lane that will hold them.
SELECT DISTINCT c.composition, c.composed_layer
FROM (
    SELECT * FROM diagrams_calls
) c
WHERE c.is_local
),
entries_inductions AS (
-- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n
),
diagrams_categories AS (
-- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM entries_inductions
) i
),
diagrams_category_members AS (
-- pm:Operation/pm:Induction as incidence; BPMN 2.0 tFlowElement/categoryValueRef.
SELECT i.filing, i.operation, i.layer
FROM (
    SELECT * FROM entries_inductions
) i
),
diagrams_pools AS (
-- epistemics/documents.sqlc projected to the filing alone; one pool per document.
SELECT d.filing
FROM (
    SELECT * FROM epistemics_documents
) d
),
epistemics_scopes AS (
-- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss
),
diagrams_scopes AS (
-- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM epistemics_scopes
) s
),
epistemics_coupling_searches AS (
-- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs
),
diagrams_searches AS (
-- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM epistemics_coupling_searches
) s
),
entries_couplings AS (
-- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c
),
diagrams_dependences AS (
-- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM entries_couplings
) c
),
entries_draws AS (
-- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d
),
diagrams_lane_members AS (
-- entries/draws.sqlc projected to D's incidence alone; one flowNodeRef per entry.
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM entries_draws
) d
),
diagrams_lane_membership AS (
-- entries/draws.sqlc and diagrams/foreign_calls.sqlc, each projected onto the lane it belongs to.
SELECT 'draw' AS node_kind, d.filing, d.layer
FROM (
    SELECT * FROM diagrams_lane_members
) d
UNION ALL
SELECT 'part', c.composition, c.composed_layer
FROM (
    SELECT * FROM diagrams_foreign_calls
) c
),
diagrams_lane_occupancy AS (
-- layers/every_layer.sqlc against diagrams/lane_membership.sqlc; every lane, occupied or not.
SELECT l.filing,
       l.layer,
       count(m.node_kind) > 0 AS occupied
FROM      (
    SELECT * FROM layers_every_layer
) l
LEFT JOIN (
    SELECT * FROM diagrams_lane_membership
) m ON m.filing = l.filing AND m.layer = l.layer
GROUP BY l.filing, l.layer
),
diagrams_legends AS (
-- the notes a correct reading requires; BPMN 2.0 tTextAnnotation, drawn and unattached.
SELECT s.filing, 'scope' AS note, 'diagrams/scopes.sqlc' AS states
FROM ( SELECT * FROM diagrams_scopes ) s
UNION ALL
SELECT s.filing, 'search', 'diagrams/searches.sqlc'
FROM ( SELECT * FROM diagrams_searches ) s
UNION ALL
SELECT DISTINCT d.filing, 'dependence', 'diagrams/dependences.sqlc'
FROM ( SELECT * FROM diagrams_dependences ) d
UNION ALL
SELECT DISTINCT c.filing, 'cover', 'diagrams/categories.sqlc'
FROM ( SELECT * FROM diagrams_categories ) c
UNION ALL
SELECT DISTINCT e.filing, 'lane', 'diagrams/lane_grain.sqlc'
FROM ( SELECT * FROM diagrams_lane_occupancy ) e
WHERE NOT e.occupied
),
diagrams_shapes AS (
-- BPMN 2.0 DI: a bpmndi:BPMNShape per box and a bpmndi:BPMNEdge per route.
SELECT p.filing AS document, 'pool' AS shape_of, p.filing AS subject, 'shape' AS di
FROM ( SELECT * FROM diagrams_pools ) p
UNION ALL
SELECT l.filing, 'lane', l.layer, 'shape'
FROM ( SELECT * FROM layers_every_layer ) l
UNION ALL
SELECT o.filing, 'task', o.label, 'shape'
FROM ( SELECT * FROM entries_operations ) o
UNION ALL
SELECT c.composition, 'callActivity', c.composed_layer || '<-' || c.part_filing || '/' || c.part_layer, 'shape'
FROM ( SELECT * FROM diagrams_foreign_calls ) c
UNION ALL
SELECT k.filing, 'group', k.layer, 'shape'
FROM ( SELECT * FROM diagrams_categories ) k
UNION ALL
SELECT g.filing, 'textAnnotation', g.note, 'shape'
FROM ( SELECT * FROM diagrams_legends ) g
UNION ALL
SELECT d.filing, 'association', d.from_layer || '->' || d.to_layer, 'edge'
FROM ( SELECT * FROM diagrams_dependences ) d
),
diagrams_descents AS (
-- asrt:Fusion/asrt:Part crossing a document; BPMN 2.0 tRelationship source/target.
SELECT c.composition, c.composed_layer, c.part_filing, c.part_layer, c.part_notation
FROM (
    SELECT * FROM diagrams_calls
) c
WHERE NOT c.is_local
),
eliminations_between AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b
),
eliminations_references AS (
-- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b
),
eliminations_resolved AS (
-- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM composition_notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer
),
composition_citations AS (
-- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c
),
diagrams_citations AS (
-- asrt:Composition/asrt:citation, flattened to the one string a documentation element can hold.
SELECT c.composition,
       c.instrument
         || coalesce(' clause ' || c.clause, '')
         || coalesce(' (' || c.version || ')', '')
         || ' under ' || c.taxonomy AS cited
FROM (
    SELECT * FROM composition_citations
) c
),
diagrams_cross_document AS (
-- diagrams/calls.sqlc's foreign parts, and the filed layers an elimination is stated between.
SELECT DISTINCT x.composition, x.part_notation
FROM (
    SELECT c.composition, c.part_notation
    FROM ( SELECT * FROM diagrams_calls ) c
    WHERE NOT c.is_local
    UNION
    SELECT b.composition, b.notation
    FROM ( SELECT * FROM eliminations_references ) b
) x
),
diagrams_attributions AS (
-- eliminations/resolved.sqlc projected to the two ends of the relationship.
SELECT b.composition, b.composed_layer, b.notation, b.resolved_filing, b.layer
FROM (
    SELECT * FROM eliminations_resolved
) b
),
entries_notation_references AS (
-- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( SELECT * FROM entries_operations ) o
WHERE o.foreign_notation IS NOT NULL
),
diagrams_annotated AS (
-- the pools, the lanes and the categories, which are the three places provenance is owed.
SELECT 'document' AS annotated, d.filing AS subject,
       'diagrams/pools.sqlc' AS states
FROM ( SELECT * FROM diagrams_pools ) d
UNION ALL
SELECT 'lane', l.filing || '/' || l.layer, 'rank/evaluation_order.sqlc'
FROM ( SELECT * FROM layers_every_layer ) l
UNION ALL
SELECT 'category', c.filing, 'diagrams/categories.sqlc'
FROM ( SELECT DISTINCT k.filing FROM ( SELECT * FROM diagrams_categories ) k ) c
UNION ALL
SELECT 'lane set, the coupling search', s.filing, 'diagrams/searches.sqlc'
FROM ( SELECT * FROM diagrams_searches ) s
UNION ALL
SELECT 'lane set, the scope', s.filing, 'diagrams/scopes.sqlc'
FROM ( SELECT * FROM diagrams_scopes ) s
UNION ALL
SELECT 'process, the citation', c.composition, 'diagrams/citations.sqlc'
FROM ( SELECT * FROM diagrams_citations ) c
UNION ALL
SELECT 'relationship', d.composition || '/' || d.composed_layer || '<-' || d.part_filing || '/' || d.part_layer,
       'diagrams/descents.sqlc'
FROM ( SELECT * FROM diagrams_descents ) d
UNION ALL
SELECT 'relationship, an attribution',
       b.composition || '/' || b.composed_layer || '<>' || b.resolved_filing || '/' || b.layer,
       'diagrams/attributions.sqlc'
FROM ( SELECT * FROM diagrams_attributions ) b
UNION ALL
SELECT 'dependence', d.filing || '/' || d.from_layer || '->' || d.to_layer,
       'diagrams/dependences.sqlc'
FROM ( SELECT * FROM diagrams_dependences ) d
UNION ALL
SELECT 'task, the notation position', n.filing || '/' || n.label,
       'entries/notation_references.sqlc'
FROM ( SELECT * FROM entries_notation_references ) n
UNION ALL
SELECT 'task, no notation position', o.filing || '/' || o.label,
       'entries/operations.sqlc'
FROM ( SELECT * FROM entries_operations ) o
WHERE o.foreign_absent IS NOT NULL
),
diagrams_expected AS (
-- diagrams/roster.sqlc's model_side relations, each counted.
SELECT 'pools'   AS slug, count(*) AS expected FROM ( SELECT * FROM epistemics_documents )  x
UNION ALL
SELECT 'lanes',   count(*) FROM ( SELECT * FROM layers_every_layer )    x
UNION ALL
SELECT 'tasks',   count(*) FROM ( SELECT * FROM entries_operations )    x
UNION ALL
SELECT 'calls',   count(*) FROM ( SELECT * FROM diagrams_foreign_calls ) x
UNION ALL
SELECT 'nestings', count(*) FROM ( SELECT * FROM diagrams_nestings )    x
UNION ALL
SELECT 'categories', count(DISTINCT x.filing) FROM ( SELECT * FROM diagrams_categories ) x
UNION ALL
SELECT 'category_values', count(*) FROM ( SELECT * FROM diagrams_categories ) x
UNION ALL
SELECT 'groups',     count(*) FROM ( SELECT * FROM diagrams_categories ) x
UNION ALL
SELECT 'induced_into', count(*) FROM ( SELECT * FROM diagrams_category_members ) x
UNION ALL
SELECT 'diagrams', count(*) FROM ( SELECT * FROM diagrams_pools ) x
UNION ALL
SELECT 'planes',   count(*) FROM ( SELECT * FROM diagrams_pools ) x
UNION ALL
SELECT 'shapes',   count(*) FROM ( SELECT * FROM diagrams_shapes ) x WHERE x.di = 'shape'
UNION ALL
SELECT 'edges',    count(*) FROM ( SELECT * FROM diagrams_shapes ) x WHERE x.di = 'edge'
UNION ALL
SELECT 'legends', count(*) FROM ( SELECT * FROM diagrams_legends ) x
UNION ALL
SELECT 'descents', count(*) FROM ( SELECT * FROM diagrams_descents ) x
UNION ALL
SELECT 'attributions', count(*) FROM ( SELECT * FROM eliminations_resolved ) x
UNION ALL
SELECT 'citations', count(*) FROM ( SELECT * FROM diagrams_citations ) x
UNION ALL
SELECT 'scopes', count(*) FROM ( SELECT * FROM diagrams_scopes ) x
UNION ALL
SELECT 'dependences', count(*) FROM ( SELECT * FROM diagrams_dependences ) x
UNION ALL
SELECT 'namespaces', count(*) FROM ( SELECT * FROM composition_notations ) x
UNION ALL
SELECT 'imports', count(*) FROM ( SELECT * FROM diagrams_cross_document ) x
UNION ALL
SELECT 'in_a_lane', count(*) FROM ( SELECT * FROM diagrams_lane_membership ) x
UNION ALL
SELECT 'definitions',   count(*) FROM ( SELECT * FROM diagrams_pools ) x
UNION ALL
SELECT 'collaboration', count(*) FROM ( SELECT * FROM diagrams_pools ) x
UNION ALL
SELECT 'process',       count(*) FROM ( SELECT * FROM diagrams_pools ) x
UNION ALL
SELECT 'lane_set',      count(*) FROM ( SELECT * FROM diagrams_pools ) x
UNION ALL
SELECT 'documentation', count(*) FROM ( SELECT * FROM diagrams_annotated ) x
)
SELECT coalesce(l.slug, e.slug)     AS subject,
       l.slug IS NOT NULL           AS declared,
       count(e.slug)                AS rows
FROM      (
    SELECT * FROM diagrams_roster
) l
FULL JOIN (
    SELECT * FROM diagrams_expected
) e ON e.slug = l.slug
GROUP BY l.slug, e.slug
