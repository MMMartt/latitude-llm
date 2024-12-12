import {
  ContentType,
  Conversation,
  Message,
  MessageRole,
} from '$compiler/types'
import OpenAI from 'openai'

type ChainStep = {
  conversation: Conversation
  completed: boolean
}

export function convertReqToChainStep(
  req: OpenAI.Chat.ChatCompletionCreateParams,
  prompt: string,
): ChainStep {
  const messages = req.messages
  const config = { ...req } as any
  // delete config['messages']

  return {
    conversation: {
      messages: messages.map((msg): Message => {
        switch (msg.role) {
          case 'system':
            return {
              role: MessageRole.system,
              content: [
                {
                  type: ContentType.text,
                  text: msg.content as string,
                },
              ],
            }
          case 'user':
            return {
              role: MessageRole.user,
              content: Array.isArray(msg.content)
                ? msg.content.map((content) => {
                    // Handle content parts
                    if ('type' in content) {
                      switch (content.type) {
                        case 'text':
                          return {
                            type: ContentType.text,
                            text: content.text,
                          }
                        case 'image_url':
                          return {
                            type: ContentType.image,
                            image: content.image_url.url,
                          }
                        default:
                          throw new Error(
                            `Unsupported content type: ${content.type}`,
                          )
                      }
                    }
                    throw new Error('Invalid content format')
                  })
                : [
                    {
                      type: ContentType.text,
                      text: msg.content as string,
                    },
                  ],
              ...(msg.name && { name: msg.name }),
            }
          case 'assistant':
            if (msg.tool_calls) {
              return {
                role: MessageRole.assistant,
                content: msg.tool_calls.map((call) => ({
                  type: ContentType.toolCall,
                  toolCallId: call.id,
                  toolName: call.function.name,
                  args: JSON.parse(call.function.arguments),
                })),
                toolCalls: msg.tool_calls.map((call) => ({
                  id: call.id,
                  name: call.function.name,
                  arguments: JSON.parse(call.function.arguments),
                })),
              }
            }
            return {
              role: MessageRole.assistant,
              content: [
                {
                  type: ContentType.text,
                  text: msg.content as string,
                },
              ],
              toolCalls: [],
            }
          case 'tool':
            return {
              role: MessageRole.tool,
              content: [
                {
                  type: ContentType.toolResult,
                  toolCallId: msg.tool_call_id,
                  toolName: '', // Tool name is not provided in OpenAI's format
                  result: msg.content,
                },
              ],
            }
          default:
            throw new Error(`Unsupported message role: ${msg.role}`)
        }
      }),
      config: {
        provider: parseBaseMetadata(prompt).parsed['provider'] || 'Latitude',
        ...config,
      },
    },
    completed: true,
  }
}

function parseBaseMetadata(prompt: string): {
  parsed: Record<string, string>
  exists: string
} {
  // Match all # key:value at the beginning of the file
  const metadataRegex = /^(?:#\s*([^:\n]+)\s*:\s*([^\n]+)\n)*/
  const existingMetadata = prompt.match(metadataRegex)?.[0] || ''

  // Parse existing metadata
  const parsed: Record<string, string> = {}
  existingMetadata.split('\n').forEach((line) => {
    if (!line.startsWith('#')) return
    const match = line.match(/^#\s*([^:\n]+)\s*:\s*([^\n]+)$/)
    if (match) {
      const [, key, value] = match
      parsed[key!.trim()] = value!.trim()
    }
  })

  return { parsed, exists: existingMetadata }
}
