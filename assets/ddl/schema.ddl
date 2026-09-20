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

-- ⭐ THE THREE QUANTITIES A LAYER SUMS, `asrt:EliminationAgainst`. A fusion's sum, an elimination
--    and a suspension are each keyed on one of them, so this is a dimension the model owns, and a
--    relation crossing the fusions with the quantities reads this set rather than whichever
--    quantities happen to be filed.
CREATE TYPE summed_quantity AS ENUM ('demand', 'nameplate', 'draw');

-- Who you would have to talk to in order to change it.
CREATE TYPE constraint_origin AS ENUM ('intrinsic', 'contractual', 'policy');

-- ⭐ A BLANK THAT SAYS WHICH KIND OF BLANK IT IS. In SQL a NULL says nothing about
--    why it is null, which is the exact failure the model exists to avoid. So every
--    quantity below carries BOTH a nullable triple and a reason, and exactly one of
--    the two is populated. The CHECK constraints make that a checked property.
CREATE TYPE absence_reason AS ENUM ('none', 'unmeasured', 'notApplicable');

-- ⭐⭐⭐ A VALUE COMPUTED FROM OTHER ELEMENTS IS NOT A BLANK: IT IS STATED BY AN EQUATION, AND IT
--    SAYS WHICH. `pm:Identity` is the closed catalogue of this model's equations and
--    `pm:Derivation` names one of them at a position filed as its output. An absence reason had
--    no place to say which equation, so every reader of a computed figure re-derived that by
--    hand, and the positions two identities can compute had no answer at all.
-- ⭐ Every position the XSD lets be computed carries a `*_derivation` column beside its
--    `*_absent` one. Exactly one of the value, the absence and the derivation is present, and
--    a CHECK holds the column to the members the XSD admits there, so a document the grammar
--    refuses is refused here too. `derivation` below is the tall mirror, as `absence` is for
--    the reasons.
CREATE TYPE identity AS ENUM (
    'fusionSum', 'magnitude', 'fit', 'clearance', 'sharesSum', 'sharedParts', 'conversionPath',
    'amountOrigin', 'quantumOrigin');

-- ⭐⭐⭐ AND THE XSD NARROWS IT WHEREVER THE VALUE ARM ALREADY NAMES THE DEGENERATE CASE.
--    The absent arm at every `pm:StatedClaim` is a `pm:ClaimAbsence` carrying
--    `pm:ClaimAbsenceReason`: "two members, `AbsenceReason` without `none`". A measured zero
--    has a unit, an observer, an author for its exactness and a provenance, and the absence arm
--    has a home for none of the four, so a zero is a CLAIM of [0,0,0] and never an absence.
-- ⭐⭐ AND THE SAME TEST REACHES TWO WRAPPERS THAT ARE NOT CLAIMS. `none` is honest only where
--    the value arm has nothing to say; where the value arm has a NAMED STATE for the degenerate
--    case, `none` is a second door to it. `pm:StatedRemainder`: "there is no remainder" reads
--    either "nothing to subtract from" or "the difference is zero", and a zero difference is a
--    CLEARANCE fit carrying [0,0,0] and a sign. `pm:StatedLumpyQuantum` at `window`: "it runs
--    continuously" is a duty fraction of ONE, with a size and an origin saying who could change
--    it. Both take a `pm:ClaimAbsence` now.
-- ⛔ Every column below that carries one of these wrappers has its own
--    `a_..._absence_has_no_none`, so Postgres cannot accept a `'none'` no valid document can
--    produce. Zero rows ever violated it; the CHECK makes that structural rather than lucky.
-- ⭐ `boundOrigin`, `couplings`, `absorber`, `notation` and `framework` keep the whole
--    enum, and the test says why: nothing sets this bound, somebody looked and the
--    layers move independently, no buffer took it, published under no identifier. Those are
--    nothings. A duty fraction of one is a number.
-- ⚠️ `CREATE DOMAIN ... CHECK (VALUE <> 'none')` is the tidier spelling and was tried first. It
--    does not work here: a domain over an enum loses the enum's comparison against an unknown
--    literal, so `WHERE absent = 'unmeasured'` stops resolving at every call site. A CHECK
--    keeps the column's type, and therefore its operators.

-- ⭐ This model's own, and the typed half of `narrowsWhen`.
CREATE TYPE narrowing_kind AS ENUM ('instrument', 'intervention', 'experiment');

-- ---------------------------------------------------------------------------
-- Documents.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- The repository's own compose DAG, one row per `(parent, child)` pair of `.sqlc` templates, with
-- how many times the parent splices the child. `examples/compositions/main.rs` builds it from the
-- source tree without a database and writes `assets/dag/edges.sql`; `ingest` loads that.
--
-- Why it is in `public`
--   Everything in `pm` descends from a filed document, which is the strongest property this
--   schema states about itself. A fact about this repository's own queries does not, so it lives
--   outside `pm`. `diagrams/lane_grain.sqlc` crosses the same line when it reads `pg_constraint`.
--
-- Why `splices` matters
--   A parent composing a child twice is ordinary: a query is idempotent, and the planner reads the
--   repeated relation once. The identical shape in `pm.part` is `checks/jagged_layer`, a
--   violation, because supply is a conserved carrier and one total closes over both occurrences.
--   Two graphs of one shape get opposite verdicts on one column, which is what this model adds to
--   `sql-composer`, and keeping both halves in SQL makes that comparison a query anybody can run.
--   Deduplicating to a bare edge would throw the argument away.
--
-- Dropped by name, with what reads it
--   `DROP SCHEMA pm CASCADE` above does not reach `public`. The views that read the table go with
--   it, and `assets/sql/views.sql` creates them again after the ingest.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS public.compose_edge CASCADE;
CREATE TABLE public.compose_edge (
    parent  text    NOT NULL,
    child   text    NOT NULL,
    -- Strictly positive. A row exists because a directive does, so zero is not a state: a parent
    -- that does not compose a child has no row, the sparse reading every incidence here uses.
    splices integer NOT NULL CHECK (splices > 0),
    -- How many of those splices are an inner join. Composing a relation as the driving set or
    -- with a `LEFT JOIN` asks *what is missing from the whole*; inner-joining it asks *does this
    -- one pair exist*, and hands the whole composed relation to every consumer downstream. One
    -- inner join of `layers/every_layer.sqlc`, the layer dimension, would put the entire
    -- dimension into most rules' transitive closure and make every reach-containment bound
    -- vacuous. A count rather than a kind, because one parent may splice one child at several
    -- call sites; `algebra/dimension_use.sqlc` only asks whether it is above zero.
    inner_joins integer NOT NULL CHECK (inner_joins >= 0),
    CONSTRAINT inner_joins_are_some_of_the_splices CHECK (inner_joins <= splices),
    PRIMARY KEY (parent, child)
);

-- ---------------------------------------------------------------------------
-- The classes this repository's own queries sort things into. A classification is a function from
-- what is classified to a set of classes, and the set is part of the function: a partition law
-- proves every row landed in exactly one class, which stays true under any renaming of the classes,
-- a misspelt one included. So each set is declared once, here, and every arm that names a class
-- and every consumer that selects on one is checked against it.
--
-- Why an enum
--   A string literal cast to an enum is checked when the query is parsed, so a misspelt class
--   fails on every run whether or not any row reaches its arm. A CHECK, a domain or a roster is
--   consulted only by rows. The arm that matters most is often the one no row has taken:
--   `not comparable`, which `examples/readiness/main.rs` pins at zero, is checked only by the
--   parser.
--
-- The label order is the precedence
--   Where the arms' predicates can overlap, the first arm that holds decides. An enum orders by
--   declaration, so each type states the precedence as well as the members.
--
-- Why in `public`, dropped by name
--   These describe this repository's queries rather than a subject, for `compose_edge`'s reason,
--   and `DROP SCHEMA pm CASCADE` above does not reach them. The views that read them go with
--   them, and `assets/sql/views.sql` creates them again after the ingest.
-- ---------------------------------------------------------------------------
DROP TYPE IF EXISTS public.arithmetic_verdict CASCADE;
DROP TYPE IF EXISTS public.remainder_standing CASCADE;
DROP TYPE IF EXISTS public.exposure_standing CASCADE;
DROP TYPE IF EXISTS public.fit_axis CASCADE;
DROP TYPE IF EXISTS public.fit_standing CASCADE;
DROP TYPE IF EXISTS public.factor_state CASCADE;
DROP TYPE IF EXISTS public.layer_quantity CASCADE;

-- arithmetic/*.sqlc: whether a site may compute. A typed absence suspends it; operands in two
-- units make it incomparable; otherwise it computes.
CREATE TYPE public.arithmetic_verdict AS ENUM ('suspended', 'not comparable', 'computable');

-- layers/remainder_scope.sqlc: how far the closure question could be put to a remainder.
CREATE TYPE public.remainder_standing AS ENUM (
    'takes a spillover', 'nobody bounded the set', 'set bounded, pairs untested',
    'bounded and the pairs answered');

-- layers/exposure_scope.sqlc: where an exposure could have gone. Ignorance outranks room.
CREATE TYPE public.exposure_standing AS ENUM (
    'a buffer nobody sized', 'a buffer with room in it', 'every buffer sized and empty');

-- checks/fit_axes.sqlc: which fit a rule's population or verdict depends on. The filed sign and
-- the fit derived from demand and nameplate agree on a conforming document and are still two
-- columns, so a rule reads one of them, both, or neither.
CREATE TYPE public.fit_axis AS ENUM (
    'filed sign', 'derived fit', 'filed against derived', 'not read');

-- checks/fit_domain.sqlc: where a rule that reads the fit stands in one cell of its axis. Some
-- document reaches the cell and the rule examines it; the rule's own population excludes it; or
-- the cell is in the domain and nothing loaded reaches it.
CREATE TYPE public.fit_standing AS ENUM ('exercised', 'outside', 'open');

-- composition/part_references.sqlc: how a part files its conversion factor. The element omitted (the
-- units already agree, so the factor is one), a stated claim, a typed absence, or a derivation
-- naming the identity that computes it. `pm.part`'s CHECKs let at most one of the three columns be
-- set, so no two arms can both hold and the order is the grammar's, not a precedence.
CREATE TYPE public.factor_state AS ENUM ('omitted', 'stated', 'absent', 'derivation');

-- layers/quantities.sqlc: the quantities a LAYER states in its own unit, each named after the
-- element that carries it. `pm.summed_quantity` names the three a FUSION sums, and the two sets
-- share `demand` and `nameplate` without being the same domain: a slack is never summed across
-- parts, and a draw belongs to an operation rather than to the layer. Two names is the whole of
-- what they have in common, so a relation that matches them matches BY NAME and casts to say so.
-- ⛔ The three slack members are built as `pm.buffer || 'Slack'`, in that type's own order, so a
-- buffer this type does not name fails at the cast instead of arriving downstream as a sixth
-- quantity nobody declared.
CREATE TYPE public.layer_quantity AS ENUM (
    'demand', 'nameplate', 'inventorySlack', 'capacitySlack', 'timeSlack');

-- The XML as it arrived. Exactly one table in schema `pm` touches the filesystem, in
-- sql/ingest.sql, and everything else in THIS SCHEMA is derived from here by ordinary SQL.
-- ⚠️ `public.compose_edge` above is also filesystem-fed and is deliberately outside `pm`, for
-- the reason its own comment gives: it is a fact about this repository and not about a subject.
CREATE TABLE source (
    name text PRIMARY KEY,
    body xml  NOT NULL
);

CREATE TABLE filing (
    name text PRIMARY KEY REFERENCES source(name),
    -- ⭐⭐ THE ROOT ELEMENT THE DOCUMENT DECLARES, read with `local-name()` rather than
    -- guessed from a prefix. FIVE values and not two: `assets/corpus/` already holds
    -- documents rooted at `coverage`, `dependence` and `run` that ingest does not yet load,
    -- and a two-valued CHECK with an `ELSE 'filing'` would file every one of them as a plain
    -- filing without complaining. A domain that closes where the SCHEMA closes cannot drift
    -- from it in silence.
    kind text NOT NULL CHECK (kind IN ('processModulus', 'composition',
                                       'coverage', 'dependence', 'run')),

    -- ⛔⛔ WHAT THIS DOCUMENT IS EVIDENCE FOR, and it is a SECOND AXIS rather than a third
    -- `kind`. A fixture is still a filing or a composition; what differs is what it attests.
    -- Folding the two into one column would put two kinds of fact in one slot, which is the
    -- flattening `pm:Provenance` and `pm:Holder` both reject.
    --
    -- ⭐ THE RULES MUST RUN ON FIXTURES -- that is what a fixture is for. THE REPORTS MUST
    -- NOT: "no stack in this corpus asserts independence" is a fact about the evidence, and a
    -- stipulation that asserts it would make the finding a lie. See assets/fixtures/README.md.
    -- ⭐⭐ IN THE DOCUMENT'S OWN WORDS, NOT THE READER'S. Read as `corpus`/`fixture`, which
    -- directory the file sits in, this is the reader's classification, and matching an English
    -- sentence in an XML comment for it is a guess. `pm:StatedEvidence` makes it a filed fact, so the
    -- values are the document's: `observation` (somebody looked at a real system) and
    -- `stipulation` (nothing here was observed).
    --
    -- ⛔⛔ AND THE THIRD STATE IS WHY IT IS NULLABLE. A document may decline to say, and every
    -- document written before the element existed is in exactly that state. Rendered as
    -- `stipulation` it would be quarantined on a guess; rendered as `observation` it would be
    -- quoted on one. It belongs to NEITHER scope, which is what a NULL here buys.
    evidence text CHECK (evidence IN ('observation', 'stipulation')),
    evidence_absent absence_reason,

    -- ⭐ WHO ASSERTS A COMPOSITION, AND ON WHAT STANDING. `asrt:Composition/provenance` and
    --   `asrt:Dependence/provenance` are REQUIRED `pm:Provenance`s: the party that composed the
    --   filings and the standing it composes them on, a parent undertaking consolidating its
    --   members. The same shape as `claim.prov_*`, one per document, and empty on a root that
    --   carries none. Until 2026-09-18 no path read it, so a composition arrived without its author.
    prov_party             text,
    prov_entered_by        text,
    prov_approved_by       text,
    prov_standing_taxonomy text,
    prov_standing_value    text,
    prov_standing_absent   absence_reason,
    prov_note              text,

    CONSTRAINT a_document_says_what_it_is_evidence_for_or_why_not
        CHECK ((evidence IS NOT NULL) <> (evidence_absent IS NOT NULL)),
    CONSTRAINT an_assertion_states_its_standing_or_why_not
        CHECK ((kind IN ('composition', 'dependence'))
               = ((prov_standing_value IS NOT NULL) <> (prov_standing_absent IS NOT NULL))),
    CONSTRAINT a_provenance_belongs_to_an_assertion
        CHECK (kind IN ('composition', 'dependence')
               OR num_nonnulls(prov_party, prov_entered_by, prov_approved_by, prov_note,
                               prov_standing_value, prov_standing_absent) = 0),
    CONSTRAINT an_assertion_standing_term_is_whole
        CHECK (num_nonnulls(prov_standing_taxonomy, prov_standing_value) <> 1)
);

-- ⭐ TALL BECAUSE A FILING CAN REPORT UNDER MORE THAN ONE REGIME, and `refutation`
--    does: the same Portuguese microentity is `NC-ME` to one authority and `M` to
--    another, the two published code lists do not line up, and neither declaration
--    says what the pair says. A `jurisdiction` column on `filing` would have forced
--    the sender to pick one and thrown away the disagreement, which is the document's
--    entire subject. That is why the column is not here and the table is.
-- ⛔⛔⛔ THE FRAMEWORK IS A BORROWED TERM AND A COLUMN HOLDING ITS VALUE ALONE STORES THE
--    AMBIGUOUS HALF. `pm:Regime`'s own annotation says why, and it is Portugal: SAF-T PT
--    publishes `S · M · N · O`, IES AnexoASNC publishes `NIC · NCRF · NCRF-PE · NC-ME`, and the
--    lists do not line up. "`S` does not identify a framework and `NCRF-PE` is not a SAF-T
--    value. A code without its authority is genuinely ambiguous rather than merely
--    unattributed." A single `framework text` column was exactly that code without its
--    authority, so `refutation`'s two regimes read as `NC-ME` and `M` with nothing saying they
--    are two authorities' codings of one entity, which is that document's whole subject.
--
-- ⛔⛔ AND `framework` AND `chart` ARE `pm:StatedBorrowedTerm`, A CHOICE OF `term` OR `absent`,
--    SO A COLUMN WITHOUT A TYPED ABSENCE FLATTENS TWO DIFFERENT FACTS INTO NULL. The fixture
--    named `unstated` files both branches on purpose: `r1` is `unmeasured` because the entity's
--    size tier is unassigned so the framework it selects is not yet known, and `r2` is `none`
--    because it is an internal management view answerable to no external framework. Both landed
--    in the database as NULL, which is the flattening this schema exists to refuse, on the
--    fixture written to exercise it.
--
-- ⛔ `chart` IS REQUIRED BY THE XSD AND HAD NO COLUMN AT ALL. Its annotation argues the point at
--    length, including that a self-authored chart names the entity as its own authority, and
--    every one of those was discarded on load.
--
-- ⚠️ `jurisdiction` STAYS A BARE NULLABLE TOKEN AND GETS NO TYPED ABSENCE, because the XSD
--    already derives its absence from a sibling: "Absent for a framework that is not a country's
--    -- IFRS has no jurisdiction, and forcing one invents a fact." Asking a filer to restate that
--    is boilerplate with no author. ⛔ And nothing may key on it: "a receiver joining on this
--    field is using it for the one purpose it was deliberately made too weak to serve."
CREATE TABLE regime (
    filing       text NOT NULL REFERENCES filing(name),
    seq          int  NOT NULL,
    -- ⛔⛔⛔ REQUIRED AND UNIQUE BECAUSE BOTH SCHEMAS SAY SO, AND THE OMISSION MANUFACTURED
    --    FALSE VIOLATIONS. `pm:Regime/id` has no `minOccurs`, so it is required, and `xs:key
    --    regimeId` keys it in `process-modulus.xsd` and again in `assertion.xsd`; the annotation
    --    states the point outright, "two declarations cannot silently be the same". Left nullable
    --    and unkeyed here, two declarations sharing an id fan out every join through the handle:
    --    measured, 27 parts became 30 and `checks/part_regime_disagrees` reported THREE
    --    violations against a corpus with none. A claim proved against this schema is meant to be
    --    a claim about the MODEL rather than about a translation, and that was the translation.
    id           text NOT NULL,
    jurisdiction text,
    framework_taxonomy text,
    framework_value    text,
    framework_absent   absence_reason,
    chart_taxonomy     text,
    chart_value        text,
    chart_absent       absence_reason,
    PRIMARY KEY (filing, seq),
    CONSTRAINT a_regime_handle_is_unique_in_a_filing UNIQUE (filing, id),
    -- ⛔ TWO CHECKS PER TERM, BECAUSE ONE CANNOT SAY BOTH THINGS. Written as one,
    --    `(num_nonnulls(taxonomy, value) = 2) <> (absent IS NOT NULL)`, a taxonomy with no value
    --    beside an absence passes: the left side is false, the right is true. That row is half a
    --    term AND a reason there is none, and two readers counting "states a framework" by
    --    different halves disagree on it. Wholeness first, then the choice, which is the shape
    --    every `pm:StatedBorrowedTerm` in this file takes.
    CONSTRAINT a_framework_term_is_whole
        CHECK (num_nonnulls(framework_taxonomy, framework_value) <> 1),
    CONSTRAINT a_framework_is_stated_or_typed_absent
        CHECK ((framework_value IS NOT NULL) <> (framework_absent IS NOT NULL)),
    CONSTRAINT a_chart_term_is_whole
        CHECK (num_nonnulls(chart_taxonomy, chart_value) <> 1),
    CONSTRAINT a_chart_is_stated_or_typed_absent
        CHECK ((chart_value IS NOT NULL) <> (chart_absent IS NOT NULL))
);

-- ⭐⭐⭐ WHAT A COMPOSER SAYS ABOUT ANOTHER DOCUMENT'S REGIME, WHICH IS NOT WHAT THAT DOCUMENT
--    SAYS ABOUT ITSELF. `asrt:composition` declares `asrt:regime` of type `pm:Regime`, the same
--    shape as the table above and a DIFFERENT FACT with a different author, so it is a second
--    table and not a discriminator column. The same refusal guards `draw` against `induction`.
--
-- ⭐⭐ EACH PART THEN NAMES WHICH OF THESE IT COMES UNDER, and XSD 1.0 checks that the handle
--    resolves: `compositionRegimeId` is the key and `partRegime` the keyref. What a keyref
--    CANNOT reach is the other document, so whether the composer's claim agrees with the part
--    filing's own declaration is exactly the question the grammar hands to a rule.
CREATE TABLE composition_regime (
    composition  text NOT NULL REFERENCES filing(name),
    seq          int  NOT NULL,
    -- ⛔⛔⛔ REQUIRED AND UNIQUE BECAUSE BOTH SCHEMAS SAY SO, AND THE OMISSION MANUFACTURED
    --    FALSE VIOLATIONS. `pm:Regime/id` has no `minOccurs`, so it is required, and `xs:key
    --    regimeId` keys it in `process-modulus.xsd` and again in `assertion.xsd`; the annotation
    --    states the point outright, "two declarations cannot silently be the same". Left nullable
    --    and unkeyed here, two declarations sharing an id fan out every join through the handle:
    --    measured, 27 parts became 30 and `checks/part_regime_disagrees` reported THREE
    --    violations against a corpus with none. A claim proved against this schema is meant to be
    --    a claim about the MODEL rather than about a translation, and that was the translation.
    id           text NOT NULL,
    jurisdiction text,
    framework_taxonomy text,
    framework_value    text,
    framework_absent   absence_reason,
    chart_taxonomy     text,
    chart_value        text,
    chart_absent       absence_reason,
    PRIMARY KEY (composition, seq),
    CONSTRAINT a_regime_handle_is_unique_in_a_composition UNIQUE (composition, id),
    CONSTRAINT a_composed_framework_term_is_whole
        CHECK (num_nonnulls(framework_taxonomy, framework_value) <> 1),
    CONSTRAINT a_composed_framework_is_stated_or_typed_absent
        CHECK ((framework_value IS NOT NULL) <> (framework_absent IS NOT NULL)),
    CONSTRAINT a_composed_chart_term_is_whole
        CHECK (num_nonnulls(chart_taxonomy, chart_value) <> 1),
    CONSTRAINT a_composed_chart_is_stated_or_typed_absent
        CHECK ((chart_value IS NOT NULL) <> (chart_absent IS NOT NULL))
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
    -- `pm:StatedSummedQuantity`: a composed layer's demand may be its fusion's sum, named.
    demand_derivation identity CHECK (demand_derivation = 'fusionSum'),
    -- ⭐ WHAT WOULD TIGHTEN THE BOUNDS, AND WHO OWNS THEM, IS NOT HERE. `narrowsWhen` and
    --    `boundOrigin` are REQUIRED on every `Claim`, so the demand's live where every claim's
    --    do: one row each in `narrowing` and `bound_origin`, keyed on the claim. Copies of them
    --    stood here and on `slack`, and the absence census counted each copied absence twice.

    -- ⭐⭐⭐ HOW LONG THE ASKING SURVIVES BEING UNANSWERED. `pm:Demand/patience`, and it is the
    -- half of the time axis `pm:Divisibility` filed as missing: `window` is the supply's duty
    -- cycle, this is demand's lifetime. A DURATION, so `patience_unit` is `shifts` or
    -- `minutes` and NOT the layer's unit -- a slack is quoted in the unit of the shares it
    -- bounds and a patience bounds none. Where the layer's unit is service time the two
    -- coincide numerically, which is a fact about that layer rather than a licence to fold
    -- these columns into `slack`.
    --
    -- ⛔ ZERO PATIENCE ARRIVES AS [0, 0, 0], NOT AS `patience_absent = 'none'`. Demand that
    -- leaves the moment it is not served has a patience of zero, and a measured zero is a
    -- claim: `pm:Demand/patience` is a `pm:StatedClaim`, whose absent arm carries
    -- `pm:ClaimAbsenceReason`, and that type has no `none`. So an ingested `'none'` here is a
    -- document that did not validate, and the three remaining reasons are what this column
    -- can honestly hold.
    patience_low    numeric,
    patience_mode   numeric,
    patience_high   numeric,
    patience_unit   text,
    patience_absent absence_reason,

    -- ⭐⭐⭐ THE WRAPPER THAT LETS THE MODEL BE CONTRADICTED, AND AN INGEST READING ONE
    --     BRANCH THROWS IT AWAY. `StatedRemainder` is a CHOICE -- a remainder, or a typed
    --     reason there is none -- and EVERY layer is required to carry one, precisely so that a
    --     sender who disagrees with "every layer has a remainder" has to say so EXPLICITLY
    --     rather than leaving a field empty. Read only the first branch and
    --     the two corpus layers that take the second land here as five NULLs: sign,
    --     absorber and quantity all blank, which is indistinguishable from a document that
    --     said nothing at all.
    --
    --  ⛔⛔ AND ONE OF THEM SAYS SO IN THE NOTE, WHICH IS WHY THE NOTE IS STORED.
    --     `refutation/object-storage` files a counter-example "to the claim that every layer
    --     carries a remainder, NOT AS A GAP IN THIS DOCUMENT." A gap is exactly what the
    --     reason alone records. Keeping only the reason keeps the fact and loses the argument,
    --     and the argument is what the document is written to make.
    --
    -- ⛔ A REMAINDER OF ZERO ARRIVES AS A FILED CLEARANCE, NOT AS `remainder_absent = 'none'`.
    --    "There is no remainder" reads two ways: nothing to subtract from, or the difference
    --    is zero. The second is a CLEARANCE FIT -- `Fit` settles the line-to-line case in
    --    prose, "minimum clearance is zero", with a quantity of [0, 0, 0] and a sign -- and an
    --    absence throws that sign away. So `pm:StatedRemainder`'s absent arm is a
    --    `pm:ClaimAbsence`, the three remaining reasons are what this column can honestly
    --    hold, and both corpus denials say `notApplicable`: their nameplate is `notApplicable`
    --    too, so `r = n - d` has no `n` and the question is malformed rather than answered.
    remainder_absent      absence_reason,
    remainder_absent_note text,

    -- the remainder's two halves: which side it is on, and how big it is
    sign          fit,
    sign_absent   absence_reason,
    sign_derivation identity CHECK (sign_derivation = 'fit'),

    -- ⛔⛔ THE ABSORBER IS A BORROWED TERM AND NOT AN ENUM, AND AN ENUM IS WRONG HERE IN
    --     THE MOST INSTRUCTIVE WAY AVAILABLE. Declare
    --     `absorber buffer` and the corpus refuses to load: `invalid input value for
    --     enum buffer: "capacidade"`. The Portuguese filing cites a TRANSLATED EDITION
    --     of Factory Physics, `urn:example:pt:fisica-da-fabrica:amortecedores`, and its
    --     absorber is `capacidade`. That filing is correct. The enum is the fork, and
    --     the README says so in as many words: "a restated value set is a fork, and a
    --     fork drifts with nothing here able to notice that it has".
    --  ⭐ So the value travels WITH the authority that defines it, and comparing two
    --     filings that cite different authorities is a step somebody has to take on
    --     purpose. See `buffer_term`.
    --
    -- ⛔⛔ AND IT IS A `pm:StatedBorrowedTerm`, A CHOICE OF `term` OR `absent`, SO TWO COLUMNS
    --    HOLD ONLY ONE BRANCH. `Remainder` argues for the other in as many words: a remainder
    --    may genuinely have been absorbed by NOTHING, a shop at capacity that turns people away
    --    with no waiting list, and choosing none of three buffers is a real empty selection.
    --    Without `absorber_absent` that filing arrived as two NULLs, the shape of a document
    --    that never said, on the corpus's own worked example of the honest answer.
    absorber_taxonomy text,
    absorber_value    text,
    absorber_absent   absence_reason,
    qty_low       numeric,
    qty_mode      numeric,
    qty_high      numeric,
    qty_unit      text,
    qty_absent    absence_reason,
    qty_derivation identity CHECK (qty_derivation = 'magnitude'),

    -- `Demand/amount` is a `pm:StatedClaim` like `patience`, so its absent arm has no `none` either.
    CONSTRAINT a_demand_absence_has_no_none CHECK (demand_absent <> 'none'),
    CONSTRAINT a_patience_absence_has_no_none CHECK (patience_absent <> 'none'),
    -- ⛔ `StatedRemainder` takes a `ClaimAbsence` for the reason above: an ingested `'none'`
    --    here is a document that did not validate.
    CONSTRAINT a_remainder_absence_has_no_none CHECK (remainder_absent <> 'none'),
    -- ⛔ `StatedFit` takes a `ClaimAbsence` too, and its annotation refuses this state in prose
    --    while the type admits it: overlapping ranges are a `transition` fit, which the value
    --    arm NAMES, so `none` is a second door to a filed answer. No document takes it, and a
    --    door nobody walks through is reachable only from the mask over
    --    `epistemics/absences.sqlc`.
    CONSTRAINT a_sign_absence_has_no_none CHECK (sign_absent <> 'none'),
    CONSTRAINT a_remainder_quantity_absence_has_no_none CHECK (qty_absent <> 'none'),
    PRIMARY KEY (filing, layer),
    CONSTRAINT patience_is_stated_or_typed_absent
        CHECK ((patience_low IS NOT NULL) <> (patience_absent IS NOT NULL)),
    CONSTRAINT a_patience_claim_is_whole_and_ordered
        CHECK (num_nonnulls(patience_low, patience_mode, patience_high) = 0
               OR (num_nonnulls(patience_low, patience_mode, patience_high, patience_unit) = 4
                   AND patience_low <= patience_mode AND patience_mode <= patience_high)),
    CONSTRAINT demand_is_stated_or_typed_absent
        CHECK (num_nonnulls(demand_low, demand_absent, demand_derivation) = 1),
    -- ⛔⛔⛔ A THREE-POINT CLAIM IS WHOLE OR IT IS ABSENT, AND `num_nonnulls` IS WHY THIS FORM
    --   RATHER THAN THE OBVIOUS ONE. The obvious one,
    --       CHECK (demand_low IS NULL OR (demand_low <= demand_mode AND demand_mode <= demand_high))
    --   READS correctly and ENFORCES nothing: with `demand_mode` NULL the comparison is
    --   NULL, and a CHECK passes on NULL. Half a claim files, and what it becomes downstream
    --   is not a blank -- `greatest(NULL, 0)` ignores the NULL and returns a zero
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
                                             AND sign_derivation IS NULL
                                             AND qty_low IS NULL AND qty_absent IS NULL
                                             AND qty_derivation IS NULL
                                             AND absorber_taxonomy IS NULL
                                             AND absorber_value IS NULL
                                             AND absorber_absent IS NULL)),
    -- ⛔ AND INSIDE A FILED REMAINDER, THE SAME STATED-OR-TYPED-ABSENT RULE AS EVERYWHERE
    --   ELSE. Without these a filed remainder carries neither a sign nor a reason for
    --   having none, and nothing notices while the corpus happens not to.
    CONSTRAINT a_filed_remainder_states_or_types_its_sign
        CHECK (remainder_absent IS NOT NULL
               OR num_nonnulls(sign, sign_absent, sign_derivation) = 1),
    CONSTRAINT an_absorber_term_is_whole
        CHECK (num_nonnulls(absorber_taxonomy, absorber_value) <> 1),
    CONSTRAINT a_filed_remainder_states_or_types_its_absorber
        CHECK (remainder_absent IS NOT NULL
               OR ((absorber_value IS NOT NULL) <> (absorber_absent IS NOT NULL))),
    CONSTRAINT a_filed_remainder_states_or_types_its_quantity
        CHECK (remainder_absent IS NOT NULL
               OR num_nonnulls(qty_low, qty_absent, qty_derivation) = 1),
    CONSTRAINT a_qty_claim_is_whole_and_ordered
        CHECK (num_nonnulls(qty_low, qty_mode, qty_high) = 0
               OR (num_nonnulls(qty_low, qty_mode, qty_high, qty_unit) = 4
                   AND qty_low <= qty_mode AND qty_mode <= qty_high))
);

CREATE TABLE nameplate (
    filing         text NOT NULL,
    layer          text NOT NULL,
    -- `pm:Facility/label`, REQUIRED: what the filer calls this supply, which is sometimes the
    -- argument itself. `unstated/margin-ratio` labels its supply "a ratio, which is not a supply".
    facility_label text NOT NULL,

    amount_low     numeric,
    amount_mode    numeric,
    amount_high    numeric,
    amount_unit    text,
    amount_absent  absence_reason,
    amount_derivation identity CHECK (amount_derivation = 'fusionSum'),
    -- ⛔ `Nameplate/amountOrigin` is a REQUIRED `pm:StatedConstraintOrigin`, an origin or a typed
    --    reason there is none, and a column holding the origin alone stores a NULL for both
    --    `unmeasured` (nobody asked who committed it) and `notApplicable` (there is no amount to
    --    have committed). `amount_origin_absent` is the second branch, and it has no `none`.
    amount_origin  constraint_origin,
    amount_origin_absent absence_reason,

    -- divisibility, axis one: AMOUNT. lumpy carries a quantum; continuous has none,
    -- and that is a different thing from a quantum of zero.
    --
    -- ⛔ NULLABLE, AND THE CORPUS IS WHY. Declared `boolean NOT NULL`, this column refuses
    --    `unstated`, which files `divisibility` as a TYPED ABSENCE, so
    --    the supply is neither lumpy nor continuous — nobody said which. A boolean has
    --    two states and this question has three, which is the same shape as the three
    --    buffer slacks as booleans. Twice in this file a two-valued column meets a
    --    three-valued fact.
    lumpy          boolean,
    divisibility_absent absence_reason,
    quantum_low    numeric,
    quantum_mode   numeric,
    quantum_high   numeric,
    quantum_unit   text,
    -- `LumpyQuantum/size` is a `pm:StatedClaim`: a supply that comes in lumps of a size nobody
    -- measured files the size absent, and a lumpy row with no quantum was refused before this.
    quantum_absent absence_reason,
    quantum_origin constraint_origin,

    -- divisibility, axis two: TIME. The machine that runs 02:00 to 05:00. A supply can
    -- be lumpy in amount AND intermittent in time, which is why this is a second axis
    -- rather than a third value of the first.
    --
    -- ⛔⛔ AND `window_absent` IS THE THIRD TWO-VALUED COLUMN IN THIS FILE TO MEET A
    --    THREE-VALUED FACT, AFTER `lumpy` ABOVE AND THE THREE SLACKS BEFORE IT. A NULL
    --    window means three things at once, and the schema's own annotation
    --    describes all three in prose it cannot file: `notApplicable` on a unit with
    --    no denominator (sixteen of this corpus's layers), `unmeasured` for one nobody
    --    asked about, and a supply that runs continuously. The second of those is the one
    --    that matters arithmetically — it is the state in which a time slack CANNOT
    --    be derived from a clearance, because nobody knows whether the spare is spread
    --    evenly across the period.
    --
    -- ⛔ AND THE THIRD IS NOT AN ABSENCE AT ALL. "The supply runs continuously" is a DUTY
    --    FRACTION OF ONE: it has a size, and in `window_origin` it has an author who could
    --    change it. Filed as `none` it lost both, and a line that cannot be stopped
    --    (`intrinsic`) read identically to one somebody staffed round the clock (`policy`)
    --    or promised in a contract (`contractual`) — three levers collapsed into a blank.
    --    A whole duty cycle is filed as ONE WHOLE PERIOD in the period's own unit, `1 week`
    --    against a period of `week`, which is a duty fraction you can read without dividing
    --    anything. `assets/sql/layers/derivation_licensed.sql` is where that is read.
    window_low     numeric,
    window_mode    numeric,
    window_high    numeric,
    window_unit    text,
    -- the window's quantum is a `LumpyQuantum` too, so its size can be typed absent: a duty
    -- cycle whose period nobody measured, which is not the same as no window answer at all.
    window_size_absent absence_reason,
    window_origin  constraint_origin,
    window_absent  absence_reason,

    -- what the supply actually served, which is neither what was asked nor committed
    draw_low       numeric,
    draw_mode      numeric,
    draw_high      numeric,
    draw_unit      text,
    draw_absent    absence_reason,
    draw_derivation identity CHECK (draw_derivation = 'fusionSum'),

    -- `pm:Jagged/measurementBasis`, REQUIRED, a `pm:StatedBasis`: the draw was read against the
    -- nameplate (`contributed`), against a borrowed basis (a taxonomy and a value), or neither
    -- with a typed reason. Every filing so far declines it, and until 2026-09-18 no column held
    -- either branch.
    measurement_basis_contributed text CHECK (measurement_basis_contributed IN ('nameplate')),
    measurement_basis_taxonomy    text,
    measurement_basis_value       text,
    measurement_basis_absent      absence_reason,

    CONSTRAINT a_amount_absence_has_no_none CHECK (amount_absent <> 'none'),
    CONSTRAINT a_draw_absence_has_no_none CHECK (draw_absent <> 'none'),
    -- ⛔ `Nameplate/amount` and `Jagged/draw` are both REQUIRED `pm:StatedClaim`s, and
    --    `Facility` requires `jagged` beside every nameplate, so a nameplate row states each one
    --    or types why not. The whole-claim CHECKs below make one column speak for the triple.
    CONSTRAINT an_amount_is_stated_or_typed_absent
        CHECK (num_nonnulls(amount_low, amount_absent, amount_derivation) = 1),
    CONSTRAINT an_amount_origin_is_stated_or_typed_absent
        CHECK ((amount_origin IS NOT NULL) <> (amount_origin_absent IS NOT NULL)),
    -- `pm:StatedAmountOrigin` takes a `ClaimAbsence`: a committed quantity has an author by
    -- definition, and where nature fixes the number `intrinsic` is the member that says so.
    CONSTRAINT an_amount_origin_absence_has_no_none CHECK (amount_origin_absent <> 'none'),
    CONSTRAINT a_draw_is_stated_or_typed_absent
        CHECK (num_nonnulls(draw_low, draw_absent, draw_derivation) = 1),
    PRIMARY KEY (filing, layer),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    -- A lumpy supply states its quantum's size or types why not, and names who set the quantum
    -- (`LumpyQuantum/origin` is required whatever the size says); nothing else carries either.
    CONSTRAINT a_lumpy_supply_states_or_types_its_quantum
        CHECK ((lumpy IS TRUE) = (num_nonnulls(quantum_low, quantum_absent) = 1)),
    CONSTRAINT a_quantum_absence_has_no_none CHECK (quantum_absent <> 'none'),
    CONSTRAINT a_lumpy_supply_says_who_set_its_quantum
        CHECK ((lumpy IS TRUE) = (quantum_origin IS NOT NULL)),
    CONSTRAINT divisibility_is_stated_or_typed_absent
        CHECK ((lumpy IS NULL) = (divisibility_absent IS NOT NULL)),
    -- A window is a size or a typed reason there is none -- never a blank, and never
    -- both. Enforced here because XSD enforces it there.
    -- ⛔ `Divisibility/window` takes a `ClaimAbsence` for the reason above: an ingested
    --    `'none'` here is a document that did not validate.
    CONSTRAINT a_window_absence_has_no_none CHECK (window_absent <> 'none'),
    -- three answers now and exactly one: a quantum with a size, a quantum whose size is typed
    -- absent, or no window with a typed reason. And all of it lives inside a stated divisibility.
    CONSTRAINT a_window_is_stated_or_typed_absent
        CHECK (divisibility_absent IS NOT NULL
               OR num_nonnulls(window_low, window_size_absent, window_absent) = 1),
    CONSTRAINT a_window_lives_in_a_stated_divisibility
        CHECK (divisibility_absent IS NULL
               OR num_nonnulls(window_low, window_size_absent, window_absent, window_origin) = 0),
    CONSTRAINT a_window_size_absence_has_no_none CHECK (window_size_absent <> 'none'),
    CONSTRAINT a_window_quantum_says_who_set_it
        CHECK ((num_nonnulls(window_low, window_size_absent) = 1) = (window_origin IS NOT NULL)),
    CONSTRAINT a_measurement_basis_is_one_of_its_three_answers
        CHECK (num_nonnulls(measurement_basis_contributed, measurement_basis_value,
                            measurement_basis_absent) = 1),
    CONSTRAINT a_borrowed_measurement_basis_is_whole
        CHECK (num_nonnulls(measurement_basis_taxonomy, measurement_basis_value) <> 1),
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
-- ⛔⛔⛔ WHAT THIS TABLE'S ABSENCE COSTS, EXACTLY. Ingest `narrowsWhen` and `boundOrigin` as
-- bare document ordinals with no way back to the claim that made them, and the two rules that
-- read a narrowing against its own width -- "a point value files narrowsWhen as notApplicable"
-- and its converse -- can only be written over `layer.demand_*`, the one copy reachable from a
-- table. No demand in this corpus is a point value, so one of them reports ⛔ VACUOUS and the
-- other examines 40 of 182 claims and passes. What neither reaches is a RANGED elimination
-- quantity filing `notApplicable`, carrying a note pasted verbatim from the point-valued claim
-- beside it -- which is the failure the rule's own comment names in those words.
--
-- ⭐⭐ AND THE ORDINAL BECOMES STRUCTURAL RATHER THAN LUCKY. `narrowing` and `bound_origin`
-- keyed on a document-order ordinal and were joinable only because `Claim` requires exactly
-- one of each, so the Nth of one belongs to the Nth of the other. That held, and nothing
-- checked it: a desynchronised stream would have attributed every edge to the wrong claim in
-- silence. Both tables now reference this one, so the coincidence is a foreign key.
CREATE TABLE claim (
    filing text NOT NULL REFERENCES filing(name),
    seq    int  NOT NULL,          -- document order; the Nth pm:claim in the document
    -- ⭐⭐ THE POSITION THE CLAIM IS THE VALUE OF, as `parent/element`:
    -- `pm:nameplate/pm:amount`, `pm:holder/pm:share`, `pm:quantum/pm:size`.
    -- ⛔ ONE SEGMENT IS NOT ENOUGH, AND THE REASON IS COUNTABLE. Carrying the parent's NAME
    -- alone, three names are filed at two positions each: `pm:amount` is `Demand/amount` AND
    -- `Nameplate/amount` (86 claims), `pm:size` is the amount quantum AND the window's (61),
    -- `pm:quantity` is a draw's AND a remainder's (4). A filter on a name therefore answers
    -- for a position nobody asked about. `units/with_a_period.sqlc` is the one relation that
    -- filters on this column, and a duty cycle is a fraction of the NAMEPLATE's period, so a
    -- name would hand it the demand's too and return two rows per layer.
    -- `every-absence/delivery` is the filing that disagrees, quoting its demand `per day`
    -- with no nameplate amount at all, and it would cost nothing only because that layer's
    -- window is `unmeasured`.
    owns   text NOT NULL,
    -- ⭐⭐ THE LAYER THIS CLAIM SITS IN, read with `ancestor::pm:layer/pm:name`. NULL is a real
    -- answer and not a gap: a coupling strength, an elimination quantity and a part factor
    -- are claims about a RELATION between layers rather than about one, and there is no
    -- ancestor to find. Without this column `pm.claim` could answer questions about claims
    -- and never join back to the layer relations, and a relation needing both grains would
    -- have to read `pm.nameplate` instead and reach a fraction of the rate-shaped claims.
    layer  text,
    low    numeric NOT NULL,
    mode   numeric NOT NULL,
    high   numeric NOT NULL,
    unit   text    NOT NULL,

    -- ⭐⭐⭐ WHAT SITS UNDER THE LINE, FILED RATHER THAN INFERRED. `pm:StatedDenominator`.
    -- Inferred instead, `LIKE '% per %' OR LIKE '% por %'` over `unit` asks a reader to decide
    -- that `semana` IS `week` -- a judgement no filing makes -- and cannot tell a PERIOD from a
    -- denominator that merely exists. `GPU-hour per GPU` has one and it is not a cycle, so
    -- `kind` carries that difference rather than the query guessing at it.
    denominator      text,
    denominator_kind text CHECK (denominator_kind IN ('period', 'each')),
    denominator_absent absence_reason,

    -- ⭐⭐⭐ WHO ASSERTS THIS CLAIM, AND ON WHAT STANDING. `pm:Provenance`, and until 0.4 it
    -- did not reach the database AT ALL -- zero columns, zero references in ingest -- while
    -- the corpus filed 58 typed absences on `standing` alone. `standing` is the axis the
    -- schema calls the one separating a statutory auditor's observation from a controller's
    -- hunch, and every query about who stands behind a number was unanswerable below the XML.
    --
    -- ⭐ TAXONOMY PLUS VALUE, like `layer.absorber_*` and for the same reason: a borrowed term
    -- travels with the list it was borrowed from, and a restated value set is a fork. There is
    -- no `standing_term` table yet because no reader has mapped two editions of one standing
    -- vocabulary -- when one does, it joins here exactly as `buffer_term` does.
    prov_party             text,
    prov_entered_by        text,
    prov_approved_by       text,
    prov_standing_taxonomy text,
    prov_standing_value    text,
    prov_standing_absent   absence_reason,
    prov_note              text,
    -- `Claim/asOf`, optional: the date the claim holds at. Filed on a fifth of the corpus's claims
    -- and read by no path until 2026-09-18.
    as_of                  date,

    PRIMARY KEY (filing, seq),
    CONSTRAINT a_claim_is_ordered
        CHECK (low <= mode AND mode <= high),
    -- ⚠️ ALL-NULL IS LEGAL HERE AND MEANS "no provenance element", which `Claim` allows.
    -- Within one, `standing` is required, so exactly one of the two arms must be present.
    -- ⛔ The guard is the whole element and not the two arms. Guarded by the arms alone, as
    -- `<= 1`, a provenance naming its party and giving no standing loads as though it had no
    -- provenance at all, and the XSD refuses that document.
    CONSTRAINT a_standing_is_stated_or_typed_absent
        CHECK (num_nonnulls(prov_party, prov_entered_by, prov_approved_by, prov_note,
                            prov_standing_value, prov_standing_absent) = 0
               OR ((prov_standing_value IS NOT NULL) <> (prov_standing_absent IS NOT NULL))),
    CONSTRAINT a_borrowed_standing_carries_its_taxonomy
        CHECK (num_nonnulls(prov_standing_taxonomy, prov_standing_value) <> 1),
    CONSTRAINT a_denominator_is_stated_or_typed_absent
        CHECK ((denominator IS NOT NULL) <> (denominator_absent IS NOT NULL)),
    CONSTRAINT a_stated_denominator_says_which_kind_it_is
        CHECK ((denominator IS NOT NULL) = (denominator_kind IS NOT NULL))
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
    -- `pm:NarrowingDerivation`: the claim is an identity's output, so it narrows as that
    -- identity's terms do.
    derivation identity
        CHECK (derivation IN ('fusionSum', 'magnitude', 'sharesSum', 'sharedParts', 'clearance',
                              'conversionPath')),
    PRIMARY KEY (filing, seq),
    FOREIGN KEY (filing, seq) REFERENCES claim(filing, seq),
    CONSTRAINT a_narrowing_is_stated_or_typed_absent
        CHECK (num_nonnulls(kind, absent, derivation) = 1),
    -- `pm:Narrowing` requires both its condition and its kind, so a narrowing is whole or absent.
    CONSTRAINT a_narrowing_is_whole
        CHECK (num_nonnulls(condition, kind) <> 1)
);

-- ⭐⭐⭐ AND ITS PAIR, IN THE SAME SHAPE AND FOR THE SAME REASON. `narrowsWhen` says what
-- would make a range SMALLER; `boundOrigin` says WHO OWNS THE EDGE it would move. Both sit
-- on `Claim`, so both are scattered across demands, nameplates, quanta, slacks, shares,
-- factors and coupling strengths, and neither question can be asked of a document until the
-- rows are in one place.
--
-- ⛔⛔ A `slack.bound_origin` COLUMN ALONE WAS WHY THE QUESTION LOOKED ANSWERED. With
-- `boundOrigin` optional on every claim and filed once in 124, the only rows worth ingesting
-- were the two sized slacks, which made the field look like a slack attribute rather than what
-- it is. Required and typed, a large share of this corpus's claims name a derivation: the model
-- ALREADY states the author of that edge in a sibling element (`Nameplate/amountOrigin`,
-- `LumpyQuantum/origin`), or the claim is an identity's output and its edge is that identity's
-- terms', and a single column on one table has no way to say so.
CREATE TABLE bound_origin (
    filing text NOT NULL REFERENCES filing(name),
    seq    int  NOT NULL,
    origin constraint_origin,
    absent absence_reason,
    -- `pm:BoundDerivation`: the author is stated in a sibling origin, or the edge is the terms'
    -- of the identity that computes the claim.
    derivation identity
        CHECK (derivation IN ('amountOrigin', 'quantumOrigin', 'fusionSum', 'magnitude',
                              'sharesSum', 'sharedParts', 'clearance', 'conversionPath')),
    PRIMARY KEY (filing, seq),
    FOREIGN KEY (filing, seq) REFERENCES claim(filing, seq),
    CONSTRAINT an_origin_is_stated_or_typed_absent
        CHECK (num_nonnulls(origin, absent, derivation) = 1)
);

-- ⛔ AND THE OTHER DIRECTION, WHICH `Claim` REQUIRES AND THE TWO KEYS ABOVE DO NOT SAY. They
--   make every narrowing and every origin belong to a claim; `narrowsWhen` and `boundOrigin` are
--   required, so every claim also owes one row in each. Declared once both tables exist, and
--   deferred to the end of the loading transaction, because a claim is inserted before the two
--   rows that complete it.
ALTER TABLE claim
    ADD CONSTRAINT a_claim_states_what_would_narrow_it_or_why_not
        FOREIGN KEY (filing, seq) REFERENCES narrowing(filing, seq) DEFERRABLE INITIALLY DEFERRED,
    ADD CONSTRAINT a_claim_states_who_owns_its_edge_or_why_not
        FOREIGN KEY (filing, seq) REFERENCES bound_origin(filing, seq) DEFERRABLE INITIALLY DEFERRED;

-- ⭐⭐⭐ EVERY TYPED ABSENCE IN A DOCUMENT, AND THE ELEMENT THAT MADE IT: THE MIRROR OF `claim`.
--   `pm:Absence` and `pm:ClaimAbsence` are the other arm of every `Stated*` wrapper, so an
--   absence is filed at as many positions as a claim, and each carries what `claim` carries for a
--   value: a note arguing for it, who declined and on what standing, and the date it holds at.
--   Its REASON is also a column on the table of the thing it is about, because that is where the
--   stated-or-absent CHECKs need it. Everything else was dropped on load, at every position but
--   three: most filed absences carry a note, and the notes are where a document argues.
--
-- ⛔ SO THE REASON IS HELD TWICE, AND A LAW IS WHAT KEEPS THAT FROM BEING A COPY NOBODY CHECKS.
--   `algebra/absences_filed.sqlc` counts, per filing, position and reason, the census built from
--   the columns against the rows of this table. A branch the ingest drops, a column no census arm
--   reads, or an arm counting one absence twice each moves one side and not the other.
--
-- `owns` is `parent/wrapper`, the same spelling as `claim.owns`: the demand's claim and the
-- demand's absence are both `pm:demand/pm:amount`.
CREATE TABLE absence (
    filing text NOT NULL REFERENCES filing(name),
    seq    int  NOT NULL,          -- document order; the Nth absent element in the document
    owns   text NOT NULL,
    layer  text,                   -- the layer it sits in; NULL for one about the document or a fusion
    reason absence_reason NOT NULL,
    note   text,
    as_of  date,

    prov_party             text,
    prov_entered_by        text,
    prov_approved_by       text,
    prov_standing_taxonomy text,
    prov_standing_value    text,
    prov_standing_absent   absence_reason,
    prov_note              text,

    PRIMARY KEY (filing, seq),
    CONSTRAINT an_absence_standing_is_stated_or_typed_absent
        CHECK (num_nonnulls(prov_party, prov_entered_by, prov_approved_by, prov_note,
                            prov_standing_value, prov_standing_absent) = 0
               OR ((prov_standing_value IS NOT NULL) <> (prov_standing_absent IS NOT NULL))),
    CONSTRAINT an_absence_standing_term_is_whole
        CHECK (num_nonnulls(prov_standing_taxonomy, prov_standing_value) <> 1)
);

-- ⭐⭐⭐ EVERY DERIVATION IN A DOCUMENT, THE MIRROR OF `absence` FOR THE THIRD ARM. `pm:Derivation`
--   carries what `pm:Absence` carries beside its reason: a note, a provenance and a date. Its
--   IDENTITY is also a column on the table of the thing it is about, where the three-arm CHECKs
--   need it, so it is held twice and `algebra/derivations_filed.sqlc` is the law that keeps the
--   two from drifting, as `algebra/absences_filed.sqlc` does for the reasons.
--
-- `owns` is `parent/wrapper`, the same spelling as `claim.owns` and `absence.owns`. A derivation
--   of a claim's edge or narrowing sits at `pm:claim/pm:boundOrigin` or `pm:claim/pm:narrowsWhen`,
--   which every claim shares, so `claim_owns` carries the claim's own position: the identity
--   computes THAT position, and without it the pairing cannot be read.
CREATE TABLE derivation (
    filing   text NOT NULL REFERENCES filing(name),
    seq      int  NOT NULL,        -- document order; the Nth derivation element in the document
    owns     text NOT NULL,
    claim_owns text,               -- the enclosing claim's `owns`; NULL for a figure's derivation
    layer    text,                 -- the layer it sits in; NULL for one about a fusion
    identity identity NOT NULL,
    note     text,
    as_of    date,

    prov_party             text,
    prov_entered_by        text,
    prov_approved_by       text,
    prov_standing_taxonomy text,
    prov_standing_value    text,
    prov_standing_absent   absence_reason,
    prov_note              text,

    PRIMARY KEY (filing, seq),
    CONSTRAINT a_claim_derivation_names_its_claim
        CHECK ((claim_owns IS NOT NULL) = (owns IN ('pm:claim/pm:boundOrigin', 'pm:claim/pm:narrowsWhen'))),
    CONSTRAINT a_derivation_standing_is_stated_or_typed_absent
        CHECK (num_nonnulls(prov_party, prov_entered_by, prov_approved_by, prov_note,
                            prov_standing_value, prov_standing_absent) = 0
               OR ((prov_standing_value IS NOT NULL) <> (prov_standing_absent IS NOT NULL))),
    CONSTRAINT a_derivation_standing_term_is_whole
        CHECK (num_nonnulls(prov_standing_taxonomy, prov_standing_value) <> 1)
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
    -- `pm:StatedTimeSlack`: only the time slack may be the clearance, named. Capacity and
    -- inventory slack are measured facts about the supply, and no identity computes either.
    derivation   identity,
    -- Who owns a sized slack's edge is its claim's `bound_origin` row, like every claim's.
    CONSTRAINT a_slack_absence_has_no_none CHECK (absent <> 'none'),
    CONSTRAINT only_the_time_slack_is_computed
        CHECK (derivation IS NULL OR (buffer = 'time' AND derivation = 'clearance')),
    PRIMARY KEY (filing, layer, buffer),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT slack_is_stated_or_typed_absent
        CHECK (num_nonnulls(low, absent, derivation) = 1),
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
    share_derivation identity CHECK (share_derivation = 'sharesSum'),
    party      text,
    as_of      date,
    CONSTRAINT a_share_absence_has_no_none CHECK (share_absent <> 'none'),
    -- `Holder/share` is a REQUIRED `pm:StatedShare`: every named holder states its share, names
    -- it as the rest of the remainder, or types why not.
    CONSTRAINT a_share_is_stated_or_typed_absent
        CHECK (num_nonnulls(share_low, share_absent, share_derivation) = 1),
    PRIMARY KEY (filing, layer, kind),   -- `holderKind`: a kind appears at most once per remainder
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

-- ---------------------------------------------------------------------------
-- P, THE OPERATION INDEX, AND THE ONE PLACE THIS MODEL NAMES A POSITION IN A
-- PROCESS NOTATION.
--
-- ⭐⭐⭐ `pm:Operation/foreignId` IS THE WHOLE BPMN INTERFACE AND IT HAD NO COLUMN.
-- `pm:ForeignId` is a notation plus an id and nothing else, and the model carries
-- THREE of them: an `asrt:Part`, an `asrt:Elimination/between`, and this. The first two
-- are ingested and have reference relations beside them; this one was dropped on
-- every load, so the corpus filed it, the database never saw it, and the emitted
-- BPMN could not carry it. A crossing nothing stores is a crossing nothing can show.
--
-- ⛔ THE NOTATION IS A LANGUAGE HERE AND A DOCUMENT IN A PART, WHICH IS WHY THIS END
-- GETS NO FOREIGN KEY AND MUST NOT. `part_filing` resolves through `filing_identity`
-- because a part names another FILING; this names the OMG BPMN MODEL URI, and the id
-- names a node in whichever BPMN document travels with the filing. No authority
-- publishes that list, so there is nothing to resolve against and nothing to key.
-- `pm:ForeignId`'s own annotation refuses the lookup outright: a receiver sent to find
-- `Task_17` in a normative list finds nothing there and reads it as a defect in the list.
--
-- ⭐⭐⭐ AND THE ABSENCE IS TYPED, WHICH IT WAS NOT WHEN THE COLUMN FIRST ARRIVED. The first
-- cut of this table followed `part_regime`: nullable, no typed absence, because
-- `foreignId` was `minOccurs="0"` over a `pm:ForeignId` with no absence branch, and a
-- typed absence would have been the DDL answering a question the XSD declined to ask.
-- ⛔ The repair was in the XSD rather than here. `notationPosition` is REQUIRED and takes
-- `pm:StatedForeignId`, a choice of the pair or an `Absence`, so the three things an
-- omission would collapse are three filed answers: `none` is in no notation and
-- somebody looked, `unmeasured` is a notation exists and nobody located this operation in it,
-- `notApplicable` is this filing has no notation to point into. ⭐ Most operations file an
-- absence, which is expected; what is refused is the blank.
-- ---------------------------------------------------------------------------
CREATE TABLE operation (
    filing text NOT NULL REFERENCES filing(name),
    label  text NOT NULL,
    -- pm:Operation/pm:notationPosition. Both children are required INSIDE `pm:ForeignId`,
    -- so the pair is whole or wholly absent, never half.
    foreign_notation text,
    foreign_id       text,
    foreign_absent   absence_reason,
    CONSTRAINT a_foreign_id_is_whole
        CHECK (num_nonnulls(foreign_notation, foreign_id) <> 1),
    -- ⛔ `<>` AND NOT `<= 1`, BECAUSE THE WRAPPER IS REQUIRED. `asrt:Part/factor` gets the
    --    weaker form for a stated reason: its wrapper is optional and an omitted factor
    --    MEANS phi = 1 exactly, so all-NULL is a third legal state. Nothing here means
    --    anything, so exactly one arm is filled and a blank is a load failure.
    CONSTRAINT a_notation_position_is_stated_or_typed_absent
        CHECK ((foreign_notation IS NOT NULL) <> (foreign_absent IS NOT NULL)),
    PRIMARY KEY (filing, label)          -- `operationLabel`: an operation is named once in its filing
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
    PRIMARY KEY (filing, operation, layer),   -- `operationDraw`: D has one entry per operation and layer
    FOREIGN KEY (filing, operation) REFERENCES operation(filing, label),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT a_draw_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high)),
    -- `Draw/quantity` is a REQUIRED `pm:StatedClaim`, and its absent arm is a `ClaimAbsence`,
    -- which has no `none`: a draw of nothing is a claim of [0, 0, 0].
    CONSTRAINT a_drawn_quantity_is_stated_or_typed_absent
        CHECK ((low IS NOT NULL) <> (absent IS NOT NULL)),
    CONSTRAINT a_drawn_quantity_absence_has_no_none CHECK (absent <> 'none')
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
    PRIMARY KEY (filing, operation, layer),   -- `operationInduction`: N has one entry per operation and layer
    FOREIGN KEY (filing, operation) REFERENCES operation(filing, label),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT a_induction_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high)),
    -- `Induction/commitment` is a REQUIRED `pm:StatedClaim`, the same shape as `Draw/quantity`.
    CONSTRAINT a_commitment_is_stated_or_typed_absent
        CHECK ((low IS NOT NULL) <> (absent IS NOT NULL)),
    CONSTRAINT a_commitment_absence_has_no_none CHECK (absent <> 'none')
);

-- ⭐⭐⭐ HOW MUCH OF THE SYSTEM IS IN THIS STACK. There is ONE system; a filing holds the
-- layers of it that mattered to whoever filed, and without its scope `pm:Stack` read as though it
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
        CHECK ((extent IS NOT NULL) <> (absent IS NOT NULL)),
    -- `pm:Scope` requires its basis beside its extent: how much of the system, and by what cut.
    CONSTRAINT a_scope_is_whole
        CHECK (num_nonnulls(extent, basis) <> 1)
);

-- ⭐⭐⭐ DID ANYBODY LOOK? ONE ROW PER FILING, AND IT IS THE ROW THAT MAKES THE EMPTY
-- `coupling` TABLE READABLE. The comment above the tall tables says an empty `coupling`
-- table "is a document where nobody looked rather than a document where nothing was
-- found" -- true, and for two revisions there was no column anywhere that said which.
--
-- ⛔ THE COUNT THIS BUYS IS ABOUT THE EVIDENCE RATHER THAN ABOUT ANY ONE FILING: how many
-- stacks file couplings, how many say nobody looked, how many have no second layer to look
-- at, and how many say somebody looked and the layers moved independently. The model's
-- central assumption -- that layers hold their remainders independently -- is tested only by
-- the last, and `epistemics/coupling_searches.sqlc` prints each stack's answer.
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
    -- ⭐⭐ `pm:Coupling/strength` WAS THE SECOND OPTIONAL `pm:StatedClaim` IN THESE SCHEMAS AND
    --   IS REQUIRED NOW, so this column has two states and not three. The three were: no
    --   element, a stated strength, or a dependence somebody observed and could not size. The
    --   first and the third are one fact. The element's own annotation justified the
    --   optionality as "the direction is frequently known when the magnitude is not", which is
    --   the definition of `unmeasured`, and the corpus proved they had collapsed: two of five
    --   couplings omitted the element and NOT ONE ever filed the typed absence.
    -- ⛔ `asrt:Part/factor` KEEPS ITS THREE, and the asymmetry is the point. An omitted factor
    --   means the part's unit and the composed layer's already agree, so the identity is FORCED
    --   by structure the document states and there is no author to name. An omitted strength
    --   was forced by nothing. `checks/unit_crossing_without_a_factor` is what keeps the first
    --   true: omit the element where the units DIFFER and the rule fires.
    strength_absent absence_reason,
    observation text NOT NULL,   -- `Coupling/observed`, REQUIRED: what was seen that couples them
    CONSTRAINT a_strength_absence_has_no_none CHECK (strength_absent <> 'none'),
    PRIMARY KEY (filing, from_layer, to_layer),   -- `couplingPair`: C has one entry per pair
    FOREIGN KEY (filing, from_layer) REFERENCES layer(filing, layer),
    FOREIGN KEY (filing, to_layer)   REFERENCES layer(filing, layer),
    CONSTRAINT a_coupling_strength_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high)),
    CONSTRAINT a_coupling_strength_is_stated_or_typed_absent
        CHECK ((low IS NOT NULL) <> (strength_absent IS NOT NULL))
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
-- ✅⭐⭐⭐ THE SECOND READER'S MAPPING, AS DATA RATHER THAN AS A READER. S-28.
--
-- A composition names its parts by a `ForeignId`: a notation plus an id, e.g.
-- `urn:example:filing:us-member:2026-08-31` / `compute`. Before `pm:notation` NO DOCUMENT
-- DECLARED ITS OWN NOTATION -- `Composition` carried witness, observedAt, provenance,
-- regime, citation and fusion, and nothing naming the document as that URN, and neither did
-- `pm:processModulus`. So a part reference could not be resolved from the corpus at
-- all, and the conformance rule "a dependence end's filing exists, and the layer named
-- is in it" presupposed a lookup the model did not provide.
--
-- ⭐ WRITING THIS QUERY IS WHAT SURFACES IT: a foreign key needs something to point AT. It is
-- invisible from both other angles -- XSD 1.0 cannot follow a cross-document reference so it
-- never has to resolve one, and the Rust tests load by FILENAME and pass the name in
-- themselves.
--
-- ⛔ THE VALUE IS THE DOCUMENT'S AND NEVER THE READER'S. `'the reader, from the filename'`
-- is a guess dressed as data. These are read out of `pm:processModulus/pm:notation` by
-- XMLTABLE like every other fact, and `asserted_by` records which filing said it about
-- itself.
--
-- ⭐⭐ AND IT IS WHAT MAKES A LOCAL PART RESOLVABLE. A part whose notation equals its own
-- composition's is local: it names a layer that composition built. Nothing else changed
-- to allow it -- no second kind of part, no new column -- so `part` below carries local
-- and foreign rows in one table and the join tells them apart.
-- ---------------------------------------------------------------------------
--
-- ⛔ ONE ROW PER FILING, THE NOTATION STATED OR TYPED ABSENT. Keyed on the notation, the table
-- could not hold a filing that declines to name itself, so `absent` was a column no row could
-- fill and the ingest dropped the branch before it arrived. Keyed on the filing, the notation is
-- the stated arm like every other `Stated*` site, and still unique where it is stated.
CREATE TABLE filing_identity (
    filing   text PRIMARY KEY REFERENCES filing(name),
    notation text UNIQUE,
    asserted_by text NOT NULL,
    absent   absence_reason,   -- a filing that declines to name itself, and why
    CONSTRAINT a_filing_names_itself_or_says_why_not
        CHECK ((notation IS NOT NULL) <> (absent IS NOT NULL))
);

-- ---------------------------------------------------------------------------
-- Composition. F and Phi live in one table, because a part IS an incidence entry
-- and its conversion factor at the same time.
-- ---------------------------------------------------------------------------

-- ⭐ A FUSION: ONE COMPOSED LAYER AND WHAT THE COMPOSER SAW THAT MAKES ITS PARTS ONE LAYER.
--   `asrt:Fusion` is keyed by name in its composition (`fusionTarget`) and its `observed` is
--   REQUIRED. Parts, the search for double counting and the eliminations each belong to one, and
--   until 2026-09-18 there was no row to belong to: `observed` was read by no path.
CREATE TABLE fusion (
    composition    text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    observed       text NOT NULL,
    PRIMARY KEY (composition, composed_layer),
    CONSTRAINT a_fusion_composes_a_layer_of_the_composing_filing
        FOREIGN KEY (composition, composed_layer) REFERENCES layer(filing, layer)
);

-- F (incidence) and Phi (diagonal conversion) together. One row per part used.
CREATE TABLE part (
    composition   text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    part_filing   text NOT NULL,
    part_layer    text NOT NULL,
    -- ⭐⭐ WHICH OF THE COMPOSITION'S OWN DECLARED REGIMES THIS PART COMES UNDER, a document-local
    --    handle into `composition_regime`. XSD 1.0 checks that it resolves (`compositionRegimeId`
    --    keyed, `partRegime` referring), which is the strongest thing a grammar can do here, and
    --    it stops at the document edge. ⛔ Whether the composer's claim AGREES with what that
    --    part's own filing declares is cross-document and is a rule's job, not a keyref's.
    --    ⚠️ Nullable, and a NULL means the composer named no regime for this part. It gets no
    --    typed absence: `asrt:regime` is `minOccurs="0"` on a part, and a composition that
    --    declares no regimes at all has nothing for a handle to point at.
    part_regime   text,
    -- ⭐⭐⭐ FOUR STATES, BECAUSE THE WRAPPER IS OPTIONAL AND ITS CHOICE HAS THREE ARMS.
    --   `asrt:Part/factor` is `minOccurs="0"`, so a part may (a) omit it, meaning the part is
    --   ALREADY in the composed unit at phi = 1, or (b) state a conversion, or (c) file a typed
    --   absence, a conversion nobody measured, or (d) file a derivation, below. (a) and (c) are
    --   different documents and were the same three NULLs here until `factor_absent` existed.
    --   `public.factor_state` names the four, and composition/part_references.sqlc assigns them.
    -- ⛔ Reading (c) as phi = 1 asserts a rate no composer filed. `asrt:Part` is explicit that
    --   an absent factor means ONE **exactly**, never "unknown", which is true of (a) and is
    --   exactly why (c) needs a column of its own rather than borrowing (a)'s silence.
    factor_low    numeric,     -- all three NULL with factor_absent NULL: the units already agree
    factor_mode   numeric,
    factor_high   numeric,
    factor_absent absence_reason,   -- (c): the typed reason nobody measured the conversion
    -- (d): the factor is an identity's output, `pm:FactorDerivation`: solved from the fusion's
    --      sum, or the product of conversions other filings state.
    factor_derivation identity CHECK (factor_derivation IN ('fusionSum', 'conversionPath')),
    CONSTRAINT a_factor_absence_has_no_none CHECK (factor_absent <> 'none'),
    PRIMARY KEY (composition, composed_layer, part_filing, part_layer),
    CONSTRAINT a_factor_is_strictly_positive
        CHECK (factor_low IS NULL OR factor_low > 0),
    -- ⭐ No unit here, and that is not an omission: phi is a RATIO of two units, so the
    --   claim is whole at three numbers.
    CONSTRAINT a_factor_claim_is_whole_and_ordered
        CHECK (num_nonnulls(factor_low, factor_mode, factor_high) = 0
               OR (num_nonnulls(factor_low, factor_mode, factor_high) = 3
                   AND factor_low <= factor_mode AND factor_mode <= factor_high)),
    -- ⚠️ `<= 1`, not `<>`, and the difference is the third state. ALL-NULL IS LEGAL and means
    --   "no factor element". A required wrapper gets `<>`; an optional one gets this; and a
    --   required wrapper inside an optional element gets `<>` guarded by that element's
    --   presence, as `a_standing_is_stated_or_typed_absent` above does for "no provenance
    --   element".
    CONSTRAINT a_factor_is_stated_or_typed_absent
        CHECK (num_nonnulls(factor_low, factor_absent, factor_derivation) <= 1),
    -- ⭐⭐⭐ THE IMAGE OF AN xs:keyref THE GRAMMAR ALREADY ENFORCES. `assertion.xsd` is explicit:
    --   "a fusion has a foreign end and a local one, the composed layer is in this very document
    --   ... and a fusion naming a layer the composer did not file is a schema error." That is
    --   `fusionName`, enforced by any validator, and this key is its image here.
    -- ⛔ AND THE OTHER END IS DELIBERATELY UNKEYED. `(part_filing, part_layer)` gets no foreign
    --   key and must not get one: `part_filing` is a NOTATION resolved through `filing_identity`,
    --   whose own `absent` admits a filing that declines to name itself, and a part naming a
    --   filing the reader does not hold is ordinary. `checks/local_part_dangles.sqlc` carries
    --   that asymmetry as a rule, which is where it belongs.
    CONSTRAINT a_composed_layer_is_a_layer_of_the_composing_filing
        FOREIGN KEY (composition, composed_layer) REFERENCES layer(filing, layer),

    -- ⭐ THE REST OF `asrt:FiledLayer`, which the part's layer is. `party` is REQUIRED and names
    --   who filed the layer; `registration` and `version` are optional. `elimination_between`
    --   holds the same type and carries the same columns.
    part_party                 text NOT NULL,
    part_registration_taxonomy text,
    part_registration_value    text,
    part_version               text,
    CONSTRAINT a_part_registration_is_whole
        CHECK (num_nonnulls(part_registration_taxonomy, part_registration_value) <> 1),
    CONSTRAINT a_part_belongs_to_a_fusion
        FOREIGN KEY (composition, composed_layer) REFERENCES fusion(composition, composed_layer),
    -- ⛔ `partIdentity` keys a part's filed layer over the WHOLE composition, not per fusion: one
    --   filed layer is a part of one fusion at most.
    CONSTRAINT a_filed_layer_is_a_part_once_in_a_composition
        UNIQUE (composition, part_filing, part_layer),
    -- `partRegime`: the handle resolves into the composer's own regime declarations.
    CONSTRAINT a_part_regime_resolves
        FOREIGN KEY (composition, part_regime) REFERENCES composition_regime(composition, id)
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
    PRIMARY KEY (composition, composed_layer),
    -- ⭐ The image of `fusionName` again. See `part`.
    CONSTRAINT a_searched_layer_is_a_layer_of_the_composing_filing
        FOREIGN KEY (composition, composed_layer) REFERENCES layer(filing, layer),
    CONSTRAINT a_search_belongs_to_a_fusion
        FOREIGN KEY (composition, composed_layer) REFERENCES fusion(composition, composed_layer)
);

-- ⛔ AND EVERY FUSION SAYS WHETHER ANYBODY LOOKED. `Fusion/eliminations` is REQUIRED, so a fusion
--   with no row above is a fusion whose search was dropped on the way in. Deferred, because the
--   fusion is loaded before its search.
ALTER TABLE fusion
    ADD CONSTRAINT a_fusion_says_whether_anybody_looked_for_double_counting
        FOREIGN KEY (composition, composed_layer)
        REFERENCES elimination_search(composition, composed_layer) DEFERRABLE INITIALLY DEFERRED;

-- e_x. Quantities double-counted across parts, filed one at a time with prose.
CREATE TABLE elimination (
    composition    text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    quantity       summed_quantity NOT NULL,
    low            numeric,
    mode           numeric,
    high           numeric,
    unit           text,
    absent         absence_reason,
    -- `pm:EliminationDerivation`: the fusion's sum solved for `e`, or the double counting the
    -- structure implies. The two need not agree, so the filer names which.
    derivation     identity CHECK (derivation IN ('fusionSum', 'sharedParts')),
    reason         text,
    -- ⭐⭐⭐ WHICH CLAIM THIS QUANTITY IS, BY DOCUMENT POSITION, AND IT IS WHAT LETS AN ELIMINATION
    -- REACH ITS OWN EDGE. `bound_origin` and `narrowing` are keyed on a claim's ordinal while this
    -- table is keyed on a fusion and a quantity, so without this column what a claim says about who
    -- set its bound is ingested and unreachable from the figure it is about.
    -- ⛔ AND THE FIGURES CANNOT RECOVER IT. Two eliminations of one filing may carry the same three
    -- points in the same unit, so a join on the values returns a product rather than a row, and
    -- document order cannot do it either because the ordinals of a filing's elimination claims are
    -- not contiguous. It is read on the `preceding::` axis at ingest, where the axis means the
    -- document rather than one fusion's fragment.
    claim_seq      int,
    CONSTRAINT a_eliminated_quantity_absence_has_no_none CHECK (absent <> 'none'),
    CONSTRAINT an_eliminated_claim_is_placed_exactly_when_it_is_stated
        CHECK ((claim_seq IS NOT NULL) = (low IS NOT NULL)),
    CONSTRAINT an_eliminated_claim_is_a_claim_of_the_composing_filing
        FOREIGN KEY (composition, claim_seq) REFERENCES claim(filing, seq),
    PRIMARY KEY (composition, composed_layer, quantity),   -- `eliminationAgainst`: one e per quantity
    CONSTRAINT a_eliminated_quantity_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high)),
    -- `asrt:Elimination/quantity` is a REQUIRED `pm:StatedEliminatedQuantity`.
    CONSTRAINT an_eliminated_quantity_is_stated_or_typed_absent
        CHECK (num_nonnulls(low, absent, derivation) = 1),
    -- ⭐ The image of `fusionName`, an xs:keyref the grammar already enforces. See `part`.
    CONSTRAINT a_eliminated_layer_is_a_layer_of_the_composing_filing
        FOREIGN KEY (composition, composed_layer) REFERENCES layer(filing, layer),
    CONSTRAINT an_elimination_belongs_to_a_fusion
        FOREIGN KEY (composition, composed_layer) REFERENCES fusion(composition, composed_layer)
);

-- ⭐⭐⭐ THE LAYERS A DOUBLE COUNT RUNS BETWEEN, WHICH IS THE EVIDENCE FOR AN ELIMINATION.
-- Repeating, `minOccurs="0" maxOccurs="unbounded"` on `asrt:Elimination`. Without a home here
-- the corpus's eight are lost on a round trip: load `merge-holding-composition.xml`, write the
-- XML back out, and every one is gone. Nothing notices, because no rule reads them, which is
-- the shape of defect only the WRITE direction finds. A rule reads what it needs; a document
-- must be storable whole.
--
-- ⛔ `notation` gets NO foreign key, for the same reason `part.part_filing` gets none: it is a
-- foreign reference that may legitimately dangle. `asrt:Elimination` argues the point directly,
-- refusing a keyref that would restrict `between` to the fusion's own parts, because "a group
-- eliminating against a member that files nothing, or against a layer folded into a different
-- composed layer, is ordinary".
CREATE TABLE elimination_between (
    composition    text NOT NULL,
    composed_layer text NOT NULL,
    quantity       summed_quantity NOT NULL,
    seq            int  NOT NULL,
    party          text NOT NULL,
    notation       text NOT NULL,   -- a pm:ForeignId notation; may name a filing nobody holds
    layer          text NOT NULL,
    version        text,
    regime         text,
    -- `asrt:FiledLayer/registration`, optional, as on `part`: one shape for one type.
    registration_taxonomy text,
    registration_value    text,
    PRIMARY KEY (composition, composed_layer, quantity, seq),
    FOREIGN KEY (composition, composed_layer, quantity)
        REFERENCES elimination(composition, composed_layer, quantity),
    CONSTRAINT a_between_registration_is_whole
        CHECK (num_nonnulls(registration_taxonomy, registration_value) <> 1),
    -- `eliminationBetweenRegime`: the handle resolves into the composer's own regime declarations.
    CONSTRAINT a_between_regime_resolves
        FOREIGN KEY (composition, regime) REFERENCES composition_regime(composition, id),
    -- `betweenLayer`: the layers a double count runs between are a set, so one is named once.
    CONSTRAINT a_layer_is_between_once
        UNIQUE (composition, composed_layer, quantity, notation, layer)
);

-- ⭐ THE STANDARDS A COMPOSITION WORKS UNDER. Repeating on `asrt:Composition`, and homeless for
-- the same reason and until the same date. Two are filed in this corpus.
CREATE TABLE composition_citation (
    composition text NOT NULL REFERENCES filing(name),
    seq         int  NOT NULL,
    -- ⭐ `asrt:instrument` is a pm:BorrowedTerm: a taxonomy and a value, the same shape
    --   `buffer_term` and `Regime/framework` use. Two columns, never one.
    taxonomy    text NOT NULL,
    instrument  text NOT NULL,
    clause      text,
    version     text,
    PRIMARY KEY (composition, seq)
);

COMMIT;
