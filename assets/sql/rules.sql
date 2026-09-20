-- The rules XSD 1.0 cannot reach, assembled from one file per rule.

SET search_path TO pm, public;
\pset border 2
\pset null '·'

\echo
\echo === Violations. An empty table is the good outcome. ============================
-- checks/all.sqlc, restricted to the rows that fail.
SELECT c.rule, c.filing, c.layer, c.detail
FROM (
    SELECT * FROM checks.all
) c
WHERE c.violates
ORDER BY 1, 2, 3
;

\echo
\echo === Referrals. Not violations: things a query can find and only a person can settle. ====
\echo 'Detecting the structure is mechanical. Judging the prose is not, so these are handed over'
\echo 'rather than passed or failed. A clean run has rows here and that is correct.'
-- pm:Coupling against asrt:Fusion/asrt:Part pairs that contain both of its ends, over the corpus.
SELECT c.filing,
       c.from_layer || ' -> ' || c.to_layer AS coupling,
       CASE WHEN a.composition IS NULL THEN '(no fusion holds both ends)'
            ELSE a.composition || '/' || a.composed_layer END AS absorbed_into,
       left(regexp_replace(c.observation, '\s+', ' ', 'g'), 56) || '...' AS what_was_observed
FROM (
    SELECT * FROM entries.couplings
) c
LEFT JOIN (
    SELECT DISTINCT sp.part_filing AS filing, sp.from_layer, sp.to_layer,
           sp.composition, sp.composed_layer
    FROM (
        SELECT * FROM composition.sibling_parts
    ) sp
) a USING (filing, from_layer, to_layer)
JOIN      (
    SELECT * FROM scope.corpus
) sc USING (filing)
ORDER BY 1, 2
;

\echo
\echo 'And the correction nobody filed: a layer built into two composed layers. Summing those'
\echo 'two counts its supply twice. Derived rather than observed, because the overlap is a part'
\echo 'and a part carries its own figures. An elimination corrects a composition somebody did;'
\echo 'this one is about a composition nobody has done yet.'
-- eliminations/derived.sqlc, with the evidence each composing document attests to.
SELECT s.part_filing || '/' || s.part_layer      AS part,
       s.composition_a || '/' || s.composed_a    AS counted_into,
       s.composition_b || '/' || s.composed_b    AS and_also_into,
       fa.evidence                               AS evidence,
       s.would_double_count_demand               AS demand,
       s.would_double_count_nameplate            AS nameplate,
       s.unit
FROM      (
    SELECT * FROM eliminations.derived
) s
JOIN      (
    SELECT * FROM scope.every_filing
) fa ON fa.filing = s.composition_a
ORDER BY fa.evidence, 1
;

\echo
\echo 'And what a receiver is entitled to say about narrowsWhen, as a number rather than'
\echo 'an opinion. The annotation: "a claim without it is weaker, and a receiver is'
\echo 'entitled to say so". Judging whether the sentence would actually narrow the range'
\echo 'is prose. Counting which ranges decline to say anything is not.'
-- epistemics/claims.sqlc's narrowsWhen on each ranged demand of layers/ranged_demands.sqlc, over the corpus.
SELECT count(*)                                                   AS ranged_demands,
       count(*) FILTER (WHERE c.narrows_condition IS NULL)        AS say_nothing,
       round(100.0 * count(*) FILTER (WHERE c.narrows_condition IS NULL)
             / nullif(count(*), 0))                               AS pct
FROM (
    -- pm:Claim on pm:Demand where low <> high.
SELECT d.*
FROM (
    SELECT * FROM layers.demand
) d
WHERE NOT d.is_a_point

) r
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
JOIN (
    SELECT * FROM epistemics.claims
) c ON c.filing = r.filing AND c.layer = r.layer AND c.owns = 'pm:demand/pm:amount'
;

\echo
\echo 'And the grain question, answerable for the first time. How much of the width in'
\echo 'this corpus is ignorance (a better instrument reveals it) and how much is the'
\echo 'world actually moving (only changing the process reduces it)? Before narrowsWhen'
\echo 'carried a kind there was nothing to group by, and the schema simply asserted the'
\echo 'first reading throughout.'
-- pm:Claim/pm:narrowsWhen kinds, over the corpus.
SELECT w.what_the_width_is_made_of, count(*) AS claims
FROM (
    SELECT * FROM epistemics.widths
) w
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
;

\echo
\echo
\echo 'Has anybody tested the model? The single most important number in this file, and'
\echo 'it is unaskable while `Stack/couplings` is a bare empty list. `pm:Coupling`'
\echo 'says a document with no couplings "is not evidence of independence; it is a document'
\echo 'where nobody looked", and for two revisions the element it says that about could'
\echo 'only write the ambiguous thing. This is a fact about the evidence rather than about'
\echo 'any one filing, which is why it is a report and not a rule.'
-- pm:Stack/pm:couplings/pm:absent, over the corpus.
SELECT CASE
         WHEN s.answer IS NULL              THEN 'somebody looked and the layers MOVE TOGETHER'
         WHEN s.answer = 'none'             THEN 'somebody looked and found independence'
         WHEN s.answer = 'notApplicable'    THEN 'one layer; no pair to couple'
         ELSE 'NOBODY LOOKED'
       END AS the_independence_assumption,
       count(*) AS stacks
FROM (
    SELECT * FROM epistemics.coupling_searches
) s
JOIN (
    SELECT * FROM scope.corpus
) c USING (filing)
GROUP BY 1 ORDER BY 2 DESC
;

\echo
\echo 'And the same question one level up, about the stack itself. `scoped` says somebody'
\echo 'established what lies outside and excluded it; `unbounded` says nobody looked. As'
\echo 'one boolean those are the same row. Note what no filing here claims: a stack is a'
\echo 'projection of one system held by whoever filed it, never an enumeration of it.'
-- pm:Stack/pm:scope over scope/corpus.sqlc; the extent axis is documented on that element.
SELECT CASE
         WHEN sc.extent = 'complete'  THEN 'the whole system is in this stack'
         WHEN sc.extent = 'scoped'    THEN 'a bounded selection: somebody said what is outside'
         WHEN sc.extent = 'unbounded' THEN 'NOBODY LOOKED at what lies outside'
         ELSE 'not stated: ' || sc.absent
       END      AS how_much_of_the_system,
       count(*) AS stacks
FROM      (
    SELECT * FROM epistemics.scopes
) sc
JOIN      (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
;

\echo
\echo 'And the other claim a document can refute in this format. The model says every'
\echo 'layer has a remainder, and `StatedRemainder` is a choice, a remainder or a typed'
\echo 'reason there is none, so a sender who disagrees has to say so rather than leave a'
\echo 'field empty. Two layers do. Until `ingest.sql` read that second branch they arrived'
\echo 'as five NULLs and read as documents that had said nothing, which is precisely what'
\echo 'one of the notes below says it must not be taken for.'
-- pm:StatedRemainder's absent branch, over the corpus.
SELECT d.filing, d.layer, d.reason,
       regexp_replace(d.argument, '\s+', ' ', 'g') AS the_counter_example,
       format('%s of %s corpus layers deny having one',
              count(*) OVER (),
              (SELECT count(*) FROM (
                    SELECT * FROM layers.every_layer
                ) l
                JOIN (
                    SELECT * FROM scope.corpus
                ) sc USING (filing))) AS how_common
FROM (
    SELECT * FROM layers.denied_remainders
) d
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
ORDER BY d.filing, d.layer
;

\echo
\echo 'Who owns the edge, beside what would narrow it. The pair is the point: narrowsWhen'
\echo 'says what would make a range smaller, boundOrigin says who owns the edge it would'
\echo 'move. As an optional bare enumeration it was filed once across the corpus; required'
\echo 'and typed, the answer that leads is that nothing sets the edge, the range being'
\echo 'simply where the measurements fell, with `derived` close behind it, where the'
\echo 'model already states the author in a sibling element and no bare column points at it.'
-- pm:Claim/pm:boundOrigin, over the corpus.
SELECT e.who_owns_the_edge, count(*) AS claims
FROM (
    SELECT * FROM epistemics.edges
) e
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
;

\echo
\echo 'And the two halves crossed, which is the question both columns exist for. Read'
\echo 'apart they are two censuses. Read together they are advice, or, in the largest'
\echo 'cell, an indictment: a claim that answers "nobody has said what would narrow this"'
\echo 'and "nothing sets this bound" has no course of action and no owner, a bare number'
\echo 'pair wearing the clothes of a three-point estimate, and neither census alone can'
\echo 'see it. The ingest aligns the two columns; this is the relation that joins them.'
-- epistemics/widths.sqlc against epistemics/edges.sqlc, joined on the claim they share.
SELECT w.what_the_width_is_made_of AS what_would_narrow_it,
       e.who_owns_the_edge         AS who_owns_the_edge,
       count(*)                    AS claims
FROM      (
    SELECT * FROM epistemics.widths
) w
JOIN      (
    SELECT * FROM epistemics.edges
) e USING (filing, seq)
JOIN      (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1, 2
ORDER BY 3 DESC, 1, 2
;

\echo
\echo 'Did the composer look for double counting? Same shape, one document up, and the'
\echo 'answer decides which arithmetic is owed. `none` or `notApplicable`: the composed'
\echo 'figure must equal the sum of its converted parts exactly. `unmeasured`: no equality'
\echo 'is owed at all, and a checker reporting one is reporting about nothing.'
-- asrt:Fusion/asrt:eliminations/pm:absent, over the corpus.
SELECT coalesce(s.answer::text, 'eliminations filed') AS the_search,
       count(*) AS fusions,
       CASE WHEN s.answer = 'unmeasured' THEN 'sum rule SUSPENDED'
            ELSE 'sum rule exact' END AS what_is_owed
FROM (
    SELECT * FROM eliminations.searched
) s
JOIN (
    SELECT * FROM scope.corpus
) c ON c.filing = s.composition
GROUP BY 1, 3 ORDER BY 2 DESC
;

\echo
\echo 'And what nobody has measured, gathered from every element that admits an absence.'
\echo 'Scattered, a typed absence looks like a nullable field. In one relation it is a map'
\echo 'of what this corpus does not know, and the four reasons are four different facts.'
-- reports/absence_census.sqlc at corpus scope.
-- epistemics/absences.sqlc, restricted by the caller's @scope.
SELECT a.question, a.reason, count(*) AS times
FROM (
    SELECT * FROM epistemics.absences
) a
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1, 2
ORDER BY 3 DESC, 1, 2

;

\echo
\echo 'And every roster against itself: something declared with nothing behind it, or produced'
\echo 'and never declared. Every contract folds/contract_subjects.sqlc counts is checked.'
\echo 'An empty table is the correct outcome and the only one.'
SELECT * FROM reports.integrity;

\echo
\echo === Coverage. A rule that examined nothing is not a rule that passed. ===========
\echo 'This repository names the trap: "a bound with nothing to bound passes loudest".'
\echo 'An empty violations table above is worth exactly as much as this table says.'
-- folds/rule_subjects.sqlc, one row per rule either side names.
SELECT f.subject                        AS rule,
       f.answered                       AS examined,
       f.violated                       AS violations,
       CASE WHEN f.answered = 0 THEN '⛔ VACUOUS - proves nothing'
            WHEN f.answered < 3 THEN 'thin'
            ELSE 'ok' END               AS verdict
FROM (
    SELECT * FROM folds.rule_subjects
) f
ORDER BY examined DESC, rule
;

\echo
\echo 'And where along the fit each rule that reads it examined anything. A cell is exercised,'
\echo 'outside the rule by its own population, or open: in its domain with nothing loaded there.'
\echo 'An open cell asks for a document; algebra/fit_domain holds every standing both ways.'
SELECT * FROM reports.fit_coverage;
