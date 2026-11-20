# Documentatie van de Office Assistent

Alles over het prototype van de Office Assistent van Digitaal GemeenGoed op één plek. Begin bij de vraag die je hebt.

## Ik wil …

| … | Lees |
| --- | --- |
| begrijpen **wat de Office Assistent is** en hoe hij in elkaar zit | [Architectuur](architectuur.md) |
| de assistent **uitproberen** op een omgeving die al draait | [TESTEN.md](../TESTEN.md) |
| een eigen omgeving **inrichten** op drie VPS'en | [server/INRICHTING.md](../server/INRICHTING.md): stap voor stap, ook voor wie geen systeembeheerder is |
| de **huisstijl** van de gemeente instellen | [huisstijl/README.md](../huisstijl/README.md) |
| het **inlogscherm** aanpassen | [keycloak-thema/README.md](../keycloak-thema/README.md) |
| de **beveiliging van het beheerportaal** beoordelen | [oa-beheer/docs/security.md](https://github.com/Digitaal-Gemeengoed/oa-beheer/blob/main/docs/security.md) |
| weten **wat er veranderd is** | [CHANGELOG.md](../CHANGELOG.md) |
| **ontwikkelen** aan een onderdeel | [README van oa-uitrol](../README.md#op-één-machine) en de README van de repository (zie hieronder) |

## Architectuur en ontwerpen

- [Architectuur werkend prototype](architectuur.md): doel, uitgangspunten, bouwblokken, technologiekeuzes, uitrol, inrichting per gemeente en alle besluiten (OA-ADR-001 tot en met 011).
- Ontwerpen per onderdeel, met de besluiten en de stand van zaken:
  - [Metadatamodel per gemeente](ontwerp/metadatamodel.md)
  - [Classificeren, bewaren en vergrendelen](ontwerp/classificeren-en-vergrendelen.md)
  - [Anonimiseren in het document](ontwerp/anonimiseren-in-het-document.md)
  - [Kwaliteit van het anonimiseren](ontwerp/kwaliteit-anonimiseren.md)

De ontwerpen noemen de versies waarin ze zijn gebouwd. Wat daarna veranderde, staat in de changelogs van de repositories.

## De repositories

Elke repository heeft een README over wat erin zit en hoe je het bouwt en test.

| Repository | Wat |
| --- | --- |
| [oa-uitrol](https://github.com/Digitaal-Gemeengoed/oa-uitrol) | Uitrol, scripts en deze documentatie |
| [oa-contract](https://github.com/Digitaal-Gemeengoed/oa-contract) | Het contract tussen alle onderdelen |
| [oa-kern](https://github.com/Digitaal-Gemeengoed/oa-kern) | De assistentkern met de modules |
| [oa-paneel](https://github.com/Digitaal-Gemeengoed/oa-paneel) | Het paneel in React met NL Design System |
| [oa-adapters](https://github.com/Digitaal-Gemeengoed/oa-adapters) | Adapters voor Word, LibreOffice en Collabora, en de demo-werkomgeving |
| [oa-integratielaag](https://github.com/Digitaal-Gemeengoed/oa-integratielaag) | Identiteit en de twee ingangen |
| [oa-beheer](https://github.com/Digitaal-Gemeengoed/oa-beheer) | Het beheerportaal |
| [oa-services](https://github.com/Digitaal-Gemeengoed/oa-services) | Assistent-services achter de lezende ingang |
| [oa-wcag](https://github.com/Digitaal-Gemeengoed/oa-wcag) | Toegankelijkheidscontrole van Office-bestanden |
| [opendop-mini](https://github.com/Digitaal-Gemeengoed/opendop-mini) | Het minimale platform |

## Deze documentatie bijwerken

De bestanden in deze map zijn leidend. Een wijziging in de architectuur of een nieuw besluit gaat in dezelfde commit of pull request als de code waar het over gaat. Een nieuwe ADR krijgt het volgende nummer (OA-ADR-012, …) in [architectuur.md](architectuur.md).
