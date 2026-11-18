#!/usr/bin/env python3
"""Test bed for the OWASP MAS EUDI Wallet profile.

Builds the list of OWASP MASTG tests that belong to the profile, runs the ones
that can run by themselves, and writes a score with an overview. It reports; it
does not judge the build: the exit code is 0 whatever the score is, and only an
error in the test bed itself (a tool that cannot run, a broken file) is non-zero.

Everything in the output says where it comes from:

  an OWASP test   a test of the OWASP MASTG, taken from its repository
  an OWASP check  a semgrep rule of the MASTG, run unchanged
  a Yivi check    our own automation of an OWASP test (mastg/yivi-checks.json)
  a Yivi test     our own test for a requirement, not from OWASP
                  (mastg/yivi-tests.json), scored apart from the OWASP tests

    python3 mastg/testbed.py --apk app.apk --ipa app.ipa
    python3 mastg/testbed.py                      # the sources only
    python3 mastg/testbed.py --write-baseline     # also store the score

See mastg/README.md. Needs Python 3.9+, git, semgrep and, for --apk, jadx.
"""

from __future__ import annotations

import argparse
import datetime
import glob
import hashlib
import json
import os
import plistlib
import re
import shlex
import shutil
import subprocess
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent

PASS, FAIL, TRIAGE, NOT_AUTOMATED, NOT_APPLICABLE = (
    "pass", "fail", "triage", "not_automated", "not_applicable",
)
STATUSES = [PASS, NOT_APPLICABLE, FAIL, TRIAGE, NOT_AUTOMATED]
RESOLVED = {PASS, NOT_APPLICABLE}
SEVERITY = {FAIL: 3, TRIAGE: 2, PASS: 1, NOT_APPLICABLE: 1, NOT_AUTOMATED: 0}
LABEL = {
    PASS: "Pass",
    NOT_APPLICABLE: "Not applicable",
    FAIL: "Fail",
    TRIAGE: "To triage",
    NOT_AUTOMATED: "Not automated",
}
OWASP, YIVI = "owasp", "yivi"
MAX_FINDINGS = 200  # kept per check; the count is always the full number


def log(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, text=True, capture_output=True, **kwargs)


def read_json(path: Path, default=None):
    if not path.exists():
        return default
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=1, ensure_ascii=False)
        handle.write("\n")


def anchor(test_id: str) -> str:
    return test_id.lower()


# --- MASTG -----------------------------------------------------------------


def fetch_mastg(config: dict, out: Path) -> Path:
    """Checks out the pinned MASTG commit, with only the folders the test bed reads."""
    target = out / "mastg-src"
    ref = config["mastg"]["ref"]
    if (target / ".git").exists():
        head = run(["git", "-C", str(target), "rev-parse", "HEAD"]).stdout.strip()
        if head == ref:
            return target
        shutil.rmtree(target)
    log(f"Fetching MASTG at {ref[:12]}")
    target.mkdir(parents=True, exist_ok=True)
    steps = [
        ["git", "init", "-q"],
        ["git", "remote", "add", "origin", config["mastg"]["repository"]],
        ["git", "sparse-checkout", "set", "tests-beta", "demos", "rules"],
        ["git", "fetch", "-q", "--depth", "1", "--filter=blob:none", "origin", ref],
        ["git", "checkout", "-q", "FETCH_HEAD"],
    ]
    for step in steps:
        result = run(step, cwd=target)
        if result.returncode != 0:
            raise SystemExit(f"{' '.join(step)} failed:\n{result.stderr}")
    return target


def front_matter(path: Path) -> dict:
    """The YAML header of a MASTG page, for the flat keys the test bed uses."""
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---"):
        return {}
    header = text.split("---", 2)[1]
    data: dict = {}
    for line in header.splitlines():
        match = re.match(r"^([a-z_-]+):\s*(.*)$", line)
        if not match:
            continue
        key, value = match.group(1), match.group(2).strip()
        if value.startswith("[") and value.endswith("]"):
            data[key] = [item.strip().strip("'\"") for item in value[1:-1].split(",") if item.strip()]
        else:
            data[key] = value.strip("'\"")
    return data


def load_owasp_tests(mastg: Path) -> list[dict]:
    tests = []
    for path in sorted((mastg / "tests-beta").rglob("MASTG-TEST-*.md")):
        meta = front_matter(path)
        if not meta.get("id") or meta.get("status") in ("placeholder", "deprecated"):
            continue
        maswe = meta.get("maswe") or []
        tests.append({
            "id": meta["id"],
            "origin": OWASP,
            "title": meta.get("title", ""),
            "platform": meta.get("platform", ""),
            "type": meta.get("type") or [],
            "maswe": [maswe] if isinstance(maswe, str) else maswe,
            "url": "https://mas.owasp.org/MASTG/tests/"
                   + str(path.relative_to(mastg / "tests-beta").with_suffix("")) + "/",
        })
    return tests


def load_demo_rules(mastg: Path) -> dict[str, list[str]]:
    """Which semgrep rule files MASTG itself uses for a test.

    Every MASTG demo names the test it demonstrates, and its run.sh shows the
    rule it runs. That gives test -> rule files without a list of our own.
    """
    rules: dict[str, set[str]] = defaultdict(set)
    for demo in (mastg / "demos").rglob("MASTG-DEMO-*.md"):
        test = front_matter(demo).get("test")
        script = demo.parent / "run.sh"
        if not test or not script.exists():
            continue
        tests = test if isinstance(test, list) else [test]
        for match in re.finditer(r"semgrep\s+(?:-c|--config)\s+(\S+)", script.read_text(errors="replace")):
            rule = mastg / "rules" / os.path.basename(match.group(1))
            if rule.exists():
                for test_id in tests:
                    rules[test_id].add(rule.name)
    return {test: sorted(files) for test, files in rules.items()}


def rule_ids(rule_file: Path) -> list[str]:
    return re.findall(r"^\s*-\s+id:\s*(\S+)", rule_file.read_text(errors="replace"), re.M)


# --- targets ----------------------------------------------------------------


def decompile(apk: Path, out: Path) -> Path:
    target = out / "jadx"
    stamp = target / ".apk-sha256"
    digest = hashlib.sha256(apk.read_bytes()).hexdigest()
    if stamp.exists() and stamp.read_text() == digest:
        return target
    if target.exists():
        shutil.rmtree(target)
    jadx = shutil.which("jadx")
    if not jadx:
        raise SystemExit("jadx is needed for --apk and is not on the PATH")
    log(f"Decompiling {apk.name} with jadx")
    # jadx exits non-zero when it could not decompile some methods; that is normal.
    run([jadx, "-q", "--no-debug-info", "-d", str(target), str(apk)])
    if not (target / "resources" / "AndroidManifest.xml").exists():
        raise SystemExit("jadx produced no AndroidManifest.xml")
    stamp.write_text(digest)
    return target


def unpack_ipa(ipa: Path, out: Path) -> Path:
    target = out / "ipa"
    stamp = target / ".ipa-sha256"
    digest = hashlib.sha256(ipa.read_bytes()).hexdigest()
    if stamp.exists() and stamp.read_text() == digest:
        return target
    if target.exists():
        shutil.rmtree(target)
    log(f"Unpacking {ipa.name}")
    with zipfile.ZipFile(ipa) as archive:
        archive.extractall(target)
    stamp.write_text(digest)
    return target


def semgrep(rule_files: list[Path], root: Path, targets: list[str]) -> list[dict]:
    """Runs semgrep once for all rules. Returns its findings."""
    command = shlex.split(os.environ.get("MASTG_SEMGREP", ""))
    if not command:
        command = ["semgrep"] if shutil.which("semgrep") else ["uvx", "semgrep"]
    # --project-root: without it semgrep takes the git repository as the project and
    # applies its default ignore list, which has build/. The decompiled code is in
    # build/mastg, so semgrep would then scan nothing and every rule would "pass".
    cmd = command + ["scan", "--json", "--quiet", "--metrics=off", "--no-git-ignore",
                     "--project-root", ".",
                     "--disable-version-check", "--timeout", "20", "--max-target-bytes", "3000000"]
    for rule in rule_files:
        cmd += ["--config", str(rule)]
    cmd += targets
    log(f"Running semgrep with {len(rule_files)} OWASP rule files on {', '.join(targets)}")
    result = run(cmd, cwd=root)
    try:
        output = json.loads(result.stdout)
    except json.JSONDecodeError:
        raise SystemExit(f"semgrep failed ({result.returncode}):\n{result.stderr[-2000:]}")
    scanned = len(output.get("paths", {}).get("scanned", []))
    if not scanned:
        raise SystemExit(f"semgrep scanned no files in {root}; refusing to report results")
    log(f"semgrep scanned {scanned} files")
    return output.get("results", [])


def fingerprint(check_id: str, text: str) -> str:
    """Identifies a finding by its check and the matched content, not by its place.

    Decompiled class names and line numbers change from build to build; the
    matched code does not. One decision covers every identical occurrence.
    """
    normalised = " ".join(text.split())
    return check_id + ":" + hashlib.sha1(normalised.encode()).hexdigest()[:12]


def finding(check_id: str, path: str, line: int | None, text: str) -> dict:
    text = " ".join(text.split())[:300]
    return {"check": check_id, "path": path, "line": line, "text": text,
            "fingerprint": fingerprint(check_id, text)}


# --- Yivi check engines -------------------------------------------------------


def expand(root: Path, patterns: list[str]) -> list[Path]:
    files: list[Path] = []
    for pattern in patterns:
        files += [Path(item) for item in glob.glob(str(root / pattern), recursive=True)]
    return sorted({item for item in files if item.is_file() and not item.is_symlink()})


MACHO_MAGIC = {b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xca\xfe\xba\xbf"}


def native_binaries(files: list[Path], kind: str) -> list[Path]:
    """The files that are ELF (kind "elf") or Mach-O (kind "macho") binaries."""
    selected = []
    for item in files:
        try:
            with open(item, "rb") as handle:
                magic = handle.read(4)
        except OSError:
            continue
        if (kind == "elf" and magic == b"\x7fELF") or (kind == "macho" and magic in MACHO_MAGIC):
            selected.append(item)
    return selected


def engine_regex(check: dict, root: Path) -> tuple[list[dict], int]:
    pattern = re.compile(check["pattern"], re.S if check.get("multiline") else 0)
    found, total = [], 0
    for item in expand(root, check["files"]):
        try:
            text = item.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for match in pattern.finditer(text):
            total += 1
            if len(found) < MAX_FINDINGS:
                line = text.count("\n", 0, match.start()) + 1
                found.append(finding(check["id"], str(item.relative_to(root)), line, match.group(0)))
    return found, total


def engine_binary(check: dict, root: Path) -> tuple[list[dict], int]:
    """Looks for names in native binaries.

    "symbols" are matched as whole, NUL-delimited strings, which is how imported
    functions, Objective-C selectors and section names are stored. "strings"
    match anywhere. With "report": "missing", a finding is a binary that has
    none of them.
    """
    needles = [b"\0" + name.encode() + b"\0" for name in check.get("symbols", [])]
    needles += [name.encode() for name in check.get("strings", [])]
    names = check.get("symbols", []) + check.get("strings", [])
    found = []
    for item in native_binaries(expand(root, check["files"]), check["binary"]):
        data = item.read_bytes()
        hits = [name for name, needle in zip(names, needles) if needle in data]
        relative = str(item.relative_to(root))
        if check.get("report") == "missing":
            if not hits:
                found.append(finding(check["id"], relative, None, f"{item.name}: none of {', '.join(names)}"))
        else:
            found += [finding(check["id"], relative, None, f"{item.name}: {name}") for name in hits]
    return found, len(found)


def engine_elf_pic(check: dict, root: Path) -> tuple[list[dict], int]:
    """A finding for every shared library that is not position independent (not ET_DYN)."""
    found = []
    for item in native_binaries(expand(root, check["files"]), "elf"):
        with open(item, "rb") as handle:
            header = handle.read(18)
        little = header[5] == 1
        e_type = int.from_bytes(header[16:18], "little" if little else "big")
        if e_type != 3:
            found.append(finding(check["id"], str(item.relative_to(root)), None, f"{item.name}: e_type {e_type}"))
    return found, len(found)


def engine_macho_pie(check: dict, root: Path) -> tuple[list[dict], int]:
    """A finding for every main executable (MH_EXECUTE) without the MH_PIE flag."""
    found = []
    for item in native_binaries(expand(root, check["files"]), "macho"):
        with open(item, "rb") as handle:
            header = handle.read(32)
        if header[:4] not in (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe"):
            continue  # a fat binary: not what CI builds
        filetype = int.from_bytes(header[12:16], "little")
        flags = int.from_bytes(header[24:28], "little")
        if filetype == 2 and not flags & 0x200000:
            found.append(finding(check["id"], str(item.relative_to(root)), None, f"{item.name}: no MH_PIE"))
    return found, len(found)


def plist_documents(item: Path) -> list:
    data = item.read_bytes()
    try:
        return [plistlib.loads(data)]
    except Exception:
        # A provisioning profile: a signed container with an XML plist inside.
        start, end = data.find(b"<?xml"), data.find(b"</plist>")
        if start >= 0 and end > start:
            try:
                return [plistlib.loads(data[start:end + len(b"</plist>")])]
            except Exception:
                return []
    return []


def engine_plist(check: dict, root: Path) -> tuple[list[dict], int]:
    """A finding when the key exists (and, with "equals", has that value)."""
    found = []
    for item in expand(root, check["files"]):
        for document in plist_documents(item):
            value = document
            for part in check["key"].split("/"):
                value = value.get(part) if isinstance(value, dict) else None
                if value is None:
                    break
            if value is None or ("equals" in check and value != check["equals"]):
                continue
            shown = json.dumps(value, default=str, sort_keys=True)
            found.append(finding(check["id"], str(item.relative_to(root)), None, f"{check['key']} = {shown}"))
    return found, len(found)


ENGINES = {
    "regex": engine_regex,
    "binary": engine_binary,
    "elf-pic": engine_elf_pic,
    "macho-pie": engine_macho_pie,
    "plist": engine_plist,
}


# --- verdicts ---------------------------------------------------------------


def judge(found: list[dict], total: int, mode: str, decisions: dict) -> dict:
    """The status of one check.

      absent   a finding is a defect, unless a triage decision accepts it
      present  a finding shows a protection; none at all is a failure
      triage   a finding is an observation that needs a decision
    """
    if mode == "present":
        if total:
            return {"status": PASS, "detail": f"{total} protection(s) found", "issues": [], "open": [],
                    "count": total, "protections": total}
        return {"status": FAIL, "detail": "the protection it looks for was not found", "issues": [], "open": [],
                "count": 0, "missing_only": True}
    issues, open_findings, accepted = [], [], 0
    for item in found:
        decision = decisions.get(item["fingerprint"], {}).get("decision")
        if decision == "ok":
            accepted += 1
        elif decision == "issue" or mode == "absent":
            issues.append(item)
        else:
            open_findings.append(item)
    status = FAIL if issues else TRIAGE if open_findings else PASS
    detail = f"{accepted} finding(s) accepted in triage.json" if accepted else ""
    return {"status": status, "detail": detail, "issues": issues, "open": open_findings, "count": total}


def owasp_rule_check(rule_file: str, mastg: Path, findings_by_rule: dict, config: dict, decisions: dict) -> dict:
    """One OWASP rule file as a check. Its rules can be of different kinds."""
    modes = config["rule_modes"]
    ref = config["mastg"]["ref"]
    result = {
        "id": rule_file,
        "origin": OWASP,
        "engine": "semgrep",
        "title": "OWASP MASTG semgrep rule, run unchanged",
        "source_url": f"https://github.com/OWASP/mastg/blob/{ref}/rules/{rule_file}",
        "target": "apk",
    }
    ordinary, present_ids, present_total, count = [], [], 0, 0
    for rule_id in rule_ids(mastg / "rules" / rule_file):
        found = findings_by_rule.get(rule_id, [])
        count += len(found)
        if modes.get(rule_id) == "present":
            present_ids.append(rule_id)
            present_total += len(found)
        else:
            ordinary.append((modes.get(rule_id, "triage"), found))
    issues, open_findings, details = [], [], []
    for mode, found in ordinary:
        verdict = judge(found, len(found), mode, decisions)
        issues += verdict["issues"]
        open_findings += verdict["open"]
        if verdict["detail"]:
            details.append(verdict["detail"])
    missing = bool(present_ids) and present_total == 0
    if missing:
        details.append("none of the protections it looks for was found")
    elif present_total:
        details.append(f"{present_total} protection(s) found")
    status = FAIL if issues or missing else TRIAGE if open_findings else PASS
    result.update(status=status, detail="; ".join(details), issues=issues, open=open_findings, count=count)
    if missing and not issues:
        result["missing_only"] = True
        result["fallback"] = TRIAGE if open_findings else PASS
    if present_total:
        result["protections"] = present_total
    return result


def yivi_check(check: dict, roots: dict, decisions: dict, repo_url: str, commit: str, source_file: str) -> dict | None:
    """One of our own checks. None when its target is not available in this run."""
    root = roots.get(check["target"])
    if root is None:
        return None
    found, total = ENGINES[check["engine"]](check, root)
    verdict = judge(found, total, check.get("mode", "triage"), decisions)
    return {
        "id": check["id"],
        "origin": YIVI,
        "engine": check["engine"],
        "title": check.get("title", ""),
        "source_url": f"{repo_url}/blob/{commit}/mastg/{source_file}",
        "target": check["target"],
        **verdict,
    }


def combine(entry: dict, checks: list[dict], override: dict | None) -> None:
    """The status of a test: the worst status of its checks.

    OWASP's tests that look for a protection fail when the app has it nowhere. So a
    check that did not find the protection does not fail the test when another
    check of the same test did find it.
    """
    entry["checks"] = checks
    if entry["origin"] == OWASP and any(check.get("protections") for check in checks):
        for check in checks:
            if check.get("missing_only"):
                check["status"] = check.get("fallback", PASS)
                check["detail"] = "did not find the protection itself; another check of this test did"
    if checks:
        entry["status"] = max((check["status"] for check in checks), key=lambda status: SEVERITY[status])
    if override:
        entry["status"] = override["status"]
        entry["recorded"] = override.get("reason", "")


def build_results(profile, owasp_tests, demo_rules, mastg, findings_by_rule, roots, config, triage,
                  yivi_checks, yivi_tests, repo_url, commit) -> dict:
    decisions = triage.get("findings", {})
    overrides = triage.get("tests", {})
    docs = config["docs_url"]
    by_maswe = defaultdict(list)
    for test in owasp_tests:
        for maswe in test["maswe"]:
            by_maswe[maswe].append(test)
    own_checks = defaultdict(list)
    for check in yivi_checks:
        own_checks[check["test"]].append(check)

    tests: dict[str, dict] = {}
    requirements = []
    for requirement in profile["requirements"]:
        ids = []
        for test in by_maswe.get(requirement["maswe"], []):
            ids.append(test["id"])
            if test["id"] in tests:
                tests[test["id"]]["requirements"].append(requirement["number"])
                continue
            entry = dict(test, requirements=[requirement["number"]], status=NOT_AUTOMATED, checks=[],
                         docs_url=f"{docs}#{anchor(test['id'])}")
            checks = []
            if findings_by_rule is not None and test["platform"] == "android":
                checks += [owasp_rule_check(rule, mastg, findings_by_rule, config, decisions)
                           for rule in demo_rules.get(test["id"], [])]
            for check in own_checks.get(test["id"], []):
                result = yivi_check(check, roots, decisions, repo_url, commit, "yivi-checks.json")
                if result:
                    checks.append(result)
            combine(entry, checks, overrides.get(test["id"]))
            tests[test["id"]] = entry
        requirements.append(dict(requirement, tests=ids, yivi_tests=[],
                                 docs_url=f"{docs}#req-{requirement['number']}"))

    by_number = {requirement["number"]: requirement for requirement in requirements}
    for test in yivi_tests:
        entry = {
            "id": test["id"], "origin": YIVI, "title": test["title"], "platform": test.get("platform", "all"),
            "type": test.get("type", ["static"]), "description": test.get("description", ""),
            "requirements": test["requirements"], "status": NOT_AUTOMATED, "checks": [],
            "url": f"{repo_url}/blob/{commit}/mastg/yivi-tests.json",
            "docs_url": f"{docs}#{anchor(test['id'])}",
        }
        checks = []
        for check in test["checks"]:
            result = yivi_check(check, roots, decisions, repo_url, commit, "yivi-tests.json")
            if result:
                checks.append(result)
        if len(checks) == len(test["checks"]):
            combine(entry, checks, overrides.get(test["id"]))
        else:
            combine(entry, [], overrides.get(test["id"]))
        tests[test["id"]] = entry
        for number in test["requirements"]:
            by_number[number]["yivi_tests"].append(test["id"])
    return {"requirements": requirements, "tests": tests}


# --- report -----------------------------------------------------------------


def score(tests: list[dict]) -> dict:
    counts = Counter(test["status"] for test in tests)
    total = len(tests)
    resolved = sum(counts[status] for status in RESOLVED)
    automated = total - counts[NOT_AUTOMATED]
    return {
        "tests": total,
        "resolved": resolved,
        "score": round(100 * resolved / total, 1) if total else 0.0,
        "automated": automated,
        "automation": round(100 * automated / total, 1) if total else 0.0,
        "by_status": {status: counts[status] for status in STATUSES},
    }


def checked_by(tests: list[dict]) -> dict:
    """How the automated OWASP tests are checked: by OWASP's rules, by ours, or both."""
    counts = Counter()
    for test in tests:
        origins = {check["origin"] for check in test["checks"]}
        if origins == {OWASP}:
            counts["owasp_checks_only"] += 1
        elif origins == {YIVI}:
            counts["yivi_checks_only"] += 1
        elif origins:
            counts["both"] += 1
        elif test["status"] != NOT_AUTOMATED:
            counts["recorded_verdict"] += 1
    return dict(counts)


def delta(now: float, before: float | None) -> str:
    if before is None:
        return ""
    change = round(now - before, 1)
    if change == 0:
        return " (no change against the baseline)"
    return f" ({'+' if change > 0 else ''}{change} against the baseline)"


def cell(text: str) -> str:
    return text.replace("|", "\\|").replace("\n", " ")


def origin_label(test: dict) -> str:
    return "OWASP test" if test["origin"] == OWASP else "Yivi test"


def summary(results: dict, totals: dict, baseline: dict | None, meta: dict) -> str:
    tests, requirements = results["tests"], results["requirements"]
    owasp = [test for test in tests.values() if test["origin"] == OWASP]
    own = [test for test in tests.values() if test["origin"] == YIVI]
    base = baseline or {}
    by = totals["owasp_checked_by"]
    lines = [
        "# OWASP MAS EUDI Wallet profile: test bed",
        "",
        "## OWASP tests",
        "",
        f"**Score: {totals['owasp']['score']}%**{delta(totals['owasp']['score'], base.get('owasp', {}).get('score'))}: "
        f"{totals['owasp']['resolved']} of {totals['owasp']['tests']} OWASP MASTG tests in the profile are resolved "
        "(pass or not applicable).",
        "",
        f"**Automation: {totals['owasp']['automation']}%**"
        f"{delta(totals['owasp']['automation'], base.get('owasp', {}).get('automation'))}: "
        f"{totals['owasp']['automated']} of {totals['owasp']['tests']} have a check or a recorded verdict. "
        f"{by.get('owasp_checks_only', 0)} are checked by OWASP's own rules only, "
        f"{by.get('yivi_checks_only', 0)} by our own checks only, {by.get('both', 0)} by both, "
        f"and {by.get('recorded_verdict', 0)} have a recorded verdict without a check.",
        "",
        "| Status | Android | iOS | Other | Total |",
        "|---|---|---|---|---|",
    ]
    for status in STATUSES:
        row = Counter(test["platform"] if test["platform"] in ("android", "ios") else "other"
                      for test in owasp if test["status"] == status)
        lines.append(f"| {LABEL[status]} | {row['android']} | {row['ios']} | {row['other']} | {sum(row.values())} |")

    lines += [
        "",
        "## Yivi tests",
        "",
        "Our own tests for requirements. They are not OWASP tests and are not part of the score above.",
        "",
        f"**{totals['yivi']['resolved']} of {totals['yivi']['tests']} resolved**"
        f"{delta(totals['yivi']['score'], base.get('yivi', {}).get('score'))}.",
        "",
        "| Test | Requirement | Status |",
        "|---|---|---|",
    ]
    for test in sorted(own, key=lambda item: item["id"]):
        numbers = ", ".join(f"#{number}" for number in test["requirements"])
        lines.append(f"| [{test['id']}]({test['docs_url']}) {cell(test['title'])} | {numbers} | {LABEL[test['status']]} |")

    lines += [
        "",
        f"Tested: {meta['target']}. App commit `{meta['commit'][:12]}`, MASTG commit `{meta['mastg_ref'][:12]}`. "
        "This overview reports; it does not fail the build.",
        "",
        "## Requirements",
        "",
        "The number links to the requirement in the Yivi documentation. Counts are OWASP tests; "
        "the last column counts our own tests.",
        "",
        "| # | Requirement | OWASP tests | Pass | N/A | Fail | To triage | Not automated | Yivi tests |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    without = 0
    for requirement in requirements:
        counts = Counter(tests[test_id]["status"] for test_id in requirement["tests"])
        if not requirement["tests"]:
            without += 1
        numbers = [counts[status] or "" for status in STATUSES]
        own_done = sum(1 for test_id in requirement["yivi_tests"] if tests[test_id]["status"] in RESOLVED)
        own_text = f"{own_done} of {len(requirement['yivi_tests'])} resolved" if requirement["yivi_tests"] else ""
        lines.append(f"| [{requirement['number']}]({requirement['docs_url']}) | {cell(requirement['title'])} | "
                     f"{len(requirement['tests']) or '–'} | " + " | ".join(str(number) for number in numbers)
                     + f" | {own_text} |")
    lines += ["", f"{without} of {len(requirements)} requirements have no OWASP MASTG test."]

    def block(title: str, status: str, key: str, intro: str) -> None:
        selected = [test for test in tests.values() if test["status"] == status]
        if not selected:
            return
        lines.extend(["", f"## {title}", "", intro, ""])
        for test in sorted(selected, key=lambda item: item["id"]):
            numbers = ", ".join(f"#{number}" for number in test["requirements"])
            original = f", [original on mas.owasp.org]({test['url']})" if test["origin"] == OWASP else ""
            lines.append(f"- {origin_label(test)} [{test['id']}]({test['docs_url']}) {test['title']} ({numbers}{original})")
            for check in test["checks"]:
                if check["status"] != status:
                    continue
                who = "OWASP check" if check["origin"] == OWASP else "Yivi check"
                lines.append(f"  - {who} [`{check['id']}`]({check['source_url']})"
                             + (f": {check['detail']}" if check["detail"] else ""))
                for item in check[key][:3]:
                    place = item["path"] + (f":{item['line']}" if item["line"] else "")
                    lines.append(f"    - `{place}` `{cell(item['text'][:110])}` (`{item['fingerprint']}`)")
                if len(check[key]) > 3:
                    lines.append(f"    - and {check['count'] - 3} more, see `results.json`")

    block("Failing tests", FAIL, "issues",
          "A check found a defect, or did not find the protection it looks for. "
          "Fix it, or record why it is acceptable in `mastg/triage.json`.")
    block("Tests to triage", TRIAGE, "open",
          "A check found something a person has to judge. Record the decision for each "
          "fingerprint in `mastg/triage.json`; `triage-todo.json` has them ready to copy.")

    todo = [test for test in owasp if test["status"] == NOT_AUTOMATED]
    lines += ["", "## OWASP tests not automated yet", "",
              "Each of these is a step up for the automation score.", "",
              "| Kind of test | Android | iOS | Other |", "|---|---|---|---|"]
    kinds = defaultdict(Counter)
    for test in todo:
        kind = "static" if "static" in test["type"] else "dynamic" if "dynamic" in test["type"] else "other"
        kind += ", with a manual verdict" if "manual" in test["type"] else ""
        kinds[kind][test["platform"] if test["platform"] in ("android", "ios") else "other"] += 1
    for kind in sorted(kinds):
        lines.append(f"| {kind} | {kinds[kind]['android']} | {kinds[kind]['ios']} | {kinds[kind]['other']} |")
    lines.append("")
    return "\n".join(lines)


def for_docs(data: dict) -> dict:
    """The results without the bulk: at most three findings per check."""
    slim = json.loads(json.dumps(data))
    for test in slim["tests"].values():
        for check in test["checks"]:
            for key in ("issues", "open"):
                check[key + "_count"] = len(check[key])
                check[key] = check[key][:3]
    return slim


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apk", type=Path, help="APK to decompile and test (needs jadx)")
    parser.add_argument("--decompiled", type=Path, help="an APK already decompiled by jadx")
    parser.add_argument("--ipa", type=Path, help="IPA to unpack and test")
    parser.add_argument("--unpacked-ipa", type=Path, help="an IPA already unpacked")
    parser.add_argument("--mastg-dir", type=Path, help="a MASTG checkout to use instead of fetching the pinned one")
    parser.add_argument("--out", type=Path, default=REPO / "build" / "mastg")
    parser.add_argument("--write-baseline", action="store_true", help="store the score in mastg/baseline.json")
    args = parser.parse_args()

    config = read_json(HERE / "config.json")
    profile = read_json(HERE / "eudiw-profile.json")
    triage = read_json(HERE / "triage.json", {})
    baseline = read_json(HERE / "baseline.json")
    yivi_checks = read_json(HERE / "yivi-checks.json", {"checks": []})["checks"]
    yivi_tests = read_json(HERE / "yivi-tests.json", {"tests": []})["tests"]
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)

    repo_url = config["repository_url"]
    commit = os.environ.get("GITHUB_SHA") or run(["git", "-C", str(REPO), "rev-parse", "HEAD"]).stdout.strip()
    mastg = args.mastg_dir.resolve() if args.mastg_dir else fetch_mastg(config, out)
    owasp_tests = load_owasp_tests(mastg)
    demo_rules = load_demo_rules(mastg)

    roots: dict[str, Path] = {"source": REPO}
    tested = ["the sources"]
    if args.apk or args.decompiled:
        roots["apk"] = args.decompiled.resolve() if args.decompiled else decompile(args.apk.resolve(), out)
        tested.append(f"the decompiled APK `{args.apk.name}`" if args.apk else "an APK decompiled by jadx")
    if args.ipa or args.unpacked_ipa:
        roots["ipa"] = args.unpacked_ipa.resolve() if args.unpacked_ipa else unpack_ipa(args.ipa.resolve(), out)
        tested.append(f"the IPA `{args.ipa.name}`" if args.ipa else "an unpacked IPA")

    in_profile = {requirement["maswe"] for requirement in profile["requirements"]}
    wanted = sorted({rule for test in owasp_tests if set(test["maswe"]) & in_profile and test["platform"] == "android"
                     for rule in demo_rules.get(test["id"], [])})

    # OWASP's rules are written for decompiled code. Without an APK they run on the sources.
    if "apk" in roots:
        semgrep_root, targets = roots["apk"], ["sources", "resources/AndroidManifest.xml", "resources/res/xml"]
    else:
        semgrep_root, targets = REPO, config["source"]["targets"]
    targets = [item for item in targets if (semgrep_root / item).exists()]
    found = semgrep([mastg / "rules" / rule for rule in wanted], semgrep_root, targets)
    known = {rule_id for rule in wanted for rule_id in rule_ids(mastg / "rules" / rule)}
    cache: dict = {}
    findings_by_rule = defaultdict(list)
    for item in found:
        # semgrep prefixes the rule id with the folders of the rule file
        rule_id = next((rule for rule in known if item["check_id"] == rule
                        or item["check_id"].endswith("." + rule)), None)
        if not rule_id:
            continue
        path = item["path"]
        if path not in cache:
            try:
                cache[path] = (semgrep_root / path).read_bytes()
            except OSError:
                cache[path] = b""
        text = cache[path][item["start"]["offset"]:item["end"]["offset"]].decode("utf-8", errors="replace")
        findings_by_rule[rule_id].append(finding(rule_id, path, item["start"]["line"], text))

    results = build_results(profile, owasp_tests, demo_rules, mastg, findings_by_rule, roots, config, triage,
                            yivi_checks, yivi_tests, repo_url, commit)
    owasp = [test for test in results["tests"].values() if test["origin"] == OWASP]
    own = [test for test in results["tests"].values() if test["origin"] == YIVI]
    totals = {"owasp": score(owasp), "owasp_checked_by": checked_by(owasp), "yivi": score(own)}
    run_url = ""
    if os.environ.get("GITHUB_RUN_ID"):
        run_url = f"{os.environ.get('GITHUB_SERVER_URL', 'https://github.com')}/" \
                  f"{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/{os.environ['GITHUB_RUN_ID']}"
    meta = {
        "target": ", ".join(tested),
        "date": datetime.date.today().isoformat(),
        "repository_url": repo_url,
        "commit": commit,
        "run_url": run_url,
        "mastg_ref": config["mastg"]["ref"],
        "profile": profile["version"],
        "docs_url": config["docs_url"],
    }
    data = {"meta": meta, "score": totals, **results}

    write_json(out / "results.json", data)
    write_json(out / "docs-results.json", for_docs(data))
    todo = {}
    for test in results["tests"].values():
        for check in test["checks"]:
            for item in check["open"] + check["issues"]:
                todo.setdefault(item["fingerprint"], {
                    "decision": "", "reason": "", "test": test["id"], "match": item["text"],
                    "seen_at": item["path"] + (f":{item['line']}" if item["line"] else ""),
                })
    write_json(out / "triage-todo.json", {"findings": todo})
    text = summary(results, totals, baseline, meta)
    (out / "summary.md").write_text(text, encoding="utf-8")
    if args.write_baseline:
        write_json(HERE / "baseline.json", totals)

    step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if step_summary:
        with open(step_summary, "a", encoding="utf-8") as handle:
            handle.write(text)
    print(f"OWASP tests: score {totals['owasp']['score']}% ({totals['owasp']['resolved']}/{totals['owasp']['tests']}), "
          f"automation {totals['owasp']['automation']}%. Yivi tests: {totals['yivi']['resolved']}/{totals['yivi']['tests']}. "
          f"Overview: {out / 'summary.md'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
