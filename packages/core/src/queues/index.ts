import { env } from '@latitude-data/env'
import Redis from 'ioredis'

import { buildRedisConnection } from '../redis'

let connection: Redis

export const queues = async (
  { enableOfflineQueue } = { enableOfflineQueue: false },
) => {
  if (connection) return connection

  connection = await buildRedisConnection({
    url: env.QUEUE_URL,
    enableOfflineQueue,
    maxRetriesPerRequest: null,
    retryStrategy: (times: number) =>
      Math.max(Math.min(Math.exp(times), 20000), 1000), // Exponential backoff with a max of 20 seconds and a min of 1 second
  })

  return connection
}
