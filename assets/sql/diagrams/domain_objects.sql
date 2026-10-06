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
