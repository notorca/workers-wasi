import * as utils from './utils'

const text = "Seeded data";
const dataBin = new TextEncoder().encode("Seeded data")

await utils.withEnv(async (fixture: utils.TestEnv) => {
  test('cases/cat.wasm', async () => {
    const result = await fixture.exec({
      preopens: ['/tmp/'],
      fs: {
        '/tmp/data.bin': dataBin, 
      },
      asyncify: false,
      args: [],
      env: {},
      moduleName: 'cases/cat.wasm',
      returnOnExit: false,
    })
    
    expect(result.stdout).toEqual(text)
  })
})
