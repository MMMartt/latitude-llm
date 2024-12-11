'use server'
import { parsePrompt, init } from '@monica/prompt-parser-wasm'
import type { OpenAI } from 'openai'
import path from 'node:path'

export async function parsePromptServer(
  prompt: string,
  input: any,
): Promise<OpenAI.Chat.ChatCompletionCreateParams> {
  const wasmPath = path.resolve(
    process.cwd(),
    '../../node_modules/@monica/prompt-parser-wasm/dist/wasm/main.wasm',
  )
  await init({ wasmPath })

  const parser = await parsePrompt(prompt)
  console.log({ parser })
  return parser.render(input) as any
}
