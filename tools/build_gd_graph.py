#!/usr/bin/env python3
"""Gerador de Grafo de Símbolos GDScript e Cenas para Godot 4 (Grass Cut Bot).

Gera `docs/05_arquitetura_e_desenvolvimento/MAPA_DE_SIMBOLOS.md` com o índice
estrutural de todos os scripts `.gd` em `scripts/` e cenas `.tscn` em `scenes/`,
permitindo localizar classes, sinais, constantes, funções (com intervalo de linhas)
e vínculos de cenas sem leituras amplas de arquivos.

Uso:
    python tools/build_gd_graph.py
    python tools/build_gd_graph.py --query cut_in_circle
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass, field
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = ROOT_DIR / "scripts"
SCENES_DIR = ROOT_DIR / "scenes"
OUTPUT_FILE = ROOT_DIR / "docs" / "05_arquitetura_e_desenvolvimento" / "MAPA_DE_SIMBOLOS.md"

RE_CLASS_NAME = re.compile(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)")
RE_EXTENDS = re.compile(r"^extends\s+([A-Za-z_][A-Za-z0-9_.\"\/:]*)")
RE_SIGNAL = re.compile(r"^signal\s+([A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?)")
RE_CONST = re.compile(r"^const\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::[^=]+)?=")
RE_FUNC = re.compile(r"^((?:static\s+)?func\s+[A-Za-z_][A-Za-z0-9_]*\s*\([^)]*\)(?:\s*->\s*[^:]+)?)")
RE_TOP_DECL = re.compile(
    r"^(?:@|class_name\b|extends\b|signal\b|enum\b|const\b|var\b|static\s+func\b|func\b|class\b)"
)

RE_TSCN_EXT = re.compile(r'^\[ext_resource\s+[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"')
RE_TSCN_EXT_ALT = re.compile(r'^\[ext_resource\s+[^\]]*id="([^"]+)"[^\]]*path="([^"]+)"')
RE_TSCN_NODE = re.compile(r'^\[node\s+name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]*)")?(?:[^\]]*instance=ExtResource\("([^"]+)"\))?')
RE_TSCN_SCRIPT = re.compile(r'^script\s*=\s*ExtResource\("([^"]+)"\)')


@dataclass
class FuncInfo:
    signature: str
    start_line: int
    end_line: int


@dataclass
class ScriptInfo:
    rel_path: str
    total_lines: int
    class_name: str = ""
    extends: str = ""
    signals: list[str] = field(default_factory=list)
    constants: list[str] = field(default_factory=list)
    functions: list[FuncInfo] = field(default_factory=list)


@dataclass
class SceneInfo:
    rel_path: str
    root_name: str = ""
    root_type: str = ""
    root_script: str = ""
    subscenes: list[str] = field(default_factory=list)
    node_scripts: list[str] = field(default_factory=list)


def _trim_block_end(lines: list[str], start_idx: int, raw_end_idx: int) -> int:
    end_idx = raw_end_idx
    while end_idx > start_idx:
        stripped = lines[end_idx].strip()
        if stripped == "" or stripped.startswith("#"):
            end_idx -= 1
        else:
            break
    return end_idx


def parse_gd_file(path: Path, root_dir: Path) -> ScriptInfo:
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    rel_path = path.relative_to(root_dir).as_posix()
    info = ScriptInfo(rel_path=rel_path, total_lines=len(lines))

    raw_funcs: list[tuple[str, int]] = []
    top_decl_lines: list[int] = []

    for idx, line in enumerate(lines, start=1):
        if line.startswith((" ", "\t")):
            continue
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if RE_TOP_DECL.match(stripped):
            top_decl_lines.append(idx)

        if m := RE_CLASS_NAME.match(stripped):
            info.class_name = m.group(1)
        elif m := RE_EXTENDS.match(stripped):
            info.extends = m.group(1)
        elif m := RE_SIGNAL.match(stripped):
            info.signals.append(m.group(1))
        elif m := RE_CONST.match(stripped):
            info.constants.append(m.group(1))
        elif m := RE_FUNC.match(stripped):
            sig = re.sub(r"\s+", " ", m.group(1)).strip()
            raw_funcs.append((sig, idx))

    for i, (sig, start_line) in enumerate(raw_funcs):
        next_func_line = raw_funcs[i + 1][1] if i + 1 < len(raw_funcs) else len(lines) + 1
        # Stop at the next top-level declaration if one appears before next_func_line (e.g. inner class)
        raw_end = next_func_line - 1
        for decl_line in top_decl_lines:
            if start_line < decl_line < next_func_line:
                # Ignore decorators stacked immediately above the next function
                if lines[decl_line - 1].lstrip().startswith("@"):
                    continue
                raw_end = decl_line - 1
                break
        end_line_1based = _trim_block_end(lines, start_line - 1, raw_end - 1) + 1
        info.functions.append(FuncInfo(signature=sig, start_line=start_line, end_line=end_line_1based))

    return info


def parse_tscn_file(path: Path, root_dir: Path) -> SceneInfo:
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    rel_path = path.relative_to(root_dir).as_posix()
    info = SceneInfo(rel_path=rel_path)

    ext_resources: dict[str, str] = {}
    current_is_root = False
    subscenes_seen: set[str] = set()
    node_scripts_seen: set[str] = set()

    for line in lines:
        stripped = line.strip()
        if m := RE_TSCN_EXT.match(stripped):
            ext_resources[m.group(2)] = m.group(1)
            continue
        if m := RE_TSCN_EXT_ALT.match(stripped):
            ext_resources[m.group(1)] = m.group(2)
            continue

        if m := RE_TSCN_NODE.match(stripped):
            node_name, node_type, parent, instance_id = m.groups()
            current_is_root = parent is None
            if current_is_root:
                info.root_name = node_name
                info.root_type = node_type or ""
            if instance_id and instance_id in ext_resources:
                sub_path = ext_resources[instance_id]
                if sub_path not in subscenes_seen:
                    subscenes_seen.add(sub_path)
                    info.subscenes.append(sub_path)
            continue

        if m := RE_TSCN_SCRIPT.match(stripped):
            res_id = m.group(1)
            if res_id in ext_resources:
                script_path = ext_resources[res_id]
                if current_is_root and not info.root_script:
                    info.root_script = script_path
                elif script_path != info.root_script and script_path not in node_scripts_seen:
                    node_scripts_seen.add(script_path)
                    info.node_scripts.append(script_path)

    return info


def collect_graph(root_dir: Path) -> tuple[list[ScriptInfo], list[SceneInfo]]:
    scripts_dir = root_dir / "scripts"
    scenes_dir = root_dir / "scenes"

    scripts: list[ScriptInfo] = []
    if scripts_dir.exists():
        for gd_path in sorted(scripts_dir.rglob("*.gd")):
            if any(part in {"tests", ".godot"} for part in gd_path.parts):
                continue
            scripts.append(parse_gd_file(gd_path, root_dir))

    scenes: list[SceneInfo] = []
    if scenes_dir.exists():
        for tscn_path in sorted(scenes_dir.rglob("*.tscn")):
            if any(part == ".godot" for part in tscn_path.parts):
                continue
            scenes.append(parse_tscn_file(tscn_path, root_dir))

    return scripts, scenes


def render_markdown(scripts: list[ScriptInfo], scenes: list[SceneInfo]) -> str:
    total_funcs = sum(len(s.functions) for s in scripts)
    total_signals = sum(len(s.signals) for s in scripts)

    out: list[str] = [
        "# Mapa de Símbolos GDScript & Cenas (CodeGraph Godot 4) 🗺️⚡",
        "",
        "> Índice estrutural gerado automaticamente por `tools/build_gd_graph.py`. "
        "Consulte este mapa (ou use `python tools/build_gd_graph.py --query <termo>`) "
        "antes de abrir scripts completos para ler apenas o intervalo exato de linhas.",
        "",
        f"- **Scripts indexados:** {len(scripts)} | **Funções:** {total_funcs} | **Signals:** {total_signals}",
        f"- **Cenas indexadas:** {len(scenes)}",
        "",
        "---",
        "",
        "## 1. Scripts GDScript (`scripts/`)",
        "",
    ]

    for s in scripts:
        header_meta: list[str] = [f"{s.total_lines} linhas"]
        if s.class_name:
            header_meta.append(f"`class_name {s.class_name}`")
        if s.extends:
            header_meta.append(f"`extends {s.extends}`")
        out.append(f"### `{s.rel_path}` ({' · '.join(header_meta)})")

        if s.signals:
            out.append(f"- **Signals:** {', '.join(f'`{sig}`' for sig in s.signals)}")
        if s.constants:
            consts_preview = ", ".join(f"`{c}`" for c in s.constants[:12])
            if len(s.constants) > 12:
                consts_preview += f" *(+{len(s.constants) - 12})*"
            out.append(f"- **Consts:** {consts_preview}")
        if s.functions:
            out.append("- **Funções:**")
            for fn in s.functions:
                out.append(f"  - `L{fn.start_line}-L{fn.end_line}` `{fn.signature}`")
        out.append("")

    out.extend([
        "---",
        "",
        "## 2. Cenas e Vínculos (`scenes/`)",
        "",
        "| Cena | Raiz | Script Principal | Subcenas Instanciadas |",
        "| :--- | :--- | :--- | :--- |",
    ])

    for sc in scenes:
        root_desc = f"`{sc.root_name}` ({sc.root_type})" if sc.root_type else f"`{sc.root_name}`"
        script_desc = f"`{sc.root_script}`" if sc.root_script else "—"
        if sc.node_scripts:
            extras = ", ".join(f"`{p}`" for p in sc.node_scripts)
            script_desc = f"{script_desc} (+ {extras})" if sc.root_script else extras
        subs_desc = ", ".join(f"`{sub}`" for sub in sc.subscenes) if sc.subscenes else "—"
        out.append(f"| `{sc.rel_path}` | {root_desc} | {script_desc} | {subs_desc} |")

    out.append("")
    return "\n".join(out)


def run_query(term: str, scripts: list[ScriptInfo], scenes: list[SceneInfo]) -> int:
    q = term.lower()
    hits = 0

    for s in scripts:
        script_match = q in s.rel_path.lower() or q in s.class_name.lower()
        sig_matches = [sig for sig in s.signals if q in sig.lower()]
        const_matches = [c for c in s.constants if q in c.lower()]
        fn_matches = [fn for fn in s.functions if q in fn.signature.lower()]

        if script_match or sig_matches or const_matches or fn_matches:
            hits += 1
            cls_tag = f" ({s.class_name})" if s.class_name else ""
            print(f"[SCRIPT] {s.rel_path}{cls_tag} [{s.total_lines}L]")
            if sig_matches:
                print(f"  signals: {', '.join(sig_matches)}")
            if const_matches:
                print(f"  consts: {', '.join(const_matches)}")
            for fn in (s.functions if script_match and not fn_matches else fn_matches):
                print(f"  L{fn.start_line}-L{fn.end_line}: {fn.signature}")

    for sc in scenes:
        in_scene = (
            q in sc.rel_path.lower()
            or q in sc.root_name.lower()
            or q in sc.root_script.lower()
            or any(q in sub.lower() for sub in sc.subscenes)
            or any(q in ns.lower() for ns in sc.node_scripts)
        )
        if in_scene:
            hits += 1
            print(f"[SCENE] {sc.rel_path} (root={sc.root_name}:{sc.root_type}, script={sc.root_script or '-'})")
            if sc.subscenes:
                print(f"  subscenes: {', '.join(sc.subscenes)}")

    if hits == 0:
        print(f"Nenhum símbolo ou cena encontrado para '{term}'.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Gera ou consulta o mapa de símbolos GDScript/Cenas.")
    parser.add_argument("--query", "-q", type=str, default="", help="Busca rápida por símbolo, classe, sinal ou cena.")
    args = parser.parse_args()

    scripts, scenes = collect_graph(ROOT_DIR)
    if args.query:
        return run_query(args.query, scripts, scenes)

    markdown = render_markdown(scripts, scenes)
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(markdown, encoding="utf-8", newline="\n")
    print(f"[GD_GRAPH] Gerado {OUTPUT_FILE.relative_to(ROOT_DIR).as_posix()} ({len(scripts)} scripts, {len(scenes)} cenas).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
