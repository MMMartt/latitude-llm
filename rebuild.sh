pushd ./apps/web/.next/standalone/apps/web > /dev/null
  cp -r ../../../static .next && cp ../../../../../../.env.production .
  cp ../../../../node_modules/@monica/prompt-parser-wasm/dist/wasm/main.wasm  node_modules/@monica/prompt-parser-wasm/dist/wasm/
popd > /dev/null
pm2 start simple.config.js