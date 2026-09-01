-- Load assets/corpus/*.xml into the relations declared by assets/sql/schema.ddl.
--
-- ⛔ RUN THIS FROM THE REPOSITORY ROOT: psql -f assets/sql/ingest.sql
--    The `\set` lines below run `cat` on the CLIENT, so the paths are relative to
--    wherever you invoked psql. Nothing here needs superuser and nothing reads a
--    file from the server, which is the point: no Rust, no extensions, no setup.
--
-- ⭐ EVERY DOCUMENT LANDS IN ONE `source` TABLE FIRST and every extraction below
--    reads from there. So exactly one place in this file touches the filesystem,
--    and the rest is ordinary SQL you can run again without re-reading anything.

SET search_path TO pm, public;

BEGIN;

TRUNCATE source, elimination, elimination_search, part, coupling, coupling_search,
         induction, draw, operation, holder, slack, nameplate, layer, regime,
         narrowing, bound_origin, stack_scope, filing CASCADE;

\set d `cat assets/corpus/enterprise-contract.xml`
INSERT INTO source VALUES ('enterprise-contract', XMLPARSE(DOCUMENT :'d'));
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

-- ---------------------------------------------------------------------------
-- Filings.
-- ---------------------------------------------------------------------------
INSERT INTO filing (name, kind, evidence)
SELECT s.name,
       CASE WHEN s.body::text LIKE '%<asrt:composition%' THEN 'composition' ELSE 'filing' END,
       -- ⚠️ Read off the document's own first line, not off which \set loaded it. A fixture
       -- that stopped announcing itself would land in the corpus silently, and
       -- tests/fixtures.rs asserts the announcement is there for exactly this reason.
       CASE WHEN s.body::text LIKE '%A STIPULATION, NOT A FILING%' THEN 'fixture' ELSE 'corpus' END
FROM source s;

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
       x.sign::fit, x.sign_absent::absence_reason, x.absorber_taxonomy, x.absorber_value,
       x.q_low, x.q_mode, x.q_high, x.q_unit, x.q_absent::absence_reason
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:layer' PASSING s.body
       COLUMNS
         name     text    PATH 'pm:name',
         d_low    numeric PATH 'pm:demand/pm:claim/pm:low',
         d_mode   numeric PATH 'pm:demand/pm:claim/pm:mostLikely',
         d_high   numeric PATH 'pm:demand/pm:claim/pm:high',
         d_unit   text    PATH 'pm:demand/pm:claim/pm:unit',
         d_absent text    PATH 'pm:demand/pm:absent/pm:reason',
         d_narrows text   PATH 'pm:demand/pm:claim/pm:narrowsWhen/pm:narrowing/pm:condition',
         d_kind    text   PATH 'pm:demand/pm:claim/pm:narrowsWhen/pm:narrowing/pm:kind',
         d_narrows_absent text PATH 'pm:demand/pm:claim/pm:narrowsWhen/pm:absent/pm:reason',
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
       x.absent::absence_reason, x.origin::constraint_origin
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

-- ⭐ And every bound origin, in the same document order, so the two can be joined on `seq`:
--   a claim's Nth narrowing and its Nth origin are the same claim's.
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
--    would put two kinds of fact in one slot, and `decider` — which only an induction
--    has — is the tell.
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
--    rows here is one where NOBODY LOOKED, not one where nothing was found — and in a
--    tall table those two look identical. See assets/sql/rules.sql, which reports it.
INSERT INTO coupling
SELECT s.name, x.f, x.t, x.low, x.mode, x.high, x.unit, x.observed
FROM source s,
     XMLTABLE(XMLNAMESPACES('https://example.invalid/process-flow/1.0' AS pm),
       '//pm:stack/pm:couplings/pm:coupling' PASSING s.body
       COLUMNS f text PATH 'pm:from',
               t text PATH 'pm:to',
               low  numeric PATH 'pm:strength/pm:claim/pm:low',
               mode numeric PATH 'pm:strength/pm:claim/pm:mostLikely',
               high numeric PATH 'pm:strength/pm:claim/pm:high',
               unit text    PATH 'pm:strength/pm:claim/pm:unit',
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
--
--   Two nested XMLTABLEs: the outer one yields each fusion and captures its own
--   element as `frag`, the inner one reads the parts out of that fragment. XPath has
--   no join, so this is where relational algebra starts earning its keep.
-- ---------------------------------------------------------------------------
INSERT INTO part
SELECT s.name, f.composed, p.pf, p.pl, p.f_low, p.f_mode, p.f_high
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
               f_high numeric PATH 'asrt:factor/pm:claim/pm:high') p;

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

COMMIT;
