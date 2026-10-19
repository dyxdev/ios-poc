#!/usr/bin/env bash
# Imprime el UDID de un simulador de iPhone del iOS más nuevo disponible (el nombre, por stderr). Solo macOS.
# Sin verificar en un runner real: la forma del JSON de `simctl` se tomó de uso habitual.
set -euo pipefail
xcrun simctl list devices available -j | python3 -c '
import json, re, sys
data = json.load(sys.stdin)["devices"]
def version(runtime):
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    return (int(match.group(1)), int(match.group(2))) if match else (0, 0)
for runtime in sorted((r for r in data if version(r) != (0, 0)), key=version, reverse=True):
    phones = sorted((d for d in data[runtime] if d["name"].startswith("iPhone")), key=lambda d: d["name"])
    if phones:
        print(phones[0]["name"], runtime, file=sys.stderr)
        print(phones[0]["udid"])
        sys.exit(0)
sys.exit("No hay simulador de iPhone disponible")
'
