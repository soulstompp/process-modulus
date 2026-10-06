-- diagrams/domain_objects.sqlc's governance claims against diagrams/roster.sqlc.
WITH diagrams_domain_objects AS (
-- the pm.* tables against BPMN 2.0's element vocabulary, as data an emitter reads.
SELECT * FROM (VALUES
  ('source', 'definitions', NULL, 'definitions', NULL, NULL, 'the document itself. A BPMN file is a definitions document'),
  ('filing', 'participant', NULL, 'pools', NULL, NULL, 'the participant that renders the document as a pool'),
  ('filing_identity', 'targetNamespace', NULL, 'namespaces', NULL, NULL, 'a notation resolved to a document, which is what import does'),
  ('layer', 'lane', NULL, 'lanes', NULL, NULL, 'a lane, and the region it delimits'),
  ('operation', 'task', NULL, 'tasks', 'demoted',
   'The pointer is on the page and no tool can follow it, which is the state `pm:ForeignId` '
   'intends. A notation plus an id names a node in the process notation the filer was reading, '
   'which is a different document from this one, so it must not become this task''s own `id` '
   '(that would claim the two documents are one) and it cannot be a `relationship`, whose '
   '`source` and `target` are QNames needing an `import` that needs a location nobody filed. It '
   'rides the task''s `documentation`: a person reads the id, a tool resolves nothing. Unlike '
   'every other `demoted` row here, the tool could not do better even in principle, because no '
   'authority publishes the list it would resolve against',
   'a flow node, reached by foreignId. `pm:Operation/foreignId` is the whole BPMN interface, '
   'and `entries/notation_references.sqlc` is the relation that holds it, one of the model''s '
   'three `pm:ForeignId` references'),
  ('draw', 'laneSet', NULL, 'in_a_lane', NULL, NULL,
   'the lane set a modeller actually files: the performer''s lane'),
  ('induction', 'group', NULL, 'induced_into', 'demoted',
   'The pointer. `tCategoryValue` adds one `xs:string` to a base element and no reference '
   'attribute, so the layer arrives as text beside a `lane` of the same name. That is a smaller '
   'form of the callActivity defect: a call loses the layer, this keeps its name and loses the '
   'tie. `decider` is lost too, and for the ordinary reason: it is a performer and nothing here '
   'files a claimant edge',
   'the cover. Emitted as categoryValueRef on each operation and drawn as a group, which adds '
   'no lane where a second laneSet would have added one per induced layer'),
  ('part', 'callActivity', NULL, 'calls', 'absent',
   'The factor. `calledElement` names a process, so it loses the target layer, and '
   '`diagrams/descents.sqlc` carries that fact at layer grain as a `relationship`, which takes '
   'QNames at both ends and a required `type`, read back and compared edge for edge. What no '
   'element carries is the factor, a three-point magnitude on a page with no unit, and that is '
   '`absent` for the reason every magnitude here is. One table maps to two elements, '
   '`callActivity` for the substitution and `relationship` for the grain, and this roster has '
   'one `element` and one `governed_by` per table',
   'foreign; a nested lane, a `childLaneSet`, when the part is local'),
  ('composition_citation', 'documentation', NULL, 'citations', 'demoted',
   'The structure. `pm.composition_citation` is `(taxonomy, instrument, clause, version)`, four '
   'typed fields, not free prose. A `documentation` element carries all four as one string, so a '
   'reader can follow the citation and a tool cannot resolve it',
   'the instrument a composition is filed under. The open question is the schema''s and not '
   'the diagram''s: `(composition, seq)` is a bare document ordinal where both sibling children '
   'carry a regime handle'),

  ('coupling', 'association', NULL, 'dependences', 'absent',
   'The observation and the strength, which is all the evidence there is. `pm:observed` is '
   'required prose and it is the whole argument; an `association` carries none, and an '
   'observation may contain a numeral, so routing it through `documentation` would put a '
   'magnitude on a page with no unit, which is `dataObject`''s refusal arriving through prose. '
   'The artifact says two layers are coupled and cannot say what was seen',
   'the observation that can show the model wrong. `sourceRef` and `targetRef` are '
   'unconstrained QNames, so two lanes are a legal pair, and the reason that rules out '
   '`messageFlow` does not apply here'),
  ('coupling_search', 'documentation', NULL, 'documentation', NULL, NULL,
   'the other half of the pair, on the laneSet, because the laneSet is the division the search '
   'is about. A filing that states no coupling draws no line, and a reader takes a silent '
   'diagram for independence. An absent line is not independence'),
  ('elimination_search',   NULL, 'notApplicable', NULL, NULL, NULL, 'the same, for double counting'),
  ('stack_scope', 'documentation', NULL, 'scopes', 'demoted',
   'The structure. `tLaneSet` has no extent attribute of any kind, so all three states render '
   'as one lane set and the answer survives only as untyped text. BPMN is the finer of the two '
   'on the basis and has nothing at all on the extent: `tLane` carries `partitionElement` and '
   '`partitionElementRef` for what the lanes are divided by, per lane, where this model files one '
   'basis per stack. The grain axis, running the other way',
   'how much of the system the stack holds. A lane set says nothing about it, so one sentence '
   'saying the same of every document would invent a claim the filings do not all make; the '
   'emitter reads the extent each filing states instead'),
  ('elimination',          NULL, 'notApplicable', NULL, NULL, NULL, 'a call references and never redeclares, so BPMN cannot double declare and owes no correction'),
  ('elimination_between', 'relationship', NULL, 'attributions', 'absent',
   'The size of the overlap, which is `pm.elimination`''s business and not this table''s, and '
   'the references that do not resolve: a QName needs a prefix and a prefix needs an import, so '
   'a `between` naming a document nobody filed cannot be pointed at',
   'a composed layer, and a layer of another document the double counting runs against. It is '
   '`asrt:FiledLayer`, whose filing is a `pm:ForeignId`, the same reference type a part uses, and '
   'the schema files it so that it can be queried rather than told as a story. `between` is the '
   'one cross-document reference no rule may check, because the schema allows one that names a '
   'filing nobody filed'),

  ('nameplate',            NULL, 'none', NULL, NULL, NULL,          'a committed, quantized magnitude. BPMN carries no quantity anywhere'),
  ('slack',                NULL, 'none', NULL, NULL, NULL,          'three buffers per layer, each a magnitude'),
  ('claim',                NULL, 'none', NULL, NULL, NULL,          'a value at a position, with its own width'),
  ('narrowing',            NULL, 'none', NULL, NULL, NULL,          'what would narrow a claim. BPMN has no epistemics'),
  ('bound_origin',         NULL, 'none', NULL, NULL, NULL,          'where a bound came from. The same'),
  ('absence',              NULL, 'none', NULL, NULL, NULL,          'a typed reason there is no value, with the note that argues for it. The same'),
  ('derivation',           NULL, 'none', NULL, NULL, NULL,          'the identity a value is computed by, with the note beside it. BPMN computes nothing it carries'),
  ('fusion',               NULL, 'none', NULL, NULL, NULL,          'what the composer observed that makes its parts one layer. The parts are drawn, as `part` says; the observation is prose no element here carries, for the reason `coupling` gives'),
  ('regime',               NULL, 'none', NULL, NULL, NULL,          'the jurisdiction and framework a document reports under'),
  ('composition_regime',   NULL, 'none', NULL, NULL, NULL,          'what a composer says another document''s regime is: a second claim with a second author, and no more drawable than the first'),
  ('buffer_term',          NULL, 'none', NULL, NULL, NULL,          'a taxonomy lookup a reader can delete'),

  ('holder',               NULL, 'misreads', NULL, NULL, NULL,      'resourceRole and performer have the right shape and the wrong claim: they say who acts, and a holder is who bears. Four of the five kinds name no party at all')
) AS d(object, element, absent, governed_by, loses_kind, loses, why)
),
diagrams_roster AS (
-- the counts a BPMN emission owes, against the relation supplying each expected count.
SELECT * FROM (VALUES
  ('pools',   'one participant per filing',    'epistemics/documents',     'participant',
              'a document rendered as two pools, or two rendered as one'),
  ('lanes',   'one lane per layer',            'layers/every_layer',       'lane',
              'layers drawn as overlapping, which draws what only a coupling may show'),
  ('tasks',   'one task per operation',        'entries/operations',       'task',
              'an operation dropped, or a flow node invented to make the picture read'),
  ('calls',   'one callActivity per part crossing a document', 'diagrams/foreign_calls',
              'callActivity',
              'A law of its own keeps a local part from being drawn as an activity: a local fusion '
              'divides the composed layer among its parts, and is not a node inside it. Only these '
              'parts go through `calledElement`, so this is the population exposed to a loop the '
              'flattening invents'),
  ('nestings', 'one childLaneSet per layer with a local part', 'diagrams/nestings', 'childLaneSet',
              'A fusion''s parts divide what they compose among them, and `Lane/childLaneSet` '
              'draws that division inside the lane. A nested lane is still keyed '
              '`(filing, layer)`, so unlike a call it collapses nothing and can invent nothing'),
  ('categories', 'one category per filing with an induction', 'diagrams/categories', 'category',
              'a classification scheme emitted into a document that has nothing to classify, or a document with inductions and no scheme to hang them on'),
  ('category_values', 'one categoryValue per layer induced into', 'diagrams/categories',
              'categoryValue',
              'The inductions given a notation. A second `laneSet` would give every layer two '
              '`lane` elements; BPMN''s other mechanism adds no lane at all: '
              '`tFlowElement/categoryValueRef` is `maxOccurs="unbounded"`, so the member declares '
              'the cover and no container grows'),
  ('groups',     'one group per categoryValue',  'diagrams/categories', 'group',
              'The glyph against the fact. `group` is to `categoryValueRef` what `lane` is to '
              '`flowNodeRef`: the drawn shape of a membership held elsewhere. A categoryValue with '
              'no group is a classification nobody drew; a group with no categoryValue is a dashed '
              'box that means nothing'),
  ('induced_into', 'one categoryValueRef per induction', 'diagrams/category_members',
              'categoryValueRef',
              'An induction dropped, which the lane count cannot see. An operation that draws '
              'from one layer and induces into another sits in one lane, so holding it in the '
              'draw alone leaves the induction out of every emitted document while the layer '
              'count still agrees'),
  ('diagrams', 'one BPMNDiagram per filing', 'diagrams/pools', 'BPMNDiagram',
              'The SVG''s proper place in the document. `bpmndi:BPMNDiagram` is in `tDefinitions`''s own sequence, and a document without one leaves the SVG stage to invent its coordinates while any tool that opens the file lays it out differently: two pictures of one model with nothing tying them'),
  ('planes', 'one BPMNPlane per filing', 'diagrams/pools', 'BPMNPlane',
              'one surface per document, naming the collaboration it is a picture of. A second plane would be a second picture of one model with no way to say which is meant'),
  ('shapes', 'one BPMNShape per element that owes a box', 'diagrams/shapes', 'BPMNShape',
              'The primitives are not all of it: a `group` and a `textAnnotation` owe a box too. '
              '`diagrams/shapes.sqlc` carries no coordinate for anything, so a row there says '
              'which elements owe a box and never where it is, and working the box out belongs '
              'to the emitter. An element drawn from geometry the document does not declare is '
              'an element every other reader of the file loses, without an error'),
  ('edges', 'one BPMNEdge per association', 'diagrams/shapes', 'BPMNEdge',
              'The one route in the notation, and it needs a different carrier from every box '
              'here: `bpmndi:BPMNEdge` with `di:waypoint`s, in a third namespace. Counting it with '
              'the shapes would make the shape count a number that matches nothing in the '
              'document, which is why `diagrams/shapes.sqlc` declares `di` per row'),
  ('legends', 'one textAnnotation per note a document owes on its face', 'diagrams/legends',
              'textAnnotation',
              'A fact present and invisible, which is what this law catches. `documentation` is '
              'admitted on any base element and drawn in no rendering, so a scope, a coupling '
              'search, a dependence''s meaning and a cover''s meaning can all be in the artifact '
              'and on no page. `textAnnotation` is the only element in BPMN that puts words on '
              'the canvas'),
  ('attributions', 'one relationship of type elimination-between per between that resolves',
              'eliminations/resolved', 'relationship',
              'The second `pm:ForeignId`, and the element''s type earning its keep. `association` '
              'cannot carry the composition: it has no type, and a second use would make two facts '
              'indistinguishable; `tRelationship/@type` is required, so a second relation costs a '
              'different string and the laws filter on it. The population is the resolved '
              'references and not all of them: a QName needs a prefix and a prefix needs an '
              'import, so a `between` naming a document nobody filed cannot be pointed at, and '
              'the schema calls that filing ordinary'),
  ('descents', 'one relationship per part crossing a document', 'diagrams/descents',
              'relationship',
              '`calledElement` names a process, so the edges between layers collapse to pairs of '
              'documents and the layer survives only inside `@name`; this carries the same fact at '
              'layer grain. The count is the weak half: as many relationships joining the wrong '
              'pairs pass it, which is why examples/diagramming/main.rs reads the endpoints back '
              'and compares them edge for edge with the parts'),
  ('citations', 'one rendered citation per filed citation', 'diagrams/citations', 'documentation',
              'A table declared as mapping and rendered nowhere, which no count of elements can see. Element kinds are not one to one: the pools and the lanes spend `documentation` too, so a count of that element is exact while this table''s share of it is zero, and `diagrams/ungoverned.sqlc` is the law that checks attribution instead'),
  ('scopes', 'one stated scope per filing', 'diagrams/scopes', 'documentation',
              'The `invents` state, caught in the emitter''s own prose. A sentence about a filing, hardcoded in the emitter, says one thing about every document where the filings differ, and `diagrams/scopes.sqlc` is what each one claims. That is not something a reader infers: the artifact says it. A count is not the law that matters here, the attribution one below it is: this only checks that a scope reached every document, and a wrong scope in every document would pass it'),
  ('dependences', 'one association per coupling', 'diagrams/dependences', 'association',
              'The observation that can show the model wrong, drawn. `pm:Coupling` exists so the '
              'model can be shown wrong in its own format, and the reason that rules out '
              '`messageFlow` says nothing about `association`, whose `sourceRef` and `targetRef` '
              'are unconstrained QNames. The law is worth as much for what it cannot check: an '
              'association carries no magnitude and no observation, so the count agrees while '
              'the evidence and the strength are both gone'),
  ('namespaces', 'one targetNamespace per notation', 'composition/notations', 'targetNamespace',
              'a document that does not declare the uri it is, so nothing can reference it'),
  ('imports', 'one import per document a composition reaches by a part or an elimination',
              'diagrams/cross_document', 'import',
              'a reference invented by the emitter, or a document reached without being imported'),
  ('in_a_lane', 'one flowNodeRef per draw and per part crossing a document',
              'diagrams/lane_membership', 'flowNodeRef',
              'an orphan flow node: emitted, counted, and in no lane, so the membership that put '
              'it there is gone from the rendering while every count still agrees'),
  ('definitions',   'one definitions per filing',   'diagrams/pools', 'definitions',
              'a filing emitted twice, or one skipped, which no leaf count would show'),
  ('collaboration', 'one collaboration per filing', 'diagrams/pools', 'collaboration',
              'one filing split across two collaborations, so its pool has no single home'),
  ('process',       'one process per filing',       'diagrams/pools', 'process',
              'one filing split into two processes, which divides its layers into two stacks'),
  ('lane_set',      'one laneSet per filing',       'diagrams/pools', 'laneSet',
              'The one that governs the elimination: a second lane set is how the draws and the '
              'inductions would both be drawn as lanes, and every layer then has two lane elements '
              'with nothing but a matching name to say they are one layer'),
  ('documentation', 'one documentation per sentence a relation states', 'diagrams/annotated',
              'documentation',
              'Documentation is not a container, which is what separates this row from the '
              'container rows above: they frame a document and appear once, while this is an '
              'annotation and may sit on any base element. A count alone is not enough here, '
              'which is what `states` is for: a document can carry the right number of sentences '
              'and each say something no relation states. examples/diagramming/main.rs reads '
              'every one back and asks what states it')
) AS l(slug, law, model_side, element, catches)
)
SELECT d.object, d.element, d.governed_by, d.loses,
       (d.governed_by IS NOT NULL AND l.slug IS NULL)          AS names_a_law_that_is_not_there,
       (d.governed_by IS NULL AND d.loses IS NULL)             AS ungoverned_and_unexplained
FROM      (
    SELECT * FROM diagrams_domain_objects
) d
LEFT JOIN (
    SELECT * FROM diagrams_roster
) l ON l.slug = d.governed_by
WHERE d.element IS NOT NULL
