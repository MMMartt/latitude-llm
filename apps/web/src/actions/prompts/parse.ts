'use server'
import { parsePrompt, init } from '@monica/prompt-parser-wasm'
import type { OpenAI } from 'openai'
import path from 'node:path'

export async function parsePromptServer(
  prompt: string,
  input: any,
): Promise<{
  result?: OpenAI.Chat.ChatCompletionCreateParams
  error?: string
}> {
  try {
    const wasmPath = path.resolve(
      process.cwd(),
      './node_modules/@monica/prompt-parser-wasm/dist/wasm/main.wasm',
    )
    await init({ wasmPath })
    const parser = await parsePrompt(prompt)
    const r = parser.render({
      ...Object.entries(input).reduce(
        (acc: Record<string, any>, [key, value]): Record<string, any> => {
          try {
            acc[key] = JSON.parse(value as any)
            return acc
          } catch (_) {
            acc[key] = value
            return acc
          }
        },
        {},
      ),
    }) as any
    return { result: r }
  } catch (e) {
    // console.error(e)
    // console.log('xxxxxxxxxx', e)
    return { error: e instanceof Error ? e.message : String(e) }
  }
}
