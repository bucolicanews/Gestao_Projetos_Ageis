export default defineNuxtPlugin(() => {
  const cliente = useSupabaseClient()
  const publicas = ['/login', '/cadastro', '/recuperar-senha', '/confirmar', '/apresentacao', '/planos', '/assinar']

  cliente.auth.onAuthStateChange((event) => {
    if (event === 'SIGNED_OUT') {
      const route = useRoute()
      if (!publicas.includes(route.path)) {
        navigateTo('/apresentacao')
      }
    }
  })
})
