-- §1  Every document that reached the database, and what it says about itself.
-- epistemics/documents.sqlc, with the citation a composition works under.
SELECT d.filing                       AS "filing!",
       d.root                         AS "root!",
       d.evidence                     AS "evidence",
       coalesce(d.witness, '')        AS "witness!",
       coalesce(c.instrument || coalesce(' ' || c.clause, ''), '') AS "under!"
FROM (
    SELECT * FROM epistemics.documents
) d
LEFT JOIN (
    SELECT * FROM composition.citations
) c ON c.composition = d.filing AND c.seq = 1
ORDER BY d.root, d.filing
