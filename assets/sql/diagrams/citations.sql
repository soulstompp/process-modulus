-- asrt:Composition/asrt:citation, flattened to the one string a documentation element can hold.
WITH composition_citations AS (
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
