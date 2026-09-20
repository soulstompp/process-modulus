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
