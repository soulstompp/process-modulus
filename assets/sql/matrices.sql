-- The matrices from docs/linear-algebra.md, pulled out with SQL.

SET search_path TO pm, public;
\pset border 2
\pset null '·'

\echo
\echo === D, the draw matrix. Operations down, layers across. =========================
\echo 'Sparse: one row per draw. No row means that operation draws nothing from that layer.'
SELECT filing, operation, layer,
       coalesce(mode::text, '(' || absent || ')') AS entry, unit
FROM (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

) d
ORDER BY filing, operation, layer;

\echo
\echo === N, the induction matrix. Same shape, different fact. ========================
\echo 'A draw is consumption that happened. An induction is a commitment that creates a'
\echo 'future draw on a DIFFERENT supply, and only it names a decider.'
SELECT filing, operation, layer,
       coalesce(mode::text, '(' || absent || ')') AS entry, unit, decider
FROM (
    -- pm:Operation/pm:Induction, carrying pm:decider.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

) n
ORDER BY filing, operation, layer;

\echo
\echo === D-transpose times N, and why it is not what it looks like ===================
\echo 'The product is a join on the shared index (the operation) and a sum over it.'
\echo 'The join is fine and returns rows. Look at the last two columns.'
SELECT filing, drawn_from, commits, drawn, committed,
       the_unit_that_warns_you       AS unit,
       the_product_nobody_should_use AS product
FROM (
    -- the shared index is (filing, operation); pm:Operation carries both children.
SELECT d.filing, d.operation,
       d.layer AS drawn_from, d.mode AS drawn,
       n.layer AS commits,    n.mode AS committed,
       coalesce(d.unit, '(unmeasured)') || ' * '
    || coalesce(n.unit, '(unmeasured)') AS the_unit_that_warns_you,
       d.mode * n.mode                    AS the_product_nobody_should_use
FROM      (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

) d
JOIN      (
    -- pm:Operation/pm:Induction, carrying pm:decider.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

) n USING (filing, operation)

) x
ORDER BY 1, 2, 3;
\echo '⛔ TWO SEPARATE REASONS THE PRODUCT IS NOT A QUANTITY, AND BOTH ARE VISIBLE ABOVE.'
\echo '   Each layer carries its OWN unit, so an entry would come out in people*launches,'
\echo '   which is not a rate of anything. And the one operation in this corpus that both'
\echo '   draws and induces has an UNMEASURED draw, so there is no number to multiply --'
\echo '   the matrix that would show cross-layer structure is empty precisely because the'
\echo '   interesting quantity has no instrument behind it.'
\echo '   The INCIDENCE composes and gives you reachability. The QUANTITIES do not. There'
\echo '   is also no firing count per operation, deliberately, because sequence and timing'
\echo '   are BPMN''s job.'

\echo
\echo === C, the coupling matrix, and the absence that matters ========================
\echo 'C = 0 is the model ASSUMPTION. Every non-zero entry is an observation somebody made.'
SELECT filing, from_layer, to_layer, low, mode, high, unit,
       left(observation, 60) || '...' AS observed
FROM (
    -- pm:Stack/pm:Couplings/pm:Coupling, each carrying its pm:observation.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c

) c
ORDER BY filing, from_layer, to_layer;

\echo
\echo '⛔⛔ AND HERE IS WHAT THE MATRIX CANNOT SAY. A filing with no rows above has either'
\echo '    a stack of independent layers, or nobody who looked. Densify it and both become'
\echo '    a grid of 0.0 and the difference is gone for good. The answer is not in C at all;'
\echo '    it is in the SEARCH beside it, which is why that element had to exist.'
SELECT p.filing, p.couplings_filed,
       coalesce(p.search_answer::text, '(couplings are filed above)') AS what_the_search_says
FROM (
    -- pm:Stack/pm:couplings against pm:Couplings/pm:absent, over a scope the caller names.
SELECT f.filing,
       count(c.filing) AS couplings_filed,
       s.answer        AS search_answer
FROM      (
    -- from pm.filing, both evidence values.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f

) f
LEFT JOIN (
    -- pm:Stack/pm:Couplings/pm:Coupling, each carrying its pm:observation.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c

) c USING (filing)
LEFT JOIN (
    -- pm:Stack/pm:Couplings and pm:Fusion/pm:Eliminations, each with its pm:Absent.
SELECT cs.filing, 'couplings between layers' AS looked_for, '(the stack)' AS about,
       cs.absent AS answer, cs.note
FROM pm.coupling_search cs
UNION ALL
SELECT es.composition, 'double counting across parts', es.composed_layer,
       es.absent, es.note
FROM pm.elimination_search es

) s
       ON s.filing = f.filing AND s.looked_for = 'couplings between layers'
GROUP BY f.filing, s.answer

) p
ORDER BY 1;

\echo
\echo === H, who bears the remainder, and S, what each buffer holds ===================
\echo 'H is L x 5 and S is L x 3. Both are tall, and both are mostly absent.'
SELECT filing, layer, kind,
       coalesce(share_mode::text, '(' || share_absent || ')') AS share
FROM (
    -- pm:Remainder/pm:Holders; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

) h
ORDER BY 1, 2, 3;

\echo
\echo 'S, and the count that matters is the SIZED column: a buffer nobody measured is not a'
\echo 'buffer that is empty, and only a sized row can bound anything at all.'
SELECT buffer,
       count(*)                                        AS entries,
       count(*) FILTER (WHERE sized)                   AS sized,
       count(*) FILTER (WHERE absent = 'none')         AS measured_zero,
       count(*) FILTER (WHERE absent = 'unmeasured')   AS nobody_measured
FROM (
    -- pm:Layer/pm:Buffers; one element per pm:BufferKind.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
GROUP BY buffer ORDER BY buffer;

\echo
\echo === r = n - d, and the bound reversal that is easy to get wrong =================
\echo 'Subtracting intervals REVERSES the bounds: the low of n-d pairs n.low with d.HIGH.'
\echo 'Get that backwards and every remainder in the corpus comes out inside out.'
SELECT filing, layer, r_low, r_mode, r_high, unit, sign,
       derived_fit AS fit_from_the_ranges
FROM (
    -- from pm.layer and pm.nameplate; pm:Layer/pm:Remainder/sign carries the filed classification.
SELECT d.filing, d.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       d.d_low, d.d_mode, d.d_high, d.d_unit AS unit,
       n.n_low, n.n_mode, n.n_high, n.n_unit AS amount_unit,
       n.n_low  - d.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.HIGH
       n.n_mode - d.d_mode AS r_mode,
       n.n_high - d.d_low  AS r_high,
       CASE WHEN n.n_low  - d.d_high >= 0 THEN 'clearance'
            WHEN n.n_high - d.d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS derived_fit,
       greatest(d.d_high - n.n_low, 0) AS exposure,
       n.lumpy, n.quantum_mode, n.quantum_unit
FROM      (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
JOIN      (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n USING (filing, layer)
JOIN pm.layer l USING (filing, layer)

) r
ORDER BY filing, layer;
\echo '⭐ The last two columns are the filed sign and the sign recomputed from the ranges.'
\echo '  They agree for every layer that files one, which is a rule XSD 1.0 cannot express'
\echo '  at all. Where `sign` is blank the document declined to classify, and declining is'
\echo '  not disagreeing -- see assets/sqlc/layers/signed.sqlc.'

\echo
\echo === F and Phi, and the recursion the schema cannot see ==========================
\echo 'Compositions nest. Holding composes the group, which composes the members.'
SELECT root_filing, root_layer, depth, filing AS part_filing, layer AS part_layer,
       array_to_string(path, ' -> ') AS route
FROM (
    -- pm:Fusion/pm:Part followed transitively through pm.filing_identity.
WITH RECURSIVE
resolved AS (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM pm.part p

) p
JOIN pm.filing_identity fi ON fi.notation = p.part_filing
JOIN pm.layer l ON l.filing = fi.filing AND l.layer = p.part_layer

),
walk(root_filing, root_layer, filing, layer, depth, path) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               ARRAY[p.composition  || '/' || p.composed_layer,
                     p.part_filing  || '/' || p.part_layer]
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.path || (p.part_filing || '/' || p.part_layer)
        FROM walk w
        JOIN resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT * FROM walk

) d
WHERE root_filing = 'merge-holding-composition'
ORDER BY root_layer, depth, part_filing, part_layer;

\echo
\echo === The fusion rule, verified: x_composed = F Phi x_parts - e_x ================
\echo 'Convert each part into the composed unit, add them up, subtract what was counted'
\echo 'twice. The elimination is the term that is easy to forget, and forgetting it is'
\echo 'how this query was wrong the first time it ran.'
SELECT composition, composed_layer,
       computed_low, computed_mode, computed_high,   -- computed here
       filed_low, filed_mode, filed_high,            -- filed in the document
       agrees
FROM (
    -- pm:Fusion/pm:Part against the composed pm:Layer/pm:Demand, less pm:Eliminations.
SELECT c.composition, c.composed_layer,
       sum(c.d_low)  - coalesce(max(e.low),  0) AS computed_low,
       sum(c.d_mode) - coalesce(max(e.mode), 0) AS computed_mode,
       sum(c.d_high) - coalesce(max(e.high), 0) AS computed_high,
       max(d.d_low)  AS filed_low,
       max(d.d_mode) AS filed_mode,
       max(d.d_high) AS filed_high,
       (sum(c.d_low)  - coalesce(max(e.low),  0) = max(d.d_low)
    AND sum(c.d_mode) - coalesce(max(e.mode), 0) = max(d.d_mode)
    AND sum(c.d_high) - coalesce(max(e.high), 0) = max(d.d_high)) AS agrees
FROM      (
    -- pm:Part/pm:ConversionFactor applied to the part layer's pm:Demand.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       d.d_low  * coalesce(p.factor_low, 1)  AS d_low,
       d.d_mode * coalesce(p.factor_mode, 1) AS d_mode,
       d.d_high * coalesce(p.factor_high, 1) AS d_high
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM pm.part p

) p
JOIN pm.filing_identity fi ON fi.notation = p.part_filing
JOIN pm.layer l ON l.filing = fi.filing AND l.layer = p.part_layer

) p
JOIN      (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
       ON d.filing = p.part_filing AND d.layer = p.part_layer

) c
JOIN      (
    -- pm.part minus the two suspensions; see composition/suspended_fusions.sqlc.
SELECT f.filing, f.layer
FROM      (
    -- distinct (composition, composedLayerName) over pm:Fusion/pm:Part.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM pm.part p

) p

) f
LEFT JOIN (
    -- the two pm:Absent reason="unmeasured" filings that lift the sum rule.
-- pm:Fusion/pm:Eliminations with pm:Absent reason="unmeasured".
SELECT es.composition, es.composed_layer,
       'the search was never made' AS suspended_because,
       es.note
FROM pm.elimination_search es
WHERE es.absent = 'unmeasured'
UNION ALL
-- pm:Eliminations/pm:Elimination quantity="demand" with pm:Absent reason="unmeasured".
SELECT e.composition, e.composed_layer,
       'the overlap was found and could not be sized' AS suspended_because,
       e.reason AS note
FROM pm.elimination e
WHERE e.quantity = 'demand' AND e.absent = 'unmeasured'


) s
       ON s.composition = f.filing AND s.composed_layer = f.layer
WHERE s.composition IS NULL

) o
       ON o.filing = c.composition AND o.layer = c.composed_layer
JOIN      (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
       ON d.filing = c.composition AND d.layer = c.composed_layer
LEFT JOIN pm.elimination e
       ON e.composition = c.composition
      AND e.composed_layer = c.composed_layer
      AND e.quantity = 'demand'
GROUP BY c.composition, c.composed_layer

) f
ORDER BY 1, 2;
\echo '⭐ Every row agrees. A fusion that states nobody looked for double counting owes no'
\echo '  equality and is SUSPENDED rather than counted as a pass -- and so is one that found'
\echo '  the overlap and could not size it. Both grounds are in'
\echo '  assets/sqlc/composition/suspended_fusions.sqlc, which is what this query anti-joins.'
\echo '  That is the composition rule checked against real filings, and XSD 1.0 cannot state'
\echo '  it, let alone check it: it spans two documents.'

\echo
\echo === Phi: the correlation trap, and why r must be converted and never re-derived =
\echo 'A conversion factor multiplies BOTH the nameplate and the demand of one part, so'
\echo 'the two converted intervals are CORRELATED. Difference them as though they were'
\echo 'independent and phi''s spread gets counted twice.'
WITH filed AS (          -- the remainder the document carries: converted directly
    SELECT qty_low AS low, qty_mode AS mode, qty_high AS high
    FROM pm.layer WHERE filing = 'merge-holding-composition' AND layer = 'compute'
),
rederived AS (           -- the same layer's own nameplate minus its own demand
    SELECT r.r_low AS low, r.r_mode AS mode, r.r_high AS high
    FROM (
        -- from pm.layer and pm.nameplate; pm:Layer/pm:Remainder/sign carries the filed classification.
SELECT d.filing, d.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       d.d_low, d.d_mode, d.d_high, d.d_unit AS unit,
       n.n_low, n.n_mode, n.n_high, n.n_unit AS amount_unit,
       n.n_low  - d.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.HIGH
       n.n_mode - d.d_mode AS r_mode,
       n.n_high - d.d_low  AS r_high,
       CASE WHEN n.n_low  - d.d_high >= 0 THEN 'clearance'
            WHEN n.n_high - d.d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS derived_fit,
       greatest(d.d_high - n.n_low, 0) AS exposure,
       n.lumpy, n.quantum_mode, n.quantum_unit
FROM      (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
JOIN      (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n USING (filing, layer)
JOIN pm.layer l USING (filing, layer)

    ) r
    WHERE r.filing = 'merge-holding-composition' AND r.layer = 'compute'
)
SELECT 'converted directly, as filed' AS method, low, mode, high FROM filed
UNION ALL
SELECT 're-derived from the composed totals', low, mode, high FROM rederived;
\echo '⛔ They agree at the MODE and nowhere else, because the mode is the one point where'
\echo '   phi is a single number and has no spread to count twice. Both figures are'
\echo '   arithmetically correct. Only the first is the remainder.'
