// middleware/auth.global.ts
// Roda só no cliente para evitar redirect prematuro antes da sessão hidratar.
export default defineNuxtRouteMiddleware((to) => {
  if (import.meta.server) return

  const usuario = useSupabaseUser()
  const publicas = ['/login', '/cadastro', '/recuperar-senha', '/confirmar', '/apresentacao', '/planos', '/assinar']

  // Se não está logado e a rota é privada -> manda pro login
  if (!usuario.value && !publicas.includes(to.path)) {
    return navigateTo('/apresentacao')
  }

  // Se já está logado e tenta abrir login/cadastro -> manda pro dashboard
  if (usuario.value && (to.path === '/apresentacao' || to.path === '/cadastro')) {
    return navigateTo('/')
  }
  // Rotas /develop/* requerem develop_admin — verificado no composable useDevelopAdmin() de cada página
})
