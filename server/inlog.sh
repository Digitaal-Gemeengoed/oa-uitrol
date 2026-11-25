#!/usr/bin/env bash
# Inloggen bij de Office Assistent (VPS 3, diensten): herstel van de tweede factor.
# Zie docs/inloggen-herstel.md.
#
#   sudo /opt/oa-uitrol/server/inlog.sh smtp                      e-mail voor Keycloak instellen
#                                                                 (zet "Wachtwoord of authenticator kwijt?" aan)
#   sudo /opt/oa-uitrol/server/inlog.sh authenticator <e-mail>    authenticator-app en herstelcodes van
#                                                                 één gebruiker weghalen; bij de volgende
#                                                                 inlog ziet hij na het wachtwoord de QR-code
#   sudo /opt/oa-uitrol/server/inlog.sh status                    wat er aan staat
#
# Herstelcodes en de rest stelt bijwerken.sh in (keycloak_herstel in lib.sh).

HIER="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HIER/lib.sh"
moet_root
[ "$(rol)" = diensten ] || stop "Keycloak draait op VPS 3 (diensten). Dit is $(vps_naam "$(rol)")."
cd "$OA_UITROL" || exit 1
[ -s .env ] || stop "Nog niet geïnstalleerd. Gebruik eerst installeer.sh."
COMPOSE="$(compose_bestand diensten)"
waarde() { sed -n "s/^$1='\?\([^']*\)'\?$/\1/p" .env | tail -1; }

case "${1:-}" in
  smtp)
    meld "E-mail voor Keycloak (herstellink)"
    echo "  Keycloak stuurt de link bij 'Wachtwoord of authenticator kwijt?'."
    echo "  Gebruik gerust hetzelfde SMTP-account als het beheerportaal op VPS 1."
    read -r -p "  Server (bijvoorbeeld smtp.example.nl): " H
    [[ "$H" =~ ^[A-Za-z0-9.-]+$ ]] || stop "Dat is geen servernaam."
    read -r -p "  Poort [587]: " P; P="${P:-587}"
    [[ "$P" =~ ^[0-9]+$ ]] || stop "De poort is een getal."
    case "$P" in 465) T=tls ;; 25) T=geen ;; *) T=starttls ;; esac
    read -r -p "  Gebruikersnaam (vaak het e-mailadres; leeg = zonder inloggen): " G
    W=""
    [ -n "$G" ] && { read -r -s -p "  Wachtwoord (je ziet niets): " W; echo; }
    read -r -p "  Afzenderadres [${G:-noreply@$(sed -n 's/^DOMEIN=//p' .env | tail -1)}]: " V
    V="${V:-${G:-noreply@$(sed -n 's/^DOMEIN=//p' .env | tail -1)}}"
    [[ "$V" =~ ^[^@[:space:]]+@[^@[:space:]]+$ ]] || stop "Dat is geen e-mailadres."
    for v in "$G" "$W" "$V"; do
      [[ "$v" == *"'"* || "$v" == *$'\n'* ]] && stop "Een enkel aanhalingsteken (') kan niet in deze waarden."
    done
    zet_env .env KC_SMTP_HOST "$H"
    zet_env .env KC_SMTP_POORT "$P"
    zet_env .env KC_SMTP_TLS "$T"
    zet_env .env KC_SMTP_GEBRUIKER "'$G'"
    zet_env .env KC_SMTP_WACHTWOORD "'$W'"
    zet_env .env KC_SMTP_VAN "'$V'"
    zet_env .env KC_SMTP_VAN_NAAM "'Office Assistent'"
    chmod 600 .env
    ok "Opgeslagen in .env (versleuteling: $T)"
    keycloak_herstel "$COMPOSE"
    echo
    echo "  Proberen: open de inlogpagina, vul je e-mailadres in en kies"
    echo "  'Wachtwoord of authenticator kwijt?'. Komt er niets aan? Kijk in de logboeken:"
    echo "    docker compose -f $COMPOSE logs --since 10m keycloak | grep -i mail"
    echo
    ;;

  authenticator)
    E="${2:-}"
    [ -n "$E" ] || read -r -p "  E-mailadres van de gebruiker: " E
    [[ "$E" =~ ^[^@[:space:]]+@[^@[:space:]]+$ ]] || stop "Dat is geen e-mailadres."
    meld "Authenticator opnieuw koppelen: $E"
    echo "  Dit haalt de authenticator-app(s) en herstelcodes van deze gebruiker weg en meldt"
    echo "  hem overal af. Bij de volgende inlog ziet hij na het wachtwoord de QR-code, daarna"
    echo "  nieuwe herstelcodes. Doe dit alleen als je zeker weet dat de vraag van hem komt"
    echo "  (bijvoorbeeld via een bekend telefoonnummer of persoonlijk)."
    read -r -p "  Doorgaan? [j/N] " J
    [[ "$J" =~ ^[jJ]$ ]] || stop "Niets gewijzigd."
    kc_authenticator_opnieuw "$COMPOSE" "$E"
    echo
    ;;

  status|"")
    meld "Herstel bij inloggen"
    if [ -n "$(waarde KC_SMTP_HOST)" ]; then
      ok "E-mail voor Keycloak via $(waarde KC_SMTP_HOST): 'Wachtwoord of authenticator kwijt?' staat aan (na bijwerken.sh)"
    else
      waarschuw "Geen e-mail voor Keycloak: 'Wachtwoord of authenticator kwijt?' staat uit. Zet het aan met: sudo $0 smtp"
    fi
    ok "Herstelcodes en de beheeropdracht 'authenticator' zijn altijd beschikbaar"
    echo
    echo "  Gebruik: sudo $0 smtp | authenticator <e-mailadres> | status"
    echo
    ;;

  *)
    stop "Onbekende opdracht '$1'. Gebruik: smtp, authenticator <e-mailadres> of status."
    ;;
esac
