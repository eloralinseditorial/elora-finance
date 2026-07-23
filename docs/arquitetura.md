# Arquitetura inicial

## Componentes

| Camada | Responsabilidade |
| --- | --- |
| Frontend | Interface web, fluxos de uso e visualização dos dados. |
| Backend | Regras de negócio, validações, integrações e serviços da aplicação. |
| Supabase | Autenticação, banco de dados PostgreSQL, armazenamento e recursos de backend. |
| Assets | Recursos visuais e materiais estáticos do produto. |

## Princípios

- Segurança e privacidade desde a modelagem dos dados.
- Separação clara entre interface, regras de negócio e persistência.
- Evolução incremental, priorizando o MVP.
- Configurações sensíveis apenas por variáveis de ambiente.

## Fluxo principal

```text
Pessoa usuária → Frontend → Backend / Supabase → Banco de dados
```

O detalhamento de tecnologias, contratos de API e autenticação será registrado conforme as decisões de implementação forem tomadas.
