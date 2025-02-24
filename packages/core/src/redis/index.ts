import Redis, { RedisOptions } from 'ioredis'

export function buildRedisConnection({
  url,
  ...opts
}: Omit<RedisOptions, 'port' & 'host'> & { url: string }) {
  return new Promise<Redis>((resolve) => {
    const instance = new Redis(url, opts)

    instance.connect(() => {
      resolve(instance)
    })
  })
}
