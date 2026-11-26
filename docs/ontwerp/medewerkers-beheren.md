# Office Assistent — medewerkers beheren in het portaal (ontwerp)

*Prototype Digitaal GemeenGoed · 26 november 2026 · besluiten van Erik Hoekstra*

## Uitgangspunten (besloten)

1. Er is één inlogaccount per persoon, in Keycloak (realm `gemeenten`). Daarmee logt hij in bij de Office Assistent en, als hij beheerrechten heeft, bij het beheerportaal.
2. Een account op de pagina *Accounts* is een machtiging voor het portaal, geen inlogaccount. Bij de eerste keer inloggen koppelt het portaal het aan de Keycloak-gebruiker met hetzelfde bevestigde e-mailadres.
3. Zolang er geen koppeling is met EntraID of een ander IAM-pakket, beheert de gemeente haar medewerkers in het portaal (pagina *Medewerkers*), niet in de Keycloak-console.
4. Toegang tot originele waarden volgt het niveau (PPL) van de medewerker, ook voor wie een stuk zelf heeft geanonimiseerd (zie `anonimiseren-in-het-document.md`).

## Wat het portaal doet

| Handeling | Uitwerking |
|---|---|
| Toevoegen | Gebruikersnaam is het e-mailadres; attribuut `gemeente`; rollen `medewerker` en `ppl-n`; lid van de organisatie als het e-maildomein daarbij hoort. Keycloak mailt een link (72 uur) om een wachtwoord te kiezen en de authenticator te koppelen. |
| Niveau wijzigen | Andere `ppl`-rol; daarna uitloggen. |
| Uitschakelen, inschakelen | Nu of op een datum (tabel `medewerkerwijzigingen`, elke 30 seconden uitgevoerd, annuleerbaar). Uitschakelen logt uit. |
| Herstelmail | Wachtwoord en/of authenticator; een nieuwe authenticator komt naast de oude. |
| Grenzen | Alleen medewerkers van de gemeente die je beheert; niet je eigen account; altijd een reden; alles in de audit. Wachtwoorden en e-mailadressen zet het portaal nooit. |

## Uitloggen tot in de Office Assistent

Keycloak stuurt bij uitloggen een uitlogbericht (OpenID Connect Back-Channel Logout) naar `/api/auth/uitlogbericht` van de integratielaag. Die controleert het `logout_token` (handtekening, uitgever, ontvanger, gebeurtenis, geen nonce, hooguit tien minuten oud) en beëindigt alle sessies van die persoon. Zo geldt een lager niveau of uitschakelen direct, niet pas als de sessie na maximaal 8 uur verloopt. `bijwerken.sh` op VPS 3 zet het adres op de client `oa-integratielaag`, afgeleid van zijn redirect-URI.

## Rechten van het portaal in Keycloak

Het service-account van de client `oa-beheer` heeft `manage-organizations` en `view-users`, plus fijnmazige beheerrechten (Keycloak 26.2 en nieuwer):

- **Users, `manage`:** gebruikers aanmaken, wijzigen, in- en uitschakelen, mails laten sturen, sessies beëindigen.
- **Users, `map-roles`** met **Roles, `map-role`**, alleen voor de rollen `medewerker`, `ppl-1`, `ppl-2` en `ppl-3`.

Getest tegen Keycloak 26.8.2: de rollen `beheerder` en `realm-admin` toekennen en de realm wijzigen worden geweigerd.

**Kanttekening.** `manage` omvat in Keycloak ook een wachtwoord zetten en een gebruiker verwijderen. Het portaal roept die niet aan, maar het recht staat het toe. Wie het portaal (of zijn client-geheim) in handen krijgt, kan dus accounts aanmaken, uitschakelen, wachtwoorden zetten of verwijderen in de realm `gemeenten`, maar zichzelf of een ander geen beheerrol geven. Daar staat tegenover dat beheerders zonder het portaal de Keycloak-console met volledige rechten gebruiken, zonder reden en audit per handeling.

## Later

- Met EntraID of een ander IAM-pakket komen medewerkers daarvandaan: het toevoegen en uitschakelen in het portaal gaat dan per gemeente uit; het niveau blijft hier.
- Sessies van de integratielaag staan in het geheugen van één proces; bij meer instanties of herstarts hoort hier een gedeelde opslag (zie `lib/sessie.ts`).
