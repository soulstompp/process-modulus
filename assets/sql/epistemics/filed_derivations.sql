-- pm:Derivation and its restrictions, every one, with pm:note, pm:asOf and pm:provenance.
SELECT d.filing, d.seq, coalesce(d.claim_owns, d.owns) AS owns, d.owns AS element, d.layer,
       d.identity, d.note, d.as_of,
       d.prov_party, d.prov_entered_by, d.prov_approved_by,
       d.prov_standing_taxonomy, d.prov_standing_value, d.prov_standing_absent, d.prov_note
FROM pm.derivation d
