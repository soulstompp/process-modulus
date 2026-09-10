**Português europeu.** Uma execução do modelo chega sequer a arquivar?

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

O `examples/resolution/main.rs` mede o que um instrumento deita fora, mas mede-o numa estrutura
que este repositório inventou para o efeito. Nada disso chega ao esquema. Este toma as mesmas
leituras, escreve-as como `pm:processModulus`, e passa-as pelos dois portões por que passa cada
documento do `assets/corpus/`: o `xmllint` contra o XSD, e as regras de conformidade em
`assets/sql/checks/`.

⭐⭐⭐ O QUE IMPORTA NÃO É QUE UM FICHEIRO GERADO VALIDE. É que um simulador escrito por outras
pessoas para outras razões, conduzido por uma bancada que nada sabe de contabilidade, preencha
estes campos SEM ESFORÇO. O `tests/independence.rs` sustenta que corroboração entre duas coisas
que partilham um caminho de código não vale nada; o `examples/matrices/main.rs` corrobora a
aritmética. Isto é o que corrobora a MODELAÇÃO. Um campo que tem de ser torcido para receber um
facto simulado é um achado acerca do campo.

⛔⛔ E É O SEGUNDO ARQUIVO QUE HÁ QUE VIGIAR. Cada execução é arquivada duas vezes, uma a partir
da história inteira e outra a partir do que um registo de stock-and-flow guarda. O arquivo mais
cego não é um documento pior, é um RELATO HONESTO DE MENOS. Se as regras o acusarem, estão a
acusar quem arquiva por não ter um instrumento, que é o modo de falha que a memória `uma regra
que dispara sobre um arquivo correto` existe para caçar. Zero violações em ambos é as ausências
tipadas do esquema a fazer o seu trabalho por inteiro.

Correr contra uma base de dados carregada:

```text
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example generation
```

⛔ Não há salto silencioso. Sem base de dados, falha em vez de correr. A carga acima acontece
   dentro de uma transação que é REVERTIDA, pelo que um conjunto de documentos já carregado fica
   exatamente como estava.
