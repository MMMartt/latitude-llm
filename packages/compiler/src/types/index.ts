import CompileError from '$compiler/error/error'
import { Message } from './message'
import { OpenAI } from 'openai'

export type Config = Record<string, unknown>

export type Conversation = {
  config: {
    provider: string
  } & OpenAI.Chat.ChatCompletionCreateParams
  // ChatCompletionMessageParam
  messages: Message[]
}

export type ConversationMetadata = {
  resolvedPrompt: string
  config: Config
  errors: CompileError[]
  parameters: Set<string> // Variables used in the prompt that have not been defined in runtime
  setConfig: (config: Config) => string
  includedPromptPaths: Set<string>
}

export * from './message'
