# Banco de dados

## Plataforma

O Elora utilizará o Supabase, baseado em PostgreSQL, como ponto de partida para persistência, autenticação e controle de acesso.

## Entidades iniciais

| Entidade | Finalidade |
| --- | --- |
| usuários | Identificação e acesso à plataforma. |
| organizações | Espaço financeiro de cada cliente ou negócio. |
| membros | Vínculo entre usuários e organizações, com papéis de acesso. |
| contas | Contas bancárias, carteiras ou centros de saldo. |
| categorias | Classificação de receitas e despesas. |
| lançamentos | Registros financeiros, valores, datas e categorias. |
| orçamentos | Limites planejados por período e categoria. |

## Diretrizes

- Todo dado financeiro deve pertencer a uma organização.
- O acesso será restringido por políticas de segurança no nível de linha (RLS).
- Valores monetários serão armazenados em formato decimal apropriado, evitando imprecisão de ponto flutuante.
- Migrações e políticas de acesso serão versionadas em `supabase/`.
