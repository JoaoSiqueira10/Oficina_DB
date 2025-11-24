# Projeto Oficina — Esquema Lógico de Banco de Dados

Este repositório contém o esquema lógico, dados de teste e consultas SQL para um sistema de gerenciamento de oficina mecânica (workshop).

## O que contém
- `oficina_schema.sql` — DDL (PostgreSQL) para criar o schema `oficina` com tabelas: party, accounts, mechanics, vehicles, parts, suppliers, inventory, service_orders, service_order_items, service_item_parts, payments, payment_methods, appointments, e view de totais.
- `seed.sql` — Dados de exemplo para testes.
- `queries.sql` — Consultas demonstrando SELECT, WHERE, atributos derivados, ORDER BY, HAVING e JOINs complexos.

## Regras e restrições chave
- Contas são PF **ou** PJ (CHECK para cpf/cnpj).
- Uma ordem de serviço (`service_orders`) pode ter múltiplos itens; itens podem usar várias peças.
- Pagamentos podem ser parciais; existem múltiplas formas de pagamento por conta.
- Integridade referencial via FK e validações via CHECK (preços >= 0, quantidades >= 0 etc.).

## Como usar
1. Crie um banco PostgreSQL vazio.
2. Execute:
   ```bash
   psql -d seu_banco -f oficina_schema.sql
   psql -d seu_banco -f seed.sql
   ```
3. Rode queries em `queries.sql` para testar os cenários descritos.

