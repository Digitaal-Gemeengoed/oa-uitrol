# Office Assistent als extensie in Collabora Online

*Prototype Digitaal GemeenGoed · 24 november 2026 · verkenning met proefversie (oa-adapters 0.23.0), nog geen besluit*

## Aanleiding

Een bijdrager aan Collabora Online wees op twee nieuwe manieren om Collabora uit te breiden. Met die manieren zou de Office Assistent (OA) in Collabora kunnen werken zoals in LibreOffice: in het document zelf, met vergelijkbare vermogens. Bronnen:

- *Extending Collabora Online with iframe-hosted extensions* (blog, 11 juni 2026);
- *Google Apps Script add-ons in Collabora Online* (blog, 16 oktober 2026);
- release notes van CODE 26.04 en de wekelijkse ontwikkelaarsblogs (*Open Source in Action* #18 en #19);
- *Server-Side Settings for Collabora Online Integrators*.

De broncode van de extensies staat op Gerrit van Collabora. De GitHub-spiegel bevat sinds juni 2026 alleen nog Helm en Docker. Gerrit en Docker Hub waren voor deze verkenning niet bereikbaar. Wat hieronder over de techniek staat, komt daarom uit de blogs en release notes. Het is nog niet nagespeeld; zie het proefplan.

## Hoe het nu werkt

Het paneel staat naast Collabora op `oa.<domein>/collabora`. Collabora zelf draait in een iframe (`office.<domein>`). Het paneel praat met Collabora via de PostMessage-API (`Action_Save`, `Send_UNO_Command`). Die API stuurt alleen opdrachten en geeft niets uit het document terug. Daardoor:

- leest de assistent het document pas na *opslaan* uit het bestand (WOPI);
- vervangt hij in tekst alleen met zoeken en vervangen van Collabora zelf, niet op een plek;
- herstelt de integratielaag rekenbladen en presentaties in het bestand, waarna Collabora het bestand **opnieuw laadt** (vervelend voor medebewerkers in hetzelfde document);
- komen klikken en de selectie niet door; documenteigenschappen schrijven kan niet.

## Wat Collabora nu biedt

### 1. Extensies in een iframe (de basis)

- **Pakket.** Een map met `manifest.json`, een pictogram en een HTML-ingang. Manifest 0.1 kent `manifestVersion`, `name`, `entry`, `icon` en `supports` (`text`, `spreadsheet`, `presentation`, `drawing`). Het formaat ligt nog niet vast; 1.0 volgt.
- **Plaats in Collabora.** Een tabblad *Extensies* (tabweergave) of submenu (compacte weergave). Een klik opent een paneel rechts, boven de gewone zijbalk. Sinds 26.04.3.1 kunnen extensies ook dialogen tonen. Volgens de ontwikkelaarsblogs komen er ook contextmenu, werkbalk en sneltoetsen bij.
- **Toegang tot het document.** De helper `cool.js` geeft:
  - `cool.callRemote(fn, ...args)`: een functie gaat als brontekst naar het kit-proces van het document en draait daar in QuickJS, met de volledige UNO-API (`uno.idl.com.sun.star.frame.Desktop.create(uno.componentContext)`). De uitkomst komt als JSON terug in een promise. Argumenten moeten JSON zijn; de functie kan geen variabelen van buiten gebruiken.
  - gebeurtenissen: `cool.document.onModified`, `onSelectionChanged`, `onCommentAdded`/`Changed`/`Removed`, en `cool.attachListener` voor elke andere UNO-luisteraar.
- **Veiligheid.** De iframe heeft sandbox `allow-scripts allow-same-origin allow-forms allow-popups` en staat los van het JavaScript van Collabora. Extensies staan uit in de beperkte modi van Collabora.
- **Uitrol.** Op de server in `browser/dist/extensions/`, aan te zetten met `experimental_features`. Of als ZIP via de server-side settings van de WOPI-host; de beheerder kan dan per organisatie uploaden. Volgens de blog is uploaden sinds september een taak van de beheerder.

Dit is in wezen dezelfde opzet als onze LibreOffice-extensie: een webpaneel met een kanaal naar UNO. Alleen draait UNO hier in het kit-proces op de server, en praat het paneel via `cool.js` in plaats van via de brug op 127.0.0.1.

### 2. Google Apps Script-add-ons (een laag erbovenop)

Sinds CODE 26.04.5.1 (12 oktober 2026) draaien add-ons voor Google Docs, Sheets en Slides in Collabora. Ze krijgen menu's in *Extensies*, en kunnen dialogen, zijbalken en contextmenu's gebruiken en gegevens ophalen. Het is een compatibiliteitslaag: Collabora heeft zijn eigen script-API dichter bij Apps Script gebracht, zodat bestaande add-ons van organisaties die van Google Workspace overstappen, blijven werken.

## Wat dit voor de OA zou opleveren

| Vermogen | Collabora nu (PostMessage) | Collabora als extensie | LibreOffice-extensie |
|---|---|---|---|
| Inhoud lezen | na opslaan, uit het bestand | live, via UNO | live, via UNO |
| Segment vervangen (tekst) | nee (heel document) | ja | ja |
| Herstellen in rekenblad/presentatie | in het bestand, dan herladen | in het document, zonder herladen | ja |
| Anonimiseren in het document | zoeken en vervangen; plekken na opslaan | markeren, plekken, klikken | ja |
| Selectie lezen, klik op plaatshouder | nee | ja (`onSelectionChanged`) | ja |
| Documenteigenschappen | nee | ja | ja |
| Samenwerken | herladen stoort medebewerkers | wijziging verschijnt bij iedereen | n.v.t. |
| In welke omgeving | alleen onze eigen pagina | elke WOPI-host met deze Collabora | LibreOffice |

**Het iframe verdwijnt niet helemaal.** Collabora draait altijd in een iframe van de WOPI-host; zo werkt de koppeling. Wat verdwijnt, is ons eigen paneel ernaast met de beperkte PostMessage-route. Het paneel komt *in* Collabora te staan. Daarmee werkt de OA ook in andere omgevingen die Collabora tonen (Nextcloud, openDesk), als die dezelfde Collabora-server en de extensie gebruiken.

## Afweging: extensie, niet Apps Script

**Voorkeur: een eigen iframe-extensie met `cool.callRemote`.**

- De UNO-API is dezelfde als in onze LibreOffice-extensie. De bestaande documentlogica in Python (`oa_document`, `oa_tekst`, `oa_pii`, `oa_bladen`; samen ongeveer 1.400 regels) is direct bruikbaar als richtlijn, en mogelijk zelfs ongewijzigd: zie proefvraag 3.
- Apps Script werkt op een grover niveau (`DocumentApp`, `Body`, `Paragraph`). Plekken, plaatshouders, eigenschappen en anonimiseren in het document passen daar slecht in. Het is ook gemaakt voor de overstap van Google; voor gemeenten die vooral Word en LibreOffice gebruiken, is dat geen doel.
- Apps Script is pas zinvol als de OA ook in Google Workspace moet draaien. Dat is nu geen doel.

## Voorstel voor de opbouw

1. **De extensie** `nl.digitaalgemeengoed.office-assistent`: een manifest, een pictogram en een kleine `index.html` op de herkomst van Collabora, die `cool.js` laadt.
2. **Het paneel.** Twee varianten; de proef beslist:
   - **A (voorkeur):** `index.html` toont het paneel van `https://oa.<domein>/collabora-extensie` in een geneste iframe. Een berichtenbrug geeft vragen door aan `cool.js`, met een sleutel per sessie, zoals het WebKit-kanaal in LibreOffice. Code, inloggen en versies blijven op één plek; een nieuwe paneelversie vraagt geen nieuwe ZIP. Dit hangt af van het CSP-beleid (`frame-src`) van Collabora voor extensies.
   - **B:** de paneelbundel zit in de ZIP en praat met de API op `oa.<domein>` via CORS. `office.<domein>` en `oa.<domein>` zijn dezelfde site, dus het sessiecookie gaat mee.
3. **De documentlaag.** Een nieuwe tekstverwerker (`CollaboraKit`) met dezelfde vorm als `LibreOfficeTekstverwerker`, onder de bestaande `StructuurAdapter`. Alle vragen gaan via `cool.callRemote`. Er zijn twee manieren:
   - de Python-modules hergebruiken: vanuit `callRemote` de scriptprovider van LibreOffice aanroepen (`com.sun.star.script.provider.MasterScriptProviderFactory`, taal Python), als het kit-proces Python heeft;
   - of de logica overzetten naar JavaScript voor QuickJS. Dat is meer werk, maar zonder afhankelijkheid van Python in de container.
4. **Gebeurtenissen.** `onSelectionChanged` voor selectie lezen en klikken op plaatshouders, en `onModified` om de toetsing bij te werken.
5. **Uitrol.**
   - Eerst: een map `collabora/extensions/` in oa-uitrol, als volume in de container, met `--o:experimental_features=true`.
   - Later: de integratielaag levert als WOPI-host de ZIP via de server-side settings, per gemeente. Dat past bij de multi-tenant opzet.
   - De extensie werkt alleen als de WOPI-host de integratielaag is. Een andere omgeving op dezelfde Collabora krijgt anders een paneel zonder werkbestand.

## Risico's

- **Experimenteel.** Het manifest is versie 0.1 en de JavaScript-API staat nog niet vast. Reken op aanpassingen bij elke versie van Collabora tot 1.0; houd de afhankelijkheid daarom klein (één module `CollaboraKit`).
- **Beperkte modi.** Extensies staan uit in de beperkte modi. Wij draaien met `home_mode.enable=true`; of dat meetelt, is onbekend.
- **Meer gebruikers in één document.** `callRemote` gebruikt in het voorbeeld `desktop.getCurrentFrame()`. Of dat bij meer gebruikers altijd het venster van de juiste gebruiker is, moet blijken. Een selectie of cursor van de verkeerde gebruiker zou ongemerkt fout gaan.
- **Bereik.** Een extensie staat op de hele Collabora-server, voor elke WOPI-host. Daarom de controle in punt 5 en de uitrol door de beheerder.
- **Veiligheid.** `callRemote` voert willekeurige UNO-code uit in het kit-proces, met de rechten van die gebruiker op dat document. De berichtenbrug moet daarom, net als de brug in LibreOffice, alleen vragen van ons eigen paneel aannemen (herkomst plus sessiesleutel), en alleen vaste functies aanbieden, geen vrije code uit het paneel.
- **Code niet ingezien.** De broncode van `cool.js` en de kit-kant is nog niet bekeken.

## Proefplan (2 à 3 dagen, op de testomgeving)

1. **Werkt het in onze versie?** CODE 26.04.5.2.1 met `--o:experimental_features=true`; installeer de demo-extensies (`com.collaboraoffice.demo-text`, `demo-events`) via een volume. Werkt het naast `home_mode`?
2. **Geneste iframe.** Kan `index.html` een iframe naar `https://oa.<domein>/…` tonen (CSP)? Zo niet: variant B.
3. **Python hergebruiken.** Kan `callRemote` via de scriptprovider een Python-functie aanroepen, bijvoorbeeld `oa_document.lees_blokken`, met de module in de container? Zo ja, dan is de bouw vooral het kanaal en de adapter.
4. **Twee gebruikers.** Twee gebruikers in één document: komt een wijziging via `callRemote` bij beiden aan? Geeft `getCurrentFrame()` steeds het venster van de vragende gebruiker, ook voor de selectie?

Na de proef volgt het besluit, met een schatting. Bij hergebruik van Python is de bouw ruwweg één à twee weken; bij overzetten naar JavaScript komen daar één à twee weken bij. Dat zijn grove schattingen.

## Proefversie (oa-adapters 0.23.0, oa-uitrol 0.35.0)

Naast de gewone pagina `/collabora` staat nu een proef. Sinds oa-uitrol 0.35.1 staat ze standaard aan, met een eigen kaart op de voorpagina van `office.<domein>`. Let op: `experimental_features` zet alle experimentele functies van Collabora aan, dus ook voor de gewone Collabora-pagina; `COLLABORA_EXPERIMENTEEL=false` zet ze (en de proef) uit. De opzet volgt het voorstel hierboven, met variant A (geneste iframe) en een JavaScript-versie van de documentlogica. Code: `oa-adapters/collabora-extensie/` (met README).

- **Pakket** (`collabora-extensie/pakket`): `manifest.json` (0.1, alleen `text`), `icon.svg`, `index.html`, `brug.js` en `kit.js`. Op VPS 1 krijgt Collabora het als volume in `/usr/share/coolwsd/browser/dist/extensions/nl.digitaalgemeengoed.office-assistent`.
- **`kit.js`**: één afgesloten functie `oaKit(opdracht, a)` voor `cool.callRemote`. Ze bevat de logica van `oa_document.py` en het Writer-deel van `oa_tekst.py`, en antwoordt altijd met `{ok, waarde}` of `{ok: false, fout, melding}`.
- **`brug.js`**: neemt alleen berichten aan van het eigen paneel (bron en herkomst), en voert alleen vaste opdrachten uit. Gebeurtenissen (selectie, gewijzigd) gaan naar het paneel.
- **Paneel**: `oa.<domein>/collabora-extensie` met `CollaboraKitTekstverwerker` onder de gewone `StructuurAdapter`. Het controleert de herkomst van de extensie: https op hetzelfde domein. Caddy staat de pagina toe in een iframe van `office.<domein>`.
- **Werkbestand openen**: `oa.<domein>/collabora-proef`, de gewone pagina zonder paneel ernaast.

**Wat werkt (Writer):** lezen en beoordelen; herstellen op een plek (kopniveau, kopregel, alternatieve tekst, linktekst); tonen; selectie lezen; tekst vervangen (anonimiseren bij de bron); documenteigenschappen lezen en schrijven. **Nog niet:** anonimiseren in het document (plaatshouders, klikken), rekenbladen en presentaties, de taal van het document, het bestand zelf vastleggen.

**Getest zonder Collabora** (Gerrit en Docker Hub waren niet bereikbaar):

1. `kit.js` draait in QuickJS (dezelfde motor als in Collabora) tegen een echte LibreOffice 24.2. Een `uno`-object geeft daarbij elke aanroep via JSON door aan PyUNO. Blokken en eigenschappen zijn gelijk aan wat de Python-extensie leest; opdrachten, tonen, selectie en tekst vervangen werken (8 tests).
2. De keten paneel → `brug.js` → nagebootste `cool.js` → `oaKit` → LibreOffice, in Chromium: het paneel start en leest het document.
3. De echte `StructuurAdapter` met de herstelroute van `oa-kern`: een alinea wordt een kop van niveau 2 en staat daarna echt zo in het document.

Wat dit niet toetst, is hoe JS-UNO in Collabora zelf waarden en eigenschappen aanbiedt. Daarom gaat `kit.js` defensief om met eigenschappen: `getPropertyValue`, dan `getX`, dan directe toegang.

**Op de testserver (VPS 1):**

1. Draai `bijwerken.sh`. Staat in `/opt/oa-uitrol/.env` nog `COLLABORA_EXPERIMENTEEL=false` (van 0.35.0), zet die dan eerst op `true`.
2. Open `https://oa.<domein>/collabora-proef`, kies of maak een tekstbestand, en kies in Collabora **Extensies → Office Assistent**.
3. Ziet u geen tabblad Extensies: controleer in de container of de map er staat (`docker compose exec collabora ls /usr/share/coolwsd/browser/dist/extensions`) en of `home_mode` de extensies tegenhoudt (zet tijdelijk `--o:home_mode.enable=false`).
4. Meldt het paneel zich niet binnen 20 seconden, dan toont de extensie een melding. Kijk in de console van de browser of `frame-src` de pagina van `oa.<domein>` tegenhoudt. Is dat zo, dan is variant B nodig, of een aanvulling via `--o:net.content_security_policy`.
5. Werkt het paneel: probeer Toegankelijkheid → Beoordelen → Herstellen, en Metadateren (eigenschappen). Probeer het ook met twee gebruikers in één document (proefvraag 4).

## Vragen voor de bijdrager van Collabora

- Wanneer verwacht Collabora manifest 1.0 en een stabiele `cool.js`? Komt er een changelog per versie?
- Mag een extensie-iframe een pagina van een andere herkomst tonen (CSP `frame-src`)?
- Draait `callRemote` in het venster van de gebruiker die de vraag stelt, ook als er meer gebruikers in het document zijn?
- Kan `callRemote` scripts in Python aanroepen? Zit de Python-scriptprovider in de CODE-container?
- Kan een extensie zich beperken tot één WOPI-host? Hoe levert een integrator een extensie via de server-side settings (sleutel en formaat in de JSON)?
- Valt `home_mode` onder de beperkte modi waarin extensies uitstaan?
- Waar draait een Apps Script-add-on: in QuickJS in het kit-proces, of elders? En hoe werkt `UrlFetchApp` (netwerktoegang, toegestane adressen)?
