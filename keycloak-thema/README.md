# Inlogthema `oa`

Het inlogscherm van Keycloak in de stijl van de OA-panelen: dezelfde kop (icoon, titel, korte uitleg), dezelfde Utrecht-componenten en het voorbeeldthema van NL Design System, met de compacte maten van `oa-paneel`. Het past in een zijbalk van ongeveer 380 pixels (LibreOffice, Word, Collabora) en staat in een gewone browser als kaart in het midden.

## Hoe het werkt

- `oa/login/theme.properties` bouwt voort op het basisthema van Keycloak (`parent=base`). Alleen de opmaak (`template.ftl`) is eigen. De pagina's zelf (inloggen, wachtwoord bijwerken, foutmeldingen, uitloggen) komen ongewijzigd uit Keycloak; de klassen in `theme.properties` geven ze de Utrecht-stijl.
- `oa/login/resources/css/`:
  - `voorbeeld-theme.css`: de design tokens van het voorbeeldthema.
  - `utrecht.css`: alleen de Utrecht-componenten die het thema gebruikt.
  - `oa-login.css`: de eigen opmaak.
  
  Bij een nieuwe versie van die pakketten draai je `./bouw-css.sh` (Node.js 20+); de uitkomst staat in git.
- `oa/login/messages/`: eigen teksten in het Nederlands en Engels. De rest komt uit Keycloak.
- De integratielaag stuurt `ui_locales=nl` mee (of `?taal=en` op `/api/auth/login`). Anders volgt Keycloak de taal van de zijbalk, en die is vaak Engels.

## Waarom het voorbeeldthema, en niet dat van de gemeente

Voor het inloggen weet Keycloak nog niet bij welke gemeente je hoort. Het paneel gebruikt het voorbeeldthema ook zolang het je gemeente niet kent, en voor gemeenten zonder eigen thema. Een huisstijl van één gemeente op het gezamenlijke inlogscherm mag bovendien niet altijd: die van Haarlem is volgens de licentie alleen voor gebruik door de gemeente Haarlem.

## Op de server

- `vps3-diensten.yml` koppelt `keycloak-thema/oa` alleen-lezen in Keycloak.
- Een nieuwe server krijgt het thema via de realm-import (`"loginTheme": "oa"`).
- `bijwerken.sh` op VPS 3 zet het thema op het realm en herstart Keycloak als er iets in `keycloak-thema/` is veranderd. Keycloak houdt thema's in het geheugen.
- Terug naar het standaardthema van Keycloak: `OA_LOGIN_THEMA=keycloak.v2` in `.env` op VPS 3, en dan `bijwerken.sh`.

## Lokaal proberen

Met een uitgepakte Keycloak (dezelfde versie als in `vps3-diensten.yml`):

```sh
ln -s "$PWD/oa" keycloak-26.8.2/themes/oa
keycloak-26.8.2/bin/kc.sh start-dev --spi-theme--cache-themes=false --spi-theme--cache-templates=false
```

Kies daarna in de beheerconsole bij het realm onder *Realm settings → Themes* het inlogthema `oa`. Wijzigingen in de sjablonen en de CSS zie je dan meteen na verversen.
