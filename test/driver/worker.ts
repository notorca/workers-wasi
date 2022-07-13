import { ModuleTable } from '../../build/test/wasm-table'
import { ExecOptions, exec } from './common'

export default {
  async fetch(request: Request) {
    const options: ExecOptions = JSON.parse(
      atob(request.headers.get('EXEC_OPTIONS')!)
    )

    // Because we send the options over JSON for the tests all of the Uint8Arrays for the seeded FS
    // will be invalid, so we must convert them back into a valid Uint8Array.
    const newFs: Record<string, Uint8Array> = {};
    for (const [path, mangledBytes] of Object.entries(options.fs)) {
      newFs[path] = new Uint8Array(Object.values(mangledBytes))
    }

    const result = await exec(
      {
        ...options,
        fs: newFs
      },
      ModuleTable[options.moduleName],
      request.body ?? undefined
    )
    return new Response(JSON.stringify(result))
  },
}
