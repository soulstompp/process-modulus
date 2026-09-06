-- Load assets/corpus/*.xml into the relations declared by assets/ddl/schema.ddl.

SET search_path TO pm, public;

BEGIN;

TRUNCATE source, elimination, elimination_search, part, coupling, coupling_search,
         induction, draw, operation, holder, slack, nameplate, layer, regime,
         narrowing, bound_origin, claim, stack_scope, filing CASCADE;

\set d `cat assets/corpus/enterprise-contract.xml`
INSERT INTO source VALUES ('enterprise-contract', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/corpus/contrato-empresarial.xml`
INSERT INTO source VALUES ('contrato-empresarial', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/corpus/refutation.xml`
INSERT INTO source VALUES ('refutation', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/corpus/unstated.xml`
INSERT INTO source VALUES ('unstated', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/corpus/merge-us-member.xml`
INSERT INTO source VALUES ('merge-us-member', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/corpus/merge-pt-member.xml`
INSERT INTO source VALUES ('merge-pt-member', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/corpus/merge-group-composition.xml`
INSERT INTO source VALUES ('merge-group-composition', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/corpus/merge-holding-composition.xml`
INSERT INTO source VALUES ('merge-holding-composition', XMLPARSE(DOCUMENT :'d'));

-- ⛔⛔ THE STIPULATIONS. Loaded because the RULES must run on them -- that is what a fixture
-- is for -- and marked so the REPORTS can exclude them. `every-local-part` is the only
-- document in either directory that exercises a LOCAL part, so without it the recursive
-- descent below never walks one.
\set d `cat assets/fixtures/every-absence.xml`
INSERT INTO source VALUES ('every-absence', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/fixtures/every-elimination.xml`
INSERT INTO source VALUES ('every-elimination', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/fixtures/every-local-part.xml`
INSERT INTO source VALUES ('every-local-part', XMLPARSE(DOCUMENT :'d'));

\set d `cat assets/fixtures/every-partial-elimination.xml`
INSERT INTO source VALUES ('every-partial-elimination', XMLPARSE(DOCUMENT :'d'));
\set d `cat assets/fixtures/every-unsized-conversion.xml`
INSERT INTO source VALUES ('every-unsized-conversion', XMLPARSE(DOCUMENT :'d'));

-- ---------------------------------------------------------------------------
-- Filings.
-- ---------------------------------------------------------------------------
INSERT INTO filing (name, kind, evidence, evidence_absent)
SELECT s.name,
       -- ⭐ THE DOCUMENT'S OWN ROOT ELEMENT, and not a substring match on a namespace PREFIX.
       -- A prefix is the sender's lexical choice -- `asrt:` is a habit, not a fact -- so a
       -- composition that bound the assertion namespace to any other letter used to land here
       -- as a plain filing, silently. `local-name()` reads what the document declares. Five
       -- roots are declared across the two schemas; epistemics/documents.sqlc lists them.
       x.root,
       -- ✅⭐⭐⭐ THE SECOND `LIKE` IS GONE. This used to match `A STIPULATION, NOT A FILING`
       -- as a substring over the whole serialised body, because no element carried the fact:
       -- English-only in a repository with a Portuguese edition, and true of any corpus
       -- document that merely QUOTED the phrase. `pm:StatedEvidence` is the element, and this
       -- reads it on the descendant axis for the same reason `notation` is read that way --
       -- a composition declares it on the filing it embeds, one level down.
       x.attests,
       x.absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm,
                            'https://example.invalid/assertion/1.0' AS asrt),
       '/*' PASSING s.body
       COLUMNS root    text PATH 'local-name(.)',
               attests text PATH '//pm:attests',
               absent  text PATH '(//pm:evidence|//asrt:evidence)/pm:absent/pm:reason') x;

-- ⭐ `FOR ORDINALITY` is what makes the two regimes in `refutation` two ROWS rather
--    than a collision. Document order is the only thing distinguishing them.
INSERT INTO regime
SELECT s.name, x.seq, x.id, x.jurisdiction, x.framework
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:regime' PASSING s.body
       COLUMNS seq          FOR ORDINALITY,
               id           text PATH 'pm:id',
               jurisdiction text PATH 'pm:jurisdiction',
               framework    text PATH 'pm:framework/pm:term/pm:value') x;

-- ⛔ THE READER'S GUESS, WRITTEN DOWN. No document declares its own notation, so
--    nothing in the corpus says which file `urn:example:filing:us-member:2026-08-31`
--    denotes. These three rows are asserted from FILENAMES and are the only reason
--    the composition queries resolve at all. Delete them and every part reference
--    dangles, which is the honest state of the corpus without a reader in the loop.
-- ✅⭐⭐⭐ S-28 REPAIRED. These three rows used to read `'the reader, from the filename'`
--    and they are read out of the document now, like every other fact in this file. A filing
--    says which filing it is; nothing here guesses.
INSERT INTO filing_identity
SELECT x.uri, s.name, 'the filing, about itself', x.absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:processModulus/pm:notation' PASSING s.body
       COLUMNS uri    text PATH 'pm:uri',
               absent text PATH 'pm:absent/pm:reason') x
WHERE x.uri IS NOT NULL;

-- ⭐⭐ HOW MUCH OF THE SYSTEM EACH STACK HOLDS.
INSERT INTO stack_scope
SELECT s.name, x.extent, x.basis, x.absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:scope' PASSING s.body
       COLUMNS extent text PATH 'pm:scope/pm:extent',
               basis  text PATH 'pm:scope/pm:basis',
               absent text PATH 'pm:absent/pm:reason') x
WHERE s.name IN (SELECT name FROM filing);

-- ---------------------------------------------------------------------------
-- Layers. ⭐ `//pm:stack/pm:layer` uses the DESCENDANT axis on purpose: a plain
-- filing has the stack at the root and a composition has it one level down, and
-- the descendant axis reads both without a branch.
-- ---------------------------------------------------------------------------
INSERT INTO layer
SELECT s.name, x.name,
       x.d_low, x.d_mode, x.d_high, x.d_unit, x.d_absent::absence_reason, x.d_narrows,
       x.d_kind::narrowing_kind, x.d_narrows_absent::absence_reason,
       x.p_low, x.p_mode, x.p_high, x.p_unit,
       x.p_origin::constraint_origin, x.p_absent::absence_reason,
       x.r_absent::absence_reason, x.r_note,
       x.sign::fit, x.sign_absent::absence_reason, x.absorber_taxonomy, x.absorber_value,
       x.q_low, x.q_mode, x.q_high, x.q_unit, x.q_absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:layer' PASSING s.body
       COLUMNS
         name     text    PATH 'pm:name',
         d_low    numeric PATH 'pm:demand/pm:amount/pm:claim/pm:low',
         d_mode   numeric PATH 'pm:demand/pm:amount/pm:claim/pm:mostLikely',
         d_high   numeric PATH 'pm:demand/pm:amount/pm:claim/pm:high',
         d_unit   text    PATH 'pm:demand/pm:amount/pm:claim/pm:unit',
         d_absent text    PATH 'pm:demand/pm:amount/pm:absent/pm:reason',
         -- ⭐⭐ THE DEMAND MIRROR. `pm:Divisibility` files the time axis as half and names
         -- `Layer/timeSlack` as where the other half goes "if demand ever gains structure".
         -- It has. A patience is a DURATION and a slack is quoted in the layer's unit, so
         -- these are two columns and not one -- they coincide numerically only where the
         -- layer's unit is service time.
         p_low    numeric PATH 'pm:demand/pm:patience/pm:claim/pm:low',
         p_mode   numeric PATH 'pm:demand/pm:patience/pm:claim/pm:mostLikely',
         p_high   numeric PATH 'pm:demand/pm:patience/pm:claim/pm:high',
         p_unit   text    PATH 'pm:demand/pm:patience/pm:claim/pm:unit',
         p_origin text    PATH 'pm:demand/pm:patience/pm:claim/pm:boundOrigin/pm:origin',
         p_absent text    PATH 'pm:demand/pm:patience/pm:absent/pm:reason',
         d_narrows text   PATH 'pm:demand/pm:amount/pm:claim/pm:narrowsWhen/pm:narrowing/pm:condition',
         d_kind    text   PATH 'pm:demand/pm:amount/pm:claim/pm:narrowsWhen/pm:narrowing/pm:kind',
         d_narrows_absent text PATH 'pm:demand/pm:amount/pm:claim/pm:narrowsWhen/pm:absent/pm:reason',
                                                               r_absent text PATH 'pm:remainder/pm:absent/pm:reason',
         r_note   text PATH 'pm:remainder/pm:absent/pm:note',
         sign        text PATH 'pm:remainder/pm:remainder/pm:sign/pm:fit',
         sign_absent text PATH 'pm:remainder/pm:remainder/pm:sign/pm:absent/pm:reason',
         absorber_taxonomy text PATH 'pm:remainder/pm:remainder/pm:absorber/pm:term/pm:taxonomy',
         absorber_value    text PATH 'pm:remainder/pm:remainder/pm:absorber/pm:term/pm:value',
         q_low    numeric PATH 'pm:remainder/pm:remainder/pm:quantity/pm:claim/pm:low',
         q_mode   numeric PATH 'pm:remainder/pm:remainder/pm:quantity/pm:claim/pm:mostLikely',
         q_high   numeric PATH 'pm:remainder/pm:remainder/pm:quantity/pm:claim/pm:high',
         q_unit   text    PATH 'pm:remainder/pm:remainder/pm:quantity/pm:claim/pm:unit',
         q_absent text    PATH 'pm:remainder/pm:remainder/pm:quantity/pm:absent/pm:reason') x;

-- ---------------------------------------------------------------------------
-- Nameplates. WIDE: these are attributes of one supply, not matrix entries.
-- ---------------------------------------------------------------------------
INSERT INTO nameplate
SELECT s.name, x.layer,
       x.a_low, x.a_mode, x.a_high, x.a_unit, x.a_absent::absence_reason, x.a_origin::constraint_origin,
       CASE WHEN x.n_divisibility = 0 THEN NULL ELSE x.n_continuous = 0 END,
       x.div_absent::absence_reason,
       x.k_low, x.k_mode, x.k_high, x.k_unit, x.k_origin::constraint_origin,
       x.w_low, x.w_mode, x.w_high, x.w_unit, x.w_origin::constraint_origin,
       x.w_absent::absence_reason,
       x.dr_low, x.dr_mode, x.dr_high, x.dr_unit, x.dr_absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:layer' PASSING s.body
       COLUMNS
         layer    text PATH 'pm:name',
         a_low    numeric PATH 'pm:supply/pm:nameplate/pm:amount/pm:claim/pm:low',
         a_mode   numeric PATH 'pm:supply/pm:nameplate/pm:amount/pm:claim/pm:mostLikely',
         a_high   numeric PATH 'pm:supply/pm:nameplate/pm:amount/pm:claim/pm:high',
         a_unit   text    PATH 'pm:supply/pm:nameplate/pm:amount/pm:claim/pm:unit',
         a_absent text    PATH 'pm:supply/pm:nameplate/pm:amount/pm:absent/pm:reason',
         a_origin text    PATH 'pm:supply/pm:nameplate/pm:amountOrigin/pm:origin',
         -- ⭐ PRESENCE, NOT VALUE. `continuous` carries a `premium` rather than a size,
         -- because a continuous supply has NO quantum and that is a different thing
         -- from a quantum of zero. So the test is whether the element is there at all.
         n_nameplate  numeric PATH 'count(pm:supply/pm:nameplate)',
         n_continuous numeric PATH 'count(pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:continuous)',
         n_divisibility numeric PATH 'count(pm:supply/pm:nameplate/pm:divisibility/pm:divisibility)',
         div_absent text PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:absent/pm:reason',
         k_low    numeric PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:lumpy/pm:size/pm:claim/pm:low',
         k_mode   numeric PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:lumpy/pm:size/pm:claim/pm:mostLikely',
         k_high   numeric PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:lumpy/pm:size/pm:claim/pm:high',
         k_unit   text    PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:lumpy/pm:size/pm:claim/pm:unit',
         k_origin text    PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:lumpy/pm:origin',
         w_low    numeric PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:window/pm:quantum/pm:size/pm:claim/pm:low',
         w_mode   numeric PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:window/pm:quantum/pm:size/pm:claim/pm:mostLikely',
         w_high   numeric PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:window/pm:quantum/pm:size/pm:claim/pm:high',
         w_unit   text    PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:window/pm:quantum/pm:size/pm:claim/pm:unit',
         w_origin text    PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:window/pm:quantum/pm:origin',
         w_absent text    PATH 'pm:supply/pm:nameplate/pm:divisibility/pm:divisibility/pm:window/pm:absent/pm:reason',
         dr_low   numeric PATH 'pm:supply/pm:jagged/pm:draw/pm:claim/pm:low',
         dr_mode  numeric PATH 'pm:supply/pm:jagged/pm:draw/pm:claim/pm:mostLikely',
         dr_high  numeric PATH 'pm:supply/pm:jagged/pm:draw/pm:claim/pm:high',
         dr_unit  text    PATH 'pm:supply/pm:jagged/pm:draw/pm:claim/pm:unit',
         dr_absent text   PATH 'pm:supply/pm:jagged/pm:draw/pm:absent/pm:reason') x
WHERE x.layer IN (SELECT layer FROM layer WHERE filing = s.name)
  AND x.n_nameplate > 0;   -- `unstated` files a layer with no supply at all

-- ---------------------------------------------------------------------------
-- ⭐ S, TALL. Three inserts, one per buffer, and the union IS the L x 3 matrix.
--   Two of the three live on the supply and one lives on the layer, because a
--   time buffer is a fact about DEMAND and demand is a bare claim with nowhere
--   to hang it. The tall form hides that asymmetry, which is a thing to know
--   rather than a thing to like.
-- ---------------------------------------------------------------------------
-- ✅⭐⭐⭐ `origin_absent` WAS DECLARED IN ALL THREE `COLUMNS` CLAUSES AND SELECTED IN NONE, so
-- `slack.bound_origin_absent` was never once populated. The DDL argues at length for both
-- columns -- "the NULL meant 'nobody asked' and 'nothing sets this bound' indistinguishably" --
-- and the ingest then produced exactly that NULL. It went unnoticed because only three slacks
-- in the corpus were sized at all, and all three stated an origin; the moment a sized slack
-- filed `boundOrigin absent`, the CHECK that a sized slack says who owns its edge caught it.
INSERT INTO slack
SELECT s.name, x.layer, 'time'::buffer, x.low, x.mode, x.high, x.unit,
       x.absent::absence_reason, x.origin::constraint_origin,
       x.origin_absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:layer' PASSING s.body
       COLUMNS layer text PATH 'pm:name',
               low   numeric PATH 'pm:timeSlack/pm:claim/pm:low',
               mode  numeric PATH 'pm:timeSlack/pm:claim/pm:mostLikely',
               high  numeric PATH 'pm:timeSlack/pm:claim/pm:high',
               unit  text    PATH 'pm:timeSlack/pm:claim/pm:unit',
               absent text   PATH 'pm:timeSlack/pm:absent/pm:reason',
               origin text   PATH 'pm:timeSlack/pm:claim/pm:boundOrigin/pm:origin',
               origin_absent text PATH 'pm:timeSlack/pm:claim/pm:boundOrigin/pm:absent/pm:reason') x
WHERE x.layer IN (SELECT layer FROM layer WHERE filing = s.name);

INSERT INTO slack
SELECT s.name, x.layer, x.buf::buffer, x.low, x.mode, x.high, x.unit,
       x.absent::absence_reason, x.origin::constraint_origin,
       x.origin_absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:layer' PASSING s.body
       COLUMNS layer text PATH 'pm:name',
               buf   text PATH '''capacity''',
               low   numeric PATH 'pm:supply/pm:nameplate/pm:capacitySlack/pm:claim/pm:low',
               mode  numeric PATH 'pm:supply/pm:nameplate/pm:capacitySlack/pm:claim/pm:mostLikely',
               high  numeric PATH 'pm:supply/pm:nameplate/pm:capacitySlack/pm:claim/pm:high',
               unit  text    PATH 'pm:supply/pm:nameplate/pm:capacitySlack/pm:claim/pm:unit',
               absent text   PATH 'pm:supply/pm:nameplate/pm:capacitySlack/pm:absent/pm:reason',
               origin text   PATH 'pm:supply/pm:nameplate/pm:capacitySlack/pm:claim/pm:boundOrigin/pm:origin',
               origin_absent text PATH 'pm:supply/pm:nameplate/pm:capacitySlack/pm:claim/pm:boundOrigin/pm:absent/pm:reason') x
WHERE x.layer IN (SELECT layer FROM layer WHERE filing = s.name);

INSERT INTO slack
SELECT s.name, x.layer, 'inventory'::buffer, x.low, x.mode, x.high, x.unit,
       x.absent::absence_reason, x.origin::constraint_origin,
       x.origin_absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:layer' PASSING s.body
       COLUMNS layer text PATH 'pm:name',
               low   numeric PATH 'pm:supply/pm:nameplate/pm:inventorySlack/pm:claim/pm:low',
               mode  numeric PATH 'pm:supply/pm:nameplate/pm:inventorySlack/pm:claim/pm:mostLikely',
               high  numeric PATH 'pm:supply/pm:nameplate/pm:inventorySlack/pm:claim/pm:high',
               unit  text    PATH 'pm:supply/pm:nameplate/pm:inventorySlack/pm:claim/pm:unit',
               absent text   PATH 'pm:supply/pm:nameplate/pm:inventorySlack/pm:absent/pm:reason',
               origin text   PATH 'pm:supply/pm:nameplate/pm:inventorySlack/pm:claim/pm:boundOrigin/pm:origin',
               origin_absent text PATH 'pm:supply/pm:nameplate/pm:inventorySlack/pm:claim/pm:boundOrigin/pm:absent/pm:reason') x
WHERE x.layer IN (SELECT layer FROM layer WHERE filing = s.name);

-- ---------------------------------------------------------------------------
-- ⭐ H, TALL. A row per bearer. No row means that kind bears none of it, and
--   `share_absent` means somebody said so without a number.
-- ---------------------------------------------------------------------------
INSERT INTO holder
SELECT s.name, x.layer, x.kind::holder_kind,
       x.low, x.mode, x.high, x.unit, x.absent::absence_reason, x.party, x.as_of::date
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:layer/pm:remainder/pm:remainder/pm:holder/pm:holder' PASSING s.body
       COLUMNS layer text PATH '../../../../pm:name',
               kind  text PATH 'pm:kind',
               low   numeric PATH 'pm:share/pm:claim/pm:low',
               mode  numeric PATH 'pm:share/pm:claim/pm:mostLikely',
               high  numeric PATH 'pm:share/pm:claim/pm:high',
               unit  text    PATH 'pm:share/pm:claim/pm:unit',
               absent text   PATH 'pm:share/pm:absent/pm:reason',
               party text    PATH 'pm:party',
               as_of text    PATH 'pm:asOf') x;

-- pm:Claim, wherever one appears -- 12 different parents across two schemas.
INSERT INTO claim
SELECT s.name, x.seq, x.owns, x.layer, x.low, x.mode, x.high, x.unit,
       coalesce(x.period, x.each),
       CASE WHEN x.period IS NOT NULL THEN 'period'
            WHEN x.each   IS NOT NULL THEN 'each' END,
       x.absent::absence_reason,
       x.prov_party, x.prov_entered, x.prov_approved,
       x.prov_st_tax, x.prov_st_val, x.prov_st_absent::absence_reason, x.prov_note
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:claim' PASSING s.body
       COLUMNS seq FOR ORDINALITY,
               -- ⛔⛔ TWO SEGMENTS, AND ONE WAS NOT ENOUGH. This read `name(..)`, the
               -- PARENT'S NAME, and called it the position. It is not: three names are
               -- filed at two positions each, so the column silently merged them.
               --   `pm:amount`   `Demand/amount` with `Nameplate/amount`     86 claims
               --   `pm:size`     `lumpy/size` with the WINDOW's `quantum/size`  61
               --   `pm:quantity` `draw/quantity` with `remainder/quantity`      4
               -- A duty cycle is a fraction of the NAMEPLATE's period, and
               -- `units/with_a_period.sqlc` is the one relation that filters on this column.
               -- It read `owns = 'pm:amount'` and therefore answered for the demand too,
               -- returning two rows per layer. Nothing was wrong yet only because no layer
               -- in this corpus disagrees with itself about carrying a period; the day one
               -- does, a window gets measured against the wrong denominator.
               -- ⭐ The grandparent settles all three, and `concat` is ordinary XPath 1.0.
               -- A composite key would settle them too and would put the burden on every
               -- caller to remember the second column, which is the trap rather than the
               -- repair.
               owns text    PATH 'concat(name(../..),"/",name(..))',
               -- ⭐ THE ANCESTOR AXIS, and it is ordinary XPath 1.0 that Postgres XMLTABLE has
               -- had all along. A claim about a coupling or an elimination has no layer
               -- ancestor and lands NULL, which is the right answer rather than a miss.
               layer text   PATH 'ancestor::pm:layer/pm:name',
               low  numeric PATH 'pm:low',
               mode numeric PATH 'pm:mostLikely',
               high numeric PATH 'pm:high',
               unit text    PATH 'pm:unit',
               -- ✅⭐⭐⭐ THE LAST TWO `LIKE`s DIE HERE. The two arms are read separately because
               -- they are two facts: a `period` makes the duty-cycle question answerable, an
               -- `each` says there IS a denominator and it is still not a cycle.
               period text  PATH 'pm:denominator/pm:period',
               each   text  PATH 'pm:denominator/pm:each',
               absent text  PATH 'pm:denominator/pm:absent/pm:reason',
               -- ✅⭐⭐⭐ `pm:Provenance` REACHES THE DATABASE. It appeared nowhere in this file
               -- before, so `standing` -- the axis separating an auditor's observation from a
               -- controller's hunch -- was filed 58 times and readable by nothing.
               prov_party   text PATH 'pm:provenance/pm:party',
               prov_entered text PATH 'pm:provenance/pm:enteredBy',
               prov_approved text PATH 'pm:provenance/pm:approvedBy',
               prov_st_tax  text PATH 'pm:provenance/pm:standing/pm:term/pm:taxonomy',
               prov_st_val  text PATH 'pm:provenance/pm:standing/pm:term/pm:value',
               prov_st_absent text PATH 'pm:provenance/pm:standing/pm:absent/pm:reason',
               prov_note    text PATH 'pm:provenance/pm:note') x;

-- ⭐ Every narrowing anywhere in the document, in document order.
INSERT INTO narrowing
SELECT s.name, x.seq, x.condition, x.kind::narrowing_kind, x.absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:narrowsWhen' PASSING s.body
       COLUMNS seq FOR ORDINALITY,
               condition text PATH 'pm:narrowing/pm:condition',
               kind      text PATH 'pm:narrowing/pm:kind',
               absent    text PATH 'pm:absent/pm:reason') x;

-- pm:Claim/pm:boundOrigin, in the same document order as the claims above.
INSERT INTO bound_origin
SELECT s.name, x.seq, x.origin::constraint_origin, x.absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:boundOrigin' PASSING s.body
       COLUMNS seq FOR ORDINALITY,
               origin text PATH 'pm:origin',
               absent text PATH 'pm:absent/pm:reason') x;

-- ---------------------------------------------------------------------------
-- Operations, and the two matrices that hang off them.
-- ---------------------------------------------------------------------------
INSERT INTO operation
SELECT DISTINCT s.name, x.label
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:operation' PASSING s.body COLUMNS label text PATH 'pm:label') x;

-- ⭐ D, TALL. What an operation takes from a layer, NOW.
INSERT INTO draw
SELECT s.name, x.op, x.layer, x.low, x.mode, x.high, x.unit, x.absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:operation/pm:draw' PASSING s.body
       COLUMNS op    text PATH '../pm:label',
               layer text PATH 'pm:layer',
               low   numeric PATH 'pm:quantity/pm:claim/pm:low',
               mode  numeric PATH 'pm:quantity/pm:claim/pm:mostLikely',
               high  numeric PATH 'pm:quantity/pm:claim/pm:high',
               unit  text    PATH 'pm:quantity/pm:claim/pm:unit',
               absent text   PATH 'pm:quantity/pm:absent/pm:reason') x;

-- ⭐⭐ N, TALL, AND A DIFFERENT TABLE ON PURPOSE despite the identical shape. A draw is
--    consumption that happened; an induction is a commitment that creates a future draw
--    on a DIFFERENT supply. Folding them into one table with a discriminator column
--    would put two kinds of fact in one slot, and `decider`, which only an induction
--    has, is the tell.
INSERT INTO induction
SELECT s.name, x.op, x.layer, x.low, x.mode, x.high, x.unit, x.absent::absence_reason, x.decider
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:operation/pm:induces' PASSING s.body
       COLUMNS op    text PATH '../pm:label',
               layer text PATH 'pm:layer',
               low   numeric PATH 'pm:commitment/pm:claim/pm:low',
               mode  numeric PATH 'pm:commitment/pm:claim/pm:mostLikely',
               high  numeric PATH 'pm:commitment/pm:claim/pm:high',
               unit  text    PATH 'pm:commitment/pm:claim/pm:unit',
               absent text   PATH 'pm:commitment/pm:absent/pm:reason',
               decider text  PATH 'pm:decidedBy') x;

-- ⭐⭐⭐ C, TALL AND ALMOST EMPTY, WHICH IS THE POINT. The stack is ASSUMED to be a set
--    of independent quantizations, so `C = 0` is the assumption and every non-zero entry
--    is an observation somebody made and is required to write down. A filing with no
--    rows here is one where NOBODY LOOKED, not one where nothing was found, and in a
--    tall table those two look identical. See assets/sql/rules.sql, which reports it.
INSERT INTO coupling
SELECT s.name, x.f, x.t, x.low, x.mode, x.high, x.unit,
       x.s_absent::absence_reason, x.observed
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:couplings/pm:coupling' PASSING s.body
       COLUMNS f text PATH 'pm:from',
               t text PATH 'pm:to',
               low  numeric PATH 'pm:strength/pm:claim/pm:low',
               mode numeric PATH 'pm:strength/pm:claim/pm:mostLikely',
               high numeric PATH 'pm:strength/pm:claim/pm:high',
               unit text    PATH 'pm:strength/pm:claim/pm:unit',
               -- ⭐ The same third state on the other optional StatedClaim: a dependence
               --   somebody observed and could not size is not a dependence with no strength.
               s_absent text PATH 'pm:strength/pm:absent/pm:reason',
               observed text PATH 'pm:observed') x;

-- ⭐⭐⭐ AND THE ROW THAT MAKES THE EMPTINESS ABOVE READABLE. One per filing that files no
--    couplings, carrying the reason the filer gave. Until `Stack/couplings` became a
--    `StatedCouplings` there was nothing to insert here, because the document did not say.
INSERT INTO coupling_search
SELECT s.name, x.absent::absence_reason, x.note
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:couplings' PASSING s.body
       COLUMNS absent text PATH 'pm:absent/pm:reason',
               note   text PATH 'pm:absent/pm:note') x
WHERE s.name IN (SELECT name FROM filing);

-- ---------------------------------------------------------------------------
-- ⭐ F AND Phi IN ONE TABLE, because a part IS an incidence entry and its conversion
--   factor at the same time. A NULL factor means the units already agree, which is
--   phi = 1 and is filed by OMISSION rather than by writing 1 three times.
--   Two nested XMLTABLEs: the outer one yields each fusion and captures its own
--   element as `frag`, the inner one reads the parts out of that fragment. XPath has
--   no join, so this is where relational algebra starts earning its keep.
-- ---------------------------------------------------------------------------
INSERT INTO part
SELECT s.name, f.composed, p.pf, p.pl, p.f_low, p.f_mode, p.f_high,
       p.f_absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '//asrt:fusion' PASSING s.body
       COLUMNS composed text PATH 'asrt:name', frag xml PATH '.') f,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt,
                            'https://example.invalid/process-flow/1.0' AS pm),
       '/asrt:fusion/asrt:part' PASSING f.frag
       COLUMNS pf text PATH 'asrt:layer/asrt:filing/pm:notation',
               pl text PATH 'asrt:layer/asrt:filing/pm:id',
               f_low  numeric PATH 'asrt:factor/pm:claim/pm:low',
               f_mode numeric PATH 'asrt:factor/pm:claim/pm:mostLikely',
               f_high numeric PATH 'asrt:factor/pm:claim/pm:high',
               -- ⭐ THE THIRD STATE. Without this path a conversion nobody measured arrives as
               --   three NULLs, indistinguishable from a part already in the composed unit,
               --   and composition/converted.sqlc's coalesce(.., 1) then asserts phi = 1 for a
               --   rate no composer filed. `asrt:Part/factor` is minOccurs="0" over
               --   pm:StatedClaim, so it admits all three; this reads the one that was lost.
               f_absent text PATH 'asrt:factor/pm:absent/pm:reason') p;

-- e_x. One row per quantity eliminated, and `absent reason="none"` is the common case:
-- somebody checked and nothing was double counted.
INSERT INTO elimination
SELECT s.name, f.composed, e.against, e.low, e.mode, e.high, e.unit,
       e.absent::absence_reason, e.observed
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '//asrt:fusion' PASSING s.body
       COLUMNS composed text PATH 'asrt:name', frag xml PATH '.') f,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt,
                            'https://example.invalid/process-flow/1.0' AS pm),
       '/asrt:fusion/asrt:eliminations/asrt:elimination' PASSING f.frag
       COLUMNS against text PATH 'asrt:against',
               low  numeric PATH 'asrt:quantity/pm:claim/pm:low',
               mode numeric PATH 'asrt:quantity/pm:claim/pm:mostLikely',
               high numeric PATH 'asrt:quantity/pm:claim/pm:high',
               unit text    PATH 'asrt:quantity/pm:claim/pm:unit',
               absent text  PATH 'asrt:quantity/pm:absent/pm:reason',
               observed text PATH 'asrt:observed') e;

-- ⭐⭐ AND THE SAME ROW ONE DOCUMENT UP: which fusions looked for double counting, and what
--    they found. Three of this corpus's eight file no elimination, and until now that was
--    indistinguishable from three composers who never checked.
INSERT INTO elimination_search
SELECT s.name, f.composed, e.absent::absence_reason, e.note
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '//asrt:fusion' PASSING s.body
       COLUMNS composed text PATH 'asrt:name', frag xml PATH '.') f,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt,
                            'https://example.invalid/process-flow/1.0' AS pm),
       '/asrt:fusion/asrt:eliminations' PASSING f.frag
       COLUMNS absent text PATH 'asrt:absent/pm:reason',
               note   text PATH 'asrt:absent/pm:note') e;

-- ⭐⭐⭐ THE LAYERS THE DOUBLE COUNT RUNS BETWEEN, WHICH IS THE EVIDENCE FOR THE ELIMINATION.
--    `asrt:Elimination/between` is `maxOccurs="unbounded"` and had no home in this database at
--    all until 2026-09-06, so eight of them in `merge-holding-composition` and
--    `merge-group-composition` were read from the XML and dropped on the floor. Nothing noticed
--    because no rule reads them: a rule reads only what it needs, and a field no rule reads is
--    under no pressure to exist. Only asking "could I WRITE this document back out" finds it.
-- ⭐ `FOR ORDINALITY` keeps two `between` elements two rows rather than one, the same reason
--   `regime` uses it above.
INSERT INTO elimination_between
SELECT s.name, f.composed, e.against, b.seq, b.party, b.notation, b.layer, b.version, b.regime
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '//asrt:fusion' PASSING s.body
       COLUMNS composed text PATH 'asrt:name', frag xml PATH '.') f,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '/asrt:fusion/asrt:eliminations/asrt:elimination' PASSING f.frag
       COLUMNS against text PATH 'asrt:against', efrag xml PATH '.') e,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt,
                            'https://example.invalid/process-flow/1.0' AS pm),
       '/asrt:elimination/asrt:between' PASSING e.efrag
       COLUMNS seq      FOR ORDINALITY,
               party    text PATH 'asrt:party',
               notation text PATH 'asrt:filing/pm:notation',
               layer    text PATH 'asrt:filing/pm:id',
               version  text PATH 'asrt:version',
               regime   text PATH 'asrt:regime') b;

-- ⭐ THE STANDARDS THE COMPOSITION WORKS UNDER. Homeless for the same reason and until the same
--   date. `asrt:Composition/citation` sits at the document root rather than inside a fusion.
INSERT INTO composition_citation
SELECT s.name, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt,
                            'https://example.invalid/process-flow/1.0' AS pm),
       '//asrt:composition/asrt:citation' PASSING s.body
       COLUMNS seq        FOR ORDINALITY,
               -- ⭐ `instrument` is a pm:BorrowedTerm, so it is a taxonomy AND a value, never the
               --   element's text. Reading the element whole returns the whitespace between the
               --   two children, which looks like a value and is not one.
               taxonomy   text PATH 'asrt:instrument/pm:taxonomy',
               instrument text PATH 'asrt:instrument/pm:value',
               clause     text PATH 'asrt:clause',
               version    text PATH 'asrt:version') c;

COMMIT;
