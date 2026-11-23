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

1. **VPS 3 (diensten).** Voeg de gemeente toe aan `GEMEENTEN` in `/opt/oa-uitrol/.env`, met haar e-maildomeinen:

   ```
   GEMEENTEN="haarlem:Gemeente Haarlem:haarlem.nl,zandvoort:Gemeente Zandvoort:zandvoort.nl+zandvoort.org"
   ```

   Draai daarna `sudo /opt/oa-uitrol/server/gemeenten.sh`. `bijwerken.sh` doet hetzelfde bij elke bijwerkronde. Het script:
   - zet Keycloak Organizations aan;
   - maakt per gemeente een organisatie (alias = de code, attribuut `naam`) met haar domeinen;
   - koppelt elke gebruiker met een e-mailadres op zo'n domein aan die gemeente, en zet zijn thuisgemeente als die nog leeg is;
   - geeft de clients `oa-integratielaag` en `oa-beheer` de scope `organization`.

2. **VPS 2 (platform).** Niets te doen. De gemeente meldt zich aan bij het platform zodra de eerste medewerker van die gemeente inlogt. Het platform zet haar dan in het register; bucket, zoekindex en sleutels ontstaan bij het eerste gebruik. `GEMEENTEN` op VPS 2 mag blijven staan, maar is niet meer nodig.

3. **VPS 1 (toegang), alleen bij een GR.** Zet in `.env` de regel `BEHEER_GEMEENTEN` met dezelfde waarde als `GEMEENTEN` op VPS 3 en draai `bijwerken.sh`. Het beheerportaal kent dan alle gemeenten. Bij één gemeente volstaat `BEHEER_GEMEENTE`.

4. **Beheerportaal.** Geef de beheerders van de nieuwe gemeente een account met alleen die gemeente. Een GR-beheerder krijgt "Alle gemeenten".

5. **Identiteitsvoorziening van de gemeente (later).** Koppel de Entra ID (of vergelijkbare voorziening) van de gemeente in Keycloak aan haar organisatie. Keycloak stuurt een medewerker dan op zijn e-maildomein door naar de eigen inlog van zijn gemeente, en maakt hem vanzelf lid.

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

Een nieuw account krijgt standaard de gemeente die de beheerder op dat moment beheert. Meer gemeenten toekennen kan alleen binnen het eigen bereik; "Alle gemeenten" alleen door een GR-brede beheerder. Groepen, rechten en instellingen van het portaal zijn voor de hele inrichting.

## Open punten

- **Scheiding binnen een GR.** Volstaan Row Level Security, een bucket en een index per gemeente? Of zijn een eigen realm, transit-engine en opslag per gemeente nodig? Af te wegen met de CISO's van de deelnemende gemeenten (OA-ADR-009).
- **Huisstijl per gemeente.** Het paneel kent nu alleen het thema van Haarlem; een andere gemeente krijgt na het inloggen de huisstijl van de inrichting. Een attribuut `huisstijl` per organisatie in Keycloak ligt voor de hand.
- **Audit in het portaal.** Wie het recht *audit bekijken* heeft, ziet de audit van de hele inrichting. Filteren op gemeente voor beheerders van één gemeente is nog te doen.
- **Eén bron voor de gemeenten.** `GEMEENTEN` staat op VPS 3 en, bij een GR, als `BEHEER_GEMEENTEN` op VPS 1. Eén instellingenbestand per inrichting (OA-ADR-010) haalt die dubbeling weg.
