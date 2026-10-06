-- the derived overlaps a BPMN emission takes, each against the relation that names it.
SELECT * FROM (VALUES
  ('the buffer',   'a draw for every operation, layer and buffer',
                   'the layer, within which the three engines are substitutes',
                   'layers/absorption.sqlc'),
  ('the lane set', 'a lane for every layer drawn on and another for every layer induced into',
                   'the layer set, enumerated twice over one conformed dimension',
                   'diagrams/lane_grain.sqlc'),
  ('the import',   'one per cross-document part',  'the document, referenced many times from one filing',
                   'diagrams/cross_document.sqlc')
) AS e(elimination, the_sum, the_overlap, named_by)
