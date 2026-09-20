-- entries/absorbing_slack.sqlc against pm:Remainder/pm:holder, each carrying its own unit.
SELECT s.filing, s.layer, s.buffer, h.kind,
       s.unit AS slack_unit, h.share_unit
FROM      (
    SELECT * FROM entries.absorbing_slack
) s
JOIN      (
    SELECT * FROM entries.holders
) h USING (filing, layer)
WHERE s.unit IS NOT NULL AND h.share_unit IS NOT NULL
