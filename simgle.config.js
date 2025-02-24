module.exports = {
  apps: [
    {
      name: 'gateway',
      script: './apps/gateway/dist/server.js',
      env: {
        NODE_ENV: 'production',
        PORT: 8081,
      },
      watch: true,
    },
    {
      name: 'workers',
      script: './apps/workers/dist/server.js',
      env: {
        NODE_ENV: 'production',
      },
      watch: true,
    },
    {
      name: 'websockets',
      script: './apps/websockets/dist/server.js',
      env: {
        NODE_ENV: 'production',
      },
      watch: true,
    },
    {
      name: 'web',
      cwd: './apps/web/.next/standalone/apps/web',
      pre_start: 'cp -r ../../../static .next && cp ../../../../../../.env.production .',
      env: {
        NODE_ENV: 'production',
      },
      script: 'server.js',
      watch: true,
    },
  ],
}
