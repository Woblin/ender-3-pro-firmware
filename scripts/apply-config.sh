#!/usr/bin/env bash
# Kopierar våra configfiler in i Marlin-submodulen så att den kan byggas.
# Användning: ./scripts/apply-config.sh   (sedan: cd Marlin && pio run -e <env>)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$ROOT/Marlin/Marlin/Configuration.h" ] || git -C "$ROOT" submodule update --init
for f in Configuration.h Configuration_adv.h _Bootscreen.h _Statusscreen.h; do
  [ -f "$ROOT/config/$f" ] && cp "$ROOT/config/$f" "$ROOT/Marlin/Marlin/$f" && echo "kopierade $f"
done
echo "Klart. Bygg med: cd Marlin && pio run -e <env från README>"
