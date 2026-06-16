import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js'
import { createClient } from '@supabase/supabase-js'

import { projetosTools, executarProjetosTool } from './tools/projetos.js'
import { tarefasTools, executarTarefasTool } from './tools/tarefas.js'
import { sprintsTools, executarSprintsTool } from './tools/sprints.js'
import { gitTools, executarGitTool } from './tools/git.js'

const ALL_TOOLS = [...projetosTools, ...tarefasTools, ...sprintsTools, ...gitTools]

const url = process.env.SUPABASE_URL
const key = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY

if (!url || !key) {
  process.stderr.write('ERRO: SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios\n')
  process.exit(1)
}

const db = createClient(url, key)

const server = new Server(
  { name: 'gestao-projetos-mcp', version: '1.0.0' },
  { capabilities: { tools: {} } },
)

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: ALL_TOOLS }))

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params
  const toolArgs = args ?? {}

  try {
    const resultado =
      (await executarProjetosTool(name, toolArgs, db)) ??
      (await executarTarefasTool(name, toolArgs, db)) ??
      (await executarSprintsTool(name, toolArgs, db)) ??
      (await executarGitTool(name, toolArgs, db))

    if (resultado === null) {
      return { content: [{ type: 'text', text: `Tool desconhecida: ${name}` }], isError: true }
    }

    return { content: [{ type: 'text', text: JSON.stringify(resultado, null, 2) }] }
  } catch (err) {
    return {
      content: [{ type: 'text', text: `Erro: ${err?.message ?? String(err)}` }],
      isError: true,
    }
  }
})

const transport = new StdioServerTransport()
await server.connect(transport)
process.stderr.write('gestao-projetos MCP rodando via stdio\n')
