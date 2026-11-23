#!/usr/bin/env bash
# Gemeenten in Keycloak (VPS 3, diensten). Een gemeente toevoegen gaat het
# eenvoudigst in het beheerportaal (pagina Gemeenten). Dit script maakt
# daarnaast de gemeenten uit GEMEENTEN in .env aan die nog niet bestaan
# (bestaande worden niet overschreven) en koppelt gebruikers op hun
# e-maildomein. bijwerken.sh doet dit ook; de timer oa-gemeenten koppelt elk
# kwartier (gemeenten.sh --koppelen). Zie docs/multi-tenant.md.
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
# De timer (elk kwartier): alleen gebruikers koppelen, stil als er niets verandert.
if [ "${1:-}" = --koppelen ]; then
  keycloak_gemeenten "$(compose_bestand diensten)" koppelen
  exit 0
fi
vul_env_aan .env GEMEENTEN "$GEMEENTEN_STANDAARD"
meld "Gemeenten in Keycloak"
gemeenten_lijst "$(sed -n 's/^GEMEENTEN=//p' .env | tail -1)" | while IFS=$'\t' read -r id naam domeinen; do
  echo "  $id  $naam  (${domeinen:-geen domein})"
done
keycloak_gemeenten "$(compose_bestand diensten)"
echo
