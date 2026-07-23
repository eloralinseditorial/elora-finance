# Supabase

## O que já está versionado

- `supabase/config.toml`: configuração para o ambiente local.
- `supabase/migrations/`: estrutura do banco, índices, gatilhos e políticas de acesso.
- `.env.example`: nomes das variáveis necessárias para frontend e backend, sem segredos.

## Modelo de acesso

Cada registro financeiro pertence a uma organização. Ao criar uma organização, a pessoa autenticada torna-se automaticamente sua proprietária. Pessoas com papel `owner` ou `admin` podem alterar os dados; as demais integrantes podem apenas consultar, de acordo com as políticas iniciais.

## Próxima configuração

1. Criar um projeto no painel do Supabase.
2. Informar o `Project Reference` para vinculá-lo a este repositório.
3. Copiar a URL e a chave anônima para um arquivo `.env` local, a partir de `.env.example`.
4. Aplicar a migração e validar as políticas de acesso antes de conectar o frontend.

> A chave `service_role` é exclusiva do backend e não deve ser incluída no frontend, no Git ou em mensagens.
