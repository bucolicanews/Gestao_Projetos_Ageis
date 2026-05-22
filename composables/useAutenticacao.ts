// composables/useAutenticacao.ts
export const useAutenticacao = () => {
  const cliente = useSupabaseClient()
  const usuario = useSupabaseUser()

  async function entrar(email: string, senha: string) {
    const { error } = await cliente.auth.signInWithPassword({ email, password: senha })
    if (error) throw error
  }

  async function cadastrar(email: string, senha: string, nome: string) {
    const redirect = typeof window !== 'undefined'
      ? `${window.location.origin}/confirmar`
      : undefined
    const { error } = await cliente.auth.signUp({
      email, password: senha,
      options: { data: { nome }, emailRedirectTo: redirect },
    })
    if (error) throw error
  }

  async function sair() {
    await cliente.auth.signOut()
  }

  return { usuario, entrar, cadastrar, sair }
}
