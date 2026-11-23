#!/usr/bin/env bash
# De Office Assistent bijwerken naar de nieuwste versie op GitHub: scripts en
# broncode ophalen, opnieuw bouwen en de gewijzigde containers herstarten.
# Wachtwoorden in .env blijven gelijk.
#
#   sudo /opt/oa-uitrol/server/bijwerken.sh

HIER="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HIER/lib.sh"
moet_root
ROL="$(rol)"
cd "$OA_UITROL" || exit 1
[ -s .env ] || stop "Nog niet geïnstalleerd. Gebruik installeer.sh."
COMPOSE="$(compose_bestand "$ROL")"

meld "Bijwerken op $(vps_naam "$ROL")"
if [ -z "${OA_BIJGEWERKT:-}" ]; then
  # De repo's staan sinds 2026-11-20 in de organisatie Digitaal-Gemeengoed.
  # GitHub stuurt het oude adres door, maar zet de remote liever goed.
  for MAP in "$OA_UITROL" "$GEMEENSCHAP_MAP"; do
    [ -d "$MAP/.git" ] || continue
    OUD="$(git -C "$MAP" remote get-url origin 2>/dev/null || true)"
    case "$OUD" in
      *github.com/digitaalgemeengoed/*)
        git -C "$MAP" remote set-url origin "${OUD/github.com\/digitaalgemeengoed\//github.com/Digitaal-Gemeengoed/}"
        ok "Remote van $MAP naar Digitaal-Gemeengoed" ;;
    esac
  done
  OA_THEMA_VOOR="$(git rev-parse -q --verify HEAD:keycloak-thema 2>/dev/null || echo geen)"
  git pull --ff-only --quiet || stop "oa-uitrol ophalen van GitHub lukte niet. Controleer de internetverbinding en probeer opnieuw."
  # Opnieuw starten met de nieuwe scripts: dit script en lib.sh zijn al
  # ingelezen in de oude versie, en die kent nieuwe instellingen nog niet.
  # Is het inlogthema veranderd, dan moet Keycloak (VPS 3) herstarten.
  OA_BIJGEWERKT=1 OA_THEMA_VOOR="$OA_THEMA_VOOR" exec "$HIER/bijwerken.sh" "$@"
fi
ok "oa-uitrol $(git rev-parse --short HEAD)"
sudo_zonder_wachtwoord
# VPS 4 (gemeenschap) werkt zichzelf bij vanuit GitHub (gemeenschap/server/uitrol.sh).
if [ "$ROL" = gemeenschap ]; then
  ok "De basis van de server is bijgewerkt. Het gemeenschapsplatform rolt zelf uit vanuit GitHub;"
  echo "  nu meteen kijken: sudo $GEMEENSCHAP_MAP/server/uitrol.sh"
  exit 0
fi
[ "$ROL" = toegang ] && vul_toegang_aan .env
[ "$ROL" = platform ] && vul_platform_aan .env
[ "$ROL" = diensten ] && vul_env_aan .env GEMEENTEN "$GEMEENTEN_STANDAARD"
HUISSTIJL_VOOR="$(controlesom huisstijl/huisstijl.css)"
case "$ROL" in toegang|diensten) huisstijl_bijwerken ;; esac
HUISSTIJL_NU="$(controlesom huisstijl/huisstijl.css)"
./haal-op.sh >/dev/null || stop "De broncode ophalen van GitHub lukte niet. Er is niets veranderd; probeer het straks opnieuw."
ok "Broncode opgehaald"
# Alleen images van buiten ophalen; wat hier gebouwd wordt, slaat pull over.
docker compose -f "$COMPOSE" --env-file .env pull --quiet --ignore-buildable --ignore-pull-failures 2>/dev/null || true
# Bouwen met een log, zodat te zien is welke stap tijd kost.
BOUWLOG="$OA_UITROL/bouw.log"
BEGIN=$(date +%s)
if ! docker compose -f "$COMPOSE" --env-file .env build --progress=plain >"$BOUWLOG" 2>&1; then
  tail -n 30 "$BOUWLOG" >&2
  stop "Bouwen lukte niet; de volledige uitvoer staat in $BOUWLOG. De draaiende containers zijn niet veranderd."
fi
ok "Gebouwd in $(( $(date +%s) - BEGIN )) s; de traagste stappen (log: $BOUWLOG):"
traagste_stappen "$BOUWLOG" 5
docker compose -f "$COMPOSE" --env-file .env up -d --remove-orphans
if [ "$ROL" = toegang ]; then
  # Een gewijzigde Caddyfile geldt pas na herladen; certificaten blijven staan.
  docker compose -f "$COMPOSE" --env-file .env exec -T proxy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null 2>&1 \
    && ok "Caddy herladen" || waarschuw "Caddy herladen lukte niet; kijk met: sudo docker compose -f $COMPOSE logs proxy"
fi
if [ "$ROL" = diensten ]; then
  THEMA_NU="$(git rev-parse -q --verify HEAD:keycloak-thema 2>/dev/null || echo geen)"
  # Keycloak houdt thema en huisstijl in het geheugen: herstarten na een wijziging.
  keycloak_thema "$COMPOSE" "$([ "${OA_THEMA_VOOR:-geen}" != "$THEMA_NU" ] || [ "$HUISSTIJL_VOOR" != "$HUISSTIJL_NU" ] && echo ja || echo nee)"
  keycloak_gemeenten "$COMPOSE"
  gemeenten_timer
fi
docker image prune -f >/dev/null
ok "Bijgewerkt"
[ "$ROL" = diensten ] && echo "  Is OpenBao opnieuw gestart? Dan eerst: sudo $OA_UITROL/server/ontzegel.sh"
echo
