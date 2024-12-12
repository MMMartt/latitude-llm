export function parseBaseMetadata(prompt: string): {
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
