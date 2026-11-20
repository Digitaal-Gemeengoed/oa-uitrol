# Office Assistent — documenteigenschappen en de titel (ontwerp)

*Prototype Digitaal GemeenGoed · 20 november 2026 · besluiten van Erik Hoekstra*

## Uitgangspunten (besloten)

1. Elk document heeft een titel (WCAG 2.2, succescriterium 2.4.2). De titel staat in de documenteigenschap *Titel*. Een regel met het opmaakprofiel *Titel* in de tekst is niet verplicht, maar er is er hooguit één.
2. Kop 1 mag vaker voorkomen: een document met meerdere hoofdstukken heeft meerdere koppen 1. De regel "meer dan één kop 1" is vervallen.
3. Staan er meer regels met het opmaakprofiel *Titel* in het document, dan ruimt de medewerker dat eerst op met de toegankelijkheidstoets. Pas daarna vult de assistent de documenteigenschap en de metadata met de titel.
4. Documenteigenschappen en metadata vullen elkaar aan, in beide richtingen. De documenteigenschappen bevatten zo veel mogelijk van de metadatavelden, omdat ze bij publicatie in het kader van de Woo de vindbaarheid bepalen.
5. Voor publicatie worden ook de documenteigenschappen geanonimiseerd. De naam van de auteur wordt de naam van de organisatie.
6. Gegevens over de medewerker (volledige naam, afdeling, rubricering) komen via Keycloak uit de identiteitsvoorziening van de gemeente (IAM, Entra ID of vergelijkbaar).

## Het opmaakprofiel Titel in de html

De adapters zetten een regel met het opmaakprofiel *Titel* om naar `<h1 data-oa-stijl="titel">`. Het attribuut is vastgelegd in het contract (`TITEL_ATTRIBUUT`, `TITEL_WAARDE`). Bij het herstellen gaat het attribuut mee terug: een herstel aan de titelregel laat het opmaakprofiel *Titel* staan, en "Maak hier kop 1 van" haalt het weg.

## Toegankelijkheidstoets

| Situatie | Bevinding | Herstel |
|---|---|---|
| Eén regel *Titel*, eigenschap *Titel* leeg of anders | Fout, 2.4.2 | Eigenschap *Titel* = de tekst van die regel |
| Geen regel *Titel*, eigenschap *Titel* leeg | Fout, 2.4.2 | Vraag om de titel; die gaat in de eigenschap |
| Meer dan één regel *Titel* | Waarschuwing per extra regel, 2.4.2 | "Maak hier kop 1 van"; de eigenschap wacht tot er één over is |
| Werkomgeving kan geen eigenschappen schrijven | Melding | Handmatig via Bestand → Eigenschappen |

De bevinding over de eigenschap heeft de bron `bestand`. Een bevinding van de toegankelijkheidsdienst over de titel van het bestand vervangt de assistent door deze bevinding.

## Van eigenschappen naar metadata (voorstellen)

Bij het openen van het paneel leest de assistent de documenteigenschappen en stelt waarden voor, alleen voor velden die nog leeg zijn:

- **titel**: de enige regel *Titel*; anders de eigenschap *Titel*; anders de eerste kop 1 (of de titel van de eerste dia). Bij meer regels *Titel* geen voorstel, met een aanwijzing onder het veld.
- **auteur**: de naam van de ingelogde medewerker; anders de eigenschap *Auteur*.
- **trefwoorden** en **omschrijving**: de gelijknamige eigenschappen (voor de omschrijving anders het *Onderwerp*).
- **taal**: de eigenschap *Taal* ("nl-NL" wordt "nl"; bij RGBZ "dut"), als het model die taal kent.

Het platform leidt: de assistent stelt voor, de medewerker beslist.

## Van metadata naar eigenschappen (na vastleggen)

Na het vastleggen schrijft de assistent de metadata in de documenteigenschappen, niet bij een persoonlijk stuk. Welk veld waarheen gaat, volgt uit de rol in het metadatamodel:

| Rol | Standaardeigenschap |
|---|---|
| titel | Titel |
| omschrijving | Opmerkingen (Word, Excel, PowerPoint) / Beschrijving (LibreOffice) |
| trefwoorden | Trefwoorden |
| auteur | Auteur |
| taal | Taal (twee letters) |
| status | Status |
| informatiecategorie | Categorie |

Alle andere velden gaan als eigen eigenschap mee, onder hun label (bijvoorbeeld *Vertrouwelijkheid*, *Zaak*). Eigenschappen die met `oa-` beginnen zijn van de assistent zelf en tellen niet mee.

## Anonimiseren

Bij het bevestigen van een anonimisering in het document vervangt de assistent ook in de documenteigenschappen elke gevonden waarde door de plaatshouder (de langste waarden eerst). De eigenschap *Auteur* wordt de naam van de organisatie ("Gemeente Haarlem"), zodat de geanonimiseerde versie geen naam van een medewerker meer bevat.

## Per werkomgeving

| Werkomgeving | Lezen | Schrijven | Bijzonderheden |
|---|---|---|---|
| Word | ja | ja | Office.js kent geen *Taal* en *Status*: die gaan als eigen eigenschap mee. |
| Excel | ja (ExcelApi 1.7) | ja | Als Word. |
| PowerPoint | ja (PowerPointApi 1.7) | ja | Als Word. |
| LibreOffice | ja | ja | *Categorie* en *Status* bestaan niet als standaardeigenschap: eigen eigenschap. *Taal* als Locale. |
| Collabora (WOPI) | nee | nee | De assistent valt zichtbaar terug: de bevinding vraagt om handmatig invullen. |
| Demo-tekstverwerker | ja | ja | Knop *Titel* in de werkbalk. |

## Open punten

- **Publicatie via DiWoo.** De koppeling moet nog worden uitgewerkt. Het voorstel aan het platform is: metadata in de documenteigenschappen, PDF/A-2 als formaat en een koppeling met het publicatiedepot van de gemeente op basis van S3.
- **PDF/A-2.** Bij omzetten naar PDF/A moeten de documenteigenschappen in de XMP-metadata terechtkomen (dc:title, dc:creator, dc:language). Dat vraagt een controle per werkomgeving.
- **Gebruikersgegevens uit Keycloak.** Afdeling en rubricering zijn nog niet aangesloten. Ze vragen een mapper in Keycloak per identiteitsvoorziening.
