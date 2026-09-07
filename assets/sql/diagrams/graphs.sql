-- the three graphs this model composes, as data an emitter chooses between.
SELECT * FROM (VALUES
  ('layers',    'a layer, keyed (filing, layer)', 'a part: F : layer -> layer',
                'a MISFILED PARTITION. The cells were one cell',              'checks/layers_move_together'),
  ('units',     'a unit',                          'a conversion: phi : unit -> unit',
                'EXPECTED, and required to CLOSE: the weights on it must vanish, so a potential exists',
                                                                              'checks/conversion_cycle_does_not_close'),
  ('claimants', 'a claimant: software, an agent, a role, a person',
                '⛔ delegation, and NOTHING FILES IT',
                'unknown. Not "nobody is accountable": mutual signing authority is a legitimate cycle',
                                                                              NULL)
) AS g(graph, node_is, edge_is, a_cycle_is, governed_by)
