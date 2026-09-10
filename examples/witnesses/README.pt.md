**Português europeu.** Se cada regra já foi VISTA A DIZER NÃO.

> **Grafia do AO90.** A versão inglesa está em `README.md`, nesta pasta, e é a que o repositório
> trata como autoritativa quando as duas divergirem. Os nomes dos ficheiros, das tabelas e dos
> elementos do XSD ficam em inglês, porque são os nomes do artefacto.

⭐⭐⭐ OS OUTROS EXEMPLOS PERGUNTAM SE AS REGRAS ESTÃO CERTAS. ESTE PERGUNTA SE PODEM ESTAR
   ERRADAS. O `soundness` verifica que cada consulta calcula o que afirma e o `readiness` verifica
   que cada regra tem população, e uma regra pode passar em ambos sendo incapaz de falhar: um
   predicado verdadeiro por construção examina mil linhas e não conclui nada. Medido antes de este
   ficheiro existir, o conjunto de documentos e os fixtures punham 22 de 24 regras sobre linhas
   reais e NENHUMA REGRA TINHA SIDO ALGUMA VEZ OBSERVADA A DISPARAR. A coluna «violou» da matriz
   regra x {passou, violou} estava vazia de ponta a ponta.

⭐⭐ UMA TESTEMUNHA É UMA MUTAÇÃO MÍNIMA DE UM ARQUIVO REAL QUE FAZ TROPEÇAR EXATAMENTE UMA REGRA.
   O mínimo importa: uma mutação que faz tropeçar seis regras mostrou que alguma coisa é
   verificada, não que ESTA regra o é. Cada uma é uma única substituição de texto contra um
   documento do conjunto ou um fixture, e o mutante tem de continuar a validar contra o XSD, porque
   um documento que a gramática rejeita não prova nada acerca de uma regra a que a gramática nunca
   chega.

⛔ UMA REGRA SEM TESTEMUNHA É O ACHADO, E NÃO UMA LACUNA DESTE FICHEIRO. Duas não têm nenhuma, e
   são exatamente as duas que não examinam nada: `share_exceeds_slack` e `exposure_unaccounted`.
   Isso não é coincidência e é a metade útil do resultado. Uma regra só pode ser falsificada onde
   tem linhas, portanto uma população vazia e uma regra infalsificável são um só facto visto de
   dois lados, e nenhuma edição a um documento para que estas regras não olham produzirá alguma vez
   uma testemunha.

⚠️ SUBSTITUIÇÃO, NÃO ADIÇÃO. O mutante SUBSTITUI o seu documento de origem na carga em vez de se
   juntar a ele, pelo que o conjunto mantém a forma: os mesmos treze arquivos, os mesmos URN de
   notação, as mesmas referências de partes. Acrescentar uma cópia mutada colidiria em
   `filing_identity` e mudaria aquilo para que cada regra de composição está a olhar.

⚠️ E A CONTAGEM DE ÂNCORAS É AFIRMADA. Cada testemunha nomeia a ocorrência que edita e este
   ficheiro verifica quantas há. Uma edição a um documento que mude a contagem falha alto aqui em
   vez de mutar silenciosamente uma afirmação diferente e continuar verde.

Correr com:

```text
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
    cargo run --example witnesses
```
