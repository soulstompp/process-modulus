-- pm:Fusion/pm:Part against itself; conformance rule "a fusion's parts partition what they compose".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    -- the conformance rules stated in the schemas' prose and gated by no grammar.
SELECT * FROM (VALUES
  ('fit_disagrees', 'layer', 'sign agrees with the range comparison'),
  ('shares_do_not_sum', 'layer', 'stated shares sum to the magnitude'),
  ('nobody_named_as_unserved', 'layer', 'a supply with nowhere to put its excess names who went unserved'),
  ('exposure_unaccounted', 'layer', 'exposure does not exceed slack plus unserved shares'),
  ('share_exceeds_slack', 'layer', 'a share does not exceed the slack of the buffer that absorbed it'),
  ('slack_unit_mismatch', 'slack', 'a slack is expressed in the unit of the shares it bounds'),
  ('quantum_unit_mismatch', 'layer', 'a quantum is expressed in the unit of the nameplate it divides'),
  ('nameplate_not_a_multiple', 'layer', 'the nameplate is a whole multiple of the quantum'),
  ('draw_exceeds_the_supply', 'layer', 'a draw does not exceed what the supply can make'),
  ('clearance_with_unserved', 'layer', 'a clearance fit rules out customer and unrealised'),
  ('unresolved_part', 'part', 'a part reference resolves to a filing that is here'),
  ('jagged_layer', 'layer', 'a fusion''s parts partition what they compose'),
  ('layers_move_together', 'layer', 'layers that always move together are one layer'),
  ('coupling_does_not_attenuate', 'layer', 'a coupling attenuates through a fusion, bounded by the part''s share'),
  ('narrows_a_point_value', 'layer', 'a point value files narrowsWhen as notApplicable, having no range'),
  ('range_says_no_range', 'layer', 'a ranged claim does not file narrowsWhen as notApplicable'),
  ('bound_fell_with_no_range', 'layer', 'a point value does not say its bound is where the measurements fell'),
  ('window_lost_or_summed', 'part', 'a window is carried through a fusion and never summed'),
  ('derived_slack_over_a_window', 'layer', 'a derived time slack needs a window that permits the derivation'),
  ('window_not_applicable_on_a_rate', 'layer', 'a window is notApplicable only where the unit has no period under the line'),
  ('elimination_not_applicable_with_parts', 'layer', 'a fusion calls double counting malformed only when it has one part'),
  ('fusion_sum_disagrees', 'layer', 'a composed demand equals the sum of its converted parts less its eliminations'),
  ('local_part_dangles', 'part', 'a local part names a layer in its own stack'),
  ('unit_crossing_without_a_factor', 'layer', 'a part crossing a unit boundary files what converts it'),
  ('regime_crossing_without_a_citation', 'part', 'a part crossing a regime boundary files what reconciles it'),
  ('part_regime_disagrees', 'part', 'a composer''s regime for a part is one that part''s own filing declares'),
  ('conversion_cycle_does_not_close', 'layer', 'converting round a cycle of units returns what it started with'),
  ('one_part_fusion_alters_its_part', 'part', 'a fusion of one part carries that part unchanged'),
  ('denied_remainder_is_not_contradicted', 'layer', 'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, subject, rule)

) r
LEFT JOIN (
    SELECT f.filing, f.layer,
           j.filing IS NOT NULL AS violates,
           CASE WHEN j.filing IS NULL
                THEN format('`%s` draws each part once', f.layer)
                ELSE format('`%s/%s` arrives through `%s/%s` and through `%s/%s`',
                            j.doubled_filing, j.doubled_layer,
                            j.via_filing, j.via_layer, j.also_via_filing, j.also_via_layer)
           END AS detail
    FROM      (
        -- distinct (composition, composedLayerName) over pm:Fusion/pm:Part.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p

    ) f
    LEFT JOIN (
        -- composition/parts.sqlc self-joined on the fusion, against the reflexive closure of
-- composition/descent.sqlc, for the layer two sibling parts both reach.
SELECT DISTINCT
       a.composition    AS filing,
       a.composed_layer AS layer,
       r1.filing        AS doubled_filing,
       r1.layer         AS doubled_layer,
       a.part_filing    AS via_filing,
       a.part_layer     AS via_layer,
       b.part_filing    AS also_via_filing,
       b.part_layer     AS also_via_layer
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
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

) a
JOIN      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
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

) b ON  b.composition    = a.composition
    AND b.composed_layer = a.composed_layer
    AND (a.part_filing, a.part_layer) < (b.part_filing, b.part_layer)
JOIN      (
    SELECT DISTINCT root_filing, root_layer, filing, layer
    FROM (
        -- pm:Fusion/pm:Part followed transitively through pm.filing_identity.
WITH RECURSIVE
resolved AS (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
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
walk(root_filing, root_layer, filing, layer, depth, path,
     factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               ARRAY[p.composition  || '/' || p.composed_layer,
                     p.part_filing  || '/' || p.part_layer],
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               (p.factor_absent IS NOT NULL)
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.path || (p.part_filing || '/' || p.part_layer),
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR (p.factor_absent IS NOT NULL)
        FROM walk w
        JOIN resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT * FROM walk

    ) w
  UNION
    SELECT DISTINCT part_filing, part_layer, part_filing, part_layer
    FROM (
        -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
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
) r1 ON r1.root_filing = a.part_filing AND r1.root_layer = a.part_layer
JOIN      (
    SELECT DISTINCT root_filing, root_layer, filing, layer
    FROM (
        -- pm:Fusion/pm:Part followed transitively through pm.filing_identity.
WITH RECURSIVE
resolved AS (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
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
walk(root_filing, root_layer, filing, layer, depth, path,
     factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               ARRAY[p.composition  || '/' || p.composed_layer,
                     p.part_filing  || '/' || p.part_layer],
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               (p.factor_absent IS NOT NULL)
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.path || (p.part_filing || '/' || p.part_layer),
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR (p.factor_absent IS NOT NULL)
        FROM walk w
        JOIN resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT * FROM walk

    ) w
  UNION
    SELECT DISTINCT part_filing, part_layer, part_filing, part_layer
    FROM (
        -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
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
) r2 ON  r2.root_filing = b.part_filing AND r2.root_layer = b.part_layer
     AND r2.filing = r1.filing AND r2.layer = r1.layer

    ) j ON j.filing = f.filing AND j.layer = f.layer
) p ON true
WHERE r.slug = 'jagged_layer'
