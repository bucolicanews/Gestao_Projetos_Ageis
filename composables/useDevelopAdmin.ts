// composables/useDevelopAdmin.ts
// Verifica se usuário logado é develop_admin. Redireciona se não for.
export const useDevelopAdmin = () => {
  const router = useRouter()
  const isDevelopAdmin = ref(false)
  const verificando = ref(true)

  onMounted(async () => {
    const perfil = await servicoOrganizacao().meuPerfil()
    isDevelopAdmin.value = perfil?.perfil === 'develop_admin'
    verificando.value = false
    if (!isDevelopAdmin.value) {
      router.push('/')
    }
  })

  return { isDevelopAdmin, verificando }
}
