#!/usr/bin/env python3
"""
scripts/audit-token-efficiency.py: Entrypoint wrapper para scripts/pipeline/audit-token-efficiency.py.
"""
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PIPELINE_SCRIPT = os.path.join(SCRIPT_DIR, "pipeline", "audit-token-efficiency.py")

if __name__ == "__main__":
    if not os.path.exists(PIPELINE_SCRIPT):
        print(f"Erro: Script core não encontrado em {PIPELINE_SCRIPT}", file=sys.stderr)
        sys.exit(1)
    with open(PIPELINE_SCRIPT, "r", encoding="utf-8") as f:
        code = compile(f.read(), PIPELINE_SCRIPT, "exec")
        exec(code, {"__name__": "__main__", "__file__": PIPELINE_SCRIPT})
