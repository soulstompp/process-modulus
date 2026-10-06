-- diagrams/roster.sqlc against diagrams/expected.sqlc, one row per diagram law.
WITH diagrams_roster AS (
-- the counts a BPMN emission owes, against the relation supplying each expected count.
SELECT * FROM (VALUES
  ('pools',   'one participant per filing',    'epistemics/documents',     'participant',
              'a document rendered as two pools, or two rendered as one'),
  ('lanes',   'one lane per layer',            'layers/every_layer',       'lane',
              'layers drawn as overlapping, which draws what only a coupling may show'),
  ('tasks',   'one task per operation',        'entries/operations',       'task',
              'an operation dropped, or a flow node invented to make the picture read'),
  ('calls',   'one callActivity per part crossing a document', 'diagrams/foreign_calls',
              'callActivity',
              'A law of its own keeps a local part from being drawn as an activity: a local fusion '
              'divides the composed layer among its parts, and is not a node inside it. Only these '
              'parts go through `calledElement`, so this is the population exposed to a loop the '
              'flattening invents'),
  ('nestings', 'one childLaneSet per layer with a local part', 'diagrams/nestings', 'childLaneSet',
              'A fusion''s parts divide what they compose among them, and `Lane/childLaneSet` '
              'draws that division inside the lane. A nested lane is still keyed '
              '`(filing, layer)`, so unlike a call it collapses nothing and can invent nothing'),
  ('categories', 'one category per filing with an induction', 'diagrams/categories', 'category',
              'a classification scheme emitted into a document that has nothing to classify, or a document with inductions and no scheme to hang them on'),
  ('category_values', 'one categoryValue per layer induced into', 'diagrams/categories',
              'categoryValue',
              'The inductions given a notation. A second `laneSet` would give every layer two '
              '`lane` elements; BPMN''s other mechanism adds no lane at all: '
              '`tFlowElement/categoryValueRef` is `maxOccurs="unbounded"`, so the member declares '
              'the cover and no container grows'),
  ('groups',     'one group per categoryValue',  'diagrams/categories', 'group',
              'The glyph against the fact. `group` is to `categoryValueRef` what `lane` is to '
              '`flowNodeRef`: the drawn shape of a membership held elsewhere. A categoryValue with '
              'no group is a classification nobody drew; a group with no categoryValue is a dashed '
              'box that means nothing'),
  ('induced_into', 'one categoryValueRef per induction', 'diagrams/category_members',
              'categoryValueRef',
              'An induction dropped, which the lane count cannot see. An operation that draws '
              'from one layer and induces into another sits in one lane, so holding it in the '
              'draw alone leaves the induction out of every emitted document while the layer '
              'count still agrees'),
  ('diagrams', 'one BPMNDiagram per filing', 'diagrams/pools', 'BPMNDiagram',
              'The SVG''s proper place in the document. `bpmndi:BPMNDiagram` is in `tDefinitions`''s own sequence, and a document without one leaves the SVG stage to invent its coordinates while any tool that opens the file lays it out differently: two pictures of one model with nothing tying them'),
  ('planes', 'one BPMNPlane per filing', 'diagrams/pools', 'BPMNPlane',
              'one surface per document, naming the collaboration it is a picture of. A second plane would be a second picture of one model with no way to say which is meant'),
  ('shapes', 'one BPMNShape per element that owes a box', 'diagrams/shapes', 'BPMNShape',
              'The primitives are not all of it: a `group` and a `textAnnotation` owe a box too. '
              '`diagrams/shapes.sqlc` carries no coordinate for anything, so a row there says '
              'which elements owe a box and never where it is, and working the box out belongs '
              'to the emitter. An element drawn from geometry the document does not declare is '
              'an element every other reader of the file loses, without an error'),
  ('edges', 'one BPMNEdge per association', 'diagrams/shapes', 'BPMNEdge',
              'The one route in the notation, and it needs a different carrier from every box '
              'here: `bpmndi:BPMNEdge` with `di:waypoint`s, in a third namespace. Counting it with '
              'the shapes would make the shape count a number that matches nothing in the '
              'document, which is why `diagrams/shapes.sqlc` declares `di` per row'),
  ('legends', 'one textAnnotation per note a document owes on its face', 'diagrams/legends',
              'textAnnotation',
              'A fact present and invisible, which is what this law catches. `documentation` is '
              'admitted on any base element and drawn in no rendering, so a scope, a coupling '
              'search, a dependence''s meaning and a cover''s meaning can all be in the artifact '
              'and on no page. `textAnnotation` is the only element in BPMN that puts words on '
              'the canvas'),
  ('attributions', 'one relationship of type elimination-between per between that resolves',
              'eliminations/resolved', 'relationship',
              'The second `pm:ForeignId`, and the element''s type earning its keep. `association` '
              'cannot carry the composition: it has no type, and a second use would make two facts '
              'indistinguishable; `tRelationship/@type` is required, so a second relation costs a '
              'different string and the laws filter on it. The population is the resolved '
              'references and not all of them: a QName needs a prefix and a prefix needs an '
              'import, so a `between` naming a document nobody filed cannot be pointed at, and '
              'the schema calls that filing ordinary'),
  ('descents', 'one relationship per part crossing a document', 'diagrams/descents',
              'relationship',
              '`calledElement` names a process, so the edges between layers collapse to pairs of '
              'documents and the layer survives only inside `@name`; this carries the same fact at '
              'layer grain. The count is the weak half: as many relationships joining the wrong '
              'pairs pass it, which is why examples/diagramming/main.rs reads the endpoints back '
              'and compares them edge for edge with the parts'),
  ('citations', 'one rendered citation per filed citation', 'diagrams/citations', 'documentation',
              'A table declared as mapping and rendered nowhere, which no count of elements can see. Element kinds are not one to one: the pools and the lanes spend `documentation` too, so a count of that element is exact while this table''s share of it is zero, and `diagrams/ungoverned.sqlc` is the law that checks attribution instead'),
  ('scopes', 'one stated scope per filing', 'diagrams/scopes', 'documentation',
              'The `invents` state, caught in the emitter''s own prose. A sentence about a filing, hardcoded in the emitter, says one thing about every document where the filings differ, and `diagrams/scopes.sqlc` is what each one claims. That is not something a reader infers: the artifact says it. A count is not the law that matters here, the attribution one below it is: this only checks that a scope reached every document, and a wrong scope in every document would pass it'),
  ('dependences', 'one association per coupling', 'diagrams/dependences', 'association',
              'The observation that can show the model wrong, drawn. `pm:Coupling` exists so the '
              'model can be shown wrong in its own format, and the reason that rules out '
              '`messageFlow` says nothing about `association`, whose `sourceRef` and `targetRef` '
              'are unconstrained QNames. The law is worth as much for what it cannot check: an '
              'association carries no magnitude and no observation, so the count agrees while '
              'the evidence and the strength are both gone'),
  ('namespaces', 'one targetNamespace per notation', 'composition/notations', 'targetNamespace',
              'a document that does not declare the uri it is, so nothing can reference it'),
  ('imports', 'one import per document a composition reaches by a part or an elimination',
              'diagrams/cross_document', 'import',
              'a reference invented by the emitter, or a document reached without being imported'),
  ('in_a_lane', 'one flowNodeRef per draw and per part crossing a document',
              'diagrams/lane_membership', 'flowNodeRef',
              'an orphan flow node: emitted, counted, and in no lane, so the membership that put '
              'it there is gone from the rendering while every count still agrees'),
  ('definitions',   'one definitions per filing',   'diagrams/pools', 'definitions',
              'a filing emitted twice, or one skipped, which no leaf count would show'),
  ('collaboration', 'one collaboration per filing', 'diagrams/pools', 'collaboration',
              'one filing split across two collaborations, so its pool has no single home'),
  ('process',       'one process per filing',       'diagrams/pools', 'process',
              'one filing split into two processes, which divides its layers into two stacks'),
  ('lane_set',      'one laneSet per filing',       'diagrams/pools', 'laneSet',
              'The one that governs the elimination: a second lane set is how the draws and the '
              'inductions would both be drawn as lanes, and every layer then has two lane elements '
              'with nothing but a matching name to say they are one layer'),
  ('documentation', 'one documentation per sentence a relation states', 'diagrams/annotated',
              'documentation',
              'Documentation is not a container, which is what separates this row from the '
              'container rows above: they frame a document and appear once, while this is an '
              'annotation and may sit on any base element. A count alone is not enough here, '
              'which is what `states` is for: a document can carry the right number of sentences '
              'and each say something no relation states. examples/diagramming/main.rs reads '
              'every one back and asks what states it')
) AS l(slug, law, model_side, element, catches)
),
composition_notations AS (
-- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi
),
scope_every_filing AS (
-- from pm.filing: both evidence values, the typed reason a document gives neither,
-- and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f
),
epistemics_documents AS (
-- The top-level declarations: pm:processModulus and asrt:composition/dependence/coverage/run.
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
-- composition/parts.sqlc reduced to which layer is composed from which; one call activity per part.
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
-- pm:Operation/pm:Induction as which layer, never how much; BPMN 2.0
-- tFlowElement/categoryValueRef.
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
-- entries/draws.sqlc reduced to which operation draws from which layer; one flowNodeRef per entry.
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
