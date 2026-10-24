import { IMPOSSIBLE, VersionInfo } from '@start9labs/start-sdk'

export const current = VersionInfo.of({
  version: '1.5.0:0',
  releaseNotes: {
    en_US: `Updates Ashigaru Desktop to 1.5.0 and fixes how it looks and behaves in the browser.

- The window now fills your browser tab and follows it when you resize, and dialogs open at their own size instead of full screen.
- The copy and lock icons on buttons show again.
- Dropdowns and the seed-word suggestions no longer have a white box around them.
- Block explorer and exposure links copy the link to your clipboard and show it, ready to paste into a new browser tab.
- Text is sharper: the desktop is streamed in full colour at higher quality.

[Ashigaru Desktop 1.5.0 release notes](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.0)`,
    es_ES: `Actualiza Ashigaru Desktop a 1.5.0 y corrige su aspecto y comportamiento en el navegador.

- La ventana ahora ocupa toda la pestaña del navegador y la sigue al cambiar su tamaño, y los diálogos se abren a su propio tamaño en lugar de a pantalla completa.
- Los iconos de copiar y bloquear de los botones vuelven a mostrarse.
- Los desplegables y las sugerencias de palabras semilla ya no tienen un recuadro blanco alrededor.
- Los enlaces al explorador de bloques y de exposición copian el enlace al portapapeles y lo muestran, listo para pegarlo en una nueva pestaña.
- El texto se ve más nítido: el escritorio se transmite a todo color y con mayor calidad.

[Notas de la versión 1.5.0 de Ashigaru Desktop](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.0)`,
    de_DE: `Aktualisiert Ashigaru Desktop auf 1.5.0 und behebt Darstellung und Verhalten im Browser.

- Das Fenster füllt jetzt deinen Browser-Tab aus und passt sich beim Ändern der Größe an; Dialoge öffnen sich in ihrer eigenen Größe statt im Vollbild.
- Die Kopieren- und Sperren-Symbole auf den Schaltflächen werden wieder angezeigt.
- Auswahllisten und die Vorschläge für Seed-Wörter haben keinen weißen Rahmen mehr.
- Links zum Block-Explorer und zur Exposure-Prüfung kopieren den Link in die Zwischenablage und zeigen ihn an, bereit zum Einfügen in einen neuen Browser-Tab.
- Schärferer Text: Der Desktop wird in voller Farbe und höherer Qualität gestreamt.

[Versionshinweise zu Ashigaru Desktop 1.5.0](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.0)`,
    pl_PL: `Aktualizuje Ashigaru Desktop do wersji 1.5.0 i poprawia jego wygląd oraz działanie w przeglądarce.

- Okno wypełnia teraz kartę przeglądarki i dopasowuje się przy zmianie jej rozmiaru, a okna dialogowe otwierają się we własnym rozmiarze zamiast na pełnym ekranie.
- Ikony kopiowania i blokady na przyciskach znów są widoczne.
- Listy rozwijane i podpowiedzi słów seed nie mają już białej ramki.
- Linki do eksploratora bloków i sprawdzania ekspozycji kopiują link do schowka i wyświetlają go, gotowy do wklejenia w nowej karcie przeglądarki.
- Ostrzejszy tekst: pulpit jest przesyłany w pełnym kolorze i w wyższej jakości.

[Informacje o wydaniu Ashigaru Desktop 1.5.0](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.0)`,
    fr_FR: `Met à jour Ashigaru Desktop vers la version 1.5.0 et corrige son apparence et son comportement dans le navigateur.

- La fenêtre occupe désormais tout l’onglet du navigateur et suit ses changements de taille, et les boîtes de dialogue s’ouvrent à leur propre taille au lieu du plein écran.
- Les icônes de copie et de verrouillage des boutons s’affichent de nouveau.
- Les listes déroulantes et les suggestions de mots de la phrase de récupération n’ont plus de cadre blanc.
- Les liens vers l’explorateur de blocs et la vérification d’exposition copient le lien dans le presse-papiers et l’affichent, prêt à être collé dans un nouvel onglet.
- Texte plus net : le bureau est diffusé en couleurs complètes et en meilleure qualité.

[Notes de version d’Ashigaru Desktop 1.5.0](https://github.com/linkinparkrulz/ashigaru-desktop/releases/tag/v1.5.0)`,
  },
  migrations: {
    up: async ({ effects }) => {},
    down: IMPOSSIBLE,
  },
})
