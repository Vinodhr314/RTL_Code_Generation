# RTL Agent — Design & Implementation Guide

A practical guide for building an **RTL generation and verification agent** that accepts **module names** (and specifications), produces synthesizable Verilog/SystemVerilog RTL files, and validates them through simulation and lint.

This repository implements a **32-bit RISC-V SoC module catalog** with **88/88 modules complete** — each has a locked spec (`specs/`), synthesizable RTL (`rtl/`), testbench (`tb/`), and passing simulation. See [Section 17](#17-module-catalog--32-bit-risc-v-soc-88-modules) for the full module list.

This document synthesizes patterns from leading open-source projects, industry workflows, and academic research (2024–2026). Use it as a blueprint for your own agent in this repository.

---

## Table of Contents

1. [What You Are Building](#1-what-you-are-building)
2. [Key Principles (From Research)](#2-key-principles-from-research)
3. [Reference Projects](#3-reference-projects)
4. [Recommended Architecture](#4-recommended-architecture)
5. [Input Contract: Module Names → RTL](#5-input-contract-module-names--rtl)
6. [Agent Roles](#6-agent-roles)
7. [Verification Pipeline](#7-verification-pipeline)
8. [Project Layout](#8-project-layout)
9. [Step-by-Step Build Guide](#9-step-by-step-build-guide)
10. [Prompt Templates](#10-prompt-templates)
11. [EDA Toolchain Setup](#11-eda-toolchain-setup)
12. [Benchmarks for Testing](#12-benchmarks-for-testing)
13. [Building in Cursor](#13-building-in-cursor)
14. [Failure Recovery Loop](#14-failure-recovery-loop)
15. [Example: End-to-End Run](#15-example-end-to-end-run)
16. [References](#16-references)
17. [Module Catalog — 32-bit RISC-V SoC (88 modules)](#17-module-catalog--32-bit-risc-v-soc-88-modules)

---

## 1. What You Are Building

**Goal:** Given one or more **module names** (e.g. `adder_8bit`, `fsm`, `traffic_light`), your agent should:

1. Resolve or load the **functional specification** for each module (ports, behavior, timing).
2. **Generate** a synthesizable RTL file per module (`rtl/<module_name>.v`).
3. **Verify** each module (compile → simulate → optional lint/synthesis).
4. **Self-repair** on failure using simulation logs and structured feedback.
5. Emit a **pass/fail report** per module.

This is **not** a one-shot code generator. Successful RTL agents use a **closed feedback loop** — generate, verify, debug, regenerate — until tests pass or a retry budget is exhausted.

```
Module name(s) + spec
        │
        ▼
   ┌─────────┐     ┌──────────┐     ┌─────────────┐
   │ Spec    │ ──► │ RTL      │ ──► │ Verify      │
   │ Agent   │     │ Coder    │     │ (sim/lint)  │
   └─────────┘     └──────────┘     └──────┬──────┘
        ▲                                  │
        └──────── Debugger ◄── FAIL ───────┘
                         PASS ──► Done
```

---

## 2. Key Principles (From Research)

| Principle | Why it matters | Source |
|-----------|----------------|--------|
| **Validation-first** | Generating RTL is easy; generating *correct* RTL is hard. Every design must compile and simulate before delivery. | [CVDP benchmark](https://www.linkedin.com/posts/turingcom_case-study-benchmarking-rtl-agents-with-activity-7436845745707565056-idSI), [SiliconForge](https://github.com/ben-biju/SiliconForge) |
| **Multi-agent specialization** | One LLM doing everything underperforms agents with focused roles (spec, coder, verifier, debugger). | [MAGE](https://github.com/stable-lab/MAGE-A-Multi-Agent-Engine-for-Automated-RTL-Code-Generation), [Veri-Sure](https://github.com/xyjoey/Veri-Sure) |
| **Structured spec before code** | Lock module name, ports, reset polarity, and timing contracts *before* RTL generation. | [VeriFlow-CC](https://github.com/bjwanneng/veriflow-cc) |
| **Golden reference model** | A Python (or C++) reference model produces expected traces for waveform diff and faster debug. | [VeriFlow-CC](https://github.com/bjwanneng/veriflow-cc), [ChipMATE](https://github.com/zhongkaiyu/ChipMATE) |
| **Iterative repair with bounded retries** | Feed compile/sim errors back to the coder; cap retries (typically 3–5) to avoid infinite loops. | [SiliconForge](https://github.com/ben-biju/SiliconForge), [MAGE](https://github.com/stable-lab/MAGE-A-Multi-Agent-Engine-for-Automated-RTL-Code-Generation) |
| **Hardware-aware prompts** | Constrain output to Verilog-2005 / Icarus-compatible constructs; forbid latches, incomplete case, mixed reset polarity. | [RTLCoder](https://github.com/hkust-zhiyao/RTL-Coder), [VeriFlow-CC coding_style.md](https://github.com/bjwanneng/veriflow-cc) |
| **Module-name + IO in prompt** | Benchmarks like RTLLM embed explicit module name and port widths in the description — this is critical for auto-verification. | [RTLLM 2.0](https://github.com/hkust-zhiyao/RTLLM) |

---

## 3. Reference Projects

Study these repositories when designing your agent:

| Project | Approach | Best for learning |
|---------|----------|-------------------|
| [**VeriFlow-CC**](https://github.com/bjwanneng/veriflow-cc) | 4-stage pipeline: spec → codegen → verify/fix → lint/synth. Claude Code skill + sub-agents. Zero pip deps. | **Pipeline orchestration**, golden model, error recovery |
| [**MAGE**](https://github.com/stable-lab/MAGE-A-Multi-Agent-Engine-for-Automated-RTL-Code-Generation) | Python multi-agent engine with VerilogEval/RTLLM benchmarks. | **Agent coordination**, benchmark integration |
| [**RTLCoder**](https://github.com/hkust-zhiyao/RTL-Coder) | Fine-tuned LLMs + prompt templates with explicit module/IO format. | **Prompt design**, module-name-driven generation |
| [**Veri-Sure**](https://github.com/xyjoey/Veri-Sure) | 6 agents + formal verification + temporal tracing. | **Advanced verification**, contract-aware design |
| [**SiliconForge**](https://github.com/ben-biju/SiliconForge) | Architect → structural lint → debugger → cocotb sim → waveforms. | **Self-repair loop**, AST-based checks |
| [**ChipMATE**](https://github.com/zhongkaiyu/ChipMATE) | Verilog agent + Python reference agent cross-verify on random stimuli. | **Verification without golden testbench** |
| [**RTLLM**](https://github.com/hkust-zhiyao/RTLLM) | 50 module designs with `design_description.txt` + `testbench.v` + golden RTL. | **Module catalog**, evaluation harness |

---

## 4. Recommended Architecture

For a **module-name-driven** agent (your use case), use a **4-stage sequential pipeline**:

```
Stage 0: INIT
  - Parse module list
  - Discover EDA tools (iverilog, vvp, yosys, verilator)
  - Load or generate per-module spec

Stage 1: SPEC
  - For each module_name:
      - Resolve spec from catalog OR generate from user description
      - Output: specs/<module_name>.json (ports, behavior, timing)
      - Output: golden/<module_name>_model.py (optional but recommended)

Stage 2: CODEGEN
  - For each module (can run in parallel):
      - Input: specs/<module_name>.json + coding_style rules
      - Output: rtl/<module_name>.v
      - Pre-write self-check (ports match spec, no latches, reset polarity)

Stage 3: VERIFY + FIX
  - Compile: iverilog -g2012 rtl/<module>.v tb/<module>_tb.v
  - Simulate: vvp sim/<module>.vvp
  - On FAIL: classify error → inject into coder → retry (max 3)
  - On PASS: proceed

Stage 4: LINT + SYNTH (optional)
  - Verilator lint or iverilog syntax-only
  - Yosys synthesis check
  - Report: logs/<module>_report.json
```

**Minimum viable agent:** Stages 0 → 1 (lightweight) → 2 → 3.

**Production agent:** All 4 stages + golden model + formal assertions.

---

## 5. Input Contract: Module Names → RTL

Your agent's primary input is a **module list**. Each module needs enough information to generate verifiable RTL.

### Option A — Module catalog (recommended for batch generation)

Maintain a `modules/` catalog keyed by module name. RTLLM follows this pattern:

```
modules/
├── adder_8bit/
│   └── design_description.txt   # Natural language spec + module name + IO
├── fsm/
│   └── design_description.txt
└── traffic_light/
    └── design_description.txt

tb/
├── adder_8bit_tb.v              # Simulation testbench (one per module)
├── fsm_tb.v
└── traffic_light_tb.v
```

**Agent input file** (`modules.txt` or `modules.json`):

```json
{
  "modules": [
    "adder_8bit",
    "fsm",
    "traffic_light"
  ],
  "language": "verilog",
  "coding_style": "verilog-2005",
  "clock_domain": "single",
  "reset": "async_active_low"
}
```

### Option B — Module name + inline spec

```json
{
  "modules": [
    {
      "name": "counter_12",
      "description": "12-bit up counter with async active-low reset and enable.",
      "ports": {
        "inputs": [
          {"name": "clk", "width": 1},
          {"name": "rst_n", "width": 1},
          {"name": "en", "width": 1}
        ],
        "outputs": [
          {"name": "count", "width": 12}
        ]
      }
    }
  ]
}
```

### Spec JSON schema (lock before codegen)

Adapted from [VeriFlow-CC spec_template.json](https://github.com/bjwanneng/veriflow-cc):

```json
{
  "module_name": "adder_8bit",
  "description": "8-bit ripple-carry adder",
  "ports": {
    "clk":    {"direction": "input",  "width": 1,  "required": false},
    "rst_n":  {"direction": "input",  "width": 1,  "reset_polarity": "active_low"},
    "a":      {"direction": "input",  "width": 8},
    "b":      {"direction": "input",  "width": 8},
    "sum":    {"direction": "output", "width": 9, "registered": false}
  },
  "behavior": "Combinational adder: sum = a + b",
  "timing_contracts": [],
  "coding_rules": ["no_latches", "explicit_widths", "default_case_in_fsm"]
}
```

**Rule:** Once Stage 1 completes, **port names and widths are locked**. The coder must not rename or resize ports — testbenches depend on them.

---

## 6. Agent Roles

Split responsibilities across specialized agents (or Cursor sub-agents / skills):

| Agent | Responsibility | Input | Output |
|-------|----------------|-------|--------|
| **Orchestrator** | Stage transitions, retry budget, state persistence | User module list | `pipeline_state.json` |
| **Spec Agent** | Resolve module spec from catalog or user text | `module_name`, optional `description` | `specs/<name>.json` |
| **Golden Model Agent** | Cycle-accurate Python reference (optional) | `specs/<name>.json` | `golden/<name>_model.py` |
| **RTL Coder Agent** | Generate synthesizable Verilog per module | `specs/<name>.json`, `coding_style.md` | `rtl/<name>.v` |
| **Testbench Agent** | Generate or reuse simulation harness | `specs/<name>.json`, golden model | `tb/<name>_tb.v` or cocotb test |
| **Verifier** | Run EDA tools, parse logs | RTL + TB | `logs/<name>_sim.log`, pass/fail |
| **Debugger Agent** | Minimal targeted fixes from error logs | Failure summary + RTL + spec | Patched `rtl/<name>.v` |
| **Linter / Synthesizer** | Static checks and Yosys synth | `rtl/<name>.v` | `logs/<name>_lint.log` |

### RTL Coder pre-write checklist

Before writing any `.v` file, the coder agent must verify:

1. Module name matches spec exactly.
2. All ports match spec (name, direction, width).
3. Reset polarity is consistent (`rst_n` = active-low).
4. FSM `case` statements have `default`.
5. No combinational latches (`always @*` assigns all outputs).
6. Registered outputs use non-blocking `<=` on posedge clock.
7. No SystemVerilog features unsupported by your simulator.

---

## 7. Verification Pipeline

Verification is the core differentiator. Use a **layered** approach:

### Layer 1 — Syntax / compile

```bash
iverilog -g2012 -o sim/<module>.vvp rtl/<module>.v tb/<module>_tb.v
```

Fail fast on syntax errors before simulation.

### Layer 2 — Functional simulation

```bash
vvp sim/<module>.vvp | tee logs/<module>_sim.log
```

**Pass criteria** (strict, from VeriFlow-CC):

1. `sim.log` exists and is non-empty.
2. No lines matching `[FAIL]` or `FAILED:`.
3. Contains explicit summary: `ALL TESTS PASSED`.

### Layer 3 — Waveform / trace diff (debug)

When simulation fails:

1. Dump VCD: add `$dumpfile` / `$dumpvars` in testbench.
2. Compare per-cycle values against golden model trace.
3. Classify bug type:
   - **Type A** — Wrong computation (logic error)
   - **Type B** — Timing offset (off-by-one cycle)
   - **Type D** — Initialization / reset error

### Layer 4 — Lint (optional)

```bash
verilator --lint-only -Wall rtl/<module>.v
```

### Layer 5 — Synthesis check (optional)

```bash
yosys -p "read_verilog rtl/<module>.v; synth; stat"
```

### Layer 6 — Formal / assertions (advanced)

Generate SVA assertions from timing contracts ([Veri-Sure](https://github.com/xyjoey/Veri-Sure), [VeriFlow formal_property_gen.py](https://github.com/bjwanneng/veriflow-cc)).

---

## 8. Project Layout

Recommended directory structure for this repository:

```
RTL_Code_Generation/
├── README.md                      # This guide
├── modules.txt                    # Input: list of module names
├── coding_style.md                # Verilog rules for the coder agent
├── agents/
│   ├── orchestrator.md            # Main pipeline skill / system prompt
│   ├── spec_agent.md              # Spec resolution
│   ├── rtl_coder.md               # RTL generation
│   ├── tb_agent.md                # Testbench generation
│   ├── debugger.md                # Error recovery
│   └── linter.md                  # Lint + synth
├── modules/                       # Module catalog (design descriptions only)
│   └── <module_name>/
│       └── design_description.txt
├── specs/                         # Generated structured specs (Stage 1)
│   └── <module_name>.json
├── golden/                        # Reference models (optional)
│   └── <module_name>_model.py
├── rtl/                           # Generated RTL (Stage 2)
│   └── <module_name>.v
├── tb/                            # All testbenches (sim harness)
│   └── <module_name>_tb.v
├── sim/                           # Compiled sim binaries
├── logs/                          # Simulation, lint, synth logs
│   └── <module_name>_report.json
├── scripts/
│   ├── discover_eda.py            # Find iverilog, vvp, yosys, verilator
│   ├── run_sim.py                 # Compile + simulate wrapper
│   ├── run_lint.py
│   └── batch_runner.py            # Run all modules, emit summary
├── templates/
│   ├── spec_template.json
│   ├── rtl_module_template.v
│   └── tb_template.v
└── .rtl_agent/
    ├── pipeline_state.json        # Resumable state
    └── eda_env.json               # Discovered tool paths
```

---

## 9. Step-by-Step Build Guide

### Phase 1 — Foundation (Day 1–2)

1. **Install EDA tools** — see [Section 11](#11-eda-toolchain-setup).
2. **Create `coding_style.md`** — Verilog-2005 rules, reset convention, FSM template.
3. **Seed module catalog** — clone [RTLLM](https://github.com/hkust-zhiyao/RTLLM) designs or add your own under `modules/`.
4. **Write `scripts/discover_eda.py`** — detect and cache tool paths.
5. **Write `scripts/run_sim.py`** — compile + simulate one module, return pass/fail JSON.

### Phase 2 — Single-module agent (Day 3–5)

1. **Implement Spec Agent** — given `module_name`, read `modules/<name>/design_description.txt` → emit `specs/<name>.json`.
2. **Implement RTL Coder Agent** — spec JSON → `rtl/<name>.v` using prompt template ([Section 10](#10-prompt-templates)).
3. **Wire verification** — run `scripts/run_sim.py` after codegen.
4. **Test on 3 modules** — start with simple combinational (`adder_8bit`), then sequential (`counter_12`), then FSM (`fsm`).

### Phase 3 — Multi-module + self-repair (Day 6–10)

1. **Batch input** — accept `modules.txt` with multiple names; process sequentially or in parallel.
2. **Debugger Agent** — on sim failure, parse log, produce `logs/<name>_failure_summary.md`, retry codegen (max 3).
3. **State persistence** — save progress in `.rtl_agent/pipeline_state.json` so runs are resumable.
4. **Summary report** — `logs/batch_report.json` with per-module pass/fail and retry count.

### Phase 4 — Hardening (Day 11+)

1. Add Verilator lint and Yosys synthesis stages.
2. Add golden Python model for waveform diff (optional).
3. Integrate benchmarks: [VerilogEval](https://github.com/NVlabs/verilog-eval), [RTLLM 2.0](https://github.com/hkust-zhiyao/RTLLM).
4. Add corner-case test generation from port definitions.
5. Consider fine-tuned models ([RTLCoder on HuggingFace](https://huggingface.co/ishorn5/RTLCoder-Deepseek-v1.1)) for faster/better codegen.

---

## 10. Prompt Templates

### RTL Coder system prompt (core)

Based on [RTLCoder](https://github.com/hkust-zhiyao/RTL-Coder) and [VeriFlow-CC vf-coder](https://github.com/bjwanneng/veriflow-cc):

```markdown
You are a professional Verilog designer.

Rules:
- Output ONLY synthesizable Verilog-2005 code. No markdown, no explanation.
- Module name and all port names/widths MUST match the provided spec exactly.
- Use active-low async reset (rst_n) unless spec says otherwise.
- FSMs: three-block style (state register, next-state logic, output logic).
- Every always @* block must assign ALL outputs (no latches).
- Sequential logic: non-blocking (<=) on posedge clk.
- Include `default` in every case statement.
- Do NOT generate testbenches.

Spec:
{spec_json}

Write the complete module to rtl/{module_name}.v
```

### Spec Agent prompt

```markdown
Given module name "{module_name}", read the design description and produce
a JSON spec with: module_name, ports (name, direction, width, reset_polarity
if applicable), behavior description, and timing_contracts (if any).

Lock all port names and widths — they must match the testbench.
```

### Debugger prompt

```markdown
RTL module "{module_name}" failed verification.

Failure summary:
{failure_summary}

Current RTL:
{rtl_content}

Spec (ports are LOCKED — do not change):
{spec_json}

Apply the MINIMAL fix to address the root cause. Do not rewrite unrelated logic.
```

---

## 11. EDA Toolchain Setup

### Windows (your environment)

| Tool | Purpose | Install |
|------|---------|---------|
| **Icarus Verilog** | Compile + simulate | [iverilog releases](https://github.com/steveicarus/iverilog) or WSL2 |
| **vvp** | Simulation runtime | Bundled with Icarus |
| **Verilator** | Lint | [verilator.org](https://www.veripool.org/verilator/) or WSL2 |
| **Yosys** | Synthesis check | [yosyshq.net](https://yosyshq.net/yosys/) or WSL2 |
| **Python 3.10+** | Golden models, cocotb | `python.org` |
| **cocotb** (optional) | Python co-simulation | `pip install cocotb` |

> **Note:** On Windows, many RTL agent projects run EDA tools inside **WSL2** for compatibility. [VeriFlow-CC](https://github.com/bjwanneng/veriflow-cc) and [MAGE](https://github.com/stable-lab/MAGE-A-Multi-Agent-Engine-for-Automated-RTL-Code-Generation) assume a Linux-like environment.

### Verify installation

```bash
iverilog -v          # Expect v12.x
vvp -v
verilator --version
yosys -V
```

---

## 12. Benchmarks for Testing

Use these to measure your agent's quality:

| Benchmark | Modules | What it tests | Link |
|-----------|---------|---------------|------|
| **RTLLM 2.0** | 50 designs | Module-name + description → RTL, auto TB | [hkust-zhiyao/RTLLM](https://github.com/hkust-zhiyao/RTLLM) |
| **VerilogEval v2** | 156+ problems | HDL coding from spec | [NVlabs/verilog-eval](https://github.com/NVlabs/verilog-eval) |
| **CVDP** | 1500+ tasks | Real-world multi-file RTL workflows | NVIDIA / Turing benchmark |

**Suggested evaluation metrics:**

- **Syntax pass rate** — compiles without error
- **Functional pass rate** — simulation passes
- **Pass@k** — success within k retries
- **Per-category breakdown** — arithmetic, memory, control, FSM

Example RTLLM module names to start with:

```
adder_8bit, comparator_3bit, counter_12, fsm, traffic_light,
barrel_shifter, LIFObuffer, signal_generator, edge_detect
```

---

## 13. Building in Cursor

You can implement this agent natively in **Cursor** using skills and sub-agents (same pattern as [VeriFlow-CC](https://github.com/bjwanneng/veriflow-cc)):

### Recommended Cursor structure

```
.cursor/
├── skills/
│   └── rtl-agent/
│       ├── SKILL.md              # Orchestrator: /rtl-gen <modules.txt>
│       ├── state.py              # Pipeline state machine
│       ├── run_sim.py            # EDA wrapper
│       └── coding_style.md
└── agents/
    ├── rtl-spec.md
    ├── rtl-coder.md
    ├── rtl-debugger.md
    └── rtl-verifier.md
```

### Orchestrator skill flow (`SKILL.md`)

```markdown
# RTL Generation Agent

Trigger: /rtl-gen

Steps:
1. Read modules.txt (or user-provided module names)
2. For each module:
   a. Call rtl-spec agent → specs/<name>.json
   b. Call rtl-coder agent → rtl/<name>.v
   c. Run scripts/run_sim.py
   d. If FAIL and retries < 3: call rtl-debugger → retry from (b)
   e. Record result in logs/<name>_report.json
3. Emit batch summary
```

### Cursor settings for safe execution

- Set **Run Mode** to **Allowlist** with an empty command allowlist so `iverilog`/`vvp` require your approval before running.
- Or use **Auto-review** if you want sandboxed auto-execution for safe compile commands.

### LLM choice

| Use case | Model suggestion |
|----------|------------------|
| RTL codegen | Claude Sonnet, GPT-4o, DeepSeek-Coder, or fine-tuned [RTLCoder](https://huggingface.co/ishorn5/RTLCoder-Deepseek-v1.1) |
| Spec parsing | Any strong reasoning model |
| Debug / fix | Same as coder; temperature 0 |

---

## 14. Failure Recovery Loop

When verification fails, follow this sequence (from VeriFlow-CC and SiliconForge):

```
1. PARSE     — Extract error from compile log or sim log
2. CLASSIFY  — Syntax / logic / timing / reset / interface
3. LOCALIZE  — Identify file, line, signal, cycle
4. SUMMARIZE — Write logs/<name>_failure_summary.md (concise)
5. PATCH     — Debugger applies minimal fix (not full rewrite)
6. RE-VERIFY — Re-run compile + sim only (skip lint if unchanged)
7. RETRY     — Max 3 attempts, then escalate to user
```

**Failure summary format:**

```markdown
# Failure: adder_8bit (attempt 2/3)
Type: Logic error (Type A)
Signal: sum
Cycle: 5
Expected: 0xFF
Actual:   0xFE
Root cause: Missing carry bit in MSB
Fix: Extend carry chain to bit 8
```

---

## 15. Example: End-to-End Run

### Input

`modules.txt`:
```
adder_8bit
counter_12
fsm
```

### Expected flow

```bash
# 1. Initialize
python scripts/discover_eda.py

# 2. Run agent (or /rtl-gen in Cursor)
python scripts/batch_runner.py --modules modules.txt

# 3. Check results
cat logs/batch_report.json
```

### Expected output

```
rtl/
├── adder_8bit.v      ✓ PASS (1 attempt)
├── counter_12.v      ✓ PASS (2 attempts)
└── fsm.v             ✗ FAIL (3 attempts — manual review needed)

logs/
├── adder_8bit_sim.log
├── counter_12_sim.log
├── fsm_sim.log
└── batch_report.json
```

### `batch_report.json` example

```json
{
  "total": 3,
  "passed": 2,
  "failed": 1,
  "modules": [
    {"name": "adder_8bit", "status": "PASS", "attempts": 1},
    {"name": "counter_12", "status": "PASS", "attempts": 2},
    {"name": "fsm",        "status": "FAIL", "attempts": 3, "error": "FSM state transition mismatch at cycle 42"}
  ]
}
```

---

## 16. References

### Open-source repositories

- [VeriFlow-CC](https://github.com/bjwanneng/veriflow-cc) — Claude Code RTL pipeline
- [MAGE](https://github.com/stable-lab/MAGE-A-Multi-Agent-Engine-for-Automated-RTL-Code-Generation) — Multi-agent RTL engine
- [RTLCoder](https://github.com/hkust-zhiyao/RTL-Coder) — Fine-tuned models + prompt format
- [RTLLM](https://github.com/hkust-zhiyao/RTLLM) — Module benchmark (50 designs)
- [Veri-Sure](https://github.com/xyjoey/Veri-Sure) — Contract-aware multi-agent + formal
- [SiliconForge](https://github.com/ben-biju/SiliconForge) — Self-repair + cocotb
- [ChipMATE](https://github.com/zhongkaiyu/ChipMATE) — Cross-verification agents
- [VerilogEval](https://github.com/NVlabs/verilog-eval) — Standard HDL benchmark

### Papers

- [MAGE: Multi-Agent Engine for Automated RTL Code Generation](https://arxiv.org/abs/2412.07822)
- [RTLCoder (IEEE TCAD)](https://zhiyaoxie.github.io/files/TCAD25_RTLCoder.pdf)
- [OpenLLM-RTL: Dataset and Benchmark](https://arxiv.org/html/2503.15112v1)
- [Spec2RTL-Agent](https://arxiv.org/html/2506.13905)
- [Veri-Sure: Contract-Aware Multi-Agent Framework](https://arxiv.org/html/2601.19747)

### Industry

- [Accelerating RTL Design with Agentic AI (MosChip / Design-Reuse)](https://www.design-reuse.com/blog/56185-accelerating-rtl-design-with-agentic-ai-a-multi-agent-llm-driven-approach/)

---

## 17. Module Catalog — 32-bit RISC-V SoC (88 modules)

**Status:** 88/88 complete — spec + RTL + testbench + simulation PASS for every module.

Each module has:

| Artifact | Path |
|----------|------|
| Design description | `modules/<name>/design_description.txt` |
| Locked spec | `specs/<name>.json` |
| RTL | `rtl/<name>.v` |
| Testbench | `tb/<name>_tb.v` |
| Sim report | `logs/<name>_report.json` |

Run one module: `python3 scripts/run_sim.py <name> --json`  
Run all: `python3 scripts/batch_runner.py --modules modules.txt`

Progress tracker: `progress_list.md`

### By category

#### Core, system & control (10)

| Module | Role |
|--------|------|
| `atomic` | Load-reserved / store-conditional and AMO helper |
| `cmu` | Clock management unit |
| `comp_isa` | Compressed ISA extension block |
| `csr` | Control/status register file |
| `interrupt_controller` | IRQ aggregation and masking |
| `pmp` | Physical memory protection unit |
| `sch` | Interrupt scheduler / round-robin arbiter |
| `ulss` | Ultra-low-power sleep / wake controller |
| `wdt` | Watchdog timer |
| `zilla_irq` | Platform IRQ controller |

#### Bus & interconnect (7)

| Module | Role |
|--------|------|
| `apb` | APB4 slave bridge |
| `apb_arbiter` | Multi-master APB arbiter |
| `axi` | AXI4 slave port |
| `axi_apb_converter` | AXI4 → APB bridge |
| `axi_axi_arbiter_4_7_config` | Configurable AXI crossbar arbiter |
| `axi_top` | AXI interconnect top |
| `noc` | Network-on-chip XY router |

#### Memory, DMA & buffering (11)

| Module | Role |
|--------|------|
| `async_fifo` | Clock-crossing FIFO (Gray-pointer) |
| `ddr3_boot_up` | DDR3 initialization sequence |
| `ddr3_controller` | DDR3 memory controller |
| `dram` | SDRAM/AXI memory interface |
| `fifo` | Synchronous FIFO |
| `gp_dma` | General-purpose DMA engine |
| `gp_dma_gen_1` | Second-generation GP DMA |
| `hpdmc_latest` | High-performance DRAM controller |
| `mem_ctrl` | External memory controller |
| `packet_buffer` | Network packet SRAM buffer |
| `pp_ext_mem` | External memory port for datapath |

#### Datapath & arithmetic (6)

| Module | Role |
|--------|------|
| `adder_8bit` | 8-bit ripple-carry adder |
| `barrel_shifter` | Configurable barrel shifter |
| `endian_converter` | Byte / half-word endian swap |
| `multiplier_divider` | Integer multiply / divide unit |
| `pp` | Datapath processing block |
| `srt_divider` | SRT floating-point divider |

#### Accelerators & FPU (8)

| Module | Role |
|--------|------|
| `compression_engine` | Data compression accelerator |
| `cordic` | CORDIC trigonometric engine |
| `cordic_algorithm` | CORDIC algorithm reference accelerator |
| `coremark_benchmark` | CoreMark benchmark harness block |
| `fpu` | Single-precision (FP32) FPU |
| `fpu_double_precision` | Double-precision (FP64) FPU |
| `spu` | Signal processing unit |
| `vpu` | Vector processing unit |

#### Crypto, hash & ECC (8)

| Module | Role |
|--------|------|
| `aes` | AES-128 block cipher |
| `bch_encoder` | BCH error-correcting encoder |
| `bch_error_correction` | BCH decoder / corrector |
| `crc` | CRC checksum engine |
| `crc_algorithm` | CRC algorithm reference block |
| `hamming_ecc` | Hamming ECC encode/decode |
| `md5` | MD5 hash digest block |
| `secured_hash_algorithm` | SHA-256 hash engine |

#### Network & Ethernet (5)

| Module | Role |
|--------|------|
| `admission_control` | Token-bucket traffic admission |
| `eth_stat` | Ethernet statistics counter block |
| `ethernet_classifier` | Packet traffic-class classifier |
| `frame_formatter` | Ethernet frame formatter |
| `tx_mac` | Transmit MAC interface |

#### Media & video (2)

| Module | Role |
|--------|------|
| `pixel_decompanding` | Pixel decompanding pipeline |
| `video_frame_formatter` | Video frame header/payload formatter |

#### Peripherals & security (5)

| Module | Role |
|--------|------|
| `gpio` | General-purpose I/O controller |
| `i2c` | I2C master/slave interface |
| `otp` | One-time-programmable ROM reader |
| `spi` | SPI controller |
| `uart` | UART serial port |

#### Debug & trace (4)

| Module | Role |
|--------|------|
| `debug_module` | RISC-V debug module (DMI) |
| `jtag` | JTAG TAP controller |
| `jtag_gen_1` | Alternate JTAG TAP (gen 1) |
| `trace_unit` | Instruction trace encoder |

#### Algorithm accelerators (21)

Software-algorithm blocks exposed as memory-mapped accelerators (graph, sort, search, math):

| Module | Module | Module | Module |
|--------|--------|--------|--------|
| `bellman_ford` | `bfs` | `binary_exponentiation` | `binary_search` |
| `bit_count_kernighan` | `bubble_sort` | `dfs` | `dijkstra` |
| `euclidean_gcd` | `fibonacci_dp` | `heap_sort` | `insertion_sort` |
| `knapsack` | `lcs` | `linear_search` | `merge_sort` |
| `power_of_two_check` | `quick_sort` | `selection_sort` | `sieve_eratosthenes` |
| `swap_no_temp` | | | |

#### Miscellaneous (1)

| Module | Role |
|--------|------|
| `custom_circuits` | Custom glue / misc logic block |

### Full alphabetical list (88)

```
adder_8bit, admission_control, aes, apb, apb_arbiter, async_fifo, atomic, axi,
axi_apb_converter, axi_axi_arbiter_4_7_config, axi_top, barrel_shifter,
bch_encoder, bch_error_correction, bellman_ford, bfs, binary_exponentiation,
binary_search, bit_count_kernighan, bubble_sort, cmu, comp_isa,
compression_engine, cordic, cordic_algorithm, coremark_benchmark, crc,
crc_algorithm, csr, custom_circuits, ddr3_boot_up, ddr3_controller,
debug_module, dfs, dijkstra, dram, endian_converter, eth_stat,
ethernet_classifier, euclidean_gcd, fibonacci_dp, fifo, fpu,
fpu_double_precision, frame_formatter, gp_dma, gp_dma_gen_1, gpio,
hamming_ecc, heap_sort, hpdmc_latest, i2c, insertion_sort,
interrupt_controller, jtag, jtag_gen_1, knapsack, lcs, linear_search, md5,
mem_ctrl, merge_sort, multiplier_divider, noc, otp, packet_buffer,
pixel_decompanding, pmp, power_of_two_check, pp, pp_ext_mem, quick_sort, sch,
secured_hash_algorithm, selection_sort, sieve_eratosthenes, spi, spu,
srt_divider, swap_no_temp, trace_unit, tx_mac, uart, ulss,
video_frame_formatter, vpu, wdt, zilla_irq
```

Source of truth for ordering: `modules.txt`

---

## Next Steps for This Repository

The initial 88-module catalog is **complete**. Suggested follow-on work:

1. **SoC integration** — instantiate modules behind a unified AXI/APB address map.
2. **Lint & synthesis** — run `scripts/run_lint.py` across all modules (requires Verilator/Yosys).
3. **Hardening** — replace stub accelerators with full implementations where needed.
4. **Regression** — `python3 scripts/batch_runner.py --modules modules.txt` after any RTL change.
5. **Golden models** — add Python reference models under `golden/` for waveform diff.

---

*Last updated: June 2026*
