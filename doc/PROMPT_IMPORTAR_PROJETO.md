
# Prompt — Gerar Projeto Completo para Importação

Use este prompt em qualquer LLM (Claude, ChatGPT, Gemini) para gerar um projeto
completo no formato JSON pronto para importar no sistema GESTAO_PROJTOS_VUE.

## Como_usar

1. Copie o bloco **PROMPT** abaixo
2. Substitua `[DESCREVA SEU PROJETO AQUI]` pela descrição do que você quer construir
3. Cole no Claude / ChatGPT / Gemini e envie
4. Copie o JSON gerado e salve como arquivo `.json`
5. No sistema, acesse **Projetos → ↑ Importar JSON** e selecione o arquivo

---

## PROMPT

```
Você é um especialista em gestão ágil de projetos de software.

Gere um projeto completo no formato JSON abaixo para o seguinte sistema:

[DESCREVA SEU PROJETO AQUI]

Exemplo de descrição:
"Sistema de e-commerce com catálogo de produtos, carrinho, checkout com pagamento PIX e cartão,
painel administrativo para gestão de pedidos e relatórios de vendas. Stack: Vue 3 + Node.js + PostgreSQL."

---

REGRAS OBRIGATÓRIAS:

1. Crie de 3 a 5 sprints de 2 semanas cada, com datas reais a partir de hoje
2. Distribua as tarefas entre as sprints de forma lógica (fundação primeiro, features depois)
3. Cada sprint deve ter entre 4 e 8 tarefas principais
4. Tarefas técnicas devem ter sub-tarefas detalhadas (2 a 4 por tarefa)
5. Todas as tarefas iniciam com coluna "backlog" ou "a_fazer"
6. Use ref_ids sequenciais: sprint_1, sprint_2... / tarefa_1, tarefa_2... / sub_1, sub_2...
7. Varie as prioridades de forma realista (urgente para bloqueadores, baixa para melhorias)
8. Adicione 2 a 4 anotações com decisões técnicas ou contexto importante do projeto
9. Deixe os campos email em branco ("") — serão preenchidos após importação
10. Responda APENAS com o JSON válido, sem texto antes ou depois

---

VALORES VÁLIDOS (use exatamente esses):

status do projeto:   ativo | pausado | concluido | arquivado
status da sprint:    planejada | ativa | concluida
coluna da tarefa:    backlog | a_fazer | em_progresso | em_revisao | concluido
prioridade:          baixa | media | alta | urgente
papel do membro:     admin | membro

---

ESTRUTURA JSON (preencha todos os campos):

{
  "_meta": {
    "versao": "1.0",
    "exportado_em": "<data e hora atual ISO 8601>",
    "sistema": "GESTAO_PROJTOS_VUE"
  },
  "projeto": {
    "nome": "<nome do projeto>",
    "descricao": "<descrição completa do objetivo>",
    "status": "ativo",
    "membros": []
  },
  "anotacoes": [
    {
      "ref_id": "nota_1",
      "titulo": "<título da decisão ou contexto>",
      "conteudo": "<texto explicando a decisão, contexto ou risco>",
      "criado_em": "<data ISO 8601>"
    }
  ],
  "sprints": [
    {
      "ref_id": "sprint_1",
      "nome": "<nome descritivo ex: Sprint 1 — Fundação>",
      "objetivo": "<objetivo principal desta sprint em 1 frase>",
      "status": "planejada",
      "data_inicio": "<YYYY-MM-DD>",
      "data_fim": "<YYYY-MM-DD>",
      "membros": []
    }
  ],
  "tarefas": [
    {
      "ref_id": "tarefa_1",
      "titulo": "<título claro e acionável>",
      "descricao": "<critérios de aceitação ou detalhes técnicos>",
      "prioridade": "alta",
      "coluna": "backlog",
      "posicao": 1,
      "pontos": 5,
      "prazo": null,
      "sprint_ref": "sprint_1",
      "tarefa_pai_ref": null,
      "responsavel_email": "",
      "comentarios": [],
      "sub_tarefas": [
        {
          "ref_id": "sub_1",
          "titulo": "<título da sub-tarefa técnica>",
          "descricao": "",
          "prioridade": "media",
          "coluna": "a_fazer",
          "posicao": 1,
          "pontos": 2,
          "prazo": null,
          "sprint_ref": "sprint_1",
          "responsavel_email": ""
        }
      ]
    }
  ]
}
```

---

## Exemplos de descrições que funcionam bem

**App mobile de delivery:**
> "Aplicativo de delivery de comida com cadastro de restaurantes, cardápio com fotos,
> pedido com rastreamento em tempo real, pagamento PIX/cartão, avaliação de entregadores.
> Stack: React Native + Supabase."

**Plataforma SaaS B2B:**
> "Plataforma de gestão de RH com módulo de ponto eletrônico, folha de pagamento,
> avaliação de desempenho e portal do colaborador. Stack: Next.js + NestJS + PostgreSQL."

**Sistema interno:**
> "Sistema de controle de estoque para rede de farmácias com entrada/saída de produtos,
> alertas de validade, integração com fornecedores e relatórios de margem. Stack: Vue + Laravel."

---

## Dica: refinamento após importação

Após importar, você pode voltar ao Claude com o projeto já criado e pedir:

```
Tenho um projeto "[nome]" com as seguintes tarefas importadas.
Quero refinar a sprint 2 adicionando tarefas de testes e documentação.
Gere apenas as tarefas novas no mesmo formato JSON (só o array "tarefas").
```
