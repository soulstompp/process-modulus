-- diagrams/roster.sqlc's model_side relations, each counted.
WITH
composition_citations AS NOT MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

),
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

),
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

),
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

),
categories AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM inductions
) i

),
diagrams_citations AS NOT MATERIALIZED (
    -- asrt:Composition/asrt:citation, flattened to the one string a documentation element can hold.
WITH
citations AS NOT MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

)
SELECT c.composition,
       c.instrument
         || coalesce(' clause ' || c.clause, '')
         || coalesce(' (' || c.version || ')', '')
         || ' under ' || c.taxonomy AS cited
FROM (
    SELECT * FROM composition_citations
) c

),
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

),
dependences AS NOT MATERIALIZED (
    -- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
WITH
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

)
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM couplings
) c

),
descents AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:Part crossing a document; BPMN 2.0 tRelationship source/target.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

),
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

)
SELECT c.composition, c.composed_layer, c.part_filing, c.part_layer, c.part_notation
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
foreign_calls AS NOT MATERIALIZED (
    -- diagrams/calls.sqlc pinned to the parts that leave their own document.
SELECT c.composition, c.composed_layer, c.part_notation, c.part_filing, c.part_layer
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

),
lane_membership AS NOT MATERIALIZED (
    -- entries/draws.sqlc and diagrams/foreign_calls.sqlc, each projected onto the lane it belongs to.
SELECT 'draw' AS node_kind, d.filing, d.layer
FROM (
    -- entries/draws.sqlc projected to D's incidence alone; one flowNodeRef per entry.
WITH
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

)
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM draws
) d

) d
UNION ALL
SELECT 'part', c.composition, c.composed_layer
FROM (
    SELECT * FROM foreign_calls
) c

),
epistemics_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

),
diagrams_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
WITH
scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

)
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM epistemics_scopes
) s

),
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

),
searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
WITH
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

)
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM coupling_searches
) s

),
every_layer AS NOT MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

),
legends AS NOT MATERIALIZED (
    -- the notes a correct reading requires; BPMN 2.0 tTextAnnotation, drawn and unattached.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

),
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

),
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

),
categories AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM inductions
) i

),
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

),
dependences AS NOT MATERIALIZED (
    -- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
WITH
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

)
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM couplings
) c

),
foreign_calls AS NOT MATERIALIZED (
    -- diagrams/calls.sqlc pinned to the parts that leave their own document.
SELECT c.composition, c.composed_layer, c.part_notation, c.part_filing, c.part_layer
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

),
lane_membership AS NOT MATERIALIZED (
    -- entries/draws.sqlc and diagrams/foreign_calls.sqlc, each projected onto the lane it belongs to.
SELECT 'draw' AS node_kind, d.filing, d.layer
FROM (
    -- entries/draws.sqlc projected to D's incidence alone; one flowNodeRef per entry.
WITH
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

)
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM draws
) d

) d
UNION ALL
SELECT 'part', c.composition, c.composed_layer
FROM (
    SELECT * FROM foreign_calls
) c

),
epistemics_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

),
diagrams_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
WITH
scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

)
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM epistemics_scopes
) s

),
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

),
searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
WITH
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

)
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM coupling_searches
) s

),
every_layer AS NOT MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

)
SELECT s.filing, 'scope' AS note, 'diagrams/scopes.sqlc' AS states
FROM ( SELECT * FROM diagrams_scopes ) s
UNION ALL
SELECT s.filing, 'search', 'diagrams/searches.sqlc'
FROM ( SELECT * FROM searches ) s
UNION ALL
SELECT DISTINCT d.filing, 'dependence', 'diagrams/dependences.sqlc'
FROM ( SELECT * FROM dependences ) d
UNION ALL
SELECT DISTINCT c.filing, 'cover', 'diagrams/categories.sqlc'
FROM ( SELECT * FROM categories ) c
UNION ALL
SELECT DISTINCT e.filing, 'lane', 'diagrams/lane_grain.sqlc'
FROM ( -- layers/every_layer.sqlc against diagrams/lane_membership.sqlc; every lane, occupied or not.
SELECT l.filing,
       l.layer,
       count(m.node_kind) > 0 AS occupied
FROM      (
    SELECT * FROM every_layer
) l
LEFT JOIN (
    SELECT * FROM lane_membership
) m ON m.filing = l.filing AND m.layer = l.layer
GROUP BY l.filing, l.layer
 ) e
WHERE NOT e.occupied

),
every_filing AS NOT MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS NOT MATERIALIZED (
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
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

),
pools AS NOT MATERIALIZED (
    -- epistemics/documents.sqlc projected to the filing alone; one pool per document.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
every_filing AS NOT MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS NOT MATERIALIZED (
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
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

)
SELECT d.filing
FROM (
    SELECT * FROM documents
) d

),
eliminations_between AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b

),
eliminations_references AS NOT MATERIALIZED (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b

),
resolved AS NOT MATERIALIZED (
    -- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer

),
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

),
notation_references AS NOT MATERIALIZED (
    -- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
WITH
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

)
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( SELECT * FROM operations ) o
WHERE o.foreign_notation IS NOT NULL

)
SELECT 'pools'   AS slug, count(*) AS expected FROM ( SELECT * FROM documents )  x
UNION ALL
SELECT 'lanes',   count(*) FROM ( SELECT * FROM every_layer )    x
UNION ALL
SELECT 'tasks',   count(*) FROM ( SELECT * FROM operations )    x
UNION ALL
SELECT 'calls',   count(*) FROM ( SELECT * FROM foreign_calls ) x
UNION ALL
SELECT 'nestings', count(*) FROM ( -- diagrams/calls.sqlc pinned to local parts, folded to the parent lane that will hold them.
SELECT DISTINCT c.composition, c.composed_layer
FROM (
    SELECT * FROM calls
) c
WHERE c.is_local
 )    x
UNION ALL
SELECT 'categories', count(DISTINCT x.filing) FROM ( SELECT * FROM categories ) x
UNION ALL
SELECT 'category_values', count(*) FROM ( SELECT * FROM categories ) x
UNION ALL
SELECT 'groups',     count(*) FROM ( SELECT * FROM categories ) x
UNION ALL
SELECT 'induced_into', count(*) FROM ( -- pm:Operation/pm:Induction as incidence; BPMN 2.0 tFlowElement/categoryValueRef.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT i.filing, i.operation, i.layer
FROM (
    SELECT * FROM inductions
) i
 ) x
UNION ALL
SELECT 'diagrams', count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'planes',   count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'shapes',   count(*) FROM ( -- BPMN 2.0 DI: a bpmndi:BPMNShape per box and a bpmndi:BPMNEdge per route.
SELECT p.filing AS document, 'pool' AS shape_of, p.filing AS subject, 'shape' AS di
FROM ( SELECT * FROM pools ) p
UNION ALL
SELECT l.filing, 'lane', l.layer, 'shape'
FROM ( SELECT * FROM every_layer ) l
UNION ALL
SELECT o.filing, 'task', o.label, 'shape'
FROM ( SELECT * FROM operations ) o
UNION ALL
SELECT c.composition, 'callActivity', c.composed_layer || '<-' || c.part_filing || '/' || c.part_layer, 'shape'
FROM ( SELECT * FROM foreign_calls ) c
UNION ALL
SELECT k.filing, 'group', k.layer, 'shape'
FROM ( SELECT * FROM categories ) k
UNION ALL
SELECT g.filing, 'textAnnotation', g.note, 'shape'
FROM ( SELECT * FROM legends ) g
UNION ALL
SELECT d.filing, 'association', d.from_layer || '->' || d.to_layer, 'edge'
FROM ( SELECT * FROM dependences ) d
 ) x WHERE x.di = 'shape'
UNION ALL
SELECT 'edges',    count(*) FROM ( -- BPMN 2.0 DI: a bpmndi:BPMNShape per box and a bpmndi:BPMNEdge per route.
SELECT p.filing AS document, 'pool' AS shape_of, p.filing AS subject, 'shape' AS di
FROM ( SELECT * FROM pools ) p
UNION ALL
SELECT l.filing, 'lane', l.layer, 'shape'
FROM ( SELECT * FROM every_layer ) l
UNION ALL
SELECT o.filing, 'task', o.label, 'shape'
FROM ( SELECT * FROM operations ) o
UNION ALL
SELECT c.composition, 'callActivity', c.composed_layer || '<-' || c.part_filing || '/' || c.part_layer, 'shape'
FROM ( SELECT * FROM foreign_calls ) c
UNION ALL
SELECT k.filing, 'group', k.layer, 'shape'
FROM ( SELECT * FROM categories ) k
UNION ALL
SELECT g.filing, 'textAnnotation', g.note, 'shape'
FROM ( SELECT * FROM legends ) g
UNION ALL
SELECT d.filing, 'association', d.from_layer || '->' || d.to_layer, 'edge'
FROM ( SELECT * FROM dependences ) d
 ) x WHERE x.di = 'edge'
UNION ALL
SELECT 'legends', count(*) FROM ( SELECT * FROM legends ) x
UNION ALL
SELECT 'descents', count(*) FROM ( SELECT * FROM descents ) x
UNION ALL
SELECT 'attributions', count(*) FROM ( SELECT * FROM resolved ) x
UNION ALL
SELECT 'citations', count(*) FROM ( SELECT * FROM diagrams_citations ) x
UNION ALL
SELECT 'scopes', count(*) FROM ( SELECT * FROM diagrams_scopes ) x
UNION ALL
SELECT 'dependences', count(*) FROM ( SELECT * FROM dependences ) x
UNION ALL
SELECT 'namespaces', count(*) FROM ( SELECT * FROM notations ) x
UNION ALL
SELECT 'imports', count(*) FROM ( -- diagrams/calls.sqlc's foreign parts, and the filed layers an elimination is stated between.
SELECT DISTINCT x.composition, x.part_notation
FROM (
    SELECT c.composition, c.part_notation
    FROM ( SELECT * FROM calls ) c
    WHERE NOT c.is_local
    UNION
    SELECT b.composition, b.notation
    FROM ( SELECT * FROM eliminations_references ) b
) x
 ) x
UNION ALL
SELECT 'in_a_lane', count(*) FROM ( SELECT * FROM lane_membership ) x
UNION ALL
SELECT 'definitions',   count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'collaboration', count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'process',       count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'lane_set',      count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'documentation', count(*) FROM ( -- the pools, the lanes and the categories, which are the three places provenance is owed.
WITH
composition_citations AS NOT MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

),
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

),
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

),
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

),
categories AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM inductions
) i

),
diagrams_citations AS NOT MATERIALIZED (
    -- asrt:Composition/asrt:citation, flattened to the one string a documentation element can hold.
WITH
citations AS NOT MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

)
SELECT c.composition,
       c.instrument
         || coalesce(' clause ' || c.clause, '')
         || coalesce(' (' || c.version || ')', '')
         || ' under ' || c.taxonomy AS cited
FROM (
    SELECT * FROM composition_citations
) c

),
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

),
dependences AS NOT MATERIALIZED (
    -- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
WITH
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

)
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM couplings
) c

),
descents AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:Part crossing a document; BPMN 2.0 tRelationship source/target.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

),
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

)
SELECT c.composition, c.composed_layer, c.part_filing, c.part_layer, c.part_notation
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
every_filing AS NOT MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS NOT MATERIALIZED (
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
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

),
pools AS NOT MATERIALIZED (
    -- epistemics/documents.sqlc projected to the filing alone; one pool per document.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
every_filing AS NOT MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS NOT MATERIALIZED (
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
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

)
SELECT d.filing
FROM (
    SELECT * FROM documents
) d

),
epistemics_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

),
diagrams_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
WITH
scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

)
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM epistemics_scopes
) s

),
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

),
searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
WITH
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

)
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM coupling_searches
) s

),
eliminations_between AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b

),
eliminations_references AS NOT MATERIALIZED (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b

),
resolved AS NOT MATERIALIZED (
    -- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer

),
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

),
notation_references AS NOT MATERIALIZED (
    -- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
WITH
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

)
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( SELECT * FROM operations ) o
WHERE o.foreign_notation IS NOT NULL

),
every_layer AS NOT MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

)
SELECT 'document' AS annotated, d.filing AS subject,
       'diagrams/pools.sqlc' AS states
FROM ( SELECT * FROM pools ) d
UNION ALL
SELECT 'lane', l.filing || '/' || l.layer, 'rank/evaluation_order.sqlc'
FROM ( SELECT * FROM every_layer ) l
UNION ALL
SELECT 'category', c.filing, 'diagrams/categories.sqlc'
FROM ( SELECT DISTINCT k.filing FROM ( SELECT * FROM categories ) k ) c
UNION ALL
SELECT 'lane set, the coupling search', s.filing, 'diagrams/searches.sqlc'
FROM ( SELECT * FROM searches ) s
UNION ALL
SELECT 'lane set, the scope', s.filing, 'diagrams/scopes.sqlc'
FROM ( SELECT * FROM diagrams_scopes ) s
UNION ALL
SELECT 'process, the citation', c.composition, 'diagrams/citations.sqlc'
FROM ( SELECT * FROM diagrams_citations ) c
UNION ALL
SELECT 'relationship', d.composition || '/' || d.composed_layer || '<-' || d.part_filing || '/' || d.part_layer,
       'diagrams/descents.sqlc'
FROM ( SELECT * FROM descents ) d
UNION ALL
SELECT 'relationship, an attribution',
       b.composition || '/' || b.composed_layer || '<>' || b.resolved_filing || '/' || b.layer,
       'diagrams/attributions.sqlc'
FROM ( -- eliminations/resolved.sqlc projected to the two ends of the relationship.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
eliminations_between AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b

),
eliminations_references AS NOT MATERIALIZED (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b

),
resolved AS NOT MATERIALIZED (
    -- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer

)
SELECT b.composition, b.composed_layer, b.notation, b.resolved_filing, b.layer
FROM (
    SELECT * FROM resolved
) b
 ) b
UNION ALL
SELECT 'dependence', d.filing || '/' || d.from_layer || '->' || d.to_layer,
       'diagrams/dependences.sqlc'
FROM ( SELECT * FROM dependences ) d
UNION ALL
SELECT 'task, the notation position', n.filing || '/' || n.label,
       'entries/notation_references.sqlc'
FROM ( SELECT * FROM notation_references ) n
UNION ALL
SELECT 'task, no notation position', o.filing || '/' || o.label,
       'entries/operations.sqlc'
FROM ( SELECT * FROM operations ) o
WHERE o.foreign_absent IS NOT NULL
 ) x
