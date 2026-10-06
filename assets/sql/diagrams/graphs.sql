
-- the three graphs this model composes, as data an emitter chooses between.
SELECT * FROM (VALUES
  ('layers',    'a layer, keyed (filing, layer)', 'a part: a layer composed from a layer',
                'undirected',
                'a leaf reached down two branches of one fusion, which counts it twice',
                                                                              'checks/jagged_layer'),
  ('units',     'a unit',                          'a conversion: a factor from unit to unit',
                'undirected',
                'expected, and required to close: converting round it returns what it started with',
                                                                              'checks/conversion_cycle_does_not_close'),
  ('claimants', 'a claimant: software, an agent, a role, a person',
                'delegation, and nothing files it',
                'directed',
                'unknown, and not a fault: mutual signing authority is a legitimate cycle',
                                                                              NULL)
) AS g(graph, node_is, edge_is, cycle_sense, a_cycle_is, governed_by)
