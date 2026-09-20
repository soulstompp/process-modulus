-- pm:Layer/pm:remainder taking the pm:claim branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value, l.absorber_absent,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent,
       l.sign_derivation, l.qty_derivation
FROM pm.layer l
WHERE l.remainder_absent IS NULL
