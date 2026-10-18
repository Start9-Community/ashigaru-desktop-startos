import { storeJson } from './fileModels/store.json'
import { i18n } from './i18n'
import { sdk } from './sdk'
import { desktopUser, uiPort } from './utils'

export const main = sdk.setupMain(async ({ effects }) => {
  console.info(i18n('Starting Ashigaru Desktop!'))

  // The desktop holds a hot wallet, so it never starts without a password.
  const PASSWORD = await storeJson.read((s) => s.PASSWORD).const(effects)
  if (!PASSWORD) {
    throw new Error('No password in store.json')
  }

  return sdk.Daemons.of(effects).addDaemon('primary', {
    subcontainer: sdk.SubContainer.of(
      effects,
      { imageId: 'main' },
      sdk.Mounts.of().mountVolume({
        volumeId: 'main',
        subpath: null,
        mountpoint: '/config',
        readonly: false,
      }),
      'ashigaru-sub',
    ),
    exec: {
      command: sdk.useEntrypoint(),
      runAsInit: true,
      env: {
        PUID: '1000',
        PGID: '1000',
        TZ: 'Etc/UTC',
        TITLE: 'Ashigaru',
        CUSTOM_USER: desktopUser,
        PASSWORD,
        S6_CMD_WAIT_FOR_SERVICES_MAXTIME: '0',
        S6_VERBOSITY: '1',
        NO_DECOR: 'true',
        DISABLE_OPEN_TOOLS: 'true',
        DISABLE_SUDO: 'true',
        DISABLE_TERMINALS: 'true',
        SELKIES_COMMAND_ENABLED: 'false',
        SELKIES_UI_SIDEBAR_SHOW_APPS: 'false',
        SELKIES_UI_SIDEBAR_SHOW_FILES: 'true',
        SELKIES_FILE_TRANSFERS: 'upload,download',
      },
    },
    ready: {
      display: i18n('Ashigaru Desktop'),
      fn: () =>
        sdk.healthCheck.checkPortListening(effects, uiPort, {
          successMessage: i18n('Ashigaru desktop is ready'),
          errorMessage: i18n('Ashigaru desktop is not ready'),
        }),
    },
    requires: [],
  })
})
