#!/usr/bin/env python3
"""Convierte los errores de un log de compilación o de pruebas en anotaciones de GitHub Actions.

Uso (en un paso `if: failure()`):  python3 tools/ci-summary.py <log> "<título>"
Los logs de Actions exigen autenticación para descargarse, pero las anotaciones de un run son públicas en un repo público:
así quien revisa puede leer los errores por la API sin que nadie copie el log. Solo emite líneas de error ya presentes en
el log (compilador, SwiftPM, Swift Testing, XCTest) y la cola del log; no añade nada ni guarda secretos.
"""
import pathlib
import re
import sys

PATTERNS = re.compile(
    r"error:|fatal error|✘|recorded an issue|Expectation failed|\*\* (TEST|BUILD) FAILED|Test Case .* failed|"
    r"Compilation failed|Testing failed|Command .* failed|warning: unable to|Could not resolve|No such module",
    re.I,
)
MAX_LINES = 45
MAX_LINE = 420


def escape(text: str) -> str:
    return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def summarize(lines: list[str]) -> tuple[list[str], list[str]]:
    seen: set[str] = set()
    errors: list[str] = []
    for line in lines:
        text = line.strip()
        if text and PATTERNS.search(text) and text not in seen:
            seen.add(text)
            errors.append(text[:MAX_LINE])
    return errors[:MAX_LINES], lines[-15:]


def main() -> int:
    path = pathlib.Path(sys.argv[1])
    title = sys.argv[2] if len(sys.argv) > 2 else "Errores"
    if not path.exists():
        print(f"::error title={escape(title)}::No existe el log {path}")
        return 0
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    errors, tail = summarize(lines)
    body = "\n".join(errors) if errors else "(ninguna línea de error reconocida: mira la cola del log)"
    print(f"::error title={escape(title)} (errores)::{escape(body)}")
    print(f"::notice title={escape(title)} (cola del log)::{escape(chr(10).join(t[:MAX_LINE] for t in tail))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
