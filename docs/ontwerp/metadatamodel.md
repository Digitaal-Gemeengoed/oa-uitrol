# Office Assistent — metadatamodel per gemeente (beheerportaal)

*Vastgelegd 9 november 2026; gebouwd in oa-beheer 0.2.0, oa-contract 0.5.0, opendop-mini 0.8.0, oa-kern 0.5.1, oa-paneel 0.9.0, oa-adapters 0.16.1 (uitrol 0.17.0). Naam en versie in paneel en bestand: 10 november 2026, uitrol 0.19.0.*

## Besluit

Een gemeente kiest in het beheerportaal (pagina **Metadatamodel**) een **basismodel**: MDTO, RGBZ of TMLO. Daarbinnen zet informatiebeheer velden aan of uit, maakt ze verplicht, past label, hulptekst, waardelijst en volgorde aan, en voegt eigen velden toe. Publiceren maakt een **nieuwe versie van het objecttype** `document`, alleen voor die gemeente. Stukken houden de versie waarmee ze zijn vastgelegd.

Gekozen door Erik (boven het alternatief "één vaste catalogus op MDTO-basis met vertalingen naar RGBZ/TMLO").

## Hoe het werkt

- **TOOI** is geen model maar levert waardelijsten (o.a. Woo-informatiecategorieën).
- De catalogus en de regels staan in **oa-contract** (`metadatamodellen.ts`); het platform voert ze uit. Het portaal stuurt alleen de keuze (`MetadatamodelConfig`).
- Elk veld kan een **rol** hebben (titel, omschrijving, informatiecategorie, vertrouwelijkheid, taal, zaak, dossier, auteur, datum, trefwoorden, status). Voorstellen, zoeken, filteren en de zoekpagina werken via de rol, dus ongeacht het model. Een rol die later in de catalogus komt, geldt via het element uit het basismodel ook voor oudere schema's.
- Het schema draagt `x-oa-model`, `x-oa-config` (de keuze, ook voor de veldvolgorde en de naam) en per veld het element (`x-mdto`/`x-rgbz`/`x-tmlo`) en `x-oa-rol`.
- Woo-informatiecategorie en zaak zijn bij RGBZ/TMLO "aanvullingen" (geen element van het model).
- Toetsing: fouten (geen titel, dubbele rol, keuzeveld zonder opties …) blokkeren publiceren; waarschuwingen (veld dat het model verplicht noemt, geen Woo-categorie) niet.
- Rechten in het portaal: `metadata.view`, `metadata.manage`. Publiceren altijd met reden; in de audit van het portaal én als gebeurtenis in het platform.

## Versies en naam (10 november 2026)

- **Naam**: de beheerder geeft het model een naam (`config.naam`, max. 80 tekens), bv. "RGBZ Haarlem". Leeg: de naam van het basismodel; zonder keuze: "Standaardmodel". Een andere naam is een wijziging en dus een nieuwe versie.
- **Per stuk**: het platform bewaart bij elk object `objecttype_versie`; het paneel laadt bij een vastgelegd stuk die versie, niet de actuele. Dat bestond al; nieuw is dat het ook zichtbaar is.
- **Paneel**: klein bovenaan Metadateren "RGBZ Haarlem · versie 4", bij een ouder stuk "· nu geldt versie 5". Overzicht: volledige identificatie, versie, status (als het model een statusveld heeft), metadatamodel met versie.
- **Bestand**: de afdruk (`oa-afdruk`) noemt `objecttypeVersie` en `model`. Documenteigenschappen: Identificatie, Versie, Metadatamodel ("RGBZ Haarlem, versie 4") en Status. Bijgewerkt bij registreren, nieuwe versie en metadata vastleggen. Het platform blijft de bron; de eigenschappen zijn een afdruk.

## Bekende beperkingen

- Overstappen naar een ander model **migreert bestaande stukken niet**; ze houden hun oude versie en velden. Een knop "overstappen op het nieuwe model" per stuk (met veldvertaling via de rollen) is een mogelijke volgende stap.
- Over gemeenten heen zoeken en overbrengen naar het e-Depot werkt via de rollen; voor velden zonder rol (bv. eigen velden) is dat per gemeente maatwerk.
- Alleen RGBZ heeft een statusveld; MDTO en TMLO niet (een eigen keuzeveld met rol "status" kan).
- De catalogus is Nederlandstalig; het portaal zelf is NL/EN.
