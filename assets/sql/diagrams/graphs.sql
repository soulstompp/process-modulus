
-- the three graphs this model composes, as data an emitter chooses between.
SELECT * FROM (VALUES
  ('layers',    'a layer, keyed (filing, layer)', 'a part: F : layer -> layer',
                'undirected',
                'a leaf reached down two branches of one fold, which is a double count rather than a partition',
                                                                              'checks/jagged_layer'),
  ('units',     'a unit',                          'a conversion: phi : unit -> unit',
                'undirected',
                'expected, and required to close: the weights on it must vanish, so a potential exists',
                                                                              'checks/conversion_cycle_does_not_close'),
  ('claimants', 'a claimant: software, an agent, a role, a person',
                'delegation, and nothing files it',
                'directed',
                'unknown. Not "nobody is accountable": mutual signing authority is a legitimate cycle',
                                                                              NULL)
) AS g(graph, node_is, edge_is, cycle_sense, a_cycle_is, governed_by)
