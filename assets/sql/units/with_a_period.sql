-- pm:Claim/pm:denominator/pm:period, at pm:Nameplate/amount.
SELECT c.filing, c.layer, c.unit, c.denominator AS period
FROM      (
    SELECT * FROM epistemics.claims
) c
WHERE c.owns = 'pm:nameplate/pm:amount'
  AND c.denominator_kind = 'period'
