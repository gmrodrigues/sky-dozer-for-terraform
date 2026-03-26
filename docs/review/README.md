# Reviews — sky-dozer-for-terraform

Perspectivas de diferentes stakeholders sobre cada sprint, escritas de forma crítica e construtiva. Cada review avalia a entrega sob a lente de quem a lê — técnica, negocial, jurídica, de usuário, de dados.

---

## Estrutura de Diretórios

```
docs/review/
├── README.md           ← este arquivo
└── sprint-1/           ← 14 reviews do Sprint 1
    ├── po.md               Product Owner
    ├── tech-lead.md        Tech Lead
    ├── secops.md           SecOps Engineer
    ├── architect.md        Software Architect
    ├── finops.md           FinOps Engineer
    ├── end-user.md         End User (Engenheira de Plataforma)
    ├── ceo.md              CEO
    ├── sales.md            Sales Specialist (Enterprise)
    ├── lawyer.md           Advogado Corporativo
    ├── hr.md               People & Culture
    ├── jr-developer.md     Desenvolvedor Júnior
    ├── data-analyst.md     Data Analyst
    ├── ux-frontend.md      UX / Frontend Specialist
    └── domain-specialist.md  Especialista em Terraform/IaC
```

---

## Sprint 1 — Fundação de Memória, Go Bridge e MultiArrayList

> **Gate técnico:** FFI Go ↔ Zig (PRT-01) e benchmark SoA vs AoS (PRT-02).
> **Entregáveis:** `go-bridge/`, `zig-engine/`, `libbridge.so`, testes, benchmark, documentação.

| Stakeholder | Foco da Review | Score |
|---|---|---|
| [Product Owner](sprint-1/po.md) | Valor de negócio, roadmap, dívida técnica | 8.5/10 |
| [Tech Lead](sprint-1/tech-lead.md) | Qualidade de código, segurança FFI, Zig 0.15 API | 8/10 |
| [SecOps](sprint-1/secops.md) | Buffer overflow, supply chain, LGPD, auditoria | 6.5/10 |
| [Architect](sprint-1/architect.md) | ADRs, trade-offs, arena vs GC, gaps de longo prazo | 8.5/10 |
| [FinOps](sprint-1/finops.md) | ROI do benchmark, custo de infra, risco de retrabalho | 7.5/10 |
| [End User](sprint-1/end-user.md) | UX esperada, features críticas do dia a dia | 5/10 |
| [CEO](sprint-1/ceo.md) | Estratégia, competidores, milestone de demo em 60 dias | 7.5/10 |
| [Sales Specialist](sprint-1/sales.md) | Vendabilidade enterprise, perguntas sem resposta, urgência de demo | 3/10 |
| [Advogado](sprint-1/lawyer.md) | Trademark "Terraform", LGPD/GDPR, autoria de código IA, LICENSE ausente | — |
| [HR / People](sprint-1/hr.md) | Bus factor, hiring difícil, cultura de documentação, retrospectiva | 8/10 |
| [Dev Júnior](sprint-1/jr-developer.md) | Onboarding, README, `cgo` inacessível, good first issues | 6/10 |
| [Data Analyst](sprint-1/data-analyst.md) | Metodologia de benchmark, std dev ausente, hardware não documentado | 5/10 |
| [UX / Frontend](sprint-1/ux-frontend.md) | Mental model ZUI, design system, interações, acessibilidade WCAG | 4/10 |
| [Domain Specialist](sprint-1/domain-specialist.md) | Fixture sintético vs `.tfstate` real, arestas ausentes, casos de uso | 4/10 |

### Média dos Scores (Sprint 1)

```
Técnico     (TechLead + Architect + SecOps):      7.7 / 10
Negócio     (PO + CEO + FinOps + Sales):           6.8 / 10
Usuário     (EndUser + UX + Domain):               4.3 / 10  ← maior gap
Processo    (HR + JrDev + DataAnalyst):            6.3 / 10
```

> Os scores baixos em "Usuário" são esperados para um sprint de fundação técnica — não há interface. O alerta real é que **os riscos de domínio e design ainda não estão no backlog**.
