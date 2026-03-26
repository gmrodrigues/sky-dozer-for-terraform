# Review — Sales Specialist
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Sales Specialist (Enterprise Accounts)
**Data:** 2026-03-26

---

## Perspectiva de Vendas

Sou responsável por fechar contratos com empresas que gerenciam infraestrutura Terraform em escala — equipes de plataforma com 10-100 engenheiros, ambientes com centenas a dezenas de milhares de recursos. Minha análise foca no que posso ou não posso vender com base no que foi entregue.

---

## O Que Posso Usar em Uma Conversa de Vendas

### Os Números São Vendáveis
"Nossa engine analisa e renderiza 50.000 componentes de infraestrutura Terraform em 70 milissegundos" é uma frase de vendas poderosa. Para comparação, o Rover — a alternativa gratuita mais popular — frequentemente trava o browser com grafos acima de 200 recursos. O Pluralith gera PDFs estáticos sem interação.

**Comprador típico:** Head of Platform Engineering em uma empresa com 300+ engenheiros usando Terraform. Essa pessoa tem *exatamente* a dor que estamos resolvendo e vai entender instintivamente o valor de "70ms vs 30 segundos de carregamento".

### A Narrativa Técnica Está Clara
O material técnico produzido (journal, diagramas, benchmarks) é suficientemente rico para construir um *solution brief* para vendas enterprise. Posso transformar o `sprint-1.md` em um one-pager de 2 páginas para executivos técnicos.

---

## O Que NÃO Posso Vender Ainda

### Sem Demo = Sem Deal
Esta é a realidade do enterprise sales: sem algo para mostrar, não existe conversa. O ciclo de vendas enterprise exige POC (Proof of Concept) com dados do cliente. Hoje não tenho sequer um screenshot para colocar num deck.

**Impacto direto:** Tenho 3 leads enterprise quentes que aguardam material. Se não tiver demo em 6-8 semanas, vou perdê-los para o Pluralith ou para soluções custom internas que estão desenvolvendo.

### Perguntas Que Não Consigo Responder Ainda

Os compradores enterprise vão fazer as seguintes perguntas, e hoje não consigo responder nenhuma:

| Pergunta do Comprador | Status |
|---|---|
| "Funciona com Terraform Cloud / Enterprise?" | ❓ Não definido |
| "Tem single sign-on (SSO)?" | ❓ Não planejado |
| "Onde os dados ficam armazenados? On-prem possível?" | ❓ Não definido |
| "Qual o SLA de suporte?" | ❓ Não definido |
| "Tem API para integrar com nosso CMDB?" | ❓ Não planejado |
| "Funciona com Terragrunt?" | ❓ Não testado |

Sem respostas para essas perguntas, não consigo avançar no processo de compra de nenhum enterprise.

---

## Análise Competitiva na Perspectiva de Vendas

| Critério | Rover | Pluralith | terraform-panel (projetado) |
|---|---|---|---|
| Preço | Gratuito / Open Source | $99-499/mês | A definir |
| Escala | Até ~200 recursos fluído | Ilimitado (estático) | 50k+ fluído ✅ |
| Interatividade | SVG estático | PDF estático | ZUI interativo |
| Enterprise features | Nenhuma | Limitada | A construir |
| Demo disponível | Sim | Sim | **Não ainda** |

Nossa vantagem diferencial é clara na coluna de escala e interatividade — mas ela não é comercializável até que exista algo para mostrar.

---

## Pedidos ao Time de Produto

1. **Tela de loading com dados sintéticos até o Sprint 2** — mesmo feio, com apenas retângulos e IDs, já me dá algo para mostrar
2. **Landing page ou teaser page** — "produto em Early Access, cadastre-se para ser notificado" me ajuda a capturar os leads quentes agora
3. **Definir modelo de preços preliminar** — os compradores enterprise sempre perguntam "é SaaS ou self-hosted, e qual o custo?" no primeiro contato

**Score de Vendabilidade Atual: 3/10**
*(Narrativa técnica forte, zero material de vendas concreto — normal para Sprint 1, mas precisa mudar urgentemente)*
