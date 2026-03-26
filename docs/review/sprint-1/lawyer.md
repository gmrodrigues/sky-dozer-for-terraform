# Review — Legal / Advogado
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Advogado Corporativo (TI & Contratos)
**Data:** 2026-03-26

---

## Avaliação Jurídica do Sprint 1

Minha função é identificar riscos jurídicos antes que se tornem problemas. Analisei os entregáveis do Sprint 1 sob as perspectivas de propriedade intelectual, licenciamento de software, proteção de dados, e responsabilidade contratual.

---

## 1. Análise de Licenciamento de Dependências

### Dependências Identificadas

| Componente | Linguagem | Dependências Externas | Licença |
|---|---|---|---|
| `go-bridge` | Go 1.25.6 | Apenas stdlib | BSD-3 (Go stdlib) |
| `zig-engine` | Zig 0.15.2 | Apenas stdlib | MIT (Zig stdlib) |
| `plantuml` | Ferramenta | GPL-3.0 | GPL-3.0 |

**Ponto Positivo:** A ausência de dependências de terceiros nos módulos principais (apenas stdlib Go e Zig) é excelente do ponto de vista de licenciamento. Há risco zero de contaminação GPL, LGPL, ou AGPL no código de produção neste sprint.

**Ponto de Atenção:** O PlantUML é GPL-3.0. Isso é adequado para uso interno de documentação, mas se os diagramas gerados forem incluídos em material de marketing ou em um produto comercial distribuído, há potencial discussão sobre se o output de uma ferramenta GPL é coberto pela GPL. Recomendo documentar o PlantUML como "ferramenta interna de documentação, não como dependência do produto".

---

## 2. Uso da Especificação HCL da HashiCorp

O produto parseia arquivos `.tfstate` — formato proprietário da HashiCorp (empresa do Terraform). É necessário verificar:

1. **Trademark:** "Terraform" é marca registrada da HashiCorp (agora IBM). O nome do produto "terraform-panel" pode infringir a trademark se comercializado sem licença. **Recomendo consulta de trademark antes do lançamento público.**

2. **Licença do formato .tfstate:** O formato `.tfstate` não está explicitamente licenciado como "livre para parsear" — ele é um formato interno. A HashiCorp oferece a `hashicorp/hcl` library sob MPL-2.0, mas o código atual não usa essa biblioteca (usa parser Go interno). Isso evita a MPL-2.0, mas adiciona risco de incompatibilidade com mudanças de formato.

3. **Terms of Service do Terraform Cloud:** Se o produto acessar o Terraform Cloud API para obter estados, os ToS da HashiCorp/IBM precisam ser revisados. Atualmente isso não ocorre (dados sintéticos), mas é uma fronteira que precisa de atenção no produto final.

---

## 3. Proteção de Dados e LGPD/GDPR

O produto, em sua forma final, irá processar arquivos `.tfstate` que contêm:
- Topologia de rede interna (IPs, CIDRs, hostnames)
- Identificadores de recursos cloud (ARNs, Resource IDs)
- Potencialmente: nomes de usuários, tags com emails, outputs de módulos com dados sensíveis

**Riscos LGPD identificados:**
1. Se o produto processar `.tfstate` de clientes em servidores da empresa (modelo SaaS), precisamos de DPA (Data Processing Agreement) com cada cliente
2. Se `.tfstate` contiver dados pessoais (ex: nome de usuário em tag), o produto é um processador de dados pessoais sob LGPD/GDPR

**Recomendação:** Antes do Sprint 3 (quando dados reais serão usados), definir formalmente se o modelo será:
- **Self-hosted (cliente processa seus próprios dados):** risco LGPD mínimo
- **SaaS (processamos dados do cliente):** requer DPA, Privacy Policy, e possivelmente DPO

---

## 4. Propriedade Intelectual do Código

O código do `go-bridge` e `zig-engine` foi desenvolvido com uso de ferramentas de IA (Antigravity). Preciso confirmar:

1. **Quem é o titular dos direitos autorais?** O código gerado com assistência de IA pode ter implicações de autoria. Em muitas jurisdições, o trabalho requer um autor humano para ter proteção de direitos autorais. O código deve ser declarado como de autoria da empresa, com o desenvolvedor humano como responsável editorial.

2. **Existe um arquivo `LICENSE` no repositório?** Não identificado nos entregáveis. Antes de compartilhar qualquer código para clientes (mesmo em PoC), o repositório precisa de um `LICENSE` explícito.

3. **Registro de trade secrets:** As otimizações de performance (SoA 12.45×, bridge FFI) podem ser tratadas como vantagem competitiva. Recomendo que os desenvolvedores assinem NDAs ou acordos de confidencialidade antes de compartilhar benchmarks detalhados externamente.

---

## Resumo de Riscos Jurídicos

| Risco | Severidade | Status |
|---|---|---|
| Trademark "Terraform" no nome do produto | Alta | ⚠️ Não endereçado |
| Ausência de arquivo LICENSE | Média | ⚠️ Não criado |
| Dependências GPL (PlantUML no produto) | Baixa | ✅ Uso interno apenas |
| LGPD/GDPR em modelo SaaS | Alta | ⚠️ Não definido |
| Autoria de código gerado por IA | Média | ⚠️ Não documentado |

**Recomendação Imediata:** Criar `LICENSE` no repositório e rever o nome do produto antes de qualquer comunicação pública.
