import { IMPOSSIBLE, VersionInfo } from '@start9labs/start-sdk'

export const current = VersionInfo.of({
  version: '1.5.1:0',
  releaseNotes: {
    en_US:
      'Updated Ashigaru Desktop to 1.5.1. Ashigaru connects to Tor again: its bundled Tor is updated to a version the Tor network still accepts. [Full release notes](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.1)',
    es_ES:
      'Ashigaru Desktop actualizado a 1.5.1. Ashigaru vuelve a conectarse a Tor: su Tor integrado se actualiza a una versión que la red Tor todavía acepta. [Notas completas de la versión](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.1)',
    de_DE:
      'Ashigaru Desktop auf 1.5.1 aktualisiert. Ashigaru verbindet sich wieder mit Tor: Das mitgelieferte Tor wurde auf eine Version aktualisiert, die das Tor-Netzwerk weiterhin akzeptiert. [Vollständige Versionshinweise](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.1)',
    pl_PL:
      'Zaktualizowano Ashigaru Desktop do wersji 1.5.1. Ashigaru znów łączy się z siecią Tor: wbudowany Tor został zaktualizowany do wersji, którą sieć Tor nadal akceptuje. [Pełne informacje o wydaniu](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.1)',
    fr_FR:
      'Ashigaru Desktop mis à jour vers la version 1.5.1. Ashigaru se connecte de nouveau à Tor : le Tor intégré passe à une version que le réseau Tor accepte toujours. [Notes de version complètes](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.1)',
  },
  migrations: {
    up: async ({ effects }) => {},
    down: IMPOSSIBLE,
  },
})
