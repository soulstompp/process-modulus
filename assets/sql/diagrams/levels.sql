-- the levels of process this corpus holds, and which of them a BPMN emission carries.
SELECT * FROM (VALUES
  (0, 'supply',   'an operation, in the lane it draws from', 'a layer''s supply',
      'a draw, and a commitment induced on another layer',   'pm.operation, pm.draw, pm.induction', true),
  (1, 'filing',   'a party, an enterer, an approver, a searcher',
      'the figures level 0 leaves behind',
      'a claim with a standing, a search with an outcome, a scope with an extent',
      'pm.claim provenance, pm.absence, pm.coupling_search, pm.stack_scope, pm.bound_origin, pm.narrowing', false),
  (2, 'checking', 'a rule on checks/roster.sqlc', 'the claims level 1 filed',
      'violates, or NULL for a rule that examined nothing',  'checks/all.sqlc', false),
  (3, 'proving',  'a law on algebra/roster.sqlc, a site on arithmetic/roster.sqlc',
      'the relations level 2 rests on', 'holds, or a verdict',
      'algebra/all.sqlc, arithmetic/all.sqlc', false),
  (4, 'contract', 'a roster, against the population it declares', 'the laws level 3 states',
      'nothing. An empty result is the end condition, which is why there is no level 5',
      'reports/integrity.sqlc', false)
) AS l(level, process, actor, subject, outcome, where_it_lives, emitted)
