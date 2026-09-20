-- pm:Claim/pm:boundOrigin and pm:Claim/pm:narrowsWhen taking pm:derivation, against the identity that computes the claim.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           i.identity IS NULL AS violates,
           format('%s claim %s files its %s as the output of `%s`', c.owns, c.seq, c.element,
                  c.identity) AS detail
    FROM      (
        SELECT * FROM epistemics.claim_derivations
    ) c
    LEFT JOIN (
        SELECT * FROM identities.roster
    ) i
           ON i.identity = c.identity::text
          AND i.owns     = c.owns
          AND i.element  = c.element
) p ON true
WHERE r.slug = 'identity_does_not_compute_the_claim'
