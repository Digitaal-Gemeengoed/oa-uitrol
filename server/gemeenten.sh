#!/usr/bin/env bash
# Na het wijzigen van GEMEENTEN in .env op VPS 3 (diensten): de gemeenten in
# Keycloak bijwerken en gebruikers op hun e-maildomein koppelen. Mag vaker;
# bijwerken.sh doet dit ook elke keer. Zie docs/multi-tenant.md.
#
#   sudo /opt/oa-uitrol/server/gemeenten.sh
#
# Een gemeente erbij: voeg in .env aan GEMEENTEN toe "id:Naam:domein", bijvoorbeeld
#   GEMEENTEN="haarlem:Gemeente Haarlem:haarlem.nl,bloemendaal:Gemeente Bloemendaal:bloemendaal.nl"
# Meer domeinen voor één gemeente met een plus: "zandvoort:Gemeente Zandvoort:zandvoort.nl+zandvoort.org".
# Het platform (VPS 2) en het beheerportaal (VPS 1) zetten een nieuwe gemeente
# vanzelf klaar zodra iemand van die gemeente inlogt.

HIER="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HIER/lib.sh"
moet_root
[ "$(rol)" = diensten ] || stop "Keycloak draait op VPS 3 (diensten). Dit is $(vps_naam "$(rol)")."
cd "$OA_UITROL" || exit 1
[ -s .env ] || stop "Nog niet geïnstalleerd. Gebruik eerst installeer.sh."
vul_env_aan .env GEMEENTEN "$GEMEENTEN_STANDAARD"
meld "Gemeenten in Keycloak"
gemeenten_lijst "$(sed -n 's/^GEMEENTEN=//p' .env | tail -1)" | while IFS=$'\t' read -r id naam domeinen; do
  echo "  $id  $naam  (${domeinen:-geen domein})"
done
keycloak_gemeenten "$(compose_bestand diensten)"
echo
