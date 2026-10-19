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


TIMING = re.compile(r" after [0-9.]+ seconds")


def summarize(lines: list[str]) -> tuple[list[str], list[str]]:
    seen: set[str] = set()
    errors: list[str] = []
    failed_tests: list[str] = []
    for index, line in enumerate(lines):
        text = TIMING.sub("", line.strip())
        test = re.match(r"✘ Test (\S+) (?:recorded an issue|failed)", text)
        if test and test.group(1) not in failed_tests:
            failed_tests.append(test.group(1))
        if text and PATTERNS.search(text) and text not in seen:
            seen.add(text)
            errors.append(text[:MAX_LINE])
            if "error:" in text:
                # Contexto: el compilador pone el código y las notas justo debajo (y en macros es lo único útil).
                errors.extend(extra.strip()[:MAX_LINE] for extra in lines[index + 1 : index + 5] if extra.strip())
    # Resumen único de las pruebas que fallan: el límite de líneas no debe esconder ninguna.
    head = [f"PRUEBAS QUE FALLAN ({len(failed_tests)}): " + ", ".join(failed_tests)] if failed_tests else []
    return (head + errors)[:MAX_LINES], lines[-15:]


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
