-- The matrices from docs/linear-algebra.md, pulled out with SQL.
--
--   psql -f assets/sql/schema.ddl -f assets/sql/ingest.sql -f assets/sql/matrices.sql
--
-- ⭐⭐ THE ONE IDEA THIS FILE IS BUILT ON, AND IT IS SMALLER THAN IT SOUNDS.
--
--   A matrix is a table. `D[p,l] = 3` is a row (p, l, 3), and an entry that is zero
--   is simply a row that is not there.
--
--   A matrix product is a JOIN and a GROUP BY. `(AB)[i,k] = sum_j A[i,j] B[j,k]` says:
--   join A to B where A's column equals B's row, multiply the two values, add up the
--   groups. That is the whole of it, and anyone who has written a join with a SUM has
--   multiplied matrices without being told that is what it was.
--
--     SELECT a.i, b.k, sum(a.v * b.v)      -- the product
--     FROM a JOIN b ON a.j = b.j           -- the shared index
--     GROUP BY a.i, b.k;                   -- the sum over it
--
-- ⛔ AND ONE THING THE TABLE HAS THAT THE MATRIX DOES NOT. A missing row can mean the
--    entry is zero, or it can mean nobody looked. This model cares about that difference
--    more than about almost anything else, and a matrix of numbers cannot hold it. Every
--    query below that could hide the distinction reports it instead.

SET search_path TO pm, public;
\pset border 2
\pset null '·'

\echo
\echo === D, the draw matrix. Operations down, layers across. =========================
\echo 'Sparse: one row per draw. No row means that operation draws nothing from that layer.'
SELECT filing, operation, layer,
       coalesce(mode::text, '(' || absent || ')') AS entry, unit
FROM draw ORDER BY filing, operation, layer;

\echo
\echo === N, the induction matrix. Same shape, different fact. ========================
\echo 'A draw is consumption that happened. An induction is a commitment that creates a'
\echo 'future draw on a DIFFERENT supply, and only it names a decider.'
SELECT filing, operation, layer,
       coalesce(mode::text, '(' || absent || ')') AS entry, unit, decider
FROM induction ORDER BY filing, operation, layer;

\echo
\echo === D-transpose times N, and why it is not what it looks like ===================
\echo 'The product is a join on the shared index (the operation) and a sum over it.'
\echo 'The arithmetic is fine. Look at the UNIT column.'
WITH product AS (
    SELECT d.filing,
           d.layer  AS drawn_from,
           n.layer  AS commits,
           sum(d.mode * n.mode)                AS value,
           d.unit || ' * ' || n.unit           AS unit
    FROM draw d
    JOIN induction n
      ON n.filing = d.filing AND n.operation = d.operation   -- the shared index
    WHERE d.mode IS NOT NULL AND n.mode IS NOT NULL
    GROUP BY d.filing, d.layer, n.layer, d.unit, n.unit      -- the sum over it
)
SELECT * FROM product ORDER BY 1, 2, 3;
\echo '⛔ Each layer carries its own unit, so an entry comes out in people*launches, which'
\echo '   is not a rate of anything. The INCIDENCE composes and gives you reachability.'
\echo '   The QUANTITIES do not. There is also no firing count per operation, deliberately,'
\echo '   because sequence and timing are BPMN''s job.'

\echo
\echo === C, the coupling matrix, and the absence that matters ========================
\echo 'C = 0 is the model ASSUMPTION. Every non-zero entry is an observation somebody made.'
SELECT filing, from_layer, to_layer, low, mode, high, unit,
       left(observation, 60) || '...' AS observed
FROM coupling ORDER BY filing, from_layer, to_layer;

\echo
\echo '⛔⛔ AND HERE IS WHAT THE MATRIX CANNOT SAY. A filing with no rows above has either'
\echo '    a stack of independent layers, or nobody who looked. Densify it and both become'
\echo '    a grid of 0.0 and the difference is gone for good.'
SELECT f.name AS filing,
       count(c.*)                             AS couplings_filed,
       CASE WHEN count(c.*) = 0
            THEN 'no rows: independent, or nobody looked. UNDECIDABLE from here'
            ELSE 'at least one observation was made' END AS what_that_means
FROM filing f LEFT JOIN coupling c ON c.filing = f.name
GROUP BY f.name ORDER BY 1;

\echo
\echo === H, who bears the remainder, and S, what each buffer holds ===================
\echo 'H is L x 5 and S is L x 3. Both are tall, and both are mostly absent.'
SELECT h.filing, h.layer, h.kind,
       coalesce(h.share_mode::text, '(' || h.share_absent || ')') AS share
FROM holder h ORDER BY 1, 2, 3;

\echo
\echo 'S, and the count that matters: 2 of 69 entries carry a number.'
SELECT buffer,
       count(*)                              AS entries,
       count(low)                            AS sized,
       count(*) FILTER (WHERE absent = 'none')       AS measured_zero,
       count(*) FILTER (WHERE absent = 'unmeasured') AS nobody_measured
FROM slack GROUP BY buffer ORDER BY buffer;

\echo
\echo === r = n - d, and the bound reversal that is easy to get wrong =================
\echo 'Subtracting intervals REVERSES the bounds: the low of n-d pairs n.low with d.HIGH.'
\echo 'Get that backwards and every remainder in the corpus comes out inside out.'
WITH remainder AS (
    SELECT l.filing, l.layer,
           n.amount_low  - l.demand_high AS r_low,    -- note the crossed subscripts
           n.amount_mode - l.demand_mode AS r_mode,
           n.amount_high - l.demand_low  AS r_high,
           l.demand_unit AS unit, l.sign
    FROM layer l JOIN nameplate n USING (filing, layer)
    WHERE l.demand_low IS NOT NULL AND n.amount_low IS NOT NULL
)
SELECT filing, layer, r_low, r_mode, r_high, unit, sign,
       CASE WHEN r_low >= 0 THEN 'clearance'
            WHEN r_high <= 0 THEN 'interference'
            ELSE 'transition' END AS fit_from_the_ranges
FROM remainder ORDER BY filing, layer;
\echo '⭐ The last two columns are the filed sign and the sign recomputed from the ranges.'
\echo '  They agree for every layer, which is a rule XSD 1.0 cannot express at all.'

\echo
\echo === F and Phi, and the recursion the schema cannot see ==========================
\echo 'Compositions nest. Holding composes the group, which composes the members.'
WITH RECURSIVE descent(root_filing, root_layer, filing, layer, depth, path) AS (
        SELECT p.composition, p.composed_layer, fi.filing, p.part_layer, 1,
               ARRAY[p.composition || '/' || p.composed_layer,
                     fi.filing || '/' || p.part_layer]
        FROM part p JOIN filing_identity fi ON fi.notation = p.part_filing
    UNION ALL
        SELECT d.root_filing, d.root_layer, fi.filing, p.part_layer, d.depth + 1,
               d.path || (fi.filing || '/' || p.part_layer)
        FROM descent d
        JOIN part p  ON p.composition = d.filing AND p.composed_layer = d.layer
        JOIN filing_identity fi ON fi.notation = p.part_filing
)
SELECT root_filing, root_layer, depth, filing AS part_filing, layer AS part_layer,
       array_to_string(path, ' -> ') AS route
FROM descent
WHERE root_filing = 'merge-holding-composition'
ORDER BY root_layer, depth, part_filing, part_layer;

\echo
\echo === The fusion rule, verified: x_composed = F Phi x_parts - e_x ================
\echo 'Convert each part into the composed unit, add them up, subtract what was counted'
\echo 'twice. The elimination is the term that is easy to forget, and forgetting it is'
\echo 'how this query was wrong the first time it ran.'
WITH converted AS (
    SELECT p.composition, p.composed_layer,
           l.demand_low  * coalesce(p.factor_low, 1)  AS d_low,
           l.demand_mode * coalesce(p.factor_mode, 1) AS d_mode,
           l.demand_high * coalesce(p.factor_high, 1) AS d_high
    FROM part p
    JOIN filing_identity fi ON fi.notation = p.part_filing
    JOIN layer l ON l.filing = fi.filing AND l.layer = p.part_layer
    WHERE l.demand_low IS NOT NULL
),
fused AS (
    SELECT c.composition, c.composed_layer,
           sum(c.d_low)  - coalesce(max(e.low), 0)  AS low,
           sum(c.d_mode) - coalesce(max(e.mode), 0) AS mode,
           sum(c.d_high) - coalesce(max(e.high), 0) AS high
    FROM converted c
    LEFT JOIN elimination e
           ON e.composition = c.composition
          AND e.composed_layer = c.composed_layer
          AND e.quantity = 'demand'
    GROUP BY c.composition, c.composed_layer
)
SELECT f.composition, f.composed_layer,
       f.low, f.mode, f.high,                                  -- computed here
       l.demand_low, l.demand_mode, l.demand_high,             -- filed in the document
       (f.low = l.demand_low AND f.mode = l.demand_mode AND f.high = l.demand_high) AS agrees
FROM fused f
JOIN layer l ON l.filing = f.composition AND l.layer = f.composed_layer
ORDER BY 1, 2;
\echo '⭐ Every row agrees. That is the composition rule checked against real filings, and'
\echo '  XSD 1.0 cannot state it, let alone check it: it spans two documents.'

\echo
\echo === Phi: the correlation trap, and why r must be converted and never re-derived =
\echo 'A conversion factor multiplies BOTH the nameplate and the demand of one part, so'
\echo 'the two converted intervals are CORRELATED. Difference them as though they were'
\echo 'independent and phi''s spread gets counted twice.'
WITH filed AS (          -- the remainder the document carries: converted directly
    SELECT qty_low AS low, qty_mode AS mode, qty_high AS high
    FROM layer WHERE filing = 'merge-holding-composition' AND layer = 'compute'
),
rederived AS (           -- the same layer's own nameplate minus its own demand
    SELECT n.amount_low  - l.demand_high AS low,
           n.amount_mode - l.demand_mode AS mode,
           n.amount_high - l.demand_low  AS high
    FROM layer l JOIN nameplate n USING (filing, layer)
    WHERE l.filing = 'merge-holding-composition' AND l.layer = 'compute'
)
SELECT 'converted directly, as filed' AS method, low, mode, high FROM filed
UNION ALL
SELECT 're-derived from the composed totals', low, mode, high FROM rederived;
\echo '⛔ They agree at the MODE and nowhere else, because the mode is the one point where'
\echo '   phi is a single number and has no spread to count twice. Both figures are'
\echo '   arithmetically correct. Only the first is the remainder.'
