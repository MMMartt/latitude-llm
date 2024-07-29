'use server'

import { ProviderApiKeysRepository } from '@latitude-data/core'

import { authProcedure } from '../procedures'

export const getProviderApiKeyAction = authProcedure
  .createServerAction()
  .handler(async ({ ctx }) => {
    const providerApiKeysScope = new ProviderApiKeysRepository(ctx.workspace.id)

    return await providerApiKeysScope.findAll().then((r) => r.unwrap())
  })