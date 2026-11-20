# Huisstijl van de inrichting

Het inlogscherm (Keycloak, thema `oa`) en het paneel vóór het inloggen gebruiken de huisstijl van de inrichting. Een huisstijl is een **design-tokens-pakket uit [NL Design System](https://nldesignsystem.nl/)**: CSS-variabelen onder één klasse (bijvoorbeeld `.haarlem-theme`), die de Utrecht-componenten van paneel en inlogscherm lezen. Na het inloggen gebruikt het paneel het thema van de gemeente van de medewerker. Zie ook OA-ADR-011 in het architectuurdocument.

## Kiezen

Zet in `.env` op **VPS 1 en VPS 3** dezelfde naam uit `catalogus.txt`, en draai `bijwerken.sh` (eerst VPS 3, dan VPS 1):

```sh
OA_HUISSTIJL=haarlem
```

Zonder instelling geldt `voorbeeld`, het voorbeeldthema van NL Design System. Dat is ook de logische keuze voor een inrichting die meerdere gemeenten bedient, tenzij het samenwerkingsverband een eigen huisstijl heeft. `OA_HUISSTIJL_KLASSE` zet `bijwerken.sh` zelf; die hoeft niemand met de hand te vullen.

## De catalogus

`catalogus.txt` heeft per huisstijl één regel met vijf kolommen:

| Kolom | Betekenis | Voorbeeld |
| --- | --- | --- |
| naam | De waarde voor `OA_HUISSTIJL` | `haarlem` |
| klasse | De CSS-klasse waaronder de tokens staan | `haarlem-theme` |
| pakket | Het npm-pakket met de design tokens | `@nl-design-system-unstable/haarlem-design-tokens` |
| versie | Een vaste versie, nooit een bereik | `1.0.0` |
| bestand | Het CSS-bestand in het pakket | `dist/index.css` |

Nu in de catalogus:

| Naam | Pakket | Versie |
| --- | --- | --- |
| `voorbeeld` | `@nl-design-system-unstable/voorbeeld-design-tokens` | 14.2.0 |
| `haarlem` | `@nl-design-system-unstable/haarlem-design-tokens` | 1.0.0 |

## Een gemeente toevoegen

1. Zoek het design-tokens-pakket van de gemeente op npm. Veel staan onder `@nl-design-system-unstable/<gemeente>-design-tokens`; sommige gemeenten publiceren onder een eigen scope.
2. Kijk in het pakket welk CSS-bestand de tokens bevat (meestal `dist/index.css` of `dist/theme.css`) en onder welke klasse ze staan (meestal `.<gemeente>-theme`).
3. Voeg één regel toe aan `catalogus.txt` en zet `OA_HUISSTIJL` op de nieuwe naam.

Heeft een gemeente nog geen pakket, dan blijft het voorbeeldthema. Een pakket maken is werk voor de gemeente of haar huisstijlbeheerder; NL Design System beschrijft hoe.

## Wat er op de server gebeurt

- `installeer.sh` en `bijwerken.sh` (VPS 1 en VPS 3) halen het pakket van npm. Ze controleren de integriteit die npm opgeeft (`dist.integrity`, SHA-512) en zetten de CSS in `huisstijl/huisstijl.css`, met de herkomst in de eerste regel. Staat die versie er al, dan gebeurt er niets.
- Mislukt het ophalen, of klopt het pakket niet met de controlesom, dan blijft de vorige huisstijl staan en meldt het script dat.
- `huisstijl.css` staat niet in git: de huisstijl van een gemeente valt onder haar eigen licentie. Die van Haarlem is bijvoorbeeld alleen voor gebruik door de gemeente Haarlem.
- Keycloak (VPS 3) krijgt de map aangekoppeld als `themes/oa/login/resources/huisstijl` en de klasse via `OA_HUISSTIJL_KLASSE`; Keycloak herstart als de huisstijl verandert.
- De integratielaag (VPS 1) krijgt de map aangekoppeld als `/app/huisstijl` en levert `/api/huisstijl` (de klasse) en `/api/huisstijl/css`. Het paneel laadt die CSS alleen als de huisstijl er niet al in zit (voorbeeld en Haarlem zitten erin).

## Beperkingen

- **Lettertypen.** Sommige pakketten noemen een lettertype met een betaalde licentie (Haarlem: Sofia Pro). Dat wordt niet meegeleverd; het scherm gebruikt dan het reservelettertype dat het pakket noemt.
- **Alleen tokens.** Een pakket geeft kleuren, lettertypen en maten, geen logo. Het inlogscherm toont het icoon en de naam van de Office Assistent, niet het logo van de gemeente.
- **Versies.** Een nieuwe versie van een pakket komt pas na een aanpassing van de catalogus. Zo verandert een huisstijl niet ongemerkt.
