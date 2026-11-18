# OWASP MAS EUDI Wallet profile: test bed

Runs the [OWASP MASTG tests](https://mas.owasp.org/MASTG/tests/) that belong to the
[OWASP MAS EUDI Wallet profile](https://mas.owasp.org/Profiles/MAS-EUDIW/) against the
app, next to tests of our own, and writes a score with an overview. The score is meant
to be raised step by step. The test bed never fails a build because of the score.

The results are published in the Yivi documentation:
[test results](https://docs.yivi.app/edi-stelsel-certification/conformance/owasp-mas-eudiw-tests).

## What is from OWASP and what is ours

Everything in the output carries one of these labels.

| Label | Where it comes from | Defined in |
|---|---|---|
| OWASP test | A test of the OWASP MASTG. The test and its pass criterion are OWASP's | The MASTG repository, at the commit in `config.json` |
| OWASP check | A semgrep rule of the MASTG, run unchanged | The MASTG repository, `rules/` |
| Yivi check | Our own automation of an OWASP test. OWASP did not write or review it | `yivi-checks.json` |
| Yivi test | Our own test for a requirement, not an OWASP test | `yivi-tests.json` |

OWASP tests and Yivi tests are scored apart. The headline score counts OWASP tests
only; it also says how many of them are checked by OWASP's rules and how many by ours.

Two things about OWASP tests are our own choice and not OWASP's:

- How a finding of an OWASP rule becomes a verdict (`rule_modes` in `config.json`).
- The decisions in `triage.json`.

## Run it

```sh
python3 mastg/testbed.py --apk path/to/app.apk --ipa path/to/app.ipa
python3 mastg/testbed.py                         # quick: the sources only
```

It needs Python 3.9 or later, `git`, [semgrep](https://semgrep.dev) (or `uvx`, which
then fetches it) and, for `--apk`, [jadx](https://github.com/skylot/jadx). Set
`MASTG_SEMGREP` to run semgrep in another way, for example
`MASTG_SEMGREP="pipx run --spec semgrep==1.186.0 semgrep"`.

The output goes to `build/mastg/`:

| File | What it is |
|---|---|
| `summary.md` | The score and the overview, also shown as the summary of the CI job |
| `results.json` | Every requirement, test, check, status and finding |
| `docs-results.json` | The same with at most three findings per check, for the documentation |
| `triage-todo.json` | The findings without a decision, ready to copy into `triage.json` |

Test the builds when you can. The OWASP rules are written for decompiled code, and the
APK also has the merged manifest and the code of the plugins and libraries. Without
builds, only the OWASP rules (on the Android sources) and the Yivi tests run.

## How it works

1. `eudiw-profile.json` lists the 78 requirements of the profile with the weakness
   (MASWE) each one belongs to.
2. The MASTG repository is fetched at the commit in `config.json`. Every MASTG test
   names its weaknesses, which gives the OWASP tests per requirement.
3. Every MASTG demo names the test it demonstrates and the semgrep rule it runs. That
   gives the OWASP checks per test, without a list of our own.
4. `yivi-checks.json` adds our own checks to OWASP tests, and `yivi-tests.json` adds
   our own tests to requirements.
5. Every check runs on its target and gets a status. A test gets the worst status of
   its checks.

| Status | Meaning | Counts for the score |
|---|---|---|
| Pass | The check ran and found no problem | yes |
| Not applicable | Recorded in `triage.json`, with a reason | yes |
| Fail | A check found a defect, or did not find the protection it looks for | no |
| To triage | A check found something a person has to judge | no |
| Not automated | No check runs for this test yet | no |

**Score** is the share of OWASP tests that pass or are not applicable. **Automation**
is the share of OWASP tests that have a check or a recorded verdict.

A check is one of three kinds (`mode`; for OWASP rules `rule_modes` in `config.json`):

- `absent`: a finding is a defect, such as a broken cipher.
- `present`: a finding shows a protection, such as `FLAG_SECURE`. No finding is a failure.
- `triage`: a finding is an observation. This is the kind of an OWASP rule that is not listed.

## Write a Yivi check or a Yivi test

A Yivi check automates one OWASP test and goes in `yivi-checks.json`, with the
identifier of that test in `test`. A Yivi test goes in `yivi-tests.json`, with the
numbers of the requirements it covers and one or more checks. Say in `title` what a
finding means: the documentation shows that text.

| Field | Meaning |
|---|---|
| `target` | `apk` (decompiled by jadx), `ipa` (unpacked) or `source` (this repository) |
| `files` | Glob patterns below the target |
| `mode` | `absent`, `present` or `triage` |
| `engine` | How it looks, see below |

| Engine | Finds | Extra fields |
|---|---|---|
| `regex` | Matches of a regular expression in text files | `pattern`, `multiline` |
| `binary` | Names in native binaries. With `"report": "missing"`: binaries that have none of them | `binary` (`elf` or `macho`), `symbols` (whole names), `strings` (anywhere) |
| `elf-pic` | Android native libraries that are not position independent | |
| `macho-pie` | iOS main executables that are not position independent | |
| `plist` | A key in a property list, also in a provisioning profile | `key` (path with `/`), `equals` |

## Raise the score

- **Triage a finding.** Copy its entry from `triage-todo.json` to `findings` in
  `triage.json`, and set `decision` to `ok` or `issue`, with a `reason`. A finding is
  known by its check and the matched content, not by its file and line, so a decision
  holds across builds and covers every identical occurrence.
- **Record a verdict for a test** that a tool cannot decide, or that does not apply,
  under `tests` in `triage.json`:
  `"MASTG-TEST-0250": {"status": "not_applicable", "reason": "The app has no WebView."}`.
  The status is `pass`, `fail` or `not_applicable`.
- **Fix the defect** that a failing test points at.
- **Automate a test** that is "Not automated", with a Yivi check.
- **Update MASTG**: change `mastg.ref` in `config.json`. New tests and rules are
  picked up by themselves.

After a change that moves the score, store it with `--write-baseline`. The overview
shows the difference with `baseline.json`.

## Link to the documentation

Every requirement and every test in the results has a `docs_url`, which points to its
anchor on the test results page of the documentation: `#req-26` for a requirement,
`#mastg-test-0204` for an OWASP test and `#yivi-test-0001` for a Yivi test. The base
address is `docs_url` in `config.json`.

To update that page: copy `docs-results.json` of a CI run to
`yivi-docs/src/data/edi-stelsel/mastg-results.json` in
[irma-documentation](https://github.com/privacybydesign/irma-documentation) and run
`python3 tools/mastg_test_results.py` there. Take the file from a run on `master`, so
that its links to this repository point to a commit that exists.

## What it does not cover yet

- Dynamic tests, which need a device or emulator with instrumentation.
- The Dart and Go code, except where a Yivi test reads the sources. It is compiled to
  machine code, and the OWASP rules read Java and XML.
- The iOS checks look for names in the binaries. They show that an API is used, not how.
- Requirements without an OWASP test that have no Yivi test yet.
