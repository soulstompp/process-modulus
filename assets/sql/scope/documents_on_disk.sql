-- the corpus directory as data; assets/ddl/schema.ddl's `filing.kind` CHECK is the domain.
SELECT * FROM (VALUES
  ('contrato-empresarial'::text,        'processModulus'::text, true,  NULL::text),
  ('coverage-pt-ncrf-pe',               'coverage',       false, 'ingest does not read a document rooted at `coverage`. `tests/coverage_parse.rs` asserts the property it exists to prove, at the XML level, so the document is checked and not stored'),
  ('coverage-us-gaap',                  'coverage',       false, 'the same, in the other regime. The PAIR is the subject: two regimes stay comparable exactly where the two witnesses cite one taxonomy'),
  ('dependence-group-consolidation',    'dependence',     false, 'ingest does not read a document rooted at `dependence`. ⚠️ It carries the only `asrt:DependenceEntry` in the corpus, so `from` and `to` are the two uses of `asrt:FiledLayer` with no apparatus, where `Part/layer` and `Elimination/between` both have one'),
  ('enterprise-contract',               'processModulus', true,  NULL),
  ('merge-group-composition',           'composition',    true,  NULL),
  ('merge-holding-composition',         'composition',    true,  NULL),
  ('merge-pt-member',                   'processModulus', true,  NULL),
  ('merge-us-member',                   'processModulus', true,  NULL),
  ('refutation',                        'processModulus', true,  NULL),
  ('run-2026-08-30',                    'run',            false, 'ingest does not read a document rooted at `run`. It is the observed side the coverage documents are asked about'),
  ('unstated',                          'processModulus', true,  NULL)
) AS d(document, kind, loaded, not_loaded_because)
