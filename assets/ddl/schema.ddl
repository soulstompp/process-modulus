-- process-modulus, as relations.
--
-- This schema exists to check what the XSD cannot. It is not a schema to copy: nothing here is
-- normalised for writing, indexed for a workload, or shaped for an application. Copy the ideas,
-- not the layout.
--
-- Run it with:  psql -f assets/ddl/schema.ddl
-- Then ingest:  psql -f assets/sql/ingest.sql   (from the repository root; it reads
--                                                assets/corpus/ and assets/fixtures/)

BEGIN;

DROP SCHEMA IF EXISTS pm CASCADE;
CREATE SCHEMA pm;
SET search_path TO pm, public;

-- ---------------------------------------------------------------------------
-- The closed sets. Each is an enum, so a value outside the set is refused when it is written.
-- One is borrowed from a standard; the rest are this model's own.
-- ---------------------------------------------------------------------------

-- Borrowed from ISO 286. Three classes, and `transition` is the one that means short at the top
-- of the demand range and spare at the bottom: both at once.
CREATE TYPE fit AS ENUM ('clearance', 'transition', 'interference');

-- This model's own. Only `booked` is a transaction inside the entity.
CREATE TYPE holder_kind AS ENUM ('booked', 'counterparty', 'customer', 'people', 'unrealised');

-- This model's own, and not the borrowed set it looks like. The three members name the three
-- elements a layer carries, `capacitySlack`, `inventorySlack` and `timeSlack`, which belong to
-- this schema. The buffer a remainder names is a different thing: see `layer.absorber_*` below.
CREATE TYPE buffer AS ENUM ('inventory', 'capacity', 'time');

-- The three quantities of a layer that a fusion sums, `asrt:EliminationAgainst`. A fusion's sum,
-- an elimination and a suspension are each keyed on one of them, so this is a dimension the
-- model owns, and a relation crossing the fusions with the quantities reads this set rather than
-- whichever quantities happen to be filed.
CREATE TYPE summed_quantity AS ENUM ('demand', 'nameplate', 'draw');

-- Who you would have to talk to in order to change it.
CREATE TYPE constraint_origin AS ENUM ('intrinsic', 'contractual', 'policy');

-- A blank that says which kind of blank it is. A NULL says nothing about why it is null, and
-- that silence is what the model exists to avoid. So every quantity below carries a nullable
-- range beside a reason, and a CHECK holds exactly one of the two present.
CREATE TYPE absence_reason AS ENUM ('none', 'unmeasured', 'notApplicable');

-- A value computed from other elements is not a blank: it names the calculation that gives it.
-- `pm:Identity` is the closed list of this model's calculations, and `pm:Derivation` names one
-- of them at a position filed as its result. An absence reason has no place to say which
-- calculation, so a computed figure has a column of its own.
--
-- Every position the XSD lets be computed carries a derivation column beside its absence column.
-- Exactly one of the value, the absence and the derivation is present (at most one on a part's
-- optional factor), and a CHECK holds the column to the members the XSD admits there, so a
-- document the grammar refuses is refused here too. The `derivation` table below holds every
-- derivation element whole, as `absence` does for the reasons.
CREATE TYPE identity AS ENUM (
    'fusionSum', 'magnitude', 'fit', 'clearance', 'sharesSum', 'sharedParts', 'conversionPath',
    'amountOrigin', 'quantumOrigin');

-- Where the value already names the empty case, the XSD narrows the reason. The absent arm of
-- every `pm:StatedClaim` is a `pm:ClaimAbsence`, whose `pm:ClaimAbsenceReason` is
-- `AbsenceReason` without `none`. A measured zero has a unit, an observer, an author for its
-- exactness and a provenance, and an absence has a place for none of the four, so a zero is a
-- claim of 0, 0 and 0 and never an absence.
--
-- Two wrappers that are not claims take a `pm:ClaimAbsence` for the same reason: their value has
-- a named state for the empty case, and `none` would be a second way of filing it. In
-- `pm:StatedRemainder`, "there is no remainder" reads either "nothing to subtract from" or "the
-- difference is zero", and a zero difference is a `clearance` fit carrying 0, 0 and 0 and a
-- sign. In `pm:StatedLumpyQuantum` at `window`, a supply that runs all the time files one whole
-- period, with a size and an origin saying who could change it.
--
-- Every column below that holds one of these wrappers' reasons has its own
-- `..._absence_has_no_none` CHECK, so Postgres refuses a `'none'` no valid document can produce.
-- Each is a CHECK on the column rather than a domain over the enum: the column keeps the enum's
-- type, and with it the comparison against a literal, so `WHERE absent = 'unmeasured'` resolves.
--
-- `boundOrigin`, `couplings`, `absorber`, `notation` and `framework` keep the whole enum, and the
-- same test says why: nothing sets this bound; somebody looked and the layers move
-- independently; no buffer took it; published under no identifier; reports under no framework.
-- Those are nothings. A window of one whole period is a number.

-- This model's own, and the typed half of `narrowsWhen`.
CREATE TYPE narrowing_kind AS ENUM ('instrument', 'intervention', 'experiment');

-- ---------------------------------------------------------------------------
-- Documents.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- The repository's own compose graph, one row per `(parent, child)` pair of `.sqlc` templates,
-- with how many times the parent splices the child. `examples/compositions/main.rs` builds it
-- from the source tree without a database and writes `assets/dag/edges.sql`; `ingest` loads that.
--
-- Why it is in `public`
--   Everything in `pm` descends from a filed document, except the reader's mapping in
--   `buffer_term`, which says so. A fact about this repository's own queries does not, so it
--   lives outside `pm`. `diagrams/lane_grain.sqlc` crosses the same line when it reads
--   `pg_constraint`.
--
-- Why `splices` matters
--   A parent composing a child twice is ordinary: the child gives the same rows each time, and
--   the composed SQL holds it once, as one `WITH` entry the parent reads twice. The same shape in
--   `pm.part` is a violation, `checks/jagged_layer`: a supply reached twice enters the total
--   twice. Two graphs of one shape get opposite verdicts on one column, which is what this model
--   adds to `sql-composer`, and keeping the count in SQL makes that comparison a query anybody
--   can run. A bare edge would lose it.
--
-- Dropped by name
--   `DROP SCHEMA pm CASCADE` above does not reach `public`.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS public.compose_edge CASCADE;
CREATE TABLE public.compose_edge (
    parent  text    NOT NULL,
    child   text    NOT NULL,
    -- Strictly positive. A row exists because a directive does, so zero is not a state: a parent
    -- that does not compose a child has no row, as everywhere here a pair that does not exist has
    -- none.
    splices integer NOT NULL CHECK (splices > 0),
    -- How many of those splices are an inner join. Composing a relation as the driving set or
    -- with a `LEFT JOIN` asks *what is missing from the whole*; inner-joining it asks *does this
    -- one pair exist*, and hands the whole composed relation to every consumer downstream. One
    -- inner join of `layers/every_layer.sqlc`, the list of every layer, would put the whole list
    -- among the relations most rules compose, and every law that a rule's reach lies inside the
    -- reach of what it composes would then hold without testing anything. A count rather than a
    -- kind, because one parent may splice one child at several places;
    -- `algebra/dimension_use.sqlc` only asks whether it is above zero.
    inner_joins integer NOT NULL CHECK (inner_joins >= 0),
    CONSTRAINT inner_joins_are_some_of_the_splices CHECK (inner_joins <= splices),
    PRIMARY KEY (parent, child)
);

-- ---------------------------------------------------------------------------
-- The classes this repository's own queries sort things into. A classification puts each row in
-- one class of a declared set. A law checks that every row lands in exactly one class, and that
-- check still passes when a class is renamed, or misspelt. So each set is declared once, here,
-- and every arm that names a class and every consumer that selects on one is checked against it.
--
-- Why an enum
--   A string literal cast to an enum is checked when the query is parsed, so a misspelt class
--   fails on every run whether or not any row reaches its arm. A CHECK, a domain or a roster is
--   consulted only by rows. The arm that matters most is often the one no row has taken:
--   `not comparable`, which `examples/readiness/main.rs` holds at zero, is checked only by the
--   parser.
--
-- The label order is the precedence
--   Where the arms' conditions can overlap, the first arm that holds decides. An enum orders by
--   declaration, so each type states the precedence as well as the members.
--
-- Why in `public`, dropped by name
--   These describe this repository's queries rather than a subject, for `compose_edge`'s reason,
--   and `DROP SCHEMA pm CASCADE` above does not reach them.
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

-- layers/remainder_scope.sqlc: how far anybody has established that a remainder's set of layers
-- is closed.
CREATE TYPE public.remainder_standing AS ENUM (
    'takes a spillover', 'nobody bounded the set', 'set bounded, pairs untested',
    'bounded and the pairs answered');

-- layers/exposure_scope.sqlc: where an exposure could have gone. Ignorance outranks room: a
-- buffer nobody sized decides before a buffer with room in it.
CREATE TYPE public.exposure_standing AS ENUM (
    'a buffer nobody sized', 'a buffer with room in it', 'every buffer sized and empty');

-- checks/fit_axes.sqlc: which fit a rule's population or verdict depends on. The filed sign and
-- the fit derived from demand and nameplate agree on a conforming document and are still two
-- columns, so a rule reads one of them, both, or neither.
CREATE TYPE public.fit_axis AS ENUM (
    'filed sign', 'derived fit', 'filed against derived', 'not read');

-- Where a declared cell stands, at two places. checks/fit_domain.sqlc takes one cell of a rule's
-- fit axis; epistemics/class_domain.sqlc takes one class of a classification. The three readings
-- are the same in both: something loaded reaches the cell; the population that would fill it
-- excludes it by construction, and the reason names why; or it can be reached and nothing loaded
-- has reached it, and the reason says what a document there would be. One type serves both,
-- because the question is the same, and a second list of the same three words would drift from
-- the first on its first edit.
CREATE TYPE public.fit_standing AS ENUM ('exercised', 'outside', 'open');

-- composition/part_references.sqlc: how a part files its conversion factor. The element omitted
-- (the units already agree, so the factor is one), a stated claim, a typed absence, or a
-- derivation naming the calculation that gives it. `pm.part`'s CHECKs let at most one of the
-- three columns be set, so no two arms can both hold, and the order is the grammar's, not a
-- precedence.
CREATE TYPE public.factor_state AS ENUM ('omitted', 'stated', 'absent', 'derivation');

-- layers/quantities.sqlc: the quantities a layer states in its own unit, each named after the
-- element that carries it. `pm.summed_quantity` names the three a fusion sums. The two sets share
-- `demand` and `nameplate` and are not the same set: a slack is never summed across parts, and
-- the `draw` a fusion sums is not one of these five. The names are all they have in common, so a
-- relation that matches them matches by name and casts to say so.
--
-- The three slack members are built as `pm.buffer || 'Slack'`, in that type's own order, so a
-- buffer this type does not name fails at the cast instead of arriving downstream as a sixth
-- quantity nobody declared.
CREATE TYPE public.layer_quantity AS ENUM (
    'demand', 'nameplate', 'inventorySlack', 'capacitySlack', 'timeSlack');

-- The XML as it arrived. It is the one table in `pm` that `assets/sql/ingest.sql` fills from
-- files, and every other table in `pm` but `buffer_term` is derived from it by ordinary SQL.
-- `public.compose_edge` above is also filled from a file, and stays outside `pm` for the reason
-- its own comment gives: it is a fact about this repository, not about a subject.
CREATE TABLE source (
    name text PRIMARY KEY,
    body xml  NOT NULL
);

CREATE TABLE filing (
    name text PRIMARY KEY REFERENCES source(name),
    -- The root element the document declares, read with `local-name()` rather than guessed from
    -- a prefix. Five values, not two: `assets/corpus/` holds documents rooted at `coverage`,
    -- `dependence` and `run`, which ingest does not load, and a two-valued CHECK with an
    -- `ELSE 'filing'` would file each of them as a plain filing without complaint. A set that
    -- closes where the XSD closes cannot drift from it in silence.
    kind text NOT NULL CHECK (kind IN ('processModulus', 'composition',
                                       'coverage', 'dependence', 'run')),

    -- What this document is evidence for, a second axis rather than a third `kind`. A fixture is
    -- still a filing or a composition; what differs is what it attests. One column for both would
    -- put two kinds of fact in one place, which `pm:Provenance` and `pm:Holder` both refuse.
    --
    -- The rules run on fixtures, which is what a fixture is for. The reports about the evidence
    -- do not: "no stack in the corpus files its couplings as `none`" is a fact about the
    -- evidence, and a stipulation counted beside it would make that finding false. See
    -- `assets/fixtures/README.md`.
    --
    -- The value is the document's own, filed in `pm:StatedEvidence`, not the directory the file
    -- sits in: `observation` (somebody looked at a real system) or `stipulation` (nothing here
    -- was observed).
    --
    -- A document may decline to say, with a typed reason in `evidence_absent`, and then
    -- `evidence` is NULL. Read as a `stipulation` it would be set aside on a guess; read as an
    -- `observation` it would be quoted on one. It belongs to neither scope.
    evidence text CHECK (evidence IN ('observation', 'stipulation')),
    evidence_absent absence_reason,

    -- Who asserts a composition, and on what standing. `asrt:Composition/provenance` and
    -- `asrt:Dependence/provenance` are required `pm:Provenance`s: the party that composed the
    -- filings, and the standing it composes them on, such as a parent undertaking consolidating
    -- its members. The same shape as `claim.prov_*`, one per document, and empty on a root that
    -- carries none.
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

-- A filing can report under more than one regime, so regimes are rows of their own, and
-- `refutation` does: the same Portuguese microentity is `NC-ME` to IES and `M` to SAF-T, the two
-- published code lists do not line up, and the pair says what neither declaration says alone. A
-- `jurisdiction` column on `filing` would force the sender to pick one and lose the
-- disagreement, which is that document's subject.
--
-- The framework is a borrowed term, so a column holding its value alone would store the
-- ambiguous half. `pm:Regime`'s annotation gives the reason, from Portugal: SAF-T PT publishes
-- `S`, `M`, `N` and `O`, IES AnexoASNC publishes `NIC`, `NCRF`, `NCRF-PE` and `NC-ME`, and the
-- lists do not line up, so `S` does not identify a framework and `NCRF-PE` is not a SAF-T value.
-- A code without its authority is ambiguous, not only unattributed. So the value is held with
-- its taxonomy, and `refutation`'s two regimes read as two authorities' codings of one entity.
--
-- `framework` and `chart` are each a `pm:StatedBorrowedTerm`, a term or a typed absence, so each
-- has an `_absent` column, and one NULL never stands for two facts. The corpus document
-- `unstated` files both arms: `r1` is `unmeasured`, because the entity's size tier is unassigned
-- and the framework it selects is not yet known, and `r2` is `none`, because it is an internal
-- management view answerable to no external framework.
--
-- `chart` is required by the XSD, and its annotation sets out why, including that a chart the
-- entity wrote itself names the entity as its own authority.
--
-- `jurisdiction` is a bare nullable token with no typed absence, because the XSD already says
-- what its absence means: a framework that is not a country's, as IFRS has no jurisdiction, and
-- forcing one would invent a fact. Asking a filer to restate that would be boilerplate with no
-- author. Nothing may key on it: "a receiver that joins on this field is using it for the one
-- purpose it was made too weak to serve".
CREATE TABLE regime (
    filing       text NOT NULL REFERENCES filing(name),
    seq          int  NOT NULL,
    -- Required and unique, as the XSD has it: `pm:Regime/id` has no `minOccurs`, so it is
    -- required, and `xs:key regimeId` in `process-modulus.xsd` keeps two regimes of one document
    -- from sharing it. Unkeyed here, two declarations sharing an id would fan out every join
    -- through the handle. A rule checked here is meant to speak about the model, not about the
    -- tables it was carried into.
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
    -- Two CHECKs per term: wholeness first, then the choice. One CHECK comparing a whole term
    -- with the absence would pass a taxonomy with no value beside an absence, half a term and a
    -- reason there is none at once, and two readers counting "states a framework" by different
    -- halves would disagree on it. Every `pm:StatedBorrowedTerm` in this file takes this shape.
    CONSTRAINT a_framework_term_is_whole
        CHECK (num_nonnulls(framework_taxonomy, framework_value) <> 1),
    CONSTRAINT a_framework_is_stated_or_typed_absent
        CHECK ((framework_value IS NOT NULL) <> (framework_absent IS NOT NULL)),
    CONSTRAINT a_chart_term_is_whole
        CHECK (num_nonnulls(chart_taxonomy, chart_value) <> 1),
    CONSTRAINT a_chart_is_stated_or_typed_absent
        CHECK ((chart_value IS NOT NULL) <> (chart_absent IS NOT NULL))
);

-- What a composer says about another document's regime, which is not what that document says
-- about itself. `asrt:composition` declares `asrt:regime` of type `pm:Regime`: the same shape as
-- `regime` above, and a different fact with a different author, so it is a second table and not
-- a column telling the two apart. `draw` and `induction` are kept apart for the same reason.
--
-- Each part then names which of these it comes under, and XSD 1.0 checks that the handle
-- resolves: `compositionRegimeId` is the key and `partRegime` the reference. A reference cannot
-- reach the other document, so whether the composer's claim agrees with the part filing's own
-- declaration is the question the grammar hands to a rule, `checks/part_regime_disagrees`.
CREATE TABLE composition_regime (
    composition  text NOT NULL REFERENCES filing(name),
    seq          int  NOT NULL,
    -- Required and unique, as the XSD has it: `pm:Regime/id` has no `minOccurs`, so it is
    -- required, and `xs:key compositionRegimeId` in `assertion.xsd` keeps two regimes of one
    -- composition from sharing it. Unkeyed here, two declarations sharing an id would fan out
    -- every part joined through the handle, and `checks/part_regime_disagrees` would report
    -- violations no document has. A rule checked here is meant to speak about the model, not
    -- about the tables it was carried into.
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
-- Layers. One wide row per layer, because these columns are attributes of one layer. `slack`
-- and `holder` below hold one row per buffer and one per holder instead.
-- ---------------------------------------------------------------------------

-- The key column is `layer`, not `name`. The tables about one layer key on `(filing, layer)`, so
-- naming it the same here makes `USING (filing, layer)` read the same in every join, in
-- `assets/sql/matrices.sql` and `assets/sql/rules.sql` among them. In a file whose job is to be
-- read, one uniform join is worth more than one natural-looking column.
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
    -- What would tighten the bounds, and who owns them, is not here. `narrowsWhen` and
    -- `boundOrigin` are required on every `Claim`, so the demand's live where every claim's do:
    -- one row each in `narrowing` and `bound_origin`, keyed on the claim. A copy here would be
    -- counted twice by the absence census.

    -- How long the demand waits unanswered before it leaves: `pm:Demand/patience`. It is the
    -- demand's half of the time axis, as `window` is the supply's. A duration, so `patience_unit`
    -- is a unit of time, such as `hours` or `shifts`, and not the layer's unit: a slack is quoted
    -- in the unit of the shares it bounds, and a patience bounds none. Where the layer's unit is
    -- itself time the two can agree in number, which is a fact about that layer and not a reason
    -- to fold these columns into `slack`.
    --
    -- Zero patience is filed as 0, 0 and 0, not as `patience_absent = 'none'`. Demand that leaves
    -- the moment it is not served has a patience of zero, and a measured zero is a claim:
    -- `pm:Demand/patience` is a `pm:StatedClaim`, whose absent arm carries
    -- `pm:ClaimAbsenceReason`, and that type has no `none`. So an ingested `'none'` here is a
    -- document that did not validate, and the two remaining reasons are what this column holds.
    patience_low    numeric,
    patience_mode   numeric,
    patience_high   numeric,
    patience_unit   text,
    patience_absent absence_reason,

    -- `StatedRemainder` is a choice, a remainder or a typed reason there is none, and every layer
    -- carries one, so a sender who disagrees with "every layer has a remainder" says so
    -- explicitly instead of leaving a field empty. `remainder_absent` holds the second arm.
    -- Without it, a layer that denies having a remainder would arrive as blanks in sign,
    -- absorber and quantity, the same as a document that said nothing.
    --
    -- The note is stored because a denial can be an argument. `refutation/object-storage` files
    -- its denial "as a counter-example to the claim that every layer carries a remainder, not as
    -- a gap in this document". A reason alone records a gap: it keeps the fact and loses the
    -- argument, and the argument is what that document is written to make.
    --
    -- A remainder of zero is filed as a clearance, not as `remainder_absent = 'none'`. "There is
    -- no remainder" reads two ways: nothing to subtract from, or a difference of zero. The second
    -- is a `clearance` fit, which `Fit` settles where the smallest clearance is zero, filed with
    -- a quantity of 0, 0 and 0 and a sign, and an absence would throw that sign away. So
    -- `pm:StatedRemainder`'s absent arm is a `pm:ClaimAbsence`, and the two remaining reasons are
    -- what this column holds. `unstated/margin-ratio` and `refutation/object-storage` deny having
    -- a remainder with `notApplicable`: neither states a nameplate, so there is nothing to
    -- subtract the demand from, and the question does not apply.
    remainder_absent      absence_reason,
    remainder_absent_note text,

    -- the remainder's two halves: which side it is on, and how big it is
    sign          fit,
    sign_absent   absence_reason,
    sign_derivation identity CHECK (sign_derivation = 'fit'),

    -- The absorber is a borrowed term, a taxonomy and a value, not the `buffer` enum.
    -- `merge-pt-member` cites a translated edition of Factory Physics,
    -- `urn:example:pt:fisica-da-fabrica:amortecedores`, and its absorber is `capacidade`. That
    -- filing is correct, and a column of type `buffer` would refuse it: a value set restated as an
    -- enum is a fork of the authority's list, and nothing here would notice the two drift apart.
    -- So the value travels with the authority that defines it, and comparing two filings that
    -- cite different authorities is a step somebody takes on purpose, through `buffer_term`.
    --
    -- It is also a `pm:StatedBorrowedTerm`, a term or a typed absence, so `absorber_absent` holds
    -- the other arm. A remainder may have been absorbed by nothing: a shop at capacity that turns
    -- people away with no waiting list chose none of the three buffers, and files `absent` with
    -- the reason `none`. Without that column the answer would arrive as two NULLs, the shape of a
    -- document that never said.
    absorber_taxonomy text,
    absorber_value    text,
    absorber_absent   absence_reason,
    qty_low       numeric,
    qty_mode      numeric,
    qty_high      numeric,
    qty_unit      text,
    qty_absent    absence_reason,
    qty_derivation identity CHECK (qty_derivation = 'magnitude'),

    -- `Demand/amount` is a `pm:StatedSummedQuantity`, whose absent arm is a `pm:ClaimAbsence`
    -- like `patience`'s, so it has no `none` either.
    CONSTRAINT a_demand_absence_has_no_none CHECK (demand_absent <> 'none'),
    CONSTRAINT a_patience_absence_has_no_none CHECK (patience_absent <> 'none'),
    -- `StatedRemainder` takes a `ClaimAbsence` for the reason above: an ingested `'none'` here
    -- is a document that did not validate.
    CONSTRAINT a_remainder_absence_has_no_none CHECK (remainder_absent <> 'none'),
    -- `StatedFit` takes a `ClaimAbsence` too. Overlapping ranges are a `transition` fit, which
    -- the value names, so `none` would be a second way of filing an answer the value gives.
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
    -- A three-point claim is whole or it is absent, and the non-nulls are counted first. A CHECK
    -- passes on NULL, so a plain comparison of the three would pass with `demand_mode` NULL and
    -- let half a claim file. Downstream that half claim is not a blank: `greatest(NULL, 0)`
    -- ignores the NULL and returns a zero exposure, and the fit CASE falls through to
    -- `transition`, a typed absence turned into a filed answer.
    --
    -- The unit is part of the claim. `Claim` requires low, mostLikely, high and unit together;
    -- the XSD gets that from its structure, and the tables have to say it. Every other
    -- three-point claim in this file carries a constraint of this shape, named the same way.
    CONSTRAINT a_demand_claim_is_whole_and_ordered
        CHECK (num_nonnulls(demand_low, demand_mode, demand_high) = 0
               OR (num_nonnulls(demand_low, demand_mode, demand_high, demand_unit) = 4
                   AND demand_low <= demand_mode AND demand_mode <= demand_high)),
    -- A layer files a remainder or says why it has none: never both, never neither. The denial
    -- is of the whole element, so when it is present the remainder's own three parts are empty.
    -- The XSD gets this from its structure, because sign, absorber and quantity live inside the
    -- element that was declined; the tables have to say it.
    CONSTRAINT a_layer_files_a_remainder_or_says_why_not
        CHECK ((remainder_absent IS NOT NULL) = (sign IS NULL AND sign_absent IS NULL
                                             AND sign_derivation IS NULL
                                             AND qty_low IS NULL AND qty_absent IS NULL
                                             AND qty_derivation IS NULL
                                             AND absorber_taxonomy IS NULL
                                             AND absorber_value IS NULL
                                             AND absorber_absent IS NULL)),
    -- Inside a filed remainder, the same stated-or-typed-absent rule as everywhere else, so a
    -- filed remainder cannot carry neither a sign nor a reason for having none.
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
    -- `pm:Facility/label`, required: what the filer calls this supply, which is sometimes the
    -- argument itself. `unstated/margin-ratio` labels its supply "a ratio, which is not a supply".
    facility_label text NOT NULL,

    amount_low     numeric,
    amount_mode    numeric,
    amount_high    numeric,
    amount_unit    text,
    amount_absent  absence_reason,
    amount_derivation identity CHECK (amount_derivation = 'fusionSum'),
    -- `Nameplate/amountOrigin` is a required `pm:StatedAmountOrigin`, an origin or a typed reason
    -- there is none. A column holding the origin alone would store one NULL for both `unmeasured`
    -- (nobody asked who committed it) and `notApplicable` (there is no amount to have committed).
    -- `amount_origin_absent` is the second arm, and it has no `none`.
    amount_origin  constraint_origin,
    amount_origin_absent absence_reason,

    -- Divisibility, first axis: amount. A lumpy supply carries a quantum; a continuous one has
    -- none, and that is a different thing from a quantum of zero.
    --
    -- `lumpy` is nullable because divisibility can be typed absent, in `divisibility_absent`, as
    -- `unstated/margin-ratio` files it: the supply is then neither lumpy nor continuous. A boolean
    -- has two states and this question has three. The three buffer slacks and the window below
    -- meet the same shape.
    lumpy          boolean,
    divisibility_absent absence_reason,
    quantum_low    numeric,
    quantum_mode   numeric,
    quantum_high   numeric,
    quantum_unit   text,
    -- `LumpyQuantum/size` is a `pm:StatedClaim`: a supply that comes in lumps of a size nobody
    -- measured files the size absent.
    quantum_absent absence_reason,
    quantum_origin constraint_origin,

    -- Divisibility, second axis: time. The machine that runs 02:00 to 05:00. A supply can be
    -- lumpy in amount and intermittent in time, which is why this is a second axis rather than a
    -- third value of the first.
    --
    -- The window has three answers, and a NULL alone would hold all three the same way:
    -- `notApplicable` on a unit with no period, `unmeasured` where the unit has a period and
    -- nobody measured the live part of it, and a size. `unmeasured` is the one that matters to the
    -- arithmetic: it is the state in which a time slack cannot be worked out from a clearance,
    -- because nobody knows whether the spare is spread evenly across the period.
    --
    -- A supply that runs all the time has a size, not an absence: one whole period in the
    -- period's own unit, `1 week` against a period of `week`, which reads without dividing
    -- anything. In `window_origin` it also has an author who could change it, so a line that
    -- cannot be stopped (`intrinsic`), a desk somebody promised round the clock (`contractual`)
    -- and a plant somebody staffed for three shifts (`policy`) stay three different levers.
    -- `assets/sql/layers/derivation_licensed.sql` is where that is read.
    window_low     numeric,
    window_mode    numeric,
    window_high    numeric,
    window_unit    text,
    -- The window is a `LumpyQuantum` too, so its size can be typed absent: a window nobody has
    -- sized, which is a different answer from no window at all.
    window_size_absent absence_reason,
    window_origin  constraint_origin,
    window_absent  absence_reason,

    -- what the supply actually served, which is neither what was asked nor what was committed
    draw_low       numeric,
    draw_mode      numeric,
    draw_high      numeric,
    draw_unit      text,
    draw_absent    absence_reason,
    draw_derivation identity CHECK (draw_derivation = 'fusionSum'),

    -- `pm:Jagged/measurementBasis`, required, a `pm:StatedBasis`: the draw was read against the
    -- nameplate (`contributed`), against a borrowed term (a taxonomy and a value), or neither,
    -- with a typed reason.
    measurement_basis_contributed text CHECK (measurement_basis_contributed IN ('nameplate')),
    measurement_basis_taxonomy    text,
    measurement_basis_value       text,
    measurement_basis_absent      absence_reason,

    CONSTRAINT a_amount_absence_has_no_none CHECK (amount_absent <> 'none'),
    CONSTRAINT a_draw_absence_has_no_none CHECK (draw_absent <> 'none'),
    -- `Nameplate/amount` and `Jagged/draw` are both required `pm:StatedSummedQuantity`s, and
    -- `Facility` requires `jagged` beside every nameplate, so a nameplate row states each one,
    -- names its derivation, or types why not. The whole-claim CHECKs below let one column speak
    -- for the range.
    CONSTRAINT an_amount_is_stated_or_typed_absent
        CHECK (num_nonnulls(amount_low, amount_absent, amount_derivation) = 1),
    CONSTRAINT an_amount_origin_is_stated_or_typed_absent
        CHECK ((amount_origin IS NOT NULL) <> (amount_origin_absent IS NOT NULL)),
    -- `pm:StatedAmountOrigin` takes a `ClaimAbsence`: a committed quantity has an author by
    -- definition, and where nature fixes the number, `intrinsic` is the member that says so.
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
    -- A window is a size or a typed reason there is none, never a blank and never both, here as
    -- in the XSD. `Divisibility/window` takes a `ClaimAbsence` for the reason above: an ingested
    -- `'none'` here is a document that did not validate.
    CONSTRAINT a_window_absence_has_no_none CHECK (window_absent <> 'none'),
    -- Exactly one of three answers: a quantum with a size, a quantum whose size is typed absent,
    -- or no window with a typed reason. All of it lives inside a stated divisibility.
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

-- Every three-point claim in a document, and the element that made it. `Claim` is reused all
-- over the schema: demands, nameplates, quanta, windows, draws, slacks, shares, factors,
-- coupling strengths and eliminated quantities are all claims. Each of those tables carries its
-- own copy of low, mostLikely, high and unit as columns of the thing it describes, which is the
-- right shape for asking about a demand. This table is the shape for asking about a claim.
--
-- Two rules read a claim's narrowing against its own width, `checks/narrows_a_point_value` and
-- `checks/range_says_no_range`. Written over `layer.demand_*`, they would reach only demands.
-- Over this table they reach every claim in every document, so a ranged eliminated quantity
-- filing `notApplicable`, with a note pasted from the single-value claim beside it, is examined
-- like any demand. That paste is the failure `checks/narrows_a_point_value` names.
--
-- `narrowing` and `bound_origin` share this table's key and each references it, and this table
-- references both in turn (below). So each claim has exactly one of each by key, and an ingest
-- that dropped or added one would fail the keys rather than pair every later row with the wrong
-- claim.
CREATE TABLE claim (
    filing text NOT NULL REFERENCES filing(name),
    seq    int  NOT NULL,          -- document order; the Nth pm:claim in the document
    -- The position the claim is the value of, as `parent/element`: `pm:nameplate/pm:amount`,
    -- `pm:holder/pm:share`, `pm:quantum/pm:size`. One name is not enough, because three element
    -- names are filed at two positions each: `pm:amount` is `Demand/amount` and
    -- `Nameplate/amount`, `pm:size` is the amount quantum's and the window's, and `pm:quantity`
    -- is a draw's and a remainder's. A filter on a name answers for a position nobody asked
    -- about. `units/with_a_period.sqlc` filters on this column: a window is a part of the
    -- nameplate's period, so a name would hand it the demand's too and return two rows per layer.
    -- `every-absence/delivery` is the layer that would disagree, quoting its demand `per day`
    -- with no nameplate amount at all, and it costs nothing only because that layer's window is
    -- `unmeasured`.
    owns   text NOT NULL,
    -- The layer this claim sits in, read with `ancestor::pm:layer/pm:name`. NULL is an answer,
    -- not a gap: a coupling strength, an eliminated quantity and a part's factor are claims about
    -- a relation between layers, and an operation's draw and commitment sit on the operation, so
    -- there is no enclosing layer to find. Without this column `pm.claim` could answer questions
    -- about claims and never join back to the layer relations, and a relation needing both would
    -- have to read `pm.nameplate` instead and reach only some of the claims quoted per period.
    layer  text,
    low    numeric NOT NULL,
    mode   numeric NOT NULL,
    high   numeric NOT NULL,
    unit   text    NOT NULL,

    -- What sits under the line, filed rather than inferred: `pm:StatedDenominator`. Inferred
    -- instead, `LIKE '% per %' OR LIKE '% por %'` over `unit` asks a reader to decide that
    -- `semana` is `week`, a judgement no filing makes, and cannot tell a period from a
    -- denominator that merely exists. `GPU-hour per GPU` has a denominator and it is not a
    -- period, so `denominator_kind` carries that difference rather than the query guessing at it.
    denominator      text,
    denominator_kind text CHECK (denominator_kind IN ('period', 'each')),
    denominator_absent absence_reason,

    -- Who asserts this claim, and on what standing: `pm:Provenance`. `standing` is what separates
    -- an auditor's assertion from a parent's, and the XSD calls it the only field that says which
    -- one is being read. Every question about who stands behind a number reads it.
    --
    -- Taxonomy plus value, like `layer.absorber_*` and for the same reason: a borrowed term
    -- travels with the list it was borrowed from. There is no `standing_term` table, because no
    -- reader has mapped two editions of one standing vocabulary; one would join here as
    -- `buffer_term` does.
    prov_party             text,
    prov_entered_by        text,
    prov_approved_by       text,
    prov_standing_taxonomy text,
    prov_standing_value    text,
    prov_standing_absent   absence_reason,
    prov_note              text,
    -- `Claim/asOf`, optional: the date the claim holds at.
    as_of                  date,

    PRIMARY KEY (filing, seq),
    CONSTRAINT a_claim_is_ordered
        CHECK (low <= mode AND mode <= high),
    -- All NULL is legal here and means no provenance element, which `Claim` allows. Within one,
    -- `standing` is required, so exactly one of its two arms is present. The guard is the whole
    -- element and not the two arms: guarded by the arms alone, as `<= 1`, a provenance naming its
    -- party and giving no standing would load as though it had no provenance at all, and the XSD
    -- refuses that document.
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

-- Every narrowing in a document, wherever it sits. `narrowsWhen` is on `Claim`, and claims are
-- on demands, nameplates, quanta, slacks, shares, factors and coupling strengths. One table is
-- what makes the question askable across a whole filing: how much of the uncertainty is
-- ignorance, and how much is the world moving? `kind` is what that question groups by.
CREATE TABLE narrowing (
    filing    text NOT NULL REFERENCES filing(name),
    seq       int  NOT NULL,
    condition text,
    kind      narrowing_kind,
    absent    absence_reason,
    -- `pm:NarrowingDerivation`: the claim is a calculation's result, so it narrows as that
    -- calculation's terms do.
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

-- Its pair, in the same shape and for the same reason. `narrowsWhen` says what would make a
-- range smaller; `boundOrigin` says who owns the edge it would move. Both sit on `Claim`, so both
-- are spread across demands, nameplates, quanta, slacks, shares, factors and coupling strengths,
-- and neither question can be asked of a document until the rows are in one place.
--
-- Many claims answer with a derivation, and a single column on one table could not say so. The
-- model already states the author of that edge in a sibling element (`Nameplate/amountOrigin`,
-- `LumpyQuantum/origin`), or the claim is a calculation's result and its edge is that
-- calculation's terms'.
CREATE TABLE bound_origin (
    filing text NOT NULL REFERENCES filing(name),
    seq    int  NOT NULL,
    origin constraint_origin,
    absent absence_reason,
    -- `pm:BoundDerivation`: the author is stated in a sibling origin, or the edge is the terms'
    -- of the calculation that computes the claim.
    derivation identity
        CHECK (derivation IN ('amountOrigin', 'quantumOrigin', 'fusionSum', 'magnitude',
                              'sharesSum', 'sharedParts', 'clearance', 'conversionPath')),
    PRIMARY KEY (filing, seq),
    FOREIGN KEY (filing, seq) REFERENCES claim(filing, seq),
    CONSTRAINT an_origin_is_stated_or_typed_absent
        CHECK (num_nonnulls(origin, absent, derivation) = 1)
);

-- The other direction, which `Claim` requires and the two keys above do not say. They make every
-- narrowing and every origin belong to a claim; `narrowsWhen` and `boundOrigin` are required, so
-- every claim also owes one row in each. Declared once both tables exist, and deferred to the end
-- of the loading transaction, because a claim is inserted before the two rows that complete it.
ALTER TABLE claim
    ADD CONSTRAINT a_claim_states_what_would_narrow_it_or_why_not
        FOREIGN KEY (filing, seq) REFERENCES narrowing(filing, seq) DEFERRABLE INITIALLY DEFERRED,
    ADD CONSTRAINT a_claim_states_who_owns_its_edge_or_why_not
        FOREIGN KEY (filing, seq) REFERENCES bound_origin(filing, seq) DEFERRABLE INITIALLY DEFERRED;

-- Every typed absence in a document, and the element that made it, as `claim` holds every value.
-- `pm:Absence` and `pm:ClaimAbsence` are the other arm of every `Stated*` wrapper, so an absence
-- is filed at as many positions as a claim, and each carries what a claim carries beside its
-- value: a note arguing for it, who declined and on what standing, and the date it holds at. The
-- notes are where a document argues.
--
-- The reason is held twice: here, and as a column on the table of the thing it is about, where
-- the stated-or-absent CHECKs need it. `algebra/absences_filed.sqlc` is the law that keeps that
-- from being a copy nobody checks: per filing and reason, it holds the census built from the
-- columns against the rows of this table. A branch the ingest drops, a column no census branch
-- reads, or a branch counting one absence twice each moves one side and not the other.
--
-- `owns` is `parent/wrapper`, the same spelling as `claim.owns`: the demand's claim and the
-- demand's absence are both `pm:demand/pm:amount`.
CREATE TABLE absence (
    filing text NOT NULL REFERENCES filing(name),
    seq    int  NOT NULL,          -- document order; the Nth absent element in the document
    owns   text NOT NULL,
    layer  text,                   -- the layer it sits in; NULL where no layer encloses it
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

-- Every derivation in a document, as `absence` holds every absence. `pm:Derivation` carries what
--   `pm:Absence` carries beside its reason: a note, a provenance and a date. Its identity is also
--   a column on the table of the thing it is about, where the three-way CHECKs need it, so it is
--   held twice, and `algebra/derivations_filed.sqlc` is the law that keeps the two from
--   drifting, as `algebra/absences_filed.sqlc` does for the reasons.
--
-- `owns` is `parent/wrapper`, the same spelling as `claim.owns` and `absence.owns`. A derivation
--   of a claim's edge or narrowing sits at `pm:claim/pm:boundOrigin` or
--   `pm:claim/pm:narrowsWhen`, which every claim shares, so `claim_owns` carries the claim's own
--   position: the identity computes that position, and without it the pairing cannot be read.
CREATE TABLE derivation (
    filing   text NOT NULL REFERENCES filing(name),
    seq      int  NOT NULL,        -- document order; the Nth derivation element in the document
    owns     text NOT NULL,
    claim_owns text,               -- the enclosing claim's `owns`; NULL for a figure's derivation
    layer    text,                 -- the layer it sits in; NULL where no layer encloses it
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
-- The tall tables. Each holds one row per entry that exists, and no row at all where there is
-- nothing.
--
-- That absence is not a technicality. That layers hold their remainders independently is this
-- model's assumption, so an empty `coupling` table is a document where nobody looked rather than
-- one where nothing was found: the typed-absence argument, arriving from the tables' side instead
-- of the schema's. `coupling_search` below is the row that says which.
-- ---------------------------------------------------------------------------

-- One row per buffer per layer: how much that buffer holds, in the layer's unit. Each is sized,
-- because knowing only that a buffer exists would let any holder's share fit inside it.
CREATE TABLE slack (
    filing       text NOT NULL,
    layer        text NOT NULL,
    buffer       buffer NOT NULL,
    low          numeric,
    mode         numeric,
    high         numeric,
    unit         text,
    absent       absence_reason,
    -- `pm:StatedTimeSlack`: only the time slack may be computed, by `clearance`, named. Capacity
    -- and inventory slack are measured facts about the supply, and no calculation gives either.
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

-- Who bears the remainder, and how much of it. A distribution rather than a selection: one
-- remainder often lands on several parties at once.
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
    -- `Holder/share` is a required `pm:StatedShare`: every named holder states its share, names
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
-- Operations, and the one place this model names a position in a process notation.
--
-- `pm:Operation/notationPosition` is the whole BPMN interface. `pm:ForeignId` is a notation plus
-- an id and nothing else, and the model carries it in an `asrt:Part`, in an
-- `asrt:Elimination/between`, at both ends of an `asrt:Dependence`, and here.
--
-- The notation is a language here and a document in a part, which is why this end gets no
-- foreign key. `part_filing` resolves through `filing_identity` because a part names another
-- filing; this names the OMG BPMN model URI, and the id names a node in whichever BPMN document
-- travels with the filing. No authority publishes that list, so there is nothing to resolve
-- against and nothing to key. `pm:ForeignId`'s annotation refuses the lookup: a receiver sent to
-- find `task_17` in a normative list finds nothing there and reads it as a defect in the list.
--
-- `notationPosition` is required and takes `pm:StatedForeignId`, the pair or a typed absence, so
-- the three things an omission would merge are three filed answers: `none`, the operation is in
-- no notation and somebody looked; `unmeasured`, a notation exists and nobody located this
-- operation in it; `notApplicable`, this filing has no notation to point into. An absence is the
-- expected answer for most operations; what is refused is the blank.
-- ---------------------------------------------------------------------------
CREATE TABLE operation (
    filing text NOT NULL REFERENCES filing(name),
    label  text NOT NULL,
    -- pm:Operation/pm:notationPosition. Both children are required inside `pm:ForeignId`, so the
    -- pair is whole or wholly absent, never half.
    foreign_notation text,
    foreign_id       text,
    foreign_absent   absence_reason,
    CONSTRAINT a_foreign_id_is_whole
        CHECK (num_nonnulls(foreign_notation, foreign_id) <> 1),
    -- `<>` and not `<= 1`, because the wrapper is required. `asrt:Part/factor` takes the weaker
    -- form because its wrapper is optional and an omitted factor means a factor of exactly one,
    -- so all NULL is a third legal state there. Here an omission means nothing, so exactly one
    -- arm is filled and a blank fails the load.
    CONSTRAINT a_notation_position_is_stated_or_typed_absent
        CHECK ((foreign_notation IS NOT NULL) <> (foreign_absent IS NOT NULL)),
    -- `operationLabel`: an operation is named once in its filing
    PRIMARY KEY (filing, label)
);

-- What an operation takes from a layer, now.
CREATE TABLE draw (
    filing    text NOT NULL,
    operation text NOT NULL,
    layer     text NOT NULL,
    low       numeric,
    mode      numeric,
    high      numeric,
    unit      text,
    absent    absence_reason,
    PRIMARY KEY (filing, operation, layer),   -- `operationDraw`: one draw per operation and layer
    FOREIGN KEY (filing, operation) REFERENCES operation(filing, label),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT a_draw_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high)),
    -- `Draw/quantity` is a required `pm:StatedClaim`, and its absent arm is a `ClaimAbsence`,
    -- which has no `none`: a draw of nothing is a claim of 0, 0 and 0.
    CONSTRAINT a_drawn_quantity_is_stated_or_typed_absent
        CHECK ((low IS NOT NULL) <> (absent IS NOT NULL)),
    CONSTRAINT a_drawn_quantity_absence_has_no_none CHECK (absent <> 'none')
);

-- A commitment made here that becomes a draw somewhere else, and who made it. A different table
-- from `draw` despite the same shape, because a commitment and a draw are different facts.
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
    -- `operationInduction`: one commitment per operation and layer
    PRIMARY KEY (filing, operation, layer),
    FOREIGN KEY (filing, operation) REFERENCES operation(filing, label),
    FOREIGN KEY (filing, layer) REFERENCES layer(filing, layer),
    CONSTRAINT a_induction_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high)),
    -- `Induction/commitment` is a required `pm:StatedClaim`, the same shape as `Draw/quantity`.
    CONSTRAINT a_commitment_is_stated_or_typed_absent
        CHECK ((low IS NOT NULL) <> (absent IS NOT NULL)),
    CONSTRAINT a_commitment_absence_has_no_none CHECK (absent <> 'none')
);

-- How much of the system is in this stack. There is one system; a filing holds the layers of it
-- that mattered to whoever filed, and without its scope `pm:Stack` would read as though it listed
-- all of them. A filing is never the system.
--
-- The third extent is the one a two-valued column would lose, and it is the distinction
-- `coupling_search` below turns on too: `scoped` says somebody established what lies outside and
-- excluded it; `unbounded` says nobody looked. Written the same way, a bounded selection could
-- not be told from an unexamined one.
--
-- It answers which filings claim a boundary, and which merely stopped. A second document holding
-- a layer this one does not is then two views of one system rather than evidence the first left
-- something out.
CREATE TABLE stack_scope (
    filing text PRIMARY KEY REFERENCES filing(name),
    extent text CHECK (extent IN ('complete', 'scoped', 'unbounded')),
    basis  text,
    absent absence_reason,
    CONSTRAINT a_scope_is_stated_or_typed_absent
        CHECK ((extent IS NOT NULL) <> (absent IS NOT NULL)),
    -- `pm:Scope` requires its `basis` beside its extent: how much of the system, and by what cut.
    CONSTRAINT a_scope_is_whole
        CHECK (num_nonnulls(extent, basis) <> 1)
);

-- Did anybody look for couplings? One row per filing, and it is the row that makes an empty
-- `coupling` table readable: the tall tables above hold no row where there is nothing, and this
-- says which kind of nothing it is.
--
-- The count it gives is about the evidence rather than any one filing: how many stacks file
-- couplings, how many say nobody looked (`unmeasured`), how many have no second layer to look at
-- (`notApplicable`), and how many say somebody looked and the layers moved independently
-- (`none`). The model's central assumption, that layers hold their remainders independently, is
-- tested only by the last, and `epistemics/coupling_searches.sqlc` prints each stack's answer.
CREATE TABLE coupling_search (
    filing text PRIMARY KEY REFERENCES filing(name),
    absent absence_reason,   -- NULL where the filing actually names couplings
    note   text
);

-- An observed dependence between two layers' remainders. Never derived, and it must carry the
-- observation that produced it.
CREATE TABLE coupling (
    filing      text NOT NULL,
    from_layer  text NOT NULL,
    to_layer    text NOT NULL,
    low         numeric,
    mode        numeric,
    high        numeric,
    unit        text,
    -- `pm:Coupling/strength` is a required `pm:StatedClaim`, so this column has two states: a
    -- stated strength, or a typed reason there is none, such as `unmeasured` for a dependence
    -- somebody observed and could not size.
    --
    -- `asrt:Part/factor` keeps an optional wrapper, and the difference is deliberate. An omitted
    -- factor means the part's unit and the composed layer's already agree, so the factor is one
    -- by what the document states, and there is no author to name. An omitted strength would rest
    -- on nothing. `checks/unit_crossing_without_a_factor` keeps the first true: omit the factor
    -- where the units differ and the rule fires.
    strength_absent absence_reason,
    observation text NOT NULL,   -- `Coupling/observed`, required: what was seen that couples them
    CONSTRAINT a_strength_absence_has_no_none CHECK (strength_absent <> 'none'),
    PRIMARY KEY (filing, from_layer, to_layer),   -- `couplingPair`: one coupling per pair
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
-- The reader's mapping, which is not data from any document.
--
-- To ask "does this holder's share fit inside the slack of the buffer its absorber names?", a
-- reader first decides that `capacidade` under a Portuguese edition means the same buffer as
-- `capacity` under an English one. No filing says that. It is a judgement a reader makes, and
-- this table is where a reader records it, so that the judgement is visible instead of buried in
-- a CASE expression.
--
-- It ships populated, and that is itself a claim a reader may disagree with. Delete the rows, and
-- the slack rules stop returning answers for the Portuguese filings rather than returning wrong
-- ones, which is the behaviour worth having.
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
-- What each filing calls itself, the second lookup a reader needs, held as data.
--
-- A composition names its parts by a `ForeignId`: a notation plus an id, such as
-- `urn:example:filing:us-member:2026-08-31` / `compute`. A part reference resolves only where a
-- document declares its own notation, and the conformance rule "a dependence end's filing
-- exists, and the layer named is in it" assumes that lookup: a foreign key needs something to
-- point at. Neither the XSD nor the Rust tests need it. XSD 1.0 cannot follow a reference across
-- documents, so it never has to resolve one, and the Rust tests load documents by filename and
-- keep their own table from notation to file.
--
-- The value is the document's, never the reader's. It is read out of
-- `pm:processModulus/pm:notation` by XMLTABLE like every other fact, and `asserted_by` records
-- which filing said it about itself.
--
-- It is also what makes a local part resolvable. A part whose notation equals its own
-- composition's is local: it names a layer that composition built. `part` below holds local and
-- foreign parts in one table, and the join tells them apart.
-- ---------------------------------------------------------------------------
--
-- One row per filing, the notation stated or typed absent. Keyed on the filing, a filing that
-- declines to name itself still has its row, with the reason in `absent`, and the notation stays
-- unique where it is stated.
CREATE TABLE filing_identity (
    filing   text PRIMARY KEY REFERENCES filing(name),
    notation text UNIQUE,
    asserted_by text NOT NULL,
    absent   absence_reason,   -- a filing that declines to name itself, and why
    CONSTRAINT a_filing_names_itself_or_says_why_not
        CHECK ((notation IS NOT NULL) <> (absent IS NOT NULL))
);

-- ---------------------------------------------------------------------------
-- Composition. A part is a reference to a layer and the factor that converts it at the same
-- time, so the two live in one table.
-- ---------------------------------------------------------------------------

-- A fusion: one composed layer, and what the composer saw that makes its parts one layer.
--   `asrt:Fusion` is keyed by name in its composition (`fusionTarget`), and its `observed` is
--   required. Parts, the search for double counting and the eliminations each belong to one.
CREATE TABLE fusion (
    composition    text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    observed       text NOT NULL,
    PRIMARY KEY (composition, composed_layer),
    CONSTRAINT a_fusion_composes_a_layer_of_the_composing_filing
        FOREIGN KEY (composition, composed_layer) REFERENCES layer(filing, layer)
);

-- One row per part: the layer it names, and the factor that converts it.
CREATE TABLE part (
    composition   text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    part_filing   text NOT NULL,
    part_layer    text NOT NULL,
    -- Which of the composition's own declared regimes this part comes under, a handle local to
    --   the document into `composition_regime`. XSD 1.0 checks that it resolves
    --   (`compositionRegimeId` the key, `partRegime` the reference), which is the most a grammar
    --   can do here, and it stops at the document's edge. Whether the composer's claim agrees with
    --   what the part's own filing declares crosses documents, and is a rule's job.
    --   Nullable, and NULL means the composer named no regime for this part. It gets no typed
    --   absence: `asrt:regime` is optional on a part, and a composition that declares no regimes
    --   has nothing for a handle to point at.
    part_regime   text,
    -- Four states, because the wrapper is optional and its choice has three arms.
    --   `asrt:Part/factor` is optional, so a part may (a) omit it, meaning the part is already in
    --   the composed unit and the factor is exactly one; (b) state a conversion; (c) file a typed
    --   absence, a conversion nobody measured; or (d) file a derivation, below. (a) and (c) are
    --   different documents, which is why (c) has a column of its own. `public.factor_state`
    --   names the four, and composition/part_references.sqlc assigns them.
    -- Reading (c) as a factor of one asserts a rate no composer filed. `asrt:Part` says an
    --   omitted factor means exactly one, never unknown, which is true of (a) only.
    factor_low    numeric,     -- all NULL, with no absence or derivation: the units already agree
    factor_mode   numeric,
    factor_high   numeric,
    factor_absent absence_reason,   -- (c): the typed reason nobody measured the conversion
    -- (d): the factor is a calculation's result, `pm:FactorDerivation`: worked back from the
    --      fusion's sum, or the conversions other filings state, multiplied along a path.
    factor_derivation identity CHECK (factor_derivation IN ('fusionSum', 'conversionPath')),
    CONSTRAINT a_factor_absence_has_no_none CHECK (factor_absent <> 'none'),
    PRIMARY KEY (composition, composed_layer, part_filing, part_layer),
    CONSTRAINT a_factor_is_strictly_positive
        CHECK (factor_low IS NULL OR factor_low > 0),
    -- No unit column here: the factor's unit, one unit per another, is filed on its claim
    --   (`pm.claim`, at `asrt:part/asrt:factor`), and this table holds the three numbers.
    CONSTRAINT a_factor_claim_is_whole_and_ordered
        CHECK (num_nonnulls(factor_low, factor_mode, factor_high) = 0
               OR (num_nonnulls(factor_low, factor_mode, factor_high) = 3
                   AND factor_low <= factor_mode AND factor_mode <= factor_high)),
    -- `<= 1`, not `<>`, and the difference is the third state. All NULL is legal and means no
    --   factor element. A required wrapper gets `<>`; an optional one gets this; and a required
    --   wrapper inside an optional element gets `<>` guarded by that element's presence, as
    --   `a_standing_is_stated_or_typed_absent` above does for no provenance element.
    CONSTRAINT a_factor_is_stated_or_typed_absent
        CHECK (num_nonnulls(factor_low, factor_absent, factor_derivation) <= 1),
    -- The same reference as `fusionName`, which every validator enforces. `assertion.xsd` says a
    --   fusion has a foreign end and a local one, since the composed layer is in this very
    --   document, and a fusion naming a layer the composer did not file is a schema error. This
    --   key states it here.
    -- The other end is unkeyed on purpose. `(part_filing, part_layer)` gets no foreign key and
    --   must not get one: `part_filing` is a notation resolved through `filing_identity`, whose own
    --   `absent` admits a filing that declines to name itself, and a part naming a filing the
    --   reader does not hold is ordinary. `checks/local_part_dangles.sqlc` carries that
    --   difference as a rule, which is where it belongs.
    CONSTRAINT a_composed_layer_is_a_layer_of_the_composing_filing
        FOREIGN KEY (composition, composed_layer) REFERENCES layer(filing, layer),

    -- The rest of `asrt:FiledLayer`, which the part's layer is. `party` is required and names who
    --   filed the layer; `registration` and `version` are optional. `elimination_between` holds
    --   the same type and carries the same columns.
    part_party                 text NOT NULL,
    part_registration_taxonomy text,
    part_registration_value    text,
    part_version               text,
    CONSTRAINT a_part_registration_is_whole
        CHECK (num_nonnulls(part_registration_taxonomy, part_registration_value) <> 1),
    CONSTRAINT a_part_belongs_to_a_fusion
        FOREIGN KEY (composition, composed_layer) REFERENCES fusion(composition, composed_layer),
    -- `partIdentity` keys a part's filed layer over the whole composition, not per fusion: one
    --   filed layer is a part of one fusion at most.
    CONSTRAINT a_filed_layer_is_a_part_once_in_a_composition
        UNIQUE (composition, part_filing, part_layer),
    -- `partRegime`: the handle resolves into the composer's own regime declarations.
    CONSTRAINT a_part_regime_resolves
        FOREIGN KEY (composition, part_regime) REFERENCES composition_regime(composition, id)
);

-- Did the composer look for double counting? The same shape as `coupling_search`, one document
-- up. Filed eliminations make the sum rule exact (`asrt:Elimination`), and that holds only for a
-- fusion that says whether anybody looked.
--
-- The answer decides which arithmetic is owed. `none` or `notApplicable`: the composed figure
-- equals the sum of its converted parts exactly. `unmeasured`: no equality is owed at all, and a
-- check that reports one is reporting about nothing.
CREATE TABLE elimination_search (
    composition    text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    absent         absence_reason,   -- NULL where the fusion actually files eliminations
    note           text,
    PRIMARY KEY (composition, composed_layer),
    -- The same reference as `fusionName`; see `part`.
    CONSTRAINT a_searched_layer_is_a_layer_of_the_composing_filing
        FOREIGN KEY (composition, composed_layer) REFERENCES layer(filing, layer),
    CONSTRAINT a_search_belongs_to_a_fusion
        FOREIGN KEY (composition, composed_layer) REFERENCES fusion(composition, composed_layer)
);

-- And every fusion says whether anybody looked. `Fusion/eliminations` is required, so a fusion
--   with no row above is a fusion whose search was dropped on the way in. Deferred, because the
--   fusion is loaded before its search.
ALTER TABLE fusion
    ADD CONSTRAINT a_fusion_says_whether_anybody_looked_for_double_counting
        FOREIGN KEY (composition, composed_layer)
        REFERENCES elimination_search(composition, composed_layer) DEFERRABLE INITIALLY DEFERRED;

-- What the composer counted twice across a fusion's parts: one row per quantity, each with the
-- prose that explains it.
CREATE TABLE elimination (
    composition    text NOT NULL REFERENCES filing(name),
    composed_layer text NOT NULL,
    quantity       summed_quantity NOT NULL,
    low            numeric,
    mode           numeric,
    high           numeric,
    unit           text,
    absent         absence_reason,
    -- `pm:EliminationDerivation`: the fusion's sum worked back for the eliminated quantity, or the
    -- double counting the structure implies. The two need not agree, so the filer names which.
    derivation     identity CHECK (derivation IN ('fusionSum', 'sharedParts')),
    reason         text,
    -- Which claim this quantity is, by document position, so an elimination reaches its own
    -- edge. `bound_origin` and `narrowing` are keyed on a claim's ordinal while this table is
    -- keyed on a fusion and a quantity, so without this column what a claim says about who set
    -- its bound would be ingested and unreachable from the figure it is about.
    -- The figures cannot recover it. Two eliminations of one filing may carry the same three
    -- points in the same unit, so a join on the values fans out rather than finding one row, and
    -- document order cannot do it either, because a filing's elimination claims do not sit at
    -- consecutive ordinals. It is read on the `preceding::` axis at ingest, over the whole
    -- document rather than one fusion's fragment.
    claim_seq      int,
    CONSTRAINT a_eliminated_quantity_absence_has_no_none CHECK (absent <> 'none'),
    CONSTRAINT an_eliminated_claim_is_placed_exactly_when_it_is_stated
        CHECK ((claim_seq IS NOT NULL) = (low IS NOT NULL)),
    CONSTRAINT an_eliminated_claim_is_a_claim_of_the_composing_filing
        FOREIGN KEY (composition, claim_seq) REFERENCES claim(filing, seq),
    -- `eliminationAgainst`: one elimination per quantity
    PRIMARY KEY (composition, composed_layer, quantity),
    CONSTRAINT a_eliminated_quantity_claim_is_whole_and_ordered
        CHECK (num_nonnulls(low, mode, high) = 0
               OR (num_nonnulls(low, mode, high, unit) = 4
                   AND low <= mode AND mode <= high)),
    -- `asrt:Elimination/quantity` is a required `pm:StatedEliminatedQuantity`.
    CONSTRAINT an_eliminated_quantity_is_stated_or_typed_absent
        CHECK (num_nonnulls(low, absent, derivation) = 1),
    -- The same reference as `fusionName`, which the grammar already enforces; see `part`.
    CONSTRAINT a_eliminated_layer_is_a_layer_of_the_composing_filing
        FOREIGN KEY (composition, composed_layer) REFERENCES layer(filing, layer),
    CONSTRAINT an_elimination_belongs_to_a_fusion
        FOREIGN KEY (composition, composed_layer) REFERENCES fusion(composition, composed_layer)
);

-- The layers a double count runs between, which is the evidence for an elimination. `between`
-- repeats on `asrt:Elimination`, `minOccurs="0" maxOccurs="unbounded"`. Without a home here these
-- rows would be lost on a round trip: load a composition, write the XML back out, and every
-- `between` would be gone. Nothing would notice, because a rule reads only what it needs; only
-- writing a document back out finds a gap like that. A document must be storable whole.
--
-- `notation` gets no foreign key, for the reason `part.part_filing` gets none: it is a reference
-- to another document and may point at nothing. `asrt:Elimination` refuses a keyref restricting
-- `between` to the fusion's own parts, because a group eliminating against a member that files
-- nothing, or against a layer folded into a different composed layer, is ordinary.
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

-- The standards a composition works under: `asrt:citation`, repeating on `asrt:Composition`.
CREATE TABLE composition_citation (
    composition text NOT NULL REFERENCES filing(name),
    seq         int  NOT NULL,
    -- `asrt:instrument` is a `pm:BorrowedTerm`: a taxonomy and a value, the shape `buffer_term`
    --   and `Regime/framework` use. Two columns, never one.
    taxonomy    text NOT NULL,
    instrument  text NOT NULL,
    clause      text,
    version     text,
    PRIMARY KEY (composition, seq)
);

COMMIT;
