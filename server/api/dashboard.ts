export default defineEventHandler(async (event) => {
    const token = getHeader(event, 'authorization')

    return await $fetch('http://localhost:54321/functions/v1/listarDashboard', {
        method: 'GET',
        headers: {
            Authorization: token || '',
        },
    })
})