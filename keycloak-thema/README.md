# Inlogthema `oa`

Het inlogscherm van Keycloak in de stijl van de OA-panelen: dezelfde kop (icoon, titel, korte uitleg), dezelfde Utrecht-componenten en het voorbeeldthema van NL Design System, met de compacte maten van `oa-paneel`. Het past in een zijbalk van ongeveer 380 pixels (LibreOffice, Word, Collabora) en staat in een gewone browser als kaart in het midden.

## Hoe het werkt

- `oa/login/theme.properties` bouwt voort op het basisthema van Keycloak (`parent=base`). Alleen de opmaak (`template.ftl`) is eigen. De pagina's zelf (inloggen, wachtwoord bijwerken, foutmeldingen, uitloggen) komen ongewijzigd uit Keycloak; de klassen in `theme.properties` geven ze de Utrecht-stijl.
- `oa/login/resources/css/`:
  - `voorbeeld-theme.css`: de design tokens van het voorbeeldthema, als terugval.
  - `utrecht.css`: alleen de Utrecht-componenten die het thema gebruikt.
  - `oa-login.css`: de eigen opmaak.
  
  Bij een nieuwe versie van die pakketten draai je `./bouw-css.sh` (Node.js 20+); de uitkomst staat in git.
- `oa/login/messages/`: eigen teksten in het Nederlands en Engels. De rest komt uit Keycloak.
- `oa/login/login-otp.ftl`: eigen versie van de pagina voor de code uit de app. Bij meer gekoppelde apps staat de laatst gekoppelde voorgeselecteerd, met uitleg (zie `docs/inloggen-herstel.md`).
- `oa/email/`: e-mailthema met een eigen herstelmail ("Wachtwoord of authenticator kwijt?"); de rest uit Keycloak.
- De integratielaag stuurt `ui_locales=nl` mee (of `?taal=en` op `/api/auth/login`). Anders volgt Keycloak de taal van de zijbalk, en die is vaak Engels.

## Huisstijl

Kleuren en lettertype komen uit de huisstijl van de inrichting: `OA_HUISSTIJL` in `.env`, een naam uit `../huisstijl/catalogus.txt` (zie [../huisstijl/README.md](../huisstijl/README.md)). `bijwerken.sh` haalt die CSS van npm en koppelt hem in Keycloak aan als `resources/huisstijl/huisstijl.css`. De klasse komt via `OA_HUISSTIJL_KLASSE` in `theme.properties` (`${env.OA_HUISSTIJL_KLASSE:voorbeeld-theme}`).

Zonder instelling blijft het voorbeeldthema van NL Design System over (`css/voorbeeld-theme.css`, meegeleverd). Dat geldt ook voor een inrichting die meerdere gemeenten bedient (bijvoorbeeld een GR), tenzij die een eigen huisstijl kiest: vóór het inloggen weet Keycloak nog niet bij welke gemeente je hoort.

## Op de server

- `vps3-diensten.yml` koppelt `keycloak-thema/oa` en `huisstijl/` alleen-lezen in Keycloak.
- Een nieuwe server krijgt het thema via de realm-import (`"loginTheme": "oa"`).
- `bijwerken.sh` op VPS 3 zet het thema op het realm en herstart Keycloak als er iets in `keycloak-thema/` of aan de huisstijl is veranderd. Keycloak houdt thema's in het geheugen.
- Terug naar het standaardthema van Keycloak: `OA_LOGIN_THEMA=keycloak.v2` in `.env` op VPS 3, en dan `bijwerken.sh`.

## Lokaal proberen

Met een uitgepakte Keycloak (dezelfde versie als in `vps3-diensten.yml`):

```sh
ln -s "$PWD/oa" keycloak-26.8.2/themes/oa
keycloak-26.8.2/bin/kc.sh start-dev --spi-theme--cache-themes=false --spi-theme--cache-templates=false
```

Kies daarna in de beheerconsole bij het realm onder *Realm settings → Themes* het inlogthema `oa`. Wijzigingen in de sjablonen en de CSS zie je dan meteen na verversen.
