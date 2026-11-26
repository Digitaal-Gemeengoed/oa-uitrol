# Inloggen: de tweede factor herstellen

*Prototype Digitaal GemeenGoed · 25 november 2026 · besluiten van Erik Hoekstra*

Iedereen logt in met wachtwoord én een code uit een authenticator-app (TOTP). Het beheerportaal eist die tweede factor (`amr`). Dit document beschrijft wat een gebruiker kan doen als het koppelen van de app misgaat of als hij de app kwijt is, en wat de beheerder doet als niets anders werkt.

## Uitgangspunt

De QR-code komt nooit terug op alleen het wachtwoord. Wie alleen het wachtwoord heeft (uitgelekt, afgekeken), zou dan een eigen app kunnen koppelen, en dan is de tweede factor niets meer waard. Elke route hieronder vraagt daarom naast het wachtwoord nog iets wat alleen de gebruiker heeft: een herstelcode, of toegang tot zijn e-mail.

## Drie situaties, drie routes

| Situatie | Route | Wat de gebruiker heeft |
|---|---|---|
| De QR-code de eerste keer niet afgemaakt | Gewoon opnieuw inloggen: na het wachtwoord komt de QR-code vanzelf terug (verplichte stap, tot hij af is) | wachtwoord |
| App kwijt, herstelcodes bewaard | Na het wachtwoord: **Op een andere manier inloggen → Herstelcode**. Daarna in het account (Accountbeveiliging → Inloggen) een nieuwe app koppelen en de oude verwijderen | wachtwoord + herstelcode |
| App én codes kwijt (of wachtwoord vergeten) | Op de inlogpagina: **Wachtwoord of authenticator kwijt?** Een link per e-mail; die toont de QR-code opnieuw en vraagt een nieuw wachtwoord | toegang tot het e-mailadres |
| Ook dat lukt niet | De beheerder: `sudo /opt/oa-uitrol/server/inlog.sh authenticator <e-mailadres>` | identiteit vastgesteld door de beheerder |

## Herstelcodes

- Na het koppelen van de app maakt iedereen twaalf herstelcodes aan (Keycloak: `add-recovery-codes` op de verplichte actie *Configure OTP*). De pagina laat ze één keer zien, met Afdrukken, Downloaden en Kopiëren.
- Bestaande gebruikers met een app maar zonder codes krijgen de stap bij hun volgende inlog (`bijwerken.sh` zet hem klaar).
- Elke code werkt één keer. Bij minder dan vier codes waarschuwt het account om nieuwe te maken.
- In de inlogflow staat *Recovery Authentication Code Form* als alternatief naast de app. Na een herstelcode staat in het token `amr: ["mfa"]` (na de app: `["otp"]`). Het portaal accepteert beide als tweede factor: een bewaarde herstelcode is iets wat alleen de gebruiker heeft.

## Herstel via e-mail

- Alleen als Keycloak e-mail heeft: `sudo /opt/oa-uitrol/server/inlog.sh smtp` (VPS 3). Hetzelfde SMTP-account als het portaal kan. Zonder e-mail staat de link uit.
- Alleen vanaf Keycloak 26.7.2: oudere versies hadden een ernstig lek in juist deze route (CVE-2026-18963). `keycloak_herstel` zet de route anders niet aan.
- De link opent eerst de QR-code, daarna het nieuwe wachtwoord. De e-mail (eigen tekst, e-mailthema `oa`) legt dat uit.
- **De oude koppeling blijft staan** ("Reset OTP": *Remove none*). Keycloak zet de stap "QR-code" alleen in de sessie, niet bij de gebruiker. Met *Remove all* zou wie na het klikken op de link afhaakt, zonder authenticator blijven en de QR-code niet meer krijgen (getest). Met *Remove none* kan hij het gewoon opnieuw proberen.
- Heeft iemand daarna twee apps, dan staat bij het inloggen de laatst gekoppelde voorgeselecteerd, met een aanwijzing om de oude in het account te verwijderen (eigen `login-otp.ftl` in het thema).

## Wat er verder is aangescherpt

- **Bescherming tegen raden** staat aan: na tien mislukte pogingen (wachtwoord, code of herstelcode) steeds langer wachten, tot vijftien minuten. Geen permanente blokkade.
- **E-mailadres en gebruikersnaam** zijn alleen door een beheerder te wijzigen. De herstellink gaat naar dat adres, en het e-maildomein bepaalt bij welke gemeente iemand hoort (multi-tenant). Voorheen kon een gebruiker zijn adres in het account zelf wijzigen.

## Vanuit het beheerportaal

Op de pagina **Medewerkers** laat een beheerder (recht `medewerkers.manage`) Keycloak een mail sturen om het wachtwoord en/of de authenticator opnieuw in te stellen (*execute actions*, eigen tekst in het e-mailthema `oa`, link drie dagen geldig). Een nieuwe authenticator komt naast de oude; dat is dezelfde keuze als bij *Remove none* hierboven. Een nieuwe medewerker krijgt dezelfde mail, met beide stappen. De mail gaat altijd naar het adres dat al in Keycloak staat; een beheerder kan dat adres in het portaal niet wijzigen. Kan iemand niet meer bij die mailbox, dan is de beheeropdracht hieronder nodig, met dezelfde controle van wie het vraagt.

## De beheeropdracht

`sudo /opt/oa-uitrol/server/inlog.sh authenticator <e-mailadres>` (VPS 3) haalt de app(s) en herstelcodes van die gebruiker weg, meldt hem overal af en zet de verplichte stap *Configure OTP*. Bij de volgende inlog ziet hij na het wachtwoord de QR-code, daarna nieuwe herstelcodes. Doe dit alleen als vaststaat dat de vraag van de gebruiker zelf komt (bijvoorbeeld via een bekend telefoonnummer of persoonlijk): wie dit laat doen, heeft daarna alleen het wachtwoord nodig.

## Getest

Tegen Keycloak 26.8.2 met het thema `oa`, in een browser (Playwright), met een SMTP-vanger:

1. Eerste inlog: wachtwoord → QR-code → herstelcodes; in Keycloak staan `otp` en `recovery-authn-codes`.
2. Inloggen met een herstelcode: lukt, `amr` is `mfa`; met de app: `otp`.
3. Herstel via e-mail: mail met eigen tekst → link → QR-code → nieuw wachtwoord → inloggen met de nieuwe app (voorgeselecteerd), `amr` is `otp`.
4. Afhaken na de link: de oude koppeling blijft, de QR-code komt bij een nieuwe poging terug.
5. De beheeropdracht: koppelingen weg, *Configure OTP* staat bij de gebruiker, na het wachtwoord de QR-code.

## Open punten

- **Oude app automatisch weg** na een geslaagde nieuwe koppeling via de e-mail: kan niet met de ingebouwde flows; nu verwijdert de gebruiker de oude zelf.
- **Iedereen zonder authenticator verplicht koppelen** (ook buiten de verplichte stap om): vraagt een eigen kopie van de inlogflow. Nu niet nodig: alle accounts krijgen *Configure OTP* bij het aanmaken, en *Remove none* laat niemand zonder.
- **Melding bij herstel**: een e-mail aan de gebruiker na inloggen met een herstelcode of na een herstellink ("was jij dit?").
