# Office Assistent — Archiefregeling 2026 (ontwerp)

*Prototype Digitaal GemeenGoed · 23 november 2026 · besluiten van Erik Hoekstra*

De Archiefregeling 2026 (Staatscourant 2026, 40895, gepubliceerd 23 november 2026) werkt de Archiefwet 2026 uit in technische en organisatorische eisen. De regeling treedt in werking tegelijk met het Archiefbesluit 2026; de artikelen 3.2 en 3.3 (vervanging en migratie) per 1 januari 2029. De assistent legt vier dingen vanaf het maken van een stuk vast. Achteraf aanvullen is veel lastiger.

## 1. Openbaarheid (art. 2.12)

Uiterlijk bij overbrenging liggen vast:
- de status: openbaar of beperkt openbaar;
- bij een beperking: de grond uit artikel 7.2 van de Archiefwet 2026, de duur en de datum waarop de beperking afloopt.

Voor stukken van vóór de inwerkingtreding geldt dit niet.

| Rol | MDTO | RGBZ | TMLO |
|---|---|---|---|
| openbaarheid | beperkingGebruik (openbaarheid) | aanvulling | openbaarheid |
| beperkingsgrond | beperkingGebruik.beperkingGebruikNadereBeschrijving | aanvulling | openbaarheid.omschrijvingBeperkingen |
| beperkingstermijn (jaren) | beperkingGebruik.beperkingGebruikTermijn.termijnLooptijd | aanvulling | aanvulling |
| beperkingEinddatum | beperkingGebruik.beperkingGebruikTermijn.termijnEinddatum | aanvulling | openbaarheid.datumOfPeriode |

Werking:
- **Velden.** Grond, duur en einddatum verschijnen in het paneel pas bij "beperkt openbaar", en zijn dan verplicht. Ontbreken ze, dan heet het stuk onvolledig; het schema legt dat vast in `x-oa-verplicht-als`.
- **Duur.** Kiest de medewerker een grond, dan stelt de assistent de langste duur voor die artikel 7.4 toestaat:
  - 75 jaar voor de eenheid van de Kroon, de veiligheid van de Staat en internationale betrekkingen;
  - 110 jaar voor bijzondere en strafrechtelijke persoonsgegevens, identificatienummers en de persoonlijke levenssfeer;
  - anders 20 jaar.

  Een langere duur weigert het platform; dat regelt het schema met `allOf`.
- **Einddatum.** De assistent rekent de einddatum uit: de datum van het stuk (of vandaag) plus de duur. Artikel 7.4 rekent met de ouderdom van het document.
- **Terug naar openbaar.** Kiest de medewerker weer "openbaar", dan verdwijnen grond, duur en einddatum, en gaan ze niet mee naar het platform.
- **De gronden.** De dertien gronden staan in het contract (`BEPERKINGSGRONDEN`), met lid, onderdeel en maximale termijn.

## 2. Uit hoofde van welke taak (art. 2.5)

Artikel 2.5 noemt onder meer: inhoud, uniek identificatiekenmerk, wanneer, door wie en uit hoofde van welke taak, samenhang, plaats in de ordening, beheeractiviteiten, de categorie uit het selectiebesluit en de bewaartermijn.

- **Rol "taak".** MDTO `activiteit` en TMLO `context.activiteit` krijgen de rol taak en staan standaard aan. RGBZ heeft een aanvulling "taak", standaard uit, omdat de taak in het zaakgericht werken uit het zaaktype volgt.
- **Datum en auteur.** In MDTO en TMLO staan de velden voor datum en betrokkene/actor nu standaard aan.
- **Waarschuwingen in de modelcontrole (beheerportaal).** Een model krijgt een waarschuwing als het geen veld heeft voor:
  - de datum of de auteur;
  - de taak of de zaak;
  - het dossier of de zaak;
  - de openbaarheid, of bij openbaarheid de grond, duur en einddatum.
- **Wat er al was.** Identificatie, gebeurtenissen (beheeractiviteiten) en het formaat legt het platform zelf vast. Categorie en bewaartermijn komen uit het classificatiemodel.

## 3. Werkomgeving en integriteit (art. 2.8)

Voor stukken die langer dan tien jaar worden bewaard.

- **Onder a: hardware, besturingsprogrammatuur en toepassingsprogrammatuur.** Bij elke versie legt het platform `omgeving` vast:
  - de werkomgeving, gemeld door de adapter: programma en versie (Office.js `diagnostics`; in LibreOffice de productversie) en het besturingssysteem;
  - de browser of webview van het paneel;
  - het platform zelf: naam, versie, Node.js en besturingssysteem.

  De omgeving staat ook in de gebeurtenis.
- **Onder b: resultaten van integriteitscontroles.** De worker leest elke versie eens per 30 dagen terug (`INTEGRITEIT_DAGEN`), ontsleutelt haar en vergelijkt de sha256. Het resultaat komt in de tabel `integriteitscontroles` (ok, afwijkend of onleesbaar), en het platform toont de laatste uitkomst bij elke versie.

  Bij een afwijking volgen een gebeurtenis `integriteit.afwijking` en een melding in het log. Dat is mogelijk een incident dat binnen 72 uur bij de Inspectie gemeld moet worden (art. 7.1).
- **Onder c: permanent uniek identificatiekenmerk.** De identificatie (UUID) van het platform verandert nooit.

## 4. Duurzaam bestandsformaat (art. 2.9)

Het platform maakt van elke zakelijke versie zo snel mogelijk een weergave in **PDF/A-2b met PDF/UA-1** (profiel in de weergave). Dat doet het ook van elke geanonimiseerde weergave: dat is wat openbaar gemaakt wordt.

- **Omzetten.** Gotenberg doet het werk, met LibreOffice voor docx, odt, xlsx, ods, pptx en odp, en Chromium voor html. Het draait in een container op VPS 2 (profiel `omzetten`, standaard aan), zonder poort naar buiten. Chromium mag niets van het netwerk halen en voert geen JavaScript uit.
- **Metadata.** Ze gaan vóór het omzetten in een kopie van het bestand, als documenteigenschappen (titel, auteur, omschrijving, trefwoorden, taal). LibreOffice zet ze in de XMP (dc:title, dc:creator, pdf:Keywords). Achteraf in de PDF schrijven breekt PDF/A.
- **Geanonimiseerde weergave.** Die krijgt alleen haar eigen eerste kop als titel, omdat de metadata persoonsgegevens kunnen bevatten.
- **Versleuteling en herstel.** De PDF wordt versleuteld zoals de versie zelf. Mislukt omzetten (omzetter even weg), dan probeert de worker het na een uur opnieuw.
- **Getest.** Met de echte LibreOffice: de PDF heeft `pdfaid:part 2` en `pdfuaid:part 1`, en de titel, auteur en trefwoorden staan in de XMP.

## Aandachtspunten

- LibreOffice 24.2 zet een `&` uit de titel in de XMP dubbel geëscaped (`&amp;amp;`); het Info-woordenboek van de PDF heeft hem goed. Te volgen bij een nieuwere LibreOffice in Gotenberg.
- De taal van de PDF (`/Lang`) komt uit het document zelf, niet uit de metadata. Een document met Engels als standaardtaal wordt dus een Engelse PDF.
- Een formele PDF/A-validatie (veraPDF) zit nog niet in de keten. Dat is een kandidaat voor de worker of voor de overbrenging.
- Overbrengen (art. 2.12 en 2.13: openbaarheid vastleggen en versleuteling verwijderen), de verklaring van vernietiging (art. 4.2) en een export met metadata (art. 2.4) volgen later.
- **Gotenberg moet nog draaien op VPS 2.** De container kon hier niet worden opgehaald; de configuratie is gecontroleerd tegen de documentatie van Gotenberg 8. Reken op ongeveer 1 GB extra geheugen.
