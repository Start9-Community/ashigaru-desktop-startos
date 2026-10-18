export const DEFAULT_LANG = 'en_US'

const dict = {
  // main.ts
  'Starting Ashigaru Desktop!': 0,
  'Ashigaru Desktop': 1,
  'Ashigaru desktop is ready': 2,
  'Ashigaru desktop is not ready': 3,

  // interfaces.ts
  'Access the Ashigaru desktop application through your web browser': 4,

  // actions/setPassword.ts
  'Set Desktop Password': 5,
  'Generate a new random password for signing in to the Ashigaru desktop': 6,
  'Replaces the current desktop password. Ashigaru restarts, and the old password stops working.': 7,
  'Ashigaru Desktop Credentials': 8,
  'Use these credentials to log into the Ashigaru desktop interface:': 9,
  Username: 10,
  Password: 11,

  // init/seedFiles.ts
  'Set your desktop password': 12,
} as const

/**
 * Plumbing. DO NOT EDIT.
 */
export type I18nKey = keyof typeof dict
export type LangDict = Record<(typeof dict)[I18nKey], string>
export default dict
