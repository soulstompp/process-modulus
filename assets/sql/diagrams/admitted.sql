-- the mapping's own history: what was tried, what replaced it, and where BPMN is simply wider.
SELECT * FROM (VALUES
  ('subProcess'::text, 'childLaneSet'::text, NULL::boolean,
   '⭐ A LOCAL FUSION IS A PARTITION, NOT AN ACTIVITY. `subProcess` is a flow node, so it collapses layer to document exactly as `calledElement` does; a nested lane keeps the key `(filing, layer)`. Measured: 10 of 27 parts are local, and every one of them left the flattening when this changed'::text),
  ('partitionElementRef', NULL, true,
   '⭐⭐⭐ THE ONLY PLACE BPMN IS THE FINER OF THE TWO, AND IT WAS TESTED BEFORE IT WAS FILED. `tLane` carries this for WHAT the partition is BY, per lane. The nearest filler is the absorber BUFFER and it fails: 14 filings here have two or more layers sharing one buffer, up to FOUR lanes on `capacity` in one process, so pointing at it would assert a partition the model does not make. A layer''s identity is its NAME and nothing else, so there is no element to point at')
) AS s(element, superseded_by, no_such_fact, why)
