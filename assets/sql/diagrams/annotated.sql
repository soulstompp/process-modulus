-- the pools, the lanes and the categories, which are the three places provenance is owed.
WITH composition_notations AS (
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
diagrams_pools AS (
-- epistemics/documents.sqlc projected to the filing alone; one pool per document.
SELECT d.filing
FROM (
    SELECT * FROM epistemics_documents
) d
),
layers_every_layer AS (
-- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l
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
diagrams_attributions AS (
-- eliminations/resolved.sqlc projected to the two ends of the relationship.
SELECT b.composition, b.composed_layer, b.notation, b.resolved_filing, b.layer
FROM (
    SELECT * FROM eliminations_resolved
) b
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
entries_operations AS (
-- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o
),
entries_notation_references AS (
-- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( SELECT * FROM entries_operations ) o
WHERE o.foreign_notation IS NOT NULL
)
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
