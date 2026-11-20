#!/usr/bin/env sh
# Haalt de CSS van de Utrecht-componenten en het voorbeeldthema van NL Design
# System op, in dezelfde versies als oa-paneel, en zet ze in het inlogthema.
# Van de Utrecht-CSS blijven alleen de componenten over die het thema gebruikt.
# Alleen nodig bij een nieuwe versie; de uitkomst staat in git.
#
# Gebruik: ./bouw-css.sh   (vraagt Node.js 20+ en npm)
set -eu
UTRECHT=9.0.16
VOORBEELD=14.2.0
HIER="$(cd "$(dirname "$0")" && pwd)"
DOEL="$HIER/oa/login/resources/css"
WERK="$(mktemp -d)"
trap 'rm -rf "$WERK"' EXIT
cd "$WERK"
npm init -y >/dev/null
npm install --silent --no-audit --no-fund \
  "@utrecht/component-library-css@$UTRECHT" \
  "@nl-design-system-unstable/voorbeeld-design-tokens@$VOORBEELD" purgecss@7
{ echo "/* @nl-design-system-unstable/voorbeeld-design-tokens $VOORBEELD (EUPL-1.2), dist/theme.css */"
  cat node_modules/@nl-design-system-unstable/voorbeeld-design-tokens/dist/theme.css; } > "$DOEL/voorbeeld-theme.css"
cat > purge.mjs <<'JS'
import { readFileSync, writeFileSync } from "node:fs";
import { PurgeCSS } from "purgecss";
const [css, uit, ...inhoud] = process.argv.slice(2);
const [r] = await new PurgeCSS().purge({
  css: [{ raw: readFileSync(css, "utf8") }],
  content: inhoud.map((f) => ({ raw: readFileSync(f, "utf8"), extension: "html" })),
  safelist: {
    // Varianten en toestanden die Keycloak of de browser pas later zet.
    standard: ["utrecht-document", /^utrecht-(button|textbox|textarea|form-field|form-label|checkbox|radio-button|alert|heading-2|paragraph|link|select)(--|__|$)/],
  },
});
writeFileSync(uit, r.css);
JS
mkdir -p "$WERK/uit"
node purge.mjs node_modules/@utrecht/component-library-css/dist/index.css "$WERK/uit/index.css" \
  "$HIER/oa/login/template.ftl" "$HIER/oa/login/theme.properties"
{ echo "/* @utrecht/component-library-css $UTRECHT (EUPL-1.2), alleen de componenten van het inlogthema */"
  cat "$WERK/uit/index.css"; } > "$DOEL/utrecht.css"
echo "Klaar: $(wc -c < "$DOEL/utrecht.css") + $(wc -c < "$DOEL/voorbeeld-theme.css") bytes"
