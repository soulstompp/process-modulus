-- The rules XSD 1.0 cannot reach, as ONE query.
--
--   psql -f assets/sql/schema.ddl -f assets/sql/ingest.sql -f assets/sql/rules.sql
--
-- ⭐⭐ WHY THIS FILE EXISTS. Forty-one rules in this model are stated in the schemas'
--    own prose and gated by nothing, because XSD 1.0 has no `xs:assert` and cannot
--    compare one element against another. Look at what they actually ARE, though:
--    "the shares sum to the magnitude", "the sign agrees with the range comparison",
--    "no leaf is reachable by two paths". Those are joins, aggregates and comparisons.
--    They are unreachable in a grammar and ordinary in a query language.
--
-- ⭐ EMPTY OUTPUT MEANS EVERY RULE HELD. Each branch below returns VIOLATIONS, so a
--   clean run prints nothing but the summary. A rule that can return nothing because
--   its inputs are missing is reported as `n/a` rather than as a pass, which is the
--   whole vacuity argument in one column.

SET search_path TO pm, public;
\pset border 2
\pset null '·'

\echo
\echo === Violations. An empty table is the good outcome. ============================

WITH
-- Every layer that carries both a demand and a nameplate, with the remainder derived.
-- Note the crossed subscripts: subtracting intervals REVERSES the bounds.
base AS (
    SELECT l.filing, l.layer, l.sign, l.absorber_taxonomy, l.absorber_value,
           l.demand_low  AS d_low,  l.demand_mode  AS d_mode,  l.demand_high AS d_high,
           l.demand_unit AS unit,
           n.amount_low  AS n_low,  n.amount_mode  AS n_mode,  n.amount_high AS n_high,
           n.amount_low - l.demand_high AS r_low,
           n.amount_mode - l.demand_mode AS r_mode,
           n.amount_high - l.demand_low  AS r_high,
           n.lumpy, n.quantum_mode, n.quantum_unit, n.amount_unit
    FROM layer l JOIN nameplate n USING (filing, layer)
    WHERE l.demand_low IS NOT NULL AND n.amount_low IS NOT NULL
),

-- ⭐⭐ A COUPLING PROPAGATES THROUGH A FUSION AND ATTENUATES. If layer A is coupled to
--    layer B, and A is fused into a bigger layer one level up, the coupling survives but
--    weakens: the composed layer is only partly A, so at most A's SHARE of it can move.
--    ⛔ Not derivable, and that is the point of checking it — a filer could put anything
--    here, and the ceiling comes from two other documents.
attenuation AS (
    SELECT up.filing AS upper_filing, up.from_layer, up.to_layer,
           lo.filing AS lower_filing,
           lo.low  * (pl.demand_low  / cl.demand_low)  AS ceil_low,
           lo.mode * (pl.demand_mode / cl.demand_mode) AS ceil_mode,
           lo.high * (pl.demand_high / cl.demand_high) AS ceil_high,
           up.low, up.mode, up.high
    FROM coupling up
    JOIN part pf  ON pf.composition = up.filing AND pf.composed_layer = up.from_layer
    JOIN filing_identity ff ON ff.notation = pf.part_filing
    JOIN coupling lo ON lo.filing = ff.filing AND lo.from_layer = pf.part_layer
    JOIN part pt  ON pt.composition = up.filing AND pt.composed_layer = up.to_layer
                 AND pt.part_layer = lo.to_layer
    JOIN layer pl ON pl.filing = ff.filing AND pl.layer = pf.part_layer
    JOIN layer cl ON cl.filing = up.filing  AND cl.layer = up.from_layer
    WHERE up.mode IS NOT NULL AND lo.mode IS NOT NULL
),
coupling_does_not_attenuate AS (
    SELECT 'a coupling attenuates through a fusion, bounded by the part''s share' AS rule,
           upper_filing AS filing, from_layer AS layer,
           format('%s->%s files %s at the mode, and %s''s share of it caps that at %s',
                  from_layer, to_layer, mode, lower_filing, round(ceil_mode, 3)) AS detail
    FROM attenuation
    WHERE low > ceil_low + 1e-9 OR mode > ceil_mode + 1e-9 OR high > ceil_high + 1e-9
),

-- ⚠️ A COUPLING WHOSE TWO ENDS FUSE INTO ONE LAYER IS ABSORBED BY THAT FUSION, and the
--    fusion owes a sentence saying so. Whether it said so is prose and unreachable here.
--    WHICH couplings are in that position is not, so they are reported for a person.
absorbed_by_a_fusion AS (
    SELECT 'a fusion absorbing a coupling between its own parts must say so' AS rule,
           c.filing, c.from_layer AS layer,
           format('%s->%s is internal to %s/%s once fused; check that fusion says so',
                  c.from_layer, c.to_layer, a.composition, a.composed_layer) AS detail
    FROM coupling c
    JOIN filing_identity fi ON fi.filing = c.filing
    JOIN part a ON a.part_filing = fi.notation AND a.part_layer = c.from_layer
    JOIN part b ON b.composition = a.composition AND b.composed_layer = a.composed_layer
               AND b.part_filing = fi.notation AND b.part_layer = c.to_layer
),

-- ⛔ A POINT VALUE HAS NO RANGE TO TIGHTEN, so a stated narrowing on one is either a paste
--    or a claim filed at the wrong width. `notApplicable` is the filing that says so.
narrows_a_point_value AS (
    SELECT 'a point value files narrowsWhen as notApplicable, having no range' AS rule,
           filing, layer,
           'demand is a point value and still names what would narrow it' AS detail
    FROM layer
    WHERE demand_low IS NOT NULL AND demand_low = demand_high AND demand_narrows IS NOT NULL
),

-- ⚠️ AND THE MIRROR: a RANGE that files `notApplicable` is claiming it has no range.
range_says_no_range AS (
    SELECT 'a ranged claim does not file narrowsWhen as notApplicable' AS rule,
           filing, layer,
           format('demand spans %s to %s yet says there is no range to narrow',
                  demand_low, demand_high) AS detail
    FROM layer
    WHERE demand_low IS NOT NULL AND demand_low <> demand_high
      AND demand_narrows_absent = 'notApplicable'
),

-- ⛔ THE FIT IS A COMPARISON OF TWO RANGES, NOT TWO POINTS. ISO 286's own criterion.
-- ⛔⛔⛔ `sign IS NOT NULL` IS NOT DEFENSIVE PADDING, AND THE FIXTURE FOUND IT. This rule
--    ran against 21 corpus layers that all FILE a sign, so it had never met an absence -- and
--    `assets/corpus/` files none at all, which is a dark state `tests/state_coverage.rs` now
--    names. The first document to file `sign absent reason="derived"` was reported as a
--    violation for disagreeing with a comparison it had explicitly declined to make.
--
-- ⭐ A DERIVED SIGN CANNOT DISAGREE WITH THE DERIVATION. That is what `derived` means: the
--    receiver computes it, and sending a value would be the thing that could contradict the
--    inputs. `unmeasured` and `notApplicable` cannot disagree either -- there is nothing filed
--    to compare. Only a STATED sign can be wrong, which is the whole population of this rule.
fit_disagrees AS (
    SELECT 'sign agrees with the range comparison' AS rule, filing, layer,
           format('filed %s, ranges say %s', sign,
                  CASE WHEN r_low >= 0 THEN 'clearance'
                       WHEN r_high <= 0 THEN 'interference'
                       ELSE 'transition' END) AS detail
    FROM base
    WHERE sign IS NOT NULL
      AND sign IS DISTINCT FROM (CASE WHEN r_low >= 0 THEN 'clearance'
                                      WHEN r_high <= 0 THEN 'interference'
                                      ELSE 'transition' END)::fit
),

-- The shares sum to |n - d|, WHEREVER EVERY SHARE IS STATED. One unstated share
-- suspends the check rather than breaking it: the sum is unknown, not wrong.
share_sums AS (
    SELECT b.filing, b.layer,
           abs(b.r_mode)                       AS magnitude,
           sum(h.share_mode)                   AS shares,
           count(*) FILTER (WHERE h.share_mode IS NULL) AS unstated
    FROM base b JOIN holder h USING (filing, layer)
    GROUP BY b.filing, b.layer, b.r_mode
),
shares_do_not_sum AS (
    SELECT 'stated shares sum to the magnitude' AS rule, filing, layer,
           format('shares %s against a magnitude of %s', shares, magnitude) AS detail
    FROM share_sums WHERE unstated = 0 AND abs(shares - magnitude) > 1e-9
),

-- ⭐ A supply whose capacity slack is a MEASURED ZERO cannot have absorbed what it
--   could not serve, so that demand went unserved and the unserved share must appear.
--   `customer` and `unrealised` are the two that bear demand nobody served.
-- ⛔⛔ A MEASURED ZERO HAS TWO SPELLINGS AND THIS USED TO SEE ONLY ONE. The schema's
--     idiom is `absent reason="none"` — "somebody looked and it is zero" — but nothing
--     forbids stating it as a claim of [0, 0, 0], which asserts the same fact. Keying on
--     the absence alone silently skipped every filer who chose the other spelling, and a
--     rule that skips is indistinguishable from a rule that passes.
--  ⭐ EXACTLY ZERO IS ITS OWN TERRITORY, and it is the territory these rules are about:
--     a supply with no room above its rating is the case where nothing could be absorbed.
cannot_run_hot AS (
    SELECT b.*, greatest(b.d_high - b.n_low, 0) AS exposure
    FROM base b JOIN slack s USING (filing, layer)
    WHERE s.buffer = 'capacity'
      AND (s.absent = 'none' OR (s.high IS NOT NULL AND s.high = 0))
),

-- ⚠️ AND THE TWO SPELLINGS THEMSELVES ARE WORTH REPORTING, because a receiver comparing
--    two filings cannot treat them as the same field. This is not stated as a rule anywhere
--    in the schema; it is reported here so somebody can decide whether it should be.
zero_stated_as_a_claim AS (
    SELECT 'a measured zero is filed as an absence, not as a claim of zero' AS rule,
           filing, layer,
           format('%s slack stated as [0,0,0] where the idiom is absent reason="none"', buffer) AS detail
    FROM slack WHERE high IS NOT NULL AND high = 0
),
nobody_named_as_unserved AS (
    SELECT 'a supply that cannot run hot names who went unserved' AS rule,
           c.filing, c.layer,
           format('%s could not be served and no holder says so', c.exposure) AS detail
    FROM cannot_run_hot c
    WHERE c.exposure > 1e-9
      AND NOT EXISTS (SELECT 1 FROM holder h
                      WHERE h.filing = c.filing AND h.layer = c.layer
                        AND h.kind IN ('customer', 'unrealised'))
),

-- ⭐⭐ THE ONE PLACE THE MODEL MEASURES SOMETHING WITH NO INSTRUMENT BEHIND IT.
--    What your own numbers say could have gone unserved is at most what the supply
--    can absorb plus what you admit went unserved. Evaluated at the high corner,
--    because the two sides of a transition fit are anti-correlated and anything
--    summed across the demand range reports a week that never happened.
exposure_unaccounted AS (
    SELECT 'exposure does not exceed slack plus unserved shares' AS rule,
           c.filing, c.layer,
           format('exposure %s, absorbable 0, unserved %s', c.exposure,
                  coalesce(u.unserved, 0)) AS detail
    FROM cannot_run_hot c
    LEFT JOIN (SELECT filing, layer, sum(share_high) AS unserved,
                      count(*) FILTER (WHERE share_high IS NULL) AS unstated
               FROM holder WHERE kind IN ('customer', 'unrealised')
               GROUP BY filing, layer) u USING (filing, layer)
    WHERE c.exposure > coalesce(u.unserved, 0) + 1e-9
      AND coalesce(u.unstated, 0) = 0
),

-- A holder's share does not exceed the slack of the buffer its absorber names, on the
-- interference side, with `unrealised` exempt because it is the overflow. ⛔ Note the
-- join through `buffer_term`: the absorber is a BORROWED value and turning it into one
-- of the three structural buffers is the reader's assertion, not the document's.
borne AS (
    SELECT b.filing, b.layer, bt.buffer,
           sum(h.share_mode) FILTER (WHERE h.kind <> 'unrealised') AS borne
    FROM base b
    JOIN buffer_term bt ON bt.taxonomy = b.absorber_taxonomy AND bt.value = b.absorber_value
    JOIN holder h USING (filing, layer)
    WHERE b.sign IN ('interference', 'transition')
    GROUP BY b.filing, b.layer, bt.buffer
),
share_exceeds_slack AS (
    SELECT 'a share does not exceed the slack of the buffer that absorbed it' AS rule,
           b.filing, b.layer,
           format('%s attributed to the %s buffer, whose slack is %s', b.borne, b.buffer, s.mode) AS detail
    FROM borne b JOIN slack s USING (filing, layer, buffer)
    WHERE s.mode IS NOT NULL AND b.borne > s.mode + 1e-9
),

-- A slack is compared against holder shares, so it must be in the same unit.
slack_unit_mismatch AS (
    SELECT 'a slack is expressed in the unit of the shares it bounds' AS rule,
           s.filing, s.layer,
           format('slack in %s, shares in %s', s.unit, h.share_unit) AS detail
    FROM slack s JOIN holder h USING (filing, layer)
    WHERE s.unit IS NOT NULL AND h.share_unit IS NOT NULL AND s.unit <> h.share_unit
),

-- A quantum's size is expressed in the unit of the nameplate it divides.
quantum_unit_mismatch AS (
    SELECT 'a quantum is expressed in the unit of the nameplate it divides' AS rule,
           filing, layer, format('quantum in %s, nameplate in %s', quantum_unit, amount_unit) AS detail
    FROM base WHERE lumpy AND quantum_unit IS DISTINCT FROM amount_unit
),

-- Supply arrives in whole units, so the nameplate is a whole multiple of the quantum.
nameplate_not_a_multiple AS (
    SELECT 'the nameplate is a whole multiple of the quantum' AS rule,
           filing, layer, format('%s does not divide %s', quantum_mode, n_mode) AS detail
    FROM base
    WHERE lumpy AND quantum_mode > 0 AND abs(n_mode - quantum_mode * round(n_mode / quantum_mode)) > 1e-9
),

-- Clearance across the whole range rules out the two unserved holders: with the
-- nameplate above demand everywhere, there is no unmet demand for them to bear.
clearance_with_unserved AS (
    SELECT 'a clearance fit rules out customer and unrealised' AS rule,
           b.filing, b.layer, format('%s holder under a clearance fit', h.kind) AS detail
    FROM base b JOIN holder h USING (filing, layer)
    WHERE b.sign = 'clearance' AND h.kind IN ('customer', 'unrealised')
),

-- A part reference that resolves to nothing. ⛔ This can only be checked because a
-- READER asserted the notation-to-document mapping; no filing declares its own.
unresolved_part AS (
    SELECT 'a part reference resolves to a filing that is here' AS rule,
           p.composition, p.composed_layer,
           format('%s / %s resolves to nothing', p.part_filing, p.part_layer) AS detail
    FROM part p
    LEFT JOIN filing_identity fi ON fi.notation = p.part_filing
    LEFT JOIN layer l ON l.filing = fi.filing AND l.layer = p.part_layer
    WHERE l.layer IS NULL
),


-- ⭐⭐⭐ THE FOUR RULES THE PATTERN 1 CLEANUP MADE WRITABLE. Every one of them existed in
--    prose in the XSD and none could be checked, because in each case the state it turns
--    on was encoded as a blank -- an empty list, a missing element, an omitted enum -- and
--    a blank has no reason attached to group by.
--
-- ⛔ A WINDOW IS CARRIED THROUGH A FUSION AND NEVER SUMMED. `Divisibility/window` says it:
--    "Two members naming one machine file one calendar between them; summing gives ten days
--    a week." Both halves were unenforceable while a dropped window and a supply that runs
--    continuously were the same document -- and the holding level HAD dropped one.
window_lost_or_summed AS (
    SELECT 'a window is carried through a fusion and never summed' AS rule,
           p.composition AS filing, p.composed_layer AS layer,
           CASE WHEN cn.window_low IS NULL
                THEN format('the part %s/%s files a %s-%s duty cycle and the composed layer '
                            'files `%s`', pn.filing, pn.layer, pn.window_low, pn.window_unit,
                            cn.window_absent)
                ELSE format('composed window %s against a part''s %s -- carried, never summed',
                            cn.window_low, pn.window_low)
           END AS detail
    FROM part p
    JOIN filing_identity fi ON fi.notation = p.part_filing
    JOIN nameplate pn ON pn.filing = fi.filing AND pn.layer = p.part_layer
    JOIN nameplate cn ON cn.filing = p.composition AND cn.layer = p.composed_layer
    WHERE pn.window_low IS NOT NULL
      AND (cn.window_low IS NULL OR cn.window_low <> pn.window_low)
),

-- ⛔ A TIME SLACK CANNOT BE DERIVED FROM A CLEARANCE WHERE THE SUPPLY IS INTERMITTENT, or
--    where nobody has said it is not. `q / clearance` assumes the spare is spread evenly
--    across the denominator; a window is the statement that it is not, and `unmeasured` is
--    the statement that nobody knows -- which is an assumption wearing a computation's
--    clothes. Only `none` and `notApplicable` license the derivation.
derived_slack_over_a_window AS (
    SELECT 'a derived time slack needs a window that permits the derivation' AS rule,
           n.filing, n.layer,
           format('timeSlack is `derived` and the window is %s',
                  coalesce(n.window_absent::text,
                           format('%s %s', n.window_low, n.window_unit))) AS detail
    FROM nameplate n
    JOIN slack s ON s.filing = n.filing AND s.layer = n.layer AND s.buffer = 'time'
    WHERE s.absent = 'derived'
      AND (n.window_low IS NOT NULL OR n.window_absent = 'unmeasured')
),

-- ⛔ THE WINDOW QUESTION IS MALFORMED ONLY WHERE THE UNIT HAS NO DENOMINATOR. `12 people`
--    has no period, so "5 days" has nothing to be five days of. A unit that DOES have one
--    can be answered, and `notApplicable` there is a refusal dressed as a category error.
window_not_applicable_on_a_rate AS (
    SELECT 'a window is notApplicable only where the unit has no denominator' AS rule,
           filing, layer,
           format('%s has a denominator, so the duty cycle question is answerable',
                  amount_unit) AS detail
    FROM nameplate
    WHERE window_absent = 'notApplicable'
      AND (amount_unit LIKE '%% per %%' OR amount_unit LIKE '%% por %%')
),

-- ⛔ A FUSION THAT CALLS DOUBLE COUNTING MALFORMED MUST HAVE ONE PART. Between a set of one
--    nothing can be counted twice; between two or more the question has a population and
--    `notApplicable` is a claim that two supplies cannot overlap, which is a judgement and
--    belongs in `observed`.
elimination_not_applicable_with_parts AS (
    SELECT 'a fusion calls double counting malformed only when it has one part' AS rule,
           es.composition AS filing, es.composed_layer AS layer,
           format('%s parts and the search is `notApplicable`', count(p.*)) AS detail
    FROM elimination_search es
    JOIN part p ON p.composition = es.composition AND p.composed_layer = es.composed_layer
    WHERE es.absent = 'notApplicable'
    GROUP BY es.composition, es.composed_layer
    HAVING count(p.*) > 1
),


-- ⭐⭐⭐ THE RULES THAT ARRIVED WITH LOCAL COMPOSITION, AND NEITHER IS REACHABLE BY A
--    VALIDATOR. A part whose notation is its own composition's names a layer THIS composer
--    built. XSD 1.0 cannot make a keyref conditional on another field's value, so
--    `composedLayerName` cannot be pointed at it -- and it cannot see a cycle at all.
--
-- ⛔ FIRST: a local part must name a layer that is actually in this document's stack. A
--    foreign part pointing at nothing is unresolvable and forgivable; a LOCAL one pointing
--    at nothing is a document contradicting itself in a single file.
local_part_dangles AS (
    SELECT 'a local part names a layer in its own stack' AS rule,
           p.composition AS filing, p.composed_layer AS layer,
           format('local part `%s` is not a layer of this filing', p.part_layer) AS detail
    FROM part p
    JOIN filing_identity fi ON fi.filing = p.composition AND fi.notation = p.part_filing
    LEFT JOIN layer l ON l.filing = p.composition AND l.layer = p.part_layer
    WHERE l.layer IS NULL
),

-- ⛔⛔ SECOND, AND IT IS THE ONE THAT WOULD HANG A READER: LOCAL PARTS MUST NOT CYCLE.
--    Layer A composed from B while B is composed from A is a document with no arithmetic in
--    it at all -- every figure depends on itself. Foreign parts cannot do this within one
--    document; local ones can, which is the cost of the capability.
--
-- ⭐ The walk below is bounded at depth 8 for the same reason `descent` is: an unbounded
--    recursive CTE over a cyclic graph does not return. Reaching the bound IS the finding.
local_cycle AS (
    WITH RECURSIVE walk(filing, root, layer, depth) AS (
            SELECT p.composition, p.composed_layer, p.part_layer, 1
            FROM part p
            JOIN filing_identity fi
              ON fi.filing = p.composition AND fi.notation = p.part_filing
        UNION ALL
            SELECT w.filing, w.root, p.part_layer, w.depth + 1
            FROM walk w
            JOIN part p ON p.composition = w.filing AND p.composed_layer = w.layer
            JOIN filing_identity fi
              ON fi.filing = p.composition AND fi.notation = p.part_filing
            WHERE w.depth < 8
    )
    SELECT 'local parts do not cycle' AS rule,
           filing, root AS layer,
           format('`%s` is reachable from itself through local parts', root) AS detail
    FROM walk
    WHERE layer = root
),

-- ⛔⛔⛔ A RULE THAT WAS WRITTEN HERE AND WITHDRAWN, RECORDED BECAUSE THE MISTAKE IS THE
--    POINT. It fired when a composition composed FROM a `complete` stack without carrying
--    every one of its layers -- 13 violations on the first run, every one of them wrong.
--
-- ⭐ A composition is free to carry a subset. `complete` says THE SYSTEM has no other layers;
--    it says nothing about what any reader must take. Conflating the two is exactly the
--    confusion `scope` was added to end: it punishes the selective reading that scope exists
--    to make ordinary. The rule was the model picking a fight on the composer's behalf.
--
-- ⚠️ AND WHAT WOULD ACTUALLY FALSIFY `complete` IS NOT REACHABLE FROM HERE. It is another
--    filing holding a layer OF THE SAME SYSTEM that this one lacks -- and no document names a
--    system, only a filing. So `complete` is falsifiable in principle and by nothing in this
--    corpus, which belongs in conformance/README.md's owed list rather than as a query that
--    looks like it checks something.

-- ⭐⭐⭐ THE ONE NO VALIDATOR CAN SEE. At one level "no part used twice" is a key.
--    At two it becomes "no leaf reachable by two paths", and the second path runs
--    through a document the first does not contain. A recursive CTE walks it.
descent AS (
    WITH RECURSIVE walk(root_filing, root_layer, filing, layer, depth) AS (
            SELECT p.composition, p.composed_layer, fi.filing, p.part_layer, 1
            FROM part p JOIN filing_identity fi ON fi.notation = p.part_filing
        UNION ALL
            SELECT w.root_filing, w.root_layer, fi.filing, p.part_layer, w.depth + 1
            FROM walk w
            JOIN part p ON p.composition = w.filing AND p.composed_layer = w.layer
            JOIN filing_identity fi ON fi.notation = p.part_filing
            WHERE w.depth < 10          -- a cycle would otherwise run for ever
    )
    SELECT * FROM walk
),
leaf AS (   -- a reached layer that is not itself composed of anything
    SELECT d.* FROM descent d
    WHERE NOT EXISTS (SELECT 1 FROM part p
                      WHERE p.composition = d.filing AND p.composed_layer = d.layer)
),
leaf_reached_twice AS (
    SELECT 'no leaf layer is reachable through two paths' AS rule,
           root_filing AS filing, root_layer AS layer,
           format('%s/%s reached %s times', filing, layer, count(*)) AS detail
    FROM leaf
    GROUP BY root_filing, root_layer, filing, layer
    HAVING count(*) > 1
)

SELECT * FROM fit_disagrees
UNION ALL SELECT * FROM shares_do_not_sum
UNION ALL SELECT * FROM nobody_named_as_unserved
UNION ALL SELECT * FROM exposure_unaccounted
UNION ALL SELECT * FROM zero_stated_as_a_claim
UNION ALL SELECT * FROM share_exceeds_slack
UNION ALL SELECT * FROM slack_unit_mismatch
UNION ALL SELECT * FROM quantum_unit_mismatch
UNION ALL SELECT * FROM nameplate_not_a_multiple
UNION ALL SELECT * FROM clearance_with_unserved
UNION ALL SELECT * FROM unresolved_part
UNION ALL SELECT * FROM leaf_reached_twice
UNION ALL SELECT * FROM coupling_does_not_attenuate
UNION ALL SELECT * FROM narrows_a_point_value
UNION ALL SELECT * FROM range_says_no_range
UNION ALL SELECT * FROM window_lost_or_summed
UNION ALL SELECT * FROM derived_slack_over_a_window
UNION ALL SELECT * FROM window_not_applicable_on_a_rate
UNION ALL SELECT * FROM elimination_not_applicable_with_parts
UNION ALL SELECT * FROM local_part_dangles
UNION ALL SELECT * FROM local_cycle
ORDER BY 1, 2, 3;

\echo
\echo === Referrals. ⚠️ Not violations: things a QUERY can find and only a PERSON can settle. =
\echo 'Detecting the structure is mechanical. Judging the prose is not, so these are handed over'
\echo 'rather than passed or failed. A clean run has rows here and that is correct.'
WITH absorbed AS (
    SELECT c.filing, c.from_layer, c.to_layer, a.composition, a.composed_layer
    FROM coupling c
    JOIN filing_identity fi ON fi.filing = c.filing
    JOIN part a ON a.part_filing = fi.notation AND a.part_layer = c.from_layer
    JOIN part b ON b.composition = a.composition AND b.composed_layer = a.composed_layer
               AND b.part_filing = fi.notation AND b.part_layer = c.to_layer
)
SELECT 'a fusion absorbing a coupling between its own parts must say so' AS referral,
       filing, from_layer || ' -> ' || to_layer AS coupling,
       composition || '/' || composed_layer AS absorbed_into
FROM absorbed ORDER BY 2, 3;

\echo
\echo '⭐ And what a receiver is entitled to say about narrowsWhen, as a number rather than'
\echo '  an opinion. The annotation: "a claim without it is weaker, and a receiver is'
\echo '  entitled to say so". Judging whether the sentence would ACTUALLY narrow the range'
\echo '  is prose. Counting which ranges decline to say anything is not.'
SELECT count(*) FILTER (WHERE demand_low <> demand_high)                        AS ranged_demands,
       count(*) FILTER (WHERE demand_low <> demand_high AND demand_narrows IS NULL) AS say_nothing,
       round(100.0 * count(*) FILTER (WHERE demand_low <> demand_high AND demand_narrows IS NULL)
             / nullif(count(*) FILTER (WHERE demand_low <> demand_high), 0)) AS pct
FROM layer WHERE demand_low IS NOT NULL;

\echo
\echo '⭐⭐ AND THE GRAIN QUESTION, ANSWERABLE FOR THE FIRST TIME. How much of the width in'
\echo '   this corpus is IGNORANCE (a better instrument reveals it) and how much is the'
\echo '   world actually MOVING (only changing the process reduces it)? Before narrowsWhen'
\echo '   carried a kind there was nothing to group by, and the schema simply asserted the'
\echo '   first reading throughout.'
SELECT CASE
         WHEN kind = 'instrument'    THEN 'ignorance: measure it better'
         WHEN kind = 'intervention'  THEN 'VARIATION: only changing the process helps'
         WHEN kind = 'experiment'    THEN 'unknown, deliberately: an experiment would say'
         WHEN absent = 'none'        THEN 'VARIATION: somebody looked, nothing would narrow it'
         WHEN absent = 'notApplicable' THEN 'no range to narrow (a point value)'
         ELSE 'nobody has said'
       END AS what_the_width_is_made_of,
       count(*)
FROM narrowing GROUP BY 1 ORDER BY 2 DESC;

\echo
\echo
\echo '⛔⛔⛔ HAS ANYBODY TESTED THE MODEL? The single most important number in this file, and'
\echo '   it was unaskable until `Stack/couplings` stopped being an empty list. `pm:Coupling`'
\echo '   says a document with no couplings "is not evidence of independence; it is a document'
\echo '   where nobody looked" -- and for two revisions the element it says that about could'
\echo '   only write the ambiguous thing. This is a fact about THE EVIDENCE rather than about'
\echo '   any one filing, which is why it is a report and not a rule.'
SELECT CASE
         WHEN cs.absent IS NULL THEN 'somebody looked and the layers MOVE TOGETHER'
         WHEN cs.absent = 'none' THEN 'somebody looked and found independence'
         WHEN cs.absent = 'notApplicable' THEN 'one layer; no pair to couple'
         ELSE 'NOBODY LOOKED'
       END AS the_independence_assumption,
       count(*) AS stacks
FROM coupling_search cs
JOIN filing f ON f.name = cs.filing
-- ⛔⛔ CORPUS ONLY. This is a REPORT about the state of the evidence, not a rule, and
-- assets/fixtures/every-absence.xml asserts independence on purpose to prove the branch
-- works. Counting a stipulation here would turn the finding into a lie.
WHERE f.evidence = 'corpus'
GROUP BY 1 ORDER BY 2 DESC;

\echo
\echo '⭐⭐ WHO OWNS THE EDGE, BESIDE WHAT WOULD NARROW IT. The pair is the point: narrowsWhen'
\echo '   says what would make a range SMALLER, boundOrigin says who owns the edge it would'
\echo '   move. As an optional bare enumeration it was filed ONCE in 124 claims; required and'
\echo '   typed, the commonest answer turns out to be that the model ALREADY states the author'
\echo '   in a sibling element and had no way to point at it.'
SELECT CASE
         WHEN origin IS NOT NULL THEN 'somebody owns it: ' || origin::text
         WHEN absent = 'derived' THEN 'stated in a sibling element (amountOrigin, quantum origin)'
         WHEN absent = 'none' THEN 'NOTHING sets it -- the range is where the measurements fell'
         WHEN absent = 'unmeasured' THEN 'nobody has asked'
         ELSE 'not a bound on a committed quantity'
       END AS who_owns_the_edge,
       count(*) AS claims
FROM bound_origin b JOIN filing f ON f.name = b.filing
WHERE f.evidence = 'corpus'   -- a report about the corpus, not about the fixtures
GROUP BY 1 ORDER BY 2 DESC;

\echo
\echo '⭐ DID THE COMPOSER LOOK FOR DOUBLE COUNTING? Same shape, one document up -- and the'
\echo '  answer decides which arithmetic is owed. `none` or `notApplicable`: the composed'
\echo '  figure must equal the sum of its converted parts EXACTLY. `unmeasured`: no equality'
\echo '  is owed at all, and a checker reporting one is reporting about nothing.'
SELECT coalesce(absent::text, 'eliminations filed') AS the_search,
       count(*) AS fusions,
       CASE WHEN absent = 'unmeasured' THEN 'sum rule SUSPENDED'
            ELSE 'sum rule exact' END AS what_is_owed
FROM elimination_search es JOIN filing f ON f.name = es.composition
WHERE f.evidence = 'corpus'   -- a report about the corpus, not about the fixtures
GROUP BY 1, 3 ORDER BY 2 DESC;

\echo === Coverage. ⛔ A rule that examined nothing is not a rule that passed. =========
\echo 'This repository names the trap: "a bound with nothing to bound passes loudest".'
\echo 'An empty violations table above is worth exactly as much as this table says.'
WITH base AS (
    SELECT l.filing, l.layer, l.sign,
           n.amount_low - l.demand_high AS r_low,
           n.amount_high - l.demand_low AS r_high,
           greatest(l.demand_high - n.amount_low, 0) AS exposure,
           n.lumpy
    FROM layer l JOIN nameplate n USING (filing, layer)
    WHERE l.demand_low IS NOT NULL AND n.amount_low IS NOT NULL
)
SELECT rule, examined,
       CASE WHEN examined = 0 THEN '⛔ VACUOUS - proves nothing'
            WHEN examined < 3 THEN '⚠️  thin'
            ELSE 'ok' END AS verdict
FROM (
    SELECT 'sign agrees with the range comparison' AS rule, count(*) AS examined FROM base
    UNION ALL SELECT 'stated shares sum to the magnitude',
        (SELECT count(*) FROM (SELECT b.filing, b.layer FROM base b JOIN holder h USING (filing, layer)
          GROUP BY b.filing, b.layer HAVING count(*) FILTER (WHERE h.share_mode IS NULL) = 0) z)
    UNION ALL SELECT 'a supply that cannot run hot names who went unserved',
        (SELECT count(*) FROM base b JOIN slack s USING (filing, layer)
          WHERE s.buffer='capacity' AND (s.absent='none' OR s.high = 0) AND b.exposure > 1e-9)
    UNION ALL SELECT 'exposure does not exceed slack plus unserved shares',
        (SELECT count(*) FROM base b JOIN slack s USING (filing, layer)
          WHERE s.buffer='capacity' AND (s.absent='none' OR s.high = 0) AND b.exposure > 1e-9)
    UNION ALL SELECT 'a share does not exceed the slack of the buffer that absorbed it',
        (SELECT count(*) FROM base b
           JOIN layer l USING (filing, layer)
           JOIN buffer_term bt ON bt.taxonomy=l.absorber_taxonomy AND bt.value=l.absorber_value
           JOIN slack s ON s.filing=b.filing AND s.layer=b.layer AND s.buffer=bt.buffer
          WHERE b.sign IN ('interference','transition') AND s.mode IS NOT NULL)
    UNION ALL SELECT 'a slack is expressed in the unit of the shares it bounds',
        (SELECT count(*) FROM slack s JOIN holder h USING (filing, layer)
          WHERE s.unit IS NOT NULL AND h.share_unit IS NOT NULL)
    UNION ALL SELECT 'a quantum is expressed in the unit of the nameplate it divides',
        (SELECT count(*) FROM base WHERE lumpy)
    UNION ALL SELECT 'the nameplate is a whole multiple of the quantum',
        (SELECT count(*) FROM base WHERE lumpy)
    UNION ALL SELECT 'a clearance fit rules out customer and unrealised',
        (SELECT count(*) FROM base WHERE sign='clearance')
    UNION ALL SELECT 'a measured zero is filed as an absence, not as a claim of zero',
        (SELECT count(*) FROM slack WHERE high IS NOT NULL)
    UNION ALL SELECT 'a coupling attenuates through a fusion, bounded by the part''s share',
        (SELECT count(*) FROM coupling up JOIN part pf
           ON pf.composition = up.filing AND pf.composed_layer = up.from_layer
          WHERE up.mode IS NOT NULL)
    UNION ALL SELECT 'a fusion absorbing a coupling between its own parts must say so',
        (SELECT count(*) FROM coupling)
    UNION ALL SELECT 'a point value files narrowsWhen as notApplicable, having no range',
        (SELECT count(*) FROM layer WHERE demand_low IS NOT NULL AND demand_low = demand_high)
    UNION ALL SELECT 'a ranged claim does not file narrowsWhen as notApplicable',
        (SELECT count(*) FROM layer WHERE demand_low IS NOT NULL AND demand_low <> demand_high)
    UNION ALL SELECT 'a part reference resolves to a filing that is here',
        (SELECT count(*) FROM part)
    UNION ALL SELECT 'a window is carried through a fusion and never summed',
        (SELECT count(*) FROM part p
           JOIN filing_identity fi ON fi.notation = p.part_filing
           JOIN nameplate pn ON pn.filing = fi.filing AND pn.layer = p.part_layer
          WHERE pn.window_low IS NOT NULL)
    UNION ALL SELECT 'a derived time slack needs a window that permits the derivation',
        (SELECT count(*) FROM slack WHERE buffer = 'time' AND absent = 'derived')
    UNION ALL SELECT 'a window is notApplicable only where the unit has no denominator',
        (SELECT count(*) FROM nameplate WHERE window_absent = 'notApplicable')
    UNION ALL SELECT 'a fusion calls double counting malformed only when it has one part',
        (SELECT count(*) FROM elimination_search WHERE absent = 'notApplicable')
    UNION ALL SELECT 'a local part names a layer in its own stack',
        (SELECT count(*) FROM part p JOIN filing_identity fi
           ON fi.filing = p.composition AND fi.notation = p.part_filing)
    UNION ALL SELECT 'local parts do not cycle',
        (SELECT count(*) FROM part p JOIN filing_identity fi
           ON fi.filing = p.composition AND fi.notation = p.part_filing)
    UNION ALL SELECT 'no leaf layer is reachable through two paths',
        (SELECT count(*) FROM part p WHERE EXISTS
           (SELECT 1 FROM part q JOIN filing_identity fi ON fi.notation=q.part_filing
             WHERE fi.filing = p.composition))    -- only nested compositions can violate it
) c ORDER BY examined DESC, rule;
