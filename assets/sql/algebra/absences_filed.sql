-- epistemics/absences.sqlc against epistemics/filed_absences.sqlc, through epistemics/absence_positions.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    WITH positions AS (
        SELECT * FROM (
            -- The XSD's Stated* wrapper positions in the documents ingest loads, against epistemics/absences.sqlc's questions.
SELECT * FROM (VALUES
  ('pm:processModulus/pm:notation',     'its own notation',                       NULL::text),
  ('pm:processModulus/pm:evidence',     'what it is evidence for',                NULL),
  ('pm:stack/pm:scope',                 'how much of the system',                 NULL),
  ('pm:stack/pm:couplings',             'did anybody look for couplings',         NULL),
  ('pm:regime/pm:framework',            'regime framework',                       NULL),
  ('pm:regime/pm:chart',                'regime chart',                           NULL),
  ('asrt:regime/pm:framework',          'part regime framework',                  NULL),
  ('asrt:regime/pm:chart',              'part regime chart',                      NULL),
  ('asrt:provenance/pm:standing',       'assertion standing',                     NULL),
  ('pm:provenance/pm:standing',         'provenance standing',                    NULL),
  ('pm:provenance/pm:standing',         'provenance standing, on an absence',     NULL),
  ('pm:provenance/pm:standing',         'provenance standing, on a derivation',   NULL),
  ('pm:claim/pm:narrowsWhen',           'narrowsWhen',                            NULL),
  ('pm:claim/pm:boundOrigin',           'boundOrigin',                            NULL),
  ('pm:claim/pm:denominator',           'denominator',                            NULL),
  ('pm:coupling/pm:strength',           'coupling strength',                      NULL),
  ('pm:operation/pm:notationPosition',  'where the operation is in a notation',   NULL),
  ('pm:draw/pm:quantity',               'operation draw',                         NULL),
  ('pm:induces/pm:commitment',          'operation induction',                    NULL),
  ('pm:demand/pm:amount',               'demand',                                 NULL),
  ('pm:demand/pm:patience',             'patience',                               NULL),
  ('pm:layer/pm:timeSlack',             'buffer slack',                           NULL),
  ('pm:nameplate/pm:capacitySlack',     'buffer slack',                           NULL),
  ('pm:nameplate/pm:inventorySlack',    'buffer slack',                           NULL),
  ('pm:layer/pm:remainder',             'remainder',                              NULL),
  ('pm:remainder/pm:sign',              'remainder sign',                         NULL),
  ('pm:remainder/pm:absorber',          'remainder absorber',                     NULL),
  ('pm:remainder/pm:quantity',          'remainder quantity',                     NULL),
  ('pm:holder/pm:share',                'holder share',                           NULL),
  ('pm:nameplate/pm:amount',            'nameplate amount',                       NULL),
  ('pm:nameplate/pm:amountOrigin',      'who committed the amount',               NULL),
  ('pm:nameplate/pm:divisibility',      'divisibility',                           NULL),
  ('pm:divisibility/pm:window',         'duty-cycle window',                      NULL),
  ('pm:lumpy/pm:size',                  'lump size',                              NULL),
  ('pm:quantum/pm:size',                'duty-cycle period',                      NULL),
  ('pm:jagged/pm:draw',                 'draw',                                   NULL),
  ('pm:jagged/pm:measurementBasis',     'measurement basis',                      NULL),
  ('asrt:fusion/asrt:eliminations',     'did anybody look for double counting',   NULL),
  ('asrt:elimination/asrt:quantity',    'eliminated quantity',                    NULL),
  ('asrt:part/asrt:factor',             'part factor',                            NULL),
  ('pm:continuous/pm:premium',          NULL,
   'a premium is a claim nothing reads, so it has no columns of its own: its value is in claim and its absence here alone'),
  ('pm:remainder/pm:holder',            NULL,
   'a holder that is typed absent has no row in holder, whose rows are the holders that bear a share')
) AS p(owns, question, why_no_column)

        ) r
    ),
    by_owns AS (
        SELECT owns, min(question) AS g FROM positions WHERE question IS NOT NULL GROUP BY owns
    ),
    by_question AS (
        SELECT p.question, min(o.g) AS g
        FROM positions p JOIN by_owns o USING (owns)
        WHERE p.question IS NOT NULL
        GROUP BY p.question
    ),
    owns_group AS (
        SELECT p.owns, min(q.g) AS g
        FROM positions p JOIN by_question q USING (question)
        GROUP BY p.owns
    ),
    counted AS (
        SELECT q.g, c.filing, c.reason, count(*) AS n
        FROM (
            SELECT * FROM epistemics.absences
        ) c
        JOIN by_question q USING (question)
        GROUP BY q.g, c.filing, c.reason
    ),
    filed AS (
        SELECT o.g, f.filing, f.reason, count(*) AS n
        FROM (
            SELECT * FROM epistemics.filed_absences
        ) f
        JOIN owns_group o USING (owns)
        GROUP BY o.g, f.filing, f.reason
    ),
    cells AS (
        SELECT coalesce(c.g, f.g) AS g, coalesce(c.filing, f.filing) AS filing,
               coalesce(c.reason, f.reason) AS reason,
               coalesce(c.n, 0) AS counted, coalesce(f.n, 0) AS filed
        FROM counted c
        FULL JOIN filed f ON f.g = c.g AND f.filing = c.filing AND f.reason = c.reason
    )
    SELECT q.g AS subject,
           coalesce(bool_and(x.counted = x.filed), true) AS holds,
           format('%s filed, %s counted%s', coalesce(sum(x.filed), 0), coalesce(sum(x.counted), 0),
                  coalesce(': ' || string_agg(format('%s %s filed %s, counted %s', x.filing, x.reason,
                                                     x.filed, x.counted), '; ' ORDER BY x.filing, x.reason)
                                   FILTER (WHERE x.counted <> x.filed), '')) AS detail
    FROM (SELECT DISTINCT g FROM by_question) q
    LEFT JOIN cells x ON x.g = q.g
    GROUP BY q.g
    UNION ALL
    SELECT 'positions the roster does not name',
           count(*) FILTER (WHERE p.owns IS NULL) = 0,
           format('%s absences at %s undeclared position(s)%s; %s at positions no column answers',
                  count(*) FILTER (WHERE p.owns IS NULL),
                  count(DISTINCT f.owns) FILTER (WHERE p.owns IS NULL),
                  coalesce(': ' || string_agg(DISTINCT f.owns, ', ') FILTER (WHERE p.owns IS NULL), ''),
                  count(*) FILTER (WHERE p.owns IS NOT NULL AND p.question IS NULL))
    FROM (
        SELECT * FROM epistemics.filed_absences
    ) f
    LEFT JOIN (SELECT owns, min(question) AS question FROM positions GROUP BY owns) p USING (owns)
    UNION ALL
    SELECT 'questions no position holds',
           count(*) = 0,
           format('%s question(s) on the census with no position%s', count(*),
                  coalesce(': ' || string_agg(q.question, ', '), ''))
    FROM (
        SELECT * FROM epistemics.absence_questions
    ) q
    WHERE q.question NOT IN (SELECT question FROM positions WHERE question IS NOT NULL)
) p ON true
WHERE a.slug = 'absences_filed'
