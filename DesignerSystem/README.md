# GESTAO DE PROJETOS

Designmare System para GESTAO DE PROJETOS, focada em produtos de alta qualidade e inovação.

> Generated with **Tokenforge** — a professional design system generator.

## Files

- `tokens.json` — W3C Design Tokens (Style Dictionary, Figma Tokens compatible)
- `index.css` — CSS variables + Tailwind directives
- `tailwind.config.ts` — Tailwind theme extension
- `_variables.scss` — Sass variables

## Usage (Tailwind / React)

1. Copy `index.css` and `tailwind.config.ts` into your project.
2. Import `index.css` in your entry file.
3. Use semantic tokens: `bg-background`, `text-foreground`, `bg-primary`, `shadow-glow`, etc.

## Padrões de Componentes

### Select de Projeto (padrão obrigatório em todas as páginas)

Toda página que exibe um seletor de projetos deve seguir este padrão:

```vue
<select v-model="projetoId" class="px-3 py-2 border rounded-lg text-sm">
  <option value="">Selecione um projeto...</option>
  <option v-for="p in lojaProjetos.projetos" :key="p.id" :value="p.id">
    {{ p.nome }}
  </option>
</select>
```

**Regras:**
- `px-3 py-2` — padding padrão
- `border rounded-lg` — borda com cantos arredondados
- `text-sm` — tamanho de fonte padrão
- Nome completo exibido — sem truncação manual
- Sem width fixo — adapta ao container pai

**Páginas que usam este padrão:** `index.vue`, `backlog.vue`, `kanban.vue`, `sprints.vue`, `equipe.vue`

---

## Color Palette

- **background**: `hsl(0 0% 100%)`
- **foreground**: `hsl(222 47% 11%)`
- **card**: `hsl(0 0% 100%)`
- **cardForeground**: `hsl(222 47% 11%)`
- **primary**: `hsl(221 83% 53%)`
- **primaryForeground**: `hsl(210 40% 98%)`
- **secondary**: `hsl(210 40% 96%)`
- **secondaryForeground**: `hsl(222 47% 11%)`
- **muted**: `hsl(210 40% 96%)`
- **mutedForeground**: `hsl(215 16% 47%)`
- **accent**: `hsl(262 83% 58%)`
- **accentForeground**: `hsl(210 40% 98%)`
- **destructive**: `hsl(0 84% 60%)`
- **destructiveForeground**: `hsl(0 0% 100%)`
- **border**: `hsl(214 32% 91%)`
- **input**: `hsl(214 32% 91%)`
- **ring**: `hsl(221 83% 53%)`

## Typography

- Display: Space Grotesk
- Body: Inter
- Mono: JetBrains Mono
- Base size: 16px · Scale: 1.25
