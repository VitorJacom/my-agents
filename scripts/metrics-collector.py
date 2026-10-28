#!/usr/bin/env python3
"""
metrics-collector.py: Extrai e consolida métricas de telemetria (tokens, tempo, estimativa de cota)
dos subagentes da esteira a partir dos transcripts do Antigravity CLI.
"""

import sys
import os
import json
import argparse
from datetime import datetime

# Constantes de calibração inicial da cota (podem ser ajustadas conforme validações com /usage)
# Janela média típica de 5 horas: ~1.500.000 tokens (estimativa base para calibração inicial)
DEFAULT_QUOTA_5H_TOKENS = 1_500_000
# Janela média semanal: ~10.000.000 tokens
DEFAULT_QUOTA_WEEKLY_TOKENS = 10_000_000

def parse_transcript(transcript_path):
    if not os.path.exists(transcript_path):
        return None

    in_tokens = 0
    out_tokens = 0
    cache_tokens = 0
    timestamps = []

    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                data = json.loads(line)
                if "created_at" in data:
                    ts_str = data["created_at"].replace("Z", "+00:00")
                    timestamps.append(datetime.fromisoformat(ts_str))
                in_tokens += data.get("input_tokens", 0)
                out_tokens += data.get("output_tokens", 0)
                cache_tokens += data.get("cache_read_tokens", 0)
            except Exception:
                continue

    duration = 0.0
    if len(timestamps) > 1:
        duration = (timestamps[-1] - timestamps[0]).total_seconds()

    return {
        "input_tokens": in_tokens,
        "output_tokens": out_tokens,
        "cache_tokens": cache_tokens,
        "total_tokens": in_tokens + out_tokens,
        "duration_seconds": duration
    }

def format_duration(seconds):
    if seconds >= 60:
        mins = int(seconds // 60)
        secs = seconds % 60
        return f"{mins}m {secs:.1f}s"
    return f"{seconds:.1f}s"

def collect_metrics(agents_dict, issue_num=None):
    results = []
    tot_in = 0
    tot_out = 0
    tot_cache = 0
    tot_tokens = 0
    tot_time = 0.0

    app_data = os.path.expanduser("~/.gemini/antigravity-cli/brain")

    for role, cid in agents_dict.items():
        path = os.path.join(app_data, cid, ".system_generated", "logs", "transcript.jsonl")
        metrics = parse_transcript(path)
        if metrics:
            results.append((role, metrics))
            tot_in += metrics["input_tokens"]
            tot_out += metrics["output_tokens"]
            tot_cache += metrics["cache_tokens"]
            tot_tokens += metrics["total_tokens"]
            tot_time += metrics["duration_seconds"]

    # Cálculo estimado de impacto na cota (/usage)
    pct_5h = (tot_tokens / DEFAULT_QUOTA_5H_TOKENS) * 100
    pct_weekly = (tot_tokens / DEFAULT_QUOTA_WEEKLY_TOKENS) * 100

    return {
        "agents": results,
        "totals": {
            "input_tokens": tot_in,
            "output_tokens": tot_out,
            "cache_tokens": tot_cache,
            "total_tokens": tot_tokens,
            "duration_seconds": tot_time
        },
        "quota_impact": {
            "pct_5h": pct_5h,
            "pct_weekly": pct_weekly
        },
        "issue_num": issue_num
    }

def render_terminal(data):
    issue_header = f" (ISSUE #{data['issue_num']})" if data['issue_num'] else ""
    out = []
    out.append("=" * 82)
    out.append(f" 📊 RELATÓRIO DE TELEMETRIA & IMPACTO DE COTA (/usage){issue_header}")
    out.append("=" * 82)
    out.append(f"{'Agente':<16} │ {'Tempo':<10} │ {'Input':<12} │ {'Output':<10} │ {'Cache':<9} │ {'Total Tokens':<12}")
    out.append("─" * 17 + "┼" + "─" * 12 + "┼" + "─" * 14 + "┼" + "─" * 12 + "┼" + "─" * 11 + "┼" + "─" * 14)

    for role, m in data["agents"]:
        dur = format_duration(m["duration_seconds"])
        out.append(f"{role:<16} │ {dur:<10} │ {m['input_tokens']:>12,} │ {m['output_tokens']:>10,} │ {m['cache_tokens']:>9,} │ {m['total_tokens']:>12,}")

    t = data["totals"]
    dur_total = format_duration(t["duration_seconds"])
    out.append("─" * 17 + "┼" + "─" * 12 + "┼" + "─" * 14 + "┼" + "─" * 12 + "┼" + "─" * 11 + "┼" + "─" * 14)
    out.append(f"{'TOTAL ESTEIRA':<16} │ {dur_total:<10} │ {t['input_tokens']:>12,} │ {t['output_tokens']:>10,} │ {t['cache_tokens']:>9,} │ {t['total_tokens']:>12,}")
    out.append("=" * 82)
    
    q = data["quota_impact"]
    out.append("💡 Impacto Estimado de Cota (Calibração inicial baseada em gasto de tokens):")
    out.append(f"   • Consumo na janela de 5 horas: ~{q['pct_5h']:.1f}% da cota")
    out.append(f"   • Consumo na janela semanal:    ~{q['pct_weekly']:.2f}% da cota")
    out.append("   • Para conferir o status oficial das suas cotas ao vivo, digite '/usage'.")
    out.append("=" * 82)
    return "\n".join(out)

def render_markdown(data):
    issue_header = f" - Issue #{data['issue_num']}" if data['issue_num'] else ""
    md = []
    md.append(f"### 📊 Telemetria de Execução dos Agentes{issue_header}\n")
    md.append("| Agente | Duração | Input Tokens | Output Tokens | Cache Read | Total Tokens |")
    md.append("| :--- | :---: | :---: | :---: | :---: | :---: |")
    for role, m in data["agents"]:
        dur = format_duration(m["duration_seconds"])
        md.append(f"| **{role}** | {dur} | {m['input_tokens']:,} | {m['output_tokens']:,} | {m['cache_tokens']:,} | {m['total_tokens']:,} |")

    t = data["totals"]
    dur_total = format_duration(t["duration_seconds"])
    md.append(f"| **TOTAL** | **{dur_total}** | **{t['input_tokens']:,}** | **{t['output_tokens']:,}** | **{t['cache_tokens']:,}** | **{t['total_tokens']:,}** |\n")
    
    q = data["quota_impact"]
    md.append("> **Impacto Estimado na Cota do Plano:**")
    md.append(f"> - Janela de 5 horas: ~`{q['pct_5h']:.1f}%` consumido")
    md.append(f"> - Janela Semanal: ~`{q['pct_weekly']:.2f}%` consumido")
    md.append(">\n> *Observação: Estimativa de cota inicial baseada em volume de tokens, calibrável via comando `/usage`.*")
    return "\n".join(md)

def main():
    parser = argparse.ArgumentParser(description="Coletor de telemetria e métricas de subagentes")
    parser.add_argument("--agents", required=True, help="JSON string no formato '{\"Planner\": \"cid\", \"QA\": \"cid\", ...}'")
    parser.add_argument("--issue", default=None, help="Número da issue")
    parser.add_argument("--markdown", action="store_true", help="Gera saída em Markdown")

    args = parser.parse_args()
    try:
        agents_map = json.loads(args.agents)
    except Exception as e:
        print(f"Erro ao parsear --agents JSON: {e}", file=sys.stderr)
        sys.exit(1)

    data = collect_metrics(agents_map, args.issue)
    if args.markdown:
        print(render_markdown(data))
    else:
        print(render_terminal(data))

if __name__ == "__main__":
    main()
