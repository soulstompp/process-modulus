-- the derived overlaps a BPMN emission takes, each against the relation that names it.
SELECT * FROM (VALUES
  ('the buffer',   'D would be P x L x 3',        'the layer, within which the three engines are substitutes',
                   'layers/absorption.sqlc'),
  ('the lane set', 'D lanes + N lanes',            'the layer set, enumerated twice over one conformed dimension',
                   'diagrams/lane_grain.sqlc'),
  ('the import',   'one per cross-document part',  'the document, referenced many times from one filing',
                   'diagrams/cross_document.sqlc')
) AS e(elimination, the_sum, the_overlap, named_by)
