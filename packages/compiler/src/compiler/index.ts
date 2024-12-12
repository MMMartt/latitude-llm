import { ConversationMetadata } from '$compiler/types'
import { z } from 'zod'

import { type Document, type ReferencePromptFn } from './readMetadata'
import yaml from 'yaml'
import type { PromptFile } from '@monica/prompt-parser-wasm/dist/src/schema'
import OpenAI from 'openai'
import { convertReqToChainStep } from '$compiler/compiler/chain'

export async function readMetadata({
  prompt,
}: {
  prompt: string
  fullPath?: string
  referenceFn?: ReferencePromptFn
  withParameters?: string[]
  configSchema?: z.ZodType
}): Promise<ConversationMetadata> {
  const promptFile = yaml.parse(prompt) as PromptFile
  const parameters = new Set<string>()
  try {
    Object.keys(promptFile.input_schema.properties).forEach((k) =>
      parameters.add(k),
    )
  } catch (_) {
    //
  }
  return {
    config: {},
    errors: [],
    parameters,
    includedPromptPaths: new Set<string>(),
    resolvedPrompt: prompt,
  } as never as ConversationMetadata
}

function createChain(
  req: OpenAI.Chat.ChatCompletionCreateParams,
  prompt: string,
) {
  console.log({ req, prompt })
  return {
    rawText: prompt,
    step: async () => {
      const ret = convertReqToChainStep(req, prompt)
      return ret
    },
    completed: true,
  }
}

export { type Document, type ReferencePromptFn, createChain }
