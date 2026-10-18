import { utils } from '@start9labs/start-sdk'

export const uiPort = 3000

// Selkies desktop login. The username is fixed; only the password is stored.
export const desktopUser = 'ashigaru'

export function getDefaultPassword(): string {
  return utils.getDefaultString({ charset: 'a-z,A-Z,0-9', len: 22 })
}
