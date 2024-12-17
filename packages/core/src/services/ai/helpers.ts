import { createAnthropic } from '@ai-sdk/anthropic'
import { createMistral } from '@ai-sdk/mistral'
import { createOpenAI } from '@ai-sdk/openai'
import { Message, MessageRole } from '@latitude-data/compiler'
import { RunErrorCodes } from '@latitude-data/constants/errors'
import { z } from 'zod'
import { OpenAI } from 'openai'

import { Providers } from '../../constants'
import { Result } from '../../lib'
import { ChainError } from '../chains/ChainErrors'

const googleCategorySettings = z.union([
  z.literal('HARM_CATEGORY_HATE_SPEECH'),
  z.literal('HARM_CATEGORY_DANGEROUS_CONTENT'),
  z.literal('HARM_CATEGORY_HARASSMENT'),
  z.literal('HARM_CATEGORY_SEXUALLY_EXPLICIT'),
])
const googleThresholdSettings = z.union([
  z.literal('HARM_BLOCK_THRESHOLD_UNSPECIFIED'),
  z.literal('BLOCK_LOW_AND_ABOVE'),
  z.literal('BLOCK_MEDIUM_AND_ABOVE'),
  z.literal('BLOCK_ONLY_HIGH'),
  z.literal('BLOCK_NONE'),
])

export const googleConfig = z
  .object({
    structuredOutputs: z.boolean().optional(),
    cachedContent: z.string().optional(),
    safetySettings: z
      .array(
        z
          .object({
            category: googleCategorySettings.optional(),
            threshold: googleThresholdSettings.optional(),
          })
          .optional(),
      )
      .optional(),
  })
  .optional()
type GoogleConfig = z.infer<typeof googleConfig>

export type Config = {
  provider: string
} & OpenAI.Chat.ChatCompletionCreateParams

export type PartialConfig = Omit<Config, 'provider'>

const GROQ_API_URL = 'https://api.groq.com/openai/v1'

function isFirstMessageOfUserType(messages: Message[]) {
  const message = messages.find((m) => m.role === MessageRole.user)

  if (message) return Result.nil()

  return Result.error(
    new ChainError({
      code: RunErrorCodes.AIProviderConfigError,
      message: 'Google provider requires at least one user message',
    }),
  )
}

export function createProvider({
  provider,
  messages,
  apiKey,
  url,
  config,
}: {
  provider: Providers
  messages: Message[]
  apiKey: string
  url?: string
  config?: PartialConfig
}) {
  switch (provider) {
    case Providers.OpenAI:
      return Result.ok(
        createOpenAI({
          apiKey,
          // Needed for OpenAI to return token usage
          compatibility: 'strict',
        }),
      )
    case Providers.Groq:
      return Result.ok(
        createOpenAI({
          apiKey,
          compatibility: 'compatible',
          baseURL: GROQ_API_URL,
        }),
      )
    case Providers.Anthropic:
      return Result.ok(
        createAnthropic({
          apiKey,
        }),
      )
    case Providers.Mistral:
      return Result.ok(
        createMistral({
          apiKey,
        }),
      )
    // case Providers.Azure:
    //   return Result.ok(
    //     createAzure({
    //       apiKey,
    //       ...(config?.azure ?? {}),
    //     }),
    //   )
    // case Providers.Google: {
    //   const firstMessageResult = isFirstMessageOfUserType(messages)
    //   if (firstMessageResult.error) return firstMessageResult
    //
    //   return Result.ok(
    //     createGoogleGenerativeAI({
    //       apiKey,
    //       ...(config?.google ?? {}),
    //     }),
    //   )
    // }
    case Providers.Custom:
      return Result.ok(
        createOpenAI({
          apiKey: apiKey,
          compatibility: 'strict',
          baseURL: url,
          fetch: async (url, init) => {
            // 确保 init 存在
            if (!init) {
              init = {}
            }
            const originalConfig = {
              ...(init.body ? JSON.parse(init.body as string) : {}),
            }
            const final = {
              ...originalConfig,
              ...config,
              messages: originalConfig.messages,
            }
            delete final['provider']

            // 创建新的请求配置
            const newInit = {
              ...init,
              // 直接使用原始 config 作为新的请求体
              body: JSON.stringify(final),
              // 确保设置正确的 headers
              headers: {
                ...init.headers,
                'Content-Type': 'application/json',
                'x-request-task-type': 'latitude',
                'x-request-user-id': '190'
              },
            }

            // 使用全局 fetch 发送请求
            return fetch(url, newInit)
          },
        }),
      )
    default:
      return Result.error(
        new ChainError({
          code: RunErrorCodes.AIProviderConfigError,
          message: `Provider ${provider} not supported`,
        }),
      )
  }
}
