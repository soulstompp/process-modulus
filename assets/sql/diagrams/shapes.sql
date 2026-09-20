-- BPMN 2.0 DI: a bpmndi:BPMNShape per box and a bpmndi:BPMNEdge per route.
SELECT p.filing AS document, 'pool' AS shape_of, p.filing AS subject, 'shape' AS di
FROM ( SELECT * FROM diagrams.pools ) p
UNION ALL
SELECT l.filing, 'lane', l.layer, 'shape'
FROM ( SELECT * FROM layers.every_layer ) l
UNION ALL
SELECT o.filing, 'task', o.label, 'shape'
FROM ( SELECT * FROM entries.operations ) o
UNION ALL
SELECT c.composition, 'callActivity', c.composed_layer || '<-' || c.part_filing || '/' || c.part_layer, 'shape'
FROM ( SELECT * FROM diagrams.foreign_calls ) c
UNION ALL
SELECT k.filing, 'group', k.layer, 'shape'
FROM ( SELECT * FROM diagrams.categories ) k
UNION ALL
SELECT g.filing, 'textAnnotation', g.note, 'shape'
FROM ( SELECT * FROM diagrams.legends ) g
UNION ALL
SELECT d.filing, 'association', d.from_layer || '->' || d.to_layer, 'edge'
FROM ( SELECT * FROM diagrams.dependences ) d
