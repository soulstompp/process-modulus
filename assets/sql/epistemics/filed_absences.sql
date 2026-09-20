-- pm:Absence and pm:ClaimAbsence, every one, with pm:note, pm:asOf and pm:provenance.
SELECT a.filing, a.seq, a.owns, a.layer, a.reason, a.note, a.as_of,
       a.prov_party, a.prov_entered_by, a.prov_approved_by,
       a.prov_standing_taxonomy, a.prov_standing_value, a.prov_standing_absent, a.prov_note
FROM pm.absence a
