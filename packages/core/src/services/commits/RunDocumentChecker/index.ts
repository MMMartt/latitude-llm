import { ReferencePromptFn } from '@latitude-data/compiler'
import { RunErrorCodes } from '@latitude-data/constants/errors'

import { DocumentVersion, ErrorableEntity } from '../../../browser'
import { Result } from '../../../lib'
import { ChainError } from '../../chains/ChainErrors'
import { createRunError } from '../../runErrors/create'
import { createChainServer } from '../../evaluations/EvaluationRunChecker'

type RunDocumentErrorCodes = RunErrorCodes.ChainCompileError

export class RunDocumentChecker {
  private document: DocumentVersion
  private errorableUuid: string
  private prompt: string
  private referenceFn?: ReferencePromptFn
  private parameters: Record<string, unknown>

  constructor({
    document,
    errorableUuid,
    prompt,
    referenceFn,
    parameters,
  }: {
    document: DocumentVersion
    errorableUuid: string
    prompt: string
    referenceFn?: ReferencePromptFn
    parameters: Record<string, unknown>
  }) {
    this.document = document
    this.errorableUuid = errorableUuid
    this.prompt = prompt
    this.referenceFn = referenceFn
    this.parameters = parameters
  }

  async call() {
    const chainResult = await createChainServer(this.prompt, this.parameters)

    console.log({chainResult})
    return Result.ok({
      chain: chainResult,
    })
  }

  private async saveError(error: ChainError<RunDocumentErrorCodes>) {
    await createRunError({
      data: {
        errorableUuid: this.errorableUuid,
        errorableType: ErrorableEntity.DocumentLog,
        code: error.errorCode,
        message: error.message,
        details: error.details,
      },
    }).then((r) => r.unwrap())
  }

  private processParameters(
    parameters: Record<string, unknown>,
  ): Record<string, unknown> {
    const result = Object.entries(parameters).reduce(
      (acc, [key, value]) => {
        if (typeof value === 'string') {
          try {
            acc[key] = JSON.parse(value as string)
          } catch (e) {
            acc[key] = value
          }
        } else {
          acc[key] = value
        }

        return acc
      },
      {} as Record<string, unknown>,
    )

    return result
  }
}
