-- process-modulus, as relations.
--
-- ⛔ THIS IS BUILT FOR PROOF AND IT IS NOT A RECOMMENDED DATABASE SCHEMA. Nothing here
--    is normalised for writing, indexed for a workload, or shaped for an application.
--    It exists so that the claims the XSD cannot check can be checked, and so that the
--    matrices in docs/linear-algebra.md can be pulled out and
--    multiplied. Copy the ideas, not the layout.
--
-- Run it with:  psql -f assets/ddl/schema.ddl
-- Then ingest:  psql -f assets/sql/ingest.sql   (from the repository root; it reads
--                                                assets/corpus/ and assets/fixtures/)

BEGIN;

DROP SCHEMA IF EXISTS pm CASCADE;
CREATE SCHEMA pm;
SET search_path TO pm, public;

-- ---------------------------------------------------------------------------
-- The four closed sets. Two are borrowed and two are this model's own, and the
-- enum is where that stops being a comment and starts being enforced.
-- ---------------------------------------------------------------------------

-- Borrowed from ISO 286. Three classes, and `transition` is the one that means
-- short at the top of the demand range and spare at the bottom: both, at once.
CREATE TYPE fit AS ENUM ('clearance', 'transition', 'interference');

-- This model's own. Only `booked` leaves a transaction behind.
CREATE TYPE holder_kind AS ENUM ('booked', 'counterparty', 'customer', 'people', 'unrealised');

-- ⭐ THIS MODEL'S OWN, AND NOT THE BORROWED SET IT LOOKS LIKE. These three name the
--    three ELEMENTS a layer carries — `capacitySlack`, `inventorySlack`, `timeSlack` —
--    which are structural and belong to this schema. The BUFFER a remainder names is a
--    different thing: see `layer.absorber_*` below.
CREATE TYPE buffer AS ENUM ('inventory', 'capacity', 'time');

-- Who you would have to talk to in order to change it.
CREATE TYPE constraint_origin AS ENUM ('intrinsic', 'contractual', 'policy');

-- ⭐ A BLANK THAT SAYS WHICH KIND OF BLANK IT IS. In SQL a NULL says nothing about
--    why it is null, which is the exact failure the model exists to avoid. So every
--    quantity below carries BOTH a nullable triple and a reason, and exactly one of
--    the two is populated. The CHECK constraints make that a checked property.
CREATE TYPE absence_reason AS ENUM ('none', 'unmeasured', 'notApplicable', 'derived');

-- ⭐ This model's own, added when `narrowsWhen` stopped being an optional bare string.
CREATE TYPE narrowing_kind AS ENUM ('instrument', 'intervention', 'experiment');

-- ---------------------------------------------------------------------------
-- Documents.
-- ---------------------------------------------------------------------------

-- The XML as it arrived. Exactly one table touches the filesystem, in sql/ingest.sql,
-- and everything else in this schema is derived from here by ordinary SQL.
CREATE TABLE source (
    name text PRIMARY KEY,
    body xml  NOT NULL
);

CREATE TABLE filing (
    name text PRIMARY KEY REFERENCES source(name),
    kind text NOT NULL CHECK (kind IN ('filing', 'composition')),

    -- ⛔⛔ WHAT THIS DOCUMENT IS EVIDENCE FOR, and it is a SECOND AXIS rather than a third
    -- `kind`. A fixture is still a filing or a composition; what differs is what it attests.
    -- Folding the two into one column would put two kinds of fact in one slot, which is the
    -- flattening `pm:Provenance` and `pm:Holder` both reject.
    --
    -- ⭐ THE RULES MUST RUN ON FIXTURES -- that is what a fixture is for. THE REPORTS MUST
    -- NOT: "no stack in this corpus asserts independence" is a fact about the evidence, and a
    -- stipulation that asserts it would make the finding a lie. See assets/fixtures/README.md.
    evidence text NOT NULL CHECK (evidence IN ('corpus', 'fixture'))
);

-- ⭐ TALL BECAUSE A FILING CAN REPORT UNDER MORE THAN ONE REGIME, and `refutation`
--    does: the same Portuguese microentity is `NC-ME` to one authority and `M` to
--    another, the two published code lists do not line up, and neither declaration
--    says what the pair says. A `jurisdiction` column on `filing` would have forced
--    the sender to pick one and thrown away the disagreement, which is the document's
--    entire subject. The first draft of this file had that column. It lasted one run.
CREATE TABLE regime (
    filing       text NOT NULL REFERENCES filing(name),
    seq          int  NOT NULL,
    id           text,
    jurisdiction text,
    framework    text,
    PRIMARY KEY (filing, seq)
);

-- ---------------------------------------------------------------------------
-- Layers. WIDE, because these columns are attributes of one layer rather than
-- entries of a matrix. Compare `slack` and `holder` below, which are TALL.
-- ---------------------------------------------------------------------------

-- ⭐ THE KEY COLUMN IS `layer` AND NOT `name`, WHICH LOOKS ODD FOR ABOUT ONE MINUTE.
--    Every other table below keys on (filing, layer), so naming it the same here makes
--    `USING (filing, layer)` read identically in every join in sql/matrices.sql and
--    sql/rules.sql. In a file whose job is to be read, one uniform join beats one
--    natural-looking column.
CREATE TABLE layer (
    filing        text NOT NULL REFERENCES filing(name),
    layer         text NOT NULL,

    -- demand: a three-point claim, or a typed absence
    demand_low    numeric,
    demand_mode   numeric,
    demand_high   numeric,
    demand_unit   text,
    demand_absent absence_reason,
    -- ⭐ WHAT WOULD TIGHTEN THE BOUNDS. Optional in the schema, because requiring it is
    --    expensive in a chain of parties — but the annotation says a claim without one is
    --    WEAKER and a receiver is entitled to say so. Carrying it here is how a receiver
    --    says so with a number instead of an opinion.
    demand_narrows text,
    -- ⭐⭐ WHAT KIND OF ACT WOULD TIGHTEN IT, WHICH SAYS WHAT THE WIDTH IS MADE OF.
    --    `instrument` = the width is IGNORANCE, a better measurement reveals it.
    --    `intervention` = the width is VARIATION, only changing the process reduces it.
    --    `experiment` = the filer does not know which, and names what would settle it.
    --    A NULL here with `demand_narrows_absent = 'none'` is ALSO the variation claim:
    --    somebody looked and nothing would tighten this.
    demand_narrows_kind   narrowing_kind,
    demand_narrows_absent absence_reason,

    -- ⭐⭐⭐ THE WRAPPER THAT LETS THE MODEL BE CONTRADICTED, AND THIS DATABASE USED TO
    --     THROW IT AWAY. `StatedRemainder` is a CHOICE -- a remainder, or a typed reason
    --     there is none -- and EVERY layer is required to carry one, precisely so that a
    --     sender who disagrees with "every layer has a remainder" has to say so EXPLICITLY
    --     rather than leaving a field empty. `ingest.sql` read only the first branch, so
    --     the two corpus layers that take the second landed here as five NULLs: sign,
    --     absorber and quantity all blank, which is indistinguishable from a document that
    --     said nothing at all.
    --
    --  ⛔⛔ AND ONE OF THEM SAYS SO IN THE NOTE, WHICH IS WHY THE NOTE IS STORED.
    --     `refutation/object-storage` files `reason=none` with: "a supply with no quantum
    --     divides exactly. Filed as a counter-example to the claim that every layer carries
    --     a remainder, NOT AS A GAP IN THIS DOCUMENT." A gap is exactly what was stored.
    --     Keeping only the reason keeps the fact and loses the argument, and the argument
    --     is what the document was written to make.
    remainder_absent      absence_reason,
    remainder_absent_note text,

    -- the remainder's two halves: which side it is on, and how big it is
    sign          fit,
    sign_absent   absence_reason,

    -- ⛔⛔ THE ABSORBER IS A BORROWED TERM AND NOT AN ENUM, AND THE FIRST DRAFT OF THIS
    --     FILE GOT IT WRONG IN THE MOST INSTRUCTIVE WAY AVAILABLE. It declared
    --     `absorber buffer` and the corpus refused to load: `invalid input value for
    --     enum buffer: "capacidade"`. The Portuguese filing cites a TRANSLATED EDITION
    --     of Factory Physics, `urn:example:pt:fisica-da-fabrica:amortecedores`, and its
    --     absorber is `capacidade`. That filing is correct. The enum was the fork, and
    --     the README says so in as many words: "a restated value set is a fork, and a
    --     fork drifts with nothing here able to notice that it has".
    --  ⭐ So the value travels WITH the authority that defines it, and comparing two
    --     filings that cite different authorities is a step somebody has to take on
    --     purpose. See `buffer_term`.
    absorber_taxonomy text,
    absorber_value    text,
    qty_low       numeric,
    qty_mode      numeric,
    qty_high      numeric,
    qty_unit      text,
    qty_absent    absence_reason,

    PRIMARY KEY (filing, layer),
    CONSTRAINT demand_is_stated_or_typed_absent
        CHECK ((demand_low IS NOT NULL) <> (demand_absent IS NOT NULL)),
    -- ⛔⛔⛔ A THREE-POINT CLAIM IS WHOLE OR IT IS ABSENT, AND `num_nonnulls` IS WHY THIS FORM
    --   RATHER THAN THE OBVIOUS ONE. This constraint used to read
    --       CHECK (demand_low IS NULL OR (demand_low <= demand_mode AND demand_mode <= demand_high))
    --   which READS correctly and ENFORCES nothing: with `demand_mode` NULL the comparison is
    --   NULL, and a CHECK passes on NULL. Half a claim could be filed, and what it became
    --   downstream was not a blank -- `greatest(NULL, 0)` ignores the NULL and returns a zero
    --   exposure, and the fit CASE falls through to `transition`. A typed absence flattened
    --   into a filed answer, which is the one thing this model exists to refuse.
    --   Counting the non-nulls first is what makes the comparison two-valued.
    -- ⭐ AND THE UNIT IS PART OF THE CLAIM. `Claim` requires low, mostLikely, high AND unit
    --   together; XSD gets that structurally and the relational form has to say it. Every
    --   other three-point claim in this file carries the same constraint under the same name.
    CONSTRAINT a_demand_claim_is_whole_and_ordered
        CHECK (num_nonnulls(demand_low, demand_mode, demand_high) = 0
               OR (num_nonnulls(demand_low, demand_mode, demand_high, demand_unit) = 4
                   AND demand_low <= demand_mode AND demand_mode <= demand_high)),
    -- ⭐ A layer files a remainder or says why it has none -- never both, never neither.
    --   The denial is of the WHOLE element, so when it is present the remainder's own three
    --   parts must be empty. XSD gets this structurally, because sign, absorber and quantity
    --   live inside the element that was declined; the relational form has to say it.
    CONSTRAINT a_layer_files_a_remainder_or_says_why_not
        CHECK ((remainder_absent IS NOT NULL) = (sign IS NULL AND sign_absent IS NULL
                                             AND qty_low IS NULL AND qty_absent IS NULL
                                             AND absorber_taxonomy IS NULL)),
    -- ⛔ AND INSIDE A FILED REMAINDER, THE SAME STATED-OR-TYPED-ABSENT RULE AS EVERYWHERE
    --   ELSE. Both of these were missing: a filed remainder could carry neither a sign nor
    --   a reason for having none, and the corpus happened not to.
    CONSTRAINT a_filed_remainder_states_or_types_its_sign
        CHECK (remainder_absent IS NOT NULL
               OR ((sign IS NOT NULL) <> (sign_absent IS NOT NULL))),
    CONSTRAINT a_filed_remainder_states_or_types_its_quantity
        CHECK (remainder_absent IS NOT NULL
               OR ((qty_low IS NOT NULL) <> (qty_absent IS NOT NULL))),
    CONSTRAINT a_qty_claim_is_whole_and_ordered
        CHECK (num_nonnulls(qty_low, qty_mode, qty_high) = 0
               OR (num_nonnulls(qty_low, qty_mode, qty_high, qty_unit) = 4
                   AND qty_low <= qty_mode AND qty_mode <= qty_high))
);

CREATE TABLE nameplate (
    filing         text NOT NULL,
    layer          text NOT NULL,

    amount_low     numeric,
    amount_mode    numeric,
    amount_high    numeric,
    amount_unit    text,
    amount_absent  absence_reason,
    amount_origin  constraint_origin,

    -- divisibility, axis one: AMOUNT. lumpy carries a quantum; continuous has none,
    -- and that is a different thing from a quantum of zero.
    --
    -- ⛔ NULLABLE, AND THE CORPUS IS WHY. A first draft declared this `boolean NOT NULL`
    --    and `unstated` refused to load: it files `divisibility` as a TYPED ABSENCE, so
    --    the supply is neither lumpy nor continuous — nobody said which. A boolean has
    --    two states and this question has three, which is the same mistake the three
    --    buffer slacks were before they stopped being booleans. Twice now, in this file,
    --    a two-valued column has met a three-valued fact.
    lumpy          boolean,
    divisibility_absent absence_reason,
    quantum_low    numeric,
    quantum_mode   numeric,
    quantum_high   numeric,
    quantum_unit   text,
    quantum_origin constraint_origin,

    -- divisibility, axis two: TIME. The machine that runs 02:00 to 05:00. A supply can
    -- be lumpy in amount AND intermittent in time, which is why this is a second axis
    -- rather than a third value of the first.
    --
    -- ⛔⛔ AND `window_absent` IS THE THIRD TWO-VALUED COLUMN IN THIS FILE TO MEET A
    --    THREE-VALUED FACT, AFTER `lumpy` ABOVE AND THE THREE SLACKS BEFORE IT. A NULL
    --    window used to mean three things at once and the schema's own annotation
    --    described all three in prose it could not file: `notApplicable` on a unit with
    --    no denominator (twenty of this corpus's layers), `none` for a supply that runs
    --    continuously, `unmeasured` for one nobody asked about. The last of those is the
    --    one that matters arithmetically — it is the state in which a time slack CANNOT
    --    be derived from a clearance, because nobody knows whether the spare is spread
    --    evenly across the period.
    window_low     numeric,
    window_mode    numeric,
    window_high    numeric,
    window_unit    text,
    window_origin  constraint_origin,
    window_absent  absence_reason,

    -- what the supply actually served, which is neither what was asked nor committed
    draw_low       numeric,
    draw_mode      numeric,
    draw_high      numeric,
    draw_unit      text,
    draw_absent    absence_reason,

    PRIMARY KEY (filing, layer),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT a_quantum_exists_exactly_when_the_supply_is_lumpy
        CHECK ((lumpy IS TRUE) = (quantum_low IS NOT NULL)),
    CONSTRAINT divisibility_is_stated_or_typed_absent
        CHECK ((lumpy IS NULL) = (divisibility_absent IS NOT NULL)),
    -- A window is a size or a typed reason there is none -- never a blank, and never
    -- both. Enforced here because XSD enforces it there.
    CONSTRAINT a_window_is_stated_or_typed_absent
        CHECK (divisibility_absent IS NOT NULL
               OR (window_low IS NOT NULL) <> (window_absent IS NOT NULL)),
    CONSTRAINT a_amount_claim_is_whole_and_ordered
        CHECK (num_nonnulls(amount_low, amount_mode, amount_high) = 0
               OR (num_nonnulls(amount_low, amount_mode, amount_high, amount_unit) = 4
                   AND amount_low <= amount_mode AND amount_mode <= amount_high)),
    CONSTRAINT a_quantum_claim_is_whole_and_ordered
        CHECK (num_nonnulls(quantum_low, quantum_mode, quantum_high) = 0
               OR (num_nonnulls(quantum_low, quantum_mode, quantum_high, quantum_unit) = 4
                   AND quantum_low <= quantum_mode AND quantum_mode <= quantum_high)),
    CONSTRAINT a_window_claim_is_whole_and_ordered
        CHECK (num_nonnulls(window_low, window_mode, window_high) = 0
               OR (num_nonnulls(window_low, window_mode, window_high, window_unit) = 4
                   AND window_low <= window_mode AND window_mode <= window_high)),
    CONSTRAINT a_draw_claim_is_whole_and_ordered
        CHECK (num_nonnulls(draw_low, draw_mode, draw_high) = 0
               OR (num_nonnulls(draw_low, draw_mode, draw_high, draw_unit) = 4
                   AND draw_low <= draw_mode AND draw_mode <= draw_high))
);

-- ⭐⭐⭐ EVERY THREE-POINT CLAIM IN A DOCUMENT, AND THE ELEMENT THAT MADE IT. `Claim` is the
-- most reused type in the schema -- demands, nameplates, quanta, windows, draws, slacks,
-- shares, factors, coupling strengths and eliminated quantities are all Claims -- so each of
-- those tables carries its own copy of low/mostLikely/high/unit as columns of the thing it
-- describes. That is the right shape for asking about a demand. It is the wrong shape, and
-- for a while the only shape, for asking about A CLAIM.
--
-- ⛔⛔⛔ WHAT THE MISSING TABLE COST, EXACTLY. `narrowsWhen` and `boundOrigin` were ingested
-- as bare document ordinals with no way back to the claim that made them, so the two rules
-- that read a narrowing against its own width -- "a point value files narrowsWhen as
-- notApplicable" and its converse -- could only be written over `layer.demand_*`, the one
-- copy reachable from a table. No demand in this corpus is a point value, so one of them
-- reported ⛔ VACUOUS and the other examined 40 of 182 claims and passed. The claim it could
-- not see was a RANGED elimination quantity filing `notApplicable`, carrying a note pasted
-- verbatim from the point-valued claim beside it -- which is the failure the rule's own
-- comment names in those words.
--
-- ⭐⭐ AND THE ORDINAL BECOMES STRUCTURAL RATHER THAN LUCKY. `narrowing` and `bound_origin`
-- keyed on a document-order ordinal and were joinable only because `Claim` requires exactly
-- one of each, so the Nth of one belongs to the Nth of the other. That held, and nothing
-- checked it: a desynchronised stream would have attributed every edge to the wrong claim in
-- silence. Both tables now reference this one, so the coincidence is a foreign key.
CREATE TABLE claim (
    filing text NOT NULL REFERENCES filing(name),
    seq    int  NOT NULL,          -- document order; the Nth pm:claim in the document
    owns   text NOT NULL,          -- the element the claim is the value OF: pm:demand, pm:share
    low    numeric NOT NULL,
    mode   numeric NOT NULL,
    high   numeric NOT NULL,
    unit   text    NOT NULL,
    PRIMARY KEY (filing, seq),
    CONSTRAINT a_claim_is_ordered
        CHECK (low <= mode AND mode <= high)
);

-- ⭐⭐⭐ EVERY NARROWING IN A DOCUMENT, WHEREVER IT SITS. `narrowsWhen` is on `Claim`, and
-- claims are on demands, nameplates, quanta, slacks, shares, factors and coupling
-- strengths. Pulling them into one table is what makes the question askable at all:
-- ACROSS THIS WHOLE FILING, HOW MUCH OF THE UNCERTAINTY IS IGNORANCE AND HOW MUCH IS THE
-- WORLD MOVING? That is the grain question, and before `narrowsWhen` gained a kind there
-- was nothing to group by.
CREATE TABLE narrowing (
    filing    text NOT NULL REFERENCES filing(name),
    seq       int  NOT NULL,
    condition text,
    kind      narrowing_kind,
    absent    absence_reason,
    PRIMARY KEY (filing, seq),
    FOREIGN KEY (filing, seq) REFERENCES claim(filing, seq),
    CONSTRAINT a_narrowing_is_stated_or_typed_absent
        CHECK ((kind IS NOT NULL) <> (absent IS NOT NULL))
);

-- ⭐⭐⭐ AND ITS PAIR, IN THE SAME SHAPE AND FOR THE SAME REASON. `narrowsWhen` says what
-- would make a range SMALLER; `boundOrigin` says WHO OWNS THE EDGE it would move. Both sit
-- on `Claim`, so both are scattered across demands, nameplates, quanta, slacks, shares,
-- factors and coupling strengths, and neither question can be asked of a document until the
-- rows are in one place.
--
-- ⛔⛔ THE COLUMN THIS TABLE REPLACES WAS `slack.bound_origin` ALONE, AND THAT IS WHY THE
-- QUESTION LOOKED ANSWERED. `boundOrigin` was optional on every claim and filed once in 124,
-- so the only rows worth ingesting were the two sized slacks -- which made the field look
-- like a slack attribute rather than what it is. Required and typed, it turns out that
-- roughly a third of this corpus's claims answer `derived`: the model ALREADY states the
-- author of that edge in a sibling element (`Nameplate/amountOrigin`, `LumpyQuantum/origin`)
-- and had no way to say so. That is a finding the single column could not produce.
CREATE TABLE bound_origin (
    filing text NOT NULL REFERENCES filing(name),
    seq    int  NOT NULL,
    origin constraint_origin,
    absent absence_reason,
    PRIMARY KEY (filing, seq),
    FOREIGN KEY (filing, seq) REFERENCES claim(filing, seq),
    CONSTRAINT an_origin_is_stated_or_typed_absent
        CHECK ((origin IS NOT NULL) <> (absent IS NOT NULL))
);

-- ---------------------------------------------------------------------------
-- ⭐⭐ THE TALL TABLES. Each one IS a matrix from the linear-algebra note, in the
-- form a matrix takes when it is sparse: a row per non-zero entry and no row at
-- all where there is nothing.
--
-- That absence is not a technicality. `C = 0` is this model's ASSUMPTION, so an
-- empty `coupling` table is a document where nobody looked rather than a document
-- where nothing was found — which is the typed-absence argument arriving from the
-- relational side instead of the schema side.
-- ---------------------------------------------------------------------------

-- S, L x 3. One row per buffer per layer: how much that buffer holds, in the
-- layer's unit. These were booleans once, and a bit says a buffer EXISTS rather
-- than how much it holds, so any share fitted.
CREATE TABLE slack (
    filing       text NOT NULL,
    layer        text NOT NULL,
    buffer       buffer NOT NULL,
    low          numeric,
    mode         numeric,
    high         numeric,
    unit         text,
    absent       absence_reason,
    -- ⭐⭐ WHO OWNS THE EDGE, AND WHY BOTH COLUMNS ARE HERE. `Claim/boundOrigin` was an
    -- optional bare enumeration filed ONCE in 124 claims, so this column was almost
    -- entirely NULL and the NULL meant "nobody asked" and "nothing sets this bound"
    -- indistinguishably. The second reading is the common one: a range read off a year
    -- of history has edges nobody chose, and an SLA has edges somebody negotiated.
    bound_origin constraint_origin,
    bound_origin_absent absence_reason,
    PRIMARY KEY (filing, layer, buffer),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT slack_is_stated_or_typed_absent
        CHECK ((low IS NOT NULL) <> (absent IS NOT NULL)),
    CONSTRAINT a_sized_slack_says_who_owns_its_edge
        CHECK (low IS NULL
               OR (bound_origin IS NOT NULL) <> (bound_origin_absent IS NOT NULL)),
    CONSTRAINT a_slack_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high))
);

-- H, L x 5. Who bears the remainder and how much of it. A DISTRIBUTION rather than
-- a selection: one remainder routinely lands on several parties at once.
CREATE TABLE holder (
    filing     text NOT NULL,
    layer      text NOT NULL,
    kind       holder_kind NOT NULL,
    share_low  numeric,
    share_mode numeric,
    share_high numeric,
    share_unit text,
    share_absent absence_reason,
    party      text,
    as_of      date,
    PRIMARY KEY (filing, layer, kind),   -- a kind appears at most once per remainder
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT party_and_as_of_belong_to_a_counterparty
        CHECK (kind = 'counterparty' OR (party IS NULL AND as_of IS NULL)),
    CONSTRAINT a_counterparty_names_its_party
        CHECK (kind <> 'counterparty' OR party IS NOT NULL),
    CONSTRAINT a_share_claim_is_whole_and_ordered
        CHECK (num_nonnulls(share_low, share_mode, share_high) = 0
               OR (num_nonnulls(share_low, share_mode, share_high, share_unit) = 4
                   AND share_low <= share_mode AND share_mode <= share_high))
);

CREATE TABLE operation (
    filing text NOT NULL REFERENCES filing(name),
    label  text NOT NULL,
    PRIMARY KEY (filing, label)
);

-- D, P x L. What an operation takes from a layer, now.
CREATE TABLE draw (
    filing    text NOT NULL,
    operation text NOT NULL,
    layer     text NOT NULL,
    low       numeric,
    mode      numeric,
    high      numeric,
    unit      text,
    absent    absence_reason,
    PRIMARY KEY (filing, operation, layer),
    FOREIGN KEY (filing, operation) REFERENCES operation(filing, label),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT a_draw_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high))
);

-- N, P x L. A commitment made here that becomes a draw somewhere else, and who
-- made it. Deliberately a different table from `draw` despite the same shape.
CREATE TABLE induction (
    filing    text NOT NULL,
    operation text NOT NULL,
    layer     text NOT NULL,
    low       numeric,
    mode      numeric,
    high      numeric,
    unit      text,
    absent    absence_reason,
    decider   text,
    PRIMARY KEY (filing, operation, layer),
    FOREIGN KEY (filing, operation) REFERENCES operation(filing, label),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT a_induction_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high))
);

-- ⭐⭐⭐ HOW MUCH OF THE SYSTEM IS IN THIS STACK. There is ONE system; a filing holds the
-- layers of it that mattered to whoever filed, and until 0.3.0 `pm:Stack` read as though it
-- enumerated one. A FILING IS NEVER THE SYSTEM.
--
-- ⛔⛔ THE THIRD EXTENT IS THE ONE A TWO-VALUED ENCODING WOULD CRUSH, and it is the same
-- distinction `coupling_search` below turns on: `scoped` says somebody established what lies
-- outside and excluded it; `unbounded` says nobody looked. Rendering them identically cannot
-- tell a bounded selection from an unexamined one.
--
-- ⭐ WHAT IT BUYS IS A QUERY NOBODY COULD WRITE: which filings claim a boundary, and which
-- merely stopped. A second document holding a layer this one does not is then TWO PROJECTIONS
-- OF ONE SYSTEM rather than evidence the first omitted something.
CREATE TABLE stack_scope (
    filing text PRIMARY KEY REFERENCES filing(name),
    extent text CHECK (extent IN ('complete', 'scoped', 'unbounded')),
    basis  text,
    absent absence_reason,
    CONSTRAINT a_scope_is_stated_or_typed_absent
        CHECK ((extent IS NOT NULL) <> (absent IS NOT NULL))
);

-- ⭐⭐⭐ DID ANYBODY LOOK? ONE ROW PER FILING, AND IT IS THE ROW THAT MAKES THE EMPTY
-- `coupling` TABLE READABLE. The comment above the tall tables says an empty `coupling`
-- table "is a document where nobody looked rather than a document where nothing was
-- found" -- true, and for two revisions there was no column anywhere that said which.
--
-- ⛔ THE COUNT THIS BUYS IS ABOUT THE EVIDENCE RATHER THAN ABOUT ANY ONE FILING. Across
-- this corpus: three stacks file couplings, three say `unmeasured`, one is a single-layer
-- stack where the question has no population, and NOT ONE says `none`. The model's central
-- assumption -- that layers hold their remainders independently -- has never been tested
-- and has once been contradicted. That is a queryable fact now.
CREATE TABLE coupling_search (
    filing text PRIMARY KEY REFERENCES filing(name),
    absent absence_reason,   -- NULL where the filing actually names couplings
    note   text
);

-- C, L x L. An OBSERVED dependence between two layers' remainders. Never derived,
-- and required to carry the observation that produced it.
CREATE TABLE coupling (
    filing      text NOT NULL,
    from_layer  text NOT NULL,
    to_layer    text NOT NULL,
    low         numeric,
    mode        numeric,
    high        numeric,
    unit        text,
    observation text,
    PRIMARY KEY (filing, from_layer, to_layer),
    FOREIGN KEY (filing, from_layer) REFERENCES layer(filing, layer),
    FOREIGN KEY (filing, to_layer)   REFERENCES layer(filing, layer),
    CONSTRAINT a_coupling_strength_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high))
);

-- ---------------------------------------------------------------------------
-- ⭐⭐ THE READER'S MAPPING, WHICH IS NOT DATA FROM ANY DOCUMENT.
--
-- To ask "does this holder's share fit inside the slack of the buffer its absorber
-- names?", you must first decide that `capacidade` under a Portuguese edition means
-- the same buffer as `capacity` under an English one. NO FILING SAYS THAT. It is a
-- judgement a reader makes, and this table is where a reader records it so that the
-- judgement is visible instead of buried in a CASE expression.
--
-- ⛔ IT SHIPS POPULATED, AND THAT IS ITSELF A CLAIM YOU MAY DISAGREE WITH. Delete the
--    rows and the slack rules below stop returning answers for the Portuguese filings
--    rather than returning wrong ones, which is the behaviour worth having.
-- ---------------------------------------------------------------------------
CREATE TABLE buffer_term (
    taxonomy text NOT NULL,
    value    text NOT NULL,
    buffer   buffer NOT NULL,
    note     text,
    PRIMARY KEY (taxonomy, value)
);

INSERT INTO buffer_term VALUES
  ('urn:example:factory-physics:buffers', 'inventory', 'inventory', 'Hopp and Spearman, as published'),
  ('urn:example:factory-physics:buffers', 'capacity',  'capacity',  'Hopp and Spearman, as published'),
  ('urn:example:factory-physics:buffers', 'time',      'time',      'Hopp and Spearman, as published'),
  ('urn:example:pt:fisica-da-fabrica:amortecedores', 'capacidade', 'capacity',
   'a translated edition. The reader asserts the translation; no filing does');

-- ---------------------------------------------------------------------------
-- ✅⭐⭐⭐ THIS WAS THE SECOND READER'S MAPPING AND IT IS NOW DATA. S-28, REPAIRED.
--
-- A composition names its parts by a `ForeignId`: a notation plus an id, e.g.
-- `urn:example:filing:us-member:2026-08-31` / `compute`. Until 0.3.0 NO DOCUMENT
-- DECLARED ITS OWN NOTATION -- `Composition` carried witness, observedAt, provenance,
-- regime, citation and fusion, and nothing that said "I am that URN", and neither did
-- `pm:processModulus`. So a part reference could not be resolved from the corpus at
-- all, and the conformance rule "a dependence end's filing exists, and the layer named
-- is in it" presupposed a lookup the model did not provide.
--
-- ⭐ WRITING THIS QUERY IS WHAT SURFACED IT: a foreign key needs something to point AT,
-- and there was nothing. It was invisible from both other angles -- XSD 1.0 cannot
-- follow a cross-document reference so it never had to resolve one, and the Rust tests
-- load by FILENAME and pass the name in themselves.
--
-- ⛔ WHAT THE ROWS USED TO SAY, kept because the change is the point: three of them read
-- `'the reader, from the filename'`. A guess dressed as data, written down so the guess
-- was visible. They are now read out of `pm:processModulus/pm:notation` by XMLTABLE like
-- every other fact, and `asserted_by` records which filing said it about itself.
--
-- ⭐⭐ AND IT IS WHAT MAKES A LOCAL PART RESOLVABLE. A part whose notation equals its own
-- composition's is local: it names a layer that composition built. Nothing else changed
-- to allow it -- no second kind of part, no new column -- so `part` below carries local
-- and foreign rows in one table and the join tells them apart.
-- ---------------------------------------------------------------------------
CREATE TABLE filing_identity (
    notation text PRIMARY KEY,
    filing   text NOT NULL REFERENCES filing(name),
    asserted_by text NOT NULL,
    absent   absence_reason   -- a filing that declines to name itself, and why
);

-- ---------------------------------------------------------------------------
-- Composition. F and Phi live in one table, because a part IS an incidence entry
-- and its conversion factor at the same time.
-- ---------------------------------------------------------------------------

-- F (incidence) and Phi (diagonal conversion) together. One row per part used.
CREATE TABLE part (
    composition   text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    part_filing   text NOT NULL,
    part_layer    text NOT NULL,
    factor_low    numeric,     -- NULL means the units already agree, i.e. phi = 1
    factor_mode   numeric,
    factor_high   numeric,
    PRIMARY KEY (composition, composed_layer, part_filing, part_layer),
    CONSTRAINT a_factor_is_strictly_positive
        CHECK (factor_low IS NULL OR factor_low > 0),
    -- ⭐ No unit here, and that is not an omission: phi is a RATIO of two units, so the
    --   claim is whole at three numbers.
    CONSTRAINT a_factor_claim_is_whole_and_ordered
        CHECK (num_nonnulls(factor_low, factor_mode, factor_high) = 0
               OR (num_nonnulls(factor_low, factor_mode, factor_high) = 3
                   AND factor_low <= factor_mode AND factor_mode <= factor_high))
);

-- ⭐⭐ DID THE COMPOSER LOOK FOR DOUBLE COUNTING? Same shape as `coupling_search` and the
-- same defect it repairs, one document up. `Elimination`'s annotation argues that filed
-- eliminations make the sum rule EXACT rather than a warning -- which held for a fusion
-- that filed one, and quietly did not for the three in this corpus that file none.
--
-- ⭐ AND THE ANSWER DECIDES WHICH ARITHMETIC IS OWED. `none` or `notApplicable`: the
-- composed figure must equal the sum of its converted parts EXACTLY. `unmeasured`: no
-- equality is owed at all and a checker that reports one is reporting about nothing.
CREATE TABLE elimination_search (
    composition    text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    absent         absence_reason,   -- NULL where the fusion actually files eliminations
    note           text,
    PRIMARY KEY (composition, composed_layer)
);

-- e_x. Quantities double-counted across parts, filed one at a time with prose.
CREATE TABLE elimination (
    composition    text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    quantity       text NOT NULL CHECK (quantity IN ('demand', 'nameplate', 'draw')),
    low            numeric,
    mode           numeric,
    high           numeric,
    unit           text,
    absent         absence_reason,
    reason         text,
    PRIMARY KEY (composition, composed_layer, quantity),
    CONSTRAINT a_eliminated_quantity_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high))
);

COMMIT;
