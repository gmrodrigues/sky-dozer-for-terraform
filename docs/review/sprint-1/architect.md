# Review — Software Architect
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Arquiteto de Software
**Data:** 2026-03-26

---

## Avaliação Arquitetural

Este sprint atacou corretamente os maiores riscos técnicos da arquitetura antes de construir qualquer UI. A decisão de não escrever uma única linha de renderização antes de validar a pipeline de memória é um sinal de maturidade arquitetural. Minha análise foca nos compromissos de design feitos e nas suas implicações de longo prazo.

---

## Decisões Arquiteturais Avaliadas

### 1. Go como Parser HCL via C-Shared Library

**Decisão:** Compilar o parser Go como `.so` para evitar subprocesso + JSON bridge.
**Avaliação: ✅ Correta, com ressalvas.**

O argumento principal é sólido: eliminar o overhead de serialização JSON para 50k recursos. Porém, há uma tensão arquitetural importante: ao empacotar Go como `.so`, nós carregamos o **runtime inteiro do Go** (incluindo GC, scheduler de goroutines, e thread pool) dentro do processo Zig. Isso significa:

- O processo tem **dois runtimes de memória concorrentes** (Go GC + Zig ArenaAllocator)
- As threads do GC do Go continuarão rodando em background mesmo durante a renderização Zig
- O `GOGC=off` proposto no Sprint 4 mitiga mas não elimina esse overhead

**Alternativa que deveria ser documentada:** Compilar o parser HCL em Zig diretamente, usando a spec pública da gramática HCL. Mais trabalho inicial, mas elimina a dependência do runtime Go em produção. Recomendo que essa alternativa seja registrada como ADR (Architecture Decision Record) com os trade-offs explícitos.

### 2. R-Tree para Culling Espacial (Sprint 2)

**Decisão:** Usar R-Tree em vez de Quadtree.
**Avaliação: ✅ Sólida para o caso de uso.**

Para polígonos sobrepostos (VPC > Subnet > EC2), R-Tree é de fato superior. Porém, a implementação da R-Tree deve ser cuidadosamente integrada com o `MultiArrayList` do Sprint 1. O padrão incorreto seria:

```
R-Tree nó → contém cópia do NodeRecord
```

O padrão correto (que o design já menciona):
```
R-Tree nó folha → contém apenas índice uint32 → MultiArrayList[i]
```

Isso mantém a localidade de cache do SoA intacta. Se a R-Tree armazenar cópias, perdemos o ganho de 12.45× medido no benchmark.

### 3. Layout de Memória: SoA com MultiArrayList

**Decisão:** Usar `std.MultiArrayList(TFNode)` como estrutura primária.
**Avaliação: ✅ Excelente, e os números provam.**

12.45× de speedup com apenas 50 bytes de padding por struct demonstra que o motor da CPU está sendo usado de forma radicalmente mais eficiente. Em hardware moderno com vetorização AVX2 (8 floats por ciclo), o SoA permite que o compilador Zig emita instruções SIMD automáticas para o loop de culling — o que o AoS nunca permitiria.

### 4. ArenaAllocator como Modelo de Ciclo de Vida

**Decisão:** Todo o grafo Terraform vive em uma única Arena, descartada atomicamente.
**Avaliação: ✅ Elegante e correto.**

Isso é o padrão "bump allocator" / "region allocator" clássico de HPC. A implicação importante é que **objetos individuais dentro da arena não podem ser liberados seletivamente**. Para o caso de uso de "recarregar arquivo Terraform", isso é perfeito: descartamos tudo e realocamos. Mas para atualizações incrementais (por exemplo, apenas um módulo Terraform mudou), este modelo é inadequado. A arquitetura precisará de um modelo de "arena por módulo" para o produto completo.

---

## ADRs (Architecture Decision Records) Recomendados

| # | Decisão | Status |
|---|---|---|
| ADR-001 | Go c-shared vs parser Zig nativo para HCL | ⚠️ Não documentado |
| ADR-002 | R-Tree vs Quadtree para culling espacial | ⚠️ Não documentado |
| ADR-003 | SoA via MultiArrayList como layout primário | ⚠️ Não documentado |
| ADR-004 | Arena única vs arenas por módulo | ⚠️ Não documentado |
| ADR-005 | Raylib vs Mach Engine para renderização | ⚠️ Não documentado |

**Recomendação:** Criar `docs/adr/` com um arquivo por decisão antes do Sprint 3, quando as decisões de renderização serão tomadas. ADRs permitem que futuros membros da equipe entendam o *porquê* das escolhas, não apenas o *quê*.

---

## Gaps Arquiteturais Identificados

1. **Sem estratégia de atualização incremental:** O modelo atual é "carga total ou nada". Para um produto que monitore infraestrutura em tempo real, precisamos de um modelo de delta.

2. **Interface de callback não está definida:** Como o motor Zig notifica a UI sobre mudanças de estado? Essa fronteira não foi desenhada ainda.

3. **Sem modelo de persistência de layout:** As posições dos nós no canvas ZUI precisam ser persistidas entre sessões. Isso não é trivial com um modelo de Arena efêmera.

**Score Arquitetural: 8.5/10**
*(Decisões sólidas; lacunas de documentação e gaps de longo prazo identificados)*
