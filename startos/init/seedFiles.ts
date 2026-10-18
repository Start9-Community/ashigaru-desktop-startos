import { setPassword } from '../actions/setPassword'
import { storeJson } from '../fileModels/store.json'
import { i18n } from '../i18n'
import { sdk } from '../sdk'

export const seedFiles = sdk.setupOnInit(async (effects, kind) => {
  await storeJson.merge(effects, {})

  if (kind === 'install') {
    await sdk.action.createOwnTask(effects, setPassword, 'critical', {
      reason: i18n('Set your desktop password'),
    })
  }
})
