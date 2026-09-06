-- §1  Every document that reached the database, and what it says about itself.
-- epistemics/documents.sqlc, with the citation a composition works under.
SELECT d.filing                       AS "filing!",
       d.root                         AS "root!",
       d.evidence                     AS "evidence",
       coalesce(d.witness, '')        AS "witness!",
       coalesce(c.instrument || coalesce(' ' || c.clause, ''), '') AS "under!"
FROM (
    --
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
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.filing = s.name
-- ⛔ pm.filing raw, and deliberately: scope/every_filing.sqlc drops evidence_absent, and a
--    document that declines to say what it is evidence FOR is exactly what this relation reports.
LEFT JOIN pm.filing f ON f.name = s.name

) d
LEFT JOIN (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

) c ON c.composition = d.filing AND c.seq = 1
ORDER BY d.root, d.filing
