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
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
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
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
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
    -- pm:Stack/pm:Couplings/pm:Coupling, each carrying its pm:observed.
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
    -- pm:Stack/pm:Couplings/pm:Coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c

) c USING (filing)
LEFT JOIN (
    -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) s ON s.filing = f.filing
GROUP BY f.filing, s.answer

) p
ORDER BY 1;

\echo
\echo === H, who bears the remainder, and S, what each buffer holds ===================
\echo 'H is L x 5 and S is L x 3. Both are tall, and both are mostly absent.'
SELECT filing, layer, kind,
       coalesce(share_mode::text, '(' || share_absent || ')') AS share
FROM (
    -- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

) h
ORDER BY 1, 2, 3;

\echo
\echo 'S, and the count that matters is the SIZED column: a buffer nobody measured is not a'
\echo 'buffer that is empty, and only a sized row can bound anything at all. A SIZED_AT_ZERO is'
\echo 'the tightest bound there is, not a missing one, and the split is the whole point.'
\echo 'Stipulations are kept apart from observations: the fixtures file absences on purpose,'
\echo 'so pooling them would answer "how much does this corpus measure" with a made-up number.'
-- entries/slacks.sqlc by buffer, split by evidence, restricted by the caller's @scope.
SELECT s.buffer::text                                          AS buffer,
       f.evidence                                              AS evidence,
       count(*) FILTER (WHERE s.sized)                         AS sized,
       count(*) FILTER (WHERE s.sized AND s.mode = 0)          AS sized_at_zero,
       count(*) FILTER (WHERE NOT s.sized)                     AS absent,
       count(*) FILTER (WHERE s.absent = 'unmeasured')         AS nobody_measured,
       count(*) FILTER (WHERE s.absent = 'notApplicable')      AS not_applicable,
       count(*) FILTER (WHERE s.absent = 'derived')            AS derived,
       count(*)                                                AS rows
FROM      (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
JOIN      (
    -- from pm.filing, both evidence values.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f

) f USING (filing)
GROUP BY s.buffer, f.evidence
ORDER BY s.buffer, f.evidence
;

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
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) l  ON l.filing = fi.filing AND l.layer = p.part_layer

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
       'demand' AS quantity,
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
    -- asrt:Part/asrt:factor applied to the part layer's pm:Demand.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       'demand' AS quantity,
       d.d_low  * coalesce(p.factor_low, 1)  AS d_low,
       d.d_mode * coalesce(p.factor_mode, 1) AS d_mode,
       d.d_high * coalesce(p.factor_high, 1) AS d_high
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) l  ON l.filing = fi.filing AND l.layer = p.part_layer

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
    -- composition/fusions.sqlc minus the suspensions that lift the demand sum.
SELECT f.filing, f.layer, 'demand' AS quantity
FROM (
    -- distinct (composition, composedLayerName) over pm:Fusion/pm:Part.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p

) f
EXCEPT
SELECT s.composition, s.composed_layer, 'demand'
FROM (
    -- the two filings that lift the sum rule, each carrying the quantity it lifts.
-- eliminations/searched.sqlc, kept where asrt:absent/pm:reason is "unmeasured".
SELECT es.composition, es.composed_layer,
       NULL::text AS quantity,
       'the search was never made' AS suspended_because,
       es.note
FROM (
    -- asrt:Fusion/asrt:Eliminations/asrt:Absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es

) es
WHERE es.answer = 'unmeasured'
UNION ALL
-- eliminations/filed.sqlc wherever asrt:quantity takes its pm:absent branch, per quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       'the overlap was found and could not be sized' AS suspended_because,
       e.reason AS note
FROM (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e
WHERE e.absent IS NOT NULL


) s
WHERE s.quantity IS NULL OR s.quantity = 'demand'

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
LEFT JOIN (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e
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
SELECT 'converted directly, as filed'       AS method, x.qty_low, x.qty_mode, x.qty_high
FROM (
    -- layers/filed_remainders.sqlc against layers/remainder.sqlc, on the layer they share.
SELECT l.filing, l.layer,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent,
       r.r_low, r.r_mode, r.r_high, r.unit,
       r.d_low, r.d_mode, r.d_high,
       r.n_low, r.n_mode, r.n_high, r.amount_unit,
       r.sign, r.derived_fit
FROM      (
    -- pm:Layer/pm:remainder taking the pm:claim branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent
FROM pm.layer l
WHERE l.remainder_absent IS NULL

) l
JOIN      (
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

) r USING (filing, layer)

) x
WHERE x.filing = 'merge-holding-composition' AND x.layer = 'compute'
UNION ALL
SELECT 're-derived from the composed totals', x.r_low, x.r_mode, x.r_high
FROM (
    -- layers/filed_remainders.sqlc against layers/remainder.sqlc, on the layer they share.
SELECT l.filing, l.layer,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent,
       r.r_low, r.r_mode, r.r_high, r.unit,
       r.d_low, r.d_mode, r.d_high,
       r.n_low, r.n_mode, r.n_high, r.amount_unit,
       r.sign, r.derived_fit
FROM      (
    -- pm:Layer/pm:remainder taking the pm:claim branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent
FROM pm.layer l
WHERE l.remainder_absent IS NULL

) l
JOIN      (
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

) r USING (filing, layer)

) x
WHERE x.filing = 'merge-holding-composition' AND x.layer = 'compute';
\echo '⛔ They agree at the MODE and nowhere else, because the mode is the one point where'
\echo '   phi is a single number and has no spread to count twice. Both figures are'
\echo '   arithmetically correct. Only the first is the remainder.'
