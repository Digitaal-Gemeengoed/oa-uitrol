# Office Assistent — meer gemeenten in één inrichting

*Prototype Digitaal GemeenGoed · 23 november 2026 · besluiten van Erik Hoekstra*

Elke gemeente krijgt in beginsel een eigen inrichting. Gemeenten die samenwerken, bijvoorbeeld in een gemeenschappelijke regeling (GR) voor IT-diensten, kunnen er één delen. Alle inrichtingen draaien dezelfde software (OA-ADR-009). Dit document beschrijft hoe een gedeelde inrichting werkt en hoe een gemeente wordt aangesloten.

## Uitgangspunten (besloten)

1. **Scheiding in de database, niet alleen in de code.** Eén register in PostgreSQL met Row Level Security per gemeente, en per gemeente een eigen bucket, zoekindex en sleutels. Geen aparte database per gemeente.
2. **De gemeente volgt uit het e-mailadres.** Elke gemeente is een organisatie in Keycloak (Keycloak Organizations) met haar e-maildomeinen. Een medewerker met een adres op zo'n domein hoort bij die gemeente.
3. **Eén thuisgemeente per medewerker.** Wie lid is van meer gemeenten (bijvoorbeeld een medewerker van de GR), werkt in het paneel voor de thuisgemeente: het attribuut `gemeente` in Keycloak.
4. **Beheer per gemeente én GR-breed.** In het beheerportaal beheert een account één, meer of alle gemeenten van de inrichting. Wie meer gemeenten beheert, kiest de gemeente waarvoor hij werkt; elke actie komt met die gemeente in de audit.
5. **Eigen modellen per gemeente.** Metadatamodel en classificatiemodel zijn per gemeente, met eigen versies. Het gedeelde objecttype `document` is het vertrekpunt.

## Wat per gemeente gescheiden is

| Onderdeel | Per gemeente | Gedeeld binnen de inrichting |
|---|---|---|
| Identiteit (Keycloak) | Organisatie met domeinen; lidmaatschap; thuisgemeente | Eén realm `gemeenten`, het Keycloak-beheer |
| Register (PostgreSQL) | Rijen met de gemeente, afgedwongen met Row Level Security | Eén database |
| Metadatamodel, classificatiemodel | Eigen versies per gemeente | Het objecttype `document` als vertrekpunt |
| Opslag (SILO, S3) | Eén bucket per gemeente (en één voor persoonlijke stukken) | Eén installatie |
| Zoekindex (OpenSearch) | Eén index per gemeente | Eén cluster |
| Sleutels (OpenBao) | Eén sleutel per object, met de gemeente in de naam | Eén transit-engine |
| Beheerportaal | Concepten, keuze en audit per gemeente | Accounts, groepen en instellingen van het portaal |
| Paneel | Thema van de gemeente na het inloggen | Huisstijl van de inrichting vóór het inloggen |

De gemeente staat ook in de metadata van elk stuk. Het platform geeft bij elk informatieobject de naam van de gemeente mee, en de assistent zet die als documenteigenschap *Organisatie* in het bestand: de uitgever bij openbaarmaking.

## Een gemeente aansluiten

Keycloak is de bron voor de gemeenten en hun e-maildomeinen: elke gemeente is een organisatie (alias = de code, attribuut `naam`, met haar domeinen).

1. **Beheerportaal, pagina Gemeenten.** Een GR-brede beheerder (bereik "Alle gemeenten") met het recht *Gemeenten beheren* (`gemeenten.manage`) vult naam, code, e-maildomeinen en een reden in. Het portaal:
   - weigert algemene domeinen (gmail.com, outlook.com, ziggo.nl, kpnmail.nl …) en hun subdomeinen, en domeinen die al bij een andere gemeente horen (in het portaal of in Keycloak);
   - maakt de organisatie in Keycloak, via het interne adres (`KEYCLOAK_INTERN`; het beheerscherm staat niet open naar buiten);
   - meldt de gemeente aan bij het platform (`PUT /gemeente`), zodat zij meteen in het register staat;
   - legt de wijziging vast in de audit (`gemeente.aangemaakt`, `gemeente.gewijzigd`, met oude en nieuwe waarden).

   Naam en domeinen zijn later te wijzigen; de code niet. Er is (nog) geen vier-ogenprincipe. Het overzicht toont per gemeente of Keycloak overeenstemt, en per domein het aantal gebruikers. Een organisatie die alleen in Keycloak bestaat, neemt het portaal bij het openen van de pagina over.

2. **VPS 3 (diensten), automatisch.** De timer `oa-gemeenten.timer` draait elk kwartier `gemeenten.sh --koppelen`: elke gebruiker met een e-mailadres op het domein van een gemeente wordt lid van haar organisatie, en zijn attribuut `gemeente` krijgt die waarde als het nog leeg is. Medewerkers horen dus binnen een kwartier bij de nieuwe gemeente. Het portaal koppelt zelf geen gebruikers: het service-account van `oa-beheer` heeft alleen `manage-organizations` en `view-users` (plus de client scope `kc-admin-api`, die Keycloak 26.8 voor de beheer-API vraagt).

3. **VPS 2 (platform).** Niets te doen. Bucket, zoekindex en sleutels ontstaan bij het eerste gebruik.

4. **Beheerportaal, modellen en accounts.** Kies de nieuwe gemeente bovenaan en stel haar metadatamodel, classificatie en anonimiseren in; tot dan geldt het standaardmodel. Geef haar beheerders een account met alleen die gemeente.

5. **Identiteitsvoorziening van de gemeente (later).** Koppel de Entra ID (of vergelijkbare voorziening) van de gemeente in Keycloak aan haar organisatie. Keycloak stuurt een medewerker dan op zijn e-maildomein door naar de eigen inlog van zijn gemeente, en maakt hem vanzelf lid.

**Eerste inrichting.** `GEMEENTEN` op VPS 3 (bijvoorbeeld `haarlem:Gemeente Haarlem:haarlem.nl,zandvoort:Gemeente Zandvoort:zandvoort.nl+zandvoort.org`) en `BEHEER_GEMEENTEN`/`BEHEER_GEMEENTE` op VPS 1 zijn alleen nog een beginstand: `gemeenten.sh` maakt ontbrekende gemeenten aan en laat bestaande ongemoeid; het portaal neemt ze over als ze er nog niet staan. Daarna is de pagina Gemeenten de plek om te beheren.

## Inloggen en de thuisgemeente

De integratielaag vraagt bij het inloggen de scope `organization:*`. Het token bevat dan alle gemeenten waar de medewerker bij hoort, met hun naam. De thuisgemeente is:

- de enige gemeente, als de medewerker bij precies één hoort;
- anders de gemeente uit het attribuut `gemeente`, als hij daar lid van is;
- zonder organisaties (een inrichting van vóór deze versie): het attribuut `gemeente`.

Lukt dat niet, dan ziet de medewerker een pagina met uitleg: zijn account hoort nog bij geen gemeente, en de beheerder moet zijn gemeente en e-maildomein aansluiten.

## Beheerportaal

| Account | Ziet en beheert | Kiest gemeente |
|---|---|---|
| Eén gemeente | Alleen accounts van die gemeente; metadatamodel, classificatie en anonimiseren van die gemeente | Nee |
| Meer gemeenten | Accounts die alleen bij die gemeenten horen | Ja, in de kop |
| Alle gemeenten (GR-breed) | Alles | Ja, in de kop |

Alleen een GR-brede beheerder met het recht *Gemeenten beheren* ziet de pagina Gemeenten. Een nieuw account krijgt standaard de gemeente die de beheerder op dat moment beheert. Meer gemeenten toekennen kan alleen binnen het eigen bereik; "Alle gemeenten" alleen door een GR-brede beheerder. Groepen, rechten en instellingen van het portaal zijn voor de hele inrichting.

## Open punten

- **Scheiding binnen een GR.** Volstaan Row Level Security, een bucket en een index per gemeente? Of zijn een eigen realm, transit-engine en opslag per gemeente nodig? Af te wegen met de CISO's van de deelnemende gemeenten (OA-ADR-009).
- **Huisstijl per gemeente.** Het paneel kent nu alleen het thema van Haarlem; een andere gemeente krijgt na het inloggen de huisstijl van de inrichting. Een attribuut `huisstijl` per organisatie in Keycloak ligt voor de hand.
- **Audit in het portaal.** Wie het recht *audit bekijken* heeft, ziet de audit van de hele inrichting. Filteren op gemeente voor beheerders van één gemeente is nog te doen.
- **Vier-ogenprincipe.** Toevoegen en wijzigen van een gemeente gaat nu door één beheerder, met reden en audit. Een tweede akkoord is later toe te voegen.
- **Domein weghalen.** Wie al lid is, blijft dat; ontkoppelen gebeurt (nog) met de hand in Keycloak.
