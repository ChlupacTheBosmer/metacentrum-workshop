# Testing log — WP4 (handover §7)

**How to use this file.** Each test below has an *exact, copy-pasteable* block.
Run it, paste the output under **OUTPUT**, and set **STATUS** to `PASS`,
`FAIL` or `PARTIAL`. Nothing here needs interpretation from you — paste raw
output, including errors. Errors are data.

> Tests are ordered by *how much they unblock*, not by number. The three tests
> in Wave 1 unblock the whole repo build; everything else can wait.

Status board:

| Test | What it unblocks | Status |
|---|---|---|
| T5a | **Compute-node egress to the AI API** (risk R10 — can Blocks 2–3 run where we plan?) | ✅ **PASS** — egress works |
| T6a | Exact R module name (every PBS script + RStudio session) | ✅ **PASS** — r/4.5.1-gcc-10.2.1-zmneq6c |
| T6b | PBS array dry run (F9, Block 5) | ✅ **PASS** — q_2h, ~100 s wait |
| T7  | Storage paths, quota, participant read access (A1–A6) | ✅ **PASS** — see CHANGELOG |
| T2  | Per-participant API keys (D5) | ☐ not run |
| T3  | Flash-crowd rate limits with ~15 keys | ☐ not run |
| T4  | R↔API on the infra (D3) | ☐ not run |
| T5b | OnDemand RStudio form reality check (slides screenshots) | ☐ not run |
| T1  | Fresh-account walkthrough (setup.md) | ☐ not run |
| T8  | Timing suite → slide numbers + fit budgets | ☐ not run |
| T9  | Full dry run with a pilot colleague | ☐ not run |

---

## WAVE 1 — run these first (≈20 minutes total)

### T5a — Does a compute node have outbound access to the AI API?

**Why this is first:** if compute nodes cannot reach `llm.ai.e-infra.cz`, then
Blocks 2 and 3 (generation + embedding) cannot happen inside an RStudio session
and the whole morning has to be re-planned. This is risk R10, the only
`[VERIFY]` that can force a redesign.

Run **from inside an OnDemand RStudio session's Terminal pane** (not from the
frontend — the frontend proves nothing about compute nodes).

```bash
# 1. Where am I? (should be a compute node, not a frontend)
hostname; echo "---"

# 2. Plain reachability
curl -s -o /dev/null -w "models endpoint HTTP=%{http_code} time=%{time_total}s\n" \
  --max-time 20 https://llm.ai.e-infra.cz/v1/models
echo "---"

# 3. Authenticated call. Paste your key at the prompt; it is NOT echoed
#    and NOT written to disk or shell history.
read -rsp "e-INFRA API key: " EINFRA_API_KEY; echo
curl -s --max-time 30 https://llm.ai.e-infra.cz/v1/embeddings \
  -H "Authorization: Bearer $EINFRA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"mxbai-embed-large:latest","input":["hello from a compute node"]}' \
  | head -c 300; echo; echo "---"

# 4. Same again through a proxy, in case one is required
env | grep -i proxy || echo "(no proxy variables set)"
```

**OUTPUT**
```
(paste here)
```
**STATUS:** ☐

---

### T6a — The exact R module name

Run **on a frontend** (SSH, or the OnDemand "Clusters → Shell" pane).

```bash
hostname; echo "---"
module avail R/ 2>&1 | head -40
echo "--- rstudio/gcc toolchain ---"
module avail 2>&1 | grep -iE '^(r|R)[-/]|rstudio|gcc/' | head -30
```

Then load the newest R and confirm it works **and that Stan can compile** —
this is risk R4 and it is cheaper to find out now:

```bash
module add <PASTE THE EXACT R MODULE STRING FROM ABOVE>
R --version | head -2
Rscript -e 'cat("libpaths:\n"); print(.libPaths());
  cat("\ninstalled (of interest):\n");
  for (p in c("httr2","jsonlite","dplyr","ggplot2","brms","rstan","cmdstanr",
              "posterior","uwot","arrow","furrr","future"))
    cat(sprintf("  %-10s %s\n", p, ifelse(requireNamespace(p, quietly=TRUE),"yes","MISSING")))'
```

**OUTPUT**
```
(paste here)
```
**STATUS:** ☐

---

### T6b — PBS array dry run (3 jobs)

Run **on a frontend**. This proves the array syntax, the index variable, where
output lands, and roughly how long the queue makes us wait.

```bash
mkdir -p ~/pbs_arraytest && cd ~/pbs_arraytest
cat > arraytest.sh <<'PBSEOF'
#!/bin/bash
#PBS -N ws_arraytest
#PBS -l select=1:ncpus=1:mem=1gb:scratch_local=1gb
#PBS -l walltime=00:05:00
echo "index=$PBS_ARRAY_INDEX array_id=$PBS_ARRAY_ID"
echo "host=$(hostname) scratch=$SCRATCHDIR"
echo "submit_dir=$PBS_O_WORKDIR"
sleep 20
echo "done"
PBSEOF

date; qsub -J 1-3 arraytest.sh
```

Wait a minute, then:

```bash
cd ~/pbs_arraytest
qstat -t -u "$USER"
echo "--- after they finish ---"
date; ls -la; echo "--- contents ---"; cat ws_arraytest.o* 2>/dev/null
```

**Record:** submit time → first-job start time (this is the queue wait we must
absorb in Block 5).

**OUTPUT**
```
(paste here)
```
**STATUS:** ☐

---

### T7 — Storage: paths, quota, and can participants read our artifacts?

Run **on a frontend**.

```bash
echo "== home =="; echo "$HOME"; df -h "$HOME" | tail -2
echo; echo "== quota =="; quota -s 2>/dev/null || echo "(quota cmd not available)"
echo; echo "== what /storage looks like =="; ls -1 /storage 2>/dev/null | head -20
echo; echo "== my storage homes =="; ls -ld /storage/*/home/"$USER" 2>/dev/null
echo; echo "== group-readable candidate for artifacts A1-A6 =="
ls -ld /storage/projects/* 2>/dev/null | head -10
```

Then tell me which path you want to use for the ~1 GB of pre-generated
artifacts, and whether every workshop participant will be able to `ls` it.

**OUTPUT**
```
(paste here)
```
**STATUS:** ☐

---

## WAVE 2 — after the decisions land

T2 (key provisioning for the room), T3 (flash crowd), T4 (R↔API on infra),
T5b (OnDemand form + screenshots), T1 (fresh account), T8 (timings), T9 (dry run).
These blocks will be written into this file once D1–D8 are answered — several of
them depend on which language and which model backend we settle on.
