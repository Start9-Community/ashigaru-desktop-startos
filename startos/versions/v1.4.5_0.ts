import { IMPOSSIBLE, VersionInfo } from '@start9labs/start-sdk'

export const v_1_4_5_0 = VersionInfo.of({
  version: '1.4.5:0',
  releaseNotes: {
    en_US:
      'Initial StartOS release of Ashigaru Desktop 1.4.5, streamed to the browser.',
    es_ES:
      'Primera versión para StartOS de Ashigaru Desktop 1.4.5, transmitida al navegador.',
    de_DE:
      'Erste StartOS-Version von Ashigaru Desktop 1.4.5, in den Browser gestreamt.',
    pl_PL:
      'Pierwsze wydanie Ashigaru Desktop 1.4.5 dla StartOS, przesyłane do przeglądarki.',
    fr_FR:
      'Première version StartOS d’Ashigaru Desktop 1.4.5, diffusée dans le navigateur.',
  },
  migrations: {
    up: async ({ effects }) => {},
    down: IMPOSSIBLE,
  },
})
