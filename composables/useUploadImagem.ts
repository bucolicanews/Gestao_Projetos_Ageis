// composables/useUploadImagem.ts
export const useUploadImagem = () => {
  const cliente = useSupabaseClient()

  async function uploadAvatar(userId: string, arquivo: File): Promise<string> {
    const ext = arquivo.name.split('.').pop()
    const path = `${userId}/avatar.${ext}`

    const { error } = await cliente.storage
      .from('avatars')
      .upload(path, arquivo, { upsert: true, contentType: arquivo.type })

    if (error) throw error

    const { data } = cliente.storage.from('avatars').getPublicUrl(path)
    return `${data.publicUrl}?t=${Date.now()}`
  }

  async function uploadLogo(orgId: string, arquivo: File): Promise<string> {
    const ext = arquivo.name.split('.').pop()
    const path = `${orgId}/logo.${ext}`

    const { error } = await cliente.storage
      .from('logos')
      .upload(path, arquivo, { upsert: true, contentType: arquivo.type })

    if (error) throw error

    const { data } = cliente.storage.from('logos').getPublicUrl(path)
    return `${data.publicUrl}?t=${Date.now()}`
  }

  return { uploadAvatar, uploadLogo }
}
