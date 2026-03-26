# Review — HR (People & Culture)
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Head de People & Culture
**Data:** 2026-03-26

---

## Perspectiva de Pessoas e Cultura Organizacional

Minha análise do Sprint 1 não é sobre código ou performance — é sobre as **pessoas** que produziram esse trabalho, o **ambiente** em que estão trabalhando, e os **riscos humanos** que podem comprometer os próximos sprints.

---

## O Que Me Chamou Atenção Positivamente

### Cultura de Documentação Sólida

A equipe produziu neste sprint, além do código:
- Um plano de implementação revisado antes da execução
- Um journal de entrega com resultados detalhados
- 5 diagramas técnicos
- Um log de todos os prompts utilizados
- 12 reviews de stakeholders (incluindo este)

Isso é um sinal de uma equipe que valoriza comunicação e transparência — a base de uma cultura de engenharia saudável. Em muitas equipes de desenvolvimento, a documentação é tratada como tarefa extra ou é ignorada. Aqui ela é parte orgânica do processo.

### Resiliência a Obstáculos Inesperados

O Zig 0.15 quebrou 4 APIs que não estavam previstas. A equipe identificou, investigou, corrigiu e documentou os problemas **dentro do mesmo sprint**, sem pânico ou escalação desnecessária. Isso indica maturidade técnica e emocional — skills muito mais difíceis de contratar do que conhecimento específico de linguagem.

---

## Preocupações de Pessoas

### 1. Concentração de Conhecimento (Bus Factor)

Revisando os entregáveis, percebo que a expertise em Zig, Go c-shared e a arquitetura da bridge FFI está concentrada em um número muito pequeno de pessoas (possivelmente uma). Isso cria o que chamamos de **"bus factor 1"** — se essa pessoa for afastada (doença, férias, desligamento), o projeto para.

**Recomendação:**
- Sessões de pair programming para distribuir conhecimento do `go-bridge` e `zig-engine`
- Pelo menos uma sessão de "lunch and learn" sobre a arquitetura FFI para o restante da equipe
- Garantir que a documentação seja suficientemente detalhada para que um novo dev consiga contribuir sem depender do conhecimento tácito de uma única pessoa

### 2. Stack com Alta Curva de Aprendizado

Zig é uma linguagem jovem e em rápida evolução (como evidenciado pelas 4 quebras de API em uma versão). Go com cgo/unsafe já é uma área que assusta desenvolvedores mais juniores. A combinação dessas duas, com interoperabilidade de memória manual, é **uma das combinações mais difíceis de encontrar em um candidato** no mercado.

**Implicações de hiring:**
- Contratar um desenvolvedor com experiência em Go + Zig + sistemas é extremamente difícil hoje. Existem poucos profissionais com esse perfil no Brasil
- O tempo de onboarding de um desenvolvedor novo para ser produtivo nessa stack é provavelmente 3-6 meses
- **Custo por contratação estimado:** significativamente acima da média de mercado para engenheiro de software

**Recomendação:** Criar um plano de crescimento interno — identificar desenvolvedores com background em C/C++ ou Rust que possam ser treinados em Zig antes de abrir posição no mercado.

### 3. Saúde e Sustentabilidade do Ritmo

Há evidências no log de prompts de que várias iterações de debugging aconteceram em sequência rápida dentro de uma única sessão. Isso é normal em sprints de PoC, mas preciso garantir que não se torne o padrão sustentado.

**Sinais que preciso monitorar:**
- O time está fazendo pausas adequadas entre sessões intensas de debugging?
- O escopo dos sprints é realista ou estamos consistentemente fazendo mais do que o planejado?

---

## Recomendações para o Próximo Sprint

1. **Pair programming document:** designar quem está "shadowing" cada componente crítico
2. **Onboarding guide preliminar:** 1 página sobre como configurar o ambiente de desenvolvimento (Zig + Go + PlantUML) para um dev novo
3. **Retrospectiva formal ao final do Sprint 2:** não apenas revisão técnica, mas como a equipe se sentiu — o que funcionou no processo, o que foi frustrante
4. **Clareza de papéis:** com 12 stakeholders diferentes revisando o sprint, a equipe precisa saber claramente quem tem autoridade para tomar quais decisões

**Score People & Culture: 8/10**
*(Cultura de documentação e resiliência exemplares; riscos de bus factor e hiring precisam de atenção)*
