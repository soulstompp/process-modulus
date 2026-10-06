**Português europeu.** Cada regra do rol já foi vista a dizer que não?

> **Grafia do AO90.** Também disponível em inglês: `examples/witnesses/README.md`.

Uma regra que nunca disse que não nunca foi posta à prova, e uma regra sem nada para examinar passa
sempre. Este programa guarda, para cada regra, a alteração mais pequena a um documento real que a
deve fazer disparar, como nomear um `customer` numa camada em `clearance`, trocar o ajustamento
declarado de uma camada, esticar uma quota para lá do maior resto possível ou mudar a unidade de um
quantum. Cada documento alterado tem de continuar a passar no esquema, porque um documento que o
esquema recusa nada diz sobre uma regra que só atua depois dele; entra pelo mesmo `ingest.sql` que o
corpus, numa transação que se desfaz logo a seguir, e correm todas as regras.

Para cada testemunha, o programa diz se a regra visada disparou, se disparou também outra ou se
ficou calada, e uma que fique calada faz o programa falhar, porque ou a alteração deixou de estar
errada ou a regra deixou de reparar, e as duas coisas interessam. Depois lê o rol, e não uma lista
sua, para mostrar as regras a que nenhuma testemunha chega, separando as que não examinam nada, que
alteração nenhuma alguma vez apanha, das que examinam linhas e só não têm ainda testemunha, o que é
uma dívida deste programa e não um facto sobre a regra.

## Correr o programa

Precisa de uma base de dados carregada, que fica como estava:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example witnesses
```
