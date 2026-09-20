-- Say each shortfall a second way and re-run every rule.

SET search_path TO pm, public;
\pset border 2
\pset null '·'

\echo
\echo '=== The relabellings, and what the model claims each one must do to a verdict. ===='
-- relabellings/roster.sqlc: what is rewritten, the sentence it tests, and the gate.
-- pm:HolderKind, the "unserved" annotation; pm:Layer/pm:timeSlack, "the holder does not get to refuse".
SELECT * FROM (VALUES
  ('refusal_as_decay',
   'capacity slack <-> time slack, on a layer whose shortfall nobody could serve',
   'the same demand went without because the supply had no room to run into, or because it did not survive the wait',
   'steady'),
  ('experienced_or_not',
   'customer <-> unrealised, on every layer, including the ones naming both',
   'demand that was there and got degraded, or demand that never became anybody''s experience',
   'steady'),
  ('unserved_as_absorbed',
   'customer -> people, where a layer has no people holder already',
   'the defeater: this one crosses unserved into absorbed, which the rules read on purpose',
   'moves')
) AS t(slug, swaps, tests, expected)
;

-- checks/all.sqlc, recorded before anything is rewritten.
CREATE TEMP TABLE verdict_before AS
SELECT * FROM checks.all;

\echo
\echo '=== 1. refusal_as_decay, the one the annotation is about. ========================'
\echo 'On every layer whose own demand and nameplate imply a shortfall nobody could serve,'
\echo 'move the empty buffer from capacity to time. Before: the supply had no room to run'
\echo 'into. After: the demand did not survive the wait. The same quantity goes without,'
\echo 'to the same holders, and `Layer/timeSlack` says the second one in as many words:'
\echo '"the holder does not get to refuse, the demand decayed".'
BEGIN;

-- layers/unabsorbed_exposure.sqlc: exactly the population the unserved rules examine.
WITH shortfall AS (
    SELECT z.filing, z.layer
    FROM (
        SELECT * FROM layers.unabsorbed_exposure
    ) z
    WHERE z.exposure > 1e-9
),
swapped AS (
    SELECT s.filing, s.layer,
           CASE s.buffer WHEN 'capacity' THEN 'time' ELSE 'capacity' END::buffer AS buffer,
           s.low, s.mode, s.high, s.unit, s.absent
    FROM shortfall JOIN pm.slack s USING (filing, layer)
    WHERE s.buffer IN ('capacity', 'time')
)
UPDATE pm.slack d
   SET low   = w.low,   mode   = w.mode, high = w.high, unit = w.unit, absent = w.absent
  FROM swapped w
 WHERE (d.filing, d.layer, d.buffer) = (w.filing, w.layer, w.buffer);

-- checks/all.sqlc again, over the rewritten corpus.
CREATE TEMP TABLE verdict_after AS
SELECT * FROM checks.all;

CREATE TEMP TABLE moved AS
SELECT g.*
FROM (
    SELECT rule, filing, layer, violates, detail,
           count(*) FILTER (WHERE side = 'before') AS said_before,
           count(*) FILTER (WHERE side = 'after')  AS said_after
    FROM ( SELECT 'before' AS side, v.* FROM verdict_before v
           UNION ALL
           SELECT 'after',          v.* FROM verdict_after  v ) u
    GROUP BY rule, filing, layer, violates, detail
) g
WHERE g.said_before <> g.said_after;

SELECT * FROM moved ORDER BY rule, filing, layer;
-- relabellings/roster.sqlc supplies the expectation; the count supplies what happened.
SELECT r.slug, r.expected, o.observed,
       CASE WHEN r.expected = o.observed  THEN 'held'
            WHEN r.expected = 'steady'    THEN '⛔ A RULE DECIDED WHICH HAPPENED'
            ELSE '⛔ THE HARNESS IS BLIND: every result above is worthless' END AS verdict
FROM (
    -- pm:HolderKind, the "unserved" annotation; pm:Layer/pm:timeSlack, "the holder does not get to refuse".
SELECT * FROM (VALUES
  ('refusal_as_decay',
   'capacity slack <-> time slack, on a layer whose shortfall nobody could serve',
   'the same demand went without because the supply had no room to run into, or because it did not survive the wait',
   'steady'),
  ('experienced_or_not',
   'customer <-> unrealised, on every layer, including the ones naming both',
   'demand that was there and got degraded, or demand that never became anybody''s experience',
   'steady'),
  ('unserved_as_absorbed',
   'customer -> people, where a layer has no people holder already',
   'the defeater: this one crosses unserved into absorbed, which the rules read on purpose',
   'moves')
) AS t(slug, swaps, tests, expected)

) r
CROSS JOIN (SELECT CASE WHEN count(*) > 0 THEN 'moves' ELSE 'steady' END AS observed FROM moved) o
WHERE r.slug = 'refusal_as_decay';

ROLLBACK;

\echo
\echo '=== 2. experienced_or_not ========================================================'
\echo 'Swap the two unserved holders on every layer. The axis between them is whether'
\echo 'anybody experienced it, and both are demand nobody served. A layer naming both has'
\echo 'its two words exchanged and each share keeps its own figure: a relabelling renames,'
\echo 'it never merges. Those layers are the sharpest test here, the only ones where a rule'
\echo 'could compare the two shares against each other.'
BEGIN;

CREATE TEMP TABLE relabelled_holders AS
SELECT jsonb_populate_record(NULL::pm.holder,
         to_jsonb(h) || jsonb_build_object('kind',
           CASE h.kind WHEN 'customer' THEN 'unrealised' ELSE 'customer' END)) AS r
FROM pm.holder h
WHERE h.kind IN ('customer', 'unrealised');

DELETE FROM pm.holder h WHERE h.kind IN ('customer', 'unrealised');

INSERT INTO pm.holder SELECT (x.r).* FROM relabelled_holders x;

-- checks/all.sqlc again, over the rewritten corpus.
CREATE TEMP TABLE verdict_after AS
SELECT * FROM checks.all;

CREATE TEMP TABLE moved AS
SELECT g.*
FROM (
    SELECT rule, filing, layer, violates, detail,
           count(*) FILTER (WHERE side = 'before') AS said_before,
           count(*) FILTER (WHERE side = 'after')  AS said_after
    FROM ( SELECT 'before' AS side, v.* FROM verdict_before v
           UNION ALL
           SELECT 'after',          v.* FROM verdict_after  v ) u
    GROUP BY rule, filing, layer, violates, detail
) g
WHERE g.said_before <> g.said_after;

SELECT * FROM moved ORDER BY rule, filing, layer;
-- relabellings/roster.sqlc supplies the expectation; the count supplies what happened.
SELECT r.slug, r.expected, o.observed,
       CASE WHEN r.expected = o.observed  THEN 'held'
            WHEN r.expected = 'steady'    THEN '⛔ A RULE DECIDED WHICH HAPPENED'
            ELSE '⛔ THE HARNESS IS BLIND: every result above is worthless' END AS verdict
FROM (
    -- pm:HolderKind, the "unserved" annotation; pm:Layer/pm:timeSlack, "the holder does not get to refuse".
SELECT * FROM (VALUES
  ('refusal_as_decay',
   'capacity slack <-> time slack, on a layer whose shortfall nobody could serve',
   'the same demand went without because the supply had no room to run into, or because it did not survive the wait',
   'steady'),
  ('experienced_or_not',
   'customer <-> unrealised, on every layer, including the ones naming both',
   'demand that was there and got degraded, or demand that never became anybody''s experience',
   'steady'),
  ('unserved_as_absorbed',
   'customer -> people, where a layer has no people holder already',
   'the defeater: this one crosses unserved into absorbed, which the rules read on purpose',
   'moves')
) AS t(slug, swaps, tests, expected)

) r
CROSS JOIN (SELECT CASE WHEN count(*) > 0 THEN 'moves' ELSE 'steady' END AS observed FROM moved) o
WHERE r.slug = 'experienced_or_not';

ROLLBACK;

\echo
\echo '=== 3. unserved_as_absorbed, the defeater. Rows below are the good outcome. ======'
\echo 'Call the customer who went without a person who absorbed it. This one is meant to be'
\echo 'seen: `unserved` and `absorbed` are a difference in kind, and entries/holders.sqlc'
\echo 'says so. If the two runs above hold still and this one does too, the diff is broken'
\echo 'and nothing on this page is evidence of anything.'
BEGIN;

UPDATE pm.holder h
   SET kind = 'people'
 WHERE h.kind = 'customer'
   AND NOT EXISTS (SELECT 1 FROM pm.holder o
                    WHERE (o.filing, o.layer) = (h.filing, h.layer) AND o.kind = 'people');

-- checks/all.sqlc again, over the rewritten corpus.
CREATE TEMP TABLE verdict_after AS
SELECT * FROM checks.all;

CREATE TEMP TABLE moved AS
SELECT g.*
FROM (
    SELECT rule, filing, layer, violates, detail,
           count(*) FILTER (WHERE side = 'before') AS said_before,
           count(*) FILTER (WHERE side = 'after')  AS said_after
    FROM ( SELECT 'before' AS side, v.* FROM verdict_before v
           UNION ALL
           SELECT 'after',          v.* FROM verdict_after  v ) u
    GROUP BY rule, filing, layer, violates, detail
) g
WHERE g.said_before <> g.said_after;

SELECT * FROM moved ORDER BY rule, filing, layer;
-- relabellings/roster.sqlc supplies the expectation; the count supplies what happened.
SELECT r.slug, r.expected, o.observed,
       CASE WHEN r.expected = o.observed  THEN 'held'
            WHEN r.expected = 'steady'    THEN '⛔ A RULE DECIDED WHICH HAPPENED'
            ELSE '⛔ THE HARNESS IS BLIND: every result above is worthless' END AS verdict
FROM (
    -- pm:HolderKind, the "unserved" annotation; pm:Layer/pm:timeSlack, "the holder does not get to refuse".
SELECT * FROM (VALUES
  ('refusal_as_decay',
   'capacity slack <-> time slack, on a layer whose shortfall nobody could serve',
   'the same demand went without because the supply had no room to run into, or because it did not survive the wait',
   'steady'),
  ('experienced_or_not',
   'customer <-> unrealised, on every layer, including the ones naming both',
   'demand that was there and got degraded, or demand that never became anybody''s experience',
   'steady'),
  ('unserved_as_absorbed',
   'customer -> people, where a layer has no people holder already',
   'the defeater: this one crosses unserved into absorbed, which the rules read on purpose',
   'moves')
) AS t(slug, swaps, tests, expected)

) r
CROSS JOIN (SELECT CASE WHEN count(*) > 0 THEN 'moves' ELSE 'steady' END AS observed FROM moved) o
WHERE r.slug = 'unserved_as_absorbed';

ROLLBACK;

DROP TABLE verdict_before;
