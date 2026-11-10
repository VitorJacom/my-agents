#!/usr/bin/env python3
"""
audit-token-efficiency.py: Analisador de telemetria e eficiência de tokens da esteira AIDD.
Inspeciona transcripts do Antigravity CLI, mapeia consumo por agente/fase e operações,
identifica hotspots e anomalias de cache, e calcula score determinístico (0-100).
"""

import sys
import os
import json
import argparse
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple

# Limiares e constantes de calibração
TOKEN_HOTSPOT_STEP_THRESHOLD = 50_000
TOKEN_STEP_ABSOLUTE_MAX = 100_000
REDUNDANT_READ_THRESHOLD = 2
CACHE_RATIO_EXCELLENT = 0.60
CACHE_RATIO_GOOD = 0.45
CACHE_RATIO_POOR = 0.30

# Mapeamento Canônico de Papéis para Fases AIDD
ROLE_TO_PHASE = {
    "product-owner": "Planning",
    "product owner": "Planning",
    "the elephant": "Planning",
    "system-architect": "Planning",
    "system architect": "Planning",
    "planner": "Planning",
    "planning": "Planning",
    "qa": "QA",
    "qa-engineer": "QA",
    "qa engineer": "QA",
    "coder": "Coding",
    "developer": "Coding",
    "gatekeeper": "Gatekeeper",
    "the goldfish": "Gatekeeper",
}

def map_role_to_phase(role: str) -> str:
    cleaned = role.strip().lower()
    if cleaned in ROLE_TO_PHASE:
        return ROLE_TO_PHASE[cleaned]
    for key, phase in ROLE_TO_PHASE.items():
        if key in cleaned:
            return phase
    return "Execution"

def parse_transcript_lines(lines: List[str]) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    steps: List[Dict[str, Any]] = []
    file_reads: List[str] = []
    tool_counts: Dict[str, int] = {}
    tool_tokens: Dict[str, Dict[str, int]] = {}

    total_in = 0
    total_out = 0
    total_cache = 0
    timestamps: List[datetime] = []

    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
        except Exception:
            continue

        in_tok = data.get("input_tokens", 0)
        out_tok = data.get("output_tokens", 0)
        cache_tok = data.get("cache_read_tokens", 0)

        total_in += in_tok
        total_out += out_tok
        total_cache += cache_tok

        if "created_at" in data:
            try:
                ts_str = data["created_at"].replace("Z", "+00:00")
                timestamps.append(datetime.fromisoformat(ts_str))
            except Exception:
                pass

        step_tools = []
        raw_tools = data.get("tool_calls", [])
        if isinstance(raw_tools, list):
            for tc in raw_tools:
                if not isinstance(tc, dict):
                    continue
                name = tc.get("name") or tc.get("function", {}).get("name") or "unknown"
                step_tools.append(name)
                tool_counts[name] = tool_counts.get(name, 0) + 1

                if name not in tool_tokens:
                    tool_tokens[name] = {"calls": 0, "input": 0, "output": 0, "cache": 0, "total": 0}
                tool_tokens[name]["calls"] += 1
                tool_tokens[name]["input"] += in_tok
                tool_tokens[name]["output"] += out_tok
                tool_tokens[name]["cache"] += cache_tok
                tool_tokens[name]["total"] += (in_tok + out_tok)

                args = tc.get("args") or tc.get("arguments") or {}
                if isinstance(args, str):
                    try:
                        args = json.loads(args)
                    except Exception:
                        args = {}
                if isinstance(args, dict):
                    path = args.get("Path") or args.get("path") or args.get("file")
                    if path and isinstance(path, str):
                        clean_path = path.strip('\'"')
                        if name in ("read_file", "view_file"):
                            file_reads.append(clean_path)

        steps.append({
            "step_index": data.get("step_index", len(steps)),
            "type": data.get("type", "UNKNOWN"),
            "input_tokens": in_tok,
            "output_tokens": out_tok,
            "cache_read_tokens": cache_tok,
            "total_tokens": in_tok + out_tok,
            "tool_calls": step_tools,
        })

    duration = 0.0
    if len(timestamps) > 1:
        duration = (timestamps[-1] - timestamps[0]).total_seconds()

    summary = {
        "input_tokens": total_in,
        "output_tokens": total_out,
        "cache_tokens": total_cache,
        "total_tokens": total_in + total_out,
        "duration_seconds": duration,
        "file_reads": file_reads,
        "tool_counts": tool_counts,
        "tool_tokens": tool_tokens,
        "steps_count": len(steps),
    }

    return steps, summary

def parse_transcript_file(path: str) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    if not os.path.exists(path):
        raise FileNotFoundError(f"Arquivo de transcript não encontrado: {path}")
    if os.path.getsize(path) == 0:
        raise ValueError(f"Arquivo de transcript está vazio: {path}")

    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    steps, summary = parse_transcript_lines(lines)
    if not steps or summary["steps_count"] == 0:
        raise ValueError(f"Nenhum evento ou step válido encontrado no transcript: {path}")
    return steps, summary

def calculate_score_and_diagnostics(
    agents_data: List[Dict[str, Any]],
    totals: Dict[str, Any],
    combined_tools: Dict[str, Any],
    all_file_reads: List[str],
    all_steps: List[Dict[str, Any]]
) -> Dict[str, Any]:
    score = 100
    deductions: List[Dict[str, Any]] = []
    hotspots: List[Dict[str, Any]] = []
    cache_anomalies: List[Dict[str, Any]] = []
    successes: List[str] = []
    issues: List[str] = []
    recommendations: List[str] = []

    tot_in = totals["input_tokens"]
    tot_out = totals["output_tokens"]
    tot_cache = totals["cache_tokens"]
    tot_all = tot_in + tot_out

    # 1. Avaliação de Cache
    denom = tot_in + tot_cache
    cache_ratio = (tot_cache / denom) if denom > 0 else 0.0
    totals["cache_ratio"] = round(cache_ratio, 4)
    totals["cache_percent"] = round(cache_ratio * 100, 1)

    if cache_ratio >= CACHE_RATIO_EXCELLENT:
        successes.append(f"Excelente taxa de reaproveitamento de cache: {totals['cache_percent']}%")
    elif cache_ratio >= CACHE_RATIO_GOOD:
        successes.append(f"Boa taxa de reaproveitamento de cache: {totals['cache_percent']}%")
        score -= 5
        deductions.append({"reason": "Taxa de cache abaixo do ideal (>= 60%)", "points": -5})
    elif cache_ratio >= CACHE_RATIO_POOR:
        issues.append(f"Taxa de cache moderada/baixa: {totals['cache_percent']}%")
        penalty = min(20, int((CACHE_RATIO_EXCELLENT - cache_ratio) * 50))
        score -= penalty
        deductions.append({"reason": f"Cache moderado ({totals['cache_percent']}%)", "points": -penalty})
        cache_anomalies.append({
            "type": "LOW_CACHE_RATIO",
            "ratio": cache_ratio,
            "description": f"Taxa de cache de {totals['cache_percent']}% inferior ao recomendado (>= 50%)"
        })
    else:
        issues.append(f"Anomalia crítica de cache miss: taxa de apenas {totals['cache_percent']}%")
        penalty = 30
        score -= penalty
        deductions.append({"reason": f"Cache miss severo ({totals['cache_percent']}%)", "points": -penalty})
        cache_anomalies.append({
            "type": "CRITICAL_CACHE_MISS",
            "ratio": cache_ratio,
            "description": f"Taxa de cache extremamente baixa ({totals['cache_percent']}%); alta incidência de cache miss"
        })
        recommendations.append("Estabilizar prefixos de prompt e regras invariantes para maximizar o cache de contexto")

    # Quedas bruscas de cache entre etapas
    last_cache = 0
    for s in all_steps:
        s_cache = s.get("cache_read_tokens", 0)
        s_in = s.get("input_tokens", 0)
        if last_cache > 15_000 and s_cache < 2_000 and s_in > 15_000:
            cache_anomalies.append({
                "type": "SUDDEN_CACHE_DROP",
                "step_index": s.get("step_index"),
                "description": f"Queda brusca de cache no step {s.get('step_index')}: {last_cache:,} -> {s_cache:,}"
            })
            if score > 15:
                score -= 5
                deductions.append({"reason": f"Queda brusca de cache no step {s.get('step_index')}", "points": -5})
        last_cache = s_cache

    # 2. Hotspots de Consumo de Tokens por Step
    heavy_steps = [s for s in all_steps if s.get("input_tokens", 0) >= TOKEN_HOTSPOT_STEP_THRESHOLD]
    if heavy_steps:
        step_penalty = min(25, len(heavy_steps) * 8)
        score -= step_penalty
        deductions.append({"reason": f"{len(heavy_steps)} step(s) com consumo excessivo (>= 50k tokens)", "points": -step_penalty})
        for s in heavy_steps:
            hotspots.append({
                "type": "STEP_TOKEN_SPIKE",
                "step_index": s.get("step_index"),
                "input_tokens": s.get("input_tokens"),
                "tools": s.get("tool_calls", []),
                "description": f"Step {s.get('step_index')} consumiu {s.get('input_tokens'):,} tokens de entrada"
            })
        issues.append(f"{len(heavy_steps)} etapa(s) ultrapassaram o limiar de 50.000 tokens de entrada")
        recommendations.append("Adotar leitura de arquivos delimitada por StartLine/EndLine e busca cirúrgica para evitar sobrecarga de contexto")
    else:
        successes.append("Nenhuma etapa individual com explosão de tokens (todas < 50k)")

    # 3. Operações Redundantes de Ferramentas (ex: leituras repetidas do mesmo arquivo)
    read_counts: Dict[str, int] = {}
    for path in all_file_reads:
        read_counts[path] = read_counts.get(path, 0) + 1

    redundant_reads = {p: c for p, c in read_counts.items() if c > REDUNDANT_READ_THRESHOLD}
    if redundant_reads:
        red_penalty = min(15, len(redundant_reads) * 4)
        score -= red_penalty
        deductions.append({"reason": f"{len(redundant_reads)} arquivo(s) lidos repetidamente sem necessidade", "points": -red_penalty})
        for p, c in redundant_reads.items():
            hotspots.append({
                "type": "REDUNDANT_FILE_READ",
                "path": p,
                "read_count": c,
                "description": f"Arquivo '{p}' foi lido {c} vezes"
            })
            issues.append(f"Arquivo '{p}' lido repetidamente ({c} vezes)")
        recommendations.append("Evitar releituras redundantes do mesmo arquivo; isolar pesquisas em subagente de pesquisa (research)")
    else:
        if all_file_reads:
            successes.append("Operações de leitura sem duplicidades excessivas")

    # 4. Concentração Excessiva de Tokens por Agente (se multi-agente >= 2)
    if len(agents_data) >= 2 and tot_all > 0:
        for ag in agents_data:
            ag_tot = ag["summary"]["total_tokens"]
            ag_ratio = ag_tot / tot_all
            if ag_ratio > 0.65:
                penalty = 10
                score -= penalty
                deductions.append({"reason": f"Agente '{ag['role']}' concentrou {ag_ratio*100:.1f}% de todos os tokens", "points": -penalty})
                hotspots.append({
                    "type": "AGENT_TOKEN_IMBALANCE",
                    "role": ag["role"],
                    "ratio": ag_ratio,
                    "description": f"Agente '{ag['role']}' absorveu {ag_ratio*100:.1f}% do consumo total da esteira"
                })
                issues.append(f"Agente '{ag['role']}' concentrou {ag_ratio*100:.1f}% dos tokens da esteira")
                recommendations.append(f"Fatiar responsabilidades do agente '{ag['role']}' em sub-etapas atômicas conforme AIDD Seção 7")

    score = max(0, min(100, score))

    # Determinação da Classe/Rating
    if score >= 90:
        rating = "Classe A (Excelente)"
    elif score >= 75:
        rating = "Classe B (Bom)"
    elif score >= 50:
        rating = "Classe C (Regular)"
    else:
        rating = "Classe D/F (Crítico)"

    if not recommendations:
        recommendations.append("Manter padrões canônicos de Zero Token Waste e leitura cirúrgica delimitada")

    return {
        "score": score,
        "rating": rating,
        "deductions": deductions,
        "hotspots": hotspots,
        "cache_anomalies": cache_anomalies,
        "diagnostics": {
            "successes": successes,
            "issues": issues
        },
        "recommendations": recommendations
    }

def format_duration(seconds: float) -> str:
    if seconds >= 60:
        mins = int(seconds // 60)
        secs = seconds % 60
        return f"{mins}m {secs:.1f}s"
    return f"{seconds:.1f}s"

def audit_pipeline(
    transcripts_map: Dict[str, str],
    issue_num: Optional[str] = None
) -> Dict[str, Any]:
    agents_data: List[Dict[str, Any]] = []
    phases_map: Dict[str, Dict[str, Any]] = {}
    combined_tools: Dict[str, Dict[str, int]] = {}
    all_file_reads: List[str] = []
    all_steps: List[Dict[str, Any]] = []

    tot_in = 0
    tot_out = 0
    tot_cache = 0
    tot_time = 0.0

    for role, path in transcripts_map.items():
        steps, summary = parse_transcript_file(path)
        phase = map_role_to_phase(role)

        agents_data.append({
            "role": role,
            "phase": phase,
            "path": path,
            "summary": summary,
            "steps": steps
        })

        all_steps.extend(steps)
        all_file_reads.extend(summary["file_reads"])

        tot_in += summary["input_tokens"]
        tot_out += summary["output_tokens"]
        tot_cache += summary["cache_tokens"]
        tot_time += summary["duration_seconds"]

        # Consolidação por fase
        if phase not in phases_map:
            phases_map[phase] = {
                "input_tokens": 0,
                "output_tokens": 0,
                "cache_tokens": 0,
                "total_tokens": 0,
                "duration_seconds": 0.0,
                "agents": []
            }
        phases_map[phase]["input_tokens"] += summary["input_tokens"]
        phases_map[phase]["output_tokens"] += summary["output_tokens"]
        phases_map[phase]["cache_tokens"] += summary["cache_tokens"]
        phases_map[phase]["total_tokens"] += summary["total_tokens"]
        phases_map[phase]["duration_seconds"] += summary["duration_seconds"]
        phases_map[phase]["agents"].append(role)

        # Consolidação por ferramenta
        for tool_name, t_stat in summary["tool_tokens"].items():
            if tool_name not in combined_tools:
                combined_tools[tool_name] = {"calls": 0, "input": 0, "output": 0, "cache": 0, "total": 0}
            combined_tools[tool_name]["calls"] += t_stat["calls"]
            combined_tools[tool_name]["input"] += t_stat["input"]
            combined_tools[tool_name]["output"] += t_stat["output"]
            combined_tools[tool_name]["cache"] += t_stat["cache"]
            combined_tools[tool_name]["total"] += t_stat["total"]

    totals = {
        "input_tokens": tot_in,
        "output_tokens": tot_out,
        "cache_tokens": tot_cache,
        "total_tokens": tot_in + tot_out,
        "duration_seconds": tot_time,
        "agents_count": len(agents_data),
        "steps_count": len(all_steps)
    }

    eval_result = calculate_score_and_diagnostics(
        agents_data, totals, combined_tools, all_file_reads, all_steps
    )

    return {
        "issue_num": issue_num,
        "score": eval_result["score"],
        "rating": eval_result["rating"],
        "totals": totals,
        "phases": phases_map,
        "agents": [
            {
                "role": a["role"],
                "phase": a["phase"],
                "input_tokens": a["summary"]["input_tokens"],
                "output_tokens": a["summary"]["output_tokens"],
                "cache_tokens": a["summary"]["cache_tokens"],
                "total_tokens": a["summary"]["total_tokens"],
                "duration_seconds": a["summary"]["duration_seconds"]
            }
            for a in agents_data
        ],
        "tools": combined_tools,
        "hotspots": eval_result["hotspots"],
        "cache_anomalies": eval_result["cache_anomalies"],
        "diagnostics": eval_result["diagnostics"],
        "recommendations": eval_result["recommendations"],
        "deductions": eval_result["deductions"]
    }

def render_terminal(data: Dict[str, Any]) -> str:
    C_RESET = "\033[0m"
    C_BOLD = "\033[1m"
    C_GREEN = "\033[32m"
    C_YELLOW = "\033[33m"
    C_RED = "\033[31m"
    C_CYAN = "\033[36m"
    C_GRAY = "\033[90m"

    score = data["score"]
    color = C_GREEN if score >= 85 else (C_YELLOW if score >= 60 else C_RED)

    out = []
    out.append(f"{C_BOLD}{'=' * 82}{C_RESET}")
    issue_hdr = f" - ISSUE #{data['issue_num']}" if data.get("issue_num") else ""
    out.append(f"{C_BOLD} 📊 AUDITORIA DE EFICIÊNCIA DE TOKENS & TELEMETRIA{issue_hdr}{C_RESET}")
    out.append(f"{C_BOLD}{'=' * 82}{C_RESET}")

    out.append(f" {C_BOLD}Score Geral de Eficiência:{C_RESET} {color}{C_BOLD}{score}/100{C_RESET} [{data['rating']}]")
    t = data["totals"]
    cache_pct = t.get("cache_percent", 0.0)
    dur_str = format_duration(t["duration_seconds"])
    out.append(f" {C_GRAY}Tokens Totais: {t['total_tokens']:,} (In: {t['input_tokens']:,} | Out: {t['output_tokens']:,} | Cache: {t['cache_tokens']:,} - {cache_pct}%) | Tempo: {dur_str}{C_RESET}")
    out.append(f"{'─' * 82}")

    # Fases
    if data.get("phases"):
        out.append(f"\n{C_BOLD}📌 CONSUMO POR FASE DA ESTEIRA:{C_RESET}")
        out.append(f"{'Fase':<16} │ {'Duração':<10} │ {'Input':<12} │ {'Output':<10} │ {'Cache':<10} │ {'Total':<12}")
        out.append("─" * 17 + "┼" + "─" * 12 + "┼" + "─" * 14 + "┼" + "─" * 12 + "┼" + "─" * 12 + "┼" + "─" * 14)
        for phase_name, p_data in data["phases"].items():
            dur = format_duration(p_data["duration_seconds"])
            out.append(f"{phase_name:<16} │ {dur:<10} │ {p_data['input_tokens']:>12,} │ {p_data['output_tokens']:>10,} │ {p_data['cache_tokens']:>10,} │ {p_data['total_tokens']:>12,}")

    # Ferramentas
    if data.get("tools"):
        out.append(f"\n{C_BOLD}🛠️  CONSUMO POR OPERAÇÃO DE FERRAMENTA (TOOL CALLS):{C_RESET}")
        out.append(f"{'Operação / Tool':<22} │ {'Chamadas':<10} │ {'Input Tokens':<14} │ {'Cache Read':<12} │ {'Total Tokens':<14}")
        out.append("─" * 23 + "┼" + "─" * 12 + "┼" + "─" * 16 + "┼" + "─" * 14 + "┼" + "─" * 16)
        for t_name, t_info in sorted(data["tools"].items(), key=lambda x: x[1]["total"], reverse=True):
            out.append(f"{t_name:<22} │ {t_info['calls']:>10} │ {t_info['input']:>14,} │ {t_info['cache']:>12,} │ {t_info['total']:>14,}")

    # Diagnóstico (Acertos e Erros)
    diag = data.get("diagnostics", {})
    if diag.get("successes"):
        out.append(f"\n{C_GREEN}{C_BOLD}✅ PONTOS FORTES / ACERTOS IDENTIFICADOS:{C_RESET}")
        for s in diag["successes"]:
            out.append(f"  {C_GREEN}✔{C_RESET} {s}")

    if diag.get("issues"):
        out.append(f"\n{C_RED}{C_BOLD}⚠️  ANOMALIAS E OPORTUNIDADES DE MELHORIA:{C_RESET}")
        for i in diag["issues"]:
            out.append(f"  {C_RED}✖{C_RESET} {i}")

    # Recomendações
    if data.get("recommendations"):
        out.append(f"\n{C_CYAN}{C_BOLD}💡 RECOMENDAÇÕES ACIONÁVEIS DE OTIMIZAÇÃO:{C_RESET}")
        for r in data["recommendations"]:
            out.append(f"  {C_CYAN}➜{C_RESET} {r}")

    out.append(f"\n{C_BOLD}{'=' * 82}{C_RESET}")
    return "\n".join(out)

def render_markdown(data: Dict[str, Any]) -> str:
    md = []
    issue_hdr = f" - Issue #{data['issue_num']}" if data.get("issue_num") else ""
    score = data["score"]
    badge_color = "brightgreen" if score >= 85 else ("yellow" if score >= 60 else "red")

    md.append(f"## 📊 Auditoria de Eficiência de Tokens e Telemetria{issue_hdr}\n")
    md.append(f"**Score de Eficiência:** `{score}/100` ({data['rating']})\n")

    t = data["totals"]
    cache_pct = t.get("cache_percent", 0.0)
    dur_str = format_duration(t["duration_seconds"])

    md.append("### 📈 Resumo Geral da Esteira\n")
    md.append(f"- **Tokens Totais:** {t['total_tokens']:,} (Input: {t['input_tokens']:,} | Output: {t['output_tokens']:,})")
    md.append(f"- **Prompt Cache Read:** {t['cache_tokens']:,} ({cache_pct}%)")
    md.append(f"- **Tempo Total de Execução:** {dur_str}")
    md.append(f"- **Etapas Analisadas:** {t['steps_count']}\n")

    if data.get("phases"):
        md.append("### 🏛️ Consumo por Fase da Esteira (AIDD)\n")
        md.append("| Fase | Duração | Input Tokens | Output Tokens | Cache Read | Total Tokens |")
        md.append("| :--- | :---: | :---: | :---: | :---: | :---: |")
        for p_name, p_val in data["phases"].items():
            dur = format_duration(p_val["duration_seconds"])
            md.append(f"| **{p_name}** | {dur} | {p_val['input_tokens']:,} | {p_val['output_tokens']:,} | {p_val['cache_tokens']:,} | {p_val['total_tokens']:,} |")
        md.append("")

    if data.get("tools"):
        md.append("### 🛠️ Consumo por Operação de Ferramenta (Tool Calls)\n")
        md.append("| Tool / Operação | Chamadas | Input Tokens | Cache Read | Total Tokens |")
        md.append("| :--- | :---: | :---: | :---: | :---: |")
        for t_name, t_val in sorted(data["tools"].items(), key=lambda x: x[1]["total"], reverse=True):
            md.append(f"| `{t_name}` | {t_val['calls']} | {t_val['input']:,} | {t_val['cache']:,} | {t_val['total']:,} |")
        md.append("")

    diag = data.get("diagnostics", {})
    if diag.get("successes"):
        md.append("### ✅ Diagnóstico de Pontos Fortes\n")
        for s in diag["successes"]:
            md.append(f"- [x] {s}")
        md.append("")

    if diag.get("issues"):
        md.append("> [!WARNING]\n> **Anomalias e Hotspots Detectados:**")
        for i in diag["issues"]:
            md.append(f"> - {i}")
        md.append("")

    if data.get("recommendations"):
        md.append("### 💡 Recomendações Acionáveis\n")
        for r in data["recommendations"]:
            md.append(f"1. {r}")
        md.append("")

    return "\n".join(md)

def main():
    parser = argparse.ArgumentParser(
        description="audit-token-efficiency.py: Analisa telemetria, consumo de tokens e hotspots da esteira AIDD"
    )
    parser.add_argument("--transcript", "-t", help="Caminho direto para arquivo transcript.jsonl")
    parser.add_argument("--file", "-f", "--input", dest="transcript_file", help="Alias para caminho do transcript")
    parser.add_argument("--agents", "-a", help="Mapeamento JSON de agentes: '{\"Planner\": \"cid1\", \"QA\": \"cid2\"}'")
    parser.add_argument("--brain-dir", default=os.path.expanduser("~/.gemini/antigravity-cli/brain"), help="Diretório base do brain")
    parser.add_argument("--stdin", action="store_true", help="Lê transcript JSONL diretamente da entrada padrão (stdin)")
    parser.add_argument("--issue", "-i", default=None, help="Número da issue em execução")
    parser.add_argument("--json", action="store_true", help="Emite resultado em JSON estruturado")
    parser.add_argument("--markdown", "-m", action="store_true", help="Emite resultado em formato Markdown")
    parser.add_argument("--min-score", type=int, default=None, help="Limiar mínimo de score (0-100); sai com exit 1 se score < limiar")

    args = parser.parse_args()

    transcripts_map: Dict[str, str] = {}
    temp_stdin_file = None

    try:
        if args.stdin:
            import tempfile
            temp_fd, temp_stdin_file = tempfile.mkstemp(prefix="audit_stdin_", suffix=".jsonl")
            with open(temp_fd, "w", encoding="utf-8") as f:
                stdin_data = sys.stdin.read()
                if not stdin_data.strip():
                    print("Erro: Entrada stdin vazia ou sem linhas de transcript.", file=sys.stderr)
                    sys.exit(1)
                f.write(stdin_data)
            transcripts_map["Session"] = temp_stdin_file

        elif args.transcript or args.transcript_file:
            path = args.transcript or args.transcript_file
            transcripts_map["Direct"] = path

        elif args.agents:
            try:
                agents_dict = json.loads(args.agents)
                if not isinstance(agents_dict, dict):
                    raise ValueError("JSON deve ser um objeto/dicionário chave-valor.")
            except Exception as e:
                print(f"Erro ao parsear JSON de --agents: {e}", file=sys.stderr)
                sys.exit(1)

            brain_base = os.path.expanduser(args.brain_dir)
            if not os.path.exists(brain_base):
                print(f"Erro: brain-dir não encontrado: {brain_base}", file=sys.stderr)
                sys.exit(1)

            for role, cid in agents_dict.items():
                p = os.path.join(brain_base, cid, ".system_generated", "logs", "transcript.jsonl")
                transcripts_map[role] = p
        else:
            print("Erro: É necessário fornecer --transcript, --agents ou --stdin.", file=sys.stderr)
            parser.print_usage(file=sys.stderr)
            sys.exit(1)

        result = audit_pipeline(transcripts_map, args.issue)

        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        elif args.markdown:
            print(render_markdown(result))
        else:
            print(render_terminal(result))

        if args.min_score is not None:
            if result["score"] < args.min_score:
                print(
                    f"\n[FAIL-FAST] Score de eficiência ({result['score']}) inferior ao mínimo exigido ({args.min_score})!",
                    file=sys.stderr
                )
                sys.exit(1)

        sys.exit(0)

    except FileNotFoundError as e:
        print(f"Erro: {e}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Erro: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Erro inesperado durante a auditoria: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if temp_stdin_file and os.path.exists(temp_stdin_file):
            try:
                os.remove(temp_stdin_file)
            except Exception:
                pass

if __name__ == "__main__":
    main()
