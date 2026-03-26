# Prompts — Sprint 1 Delivery
**Projeto:** terraform-panel / Motor ZUI de Alta Performance para IaC
**Sessão:** 2026-03-26
**Agente:** Antigravity (Google DeepMind)

Este documento registra todos os prompts enviados ao agente de IA durante a entrega do Sprint 1, em ordem cronológica, com contexto e resultado de cada um.

---

## P-01 — Leitura da documentação do projeto

**Prompt:**
> hello. read the docs and get to know the project

**Contexto:** Início da sessão. O usuário tinha abertos `PRT.md`, `PTEC.md` e `Sprints.md`.

**Resultado:** Agente leu os três documentos de arquitetura e produziu um resumo estruturado cobrindo: objetivo do projeto (ZUI para Terraform com 50k+ recursos a 60 FPS), stack tecnológica (Zig + Go c-shared), os 4 gates de validação da PoC (PRT-01 a PRT-04) e o plano de sprints.

---

## P-02 — Quebra do Sprint 1 em tarefas e criação de testes

**Prompt:**
> break print 1 in tasks and write tests

**Contexto:** Usuário queria decompor o Sprint 1 em tarefas concretas e ter os testes escritos.

**Resultado:** Agente entrou em modo PLANNING, criou `task.md` e `implementation_plan.md` com:
- Fase 1: Scaffold (Go module + Zig project)
- Fase 2: Go Bridge com `ParseTFState` exportado via C ABI
- Fase 3: Zig engine com `ArenaAllocator` e teste de integração
- Fase 4: Benchmark SoA (`MultiArrayList`) vs AoS (`ArrayList`)
- Fase 5: Gerador de dados sintéticos (50k nós `.tfstate`)

Plano enviado para review antes da execução.

---

## P-03 — Aprovação do plano (implícita)

**Prompt:** *(O usuário aprovou o `implementation_plan.md` sem texto adicional)*

**Resultado:** Agente iniciou modo EXECUTION. Verificou versões instaladas (Go 1.25.6 confirmado, Zig não encontrado). Iniciou criação dos arquivos Go em paralelo com a instalação do Zig.

---

## P-04 — Zig instalado, rode agora

**Prompt:**
> i installed zig, now run it

**Contexto:** O usuário havia tentado `zig build bench` na raiz do projeto e recebeu erro `no build.zig file found`. O Zig instalado era a versão 0.15.2 (não 0.14.0 conforme planejado).

**Resultado:** Agente identificou que:
1. O comando foi executado no diretório errado (raiz vs `zig-engine/`)
2. O Zig 0.15.x quebrou 4 APIs em relação ao 0.14.0 planejado:
   - `addTest`/`addExecutable` → `root_module: *Module`
   - `std.ArrayList` → unmanaged (allocator por chamada)
   - `std.rand` → `std.Random`
   - `std.io.getStdOut()` → removido

Agente corrigiu `build.zig` e `soa_bench.zig` iterativamente e rodou com sucesso:
```
PRT-02 PASS  SoA é 12.45× mais rápido que AoS
```

---

## P-05 — Questionamento sobre Makefile vs build.zig

**Prompt:**
> why we have a makefile where if we are using zig and zig got its own build system?

**Contexto:** Usuário estava com o `Makefile` aberto e questionou a necessidade de dois sistemas de build.

**Resultado:** Agente explicou que o Makefile existe para orquestrar os dois toolchains (`go test`, `go build -buildmode=c-shared`, `zig build`) e que o `build.zig` poderia assumir essa responsabilidade via `b.addSystemCommand()`. Propôs consolidar no Sprint 2, sem alterar nada imediatamente.

---

## P-06 — Como testar os entregáveis do sprint

**Prompt:**
> how can i test the deliverables of the current sprint?

**Resultado:** Agente listou os 2 comandos de validação:
```bash
# PRT-01
cd go-bridge && go test ./... -v -run TestParseTFState -count=1

# PRT-02
cd zig-engine && zig build bench
```
E apresentou a tabela de resultados (PRT-01: 70ms vs 500ms; PRT-02: 12.45× vs 1.40×).

---

## P-07 — Criar journal e relatório de entrega

**Prompt:**
> now create a journal directory inside docs and write a full report about this delivery: objectives and reproduceable steps, highlights and lowlights

**Contexto:** Usuário havia acabado de rodar `make zig-bench` com sucesso, vendo o resultado `12.45×`.

**Resultado:** Agente criou `docs/journal/sprint-1.md` com:
- Objetivos (PRT-01 e PRT-02)
- Árvore de entregáveis
- Passos reproduzíveis (4 comandos)
- Tabelas de resultados com metas vs real
- Highlights: speedup 12.45×, parse em 70ms, FFI segura
- Lowlights: 3 APIs quebradas no Zig 0.15, teste integração Zig pendente, debate Makefile vs build.zig
- Próximos passos para Sprint 2

---

## P-08 — Diagramas PlantUML no journal

**Prompt:**
> crie alguns diagramas em plantuml no report do journal, gere as imagens com a ferramenta plantuml local. As opções de diagrama são: caso de uso, c4 (com plugin), salt (para wireframes), diagrama sequencial e de jornada de usuário, diagrama de integração, diagrama de dependências e mapa mental.

**Resultado:** Agente verificou PlantUML 1.2026.1 disponível em `/usr/local/bin/plantuml` e criou 5 diagramas em `docs/journal/diagrams/`:

| Arquivo | Tipo | Conteúdo |
|---|---|---|
| `ffi-sequence.puml` | Sequencial | Fluxo completo da chamada `ParseTFState` via C ABI |
| `c4-component.puml` | C4 Component | go-bridge, zig-engine, artefatos e relações |
| `dependency-graph.puml` | Dependências | Grafo cross-boundary de todos os módulos |
| `mind-map.puml` | Mapa mental | Conceitos arquiteturais, resultados e riscos |
| `integration-pipeline.puml` | Atividades/Swimlanes | Pipeline de build & test completo |

Todos renderizados com `plantuml -tpng` e embutidos em `sprint-1.md`.

---

## P-09 — Documentar os prompts

**Prompt:**
> agora dentro de docs crie um diretorio chamado prompts e documente todos os prompts usados para esse entrega da sprint 1

**Resultado:** Este arquivo.

---

## P-10 — Regra de documentação contínua de prompts

**Prompt:**
> lembre-se sempre de finalizar cada iteração de prompt com a documentação dos prompts utilizados

**Resultado:** Agente registrou a instrução como regra permanente de processo. A partir deste ponto, ao final de cada resposta que gere artefatos ou altere código, o arquivo `docs/prompts/sprint-N.md` correspondente será atualizado com o novo prompt da iteração.

---

## P-11 — Reviews de 12 stakeholders para o Sprint 1

**Prompt:**
> agora crie um diretorio chamado review. Aga como stakeholders diferentes: PO, TechLead, SecOps, Architect, Finops, EndUser, CEO, Sales Specialist, Lawer, HR person. Jr Developer, Data Analyst. Write differente reports consearing this deliveryy of sprint 1. Be very verbose about expectations and construtive criticism.

**Resultado:** Agente criou `docs/review/` com 12 arquivos de review + `README.md` de índice:

| Arquivo | Stakeholder | Score |
|---|---|---|
| `po.md` | Product Owner | 8.5/10 |
| `tech-lead.md` | Tech Lead | 8/10 |
| `secops.md` | SecOps | 6.5/10 |
| `architect.md` | Architect | 8.5/10 |
| `finops.md` | FinOps | 7.5/10 |
| `end-user.md` | End User (Eng. Plataforma) | 5/10 |
| `ceo.md` | CEO | 7.5/10 |
| `sales.md` | Sales Specialist | 3/10 |
| `lawyer.md` | Advogado | — |
| `hr.md` | HR / People | 8/10 |
| `jr-developer.md` | Dev Júnior | 6/10 |
| `data-analyst.md` | Data Analyst | 5/10 |

Cada review cobre: expectativas do stakeholder, o que foi entregue sob sua perspectiva, críticas construtivas específicas, e recomendações para os próximos sprints.

---

## Resumo da Sessão

| # | Prompt | Categoria | Artefatos Gerados |
|---|---|---|---|
| P-01 | Leitura dos docs | Pesquisa | — |
| P-02 | Break Sprint 1 em tasks e tests | Planejamento | `task.md`, `implementation_plan.md` |
| P-03 | Aprovação do plano | Revisão | — |
| P-04 | Rodar Zig | Execução | `bridge.go`, `bridge_test.go`, `gen-tfstate/main.go`, `main.zig`, `soa_bench.zig`, `build.zig`, `Makefile`, `libbridge.so`, `fixture.tfstate.json` |
| P-05 | Makefile vs build.zig? | Questionamento técnico | — |
| P-06 | Como testar entregáveis? | Dúvida operacional | — |
| P-07 | Criar journal com report | Documentação | `docs/journal/sprint-1.md` |
| P-08 | Diagramas PlantUML | Documentação visual | 5 × `.puml` + 5 × `.png` |
| P-09 | Documentar prompts | Meta-documentação | `docs/prompts/sprint-1.md` |
| P-10 | Regra de documentação de prompts | Processo | — |
| P-11 | Reviews de 12 stakeholders | Documentação | 12 × `docs/review/*.md` + `README.md` |
| P-12 | +2 stakeholders + estrutura por sprint | Documentação | `ux-frontend.md`, `domain-specialist.md`, reorganização em `sprint-1/` |
| P-13 | Criar .gitignore | Infra | `.gitignore` (Go + Zig + .tfstate + secrets) |
| P-14 | Criar README do projeto | Documentação | `README.md` |
| P-15 | Atualizar README de reviews | Documentação | `docs/review/README.md` (médias) |

