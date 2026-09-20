-- §22 What each fusion declared it cannot see: the offsets between its own parts.
-- asrt:Fusion/asrt:Part crossed with itself on the fusion, carrying each part's factor.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       CASE WHEN p.factor_low        IS NOT NULL THEN 'stated'::public.factor_state
            WHEN p.factor_absent     IS NOT NULL THEN 'absent'::public.factor_state
            WHEN p.factor_derivation IS NOT NULL THEN 'derivation'::public.factor_state
            ELSE                                      'omitted'::public.factor_state END AS factor_state,
       p.part_party, p.part_registration_taxonomy, p.part_registration_value, p.part_version
FROM pm.part p

),
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

),
fusions AS NOT MATERIALIZED (
    -- asrt:Fusion: the composed layer it names, and asrt:observed.
SELECT f.composition AS filing, f.composed_layer AS layer, f.observed
FROM pm.fusion f

),
sized AS (
    SELECT p.composition, p.composed_layer,
           p.part_filing, p.part_layer, p.factor_state,
           CASE WHEN p.factor_state = 'omitted' THEN 1 ELSE p.factor_low  END AS lo,
           CASE WHEN p.factor_state = 'omitted' THEN 1 ELSE p.factor_mode END AS md,
           CASE WHEN p.factor_state = 'omitted' THEN 1 ELSE p.factor_high END AS hi
    FROM ( SELECT * FROM parts ) p
)
SELECT a.composition                                        AS "composition!",
       a.composed_layer                                     AS "composed_layer!",
       a.part_filing  || '/' || a.part_layer                AS "part_a!",
       b.part_filing  || '/' || b.part_layer                AS "part_b!",
       (a.lo IS NOT NULL AND b.lo IS NOT NULL)              AS "determined!",
       least(a.lo / b.hi, a.hi / b.lo)::double precision    AS rate_low,
       (a.md / b.md)::double precision                      AS rate_mode,
       greatest(a.lo / b.hi, a.hi / b.lo)::double precision AS rate_high,
       CASE WHEN a.lo IS NOT NULL AND b.lo IS NOT NULL THEN NULL
            ELSE concat_ws(' and ',
                     CASE WHEN a.lo IS NULL
                          THEN 'the factor on ' || a.part_layer || ' is ' || a.factor_state END,
                     CASE WHEN b.lo IS NULL
                          THEN 'the factor on ' || b.part_layer || ' is ' || b.factor_state END)
       END                                                  AS undetermined_because,
       f.observed                                           AS "observed!"
FROM      sized a
JOIN      sized b
       ON b.composition    = a.composition
      AND b.composed_layer = a.composed_layer
      AND (b.part_filing, b.part_layer) > (a.part_filing, a.part_layer)
JOIN      (
    SELECT * FROM fusions
) f ON f.filing = a.composition AND f.layer = a.composed_layer
ORDER BY a.composition, a.composed_layer, "part_a!", "part_b!"
