'use client'

import {
  ContentType,
  Message as ConversationMessage,
  ToolCall,
  ToolRequestContent,
} from '@latitude-data/compiler'

import { Message } from '../Message'

export function MessageList({
  messages,
  parameters,
  collapseParameters,
}: {
  messages: ConversationMessage[]
  parameters?: Record<string, unknown>
  collapseParameters?: boolean
}) {
  return (
    <div className='flex flex-col gap-4'>
      {messages.map((message, index) => (
        <Message
          key={index}
          role={message.role}
          content={
            typeof message.content === 'string'
              ? [
                  {
                    type: ContentType.text,
                    text: message.content,
                  } as any,
                  ...(message.toolCalls
                    ? (message.toolCalls as ToolCall[]).map(
                        (a): ToolRequestContent => ({
                          type: ContentType.toolCall,
                          toolCallId: a.id,
                          toolName: a.name,
                          args: a.arguments,
                        }),
                      )
                    : []),
                ]
              : message.content
          }
          parameters={parameters}
          collapseParameters={collapseParameters}
        />
      ))}
    </div>
  )
}
