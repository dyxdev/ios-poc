#!/usr/bin/env python3
"""Resume una captura de mitmproxy: hosts y número de peticiones, y el veredicto de ADR-IOS-0029.

Uso:
  mitmdump -nr captura-A.flows --flow-detail 1 | python3 tools/capture-hosts.py [--approve sufijo ...]

Condición que pasa o falla (la misma lógica que `NetworkEvidence` en Core): 0 peticiones a `*.litix.io` y ninguna a un
host fuera de los sufijos aprobados. Solo lee métodos y hosts de la salida de mitmdump: nunca guarda rutas ni cuerpos.
"""
import argparse
import collections
import re
import sys

FORBIDDEN = ("litix.io",)
DEFAULT_APPROVED = ("mux.com", "images.unsplash.com")
REQUEST = re.compile(r"\b(?:GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|CONNECT)\s+(?:https?://)?([A-Za-z0-9.-]+)(?::\d+)?", re.I)


def matches(host: str, suffixes) -> bool:
    return any(host == s or host.endswith("." + s) for s in suffixes)


def evaluate(text: str, approved):
    counts = collections.Counter(m.group(1).lower() for m in REQUEST.finditer(text))
    violations = {h: n for h, n in counts.items() if matches(h, FORBIDDEN) or not matches(h, approved)}
    return counts, violations


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--approve", nargs="*", default=[], help="sufijos aprobados además de los de siempre")
    args = parser.parse_args()
    approved = tuple(DEFAULT_APPROVED) + tuple(args.approve)
    counts, violations = evaluate(sys.stdin.read(), approved)
    for host, number in sorted(counts.items()):
        print(f"{'NO' if host in violations else 'ok'}  {host}  {number}")
    print(f"{sum(counts.values())} peticiones, {len(counts)} hosts, {len(violations)} no permitidos")
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main())
