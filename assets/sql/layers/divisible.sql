-- pm:LumpyQuantum/size, strictly positive.
SELECT l.*
FROM (
    SELECT * FROM layers.lumpy
) l
WHERE l.quantum_mode > 0
