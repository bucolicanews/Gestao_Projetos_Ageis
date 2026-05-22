// server/api/saude.get.ts — endpoint Nitro de health-check
export default defineEventHandler(() => ({
  status: 'ok',
  servico: 'gestao-ageis-nuxt',
  horario: new Date().toISOString(),
}))
