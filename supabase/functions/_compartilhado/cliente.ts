import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export async function obterUsuario(req: Request) {
  const supa = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: {
        headers: {
          Authorization: req.headers.get('Authorization') || '',
        },
      },
    }
  )

  const {
    data: { user },
    error,
  } = await supa.auth.getUser()

  if (error || !user) {
    throw new Error('Usuário não autenticado')
  }

  return { supa, user }
}