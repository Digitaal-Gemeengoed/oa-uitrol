# Office Assistent — anonimiseren in het document (ontwerp)

*Prototype Digitaal GemeenGoed · 9 november 2026, aangevuld 25 november 2026 · besluiten van Erik Hoekstra*

## Uitgangspunten (besloten)

1. Anonimiseren gebeurt in het document zelf (het hoofdvenster), zoals in de MIRA-demo: plaatshouders verschijnen al tijdens de voorvertoning in de tekst, gekleurd per PPL-niveau en gestippeld zolang het een voorvertoning is.
2. Originele waarden staan alleen in de lijst in het paneel van de assistent (volgens het PPL-niveau van wie kijkt), nooit terug in het document. Zo zet AutoSave geen persoonsgegevens in een nieuwe versie. Uitzondering (25 november): in LibreOffice Writer kan de gebruiker de originelen binnen het eigen niveau tijdelijk in de tekst tonen, mits opslaan, exporteren en afdrukken dan uitgeschakeld zijn (zie *Na het bevestigen*).
3. Anonimiseren leidt tot een nieuwe versie. Het origineel wordt eerst als versie vastgelegd; de assistent toont de versies met hun soort.
4. Het versienummer komt in de documenteigenschappen (eigenschap `Versie`; een veld in de koptekst kan die tonen). Het nummer is dat van het platform.
5. Terug naar het origineel: per gegeven volgens het PPL-niveau van de categorie; het hele document alleen met PPL 3 en een reden, als nieuwe versie.
6. Sleutel vernietigen: de beheerder kiest apart wat er met de originele versies gebeurt; de rechten op het origineel kunnen worden beperkt.

## Werkwijze

0. **Origineel vastleggen.** Wijkt het document af van de laatste versie, dan eerst een nieuwe versie N. Daarna een anonimiseersessie.
1. **Vinden en vervangen.** De herkenning vindt de gegevens; de assistent registreert ze als voorvertoning (versleuteld, met vast nummer) en vervangt ze in het document door een gemarkeerde plaatshouder.
2. **Bijwerken in het document.** Klik op een plaatshouder → de kaart in het paneel. Selectie → "Anonimiseer selectie" (lint, werkbalk, rechtermuismenu). Per plek terugzetten ("De-anonimiseer", "Laat staan").
3. **Paneel.** Per gegeven een kaart: plaatshouder, PPL, AVG-artikel, algoritme, sleutel, origineel (volgens niveau), "Toon in document".
4. **Bevestigen.** Register definitief; versie N+1 (soort *anonimisering*, bron N); markering wordt vast.
5. **Terug.** Per gegeven of het hele document (zie boven); altijd als nieuwe versie.

## Na het bevestigen

*Aanvulling 25 november 2026.*

- **De lijst blijft.** Na Bevestigen blijven de kaarten staan, met status *bevestigd*.
- **Herkennen bij openen.** Opent iemand een al geanonimiseerd document en start de assistent, dan leest `anonimiseren.hervat()` de plaatshouders in het document. Staan die in het register van het stuk (`GET /objecten/:id/pii`), dan bouwt de assistent de lijst daaruit op, ook als er geen voorvertoningen meer zijn.
- **Originelen in de lijst.** *Originelen tonen* vraagt in één verzoek (`POST /objecten/:id/pii/onthul`) de waarden van alle gegevens binnen het niveau van de gebruiker op. Het platform controleert het niveau opnieuw en legt het inzien vast (`pii.ingezien`). Gegevens boven dat niveau blijven zonder waarde; de kaart noemt het benodigde niveau.
- **Originelen in de tekst** (alleen LibreOffice Writer; adapter `toonPiiOriginelen`). Voorwaarden en werking:

| Onderdeel | Uitwerking |
|---|---|
| Voorwaarde | Het document is opgeslagen en ongewijzigd, en er staat geen voorvertoning open. |
| Alleen-lezen | Het document gaat op alleen-lezen (*Document bewerken* uit); typen kan niet. |
| Niet gewijzigd | Het document wordt niet als gewijzigd gemarkeerd (`disableSetModified`): geen herstelkopie, geen vraag om op te slaan bij sluiten. |
| Opdrachten | Een dispatch-interceptor maakt Opslaan, Opslaan als, Exporteren (ook PDF), Afdrukken, Mailen, Ondertekenen, Opnieuw laden en *Document bewerken* grijs en laat ze niets doen. |
| Vangnet | Wordt het document toch opgeslagen of gekopieerd (macro, API), dan gaan bij `OnSave`/`OnSaveAs`/`OnCopyTo` eerst de plaatshouders terug, en na afloop weer de originelen. |
| Ongedaan maken | De wissel staat niet in de ongedaan-maken-lijst. |
| Herkenbaar | De originelen staan onderstippeld; opmerkingen houden hun plaatshouders. |
| De assistent | Zolang de originelen in de tekst staan, weigert de brug het lezen en wijzigen van het document; het paneel zet de overige handelingen stil. |
| Terug | *Plaatshouders terug in de tekst*, het verlaten van het tabblad of het sluiten van de assistent zet de plaatshouders terug en heft het alleen-lezen op. |

Word en Collabora tonen de originelen alleen in de lijst: daar is opslaan niet betrouwbaar uit te zetten (AutoSave, gedeelde bewerking).

## Platform

- `pii_register.status`: voorvertoning of bevestigd. Voorvertoningen mogen weg; een gebeurtenis pas bij bevestigen (alleen aantallen).
- Per versie: `soort` (gewoon, anonimisering, terugzetting), `bronversie`, en `ppl`: het niveau dat nodig is om de versie te lezen (origineel 3; geanonimiseerd 0; na terugzetten per gegeven het niveau van die categorie). Vervangt `objecten.pii_tot_versie`.
- Per versie `beperkt`: alleen informatiebeheer (rol beheerder) mag lezen.

## Kanttekeningen

- De versiegeschiedenis van SharePoint/OneDrive bevat wat er vóór het anonimiseren stond. Dat is een vraag voor informatiebeheer.
- Het origineel is onder de Archiefwet het archiefstuk; vernietigen vóór de bewaartermijn kan niet (en Object Lock houdt het tegen). Daarom bij vernietigen van een categoriesleutel: originele versies laten of beperken; echte vernietiging volgt het vernietigingsproces.
- Terug naar het origineel zet gegevens weer in het werkdocument (en in de autosave): daarom PPL 3, reden, geschiedenis.
- Eén anonimiseersessie per document tegelijk.
- Collabora geeft klik en selectie niet door: daar gaat het alleen van kaart naar plek.

## Per werkomgeving

| Werkomgeving | Plaatshouder | Klik | Selectie |
|---|---|---|---|
| Demo | gekleurde span (MIRA) | ja | ja |
| Word | inhoudsbesturingselement, vergrendeld, kleur per niveau | ja (WordApi 1.5) | lint, rechtermuismenu |
| LibreOffice Writer | bladwijzer + achtergrondkleur | selectieluisteraar via de brug | werkbalk, rechtermuismenu |
| Calc / Excel | celtekst + celkleur | celselectie | ja |
| Impress / PowerPoint | tekst; kleur waar mogelijk | beperkt | ja |
| Collabora | vervangen en kleuren via UNO | nee | via het paneel |

## Fasen

- **A:** contract, platform (migratie 007), kern, paneel met kaarten, demo-werkomgeving.
- **B:** Word en LibreOffice Writer; lint/rechtermuismenu; eigenschap `Versie`; terug naar het origineel voor het hele document.
- **C:** rekenbladen, presentaties, Collabora, documenteigenschappen (auteur) anonimiseren.
