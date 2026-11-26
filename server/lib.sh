# Gedeelde hulpfuncties voor de serverscripts. Wordt ingelezen, niet gestart.
# shellcheck shell=bash

set -euo pipefail

OA_MAP="${OA_MAP:-/etc/oa}"
WG_MAP="${WG_MAP:-/etc/wireguard}"
OA_UITROL="${OA_UITROL:-/opt/oa-uitrol}"
WG_NET="10.66.0"
# shellcheck disable=SC2034  # gebruikt in de scripts die dit inlezen
WG_POORT=51820
# shellcheck disable=SC2034
ROLLEN=(toegang platform diensten)
# VPS 4 (gemeenschap) staat los van de Office Assistent: geen WireGuard, geen
# gedeeld.env. Daarom staat die rol niet in ROLLEN. De software staat in een
# eigen repo, in /opt/gemeenschap; oa-uitrol zorgt alleen voor de basis.
GEMEENSCHAP_MAP="${GEMEENSCHAP_MAP:-/opt/gemeenschap}"
# shellcheck disable=SC2034
GEMEENSCHAP_REPO="https://github.com/Digitaal-Gemeengoed/gemeenschap"

meld()     { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()       { printf '  \033[32m✓\033[0m %s\n' "$*"; }
waarschuw(){ printf '  \033[33m!\033[0m %s\n' "$*"; }
stop()     { printf '\n\033[1;31mGestopt:\033[0m %s\n\n' "$*" >&2; exit 1; }

# De traagste stappen uit een bouwlog van "docker compose build --progress=plain".
traagste_stappen() {
  awk '
    /^#[0-9]+ \[/ { id = $1; $1 = ""; naam[id] = substr($0, 2) }
    /^#[0-9]+ DONE [0-9.]+s$/ { t = $3; sub(/s$/, "", t); if ($1 in naam) printf "%.1f\t%s\n", t, naam[$1] }
  ' "$1" | sort -rn | head -n "${2:-5}" | while IFS=$'\t' read -r sec stap; do
    printf '      %6ss  %s\n' "$sec" "${stap:0:90}"
  done || true
}

moet_root() {
  [ "$(id -u)" -eq 0 ] || stop "Start dit script met sudo ervoor, bijvoorbeeld: sudo $0"
}

# Het nummer van een rol in het WireGuard-netwerk: 10.66.0.1, .2, .3
wg_nr() {
  case "$1" in toegang) echo 1 ;; platform) echo 2 ;; diensten) echo 3 ;; *) stop "Onbekende rol: $1" ;; esac
}
wg_ip() { echo "$WG_NET.$(wg_nr "$1")"; }

vps_naam() {
  case "$1" in toegang) echo "VPS 1 (toegang)" ;; platform) echo "VPS 2 (platform)" ;; diensten) echo "VPS 3 (diensten)" ;; gemeenschap) echo "VPS 4 (gemeenschap)" ;; esac
}

compose_bestand() {
  case "$1" in toegang) echo vps1-toegang.yml ;; platform) echo vps2-platform.yml ;; diensten) echo vps3-diensten.yml ;; esac
}

rol() {
  [ -s "$OA_MAP/rol" ] || stop "Deze server heeft nog geen rol. Begin met inrichten.sh."
  cat "$OA_MAP/rol"
}

# Het publieke IPv4-adres: het bronadres van de route naar buiten.
publiek_ip() {
  ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") { print $(i + 1); exit }}'
}

# Het adres waarover WireGuard loopt: het adres in het privénetwerk van de
# provider als dat er is (bij Contabo 10.0.20.0/22), anders het publieke.
# Docker-, WireGuard- en veth-kaarten tellen niet mee.
koppel_ip() {
  local p
  p="$(ip -4 -o addr show scope global 2>/dev/null \
    | awk '$2 !~ /^(docker|br-|veth|wg|lo)/ {split($4, a, "/"); print a[1]}' \
    | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)' | grep -v "^$WG_NET\." | head -1)"
  echo "${p:-$(publiek_ip)}"
}

vraag_ja() {
  local a
  read -r -p "$1 [ja/nee] " a
  [[ "${a,,}" =~ ^(j|ja|y|yes)$ ]]
}

# Willekeurig geheim, alleen hexadecimale tekens: veilig in .env, JSON en URL's.
geheim() { openssl rand -hex "${1:-32}"; }

# Leest een KEY=waarde-bestand zonder het als script uit te voeren.
# Alleen hoofdletters, cijfers en _ als naam; waarden zonder spaties of quotes.
lees_env() {
  local bestand="$1" regel naam waarde
  [ -f "$bestand" ] || return 0
  while IFS= read -r regel || [ -n "$regel" ]; do
    regel="${regel%$'\r'}"
    [[ -z "$regel" || "$regel" == \#* ]] && continue
    [[ "$regel" =~ ^([A-Z][A-Z0-9_]*)=([A-Za-z0-9+/=.:_,@-]*)$ ]] || stop "Onverwachte regel in $bestand: $regel"
    naam="${BASH_REMATCH[1]}"
    waarde="${BASH_REMATCH[2]}"
    printf -v "$naam" '%s' "$waarde"
    export "${naam?}"
  done < "$bestand"
}

# Voegt KEY=waarde aan .env toe als KEY er nog niet in staat. Zo krijgt een
# bestaande installatie nieuwe instellingen zonder dat wachtwoorden veranderen.
vul_env_aan() {
  local bestand="$1" naam="$2" waarde="$3"
  grep -q "^${naam}=" "$bestand" 2>/dev/null && return 0
  echo "${naam}=${waarde}" >> "$bestand"
  ok "Nieuwe instelling in .env: $naam"
}

# Nieuwe instellingen op VPS 1: Collabora Online (profiel "collabora", staat
# standaard aan) en het beheerportaal.
vul_toegang_aan() {
  # Beheerportaal: geheimen nieuw; Keycloak en SMTP leeg tot beheer.sh ze zet.
  vul_env_aan "$1" BEHEER_ADMIN_SECRET "$(geheim 32)"
  vul_env_aan "$1" BEHEER_DB_EIGENAAR_WACHTWOORD "$(geheim 24)"
  vul_env_aan "$1" BEHEER_DB_APP_WACHTWOORD "$(geheim 24)"
  vul_env_aan "$1" BEHEER_OIDC_ISSUER ""
  vul_env_aan "$1" BEHEER_OIDC_SECRET ""
  vul_env_aan "$1" COLLABORA_INTERN "http://collabora:9980"
  vul_env_aan "$1" COLLABORA_VERSIE "26.04.5.2.1"
  # Proef: extensies in Collabora (de assistent als extensie, /collabora-proef). Standaard aan.
  vul_env_aan "$1" COLLABORA_EXPERIMENTEEL "true"
  if grep -q '^COMPOSE_PROFILES=' "$1"; then
    grep -q '^COMPOSE_PROFILES=.*collabora' "$1" || sed -i 's/^COMPOSE_PROFILES=\(.*\)$/COMPOSE_PROFILES=\1,collabora/; s/^COMPOSE_PROFILES=,/COMPOSE_PROFILES=/' "$1"
  else
    vul_env_aan "$1" COMPOSE_PROFILES collabora
  fi
}

# Nieuwe instellingen op VPS 2: omzetten naar PDF/A (Archiefregeling 2026, art. 2.9),
# standaard aan. Uitzetten: OMZETTER_URL= (leeg) en "omzetten" uit COMPOSE_PROFILES.
vul_platform_aan() {
  vul_env_aan "$1" GOTENBERG_VERSIE 8
  if ! grep -q '^OMZETTER_URL=' "$1"; then
    vul_env_aan "$1" OMZETTER_URL "http://omzetter:3000"
    if grep -q '^COMPOSE_PROFILES=' "$1"; then
      grep -q '^COMPOSE_PROFILES=.*omzetten' "$1" || sed -i 's/^COMPOSE_PROFILES=\(.*\)$/COMPOSE_PROFILES=\1,omzetten/; s/^COMPOSE_PROFILES=,/COMPOSE_PROFILES=/' "$1"
    else
      vul_env_aan "$1" COMPOSE_PROFILES omzetten
    fi
  fi
}

# Zet KEY=waarde in .env: vervangt een bestaande regel of voegt toe. De waarde
# komt er letterlijk in; aanhalingstekens moet de aanroeper zelf zetten.
zet_env() {
  local bestand="$1" naam="$2" waarde="$3" tijdelijk
  tijdelijk="$(mktemp "$bestand.XXXXXX")"
  grep -v "^${naam}=" "$bestand" > "$tijdelijk" || true
  printf '%s=%s\n' "$naam" "$waarde" >> "$tijdelijk"
  chmod 600 "$tijdelijk"
  mv "$tijdelijk" "$bestand"
}

# Laat de beheerder (standaard "beheer") de bijwerkscripts zonder wachtwoord
# met sudo starten, en verder niets. Alleen als niemand anders dan root de
# scripts kan wijzigen: anders zou dit iedereen met schrijfrechten root geven.
# Uitzetten: OA_SUDO_ZONDER_WACHTWOORD=nee.
SUDO_REGELBESTAND=/etc/sudoers.d/oa-bijwerken
sudo_zonder_wachtwoord() {
  local gebruiker="${OA_BEHEERDER:-beheer}" scripts=() map s regels tijdelijk
  if [ "${OA_SUDO_ZONDER_WACHTWOORD:-ja}" = nee ]; then
    rm -f "$SUDO_REGELBESTAND"; return 0
  fi
  id "$gebruiker" >/dev/null 2>&1 || return 0
  command -v visudo >/dev/null || return 0
  scripts=("$OA_UITROL/server/bijwerken.sh")
  for s in uitrol.sh bijwerken.sh; do
    [ -f "$GEMEENSCHAP_MAP/server/$s" ] && scripts+=("$GEMEENSCHAP_MAP/server/$s")
  done
  # Alles in de repo's en de mappen erboven moet van root zijn en voor anderen
  # alleen-lezen (git gebruikt geen symlinks naar buiten; die slaan we over).
  for map in "$OA_UITROL" "$GEMEENSCHAP_MAP"; do
    [ -d "$map" ] || continue
    if [ -n "$(find "$map" -path "$map/bron" -prune -o \( ! -type l \) \( ! -user root -o -perm /022 \) -print -quit)" ] \
       || [ -n "$(find /opt -maxdepth 0 \( ! -user root -o -perm /022 \) -print)" ]; then
      waarschuw "Sudo zonder wachtwoord niet ingesteld: in $map kan iemand anders dan root bestanden wijzigen."
      echo "  Zoek ze met: sudo find $map \\( ! -user root -o -perm /022 \\) -not -type l"
      rm -f "$SUDO_REGELBESTAND"; return 0
    fi
  done
  regels="# Door oa-uitrol (lib.sh, sudo_zonder_wachtwoord). Niet met de hand wijzigen."
  for s in "${scripts[@]}"; do regels+=$'\n'"$gebruiker ALL=(root) NOPASSWD: $s"; done
  [ -f "$SUDO_REGELBESTAND" ] && [ "$(cat "$SUDO_REGELBESTAND")" = "$regels" ] && return 0
  tijdelijk="$(mktemp)"
  printf '%s\n' "$regels" > "$tijdelijk"
  if visudo -cqf "$tijdelijk"; then
    install -m 0440 -o root -g root "$tijdelijk" "$SUDO_REGELBESTAND"
    ok "$gebruiker mag de bijwerkscripts nu zonder wachtwoord starten (met het volledige pad)"
  else
    waarschuw "De sudo-regel klopt niet; niets gewijzigd."
  fi
  rm -f "$tijdelijk"
}

# SHA-256 van een bestand, of "geen" als het er (nog) niet is. Veilig onder
# set -euo pipefail: een ontbrekend bestand stopt het script niet.
controlesom() {
  if [ -f "$1" ]; then sha256sum "$1" | cut -c1-64; else echo geen; fi
}

# Huisstijl van deze inrichting (VPS 1 en VPS 3): OA_HUISSTIJL in .env, een
# naam uit huisstijl/catalogus.txt (standaard voorbeeld). Haalt het pakket van
# npm, controleert de integriteit die npm opgeeft, en zet de CSS in
# huisstijl/huisstijl.css en de klasse in OA_HUISSTIJL_KLASSE. Doet niets als
# die versie er al staat. Mislukt het ophalen, dan blijft de vorige staan.
HUISSTIJL_NPM="${HUISSTIJL_NPM:-https://registry.npmjs.org}"
huisstijl_bijwerken() {
  local env="$OA_UITROL/.env" map="$OA_UITROL/huisstijl" naam regel klasse pakket versie bestand kop meta tarball integriteit werk som
  naam="$(sed -n 's/^OA_HUISSTIJL=//p' "$env" | tail -1)"; naam="${naam:-voorbeeld}"
  regel="$(awk -v n="$naam" '$1 == n { print; exit }' "$map/catalogus.txt")"
  if [ -z "$regel" ]; then
    waarschuw "Huisstijl $naam staat niet in huisstijl/catalogus.txt; ik gebruik voorbeeld."
    naam=voorbeeld; regel="$(awk '$1 == "voorbeeld" { print; exit }' "$map/catalogus.txt")"
  fi
  read -r _ klasse pakket versie bestand <<<"$regel"
  kop="/* huisstijl $naam: $pakket@$versie $bestand */"
  if [ ! -f "$map/huisstijl.css" ] || [ "$(head -n 1 "$map/huisstijl.css")" != "$kop" ]; then
    command -v jq >/dev/null || apt-get install -y -qq jq >/dev/null
    werk="$(mktemp -d)"
    if meta="$(curl -fsS --max-time 30 "$HUISSTIJL_NPM/$pakket/$versie")" \
       && tarball="$(jq -r '.dist.tarball // empty' <<<"$meta")" && integriteit="$(jq -r '.dist.integrity // empty' <<<"$meta")" \
       && [ -n "$tarball" ] && [[ "$integriteit" == sha512-* ]] \
       && curl -fsS --max-time 60 -o "$werk/pakket.tgz" "$tarball"; then
      som="sha512-$(openssl dgst -sha512 -binary "$werk/pakket.tgz" | base64 -w0)"
      if [ "$som" != "$integriteit" ]; then
        waarschuw "Huisstijl $naam: het pakket klopt niet met de controlesom van npm. Niets gewijzigd."
      elif tar -xzf "$werk/pakket.tgz" -C "$werk" "package/$bestand" 2>/dev/null; then
        { echo "$kop"; cat "$werk/package/$bestand"; } > "$werk/huisstijl.css"
        install -m 0644 "$werk/huisstijl.css" "$map/huisstijl.css"
        ok "Huisstijl $naam opgehaald ($pakket@$versie)"
      else
        waarschuw "Huisstijl $naam: $bestand staat niet in $pakket@$versie. Niets gewijzigd."
      fi
    else
      waarschuw "Huisstijl $naam ophalen van npm lukte niet. De vorige huisstijl blijft staan."
    fi
    rm -rf "$werk"
  fi
  # De klasse alleen aanpassen als de CSS die erbij hoort er ook echt staat.
  if [ "$(head -n 1 "$map/huisstijl.css" 2>/dev/null)" = "$kop" ]; then
    [ "$(sed -n 's/^OA_HUISSTIJL_KLASSE=//p' "$env" | tail -1)" = "$klasse" ] || zet_env "$env" OA_HUISSTIJL_KLASSE "$klasse"
  fi
}

# Inlogthema van Keycloak (VPS 3). Keycloak houdt thema's in het geheugen, dus
# na een wijziging in keycloak-thema/ eerst herstarten (tweede argument "ja").
# Daarna het thema op het realm zetten: de realm-import doet dat alleen bij
# een nieuwe server. OA_LOGIN_THEMA in .env kiest een ander thema
# (bijvoorbeeld keycloak.v2, het standaardthema van Keycloak).
keycloak_thema() {
  local compose="$1" herstart="${2:-nee}" env="$OA_UITROL/.env" thema gebruiker wachtwoord binnen=nee
  thema="$(sed -n 's/^OA_LOGIN_THEMA=//p' "$env" | tail -1)"; thema="${thema:-oa}"
  gebruiker="$(sed -n 's/^KC_BEHEERDER=//p' "$env" | tail -1)"
  wachtwoord="$(sed -n 's/^KC_BEHEERDER_WACHTWOORD=//p' "$env" | tail -1)"
  kcadm() { docker compose -f "$compose" --env-file "$env" exec -T keycloak /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/oa-kcadm.config; }
  if [ "$herstart" = ja ]; then
    docker compose -f "$compose" --env-file "$env" restart keycloak >/dev/null && ok "Keycloak herstart voor het nieuwe inlogthema"
  fi
  for _ in $(seq 1 30); do
    kcadm config credentials --server http://localhost:8080 --realm master \
      --user "${gebruiker:-beheer}" --password "$wachtwoord" >/dev/null 2>&1 && { binnen=ja; break; }
    sleep 3
  done
  if [ "$binnen" = nee ]; then
    waarschuw "Inlogthema niet ingesteld: inloggen op Keycloak lukte niet. Kijk met: sudo docker compose -f $compose logs keycloak"
    return 0
  fi
  if kcadm update realms/gemeenten -s "loginTheme=$thema" >/dev/null 2>&1; then
    ok "Inlogthema: $thema"
  else
    waarschuw "Inlogthema $thema instellen lukte niet."
  fi
  docker compose -f "$compose" --env-file "$env" exec -T keycloak rm -f /tmp/oa-kcadm.config >/dev/null 2>&1 || true
}

# --- Gemeenten in Keycloak (VPS 3) ---------------------------------------------
# GEMEENTEN in .env op VPS 3: "id:Naam:domein+domein,id:Naam:domein", bijvoorbeeld
#   GEMEENTEN="haarlem:Gemeente Haarlem:haarlem.nl,zandvoort:Gemeente Zandvoort:zandvoort.nl"
# Elke gemeente wordt een organisatie in Keycloak (alias = id, attribuut naam),
# met haar e-maildomeinen. Een gebruiker met een e-mailadres op zo'n domein wordt
# lid, en krijgt die gemeente als attribuut 'gemeente' (de thuisgemeente) als dat
# nog leeg is. Een gebruiker kan lid zijn van meer gemeenten (bijvoorbeeld bij een
# GR); de assistent werkt dan voor de thuisgemeente.
# Voor een test: OA_KCADM="pad/naar/kcadm.sh --config ..." (al ingelogd).
GEMEENTEN_STANDAARD='"haarlem:Gemeente Haarlem:haarlem.nl,zandvoort:Gemeente Zandvoort:zandvoort.nl"'

# Leest GEMEENTEN en schrijft per gemeente een regel "id<TAB>naam<TAB>domein domein".
gemeenten_lijst() {
  local tekst="$1" deel id naam domeinen
  tekst="${tekst#\"}"; tekst="${tekst%\"}"
  IFS=',' read -r -a delen <<< "$tekst"
  for deel in "${delen[@]}"; do
    deel="$(echo "$deel" | sed 's/^ *//; s/ *$//')"
    [ -n "$deel" ] || continue
    id="${deel%%:*}"; naam="${deel#*:}"; domeinen=""
    [ "$naam" = "$deel" ] && naam="$id"
    if [[ "$naam" == *:* ]]; then domeinen="${naam##*:}"; naam="${naam%:*}"; fi
    [[ "$id" =~ ^[a-z0-9-]{2,40}$ ]] || { waarschuw "GEMEENTEN: '$id' is geen geldige gemeente (kleine letters, cijfers en -)."; continue; }
    printf '%s\t%s\t%s\n' "$id" "$naam" "${domeinen//+/ }"
  done
}

# keycloak_gemeenten <compose> [koppelen]
# Volledig (bijwerken.sh, gemeenten.sh): organisaties aan, scope en mapper,
# het service-account van het beheerportaal, ontbrekende gemeenten uit
# GEMEENTEN aanmaken, gebruikers koppelen. "koppelen" (de timer, elk kwartier):
# alleen gebruikers koppelen, stil als er niets verandert.
# Keycloak is de bron: een gemeente die al bestaat (ook een die het portaal
# aanmaakte of wijzigde), wordt niet overschreven vanuit GEMEENTEN.
keycloak_gemeenten() {
  local compose="$1" modus="${2:-volledig}" env="$OA_UITROL/.env" R=gemeenten tekst gebruiker wachtwoord binnen=nee
  tekst="$(sed -n 's/^GEMEENTEN=//p' "$env" | tail -1)"
  [ "$modus" = koppelen ] && { ok() { :; }; }
  if [ -n "${OA_KCADM:-}" ]; then
    kcg() { $OA_KCADM "$@"; }
    binnen=ja
  else
    gebruiker="$(sed -n 's/^KC_BEHEERDER=//p' "$env" | tail -1)"
    wachtwoord="$(sed -n 's/^KC_BEHEERDER_WACHTWOORD=//p' "$env" | tail -1)"
    kcg() { docker compose -f "$compose" --env-file "$env" exec -T keycloak /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/oa-kcadm-g.config; }
    for _ in $(seq 1 30); do
      kcg config credentials --server http://localhost:8080 --realm master \
        --user "${gebruiker:-beheer}" --password "$wachtwoord" >/dev/null 2>&1 && { binnen=ja; break; }
      sleep 3
    done
  fi
  if [ "$binnen" = nee ]; then
    waarschuw "Gemeenten niet bijgewerkt: inloggen op Keycloak lukte niet."
    return 0
  fi
  command -v jq >/dev/null || apt-get install -y -qq jq >/dev/null
  if [ "$modus" != koppelen ]; then

  # Organisaties aan, en de scope 'organization' (claim met alle gemeenten en hun
  # naam) op de clients van de integratielaag en het beheerportaal.
  kcg update "realms/$R" -s organizationsEnabled=true >/dev/null
  local scope mapper client cid
  scope="$(kcg get client-scopes -r $R --fields id,name 2>/dev/null | jq -r '.[] | select(.name=="organization") | .id')"
  if [ -n "$scope" ]; then
    mapper="$(kcg get "client-scopes/$scope/protocol-mappers/models" -r $R 2>/dev/null | jq -r '[.[] | select(.protocolMapper=="oidc-organization-membership-mapper")][0].id // empty')"
    [ -n "$mapper" ] && kcg update "client-scopes/$scope/protocol-mappers/models/$mapper" -r $R \
      -s name=organization -s protocol=openid-connect -s protocolMapper=oidc-organization-membership-mapper \
      -s 'config."claim.name"=organization' -s 'config."jsonType.label"=JSON' -s 'config."multivalued"=true' \
      -s 'config."addOrganizationAttributes"=true' -s 'config."id.token.claim"=true' \
      -s 'config."access.token.claim"=true' -s 'config."introspection.token.claim"=true' >/dev/null
    for client in oa-integratielaag oa-beheer; do
      cid="$(kcg get clients -r $R -q clientId=$client --fields id 2>/dev/null | jq -r '.[0].id // empty')"
      [ -n "$cid" ] || continue
      if ! kcg get "clients/$cid/optional-client-scopes" -r $R 2>/dev/null | jq -e '.[] | select(.name=="organization")' >/dev/null \
         && ! kcg get "clients/$cid/default-client-scopes" -r $R 2>/dev/null | jq -e '.[] | select(.name=="organization")' >/dev/null; then
        kcg update "clients/$cid/optional-client-scopes/$scope" -r $R >/dev/null && ok "Scope organization op $client"
      fi
    done
  else
    waarschuw "Keycloak heeft geen scope 'organization'; is dit Keycloak 26 of nieuwer?"
  fi

  # Het beheerportaal maakt zelf gemeenten aan (pagina Gemeenten): een
  # service-account op de client oa-beheer met alleen manage-organizations en
  # view-users, en de scope kc-admin-api (vanaf Keycloak 26.8.2 vereist voor de
  # beheer-API). Gebruikers koppelen blijft hier, op VPS 3.
  local beheer adminscope
  beheer="$(kcg get clients -r $R -q clientId=oa-beheer --fields id 2>/dev/null | jq -r '.[0].id // empty')"
  if [ -n "$beheer" ]; then
    kcg update "clients/$beheer" -r $R -s serviceAccountsEnabled=true >/dev/null 2>&1
    for rol in manage-organizations view-users; do
      kcg add-roles -r $R --uusername service-account-oa-beheer --cclientid realm-management --rolename "$rol" >/dev/null 2>&1 || true
    done
    adminscope="$(kcg get client-scopes -r $R --fields id,name 2>/dev/null | jq -r '.[] | select(.name=="kc-admin-api") | .id')"
    [ -n "$adminscope" ] && kcg update "clients/$beheer/default-client-scopes/$adminscope" -r $R >/dev/null 2>&1
    ok "Beheerportaal mag gemeenten aanmaken (service-account: manage-organizations, view-users)"

    # Het PPL-niveau van medewerkers (pagina Medewerkers): fijnmazige
    # beheerrechten (Keycloak 26.2+). Het service-account mag bij gebruikers
    # alleen rollen toekennen, en dan alleen ppl-1, ppl-2 en ppl-3. Andere
    # rollen, gebruikersgegevens of sessies blijven buiten bereik.
    local ap pol rol ids
    kcg update "realms/$R" -s adminPermissionsEnabled=true >/dev/null 2>&1
    ap="$(kcg get clients -r $R -q clientId=admin-permissions --fields id 2>/dev/null | jq -r '.[0].id // empty')"
    if [ -z "$ap" ]; then
      waarschuw "Keycloak kent geen fijnmazige beheerrechten (admin-permissions); het portaal kan het PPL-niveau niet wijzigen."
    else
      pol="$(kcg get "clients/$ap/authz/resource-server/policy" -r $R -q name=oa-beheer-portaal 2>/dev/null | jq -r '[.[] | select(.name=="oa-beheer-portaal")][0].id // empty')"
      if [ -z "$pol" ]; then
        jq -cn --arg c "$beheer" '{name:"oa-beheer-portaal", description:"Het service-account van het beheerportaal", clients:[$c], logic:"POSITIVE"}' \
          | kcg create "clients/$ap/authz/resource-server/policy/client" -r $R -f - >/dev/null 2>&1
        pol="$(kcg get "clients/$ap/authz/resource-server/policy" -r $R -q name=oa-beheer-portaal 2>/dev/null | jq -r '[.[] | select(.name=="oa-beheer-portaal")][0].id // empty')"
      fi
      ids="$(for rol in ppl-1 ppl-2 ppl-3; do kcg get "roles/$rol" -r $R --fields id 2>/dev/null | jq -r '.id // empty'; done | jq -R . | jq -sc 'map(select(length>0))')"
      if [ -n "$pol" ] && [ "$(echo "$ids" | jq length)" = 3 ]; then
        kcg get "clients/$ap/authz/resource-server/permission" -r $R 2>/dev/null | jq -e '.[] | select(.name=="oa-beheer: rollen toekennen")' >/dev/null \
          || jq -cn --arg p "$pol" '{name:"oa-beheer: rollen toekennen", resourceType:"Users", scopes:["map-roles"], policies:[$p], decisionStrategy:"UNANIMOUS"}' \
            | kcg create "clients/$ap/authz/resource-server/permission/scope" -r $R -f - >/dev/null 2>&1
        kcg get "clients/$ap/authz/resource-server/permission" -r $R 2>/dev/null | jq -e '.[] | select(.name=="oa-beheer: alleen ppl-rollen")' >/dev/null \
          || jq -cn --arg p "$pol" --argjson r "$ids" '{name:"oa-beheer: alleen ppl-rollen", resourceType:"Roles", resources:$r, scopes:["map-role"], policies:[$p], decisionStrategy:"UNANIMOUS"}' \
            | kcg create "clients/$ap/authz/resource-server/permission/scope" -r $R -f - >/dev/null 2>&1
        if kcg get "clients/$ap/authz/resource-server/permission" -r $R 2>/dev/null | jq -e '[.[] | select(.name=="oa-beheer: rollen toekennen" or .name=="oa-beheer: alleen ppl-rollen")] | length == 2' >/dev/null; then
          ok "Beheerportaal mag het PPL-niveau van medewerkers zetten (alleen de rollen ppl-1, ppl-2, ppl-3)"
        else
          waarschuw "Rechten voor het PPL-niveau in het portaal konden niet worden gezet."
        fi
      else
        waarschuw "Rollen ppl-1, ppl-2, ppl-3 ontbreken; draai keycloak-beheer.sh en daarna dit opnieuw."
      fi
    fi
  fi

  # Gemeenten uit GEMEENTEN die nog niet bestaan.
  local id naam domeinen json
  if [ -n "$tekst" ]; then
    while IFS=$'\t' read -r id naam domeinen; do
      kcg get organizations -r $R -q max=1000 2>/dev/null | jq -e --arg a "$id" '.[] | select(.alias==$a)' >/dev/null && continue
      json="$(jq -cn --arg n "$naam" --arg a "$id" --arg d "$domeinen" \
        '{name:$n, alias:$a, enabled:true, attributes:{naam:[$n]}, domains:[($d|split(" ")[]|select(length>0)|{name:., verified:true})]}')"
      echo "$json" | kcg create organizations -r $R -f - >/dev/null 2>&1 && ok "Gemeente $id ($naam) aangemaakt in Keycloak" \
        || waarschuw "Gemeente $id aanmaken in Keycloak lukte niet (staat een domein al bij een andere gemeente?)."
    done < <(gemeenten_lijst "$tekst")
  fi
  fi  # einde volledig

  # Welk domein bij welke gemeente hoort: uit Keycloak zelf (ook wat het portaal aanmaakte).
  local oid d
  declare -A ORG_VAN_DOMEIN=()
  while IFS=$'\t' read -r id oid domeinen; do
    for d in $domeinen; do ORG_VAN_DOMEIN[$d]="$id $oid"; done
  done < <(kcg get organizations -r $R -q max=1000 -q briefRepresentation=false 2>/dev/null | jq -r '.[] | select(.enabled != false) | [.alias, .id, ([.domains[]?.name] | join(" "))] | @tsv')

  # Gebruikers koppelen op hun e-maildomein.
  local eerste=0 blok u uid email dom thuis gekoppeld=0 zonder=0 doel
  while :; do
    blok="$(kcg get users -r $R -q first=$eerste -q max=200 -q briefRepresentation=false 2>/dev/null)" || break
    [ "$(echo "$blok" | jq 'length')" -gt 0 ] || break
    while IFS=$'\t' read -r uid email thuis; do
      dom="${email##*@}"
      doel="${ORG_VAN_DOMEIN[$dom]:-}"
      if [ -z "$doel" ]; then
        [ -n "$thuis" ] || zonder=$((zonder + 1))
        continue
      fi
      id="${doel%% *}"; oid="${doel#* }"
      if ! kcg get "organizations/$oid/members/$uid" -r $R >/dev/null 2>&1; then
        kcg create "organizations/$oid/members" -r $R -b "\"$uid\"" >/dev/null 2>&1 && gekoppeld=$((gekoppeld + 1))
      fi
      [ -n "$thuis" ] || kcg update "users/$uid" -r $R -s "attributes.gemeente=[\"$id\"]" >/dev/null 2>&1 || true
    done < <(echo "$blok" | jq -r '.[] | [.id, (.email // ""), (.attributes.gemeente[0] // "")] | @tsv')
    eerste=$((eerste + 200))
  done
  if [ "$modus" = koppelen ]; then
    [ "$gekoppeld" -eq 0 ] || echo "gemeenten: $gekoppeld gebruiker(s) gekoppeld op e-maildomein"
  else
    ok "Gemeenten in Keycloak bijgewerkt; $gekoppeld gebruiker(s) nieuw gekoppeld op e-maildomein"
    [ "$zonder" -eq 0 ] || waarschuw "$zonder gebruiker(s) horen nog bij geen gemeente: hun e-maildomein hoort bij geen gemeente."
  fi
  [ -n "${OA_KCADM:-}" ] || docker compose -f "$compose" --env-file "$env" exec -T keycloak rm -f /tmp/oa-kcadm-g.config >/dev/null 2>&1 || true
}

# Elk kwartier gebruikers op hun e-maildomein koppelen (VPS 3), zodat een gemeente
# die het beheerportaal aanmaakt, binnen een kwartier werkt.
gemeenten_timer() {
  cat > /etc/systemd/system/oa-gemeenten.service <<EOT
[Unit]
Description=Office Assistent: gebruikers op e-maildomein aan hun gemeente koppelen
After=docker.service

[Service]
Type=oneshot
ExecStart=$OA_UITROL/server/gemeenten.sh --koppelen
EOT
  cat > /etc/systemd/system/oa-gemeenten.timer <<'EOT'
[Unit]
Description=Office Assistent: gemeenten koppelen, elk kwartier

[Timer]
OnBootSec=5min
OnUnitActiveSec=15min

[Install]
WantedBy=timers.target
EOT
  systemctl daemon-reload
  systemctl enable --now oa-gemeenten.timer >/dev/null 2>&1 && ok "Gemeenten koppelen elk kwartier (oa-gemeenten.timer)" \
    || waarschuw "De timer oa-gemeenten kon niet aan; kijk met: systemctl status oa-gemeenten.timer"
}

# --- Inloggen: herstelcodes en herstel via e-mail (VPS 3) -----------------------
# Zie docs/inloggen-herstel.md.
#
# kc_verbind <compose>: logt in op Keycloak en geeft de functie kch (kcadm in de
# container). Voor een test: OA_KCADM="pad/naar/kcadm.sh --config ..." (al ingelogd).
kc_verbind() {
  local compose="$1" env="$OA_UITROL/.env" gebruiker wachtwoord
  if [ -n "${OA_KCADM:-}" ]; then
    kch() { $OA_KCADM "$@"; }
    return 0
  fi
  gebruiker="$(sed -n 's/^KC_BEHEERDER=//p' "$env" | tail -1)"
  wachtwoord="$(sed -n 's/^KC_BEHEERDER_WACHTWOORD=//p' "$env" | tail -1)"
  # shellcheck disable=SC2317
  kch() { docker compose -f "$KC_COMPOSE" --env-file "$OA_UITROL/.env" exec -T keycloak /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/oa-kcadm-h.config; }
  KC_COMPOSE="$compose"
  for _ in $(seq 1 30); do
    kch config credentials --server http://localhost:8080 --realm master \
      --user "${gebruiker:-beheer}" --password "$wachtwoord" >/dev/null 2>&1 && return 0
    sleep 3
  done
  return 1
}
kc_klaar() {
  [ -n "${OA_KCADM:-}" ] || docker compose -f "$KC_COMPOSE" --env-file "$OA_UITROL/.env" exec -T keycloak rm -f /tmp/oa-kcadm-h.config >/dev/null 2>&1 || true
}

# keycloak_herstel <compose>
# - Herstelcodes: na het koppelen van de authenticator-app maakt iedereen
#   herstelcodes aan; bij het inloggen kan "Op een andere manier inloggen" met
#   een herstelcode. Bestaande gebruikers met een app krijgen de stap bij hun
#   volgende inlog.
# - Herstel via e-mail ("Wachtwoord of authenticator kwijt?"): alleen als
#   Keycloak e-mail heeft (inlog.sh smtp). De link toont de QR-code opnieuw en
#   vraagt een nieuw wachtwoord. De oude koppeling blijft staan tot de gebruiker
#   haar zelf verwijdert ("Remove none"): wie na de link afhaakt, staat zo nooit
#   zonder authenticator (Keycloak zet de nieuwe stap alleen in de sessie).
# - Bescherming tegen raden (ook voor codes), en e-mailadres en gebruikersnaam
#   alleen door een beheerder te wijzigen: het e-maildomein bepaalt de gemeente
#   en de herstellink gaat naar dat adres.
keycloak_herstel() {
  local compose="$1" env="$OA_UITROL/.env" R=gemeenten flow ex otp rc rf cfg host
  if ! kc_verbind "$compose"; then
    waarschuw "Herstel bij inloggen niet ingesteld: inloggen op Keycloak lukte niet."
    return 0
  fi
  command -v jq >/dev/null || apt-get install -y -qq jq >/dev/null

  # Bescherming tegen raden: na 10 mislukte pogingen steeds langer wachten (max. 15 min).
  kch update "realms/$R" -s bruteForceProtected=true -s permanentLockout=false -s failureFactor=10 \
    -s waitIncrementSeconds=60 -s maxFailureWaitSeconds=900 -s maxDeltaTimeSeconds=43200 \
    -s quickLoginCheckMilliSeconds=1000 -s minimumQuickLoginWaitSeconds=60 >/dev/null \
    && ok "Bescherming tegen raden van wachtwoorden en codes staat aan"

  # E-mailadres en gebruikersnaam: alleen de beheerder wijzigt ze.
  if kch get users/profile -r $R 2>/dev/null \
      | jq '.attributes |= map(if (.name == "email" or .name == "username") then .permissions.edit = ["admin"] else . end)' \
      | kch update users/profile -r $R -f - >/dev/null 2>&1; then
    ok "E-mailadres en gebruikersnaam zijn alleen door een beheerder te wijzigen"
  else
    waarschuw "E-mailadres alleen-beheerder zetten lukte niet: zet in Keycloak bij Realm settings → User profile → email → Permissions 'Who can edit' op alleen Admin."
  fi

  # Herstelcodes: de verplichte actie aan, en na het koppelen van de app verplicht.
  if ! kch get authentication/required-actions/CONFIGURE_RECOVERY_AUTHN_CODES -r $R >/dev/null 2>&1; then
    kch create authentication/register-required-action -r $R \
      -s providerId=CONFIGURE_RECOVERY_AUTHN_CODES -s name="Recovery Authentication Codes" >/dev/null 2>&1 || true
  fi
  kch update authentication/required-actions/CONFIGURE_RECOVERY_AUTHN_CODES -r $R \
    -s alias=CONFIGURE_RECOVERY_AUTHN_CODES -s name="Recovery Authentication Codes" \
    -s providerId=CONFIGURE_RECOVERY_AUTHN_CODES -s enabled=true -s defaultAction=false -s priority=55 >/dev/null 2>&1
  kch update authentication/required-actions/CONFIGURE_TOTP/config -r $R \
    -b '{"config":{"add-recovery-codes":"true"}}' >/dev/null 2>&1 \
    || waarschuw "Herstelcodes na het koppelen van de app verplicht maken lukte niet (Keycloak 26.3 of nieuwer nodig)."

  # In de inlogflow: herstelcode als alternatief naast de app.
  flow="$(kch get "realms/$R" --fields browserFlow 2>/dev/null | jq -r '.browserFlow')"
  ex="$(kch get "authentication/flows/$(jq -rn --arg f "$flow" '$f|@uri')/executions" -r $R 2>/dev/null)"
  otp="$(jq -r '[.[] | select(.providerId == "auth-otp-form")][0].id // empty' <<<"$ex")"
  rc="$(jq -r '[.[] | select(.providerId == "auth-recovery-authn-code-form")][0].id // empty' <<<"$ex")"
  if [ -n "$otp" ] && [ -n "$rc" ]; then
    # De volledige stap terugsturen (anders zet Keycloak de prioriteit, en dus de
    # volgorde, op 0); een prioriteit 0 krijgt de standaardplek (OTP 30, code 50).
    for id in "$otp" "$rc"; do
      kch update "authentication/flows/$(jq -rn --arg f "$flow" '$f|@uri')/executions" -r $R \
        -b "$(jq -c --arg id "$id" '[.[] | select(.id == $id)][0] | .requirement = "ALTERNATIVE"
              | if (.priority // 0) == 0 then .priority = (if .providerId == "auth-otp-form" then 30 else 50 end) else . end' <<<"$ex")" >/dev/null
    done
    # In het token: amr "mfa" na een herstelcode (de app geeft "otp", zie
    # keycloak-beheer.sh); het portaal eist een tweede factor in amr.
    local rcfg
    rcfg="$(jq -r --arg id "$rc" '[.[] | select(.id == $id)][0].authenticationConfig // empty' <<<"$ex")"
    if [ -n "$rcfg" ]; then
      kch update "authentication/config/$rcfg" -r $R -b '{"alias":"oa-herstelcode-referentie","config":{"default.reference.value":"mfa"}}' >/dev/null 2>&1
    else
      kch create "authentication/executions/$rc/config" -r $R -b '{"alias":"oa-herstelcode-referentie","config":{"default.reference.value":"mfa"}}' >/dev/null 2>&1
    fi
    ok "Inloggen met een herstelcode kan (Op een andere manier inloggen); het portaal ziet dat als tweede factor"
  else
    waarschuw "De inlogflow '$flow' heeft geen stap voor herstelcodes. Zet in Keycloak bij Authentication → $flow 'Recovery Authentication Code Form' op Alternative (een eigen flow is nodig als dit een ingebouwde flow van vóór 26.3 is)."
  fi

  # Herstel via e-mail: alleen met e-mail voor Keycloak (inlog.sh smtp).
  host="$(sed -n 's/^KC_SMTP_HOST=//p' "$env" | tail -1)"
  # Vóór 26.7.2 had de herstelroute een ernstig lek (CVE-2026-18963): dan uit.
  local versie
  versie="$(kch get serverinfo 2>/dev/null | jq -r '.systemInfo.version // empty')"
  if [ -n "$host" ] && [ -n "$versie" ] && [ "$(printf '%s\n26.7.2\n' "${versie%%-*}" | sort -V | head -1)" != 26.7.2 ]; then
    waarschuw "Keycloak $versie is ouder dan 26.7.2 (lek CVE-2026-18963 in de herstelroute): 'Wachtwoord of authenticator kwijt?' blijft uit tot na de update."
    host=""
  fi
  if [ -n "$host" ]; then
    local poort tls gebr ww van naam
    poort="$(sed -n 's/^KC_SMTP_POORT=//p' "$env" | tail -1)"
    tls="$(sed -n 's/^KC_SMTP_TLS=//p' "$env" | tail -1)"
    gebr="$(sed -n "s/^KC_SMTP_GEBRUIKER='\?\([^']*\)'\?$/\1/p" "$env" | tail -1)"
    ww="$(sed -n "s/^KC_SMTP_WACHTWOORD='\?\([^']*\)'\?$/\1/p" "$env" | tail -1)"
    van="$(sed -n "s/^KC_SMTP_VAN='\?\([^']*\)'\?$/\1/p" "$env" | tail -1)"
    naam="$(sed -n "s/^KC_SMTP_VAN_NAAM='\?\([^']*\)'\?$/\1/p" "$env" | tail -1)"
    jq -n --arg h "$host" --arg p "${poort:-587}" --arg t "${tls:-starttls}" --arg u "$gebr" --arg w "$ww" \
      --arg v "${van:-$gebr}" --arg n "${naam:-Office Assistent}" \
      '{resetPasswordAllowed: true, smtpServer: ({host: $h, port: $p, from: $v, fromDisplayName: $n,
        ssl: (if $t == "tls" then "true" else "false" end), starttls: (if $t == "starttls" then "true" else "false" end),
        auth: (if $u == "" then "false" else "true" end)} + (if $u == "" then {} else {user: $u, password: $w} end))}' \
      | kch update "realms/$R" -f - >/dev/null && ok "E-mail voor Keycloak via $host; 'Wachtwoord of authenticator kwijt?' staat aan"
    kch update "realms/$R" -s emailTheme=oa >/dev/null 2>&1 || waarschuw "Het e-mailthema 'oa' zetten lukte niet; de herstelmail gebruikt de standaardtekst."
    # De link toont de QR-code opnieuw; de oude koppeling blijft (zie boven).
    rf="$(kch get "realms/$R" --fields resetCredentialsFlow 2>/dev/null | jq -r '.resetCredentialsFlow')"
    ex="$(kch get "authentication/flows/$(jq -rn --arg f "$rf" '$f|@uri')/executions" -r $R 2>/dev/null)"
    id="$(jq -r '[.[] | select(.providerId == "reset-otp")][0].id // empty' <<<"$ex")"
    cfg="$(jq -r '[.[] | select(.providerId == "reset-otp")][0].authenticationConfig // empty' <<<"$ex")"
    if [ -z "$id" ]; then
      waarschuw "De herstelflow '$rf' heeft geen stap 'Reset OTP': de link geeft dan alleen een nieuw wachtwoord."
    elif [ -n "$cfg" ]; then
      kch update "authentication/config/$cfg" -r $R -b '{"alias":"oa-reset-otp","config":{"action_on_otp_reset_flag":"Remove none"}}' >/dev/null \
        && ok "De herstellink toont de QR-code opnieuw"
    else
      kch create "authentication/executions/$id/config" -r $R -b '{"alias":"oa-reset-otp","config":{"action_on_otp_reset_flag":"Remove none"}}' >/dev/null 2>&1 \
        && ok "De herstellink toont de QR-code opnieuw"
    fi
  else
    kch update "realms/$R" -s resetPasswordAllowed=false >/dev/null
    waarschuw "Keycloak heeft geen e-mail: 'Wachtwoord of authenticator kwijt?' staat uit. Zet het aan met: sudo $OA_UITROL/server/inlog.sh smtp"
  fi

  # Bestaande gebruikers met een app maar zonder herstelcodes: bij de volgende inlog.
  local n=0 u
  while read -r u; do
    [ -n "$u" ] || continue
    local soorten acties
    soorten="$(kch get "users/$u/credentials" -r $R 2>/dev/null | jq -r '[.[].type] | join(",")')"
    [[ ",$soorten," == *",otp,"* && ",$soorten," != *",recovery-authn-codes,"* ]] || continue
    acties="$(kch get "users/$u" -r $R --fields requiredActions 2>/dev/null | jq -c '(.requiredActions // []) + ["CONFIGURE_RECOVERY_AUTHN_CODES"] | unique')"
    kch update "users/$u" -r $R -s "requiredActions=$acties" >/dev/null && n=$((n + 1))
  done < <(kch get users -r $R --fields id -q max=2000 2>/dev/null | jq -r '.[].id')
  [ "$n" -gt 0 ] && ok "$n gebruiker(s) maken bij hun volgende inlog herstelcodes aan"
  kc_klaar
}

# kc_authenticator_opnieuw <compose> <e-mailadres>: haalt de authenticator-app en de
# herstelcodes van een gebruiker weg en meldt hem af; bij de volgende inlog (na het
# wachtwoord) verschijnt de QR-code opnieuw, daarna nieuwe herstelcodes.
kc_authenticator_opnieuw() {
  local compose="$1" email="${2,,}" R=gemeenten u cred n=0 acties
  kc_verbind "$compose" || stop "Inloggen op Keycloak lukte niet."
  command -v jq >/dev/null || apt-get install -y -qq jq >/dev/null
  u="$(kch get users -r $R -q email="$email" -q exact=true --fields id 2>/dev/null | jq -r '.[0].id // empty')"
  [ -n "$u" ] || { kc_klaar; stop "Geen gebruiker met e-mailadres $email."; }
  while read -r cred; do
    [ -n "$cred" ] || continue
    kch delete "users/$u/credentials/$cred" -r $R >/dev/null && n=$((n + 1))
  done < <(kch get "users/$u/credentials" -r $R 2>/dev/null | jq -r '.[] | select(.type == "otp" or .type == "recovery-authn-codes") | .id')
  acties="$(kch get "users/$u" -r $R --fields requiredActions 2>/dev/null | jq -c '(.requiredActions // []) - ["CONFIGURE_RECOVERY_AUTHN_CODES"] + ["CONFIGURE_TOTP"] | unique')"
  kch update "users/$u" -r $R -s "requiredActions=$acties" >/dev/null
  kch create "users/$u/logout" -r $R >/dev/null 2>&1 || true
  kc_klaar
  ok "$email: $n koppeling(en) weggehaald en afgemeld. Bij de volgende inlog verschijnt na het wachtwoord de QR-code."
}

geldig_domein() { [[ "$1" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$ ]]; }
geldig_ip()     { [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }
geldige_wg()    { [[ "$1" =~ ^[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]=$ ]]; }
