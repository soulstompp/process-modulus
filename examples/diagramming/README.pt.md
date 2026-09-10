**Português europeu.** O modelo, traduzido para BPMN 2.0, e as leis que dizem que a tradução foi fiel.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do BPMN e do XSD ficam em inglês, porque são os nomes do artefacto.

⭐⭐⭐ ISTO É UM PASSO DE COMPOSIÇÃO, NÃO UM PROGRAMA DE DESENHO. O modulus é o `.sqlc`, o BPMN é
o `assets/sql/`, e isto é o `cargo sqlc compose`. Portanto o `assets/bpmn/` é GERADO E APAGADO em
cada execução e nunca deve ser editado à mão, cada documento emitido é completo e abre SOZINHO, e
a proveniência sobrevive DENTRO do artefacto tal como a linha `--` sobrevive no SQL gerado. Se
encontrou um diagrama que quer mudar, mude o modelo.

⛔⛔ QUEM LÊ ISTO É O SGBD DESTE PIPELINE. O Postgres executa uma diferença mal escrita e devolve
uma tabela plausível; um analista brilhante lê um diagrama mal feito e chega a uma conclusão
confiante. Nenhum dos dois lhe diz que se enganou, e o diagrama é o pior dos dois, porque uma
tabela errada volta a ser verificada e um diagrama errado é acreditado e vai para uma apresentação.
O `assets/sqlc/diagrams/roster.sqlc` é a razão pela qual as leis abaixo existem.

⭐⭐ O EMISSOR NÃO TEM JUÍZO NENHUM LÁ DENTRO, E AS CONTAGENS ESPERADAS NÃO SÃO SUAS. Cada objeto
`pm.*` é desenhado como o `diagrams/domain_objects.sqlc` diz, e cada contagem é confrontada com o
`diagrams/expected.sqlc`, que é calculado a partir do modelo por relações que este programa não
escreve. Um emissor que calculasse a sua própria expectativa concordaria consigo mesmo fizesse o
que fizesse.

⛔ O QUE NÃO PÔDE SER DESENHADO É ENUMERADO, porque um diagrama em branco e um diagrama de nada
são indistinguíveis de fora. Essa lista é a afirmação de fronteira executada em vez de afirmada.

```text
DATABASE_URL=... cargo run --example diagramming
```
