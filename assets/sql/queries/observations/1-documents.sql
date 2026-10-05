-- §1  Every document that reached the database, and what it says about itself.
-- epistemics/documents.sqlc, with the citation a composition works under.
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
composition_citations AS (
-- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c
)
SELECT d.filing                       AS "filing!",
       d.root                         AS "root!",
       d.evidence                     AS "evidence",
       coalesce(d.witness, '')        AS "witness!",
       coalesce(c.instrument || coalesce(' ' || c.clause, ''), '') AS "under!"
FROM (
    SELECT * FROM epistemics_documents
) d
LEFT JOIN (
    SELECT * FROM composition_citations
) c ON c.composition = d.filing AND c.seq = 1
ORDER BY d.root, d.filing
