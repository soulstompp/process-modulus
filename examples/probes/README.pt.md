**Português europeu.** Se cada lei já foi VISTA A FALHAR, e cada declaração correta vista a sobreviver a uma edição que não a pode acusar.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

O exemplo `soundness` afirma que todas as leis se verificam, e o `witnesses` que todas as regras
sabem dizer não. Uma lei também é uma guarda, e uma guarda que ninguém viu falhar pode ser
verdadeira por construção. Este programa edita aquilo que uma lei governa e exige que a lei dê por
isso.

Cada sonda é uma edição, feita dentro de uma transação que é revertida, portanto o corpus carregado
fica intacto e a bateria inteira é uma única execução do psql. Há quatro espécies.

- **Uma sonda de lei** edita o texto de uma relação composta tal como está dentro da instrução da
  própria lei, e nomeia os sujeitos que têm então de falhar. A maioria é a versão errada mais
  pequena da relação: um emparelhamento cruzado lido limite a limite, um divisor trocado por um
  máximo, uma partição sem o último ramo. Algumas editam antes as linhas carregadas, onde o
  trabalho da lei é vigiar os dados. Lê a lei da composição inline, `target/sql-inline/`, onde
  todas as relações que a lei compõe estão no seu texto; o `assets/sql/` versionado nomeia uma
  relação partilhada pela sua vista, e aí não há nada para editar.
- **Uma absolvição** edita um documento correto e nomeia todos os veredictos que ele tem de
  continuar a ter: exatamente estas regras disparam, exatamente estas leis falham. É a outra
  metade de uma testemunha. Uma testemunha mostra que uma regra sabe acusar; uma absolvição mostra
  que o modelo não acusa onde não pode, que é onde uma suspensão ou um valor levantado fazem o seu
  trabalho.
- **Uma recusa** edita um documento para um estado que a gramática proíbe e exige que o validador
  o rejeite, para que nenhum leitor seja alguma vez chamado a julgá-lo.
- **Os planos.** Todas as instruções que um programa lê com `query_file!` são verificadas quando
  compila, e o sqlx lê o plano de volta como JSON através de um descodificador que recusa
  aninhamento para lá de uma profundidade fixa. Este programa mede cada plano e falha antes de
  esse teto falhar.

Cada edição afirma quantas vezes a sua âncora ocorre, para que uma relação ou um documento que se
mexa por baixo de uma sonda falhe aqui com estrondo em vez de mutar outra coisa e passar.

O relatório fecha com as leis da lista que nenhuma sonda viu ainda falhar. São lidas da lista, para
que uma lei acrescentada amanhã chegue por sondar em vez de chegar sem ninguém reparar.

O programa não lê instrução nenhuma com `query_file!`, portanto compila seja qual for o estado da
cache `.sqlx`, e pode correr depois de a base de dados ser recarregada e antes de
`cargo sqlx prepare`.

Correr com:

```text
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
    cargo run --example probes
```
