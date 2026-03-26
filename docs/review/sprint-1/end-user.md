# Review — End User (Engenheira de Plataforma)
**Sprint 1 | terraform-panel ZUI Motor**
**Revisor:** Marina Souza, Engenheira de Plataforma Sênior
**Contexto:** Gerencio a infraestrutura Terraform de uma organização com ~800 recursos ativos. Usuária-alvo direta desta ferramenta.
**Data:** 2026-03-26

---

## Minha Perspectiva Como Quem Vai Usar Isso Todo Dia

Deixa eu ser honesta: quando recebi o relatório do Sprint 1, minha primeira reação foi "benchmarks de terminal... ótimo, mais uma ferramenta que os devs acham incrível e ninguém consegue usar". Mas li o material com cuidado e mudei de opinião sobre *por que* isso importa.

Vou explicar o que me preocupa e o que me empolga, como alguém que passa horas por dia tentando entender o estado da minha infraestrutura.

---

## O Problema Real Que Preciso Resolver

Toda vez que o time de produto pede "quantas instâncias EC2 temos no ambiente de staging?", eu preciso:
1. Rodar `terraform state list | grep aws_instance` 
2. Exportar para JSON com `terraform show -json`
3. Abrir o JSON de 40MB num editor
4. Torcer para que o Rover não trave meu browser

O Rover trava. Sempre trava. Com mais de 200 recursos, o SVG que ele gera tem tantos elementos DOM que o Chrome engasga e fica iresponsivo por minutos. O Pluralith é melhor mas gera um PDF estático — sem zoom, sem interação, sem pesquisa.

**O que eu quero:** um mapa interativo onde eu possa navegar pela minha nuvem como navego pelo Google Maps. Aproximar para ver uma VPC, afastar para ver módulos inteiros, filtrar por tag ou tipo de recurso.

---

## O Que o Sprint 1 Significa Para Mim

### O Número Que Me Importa: 70ms

Eu não sei o que é uma bridge FFI. Mas sei que 70ms significa que quando eu abrir minha infra de 800 recursos, ela vai carregar **antes de eu tirar meu dedo do mouse**. Com o Rover, espero 15-30 segundos. Com o Pluralith, às vezes minutos.

Se vocês conseguiram 70ms para 50k recursos com dados sintéticos, 800 recursos reais devem ser praticamente instantâneos. Isso muda completamente minha experiência diária.

### O Número Que Me Preocupa: 0 (telas entregues)

Com todo o respeito ao esforço técnico, depois de um sprint inteiro eu ainda não tenho **nada para abrir no meu computador**. Sei que isso é uma PoC de performance, e tecnicamente faz sentido. Mas do ponto de vista de quem vai usar:

- Eu não consigo validar se o layout vai fazer sentido para mim
- Não sei se vou conseguir encontrar um recurso específico entre 50k nós
- Não sei se o zoom semântico vai funcionar de forma intuitiva ou vai ser confuso

**Meu pedido para os próximos sprints:** mesmo que seja um protótipo feio, me mostre alguma tela. Um wireframe clicável. Algo que eu possa colocar na mão de um colega e perguntar "você conseguiria encontrar a VPC de produção aqui?".

---

## Funcionalidades Que Não Vi No Roadmap e Que Preciso

1. **Pesquisa por nome de recurso:** Com 800 recursos, navegar visualmente sem busca é impraticável
2. **Filtro por tipo:** Quero ver só os `aws_security_group` que atravessam múltiplas VPCs
3. **Estado de drift visual:** Recurso que divergiu do estado esperado deveria aparecer destacado
4. **Integração com `terraform plan`:** Quero ver *antes* de aplicar quais recursos vão mudar e como o grafo vai se transformar
5. **Export de subgrafo:** Às vezes preciso compartilhar só a topologia de uma VPC específica com o time de segurança

---

## Crítica Construtiva

Vocês estão construindo um motor de Fórmula 1 sem me consultar sobre qual pista vou correr. O motor pode ser tecnicamente perfeito e eu ainda assim me perder na interface.

**Meu pedido:** inclua pelo menos uma sessão de entrevista de usuário por sprint. Não precisa ser longa — 30 minutos comigo ou com outro engenheiro de plataforma para validar que as decisões de UX fazem sentido para quem vai usar no dia a dia.

**Nota do Usuário Final: 5/10 para esta sprint especificamente**
*(Nota para o produto completo: potencial para 10/10 se as promessas técnicas se confirmarem na UI)*
