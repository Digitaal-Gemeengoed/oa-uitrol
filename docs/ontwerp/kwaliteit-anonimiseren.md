# Ontwerp: kwaliteit van het anonimiseren (beheerportaal → Anonimiseren → Kwaliteit)

Status: gebouwd in uitrol 0.18.0 (oa-beheer 0.3.0, opendop-mini 0.9.0, oa-contract 0.6.0, oa-kern 0.6.0, oa-paneel 0.10.0).

## Bron: wat medewerkers doen
Bij elke bevestiging van het anonimiseren in het document stuurt het paneel een meting mee. Per gegeven:
- soort, bron (patroon / model / medewerker), zekerheid;
- uitkomst: bevestigd, gelaten (*Laat staan*), zelf toegevoegd;
- reden bij Laat staan: geen persoonsgegeven, mag openbaar, verkeerde soort, of zonder reden;
- of de soort standaard wordt geanonimiseerd, en of de grondslag (AVG-artikel) gewijzigd is;
- vorm (cijfers → 9, hoofdletters → A, kleine letters → a; "06-51209934" → `9-9`), lengte (kort/middel/lang), signaalwoord uit een vaste lijst, aantal plekken.

Nooit de waarde, geen koppeling met het stuk, alleen de dag. Het platformschema weigert vormen met andere tekens en signaalwoorden buiten de lijst.

## Indeling
- juist: bevestigd (standaardsoort), of gelaten als "mag openbaar" / "verkeerde soort";
- onterecht: gelaten als "geen persoonsgegeven" of zonder reden;
- gemist: zelf toegevoegd;
- keuze: bevestigd terwijl de soort standaard uit staat (telt niet als vondst).

Precisie = juist / (juist + onterecht). Gevonden = juist / (juist + gemist): een **bovengrens** voor de recall; wat assistent én medewerker missen ziet niemand. Echte recall vraagt een steekproef met een tweede beoordelaar.

## Wat het portaal toont
Periode 30/90/365 dagen; kerncijfers; per soort; zekerheid tegen terecht/onterecht per band (voor drempelkeuze); vormen gemist / te veel met regexp (`9-9` → `\d+-\d+`) als begin voor een patroon, signaalwoorden en lengte; gewijzigde grondslag; per versie van de herkenner. Vormen pas zichtbaar bij ≥ 5 bevestigingen (een zeldzame vorm kan naar één persoon wijzen). Recht: `anonimiseren.view`.

## Beperkingen
- Bij namen zegt de vorm weinig (`Aa Aa`); signaalwoorden ("heer", "burgemeester") helpen meer.
- De regexp is een begin, geen kant-en-klaar patroon: `\d+-\d+` vangt ook datums en bedragen.
- Later bruikbaar als evaluatieset voor een LLM-herkenner: vergelijken per motorversie.
