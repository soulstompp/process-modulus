# `schema/`: o próprio artefacto, e os cinco documentos que permite a qualquer um escrever

> **Grafia do AO90.** A versão inglesa está em [`README.md`](README.md), nesta pasta, e é a que o
> repositório trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das
> tabelas e dos elementos do XSD ficam em inglês, porque são os nomes do artefacto.

⛔ **Esta pasta é o artefacto.** Todo o resto do repositório é uma implementação de referência do
que está aqui, um corpo de prova sobre isso, ou uma demonstração de que diz aquilo que afirma
dizer. Aquilo que não puder ser dito nestes dois ficheiros não faz parte do modelo.

## Dois ficheiros, e o segundo importa o primeiro

| ficheiro | prefixo | o que declara |
|---|---|---|
| `process-modulus.xsd` | `pm` | o modelo: uma oferta, aquilo em que se divide, o que a divisão deixa, e quem o suporta |
| `assertion.xsd` | `asrt` | o que uma SEGUNDA parte diz sobre um arquivo, que é outro género e precisa das suas próprias raízes |

A separação não é arrumação. Um arquivo é assinado pela entidade que descreve; uma resposta de
cobertura, uma execução promovida, uma dependência entre arquivos e uma consolidação são assinadas
por outrem, e uma afirmação *sobre* um arquivo não pode viver dentro do arquivo que julga.

Cinco elementos de raiz, portanto cinco géneros de documento:

| elemento | apresentado por |
|---|---|
| `pm:processModulus` | a entidade, sobre si própria |
| `asrt:coverage` | uma testemunha, a responder a um conjunto de perguntas |
| `asrt:run` | uma testemunha, a promover um ensaio datado a algo que um relatório pode citar |
| `asrt:dependence` | quem leu dois arquivos, nenhum deles seu |
| `asrt:composition` | uma entidade-mãe, a publicar uma pilha construída a partir dos arquivos de outros |

## Validar com o que houver

XSD 1.0, de propósito, e sem `xs:assert`. A funcionalidade tentadora da versão 1.1 reduziria três
tipos a zero, e foi testada em vez de presumida: um JDK normal não traz validador de 1.1, e a
`libxml2` nunca implementou a 1.1, que é o que o `xmllint`, o `lxml`, o PHP e o Nokogiri embrulham.
⛔ Um esquema cuja finalidade inteira é várias organizações poderem verificar um documento contra
ele não pode exigir uma instalação primeiro, e esse custo cai com mais peso sobre a parte mais
pequena da cadeia.

```bash
xmllint --noout --schema schema/process-modulus.xsd assets/corpus/enterprise-contract.xml
```

⚠️ **Desserializar não é validar**, em nenhuma das direções. O Rust gerado aceita um documento que
o `xmllint` recusa, e também o escreve. Use um validador.

## Para que servem as anotações, e para que não servem

Cada declaração documenta-se a si própria, em inglês e em português europeu, sob quatro títulos:

| título | |
|---|---|
| `WHAT IT IS` | o facto que esta posição transporta |
| `WHAT IT CONTAINS` | os seus filhos, confrontados com o modelo de conteúdo pelo `tests/annotations.rs` |
| `WHAT IT OBLIGES` | o que um emissor tem de fazer para o arquivar honestamente |
| `WHAT IT REFUSES` | a leitura a que um emissor competente chegaria, e porque está errada |

⛔ **Descrevem os DADOS.** Porque é que o modelo tem esta forma, o que foi tentado e retirado, e
como tudo isso foi descoberto são outro assunto com outro público, e pertencem ao lado do
argumento e não dentro do artefacto.

**`NOT REACHABLE BY A VALIDATOR` assinala as regras que o XSD 1.0 não consegue exprimir**, que são
quase todas comparações entre elementos ou entre documentos. A marca fica na declaração que enuncia
a regra, para que um leitor distinga sempre uma regra com guarda de uma sem ela. O
[`../conformance/README.md`](../conformance/README.md) lista-as e nomeia o que executa cada uma das
que é executada; o [`../assets/sqlc/README.md`](../assets/sqlc/README.md) é onde estão expressas
como consultas.

⚠️ **Os URI de espaço de nomes são provisórios** até estar decidido o domínio do autor. O
`tests/namespace.rs` faz da sua alteração uma operação verificada. Nada mais aqui é provisório.
