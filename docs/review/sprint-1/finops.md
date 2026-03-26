# Review — FinOps
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** FinOps Engineer
**Data:** 2026-03-26

---

## Perspectiva de Custo e Valor Financeiro

Meu papel como FinOps é garantir que o investimento em engenharia produza retorno mensurável e que as decisões técnicas não criem custos ocultos de infra ou operação. Vou analisar o Sprint 1 sob essa lente.

---

## Custo do Sprint

### Tempo de Engenharia (Estimado)
- Planejamento e design: ~2h
- Implementação Go bridge + testes: ~3h
- Correções de compatibilidade Zig 0.15: ~2h (não previsto)
- Benchmark Zig + correções de API: ~1.5h
- Documentação (journal, diagramas, prompts, reviews): ~2h
- **Total estimado: ~10,5 horas de engenharia**

### Overhead Não Planejado
- Incompatibilidade Zig 0.14 vs 0.15: **~2h de retrabalho** (19% do total do sprint)

Esse overhead é aceitável para um sprint de PoC com linguagem de sistema nova, mas precisa ser incorporado nas estimativas de sprints futuros. **Recomendo adicionar buffer de 20% para sprints envolvendo Zig** até que a equipe acumule fluência com a evolução rápida da linguagem.

---

## Análise de Custo de Infra (PoC vs Produção)

### Custo Zero de Infra Neste Sprint ✅

Um ponto extremamente positivo: **toda a validação foi feita offline com dados sintéticos**. Não há:
- Custos de EC2, EKS, ou qualquer serviço AWS para gerar o grafo de teste
- Custos de egress de dados
- Custos de CI/CD além dos já existentes

Isso foi uma decisão explícita de design correto: a estratégia de gerador sintético (`gen-tfstate`) elimina a dependência de infraestrutura real para validar performance. Isso economiza potencialmente centenas de dólares por sprint em ambientes de teste.

---

## Análise de ROI: O Que os Números Significam

### Benchmark PRT-02: 12.45× de Speedup

Em termos financeiros, esse número tem implicações diretas de custo de infra:

Se o motor fosse rodado em um servidor de renderização dedicado:
- **Com AoS (baseline):** Para suportar 50k nós em 16.6ms, seria necessário hardware significativamente mais robusto
- **Com SoA:** O mesmo throughput é alcançado em hardware ~12× mais modesto

Em termos práticos: **um servidor de $500/mês poderia ser substituído por um de $50/mês** mantendo a mesma performance. Para um produto SaaS servindo dezenas de clientes simultaneamente, isso é um multiplicador enorme.

### Parse em 70ms vs 500ms

O parsing em tempo real de estados Terraform é uma operação que ocorre toda vez que o usuário recarrega o grafo. Em produção:
- 500ms de latência: impacto perceptível no UX, seria necessário loading spinner e feedback visual
- 70ms: imperceptível para o usuário — sub-threshold de percepção humana (~100ms)

Isso tem valor de produto direto: **UX fluido sem custo adicional de infra de cache**.

---

## Riscos Financeiros Identificados

### 1. Vendor Lock-in: Zig ainda é pré-1.0
Zig 0.15 quebrou 4 APIs em relação ao 0.14. Para uma linguagem pré-1.0, isso é esperado — mas representa **risco de retrabalho contínuo**. Cada nova versão do Zig pode exigir N horas de migração. Até o Zig atingir 1.0 estável, recomendo:
- Fixar a versão do Zig no toolchain da equipe (via `zigup` ou Docker)
- Budget de 10% por sprint para atualizações de toolchain

### 2. Custo de Onboarding: Stack Altamente Especializada
A stack Go + Zig + C ABI é incomum. O custo de contratar ou treinar engenheiros com essa combinação é significativamente maior do que stacks mainstream (TypeScript, Python, Rust).

**Recomendação:** A equipe atual deve documentar exaustivamente os padrões de código (o que está sendo feito — ponto positivo) para reduzir o custo de onboarding futuro.

### 3. Sem Modelo de Precificação Definido
Do ponto de vista FinOps, ainda não há modelo de como esse produto será monetizado. Se for SaaS, o custo por usuário precisa ser estimado. Se for self-hosted, o custo de suporte precisa ser calculado.

---

## Recomendações

1. **Documentar custo por sprint** (horas de eng × taxa horária) no journal de entrega
2. **Criar um benchmark de custo de infra estimado** junto com o PRT-03 (R-Tree)
3. **Definir modelo de monetização** antes do Sprint 3 para guiar decisões de arquitetura de escala

**Score FinOps: 7.5/10**
*(Excelente controle de custo de infra na PoC; riscos de retrabalho e stack especializada precisam de gestão ativa)*
