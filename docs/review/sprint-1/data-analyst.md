# Review — Data Analyst
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Ana Ferreira, Data Analyst Sênior
**Data:** 2026-03-26

---

## Perspectiva de Dados e Métricas

Minha especialidade é transformar dados em insights acionáveis. Analiso o Sprint 1 sob a lente de: qualidade dos dados de benchmark, metodologia de medição, validade estatística dos resultados, e oportunidades de instrumentação futura.

---

## Análise da Qualidade dos Dados de Benchmark

### PRT-01: Parse de 50k Nós em 70ms

**O que foi medido:** Tempo total de execução da função `callParseInProcess` para uma entrada de 50.000 nós.

**Problemas metodológicos identificados:**

1. **Amostra única (N=1):** O teste roda a função uma vez e mede o tempo. Em benchmarking de performance, uma única amostra é estatisticamente inútil — o resultado pode ser dominado por variações de contexto (CPU scheduling, page faults, estado do cache L1 na primeira execução, etc.).

   **Recomendação:** Rodar o `BenchmarkParseTFState` do Go com `go test -bench=. -count=10 -benchtime=5s` para obter média, desvio padrão e coeficiente de variação. O resultado de 70ms precisa de ±Xms para ser interpretável.

2. **"Primeiro run" vs "steady state":** O `json.Unmarshal` do Go faz lazy compilation de reflection internamente na primeira chamada. Runs subsequentes são mais rápidos. O teste reporta o **warmup run** como resultado, não o steady-state. Para comparação justa com alternativas, precisamos de runs pós-warmup.

3. **Hardware não documentado:** Os benchmarks foram executados em qual hardware? CPU, RAM, tipo de disco (SSD/NVMe?), sistema operacional, outros processos rodando? Esses fatores afetam profundamente os números. Um benchmark sem especificação de hardware é irreproduzível externamente.

---

### PRT-02: Speedup SoA vs AoS (12.45×)

**O que foi medido:** Média de 100 runs do loop de soma `x + y` para 50.000 nós, comparando `ArrayList` (AoS) vs `MultiArrayList` (SoA).

**O que a metodologia fez bem:**
- ✅ N=100 runs — adequado para reduzir ruído de scheduling
- ✅ Sink variable para evitar dead-code elimination pelo compilador
- ✅ ReleaseFast para benchmarking realista com vetorização SIMD
- ✅ Reset do RNG com mesma seed para dados idênticos em ambos os layouts

**Problemas identificados:**

1. **Ausência de desvio padrão:** A métrica reportada é apenas a média. Com 100 runs, temos dados suficientes para calcular std dev, P50, P95, P99. Um outlier de 200µs em uma run de 5µs inflaciona a média. Preciso dos percentis para confiar no número.

2. **O "efeito inicial" não foi controlado:** As primeiras iterações de ambos os benchmarks podem ter page faults enquanto a memória é mapeada. Isso beneficia artificialmente o segundo benchmark (SoA) que roda depois que as páginas já foram carregadas.

   **Recomendação:** Adicionar um loop de warmup de 10 runs descartadas antes de iniciar a medição em ambos.

3. **O padding de metadados é artificial:** O `TFNode` tem `name[32]u8` e `resource_type[16]u8` adicionados deliberadamente para exacerbar o cache miss do AoS. Um struct mais realista precisaria de validação com o PM/Architect sobre quais campos realmente estarão no struct de produção. **O speedup de 12.45× pode ser inflado artificialmente** pelo tamanho do padding.

---

## Dados que Estão Faltando e Que Precisarei

Para os dashboards de acompanhamento do produto, vou precisar que os benchmarks futuros capturem e exportem:

| Métrica | Formato | Ferramenta |
|---|---|---|
| Latência de parse (P50/P95/P99) | JSON ou CSV | `go test -bench -json` |
| L1 cache miss rate | % | `perf stat` |
| Throughput (nós/ms) | Número | Calculado |
| Consumo de memória (peak RSS) | MB | `/usr/bin/time -v` ou `valgrind` |
| CPU utilization por fase | % | `pprof` (Go) |
| Tempo de deinit da Arena | µs | Timer em Zig |

Sem esses dados estruturados e em formato exportável, não consigo construir tendências entre sprints. Um número isolado de "12.45×" não me diz se estamos melhorando ou piorando sprint a sprint.

---

## Proposta: Dashboard de Performance

Proponho criar um arquivo `docs/benchmarks/sprint-N.json` ao final de cada sprint com os resultados brutos dos benchmarks, incluindo hardware spec. Isso me permitirá:

1. Acompanhar regressões de performance entre sprints
2. Projetar performance em hardware de produção
3. Construir visualizações de tendência para o board

```json
{
  "sprint": 1,
  "date": "2026-03-26",
  "hardware": {
    "cpu": "Intel i7-XXXXX",
    "ram_gb": 16,
    "os": "Ubuntu 24.04"
  },
  "prt01": {
    "parse_50k_ms_mean": 70.78,
    "parse_50k_ms_stddev": null
  },
  "prt02": {
    "aos_avg_us": 70,
    "soa_avg_us": 5,
    "speedup": 12.45
  }
}
```

---

## Conclusão

Os resultados do Sprint 1 são **promissores mas metodologicamente incompletos** para análise rigorosa. O speedup de 12.45× é impressionante, mas sem desvio padrão, especificação de hardware, e controle de warmup, não consigo atribuir confiança estatística a esse número. Para os próximos sprints, preciso de benchmarks mais instrumentados para fazer meu trabalho adequadamente.

**Score de Qualidade de Dados: 5/10**
*(Direção certa, metodologia precisa de maturação)*
