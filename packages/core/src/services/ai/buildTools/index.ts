import { RunErrorCodes } from '@latitude-data/constants/errors'
import { CoreTool, jsonSchema } from 'ai'

import { Result } from '../../../lib'
import { compactObject } from '../../../lib/compactObject'
import { ChainError } from '../../chains/ChainErrors'
import { OpenAI } from 'openai'

export type AITools = Record<
  string,
  { description?: string; parameters: Record<string, any> }
>
export const buildTools = (
  tools: OpenAI.Chat.ChatCompletionTool[] | undefined,
) => {
  if (!tools) return Result.ok(undefined)
  try {
    const data = tools.reduce<Record<string, CoreTool>>(
      (acc, { function: { name, parameters, description } }) => {
        acc[name] = {
          type: 'function',
          description,
          parameters: jsonSchema(parameters as any)
        } as CoreTool

        return acc
      },
      {},
    )
    return Result.ok(data)
  } catch (e) {
    const error = e as Error
    return Result.error(
      new ChainError({
        code: RunErrorCodes.AIProviderConfigError,
        message: `Error building "tools": ${error.message}`,
      }),
    )
  }
}
