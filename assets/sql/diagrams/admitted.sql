-- the mapping's own history: what was tried, what replaced it, and where BPMN is simply wider.
SELECT * FROM (VALUES
  ('subProcess'::text, 'childLaneSet'::text, NULL::boolean,
   'A local fusion divides its composed layer among its parts; it is not an activity. '
   '`subProcess` is a flow node, so it collapses layer to document exactly as `calledElement` '
   'does; a nested lane keeps the key `(filing, layer)`'::text),
  ('partitionElementRef', NULL, true,
   'The only place BPMN is the finer of the two. `tLane` carries this for what the lanes are '
   'divided by, per lane. The nearest filler is the absorber buffer, and it does not fit: '
   'several layers of one filing can share one buffer, so pointing at it would assert a '
   'division the model does not make. A layer''s identity is its name and nothing else, so '
   'there is no element to point at')
) AS s(element, superseded_by, no_such_fact, why)
