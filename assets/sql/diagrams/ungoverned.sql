-- diagrams/domain_objects.sqlc's governance claims against diagrams/roster.sqlc.
SELECT d.object, d.element, d.governed_by, d.loses,
       (d.governed_by IS NOT NULL AND l.slug IS NULL)          AS names_a_law_that_is_not_there,
       (d.governed_by IS NULL AND d.loses IS NULL)             AS ungoverned_and_unexplained
FROM      (
    -- the pm.* tables against BPMN 2.0's element vocabulary, as data an emitter reads.
SELECT * FROM (VALUES
  ('source', 'definitions', NULL, 'definitions', NULL, NULL, 'the document itself. A BPMN file IS a definitions document'),
  ('filing', 'participant', NULL, 'pools', NULL, NULL, 'the participant that renders the document as a pool'),
  ('filing_identity', 'targetNamespace', NULL, 'namespaces', NULL, NULL, 'a notation resolved to a document, which is what import does'),
  ('layer', 'lane', NULL, 'lanes', NULL, NULL, 'a lane, and the region it delimits'),
  ('operation', 'task', NULL, 'tasks', 'demoted', '⭐ THE POINTER IS ON THE PAGE AND NO TOOL CAN FOLLOW IT, WHICH IS THE STATE `pm:ForeignId` INTENDS. A notation plus an id names a node in the process notation the filer was READING, which is a different document from this one, so it must not become this task''s own `id` (that would claim the two documents are one) and it cannot be a `relationship`, whose `source` and `target` are QNames needing an `import` that needs a location nobody filed. It rides the task''s `documentation`: a person reads the id, a tool resolves nothing. ⚠ Unlike every other `demoted` row here, the tool could not do better even in principle, because no authority publishes the list it would resolve against', 'a flow node, reached by foreignId. ⛔⛔ AND THE COLUMN DID NOT EXIST, so this row read `loses` NOTHING while losing the only thing it is about. `pm:Operation/foreignId` is the whole BPMN interface, the ingest read the label alone, and the crossing was filed by the corpus, discarded on every load and absent from every artifact. Third of the model''s three `pm:ForeignId` references and the last without a relation beside it: `entries/notation_references.sqlc`'),
  ('draw', 'laneSet', NULL, 'in_a_lane', NULL, NULL, 'D. The lane set a modeller actually files: the performer''s lane'),
  ('induction', 'group', NULL, 'induced_into', 'demoted', '⭐ THE POINTER, AND NOTHING ELSE NOW. `tCategoryValue` adds one `xs:string` to a base element and no reference attribute, so the layer arrives as TEXT beside a `lane` of the same name. That is the callActivity defect at one tenth the size: a call loses the layer, this keeps its name and loses the tie. ⛔ `decider` is lost too, and for the ordinary reason: it is a performer and nothing here files a claimant edge', 'N, the cover. Emitted as categoryValueRef on each operation and drawn as a group, which adds no lane where a second laneSet would have added one per induced layer'),
  ('part', 'callActivity', NULL, 'calls', 'absent', '⭐ WHAT IS LEFT IS THE FACTOR. With `calledElement` as the only reference the target LAYER went too: it names a PROCESS, so 17 layer-grain edges collapsed to 5 document pairs. `tRelationship` takes QNames at BOTH ends and a REQUIRED `type`, so `diagrams/descents.sqlc` now carries the same fact at the grain F has, read back and compared edge for edge. ⛔ What no element carries is the FACTOR, a three-point magnitude on a page with no unit, and that is `absent` for the reason every magnitude here is. ⚠️ AND THIS ROW IS AT THE WRONG GRAIN TO SAY SO: one table maps to TWO elements now, `callActivity` for the substitution and `relationship` for the grain, and the roster has one `element` and one `governed_by`', 'foreign; an embedded subProcess when the part is local'),
  ('composition_citation', 'documentation', NULL, 'citations', 'demoted', '⛔ THE STRUCTURE, AND NOT EVERYTHING. The table settles it: `pm.composition_citation` is `(taxonomy, instrument, clause, version)`, four TYPED fields, not free prose. A `documentation` element carries all four as ONE STRING, so a reader can follow the citation and a tool cannot resolve it. ⭐ Narrower than *everything* and worth being exact about, because the two states owe different repairs', 'the instrument a composition is filed under. ⚠️ The open question is the schema''s and not the diagram''s: `(composition, seq)` is a bare document ordinal where both sibling children carry a regime handle'),

  ('coupling', 'association', NULL, 'dependences', 'absent', '⛔⛔ THE OBSERVATION AND THE STRENGTH, WHICH IS ALL THE EVIDENCE THERE IS. `pm:observed` is REQUIRED prose and it is the whole argument; an `association` carries none, and two of the five observations here contain a numeral, so routing them through `documentation` would put a magnitude on a page with no unit, which is `dataObject`''s refusal arriving through prose. The artifact says two layers are coupled and cannot say what was seen', 'C, the model''s own falsifier. `sourceRef` and `targetRef` are unconstrained QNames, so two LANES are a legal pair; withheld for years on a reason that ruled out `messageFlow` and was never asked of this'),
  ('coupling_search', 'documentation', NULL, 'documentation', NULL, NULL, '⭐ the OTHER HALF OF THE PAIR, on the laneSet, because the laneSet IS the partition the search is about. 12 of 15 filings state no coupling, so a diagram drawing only the matrix is silent about them in a way a reader resolves as independence. An absent line is not independence'),
  ('elimination_search',   NULL, 'notApplicable', NULL, NULL, NULL, 'the same, for double counting'),
  ('stack_scope', 'documentation', NULL, 'scopes', 'demoted', '⛔ THE STRUCTURE. `tLaneSet` has no extent attribute of any kind, so all three states render as one lane set and the answer survives only as untyped text. ⚠️ BPMN is the FINER of the two on the BASIS and has nothing at all on the extent: `tLane` carries `partitionElement` and `partitionElementRef` for what a partition is BY, per LANE, where this model files one basis per STACK. The grain axis, running backwards for once', '⛔⛔ THIS ROW SAID `notApplicable` WHILE ITS OWN REASON SAID *a lane set is implicitly complete*, and a tuple that contradicts itself is the sharpest finding shape there is. Both cannot hold: if the answer is implicitly complete then the question arose and the artifact answered it. It did, literally, in a hardcoded sentence in 15 of 15 documents where 1 filing claims complete. That is `invents` and not an absence, and the repair was to read the extent instead of asserting it'),
  ('elimination',          NULL, 'notApplicable', NULL, NULL, NULL, 'a call REFERENCES and never redeclares, so BPMN cannot double declare and owes no correction'),
  ('elimination_between', 'relationship', NULL, 'attributions', 'absent', '⛔ THE SIZE OF THE OVERLAP, which is `pm.elimination`''s business and not this table''s, and the REFERENCES THAT DO NOT RESOLVE: a QName needs a prefix and a prefix needs an import, so a `between` naming a document nobody filed cannot be pointed at. ⚠️ 8 of 8 resolve here, so that arm is unexercised by luck', '⛔⛔ FILED `notApplicable` ON A REASON THAT WAS NEVER ABOUT IT: *presupposes the overlap BPMN cannot express*. That is about the MAGNITUDE, and this table has none. It is `asrt:FiledLayer`, whose filing is a `pm:ForeignId` -- the SAME reference type a part uses -- and the schema says it exists *so the attribution is queryable rather than narrated*. ⭐ The reason it stayed invisible is structural: this tree grows by rules, and `between` is the one cross-document reference no rule MAY check, because the schema licenses an unresolvable one outright'),

  ('nameplate',            NULL, 'none', NULL, NULL, NULL,          'a committed, quantized magnitude. BPMN carries no quantity anywhere'),
  ('slack',                NULL, 'none', NULL, NULL, NULL,          'three buffers per layer, each a magnitude'),
  ('claim',                NULL, 'none', NULL, NULL, NULL,          'a value at a position, with its own width'),
  ('narrowing',            NULL, 'none', NULL, NULL, NULL,          'what would narrow a claim. BPMN has no epistemics'),
  ('bound_origin',         NULL, 'none', NULL, NULL, NULL,          'where a bound came from. The same'),
  ('regime',               NULL, 'none', NULL, NULL, NULL,          'the jurisdiction and framework a document reports under'),
  ('composition_regime',   NULL, 'none', NULL, NULL, NULL,          'what a COMPOSER says another document''s regime is: a second claim with a second author, and no more drawable than the first'),
  ('buffer_term',          NULL, 'none', NULL, NULL, NULL,          'a taxonomy lookup a reader can delete'),

  ('holder',               NULL, 'misreads', NULL, NULL, NULL,      '⛔ resourceRole and performer have the right SHAPE and the wrong claim: they say who ACTS, and a holder is who BEARS. Four of the five kinds name no party at all')
) AS d(object, element, absent, governed_by, loses_kind, loses, why)

) d
LEFT JOIN (
    -- the cardinality identities a BPMN emission owes, against the relation supplying each expected count.
SELECT * FROM (VALUES
  ('pools',   '|participant| = |filing|',      'epistemics/documents',     'participant',
              'a document rendered as two pools, or two rendered as one'),
  ('lanes',   '|lane| = |layer|',              'layers/every_layer',       'lane',
              'a partition rendered as an overlap: the falsifier, drawn'),
  ('tasks',   '|task| = |operation|',          'entries/operations',       'task',
              'an operation dropped, or a flow node invented to make the picture read'),
  ('calls',   '|callActivity| = |part crossing a document|', 'diagrams/foreign_calls', 'callActivity',
              '⛔ ONE LAW OVER TWO ELEMENTS WOULD LET A LOCAL PART BE RENDERED AS AN ACTIVITY. A local fusion is a PARTITION of the composed layer, not a node inside it. Splitting the law is also what makes the flattening measurable: only these parts go through `calledElement`, so this IS the population exposed to the invented-cycle defect'),
  ('nestings', '|childLaneSet| = |layer with a local part|', 'diagrams/nestings', 'childLaneSet',
              '⭐ THE RECURSION EQUIVALENCE, AND BPMN ALREADY HAD THE ELEMENT. A fusion''s parts partition what they compose, and `Lane/childLaneSet` is a SUB-PARTITION. A nested lane is still keyed `(filing, layer)`, so unlike a call it collapses nothing and can invent nothing'),
  ('categories', '|category| = |filing with an induction|', 'diagrams/categories', 'category',
              'a classification scheme emitted into a document that has nothing to classify, or a document with inductions and no scheme to hang them on'),
  ('category_values', '|categoryValue| = |layer induced into|', 'diagrams/categories', 'categoryValue',
              '⭐ N GETTING A NOTATION. It was filed as losing EVERYTHING and emitted nothing, on the true observation that a second `laneSet` gives every layer two `lane` elements. BPMN''s other mechanism adds no lane at all: `tFlowElement/categoryValueRef` is `maxOccurs="unbounded"`, so the MEMBER declares the cover and no container grows'),
  ('groups',     '|group| = |categoryValue|',    'diagrams/categories', 'group',
              '⭐⭐ THE GLYPH AGAINST THE FACT, AND THE PAIR IS THE ANSWER TO WHAT A GROUP IS. `group` is to `categoryValueRef` what `lane` is to `flowNodeRef`: the drawn shape of an incidence held elsewhere. A categoryValue with no group is a classification nobody drew; a group with no categoryValue is a dashed box that means nothing'),
  ('induced_into', '|categoryValueRef| = |induction|', 'diagrams/category_members', 'categoryValueRef',
              '⛔ AN INDUCTION DROPPED, WHICH `|lane| = |layer|` CANNOT SEE. One operation here draws from `labour` and induces into `capability`; a lane set holds it in one place, so holding it in the draw alone leaves the second incidence out of every emitted document while the layer count still agrees'),
  ('diagrams', '|BPMNDiagram| = |filing|', 'diagrams/pools', 'BPMNDiagram',
              '⭐⭐⭐ THE SVG''S PROPER PLACE IN THE DOCUMENT. `bpmndi:BPMNDiagram` is in `tDefinitions`''s own sequence, and a document without one leaves the SVG stage to INVENT its coordinates while any tool that opens the file lays it out differently: two pictures of one model with nothing tying them'),
  ('planes', '|BPMNPlane| = |filing|', 'diagrams/pools', 'BPMNPlane',
              'one surface per document, naming the collaboration it is a picture OF. A second plane would be a second picture of one model with no way to say which is meant'),
  ('shapes', '|BPMNShape| = |pool| + |lane| + |flow node|', 'diagrams/shapes', 'BPMNShape',
              '⛔ THE PRIMITIVES ONLY. A `group`, an `association` and a `textAnnotation` are drawn and none is declared, because each is DERIVED from these boxes, and filing a derived coordinate is filing a value that can disagree with what computes it'),
  ('legends', '|textAnnotation| = |note a document owes on its face|', 'diagrams/legends', 'textAnnotation',
              '⭐⭐⭐ A FACT PRESENT AND INVISIBLE, WHICH IS THE STATE 71 OF THEM WERE IN. `documentation` is admitted on any base element and drawn in no rendering, so a scope, a coupling search, a dependence''s meaning and a cover''s meaning were all in the artifact and on no page. `textAnnotation` is the only element in BPMN that puts words on the canvas and it was withheld on *documentation is spent instead*: true, and about the wrong property'),
  ('attributions', '|relationship type=elimination-between| = |between that resolves|', 'eliminations/resolved', 'relationship',
              '⭐⭐⭐ THE SECOND `pm:ForeignId`, AND THE ELEMENT''S TYPE EARNING ITS KEEP. `association` was refused for F because it has no type and a second use makes two facts indistinguishable; `tRelationship/@type` is REQUIRED, so a second relation costs a different string and the laws filter on it. ⛔ The population is the RESOLVED references and not all of them: a QName needs a prefix and a prefix needs an import, so a `between` naming a document nobody filed cannot be pointed at, and the schema calls that filing ORDINARY'),
  ('descents', '|relationship| = |part crossing a document|', 'diagrams/descents', 'relationship',
              '⭐⭐⭐ THE MAPPING''S WIDEST DEMOTION, PROMOTED. `calledElement` names a PROCESS, so 17 layer-grain edges collapsed to 5 document pairs and the layer survived only inside `@name`. ⛔ THE COUNT IS THE WEAK HALF: 17 relationships joining the wrong 17 pairs passes it, which is why the isomorphism law in examples/diagramming/main.rs reads the ENDPOINTS back and compares the edge SET to F'),
  ('citations', '|citation rendered| = |citation filed|', 'diagrams/citations', 'documentation',
              '⭐ THE LAST ROW THAT WAS DECLARED AND NEVER RENDERED. It named `documentation`, emitted nothing, and was invisible because element KINDS are not one to one: that element was already spent by the pools and the lanes, so its count was exact while this table''s share of it was zero'),
  ('scopes', '|scope stated| = |filing|', 'diagrams/scopes', 'documentation',
              '⛔⛔⛔ THE `invents` STATE, CAUGHT IN THE EMITTER''S OWN PROSE. Every document said *a partition of layers claimed exhaustive*, hardcoded, 15 of 15, where one filing claims `complete` and 14 declined to. That is not something a reader inferred: the artifact SAID it. ⭐ A count is not the law that matters here, the ATTRIBUTION one below it is: this only checks that a scope reached every document, and a wrong scope in every document would pass it'),
  ('dependences', '|association| = |coupling|', 'diagrams/dependences', 'association',
              '⭐⭐⭐ THE MODEL''S OWN FALSIFIER, WHICH NO EMITTED DOCUMENT COULD STATE. `pm:Coupling` exists so the model can be REFUTED IN ITS OWN FORMAT, and it was mapped `notApplicable` on a reason that ruled out `messageFlow` and was never asked of `association`, whose `sourceRef` and `targetRef` are unconstrained QNames. ⛔ The law is worth as much for what it CANNOT check: an association carries no magnitude and no observation, so |association| = |coupling| passes while the evidence and the strength are both gone'),
  ('namespaces', '|targetNamespace| = |notation|', 'composition/notations', 'targetNamespace',
              'a document that does not declare the uri it IS, so nothing can reference it'),
  ('imports', '|import| = |cross-document part reference|', 'diagrams/cross_document', 'import',
              'a reference invented by the emitter, or a document reached without being imported'),
  ('in_a_lane', '|flowNodeRef| = |draw| + |part|', 'diagrams/lane_membership', 'flowNodeRef',
              '⛔ an ORPHAN flow node: emitted, counted, and in no lane, so the incidence that put it there is gone from the rendering while every cardinality law still passes'),
  ('definitions',   '|definitions| = |filing|',   'diagrams/pools', 'definitions',
              'a filing emitted twice, or one skipped, which no leaf count would show'),
  ('collaboration', '|collaboration| = |filing|', 'diagrams/pools', 'collaboration',
              'one filing split across two collaborations, so its pool has no single home'),
  ('process',       '|process| = |filing|',       'diagrams/pools', 'process',
              'one filing split into two processes, which makes its layers two partitions'),
  ('lane_set',      '|laneSet| = |filing|',       'diagrams/pools', 'laneSet',
              '⛔ THE ONE THAT GOVERNS THE ELIMINATION: a SECOND lane set is how D and N would both be rendered, and every layer then has two lane elements with nothing but a matching name to say they are one layer'),
  ('documentation', '|documentation| = |sentence a relation states|', 'diagrams/annotated', 'documentation',
              '⛔ IT WAS IN THE CONTAINER LIST AND DOCUMENTATION IS NOT A CONTAINER. The other four frame a document and must appear once; this is an ANNOTATION and may sit on any base element. Written as one per document it fired the moment a lane was annotated, which is the law being right about a fact and wrong about a kind. ⛔⛔ AND ITS IDENTITY READ `|filing| + |layer|` LONG AFTER `diagrams/annotated.sqlc` GREW TO NINE ARMS: the model side is a relation and the identity beside it is prose, so the count stayed exact while the sentence describing it rotted. ⭐ A count is also the wrong instrument here and always was, which is what `states` is for: fifteen documents can carry the right number of sentences and each say something no relation states. examples/diagramming/main.rs reads every one back and asks what states it')
) AS l(slug, law, model_side, element, catches)

) l ON l.slug = d.governed_by
WHERE d.element IS NOT NULL
