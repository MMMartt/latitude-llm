import { describe, expect, it } from 'vitest'
import { parsePrompt } from '@monica/prompt-parser-wasm'

describe('test monica', () => {
  it('should parse prompt', async () => {
    const r = await parsePrompt(`messages:
  - role: user
    content: Hello {{.firstName}} {{.lastName}}
`)
    const result = r.render({ firstName: 'John', lastName: 'Snow' })
    expect(result.messages[0]?.role).toEqual('user')
    expect(result.messages[0]?.content).toEqual('Hello John Snow')
  })
})
