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
