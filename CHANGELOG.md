# Wijzigingen

## 0.39.1 — 2026-11-26

- oa-beheer 0.21.0: uitnodiging opnieuw sturen, met de mail van Keycloak als het inlogaccount nog niet is ingesteld. Uitrollen: `bijwerken.sh` op VPS 1.
- Correctie in de uitrolstappen van 0.38.0 en 0.39.0: het beheerportaal draait op VPS 1, niet op VPS 3. De volgorde (eerst VPS 3, dan VPS 1) blijft gelijk.

## 0.39.0 — 2026-11-26

**Medewerkers beheren in het beheerportaal** (oa-beheer 0.20.0). Ontwerp: `docs/ontwerp/medewerkers-beheren.md`.
- `bijwerken.sh` op VPS 3 breidt de fijnmazige rechten van het service-account van het portaal uit: gebruikers beheren (aanmaken, in- en uitschakelen, mails laten sturen, sessies beëindigen), en daarbij alleen de rollen `medewerker`, `ppl-1`, `ppl-2` en `ppl-3` toekennen. Beheerrollen en de instellingen van de realm blijven buiten bereik (getest tegen Keycloak 26.8.2). Een bestaande inrichting wordt bijgewerkt.
- `bijwerken.sh` op VPS 3 zet op de client `oa-integratielaag` het adres voor het uitlogbericht (Back-Channel Logout, oa-integratielaag 0.16.0): uitloggen, uitschakelen of een ander niveau geldt direct in de Office Assistent.
- E-mailthema `oa`: eigen tekst voor de mail om het account in te stellen (nieuwe medewerker, herstelmail vanuit het portaal), Nederlands en Engels.
- `INRICHTING.md` en `docs/inloggen-herstel.md` bijgewerkt.
- Werkplaats: oa-integratielaag 0.16.0.
- Uitrollen: `bijwerken.sh` op VPS 3 (Keycloak en thema), daarna op VPS 1 (portaal en integratielaag). Keycloak moet mail kunnen versturen (`inlog.sh smtp` op VPS 3).

## 0.38.0 — 2026-11-26

**Het PPL-niveau van medewerkers instellen in het beheerportaal** (oa-beheer 0.19.0, pagina Medewerkers).
- `bijwerken.sh` op VPS 3 zet in de realm `gemeenten` de fijnmazige beheerrechten aan en geeft het service-account van het portaal één recht: bij gebruikers de rollen `ppl-1`, `ppl-2` en `ppl-3` toekennen en weghalen. Andere rollen toekennen, gebruikers wijzigen of sessies beëindigen kan het portaal niet (getest tegen Keycloak 26.8.2).
- Ook de maker van een geanonimiseerd stuk ziet na het bevestigen alleen de originelen binnen zijn eigen niveau (oa-paneel 0.24.1, oa-kern 0.16.1).
- `INRICHTING.md`: niveau wijzigen via het portaal.
- Uitrollen: `bijwerken.sh` op VPS 3 (Keycloak), daarna op VPS 1 (portaal en werkplaats). Geef daarna in het portaal bij **Groepen** de rechten Medewerkers (PPL-niveau) aan wie het niveau mag beheren.

## 0.37.3 — 2026-11-25

- oa-adapters 0.24.1 (LibreOffice-extensie 0.19.1): een geanonimiseerd document dat als .docx is opgeslagen, wordt weer herkend. Uitrollen: `bijwerken.sh` op VPS 1, daarna de extensie 0.19.1 opnieuw installeren.

## 0.37.2 — 2026-11-25

- Toegankelijkheidscontrole (oa-wcag 0.1.1): de plaatshouders van de anonimisering gelden niet meer als "gekleurde tekst zonder extra visuele aanduiding" (WCAG 1.4.1). Uitrollen: `bijwerken.sh` op VPS 3.

## 0.37.1 — 2026-11-25

- Werkplaats: opendop-mini 0.20.1 en oa-services 0.7.3 vragen oa-contract 0.16.0. In 0.37.0 vroegen ze nog `^0.15.0`, waardoor `npm ci` het contract in de openbare registry zocht en het bouwen op VPS 1 stopte.

## 0.37.0 — 2026-11-25

**Geanonimiseerde gegevens in beeld houden.** Ontwerp: `docs/ontwerp/anonimiseren-in-het-document.md`.
- De lijst met geanonimiseerde gegevens blijft na Bevestigen staan; een al geanonimiseerd document wordt bij het openen herkend en de lijst wordt uit het register opgehaald.
- De originele waarden binnen het eigen niveau (PPL) in de lijst, en in LibreOffice Writer desgewenst ook tijdelijk in de tekst, met het document op alleen-lezen en opslaan, exporteren en afdrukken uitgeschakeld.
- Werkplaats: oa-contract 0.16.0, oa-kern 0.16.0, oa-paneel 0.24.0, oa-adapters 0.24.0 (LibreOffice-extensie 0.19.0), oa-integratielaag 0.15.1, opendop-mini 0.20.1, oa-services 0.7.3.
- Uitrollen: `bijwerken.sh` op VPS 1; daarna de LibreOffice-extensie 0.19.0 opnieuw installeren.

## 0.36.0 — 2026-11-25

**De tweede factor herstellen.** Ontwerp en tests: `docs/inloggen-herstel.md`.
- **Herstelcodes**: na het koppelen van de authenticator-app maakt iedereen twaalf herstelcodes aan; bestaande gebruikers bij hun volgende inlog. Bij het inloggen: *Op een andere manier inloggen → Herstelcode*. Het token meldt dan `amr: mfa`; het portaal accepteert dat als tweede factor.
- **Wachtwoord of authenticator kwijt?** (herstel via e-mail): de link toont de QR-code opnieuw en vraagt een nieuw wachtwoord. De oude koppeling blijft staan tot de gebruiker haar verwijdert, zodat wie halverwege afhaakt nooit zonder authenticator staat. Alleen met e-mail voor Keycloak (`inlog.sh smtp`) en vanaf Keycloak 26.7.2 (CVE-2026-18963).
- Nieuw script `server/inlog.sh` (VPS 3): `smtp`, `authenticator <e-mailadres>` (koppeling van één gebruiker resetten; na het wachtwoord de QR-code) en `status`.
- Inlogthema: teksten in de je-vorm voor herstelcodes en herstel; eigen `login-otp.ftl` (bij meer apps de laatst gekoppelde voorgeselecteerd, met uitleg); opmaak van de pagina met herstelcodes; e-mailthema `oa` met een eigen herstelmail.
- Aangescherpt: bescherming tegen raden aan (na tien pogingen oplopend wachten, max. 15 minuten); e-mailadres en gebruikersnaam alleen door een beheerder te wijzigen (het e-maildomein bepaalt de gemeente).
- Voorpagina `office.<domein>`: uitleg "QR-code gemist, of je telefoon of app kwijt?".
- Uitrollen: `bijwerken.sh` op VPS 3 (Keycloak herstart vanwege het thema), daarna `sudo /opt/oa-uitrol/server/inlog.sh smtp` op VPS 3 voor de herstellink. VPS 1: `bijwerken.sh` (voorpagina).

## 0.35.1 — 2026-11-24

- De proef met de assistent als extensie in Collabora staat **standaard aan** (`COLLABORA_EXPERIMENTEEL=true`) en staat op de voorpagina van `office.<domein>` als extra optie in de kaart Collabora Online (knop *Assistent als extensie (proef)*), met wat werkt, wat (nog) niet, en de vermeldingen (proef; raamwerk van Collabora experimenteel; merk en licentie van Collabora Online; EUPL 1.2). Ook een regel in "Wat werkt waar".
- Let op: `experimental_features` geldt voor heel Collabora, dus ook voor de gewone Collabora-pagina. Uitzetten: `COLLABORA_EXPERIMENTEEL=false`.
- Uitrollen: `bijwerken.sh` op VPS 1. Had je 0.35.0 al uitgerold, zet dan eerst in `.env` de regel `COLLABORA_EXPERIMENTEEL=false` op `true`.

## 0.35.0 — 2026-11-24

- **Proef: de assistent als extensie in Collabora Online** (oa-adapters 0.23.0, oa-integratielaag 0.15.0), naast de gewone Collabora-pagina. Standaard uit.
  - VPS 1: Collabora krijgt het pakket als volume (`bron/oa-adapters/collabora-extensie/pakket`) en `--o:experimental_features=${COLLABORA_EXPERIMENTEEL}`; `.env` krijgt `COLLABORA_EXPERIMENTEEL=false`.
  - Caddy: `/collabora-extensie` mag in een iframe van `office.<domein>` (frame-ancestors).
  - Aanzetten: `COLLABORA_EXPERIMENTEEL=true` in `.env` op VPS 1, `bijwerken.sh`, dan `https://oa.<domein>/collabora-proef`. Proefplan: `docs/ontwerp/collabora-extensie.md`.

## 0.34.1 — 2026-11-24

- Werkplaats: oa-adapters 0.22.1 (LibreOffice-extensie 0.18.1): het zijpaneel werkt weer bij een nieuw, leeg document.
- Uitrollen: `bijwerken.sh` op VPS 1 (de integratielaag levert de nieuwe extensie). Daarna de extensie opnieuw downloaden en installeren (Extra → Extensiebeheer → Toevoegen, dan LibreOffice herstarten).

## 0.34.0 — 2026-11-23

- **Gemeenten beheren in het portaal.** `docs/multi-tenant.md` bijgewerkt: Keycloak is de bron voor gemeenten en domeinen; een GR-brede beheerder met het recht *Gemeenten beheren* voegt gemeenten toe op de pagina Gemeenten (oa-beheer 0.18.0).
- VPS 3: `keycloak_gemeenten` geeft de client `oa-beheer` een service-account (`manage-organizations`, `view-users`, client scope `kc-admin-api`) en maakt gemeenten uit `GEMEENTEN` alleen nog aan als ze ontbreken. Nieuwe timer `oa-gemeenten.timer` koppelt elk kwartier gebruikers aan hun gemeente (`gemeenten.sh --koppelen`).
- VPS 1: het portaal krijgt `KEYCLOAK_INTERN` (het beheerscherm van Keycloak blijft dicht naar buiten). `BEHEER_GEMEENTEN` is nu optioneel: alleen de beginstand.
- Uitrollen: `bijwerken.sh` op VPS 3 (service-account, timer), dan VPS 1 (migratie 007 van het portaal gaat vanzelf). Geef daarna de groep van de superbeheerders in het portaal het recht *Gemeenten beheren*.

## 0.33.0 — 2026-11-23

- **Archiefregeling 2026** (Stcrt. 2026, 40895): nieuw ontwerp `docs/ontwerp/archiefregeling-2026.md` en OA-ADR-013. Openbaarheid met grond, duur en einddatum; de taak; werkomgeving en integriteitscontroles bij elke versie; PDF/A-2b met PDF/UA.
- VPS 2: nieuwe container `omzetter` (Gotenberg 8, profiel `omzetten`, standaard aan; ongeveer 1 GB geheugen). `bijwerken.sh` zet `OMZETTER_URL`, `GOTENBERG_VERSIE` en het profiel in `.env`. Uitzetten: `OMZETTER_URL=` (leeg) en `omzetten` uit `COMPOSE_PROFILES`.
- Werkplaats: oa-contract 0.15.0, opendop-mini 0.20.0, oa-services 0.7.2, oa-kern 0.15.0, oa-paneel 0.23.0, oa-adapters 0.22.0, oa-integratielaag 0.14.1.
- Uitrollen: `bijwerken.sh` op VPS 2 (migratie 013 gaat vanzelf, Gotenberg wordt opgehaald), dan VPS 3, dan VPS 1. LibreOffice-extensie 0.18.0 opnieuw installeren. In het beheerportaal: een nieuwe versie van het metadatamodel publiceren om openbaarheid en taak te krijgen.

## 0.32.0 — 2026-11-23

- **Meer gemeenten in één inrichting.** Nieuw: `docs/multi-tenant.md` en OA-ADR-012. Elke gemeente in `GEMEENTEN` op VPS 3 (met e-maildomeinen) wordt een organisatie in Keycloak; gebruikers worden op hun e-maildomein gekoppeld. `bijwerken.sh` doet dat op VPS 3 bij elke ronde; na een wijziging los: `server/gemeenten.sh`. Een nieuwe gemeente meldt zich daarna vanzelf aan bij het platform.
- Beheerportaal voor een GR: `BEHEER_GEMEENTEN` op VPS 1 (dezelfde waarde als `GEMEENTEN` op VPS 3).
- Werkplaats: oa-contract 0.14.0, opendop-mini 0.19.0, oa-services 0.7.1, oa-kern 0.14.0, oa-paneel 0.22.0, oa-adapters 0.21.1, oa-integratielaag 0.14.0; oa-beheer 0.17.0.
- Uitrollen: `bijwerken.sh` op VPS 3, dan VPS 2 (migratie 012 gaat vanzelf), dan VPS 1 (migratie 006 van het portaal gaat vanzelf). Controleer daarna op VPS 3 de regel `GEMEENTEN` in `.env`: die is aangevuld met haarlem.nl en zandvoort.nl.

## 0.31.0 — 2026-11-20

- **Documenteigenschappen en de titel.** Ontwerp in `docs/ontwerp/documenteigenschappen.md`: de documenttitel volgens WCAG 2.4.2 in de eigenschappen, hooguit één regel met het opmaakprofiel Titel, metadata en eigenschappen in beide richtingen, en anonimiseren van de eigenschappen (auteur wordt de organisatie).
- Werkplaats: oa-contract 0.13.0, opendop-mini 0.18.1, oa-kern 0.13.0, oa-services 0.7.0, oa-paneel 0.21.0, oa-adapters 0.21.0 (LibreOffice-extensie 0.17.0), oa-integratielaag 0.13.1.
- Uitrollen: `bijwerken.sh` op VPS 3 (diensten), dan VPS 1 (toegang). VPS 2 (platform) mag mee voor opendop-mini 0.18.1; daar verandert niets aan het gedrag. Geen migratie. In LibreOffice de extensie 0.17.0 opnieuw installeren.

## 0.30.2 — 2026-11-20

- **Herstel:** Keycloak startte niet meer na 0.30.0/0.30.1 ("error mounting … /opt/keycloak/themes/oa/login/resources/huisstijl … read-only file system"). De huisstijl wordt gekoppeld binnen de alleen-lezen koppeling van het thema, en daar kan Docker het koppelpunt niet zelf aanmaken. De map staat nu in de repo (`keycloak-thema/oa/login/resources/huisstijl/`). Nagespeeld met Docker: zonder de map dezelfde fout, met de map werkt het.
- Uitrollen: `bijwerken.sh` op VPS 3. Geen migratie.

## 0.30.1 — 2026-11-20

- **Herstel:** `bijwerken.sh` stopte zonder melding direct na "oa-uitrol …" op VPS 1 en VPS 3, zolang er nog geen huisstijl was opgehaald. De controlesom van het ontbrekende `huisstijl/huisstijl.css` mislukte, en onder `set -o pipefail` stopt het script dan. Nu geeft `controlesom` voor een ontbrekend bestand "geen".
- Getest door het hele script voor VPS 1 en VPS 3 te draaien onder dezelfde instellingen als op de server, vanaf een lege huisstijl en een tweede keer zonder wijzigingen (dan herstart Keycloak niet).
- Uitrollen: `bijwerken.sh` op VPS 3, dan VPS 1. Geen migratie.

## 0.30.0 — 2026-11-20

**Een huisstijl per inrichting.** Met `OA_HUISSTIJL` in `.env` (op VPS 1 en VPS 3) kiest een inrichting de huisstijl van het inlogscherm en van het paneel vóór het inloggen, bijvoorbeeld `haarlem`. Standaard blijft het voorbeeldthema van NL Design System.

- `huisstijl/catalogus.txt` noemt per huisstijl het design-tokens-pakket van NL Design System, de versie, het CSS-bestand en de klasse. Een gemeente toevoegen is één regel.
- De server haalt het pakket zelf van npm, controleert de integriteit die npm opgeeft, en zet de CSS in `huisstijl/huisstijl.css`. Die staat niet in git: de huisstijl van een gemeente is van die gemeente. Lukt het ophalen niet, of klopt het pakket niet, dan blijft de vorige huisstijl staan.
- Keycloak (VPS 3) en de integratielaag (VPS 1) krijgen de huisstijl aangekoppeld; Keycloak herstart als die verandert.
- oa-paneel 0.20.0, oa-adapters 0.20.8 en oa-integratielaag 0.13.0.
- Uitrollen: `bijwerken.sh` op VPS 3 en VPS 1. Geen migratie. Wil je een andere huisstijl: eerst `OA_HUISSTIJL=...` in `.env` op beide, dan `bijwerken.sh`.

## 0.29.0 — 2026-11-20

**Een inlogscherm in de stijl van de panelen.** Keycloak krijgt het thema `oa` (map `keycloak-thema/`): dezelfde kop, Utrecht-componenten en het voorbeeldthema van NL Design System als de panelen, passend in een zijbalk van ongeveer 380 pixels en als kaart in een gewone browser. Het geldt voor alle pagina's van het inloggen: inloggen, wachtwoord bijwerken, foutmeldingen. Het scherm opent in het Nederlands (oa-integratielaag 0.12.0 geeft `ui_locales` mee); Engels blijft te kiezen.

- `vps3-diensten.yml` koppelt het thema alleen-lezen in Keycloak; de realm-import zet het voor een nieuwe server.
- `bijwerken.sh` op VPS 3 zet het thema op het bestaande realm en herstart Keycloak als er iets in `keycloak-thema/` veranderde. `OA_LOGIN_THEMA=keycloak.v2` in `.env` zet het standaardscherm terug.
- Uitrollen: `bijwerken.sh` op VPS 3 (Keycloak herstart, inloggen kan dan een halve minuut niet) en VPS 1 (integratielaag). Geen migratie.

## 0.28.1 — 2026-11-20

De lockfile van de werkplaats past bij oa-paneel 0.19.1: de keuze Zakelijk / Persoonlijk staat weer naast elkaar. Uitrollen: `bijwerken.sh` op VPS 1 (toegang). Geen migratie.

## 0.28.0 — 2026-11-20

**Bijwerken zonder wachtwoord.** `beheer` mag `sudo /opt/oa-uitrol/server/bijwerken.sh` starten zonder het sudo-wachtwoord; op VPS 4 geldt dat ook voor `uitrol.sh` en `bijwerken.sh` van het gemeenschapsplatform. Voor elk ander commando blijft sudo om het wachtwoord vragen.

- De regel staat in `/etc/sudoers.d/oa-bijwerken` en wordt gecontroleerd met `visudo` voordat hij wordt geplaatst. Hij komt er alleen als de repo's en `/opt` van root zijn en voor anderen alleen-lezen; anders zou wie de scripts kan wijzigen root worden.
- Uitrollen: één keer `bijwerken.sh` op elke VPS, met wachtwoord. Daarna is het niet meer nodig. Geen migratie.
- Uitzetten: `sudo OA_SUDO_ZONDER_WACHTWOORD=nee /opt/oa-uitrol/server/bijwerken.sh`.

## 0.27.1 — 2026-11-20

**De repo's staan nu in de organisatie [Digitaal-Gemeengoed](https://github.com/Digitaal-Gemeengoed).** `haal-op.sh` haalt standaard daar op, het gemeenschapsplatform komt van `Digitaal-Gemeengoed/gemeenschap`, en alle links in de documentatie en de downloadpagina wijzen naar de nieuwe plek.

- `bijwerken.sh` zet de remote van `/opt/oa-uitrol` en `/opt/gemeenschap` om als die nog naar het oude account wijst. Het oude adres werkt via de doorverwijzing van GitHub nog, dus haast is er niet.
- Uitrollen: `bijwerken.sh` op elke VPS, in willekeurige volgorde. Geen migratie, geen nieuwe containers.

## 0.27.0 — 2026-11-20

De lockfile van de werkplaats past bij oa-contract 0.12.0, opendop-mini 0.18.0, oa-kern 0.12.3, oa-paneel 0.19.0, oa-adapters 0.20.7, oa-integratielaag 0.11.3 en oa-services 0.6.5: het classificatiemodel reageert op de status van een stuk (eerst classificeren, doorgeven aan de hele zaak of het dossier, klassen per status, attributen verplicht vanaf een status). Geen migratie.

## 0.26.0 — 2026-11-19

De lockfile van de werkplaats past bij opendop-mini 0.17.0, oa-kern 0.12.2, oa-paneel 0.18.0 en oa-adapters 0.20.6: een vastgelegde classificatie toont het paneel met de versie van het classificatiemodel waarmee ze is vastgelegd. Geen migratie.

## 0.25.0 — 2026-11-19

De lockfile van de werkplaats past bij oa-contract 0.11.0, opendop-mini 0.16.0, oa-kern 0.12.1, oa-paneel 0.17.0, oa-adapters 0.20.5, oa-integratielaag 0.11.2 en oa-services 0.6.4: standaardattributen in het classificatiemodel, met een voorstel voor persoonsgegevens.

- Uitrollen: eerst `bijwerken.sh` op VPS 2 (platform), daarna op VPS 1 (toegang: integratielaag, paneel en oa-beheer 0.15.0). Geen migratie. VPS 3 hoeft niet: het voorstel gebruikt de bestaande herkenning van persoonsgegevens.
- Bestaande classificatiemodellen blijven werken. Heeft een gemeente een eigen attribuut met de sleutel van een standaardattribuut (zoals `persoonsgegevens` of `hotspot`), dan meldt de controle dat bij de volgende versie; zet dan het standaardattribuut aan.

## 0.24.1 — 2026-11-19

**Sneller en zichtbaarder bouwen.**
- `npm ci` in de Dockerfile gebruikt een BuildKit-cache voor npm (`--mount=type=cache,target=/root/.npm`, met `--prefer-offline`). Pakketten die eerder zijn opgehaald, komen dan van de eigen schijf; een nieuw versienummer of een nieuwe lockfile hoeft niet alles opnieuw te downloaden. De eerste keer bouwen vult de cache.
- `bijwerken.sh` bouwt met een log in `/opt/oa-uitrol/bouw.log` en meldt hoe lang het bouwen duurde, met de vijf traagste stappen. Mislukt het bouwen, dan toont het de laatste 30 regels en stopt het; de draaiende containers blijven ongewijzigd (voorheen ging het script na een mislukte build door).
- Uitrollen: `bijwerken.sh` op de VPS'en die bouwen (1, 2 en 3), wanneer het uitkomt. Er verandert niets aan de werking.

## 0.24.0 — 2026-11-19

De lockfile van de werkplaats past bij oa-contract 0.10.0, opendop-mini 0.15.0, oa-kern 0.12.0, oa-paneel 0.16.0, oa-adapters 0.20.4, oa-integratielaag 0.11.1 en oa-services 0.6.3 (alleen de afhankelijkheid): ondersteunende stukken met categorieën (O1 tot en met O5) en toetsvragen.

- Uitrollen: eerst `bijwerken.sh` op VPS 2 (platform), daarna op VPS 1 (toegang: integratielaag, paneel en oa-beheer 0.14.0). Geen migratie. De LibreOffice-extensie hoeft niet opnieuw. VPS 3 (diensten) hoeft niet.
- Bestaande classificatiemodellen blijven werken: zonder categorieën is er één soort ondersteunend stuk, zoals voorheen. De categorieën komen er pas als informatiebeheer ze in het beheerportaal laadt en publiceert.

## 0.23.0 — 2026-11-19

De lockfile van de werkplaats past bij oa-contract 0.9.0, opendop-mini 0.14.0, oa-kern 0.11.0, oa-paneel 0.15.0, oa-adapters 0.20.3, oa-integratielaag 0.11.0 en oa-services 0.6.2 (alleen de afhankelijkheid): classificeren met de klasse van de zaak, ondersteunende stukken en eigen zoektermen.

- Uitrollen: eerst `bijwerken.sh` op VPS 2 (platform), daarna op VPS 1 (toegang: integratielaag, paneel en oa-beheer 0.13.0). Geen migratie. De LibreOffice-extensie hoeft niet opnieuw. VPS 3 (diensten) hoeft niet: daar verandert niets; de volgende keer bijwerken neemt de nieuwe lockfile mee.

## 0.22.4 — 2026-11-19

De lockfile van de werkplaats past bij oa-kern 0.10.0, oa-paneel 0.14.0 en oa-adapters 0.20.2 (Classificeren: kiezen in stappen).

- Uitrollen: `bijwerken.sh` op VPS 1 (toegang). Word, LibreOffice en de demo laden het nieuwe paneel vanzelf van de server; de LibreOffice-extensie hoeft niet opnieuw.

## 0.22.3 — 2026-11-19

De lockfile van de werkplaats past bij opendop-mini 0.13.0 (een geplande modelversie wijzigen).

- Uitrollen: eerst `bijwerken.sh` op VPS 2 (platform; voert migratie `011_vervangen.sql` uit), daarna op VPS 1 (oa-beheer 0.11.0).

## 0.22.2 — 2026-11-19

De lockfile van de werkplaats past bij oa-contract 0.8.2 en opendop-mini 0.12.0 (ingangsdatum voor modelversies).

- Uitrollen: eerst `bijwerken.sh` op VPS 2 (platform; voert migratie `010_ingang.sql` uit), daarna op VPS 1 (oa-beheer 0.10.0).

## 0.22.1 — 2026-11-18

De lockfile van de werkplaats past bij de nieuwe versies; zonder deze stap breekt `npm ci` bij het bouwen op VPS 1 en 3.

- oa-services 0.6.1: anonimiseren vindt meer in tabellen en rekenbladen (kolomkoppen, doorzetten, BSN met puntjes, postcodes met SA/SD/SS, geboortedatum).
- oa-adapters 0.20.1 (LibreOffice-extensie 0.16.0): datums en getallen in Calc en Excel zoals de cel ze toont, en plaatshouders ook in zulke cellen.
- oa-kern 0.9.0 en oa-paneel 0.13.0: Toegankelijkheid — *Alles herstellen*.
- Uitrollen: `bijwerken.sh` op VPS 3 (diensten) en VPS 1 (toegang); daarna de LibreOffice-extensie opnieuw installeren via `https://oa.<domein>/libreoffice`.

## 0.22.0 — 2026-11-11

**Het gemeenschapsplatform heeft een eigen repo**: [Digitaal-Gemeengoed/gemeenschap](https://github.com/Digitaal-Gemeengoed/gemeenschap). De map `gemeenschap/` en `vps4-gemeenschap.yml` zijn hier weg. Op VPS 4 haalt `server/installeer.sh` die repo op naar `/opt/gemeenschap` en geeft door; daarna rolt de server zelf uit vanuit GitHub: pagina's en menu's (`inhoud/`) na elke samenvoeging op `main`, de rest bij een nieuwe versie-tag. Zie INRICHTING.md, stap 12.

- Op VPS 1 tot 3 verandert niets.
- Had je 0.21.0 al op een VPS 4 geïnstalleerd? Dat is niet waarschijnlijk; vraag het anders, want `.env` moet dan naar `/opt/gemeenschap`.

## 0.21.0 — 2026-11-10

**Gemeenschapsplatform op VPS 4** (nieuw, los van de Office Assistent). Lid worden, profielen en groepen (WordPress met BuddyPress), traditionele fora (bbPress), contacten en nieuwsbrief (CiviCRM), en meldingen, wensen en projecten (Redmine), met één account via Keycloak op `aanmelden.<domein>`. Keycloak is de bron voor leden, organisaties, groepen (`/netwerk/gebruikers`, `contributors`, `members`, `kerngroep`) en de toestemming voor de nieuwsbrief; de andere onderdelen nemen dat over bij het inloggen, Redmine elke tien minuten. Zie INRICHTING.md, stap 12, en gemeenschap/README.md.

- `inrichten.sh` kent de rol 4 (gemeenschap): HTTP en HTTPS open, geen WireGuard, geen koppelen. `installeer.sh`, `bijwerken.sh` en `controleer.sh` geven op VPS 4 door aan de scripts in `gemeenschap/`.
- Elke nacht een back-up van de drie databases, de uploads en de Redmine-bestanden.
- Op VPS 1 tot 3 verandert niets.

## 0.20.1 — 2026-11-10

**Woo: "geen categorie"** (oa-contract 0.8.1, opendop-mini 0.11.1, oa-beheer 0.5.1). Niet elk stuk valt in een informatiecategorie van artikel 3.3 Woo. In het beheerportaal, bij Metadatamodel, zet je bij de Woo-informatiecategorie *Ook "geen categorie (niet actief openbaar)" aanbieden* aan en publiceer je een nieuwe versie; dan kan een medewerker dat kiezen in plaats van een categorie die niet klopt. Nieuwe modellen hebben het al aan.

## 0.20.0 — 2026-11-10

**Classificeren, bewaren en vergrendelen** (oa-beheer 0.5.0, opendop-mini 0.11.0, oa-contract 0.8.0, oa-kern 0.8.0, oa-paneel 0.12.0, oa-adapters 0.19.0, oa-integratielaag 0.10.0, oa-services 0.5.4).

- **Classificatie** in het beheerportaal: het classificatiemodel op basis van de Selectielijst gemeenten 2020 (VNG), met afwijkingen, eigen attributen, vergrendelen bij status en de status waarop de bewaartermijn ingaat.
- **Classificeren** in het paneel: de assistent stelt een klasse voor; het Overzicht toont tot wanneer het stuk bewaard wordt.
- Een vergrendeld stuk krijgt geen nieuwe versie; een wijziging wordt een **wijzigingsvoorstel** dat een vrijgever beoordeelt.
- Een **laadscherm** met voortgang tijdens het laden van de Assistent.

Zie INRICHTING.md, stap 9, "Classificatie en vergrendelen".

- Bijwerken in de volgorde VPS 3, VPS 2, VPS 1. Migratie 009 van het platform en migratie 004 van het portaal draaien vanzelf.
- Op VPS 3 opnieuw `sudo /opt/oa-uitrol/server/keycloak-beheer.sh` draaien: dat maakt de rol **vrijgever** aan. Ken hem toe aan wie mag vrijgeven.
- Geef een groep in het portaal `classificatie.manage` (en wie mag afwijken `bewaartermijn.afwijken`), en publiceer een classificatiemodel. Zonder model wordt niets vergrendeld.

## 0.19.0 — 2026-11-10

**Naam en versie van het metadatamodel** (oa-beheer 0.4.0, opendop-mini 0.10.0, oa-contract 0.7.0, oa-kern 0.7.0, oa-paneel 0.11.0, oa-adapters 0.18.0 met LibreOffice-extensie 0.15.0, oa-services 0.5.3, oa-integratielaag 0.9.8). De beheerder geeft het model een naam; een andere naam is een nieuwe versie. Het paneel toont naam en versie bovenaan Metadateren, en bij een stuk met een ouder model welke versie nu geldt. Het overzicht toont identificatie, versie, status en metadatamodel. In het bestand staan de documenteigenschappen Identificatie, Versie, Metadatamodel en Status, en de afdruk noemt de modelversie. Zie INRICHTING.md, stap 9, "Metadatamodel".

- Bijwerken in de volgorde VPS 3, VPS 2, VPS 1. Geen nieuwe migraties.
- Wie de LibreOffice-extensie zelf installeert: versie 0.15.0.

## 0.18.0 — 2026-11-09

**Kwaliteit van het anonimiseren in het beheerportaal** (oa-beheer 0.3.0, opendop-mini 0.9.0, oa-contract 0.6.0, oa-kern 0.6.0, oa-paneel 0.10.0, oa-adapters 0.17.0, oa-services 0.5.2, oa-integratielaag 0.9.7): een pagina Anonimiseren met de tab Kwaliteit. *Laat staan* in het paneel vraagt nu waarom. Bij bevestigen bewaart het platform een meting zonder waarden en zonder koppeling met het stuk: wat bevestigd, gelaten of toegevoegd werd, met vorm (`9-9`), lengte en signaalwoord. Het portaal toont precisie, gevonden (bovengrens voor de recall), zekerheid tegen terecht/onterecht, en de vormen die vaak gemist of onterecht gevonden worden, met een regexp om te kopiëren. Zie INRICHTING.md, stap 9, "Anonimiseren → Kwaliteit".

- Bijwerken in de volgorde VPS 3, VPS 2, VPS 1. Migratie 008 van het platform en migratie 003 van het portaal draaien vanzelf.
- Geef een groep het recht `anonimiseren.view`.

## 0.17.0 — 2026-11-09

**Metadatamodel in het beheerportaal** (oa-beheer 0.2.0, oa-contract 0.5.0, opendop-mini 0.8.0, oa-services 0.5.1, oa-integratielaag 0.9.6, oa-kern 0.5.1, oa-paneel 0.9.0, oa-adapters 0.16.1): informatiebeheer kiest een basismodel (MDTO, RGBZ of TMLO), zet velden aan of uit, maakt ze verplicht, past labels, hulpteksten en waardelijsten (ook uit TOOI) aan en voegt eigen velden toe. Publiceren maakt een nieuwe versie van het objecttype voor die gemeente; het paneel Metadateren volgt die meteen, en stukken die al zijn vastgelegd houden hun versie. Zie INRICHTING.md, stap 9, "Metadatamodel".

- VPS 1: het portaal praat met het platform (`PLATFORM_INTERN`, `PLATFORM_DIENSTSLEUTEL`, die er al staan) voor één gemeente: `BEHEER_GEMEENTE` (standaard haarlem).
- Geef een groep het recht `metadata.manage` (migratie 002 van het portaal draait vanzelf).

Lockfile bijgewerkt. Bijwerken: **VPS 3, VPS 2, dan VPS 1**. LibreOffice-extensie 0.14.1 opnieuw installeren.

## 0.16.3 — 2026-11-09

Lockfile voor oa-adapters 0.15.3: in LibreOffice is het paneel weer helemaal naar beneden te scrollen als er onderin een werkbalk staat (zoals de zoekbalk). Bijwerken: VPS 1 is genoeg; LibreOffice-extensie 0.13.3 opnieuw installeren. Wie 0.16.0 tot en met 0.16.2 nog niet had bijgewerkt: VPS 3, VPS 2, VPS 1.

## 0.16.2 — 2026-11-09

Alleen documentatie, bijwerken hoeft niet. README: "Begin hier" per rol (uitproberen, inrichten, ontwikkelen) en oa-wcag en OpenAnonymiser in het overzicht. INRICHTING.md bijgewerkt: wat er op VPS 3 draait en hoeveel geheugen dat vraagt, PPL 0 na het inloggen, het Word-manifest zonder vast versienummer, het webpaneel van LibreOffice ook op Windows en Mac (proef), niveaus toekennen via de tunnel (er is geen `auth.<domein>`), en oa-wcag bij dagelijks beheer.

## 0.16.1 — 2026-11-09

**Grondslag bij anonimiseren begrijpelijk en aan te passen** (oa-contract 0.4.2, opendop-mini 0.7.2, oa-integratielaag 0.9.5, oa-kern 0.4.3, oa-paneel 0.8.4, oa-adapters 0.15.2): bij elk persoonsgegeven staat de grondslag in gewone taal ("AVG art. 9 · bijzondere persoonsgegevens") met uitleg. Zolang het een voorvertoning is, kies je een andere; het gegeven gaat dan over naar de sleutel van die categorie en de plaatshouder krijgt de kleur van het nieuwe niveau. Elke wijziging is een gebeurtenis (`pii.categorie-gewijzigd`). Geen databasemigratie.

Lockfile bijgewerkt. Samen met 0.16.0 bijwerken: **VPS 3, VPS 2, VPS 1** (in die volgorde). LibreOffice: extensie 0.13.2 opnieuw installeren.

## 0.16.0 — 2026-11-09

**Toegankelijkheid van het bestand zelf:** [oa-wcag](https://github.com/Digitaal-Gemeengoed/oa-wcag) 0.1.0 op VPS 3, naast de assistent-services en alleen voor hen bereikbaar (geen poort naar buiten). 34 controles voor docx, xlsx en pptx; de assistent dekt daarmee 20 WCAG-criteria in plaats van 5 (titel, taal, contrast, tekstafstand, leesvolgorde, alt-tekst van grafieken, tabellen …).

- `vps3-diensten.yml`: dienst `wcag` (Java, ongeveer 150 MB, grens 512 MB, alleen-lezen bestandssysteem). `haal-op.sh` haalt oa-wcag op.
- `WCAG_DIENSTSLEUTEL` in `.env` op VPS 3 mag leeg blijven: dan dezelfde als `DIENSTEN_DIENSTSLEUTEL`.
- TESTEN.md, stap 10: let op bevindingen *uit het bestand*.

Bijwerken: **VPS 3** (bouwt oa-wcag; de eerste keer duurt dat een paar minuten), daarna VPS 1.

## 0.15.3 — 2026-11-09

Lockfile voor oa-adapters 0.15.1: anonimiseren ook in opmerkingen (LibreOffice-extensie 0.13.1; opnieuw installeren). Bijwerken: VPS 1 is genoeg.

## 0.15.2 — 2026-11-09

Lockfile voor oa-contract 0.4.1, oa-kern 0.4.2, oa-services 0.5.0, oa-paneel 0.8.3 en oa-adapters 0.15.0 (voorbereiding op de toegankelijkheidscontrole van het bestand; die gaat aan zodra oa-wcag op VPS 3 staat). Bijwerken mag; er verandert nog niets zichtbaars, behalve de LibreOffice-extensie 0.13.0 op de downloadpagina.

## 0.15.1 — 2026-11-09

**Inloggen en verlopen sessies netjes afgevangen** (oa-integratielaag 0.9.4, oa-paneel 0.8.2, oa-adapters 0.14.1): geen kale foutmelding meer na te lang wachten op het inlogscherm, een knop *Opnieuw inloggen* als de sessie verloopt, en een melding in plaats van een leeg paneel als de server weg is. Zie TESTEN.md, stap 11 (toen 10).

Lockfile bijgewerkt. Bijwerken: VPS 1 is genoeg. Geen nieuwe extensie of manifest nodig.

## 0.15.0 — 2026-11-09

- **LibreOffice op Windows en Mac:** het webpaneel in de zijbalk als proef (oa-adapters 0.14.0, extensie 0.12.0). Extensie opnieuw installeren.
- **TESTEN.md:** dezelfde testronde voor elke werkomgeving, en wat testers meesturen (met het logboek van de extensie). De downloadpagina verwijst ernaar en is bijgewerkt.

Lockfile voor oa-adapters 0.14.0. Bijwerken: VPS 1 is genoeg.

## 0.14.1 — 2026-11-09

Downloadpagina (office.<domein>): het versienummer bij het manifest en de extensie (ook op de knop), een tabel met de versies op de servers, en de tekst over anonimiseren bijgewerkt. De pagina haalt dat op bij oa.<domein>/versies.json; de Content-Security-Policy staat het script (op hash) en die ene verbinding toe. Lockfile voor oa-integratielaag 0.9.3.

## 0.14.0 — 2026-11-09

**Anonimiseren in het document in alle werkomgevingen**: Word, Excel, PowerPoint, LibreOffice Calc en Impress, en Collabora (zie de CHANGELOG van oa-adapters 0.13.0 voor wat per omgeving kan).

Lockfile voor oa-kern 0.4.1, oa-paneel 0.8.1, oa-adapters 0.13.0 en oa-integratielaag 0.9.2. Bijwerken (VPS 1 is genoeg). Daarna:
- het **Office-manifest (0.6.0.0)** opnieuw uploaden in Word, Excel en PowerPoint;
- de **LibreOffice-extensie (0.11.0)** opnieuw installeren.

## 0.13.0 — 2026-11-09

LibreOffice Writer anonimiseert nu in het document zelf, zoals de demo-werkomgeving: lockfile voor oa-adapters 0.12.0. Bijwerken (VPS 1 is genoeg; de volgorde 3, 2, 1 mag ook) en daarna de **LibreOffice-extensie 0.10.0** opnieuw installeren.

## 0.12.1 — 2026-11-09

Lockfile voor opendop-mini 0.7.1, oa-services 0.4.3 en oa-integratielaag 0.9.1: de overzichtspagina toont welke versies er draaien en welke versie van het Office-manifest en de LibreOffice-extensie hoort bij deze omgeving. Bijwerken in de volgorde VPS 3, 2, 1.

## 0.12.0 — 2026-11-09

**Anonimiseren in het document** (fase A): in de demo-werkomgeving gebeurt het anonimiseren nu in het document zelf, zoals in de MIRA-demo, met kaarten in het paneel, versies die je kunt herkennen en terugzetten, en het versienummer als documenteigenschap. Word en LibreOffice volgen (fase B).

Lockfile voor oa-contract 0.4.0, opendop-mini 0.7.0 (migratie 007, draait vanzelf), oa-services 0.4.2, oa-kern 0.4.0, oa-paneel 0.8.0, oa-adapters 0.11.0 en oa-integratielaag 0.9.0. Bijwerken in de volgorde VPS 3, 2, 1. Extensie en manifest hoeven niet opnieuw.

## 0.11.0 — 2026-11-09

**Anonimiseren bij de bron.** Persoonsgegevens worden na bevestiging versleuteld in een register (in PostgreSQL, bij de metadata), met een sleutel per document per AVG-categorie, en in het document vervangen door plaatshouders.

- Keycloak: rollen `ppl-1`, `ppl-2` en `ppl-3` (wie welk niveau persoonsgegevens mag inzien). `keycloak-beheer.sh` maakt ze aan (op VPS 3), geeft medewerkers zonder niveau `ppl-1`, en vraagt bij een eigen gebruiker om het niveau. Daarna opnieuw inloggen.
- Lockfile voor oa-contract 0.3.3, opendop-mini 0.6.0 (migratie 006, draait vanzelf), oa-services 0.4.1, oa-kern 0.3.4, oa-paneel 0.7.0, oa-adapters 0.10.0 en oa-integratielaag 0.8.0. Bijwerken in de volgorde VPS 3, 2, 1.
- LibreOffice-extensie 0.9.0 opnieuw installeren (vervangen en selectie lezen). Het Office-manifest hoeft niet opnieuw.

## 0.10.0 — 2026-11-09

**Anonimiseren.** VPS 3 krijgt OpenAnonymiser (Conduction, EUPL-1.2): herkenning van persoonsgegevens met Presidio en het Nederlandse taalmodel van spaCy. We bouwen het zelf uit de broncode, op een vaste versie (`haal-op.sh`), zonder poort naar buiten; alleen de assistent-services gebruiken het. Ongeveer 1 GB geheugen.

Lockfile voor oa-contract 0.3.2, opendop-mini 0.5.0 (migratie 005, draait vanzelf), oa-services 0.4.0, oa-kern 0.3.3, oa-paneel 0.6.0, oa-adapters 0.9.1 en oa-integratielaag 0.7.1. Bijwerken in de volgorde VPS 3, 2, 1. Het Office-manifest (0.5.1.0) en de LibreOffice-extensie (0.8.1) hoeven niet opnieuw, maar het mag.

## 0.9.0 — 2026-11-09

Lockfile voor oa-contract 0.3.1, opendop-mini 0.4.0, oa-kern 0.3.2, oa-paneel 0.5.0, oa-adapters 0.9.0 en oa-integratielaag 0.7.0:

- Het paneel heeft de modules van de demo, met knoppen in de werkbalk van elke werkomgeving (LibreOffice: werkbalk Assistent; Office: tabblad Assistent; Collabora: in de eigen werkbalk).
- Zakelijk of persoonlijk. Het platform maakt per gemeente een tweede bucket (`…-persoonlijk`, zonder Object Lock); de migratie (004) draait vanzelf bij het bijwerken van VPS 2.
- Bijwerken in de volgorde VPS 3, VPS 2, VPS 1. Daarna: het Office-manifest opnieuw uploaden en de LibreOffice-extensie (0.8.0) opnieuw installeren.

Overzichtspagina en INRICHTING bijgewerkt.

## 0.8.0 — 2026-11-08

Lockfile voor oa-adapters 0.8.0 en oa-integratielaag 0.6.0: de invoegtoepassing werkt ook in Excel en PowerPoint (één manifest; gebouwd, nog niet getest in een echte Excel of PowerPoint). De overzichtspagina op office.<domein> en INRICHTING zeggen wat werkt: Collabora en LibreOffice nu ook met rekenblad en presentatie. Wie het manifest al had geüpload, uploadt het nieuwe opnieuw.

## 0.7.0 — 2026-11-08

Ook: integratielaag 0.5.0 (Collabora met rekenblad en presentatie; nieuwe afhankelijkheid `@xmldom/xmldom`).


Lockfile voor oa-services 0.3.0, oa-kern 0.3.1, oa-paneel 0.4.1 en oa-adapters 0.7.0: rekenbladen en presentaties, en het zijpaneel in LibreOffice Calc en Impress. Bijwerken in de volgorde VPS 3 (services), VPS 2, VPS 1.

## 0.6.0 — 2026-11-08

- LibreOffice: het webpaneel van de server in de zijbalk (oa-adapters 0.6.0). `INRICHTING.md` stap 8 en de voorpagina van `office.<domein>` beschrijven installeren (op Linux `python3-gi` en `gir1.2-webkit2-4.1`) en kiezen tussen webpaneel en eigen paneel.
- Lockfile voor oa-adapters 0.6.0.

## 0.5.2 — 2026-11-08

- Voorpagina op `office.<domein>`: overzicht van de werkomgevingen, met de downloads (Word-manifest, LibreOffice-extensie) en wat waar werkt. Collabora blijft op dezelfde naam; alleen `/` is de voorpagina.
- Caddy krijgt de hele map `caddy/` in plaats van alleen de Caddyfile, en `bijwerken.sh` herlaadt Caddy. Eerder bleef een gewijzigde Caddyfile (zoals het blok voor `oa-admin`) ongebruikt tot een herstart.

## 0.5.1 — 2026-11-08

- `bijwerken.sh` start zichzelf opnieuw na het ophalen, zodat nieuwe instellingen in `.env` er meteen bij komen. Voorheen draaide de oude `lib.sh` nog en ontbraken de geheimen van het beheerportaal.
- De LibreOffice-extensie heeft een eigen zijpaneel in Writer (oa-adapters 0.5.0); `INRICHTING.md` stap 8 beschrijft installeren en aanmelden.
- Lockfile bijgewerkt voor oa-adapters 0.5.0.

## 0.5.0 — 2026-11-08

- Het beheerportaal (`oa-beheer`) op VPS 1: `oa-admin.<domein>` in Caddy, services `beheer-db` (niet gepubliceerd), `beheer-migreer` en `beheer` (alleen-lezen, zonder rechten). `haal-op.sh` haalt `oa-beheer` op.
- `installeer.sh` en `bijwerken.sh` vullen `.env` aan met nieuwe geheimen voor het portaal; DNS-controle voor `oa-admin.<domein>`.
- `server/beheer.sh` (VPS 1): noodaccount, Keycloak-client-geheim, SMTP, status en logboek.
- `server/keycloak-beheer.sh` (VPS 3): client `oa-beheer`, AMR-mapper, referentie `otp` op de OTP-stap, brute-force-detectie, en op verzoek een eigen Keycloak-gebruiker.
- `INRICHTING.md` stap 9: het beheerportaal.

## 0.4.2 — 2026-11-08

- `haal-op.sh` probeert tot drie keer bij een netwerkhapering; `bijwerken.sh` en `installeer.sh` stoppen als ophalen mislukt.
- Lokaal gebouwde images (`oa/platform`) worden niet meer van een registry gehaald (`pull_policy: never`).

## 0.4.1 — 2026-11-08

Lockfile bijgewerkt voor contract 0.3.0 en de nieuwe versies. Bijwerken in de volgorde VPS 2 (migratie 003), VPS 3, VPS 1.

## 0.4.0 — 2026-11-08

- Collabora Online op VPS 1 (profiel `collabora`, adres `office.<domein>`), met volume voor werkbestanden.
- `installeer.sh` en `bijwerken.sh` vullen een bestaande `.env` aan met nieuwe instellingen; DNS-controle voor `office.<domein>`.
- `INRICHTING.md`: de assistent in Word, Collabora en LibreOffice.
- Caddy zet geen `X-Frame-Options` meer; de integratielaag regelt het inbedden zelf.

## 0.3.0 — 2026-11-07

- `server/`: scripts om drie VPS'en in te richten en te beveiligen (`inrichten.sh`, `ssh-afsluiten.sh`, `koppelen.sh`, `installeer.sh`, `controleer.sh`, `ontzegel.sh`, `bijwerken.sh`) en het stappenplan `INRICHTING.md`.
- Verkeer tussen de VPS'en via WireGuard (10.66.0.0/24); een filter op `DOCKER-USER` laat per containerpoort alleen de VPS toe die hem nodig heeft.
- OpenBao: `server` zonder extra `-config` (de map werd anders dubbel geladen), opslag in `/openbao/file`, mlock uit bij raft.
- Keycloak: het beheerscherm via een SSH-tunnel (`KC_HOSTNAME_ADMIN`); testgebruikers krijgen een willekeurig tijdelijk wachtwoord (`OA_TESTWACHTWOORD`); testbeheerder `beheer.haarlem`.
- `openbao/init.sh`: met `OA_ROOT_INTREKKEN=1` wordt het root-token meteen ingetrokken.

## 0.2.0 — 2026-11-07

OpenSearch (profiel `zoeken`, VPS 2) en OpenBao (profiel `sleutels`, VPS 3) als optionele onderdelen, met `openbao/init.sh` en een beleid voor het platform. De worker krijgt dezelfde instellingen als het platform.

## 0.1.1 — 2026-11-07

S3-opslag in de uitrol is SILO, de open-source voortzetting van MinIO (OA-ADR-006).

## 0.1.0 — 2026-11-07

Fase 1 van het werkende prototype: contract, minimaal platform, integratielaag met twee ingangen, assistentkern, paneel en een demo-werkomgeving met de modules metadateren en toegankelijkheid.
