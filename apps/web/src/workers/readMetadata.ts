import {
  type ConversationMetadata,
  readMetadata,
} from '@latitude-data/compiler'
import { type DocumentVersion } from '@latitude-data/core/browser'
import yaml from 'yaml'
import type { PromptFile } from '@monica/prompt-parser-wasm/dist/src/schema'

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

export type ReadMetadataWorkerProps = Parameters<typeof readMetadata>[0] & {
  promptlVersion: number
  document?: DocumentVersion
  documents?: DocumentVersion[]
}

self.onmessage = async function (event: { data: ReadMetadataWorkerProps }) {
  const { prompt } = event.data
  console.log(prompt)
  const promptFile = yaml.parse(prompt) as PromptFile
  const parameters = new Set<string>()
  try {
    Object.keys(promptFile.input_schema.properties).forEach((k) =>
      parameters.add(k),
    )
  } catch (_) {
    //
  }
  const { parsed } = parseBaseMetadata(prompt)
  self.postMessage({
    config: parsed,
    errors: [],
    parameters,
    includedPromptPaths: new Set<string>(),
    resolvedPrompt: prompt,
  } as never as ConversationMetadata)

  return
  // const referenceFn = readDocument(document, documents, prompt)
  //
  // const props = {
  //   ...rest,
  //   prompt,
  //   referenceFn,
  // }
  //
  // const metadata =
  //   promptlVersion === 0 ? await readMetadata(props) : await scan(props)
  //
  // const { setConfig: _, errors: errors, ...returnedMetadata } = metadata
  //
  // const errorsWithPositions = errors.map((error) => {
  //   return {
  //     start: {
  //       line: error.start?.line ?? 0,
  //       column: error.start?.column ?? 0,
  //     },
  //     end: {
  //       line: error.end?.line ?? 0,
  //       column: error.end?.column ?? 0,
  //     },
  //     message: error.message,
  //     name: error.name,
  //   }
  // })
  //
  // self.postMessage({
  //   ...returnedMetadata,
  //   errors: errorsWithPositions,
  // })
}

// @ts-ignore
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function readDocument(
  document?: DocumentVersion,
  documents?: DocumentVersion[],
  prompt?: string,
) {
  if (!document || !documents || !prompt) return undefined

  return async (refPath: string, from?: string) => {
    const fullPath = resolveRelativePath(refPath, from)

    if (fullPath === document.path) {
      return {
        path: fullPath,
        content: prompt,
      }
    }

    const content = documents.find((d) => d.path === fullPath)?.content
    if (content === undefined) return undefined

    return {
      path: fullPath,
      content,
    }
  }
}

function resolveRelativePath(refPath: string, from?: string): string {
  if (refPath.startsWith('/')) {
    return refPath.slice(1)
  }

  if (!from) {
    return refPath
  }

  const fromDir = from.split('/').slice(0, -1).join('/')

  const segments = refPath.split('/')
  const resultSegments = fromDir ? fromDir.split('/') : []

  for (const segment of segments) {
    if (segment === '..') {
      resultSegments.pop()
    } else if (segment !== '.') {
      resultSegments.push(segment)
    }
  }

  return resultSegments.join('/')
}
