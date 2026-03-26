# Review — Domain Specialist (Terraform / IaC / Cloud Infrastructure)
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Ricardo Azevedo, Especialista em Terraform e Cloud Infrastructure
**Experiência:** 8 anos gerenciando infraestrutura AWS/GCP via Terraform em ambientes enterprise (500+ recursos, múltiplas contas, módulos compartilhados)
**Data:** 2026-03-26

---

## Por Que Minha Perspectiva Importa

Sou a pessoa que vai usar esta ferramenta para resolver problemas reais de gestão de infraestrutura. Também sou a pessoa que vai recusar adotá-la se ela não respeitar as nuances do domínio do Terraform. Vi muitas ferramentas de visualização de IaC que foram construídas por engenheiros que nunca gerenciaram um estado Terraform real — e todas falharam no mesmo ponto: **elas não entendem que Terraform não é só um grafo de recursos, é um sistema de estado com semântica complexa**.

---

## Análise do Modelo de Dados: O Que Foi Assumido vs a Realidade

### O Limite Mais Crítico do Sprint 1

O gerador sintético cria nós com campos `index`, `x`, `y`, `w`, `h` — coordenadas geométricas inventadas. Um `.tfstate` real do Terraform tem uma estrutura radicalmente diferente:

```json
{
  "format_version": "1.0",
  "terraform_version": "1.7.0",
  "values": {
    "root_module": {
      "resources": [
        {
          "address": "aws_vpc.main",
          "mode": "managed",
          "type": "aws_vpc",
          "name": "main",
          "provider_name": "registry.terraform.io/hashicorp/aws",
          "schema_version": 1,
          "values": {
            "cidr_block": "10.0.0.0/16",
            "id": "vpc-0abc123",
            "tags": {"Environment": "production", "Owner": "platform-team"}
          },
          "depends_on": ["aws_internet_gateway.main"]
        }
      ],
      "child_modules": [
        {
          "address": "module.networking",
          "resources": [...]
        }
      ]
    }
  }
}
```

**O que o parser atual *não* extrai (e que é essencial para UI útil):**

| Campo | Importância para UI | Status |
|---|---|---|
| `address` (ex: `aws_vpc.main`) | Identificador único no canvas | ❌ Não parseado |
| `type` (ex: `aws_vpc`) | Define ícone e categoria visual | ❌ Não parseado |
| `depends_on` | Define as **arestas** do grafo | ❌ Não parseado |
| `child_modules` | Define hierarquia pai-filho | ❌ Não parseado |
| `provider_name` | Define provider (AWS/GCP/Azure) | ❌ Não parseado |
| `values.tags` | Filtros essenciais de usuário | ❌ Não parseado |
| `values.id` | ID do recurso real na cloud | ❌ Não parseado |

**O benchmark atual prova que conseguimos mover coordenadas `int32` rapidamente — mas um grafo Terraform real exige strings, hierarquias e arestas.** A performance real com strings variáveis e estrutura aninhada pode ser significativamente diferente dos 70ms medidos.

### O Modelo de Grafo Está Incompleto

O projeto fala em "Grafo Acíclico Dirigido (DAG) do Terraform". Correto — o Terraform usa um DAG internamente. Mas há duas fontes de dados para construir esse DAG:

1. **`depends_on` explícito:** Declarado pelo usuário no código HCL
2. **Dependências implícitas:** Quando um recurso referencia o `id` de outro (ex: `subnet_id = aws_subnet.private.id`)

O segundo tipo **não aparece no `.tfstate`** — ele só é visível no **plano de execução** (`terraform plan`) ou no grafo de configuração (`terraform graph`). Um visualizador que usa apenas o `.tfstate` vai mostrar recursos sem conexões entre eles na maioria dos casos — o que é quase inútil para entender a infraestrutura.

**Recomendação:** Definir explicitamente as fontes de dados do produto:
- Apenas `.tfstate` (o que está deployado, sem arestas de dependência)
- `.tfstate` + `terraform graph` (topologia completa, mas requer execução do Terraform)
- HCL source files (configuração completa, requer parser HCL robusto)

Cada escolha tem implicações radicalmente diferentes para a arquitetura.

---

## Casos de Uso Críticos Não Mapeados

Como especialista de domínio, esses são os casos de uso que fariam eu adotar (ou recusar) a ferramenta:

### Caso 1: Entender o Impact Radius de uma Mudança
*"Se eu modificar `aws_security_group.app`, quais recursos serão afetados?"*

Isso requer navegar as arestas de dependência no sentido inverso — resources que *dependem de* `aws_security_group.app`. Sem arestas, não é possível.

### Caso 2: Encontrar Recursos Órfãos
*"Quais recursos existem no state mas não têm nenhuma dependência — podem ser candidatos para remoção?"*

### Caso 3: Comparar Dois Ambientes
*"Mostre diferenças entre o state de produção e o de staging"*

### Caso 4: Navegar por Tags
*"Mostre todos os recursos com `Environment=production` e `CostCenter=dataplatform`"*

### Caso 5: Detectar Drift
*"Quais recursos estão marcados como `tainted` ou têm estado inconsistente?"*

Nenhum desses casos de uso foi mencionado no roadmap. **Eles são fundamentais para que a ferramenta tenha valor diferenciado** — sem pelo menos Caso 1 e Caso 4, ela é apenas um visualizador decorativo.

---

## Análise da Stack: Compatibilidade com Ecossistema Terraform

| Tecnologia | Suportada? | Observação |
|---|---|---|
| Terraform OSS (open source) | ✅ (planejado) | Usa `.tfstate` local |
| Terraform Cloud | ❓ | API diferente para acessar states |
| Terraform Enterprise | ❓ | Air-gapped, requer instalação local |
| Terragrunt | ❓ | Gera múltiplos `.tfstate` por módulo |
| OpenTofu | ❓ | Fork open source do Terraform — formato compatível? |
| Pulumi | ❌ | Stack diferente, formato de state diferente |
| CDK for Terraform | ❓ | Gera HCL, deveria ser compatível |

A pergunta "suporta Terragrunt?" virá de 60% dos clientes enterprise. Terragrunt usa uma estrutura de estados fragmentados por módulo que não é trivial de agregar.

---

## Expectativas e Recomendações

### Imediato (Sprint 2)
1. Definir formalmente quais campos do `.tfstate` real serão parseados
2. Adicionar `type`, `address`, `depends_on`, e `child_modules` ao modelo de dados
3. Validar o parser com um `.tfstate` real (com dados sanitizados, sem IPs ou credenciais)

### Médio Prazo (Sprint 3-4)
4. Definir se o produto usará apenas `.tfstate` ou também `terraform graph` output
5. Mapear os 5 casos de uso críticos e garantir que a arquitetura os suporta
6. Testar com Terragrunt (estados fragmentados)

### Crítica Construtiva Central

O motor foi construído para mover retângulos com `int32`. Um estado Terraform real tem strings de comprimento variável, hierarquias de módulos de profundidade arbitrária, múltiplos providers, e dependências que atravessam módulos. **A transição do fixture sintético para dados reais será o próximo grande desafio técnico** — e ele não está no roadmap ainda.

**Score de Adequação ao Domínio: 4/10 para dados sintéticos / Promissor para o produto real**
*(O motor é sólido; o modelo de dados precisa urgentemente de alinhamento com a realidade do Terraform)*
