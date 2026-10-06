# `schema/`: o artefacto em si e os cinco documentos que qualquer pessoa pode escrever com ele

> **Português europeu, grafia do AO90.** Também disponível em inglês: [`README.md`](../../schema/README.md).

O que este projeto entrega é esta pasta, dois ficheiros XSD, e é com eles que uma empresa, um
contabilista ou quem consolida as contas de um grupo escreve os seus documentos, num editor de texto
qualquer, e os valida com as ferramentas que já tem, sem compilar nem instalar nada daqui; as
consultas, os testes e os exemplos que o repositório traz servem para ler esses documentos e para
verificar aquilo a que a validação não chega. O [corpus](../assets/corpus/) tem pelo menos um
documento de cada espécie.

## O esquema base e o das afirmações

Cada ficheiro tem o seu espaço de nomes, e o segundo importa o primeiro pelo caminho relativo, pelo
que os dois andam sempre juntos, lado a lado, como estão nesta pasta:

| ficheiro | prefixo | o que define |
|---|---|---|
| `process-modulus.xsd` | `pm` | o que uma entidade declara sobre si própria: as camadas, a procura e a oferta de cada uma, o resto que fica entre as duas e as operações que as consomem |
| `assertion.xsd` | `asrt` | o que alguém afirma sobre documentos que não escreveu, com os tipos do esquema base reaproveitados em vez de repetidos |

Quem recebe um documento sabe o que tem nas mãos pelo elemento de raiz, e há cinco: na declaração,
quem fala é a própria entidade, sobre si mesma, ao passo que os outros quatro são atestações,
afirmações de uma testemunha sobre coisas que não são suas, e por isso todos trazem a `witness`, o
nome de quem afirma:

| raiz | o documento |
|---|---|
| `pm:processModulus` | a declaração: uma pilha de camadas e, quando as há, as operações que as consomem |
| `asrt:composition` | a composição: a declaração de um grupo montada a partir das dos membros, com o que veio de onde e o que contava duas vezes |
| `asrt:dependence` | a dependência: um terceiro que leu duas declarações e atesta que uma camada de uma depende de uma camada da outra |
| `asrt:coverage` | a cobertura: as respostas de uma testemunha a um corpus de perguntas, pergunta a pergunta |
| `asrt:run` | a execução promovida a prova: o extrato datado e fechado que um relatório cita |

## Um validador qualquer chega

Os esquemas não saem do XSD 1.0, que todos os validadores correntes leem, e as referências de um
elemento a outro dentro do mesmo documento fazem-se com `xs:key` e `xs:keyref`, que também são
XSD 1.0, de modo que uma operação que diga consumir uma camada inexistente é recusada pelo próprio
validador, sem depender de convenção nenhuma. Os espaços de nomes são identificadores e não
endereços, pelo que nada se vai buscar à rede. A partir da raiz do repositório:

```sh
xmllint --noout --schema schema/process-modulus.xsd assets/corpus/enterprise-contract.xml
xmllint --noout --schema schema/assertion.xsd       assets/corpus/merge-group-composition.xml
```

Cada linha responde `validates` quando o documento está conforme; quando não está, o xmllint diz a
linha e a chave que falhou.

## O que cada anotação diz, e por que ordem

Os tipos dos dois esquemas trazem, num `xs:annotation`, o texto que explica para que servem, e é
esse texto, mais do que as sequências de elementos, que quem implementa lê; o `cargo doc` mostra-o
tal e qual na documentação dos tipos Rust que o `build.rs` gera a partir dos esquemas. Primeiro vem
o bloco em inglês, com `xml:lang="en"`, e onde há tradução segue-se o português, com
`xml:lang="pt"`, que abre com **Português.**; os dois seguem as mesmas secções, pela mesma ordem,
cada tipo com as que lhe fazem falta:

| secção | o que lá se lê |
|---|---|
| `# O que é` | o tipo, em poucas linhas |
| `# O que contém` | os elementos filhos, um por linha, cada um com o que guarda |
| `# O que obriga` | o que o tipo exige de quem escreve o documento e de quem o recebe |
| `# O que não admite` | os estados que o tipo não admite e as leituras erradas a afastar, cada um com a sua razão |
| `# O que nenhum validador alcança` | as regras que o XSD 1.0 não consegue verificar ali |

Uma enumeração lista os seus valores em `# Os membros`; `# Onde se verifica` diz que consulta faz
cumprir uma regra, e `# Ver também` aponta os tipos vizinhos. A lista de `# O que contém`, essa, é
mais do que uma descrição, já que um teste a confronta, nas duas línguas, com os filhos que o tipo
de facto declara, de modo que quem escreve a partir dela nunca envia um elemento que o validador
recuse nem fica sem saber de um que podia enviar.

## Até onde chega um validador

O XSD 1.0 não tem `xs:assert`, não compara um elemento com outro e não segue uma referência para
fora do documento, pelo que muitas das regras que as próprias anotações enunciam lhe escapam: que
as quotas de quem suporta um resto somem o resto inteiro, que a capacidade nominal de uma oferta em
unidades inteiras dê um número certo dessas unidades, que a parte de uma composição aponte para uma
declaração e uma camada que existam de facto. Essas regras são consultas em SQL, e o percurso de
[`assets/sqlc/`](../assets/sqlc/README.md) acaba precisamente nelas, cada uma com as linhas que
examinou e as que a quebraram; quanto ao que um perfil pode apertar por cima destes esquemas, e ao
que um implementador continua a dever, está tudo em [`conformance/`](../conformance/README.md).
