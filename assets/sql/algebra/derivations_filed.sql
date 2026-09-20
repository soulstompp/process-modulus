-- epistemics/derivations.sqlc against epistemics/filed_derivations.sqlc, through identities/roster.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    WITH counted AS (
        SELECT c.owns, c.element, c.filing, c.identity, count(*) AS n
        FROM (
            -- every pm:derivation/identity in the schema, from every column that keeps one.
SELECT filing, subject, owns, coalesce(element, owns) AS element, identity FROM (
    SELECT filing, layer AS subject, 'pm:demand/pm:amount' AS owns, NULL::text AS element,
           derivation AS identity FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'demand'
    UNION ALL SELECT filing, layer, 'pm:nameplate/pm:amount', NULL, derivation FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'nameplate'
    UNION ALL SELECT filing, layer, 'pm:jagged/pm:draw', NULL, derivation FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'draw'
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:sign', NULL, sign_derivation FROM (
        SELECT * FROM layers.filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:quantity', NULL, qty_derivation FROM (
        SELECT * FROM layers.filed_remainders
    ) fr
    UNION ALL SELECT filing, layer || ' / ' || buffer::text,
                     CASE s.buffer WHEN 'time'     THEN 'pm:layer/pm:timeSlack'
                                   WHEN 'capacity' THEN 'pm:nameplate/pm:capacitySlack'
                                   ELSE 'pm:nameplate/pm:inventorySlack' END,
                     NULL, derivation FROM (
        SELECT * FROM entries.slacks
    ) s
    UNION ALL SELECT filing, layer || ' / ' || kind::text, 'pm:holder/pm:share', NULL, share_derivation FROM (
        SELECT * FROM entries.holders
    ) h
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, owns, element, identity FROM (
        SELECT * FROM epistemics.claim_derivations
    ) c
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'asrt:elimination/asrt:quantity', NULL, derivation FROM (
        SELECT * FROM eliminations.filed
    ) e
    UNION ALL SELECT composition, composed_layer || ' / ' || part_filing || ' ' || part_layer,
                     'asrt:part/asrt:factor', NULL, factor_derivation FROM (
        SELECT * FROM composition.part_references
    ) pr
) d
WHERE identity IS NOT NULL

        ) c
        GROUP BY c.owns, c.element, c.filing, c.identity
    ),
    filed AS (
        SELECT f.owns, f.element, f.filing, f.identity, count(*) AS n
        FROM (
            SELECT * FROM epistemics.filed_derivations
        ) f
        GROUP BY f.owns, f.element, f.filing, f.identity
    ),
    cells AS (
        SELECT coalesce(c.owns, f.owns) AS owns, coalesce(c.element, f.element) AS element,
               coalesce(c.filing, f.filing) AS filing, coalesce(c.identity, f.identity) AS identity,
               coalesce(c.n, 0) AS counted, coalesce(f.n, 0) AS filed
        FROM counted c
        FULL JOIN filed f ON f.owns = c.owns AND f.element = c.element AND f.filing = c.filing
                         AND f.identity = c.identity
    ),
    positions AS (
        SELECT DISTINCT r.owns, r.element
        FROM (
            SELECT * FROM identities.roster
        ) r
    )
    SELECT CASE WHEN q.element = q.owns THEN q.owns ELSE q.element || ' at ' || q.owns END AS subject,
           coalesce(bool_and(x.counted = x.filed), true) AS holds,
           format('%s filed, %s counted%s', coalesce(sum(x.filed), 0), coalesce(sum(x.counted), 0),
                  coalesce(': ' || string_agg(format('%s %s filed %s, counted %s', x.filing,
                                                     x.identity, x.filed, x.counted),
                                              '; ' ORDER BY x.filing, x.identity)
                                   FILTER (WHERE x.counted <> x.filed), '')) AS detail
    FROM positions q
    LEFT JOIN cells x ON x.owns = q.owns AND x.element = q.element
    GROUP BY q.owns, q.element
    UNION ALL
    SELECT 'pairs the roster does not admit',
           count(*) = 0,
           format('%s derivation(s) at a cell identities/roster.sqlc does not list%s', count(*),
                  coalesce(': ' || string_agg(DISTINCT f.element || ' at ' || f.owns || ' ' || f.identity::text, ', '), ''))
    FROM (
        SELECT * FROM epistemics.filed_derivations
    ) f
    WHERE NOT EXISTS (
        SELECT 1
        FROM (
            SELECT * FROM identities.roster
        ) r
        WHERE r.owns = f.owns AND r.element = f.element AND r.identity = f.identity::text
    )
) p ON true
WHERE a.slug = 'derivations_filed'
