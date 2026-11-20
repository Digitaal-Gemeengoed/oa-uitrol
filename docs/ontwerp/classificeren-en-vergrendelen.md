# Office Assistent — classificeren, bewaren en vergrendelen

*Vastgelegd 10 november 2026; gebouwd in uitrol 0.20.0 (oa-beheer 0.5.0, opendop-mini 0.11.0, oa-contract 0.8.0, oa-kern 0.8.0, oa-paneel 0.12.0, oa-adapters 0.19.0, oa-integratielaag 0.10.0).*

## Besluiten (Erik, 10 november 2026)

1. De bewaartermijn gaat standaard in bij de status **definitief**. Per klasse kan een datumveld de start bepalen: bij een procestermijn "bestaansduur van het procesobject" of "vast te leggen vervaldatum" vult de medewerker de einddatum in. Een koppeling met zaken volgt later; dan wint de datum van de zaak.
2. De catalogus is de **Selectielijst gemeenten en intergemeentelijke organen 2020** (VNG). Het Selectiebesluit 2027 volgt zodra het is vastgesteld.
3. De beheerder kiest bij welke statussen een stuk vergrendeld is, met **ten minste één** status.
4. Een wijziging aan een vergrendeld stuk wordt een **wijzigingsvoorstel naast het stuk**, niet een "geblokkeerde" versie in de versieketen.

## Wettelijk kader (onderzoek)

- De Archiefwet 2026 is aangenomen (Eerste Kamer 12 mei 2026, Staatsblad 19 juni 2026). Ingang per koninklijk besluit, verwacht 1 januari 2027. De overbrengingstermijn gaat van 20 naar 10 jaar; volgens een toelichting loopt die vanaf het ontstaan van het stuk.
- Bewaartermijnen komen uit de selectielijst. Afwijken mag gemotiveerd en moet worden gemeld. De Selectielijst 2020 wordt per 31 december 2026 afgesloten; het Selectiebesluit 2027 (ontwerp, consultatie gesloten 5 oktober 2026) geldt voor stukken vanaf 1 januari 2027.
- In ZGW heet het startpunt de **brondatum archiefprocedure**, met afleidingswijzen zoals afgehandeld, ingangsdatum of vervaldatum van een besluit, eigenschap en termijn. Procestermijn "nihil" betekent dat de bewaartermijn direct na de procesfase start.
- MDTO: de elementen waardering, bewaartermijn (trigger, startdatum, looptijd, einddatum) en classificatie.

## Hoe het werkt

### Classificatiemodel

Het classificatiemodel staat in het beheerportaal (Classificatie) en heeft versies per gemeente. Het bevat:

- een naam;
- de selectielijst;
- de uitgezette resultaten;
- afwijkingen, alleen met een reden en het recht `bewaartermijn.afwijken`;
- eigen attributen (tekst, keuze, ja of nee);
- `vergrendelBij` (ten minste één status uit het statusveld van het metadatamodel);
- `termijnStartBij`.

Rechten: `classificatie.view`, `classificatie.manage` en `bewaartermijn.afwijken`.

### Per stuk

- **Classificatie:** de modelversie, de klasse, de attributen en eventueel de einddatum van het procesobject.
- **Statusdata:** per status de eerste dag waarop het stuk die status kreeg.
- **Bewaren:** het platform berekent de archiefactiedatum (brondatum plus bewaartermijn). Het Overzicht toont "tot …, daarna vernietigen" of "blijvend bewaren".

### Assistent

De assistent stelt drie klassen voor op grond van de woorden in het stuk. Zeldzame woorden wegen zwaarder; de omschrijving en het procestype wegen zwaarder dan de toelichting. Dit is bewust eenvoudig; een taalmodel kan het later overnemen met dezelfde vorm van voorstel.

### Vergrendeld

Bij een status in `vergrendelBij`:

- **Geen nieuwe versie:** het platform geeft 409 `vergrendeld`.
- **Geen andere metadata of classificatie:** dit mag alleen een vrijgever. Zo geeft hij een stuk vrij: hij zet de status terug.
- **Een geanonimiseerde versie mag wel**, voor openbaarmaking onder de Woo.

### Wijzigingsvoorstel

- De medewerker dient een voorstel in met een reden. De inhoud staat versleuteld met de sleutel van het stuk, naast het stuk.
- Een vrijgever (Keycloak-rol `vrijgever`) ziet de open voorstellen in het paneel, met per alinea wat weggaat en wat erbij komt, en keurt goed of wijst af met een toelichting.
- Goedgekeurd wordt het de volgende versie, op naam van de indiener; het stuk blijft vergrendeld.
- Een eigen voorstel beoordeelt de vrijgever niet. Een voorstel dat op een verouderde versie voortbouwt, wordt geweigerd.

### Editors

Het slot zit in het platform. De editors blijven bewerkbaar; anders kun je geen voorstel voorbereiden.

- Collabora kan echt alleen-lezen: wij zijn daar de WOPI-host.
- In Word op de desktop en in LibreOffice is "alleen lezen" op te heffen.
- Zo'n editorslot kan later als extra signaal, maar het vervangt het slot in het platform niet.

### Laden

- **Stap 1:** een laadscherm in de html van de pagina zelf, zichtbaar voordat de JavaScript binnen is.
- **Stap 2:** in het paneel, met een voortgangsbalk die bijhoudt hoeveel van de vier opstartvragen beantwoord zijn.
- De selectielijst (128 kB) zit niet in de paneelbundel. Het paneel haalt hem pas op als Classificeren opent.

## Open punten

- Het Selectiebesluit 2027 als tweede lijst, met de geldigheid op basis van de datum waarop het stuk ontstond.
- Een koppeling met zaken, zodat de bewaartermijn van de zaak (dossier) geldt.
- Meldingen aan vrijgevers (nu alleen zichtbaar in het paneel).
- De paneelbundel is ongeveer 550 kB, zonder compressie. Opsplitsen per module maakt het laden over mobiel sneller.
