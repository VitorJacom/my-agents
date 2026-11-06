#!/usr/bin/env python3
"""
scripts/reclassify-epics-and-releases.py
Reclassifica Milestones como Épicos temáticos e preenche o campo 'Release' (v1.0.0, v1.1.0, v1.2.0, Backlog / Future) no Project #1.
"""

import json
import subprocess
import sys

REPO = "VitorJacom/my-agents"
OWNER = "VitorJacom"
PROJECT_NUM = "1"

EPICS = {
    "Epic: AIDD Core & Engineering Governance": {
        "description": "Pilares centrais do AIDD: Governança, Ciclo de Vida Efêmero, Duplo Gate, Cobertura 85% e Sandboxing.",
        "issues": {1, 2, 4, 10, 12, 19, 20, 21, 22, 35, 36, 44, 45, 46}
    },
    "Epic: Multi-Agent Parallel Pipeline & Worktrees": {
        "description": "Orquestração concorrente via Maestro, isolamento em Git Worktrees, waves e auto-reconciliação.",
        "issues": {8, 9, 11, 42, 48}
    },
    "Epic: UI/UX Design System & Living Mockups": {
        "description": "Skill executiva de UI/UX, Design System, Mockup-as-Code e validação visual determinística.",
        "issues": {6, 7, 13, 14, 15, 17, 31, 32, 33}
    },
    "Epic: Automated PR Review Skill": {
        "description": "Skill especializada de revisão estrita de Pull Requests, motor determinístico e comentários inline.",
        "issues": {51, 52, 53, 54}
    },
    "Epic: Wiki & Living Documentation": {
        "description": "Arquitetura e sincronização modular da GitHub Wiki, documentação canônica viva e guias de onboarding.",
        "issues": {24, 25, 26, 27, 57}
    },
    "Epic: Multi-Model Adversarial Pipeline & Metrics": {
        "description": "Integração bidirecional com múltiplos modelos, métricas de eficiência de tokens e telemetria resiliente.",
        "issues": {28, 29, 30, 49, 56}
    }
}

# Mapeamento de Releases
RELEASES = {
    "v1.0.0": {1, 2, 4, 8, 9, 12, 13, 14, 15, 19, 20, 21, 22, 35, 36, 42},
    "v1.1.0": {6, 7, 10, 11, 17, 31, 32, 33, 44, 45, 46, 48, 49, 51, 52, 53, 54, 56, 57},
    "v1.2.0": {24, 25, 26, 27, 28, 29, 30}
}

def run_cmd(args, check=True):
    res = subprocess.run(args, capture_output=True, text=True)
    if check and res.returncode != 0:
        print(f"Erro ao executar {' '.join(args)}: {res.stderr.strip()}", file=sys.stderr)
        sys.exit(res.returncode)
    return res.stdout.strip()

def main():
    print("=" * 70)
    print(" 🚀 Iniciando Reclassificação de Épicos (Milestones) e Releases no Project #1")
    print("=" * 70)

    # 1. Obter Milestones existentes
    milestones_raw = run_cmd(["gh", "api", f"repos/{REPO}/milestones?state=all"])
    existing_milestones = {m["title"]: m for m in json.loads(milestones_raw)}

    # 2. Criar ou validar os 6 Épicos
    print("\n[1/3] Garantindo existência dos 6 Épicos (Milestones)...")
    for epic_title, meta in EPICS.items():
        if epic_title not in existing_milestones:
            print(f"  ➕ Criando Épico: '{epic_title}'...")
            run_cmd([
                "gh", "api", f"repos/{REPO}/milestones", "-X", "POST",
                "-f", f"title={epic_title}",
                "-f", f"description={meta['description']}"
            ])
        else:
            print(f"  ✓ Épico '{epic_title}' já existe.")

    # 3. Mapear cada issue para seu Épico e Release
    issue_to_epic = {}
    for epic, meta in EPICS.items():
        for num in meta["issues"]:
            issue_to_epic[num] = epic

    issue_to_release = {}
    for rel, issues in RELEASES.items():
        for num in issues:
            issue_to_release[num] = rel

    # 4. Listar todas as issues
    print("\n[2/3] Coletando todas as issues do repositório...")
    issues_raw = run_cmd(["gh", "issue", "list", "--repo", REPO, "--state", "all", "--limit", "200", "--json", "number,title,state,milestone,url"])
    all_issues = json.loads(issues_raw)

    print(f"Total de issues: {len(all_issues)}")

    # 5. Aplicar Épico e Release
    print("\n[3/3] Aplicando Épico (Milestone) e Release no Project #1...")
    for it in sorted(all_issues, key=lambda x: x["number"]):
        num = it["number"]
        title = it["title"]
        url = it["url"]
        curr_m = (it.get("milestone") or {}).get("title")

        target_epic = issue_to_epic.get(num, "Epic: AIDD Core & Engineering Governance")
        target_release = issue_to_release.get(num, "v1.1.0")

        print(f"\n👉 Issue #{num}: {title[:50]}...")
        # 5.1 Atualizar Milestone (Épico)
        if curr_m != target_epic:
            print(f"  [Milestone -> Épico] '{curr_m}' => '{target_epic}'")
            run_cmd(["gh", "issue", "edit", str(num), "--repo", REPO, "--milestone", target_epic], check=False)
        else:
            print(f"  [Milestone -> Épico] OK ('{target_epic}')")

        # 5.2 Garantir presença no Project #1
        run_cmd(["gh", "project", "item-add", PROJECT_NUM, "--owner", OWNER, "--url", url], check=False)

        # 5.3 Atualizar campo Release no Project #1
        print(f"  [Project #1 Release] Definindo Release -> '{target_release}'")
        run_cmd([
            "gh", "project", "item-edit", PROJECT_NUM,
            "--owner", OWNER,
            "--url", url,
            "--field", "Release",
            "--value", target_release
        ], check=False)

    print("\n" + "=" * 70)
    print(" ✅ Reclassificação de Épicos e Releases concluída com sucesso!")
    print(f" Acesse o projeto: https://github.com/users/{OWNER}/projects/{PROJECT_NUM}")
    print("=" * 70)

if __name__ == "__main__":
    main()
