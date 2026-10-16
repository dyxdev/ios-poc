#!/usr/bin/env python3
"""Comprueba el catálogo de textos: paridad EN/ES, mismos marcadores de formato y claves usadas frente a definidas.

Condiciones que pasan o fallan (salida distinta de 0 si falla alguna):
  1. Toda clave tiene texto EN y ES, no vacío.
  2. Los marcadores de formato (%@, %lld, %1$@…) son los mismos en EN y ES.
  3. Toda clave literal usada en el código (AppStrings.text/format) existe en el catálogo.
Aviso (no falla): claves definidas que no aparecen literalmente; las dinámicas conocidas se excluyen.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Packages/AppleKit/Sources/AppStrings/Resources/Localizable.xcstrings"
SOURCES = ROOT / "Packages/AppleKit/Sources"
DYNAMIC_PREFIXES = ("tab.", "category.", "context.", "account.error.", "diagnostics.sim.", "venue.", "detail.analytics.")
PLACEHOLDER = re.compile(r"%(?:\d+\$)?[@dlfs]+")
USED = re.compile(r'AppStrings\.(?:text|format)\(\s*(?:[^"\n]*\?\s*)?"([^"\\]+)"(?:\s*:\s*"([^"\\]+)")?')


def main() -> int:
    strings = json.loads(CATALOG.read_text(encoding="utf-8"))["strings"]
    errors: list[str] = []
    for key, entry in strings.items():
        values = {}
        for lang in ("en", "es"):
            unit = entry.get("localizations", {}).get(lang, {}).get("stringUnit", {})
            value = unit.get("value", "")
            if not value.strip():
                errors.append(f"{key}: falta el texto {lang}")
            values[lang] = value
        if sorted(PLACEHOLDER.findall(values["en"])) != sorted(PLACEHOLDER.findall(values["es"])):
            errors.append(f"{key}: los marcadores de formato de EN y ES no coinciden")
    used: set[str] = set()
    for path in SOURCES.rglob("*.swift"):
        for match in USED.finditer(path.read_text(encoding="utf-8")):
            used.update(group for group in match.groups() if group)
    for key in sorted(used):
        if "\\(" not in key and key not in strings:
            errors.append(f"{key}: se usa en el código y no está en el catálogo")
    unused = [k for k in strings if k not in used and not k.startswith(DYNAMIC_PREFIXES)]
    for key in unused:
        print(f"aviso: {key} está definida y no se usa literalmente")
    for error in errors:
        print(f"ERROR: {error}")
    print(f"{len(strings)} claves, {len(used)} usadas literalmente, {len(errors)} errores")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
