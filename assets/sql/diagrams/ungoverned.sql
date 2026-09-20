-- diagrams/domain_objects.sqlc's governance claims against diagrams/roster.sqlc.
WITH
domain_objects AS NOT MATERIALIZED (
    -- the pm.* tables against BPMN 2.0's element vocabulary, as data an emitter reads.
SELECT * FROM (VALUES
  ('source', 'definitions', NULL, 'definitions', NULL, NULL, 'the document itself. A BPMN file is a definitions document'),
  ('filing', 'participant', NULL, 'pools', NULL, NULL, 'the participant that renders the document as a pool'),
  ('filing_identity', 'targetNamespace', NULL, 'namespaces', NULL, NULL, 'a notation resolved to a document, which is what import does'),
  ('layer', 'lane', NULL, 'lanes', NULL, NULL, 'a lane, and the region it delimits'),
  ('operation', 'task', NULL, 'tasks', 'demoted', 'The pointer is on the page and no tool can follow it, which is the state `pm:ForeignId` intends. A notation plus an id names a node in the process notation the filer was reading, which is a different document from this one, so it must not become this task''s own `id` (that would claim the two documents are one) and it cannot be a `relationship`, whose `source` and `target` are QNames needing an `import` that needs a location nobody filed. It rides the task''s `documentation`: a person reads the id, a tool resolves nothing. Unlike every other `demoted` row here, the tool could not do better even in principle, because no authority publishes the list it would resolve against', 'a flow node, reached by foreignId. And the column did not exist, so this row read `loses` nothing while losing the only thing it is about. `pm:Operation/foreignId` is the whole BPMN interface, the ingest read the label alone, and the crossing was filed by the corpus, discarded on every load and absent from every artifact. Third of the model''s three `pm:ForeignId` references and the last without a relation beside it: `entries/notation_references.sqlc`'),
  ('draw', 'laneSet', NULL, 'in_a_lane', NULL, NULL, 'D. The lane set a modeller actually files: the performer''s lane'),
  ('induction', 'group', NULL, 'induced_into', 'demoted', 'The pointer, and nothing else now. `tCategoryValue` adds one `xs:string` to a base element and no reference attribute, so the layer arrives as text beside a `lane` of the same name. That is the callActivity defect at one tenth the size: a call loses the layer, this keeps its name and loses the tie. `decider` is lost too, and for the ordinary reason: it is a performer and nothing here files a claimant edge', 'N, the cover. Emitted as categoryValueRef on each operation and drawn as a group, which adds no lane where a second laneSet would have added one per induced layer'),
  ('part', 'callActivity', NULL, 'calls', 'absent', 'What is left is the factor. With `calledElement` as the only reference the target layer went too: it names a process, so 17 layer-grain edges collapsed to 5 document pairs. `tRelationship` takes QNames at both ends and a required `type`, so `diagrams/descents.sqlc` now carries the same fact at the grain F has, read back and compared edge for edge. What no element carries is the factor, a three-point magnitude on a page with no unit, and that is `absent` for the reason every magnitude here is. And this row is at the wrong grain to say so: one table maps to two elements now, `callActivity` for the substitution and `relationship` for the grain, and the roster has one `element` and one `governed_by`', 'foreign; an embedded subProcess when the part is local'),
  ('composition_citation', 'documentation', NULL, 'citations', 'demoted', 'The structure, and not everything. The table settles it: `pm.composition_citation` is `(taxonomy, instrument, clause, version)`, four typed fields, not free prose. A `documentation` element carries all four as one string, so a reader can follow the citation and a tool cannot resolve it. Narrower than *everything* and worth being exact about, because the two states owe different repairs', 'the instrument a composition is filed under. The open question is the schema''s and not the diagram''s: `(composition, seq)` is a bare document ordinal where both sibling children carry a regime handle'),

  ('coupling', 'association', NULL, 'dependences', 'absent', 'The observation and the strength, which is all the evidence there is. `pm:observed` is required prose and it is the whole argument; an `association` carries none, and two of the five observations here contain a numeral, so routing them through `documentation` would put a magnitude on a page with no unit, which is `dataObject`''s refusal arriving through prose. The artifact says two layers are coupled and cannot say what was seen', 'C, the model''s own falsifier. `sourceRef` and `targetRef` are unconstrained QNames, so two lanes are a legal pair; withheld for years on a reason that ruled out `messageFlow` and was never asked of this'),
  ('coupling_search', 'documentation', NULL, 'documentation', NULL, NULL, 'the other half of the pair, on the laneSet, because the laneSet is the partition the search is about. 12 of 15 filings state no coupling, so a diagram drawing only the matrix is silent about them in a way a reader resolves as independence. An absent line is not independence'),
  ('elimination_search',   NULL, 'notApplicable', NULL, NULL, NULL, 'the same, for double counting'),
  ('stack_scope', 'documentation', NULL, 'scopes', 'demoted', 'The structure. `tLaneSet` has no extent attribute of any kind, so all three states render as one lane set and the answer survives only as untyped text. BPMN is the finer of the two on the basis and has nothing at all on the extent: `tLane` carries `partitionElement` and `partitionElementRef` for what a partition is by, per lane, where this model files one basis per stack. The grain axis, running backwards for once', 'This row said `notApplicable` while its own reason said *a lane set is implicitly complete*, and a tuple that contradicts itself is the sharpest finding shape there is. Both cannot hold: if the answer is implicitly complete then the question arose and the artifact answered it. It did, literally, in a hardcoded sentence in 15 of 15 documents where 1 filing claims complete. That is `invents` and not an absence, and the repair was to read the extent instead of asserting it'),
  ('elimination',          NULL, 'notApplicable', NULL, NULL, NULL, 'a call references and never redeclares, so BPMN cannot double declare and owes no correction'),
  ('elimination_between', 'relationship', NULL, 'attributions', 'absent', 'The size of the overlap, which is `pm.elimination`''s business and not this table''s, and the references that do not resolve: a QName needs a prefix and a prefix needs an import, so a `between` naming a document nobody filed cannot be pointed at. 8 of 8 resolve here, so that arm is unexercised by luck', 'Filed `notApplicable` on a reason that was never about it: *presupposes the overlap BPMN cannot express*. That is about the magnitude, and this table has none. It is `asrt:FiledLayer`, whose filing is a `pm:ForeignId`, the same reference type a part uses, and the schema says it exists *so the attribution is queryable rather than narrated*. The reason it stayed invisible is structural: this tree grows by rules, and `between` is the one cross-document reference no rule may check, because the schema licenses an unresolvable one outright'),

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
roster AS NOT MATERIALIZED (
    -- the cardinality identities a BPMN emission owes, against the relation supplying each expected count.
SELECT * FROM (VALUES
  ('pools',   '|participant| = |filing|',      'epistemics/documents',     'participant',
              'a document rendered as two pools, or two rendered as one'),
  ('lanes',   '|lane| = |layer|',              'layers/every_layer',       'lane',
              'a partition rendered as an overlap: the falsifier, drawn'),
  ('tasks',   '|task| = |operation|',          'entries/operations',       'task',
              'an operation dropped, or a flow node invented to make the picture read'),
  ('calls',   '|callActivity| = |part crossing a document|', 'diagrams/foreign_calls', 'callActivity',
              'One law over two elements would let a local part be rendered as an activity. A local fusion is a partition of the composed layer, not a node inside it. Splitting the law is also what makes the flattening measurable: only these parts go through `calledElement`, so this is the population exposed to the invented-cycle defect'),
  ('nestings', '|childLaneSet| = |layer with a local part|', 'diagrams/nestings', 'childLaneSet',
              'The recursion equivalence, and BPMN already had the element. A fusion''s parts partition what they compose, and `Lane/childLaneSet` is a sub-partition. A nested lane is still keyed `(filing, layer)`, so unlike a call it collapses nothing and can invent nothing'),
  ('categories', '|category| = |filing with an induction|', 'diagrams/categories', 'category',
              'a classification scheme emitted into a document that has nothing to classify, or a document with inductions and no scheme to hang them on'),
  ('category_values', '|categoryValue| = |layer induced into|', 'diagrams/categories', 'categoryValue',
              'N getting a notation. The route that does not work is a second `laneSet`, which gives every layer two `lane` elements. BPMN''s other mechanism adds no lane at all: `tFlowElement/categoryValueRef` is `maxOccurs="unbounded"`, so the member declares the cover and no container grows'),
  ('groups',     '|group| = |categoryValue|',    'diagrams/categories', 'group',
              'The glyph against the fact, and the pair is the answer to what a group is. `group` is to `categoryValueRef` what `lane` is to `flowNodeRef`: the drawn shape of an incidence held elsewhere. A categoryValue with no group is a classification nobody drew; a group with no categoryValue is a dashed box that means nothing'),
  ('induced_into', '|categoryValueRef| = |induction|', 'diagrams/category_members', 'categoryValueRef',
              'An induction dropped, which `|lane| = |layer|` cannot see. One operation here draws from `labour` and induces into `capability`; a lane set holds it in one place, so holding it in the draw alone leaves the second incidence out of every emitted document while the layer count still agrees'),
  ('diagrams', '|BPMNDiagram| = |filing|', 'diagrams/pools', 'BPMNDiagram',
              'The SVG''s proper place in the document. `bpmndi:BPMNDiagram` is in `tDefinitions`''s own sequence, and a document without one leaves the SVG stage to invent its coordinates while any tool that opens the file lays it out differently: two pictures of one model with nothing tying them'),
  ('planes', '|BPMNPlane| = |filing|', 'diagrams/pools', 'BPMNPlane',
              'one surface per document, naming the collaboration it is a picture of. A second plane would be a second picture of one model with no way to say which is meant'),
  ('shapes', '|BPMNShape| = every element that owes a box', 'diagrams/shapes', 'BPMNShape',
              'The primitives are not all of it, and the tempting answer is that a `group`, an `association` and a `textAnnotation` are derived from these boxes, so filing a derived coordinate files a value that can disagree with whatever computes it. That argument holds and it is about the wrong column: `diagrams/shapes.sqlc` carries no coordinate for anything, so a row there says which elements owe a box and never where it is, and the derivation belongs in the emitter. An element drawn from geometry the document does not declare is an element every other reader of the file loses, without an error'),
  ('edges', '|BPMNEdge| = |association|', 'diagrams/shapes', 'BPMNEdge',
              'The one route in the notation, and it needs a different carrier from every box here: `bpmndi:BPMNEdge` with `di:waypoint`s, in a third namespace. Counting it with the shapes would make `|BPMNShape|` a number that matches nothing in the document, which is why `diagrams/shapes.sqlc` declares `di` per row'),
  ('legends', '|textAnnotation| = |note a document owes on its face|', 'diagrams/legends', 'textAnnotation',
              'A fact present and invisible, which is what this law catches. `documentation` is admitted on any base element and drawn in no rendering, so a scope, a coupling search, a dependence''s meaning and a cover''s meaning can all be in the artifact and on no page. `textAnnotation` is the only element in BPMN that puts words on the canvas, and *documentation is spent instead* is true and about the wrong property'),
  ('attributions', '|relationship type=elimination-between| = |between that resolves|', 'eliminations/resolved', 'relationship',
              'The second `pm:ForeignId`, and the element''s type earning its keep. `association` was refused for F because it has no type and a second use makes two facts indistinguishable; `tRelationship/@type` is required, so a second relation costs a different string and the laws filter on it. The population is the resolved references and not all of them: a QName needs a prefix and a prefix needs an import, so a `between` naming a document nobody filed cannot be pointed at, and the schema calls that filing ordinary'),
  ('descents', '|relationship| = |part crossing a document|', 'diagrams/descents', 'relationship',
              'The mapping''s widest demotion, promoted. `calledElement` names a process, so 17 layer-grain edges collapsed to 5 document pairs and the layer survived only inside `@name`. The count is the weak half: 17 relationships joining the wrong 17 pairs passes it, which is why the isomorphism law in examples/diagramming/main.rs reads the endpoints back and compares the edge set to F'),
  ('citations', '|citation rendered| = |citation filed|', 'diagrams/citations', 'documentation',
              'A table declared as mapping and rendered nowhere, which no count of elements can see. Element kinds are not one to one: the pools and the lanes spend `documentation` too, so a count of that element is exact while this table''s share of it is zero, and `diagrams/ungoverned.sqlc` is the law that checks attribution instead'),
  ('scopes', '|scope stated| = |filing|', 'diagrams/scopes', 'documentation',
              'The `invents` state, caught in the emitter''s own prose. A sentence about a filing, hardcoded in the emitter, says one thing about every document where the filings differ, and `diagrams/scopes.sqlc` is what each one claims. That is not something a reader infers: the artifact says it. A count is not the law that matters here, the attribution one below it is: this only checks that a scope reached every document, and a wrong scope in every document would pass it'),
  ('dependences', '|association| = |coupling|', 'diagrams/dependences', 'association',
              'The model''s own falsifier, which no emitted document could state. `pm:Coupling` exists so the model can be refuted in its own format, and the reason that rules out `messageFlow` says nothing about `association`, whose `sourceRef` and `targetRef` are unconstrained QNames. The law is worth as much for what it cannot check: an association carries no magnitude and no observation, so |association| = |coupling| passes while the evidence and the strength are both gone'),
  ('namespaces', '|targetNamespace| = |notation|', 'composition/notations', 'targetNamespace',
              'a document that does not declare the uri it is, so nothing can reference it'),
  ('imports', '|import| = |document a composition reaches by a part or an elimination|', 'diagrams/cross_document', 'import',
              'a reference invented by the emitter, or a document reached without being imported'),
  ('in_a_lane', '|flowNodeRef| = |draw| + |part crossing a document|', 'diagrams/lane_membership', 'flowNodeRef',
              'an orphan flow node: emitted, counted, and in no lane, so the incidence that put it there is gone from the rendering while every cardinality law still passes'),
  ('definitions',   '|definitions| = |filing|',   'diagrams/pools', 'definitions',
              'a filing emitted twice, or one skipped, which no leaf count would show'),
  ('collaboration', '|collaboration| = |filing|', 'diagrams/pools', 'collaboration',
              'one filing split across two collaborations, so its pool has no single home'),
  ('process',       '|process| = |filing|',       'diagrams/pools', 'process',
              'one filing split into two processes, which makes its layers two partitions'),
  ('lane_set',      '|laneSet| = |filing|',       'diagrams/pools', 'laneSet',
              'The one that governs the elimination: a second lane set is how D and N would both be rendered, and every layer then has two lane elements with nothing but a matching name to say they are one layer'),
  ('documentation', '|documentation| = |sentence a relation states|', 'diagrams/annotated', 'documentation',
              'Documentation is not a container, which is what separates this row from the other four. They frame a document and must appear once; this is an annotation and may sit on any base element, so one per document fires the moment a lane is annotated, which is a law right about a fact and wrong about a kind. And the identity beside it is prose where the model side is a relation, so `diagrams/annotated.sqlc` can grow an arm with this count staying exact and the sentence describing it going stale. A count is also the wrong instrument here and always was, which is what `states` is for: every document can carry the right number of sentences and each say something no relation states, with the count exact for any corpus size. examples/diagramming/main.rs reads every one back and asks what states it')
) AS l(slug, law, model_side, element, catches)

)
SELECT d.object, d.element, d.governed_by, d.loses,
       (d.governed_by IS NOT NULL AND l.slug IS NULL)          AS names_a_law_that_is_not_there,
       (d.governed_by IS NULL AND d.loses IS NULL)             AS ungoverned_and_unexplained
FROM      (
    SELECT * FROM domain_objects
) d
LEFT JOIN (
    SELECT * FROM roster
) l ON l.slug = d.governed_by
WHERE d.element IS NOT NULL
