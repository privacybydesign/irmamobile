// Merges the per-ecosystem CycloneDX SBOMs from generate_sbom.sh into a single SBOM for yivi_app.
// See generate_sbom.sh for usage; all inputs are passed as named arguments by that script.
import crypto from "node:crypto";
import fs from "node:fs";
import { parseArgs } from "node:util";

const { values: args, positionals: inputs } = parseArgs({
  allowPositionals: true,
  options: {
    out: { type: "string" },
    version: { type: "string" },
    "go-linked": { type: "string" },
    "pub-deps": { type: "string" },
    "pubspec-lock": { type: "string" },
    "podfile-lock": { type: "string" },
    "sqlcipher-version": { type: "string" },
    "sqlcipher-sha256": { type: "string" },
    "openssl-version": { type: "string" },
  },
});

const PURL_GOLANG = "pkg:golang/";
const PURL_PUB = "pkg:pub/";
const PURL_COCOAPODS = "pkg:cocoapods/";

// SPDX licence identifiers we recognise in package metadata (matched case-insensitively), and other
// spellings of them. GPL-3.0 is what GitHub reports for a plain GPLv3 licence file.
const SPDX_IDS = [
  "0BSD", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "BSL-1.0", "CC0-1.0", "GPL-2.0-only", "GPL-3.0",
  "GPL-3.0-only", "GPL-3.0-or-later", "ISC", "LGPL-2.1-only", "LGPL-3.0-only", "MIT", "MPL-2.0", "Unlicense", "Zlib",
];
const LICENSE_ALIASES = { "apache": "Apache-2.0", "apache 2.0": "Apache-2.0", "apache license, version 2.0": "Apache-2.0" };
// Licences for components whose package metadata does not declare one, by purl prefix.
const ML_KIT_TERMS = { name: "ML Kit Terms of Service", url: "https://developers.google.com/ml-kit/terms" };
const KNOWN_LICENSES = [
  // The Flutter engine, shipped as a pod on iOS and as Maven artifacts on Android.
  ["pkg:cocoapods/Flutter@", { id: "BSD-3-Clause" }],
  ["pkg:maven/io.flutter/", { id: "BSD-3-Clause" }],
  // https://github.com/firebase/firebase-android-sdk
  ["pkg:maven/com.google.firebase/firebase-", { id: "Apache-2.0" }],
  // Closed source. The podspecs only say "Copyright Google LLC"; the Android POMs name the terms.
  ["pkg:cocoapods/GoogleMLKit@", ML_KIT_TERMS],
  ["pkg:cocoapods/MLImage@", ML_KIT_TERMS],
  ["pkg:cocoapods/MLKit", ML_KIT_TERMS],
  ["pkg:maven/com.google.mlkit/", ML_KIT_TERMS],
  // Closed source; the Regula podspecs declare a commercial licence.
  ["pkg:maven/com.regula.", { name: "Proprietary (commercial)" }],
];

const goLinked = new Set(fs.readFileSync(args["go-linked"], "utf8").trim().split("\n"));
const pubDeps = JSON.parse(fs.readFileSync(args["pub-deps"], "utf8"));
const devOnlyPubPackages = findDevOnlyPubPackages(pubDeps);
const pubSources = new Map(pubDeps.packages.map((p) => [p.name, p.source]));
const pubGitUrls = parsePubGitUrls(fs.readFileSync(args["pubspec-lock"], "utf8").replace(/\r\n/g, "\n"));
const podSpecRepos = parsePodSpecRepos(fs.readFileSync(args["podfile-lock"], "utf8").replace(/\r\n/g, "\n"));

const app = {
  type: "application",
  "bom-ref": `pkg:generic/foundation.privacybydesign/yivi-app@${args.version}`,
  group: "foundation.privacybydesign",
  name: "yivi-app",
  version: args.version,
  purl: `pkg:generic/foundation.privacybydesign/yivi-app@${args.version}`,
  supplier: { name: "Yivi", url: ["https://yivi.app"] },
  externalReferences: [{ type: "vcs", url: "https://github.com/privacybydesign/irmamobile" }],
};

const components = new Map();
const dependencies = new Map();
const appDependsOn = new Set();
const tools = [];

for (const file of inputs) {
  const bom = JSON.parse(fs.readFileSync(file, "utf8"));
  tools.push(...(bom.metadata?.tools?.components ?? []));
  // Every scan has its own root (the yivi pub package, the Go module, the Podfile, the Gradle
  // project). Those are all the app itself, so their direct dependencies move to the app.
  const scanRoot = bom.metadata?.component?.["bom-ref"];
  for (const c of bom.components ?? []) {
    delete c.components;
    if (c["bom-ref"] === scanRoot || !keepComponent(c)) continue;
    if (!components.has(c["bom-ref"])) components.set(c["bom-ref"], c);
  }
  for (const d of bom.dependencies ?? []) {
    const merged = new Set([...(dependencies.get(d.ref)?.dependsOn ?? []), ...(d.dependsOn ?? [])]);
    dependencies.set(d.ref, { ref: d.ref, dependsOn: [...merged] });
  }
  if (!scanRoot) continue;
  for (const ref of dependencies.get(scanRoot)?.dependsOn ?? []) appDependsOn.add(ref);
  dependencies.delete(scanRoot);
}

addAndroidNativeLibraries();
await addLicenses();

dependencies.set(app["bom-ref"], { ref: app["bom-ref"], dependsOn: [...appDependsOn] });
// Drop dependency entries and references for components that were filtered out above.
for (const [ref, d] of dependencies) {
  if (ref !== app["bom-ref"] && !components.has(ref)) {
    dependencies.delete(ref);
  } else {
    d.dependsOn = [...new Set(d.dependsOn.filter((dep) => components.has(dep)))].sort();
  }
}

const bom = {
  bomFormat: "CycloneDX",
  specVersion: "1.6",
  serialNumber: `urn:uuid:${crypto.randomUUID()}`,
  version: 1,
  metadata: {
    timestamp: new Date().toISOString(),
    tools: { components: [...new Map(tools.map((t) => [`${t.name}@${t.version}`, t])).values()] },
    component: app,
  },
  components: [...components.values()].sort((a, b) => a["bom-ref"].localeCompare(b["bom-ref"])),
  dependencies: [...dependencies.values()].sort((a, b) => a.ref.localeCompare(b.ref)),
};
fs.writeFileSync(args.out, JSON.stringify(bom, null, 2) + "\n");

const unlicensed = bom.components.filter((c) => !c.licenses?.length).map((c) => c.purl);
console.log(`Wrote ${bom.components.length} components to ${args.out}`);
if (unlicensed.length) console.log(`No licence found for ${unlicensed.length} components:\n  ${unlicensed.join("\n  ")}`);

function keepComponent(c) {
  const purl = c.purl ?? "";
  if (purl.startsWith(PURL_GOLANG)) {
    // cdxgen marks indirect modules as optional, even though they are compiled into the bridge.
    // go-linked holds the modules irmagobridge links, so use that instead.
    const module = decodeURIComponent(purl.slice(PURL_GOLANG.length).split("?")[0]);
    if (!goLinked.has(module)) return false;
    c.scope = "required";
  }

  // pubspec.lock cannot tell dev and runtime dependencies apart: transitive dev dependencies look
  // like any other, and packages that yivi_core needs at runtime but yivi_app also lists under
  // dev_dependencies are marked "direct dev". So the pub dependency graph decides instead. Flutter
  // plugins also show up as pods with the same name, and dev-only plugins are not part of the release.
  if (purl.startsWith(PURL_PUB) || purl.startsWith(PURL_COCOAPODS)) {
    if (devOnlyPubPackages.has(c.name)) return false;
    if (purl.startsWith(PURL_PUB)) c.scope = "required";
  }
  return true;
}

// Returns the packages in `flutter pub deps --json` output that are only reachable through dev dependencies.
function findDevOnlyPubPackages(pubDeps) {
  const packages = new Map(pubDeps.packages.map((p) => [p.name, p]));
  const root = pubDeps.packages.find((p) => p.kind === "root");
  const runtime = new Set();
  const todo = [...root.directDependencies];
  while (todo.length) {
    const name = todo.pop();
    if (runtime.has(name)) continue;
    runtime.add(name);
    todo.push(...(packages.get(name)?.dependencies ?? []));
  }
  return new Set(pubDeps.packages.filter((p) => p.kind !== "root" && !runtime.has(p.name)).map((p) => p.name));
}

// Maps every pod from the SPEC REPOS section of a Podfile.lock to the spec repo it came from.
// Pods that are not listed there are local (Flutter plugins).
function parsePodSpecRepos(podfileLock) {
  const repos = new Map();
  const section = podfileLock.split(/^SPEC REPOS:$/m)[1]?.split(/^\S/m)[0] ?? "";
  let repo;
  for (const line of section.split("\n")) {
    const repoMatch = line.match(/^  "?([^"]+?)"?:$/);
    const podMatch = line.match(/^    - "?([^"]+?)"?$/);
    if (repoMatch) repo = repoMatch[1];
    else if (podMatch) repos.set(podMatch[1], repo);
  }
  return repos;
}

// On Android, bind_go.sh links prebuilt SQLCipher and OpenSSL static libraries into the Go bridge.
// No package manager knows about them, so they are declared here.
function addAndroidNativeLibraries() {
  const sqlcipherVersion = args["sqlcipher-version"];
  const opensslVersion = args["openssl-version"];
  const sqlcipher = {
    type: "library",
    "bom-ref": `pkg:github/sqlcipher/sqlcipher@v${sqlcipherVersion}`,
    name: "sqlcipher",
    version: sqlcipherVersion,
    description: "Statically linked into the Android Go bridge (libgojni.so)",
    scope: "required",
    licenses: [{ license: { id: "BSD-3-Clause" } }],
    purl: `pkg:github/sqlcipher/sqlcipher@v${sqlcipherVersion}`,
    externalReferences: [{
      type: "distribution",
      url: `https://github.com/privacybydesign/yivi-sqlcipher-prebuilt/releases/tag/v${sqlcipherVersion}`,
      hashes: [{ alg: "SHA-256", content: args["sqlcipher-sha256"] }],
    }],
  };
  const openssl = {
    type: "library",
    "bom-ref": `pkg:github/openssl/openssl@openssl-${opensslVersion}`,
    name: "openssl",
    version: opensslVersion,
    description: "Statically linked into the Android Go bridge (libgojni.so) as SQLCipher's crypto provider",
    scope: "required",
    licenses: [{ license: { id: "Apache-2.0" } }],
    purl: `pkg:github/openssl/openssl@openssl-${opensslVersion}`,
  };
  for (const c of [sqlcipher, openssl]) components.set(c["bom-ref"], c);
  dependencies.set(sqlcipher["bom-ref"], { ref: sqlcipher["bom-ref"], dependsOn: [openssl["bom-ref"]] });
  appDependsOn.add(sqlcipher["bom-ref"]);
}

// cdxgen leaves many licences empty or "CUSTOM": it only finds pod licences by running `pod` (which
// fails for our Podfile), and its Go and pub.dev lookups are incomplete. Fill in the gaps here.
async function addLicenses() {
  const all = [...components.values()];
  for (const c of all) {
    if (c.licenses?.every((l) => (l.license?.id ?? l.license?.name) === "CUSTOM")) delete c.licenses;
    const known = KNOWN_LICENSES.find(([prefix]) => c.purl?.startsWith(prefix));
    if (known && !c.licenses?.length) c.licenses = [{ license: known[1] }];
  }
  const missing = (prefix) => all.filter((c) => c.purl?.startsWith(prefix) && !c.licenses?.length);
  await Promise.all(missing(PURL_GOLANG).map(async (c) => setLicense(c, await goLicense(c))));
  await Promise.all(missing(PURL_PUB).map(async (c) => setLicense(c, await pubLicense(c))));
  // Flutter plugin pods have the licence of their pub package, so these go after the pub packages.
  const pubLicenses = new Map(all.filter((c) => c.purl?.startsWith(PURL_PUB)).map((c) => [c.name, c.licenses]));
  await Promise.all(missing(PURL_COCOAPODS).map(async (c) => {
    const repo = podSpecRepos.get(c.name);
    if (!repo) c.licenses = pubLicenses.get(c.name);
    else setLicense(c, await podLicense(repo, c.name, c.version));
  }));
}

function setLicense(c, license) {
  if (license) c.licenses = [license.expression ? license : { license }];
}

// Returns a CycloneDX licence for an SPDX identifier (or alias), or undefined if it is not one.
function spdxLicense(id) {
  const lower = id?.toLowerCase();
  const spdx = SPDX_IDS.find((s) => s.toLowerCase() === lower) ?? LICENSE_ALIASES[lower];
  return spdx && { id: spdx };
}

// deps.dev knows the licences of Go modules. Modules that contain code under several licences
// (e.g. vendored code) get an SPDX "AND" expression.
async function goLicense(c) {
  const module = decodeURIComponent(c.purl.slice(PURL_GOLANG.length).split(/[@?]/)[0]);
  const json = await fetchText(
    `https://api.deps.dev/v3/systems/go/packages/${encodeURIComponent(module)}/versions/${encodeURIComponent(c.version)}`,
  );
  const licenses = json ? JSON.parse(json).licenses ?? [] : [];
  if (licenses.length > 1) return { expression: licenses.join(" AND ") };
  return spdxLicense(licenses[0]);
}

async function pubLicense(c) {
  const source = pubSources.get(c.name);
  if (source === "sdk") return { id: "BSD-3-Clause" }; // Part of the Flutter SDK.
  if (source === "path") return { id: "GPL-3.0-only" }; // Part of this repository.
  // A package with the same name on pub.dev may be a different project, so ask the git repository.
  if (source === "git") return githubLicense(pubGitUrls.get(c.name));
  // pub.dev detects the licence of every package and exposes it as a tag, e.g. "license:mit".
  const score = await fetchText(`https://pub.dev/api/packages/${encodeURIComponent(c.name)}/score`);
  const tags = score ? JSON.parse(score).tags : [];
  const fromTags = tags.filter((t) => t.startsWith("license:")).map((t) => spdxLicense(t.slice("license:".length))).find(Boolean);
  if (fromTags) return fromTags;
  const info = await fetchText(`https://pub.dev/api/packages/${encodeURIComponent(c.name)}`);
  const pubspec = info ? JSON.parse(info).latest.pubspec : {};
  return githubLicense(pubspec.repository ?? pubspec.homepage);
}

async function githubLicense(url) {
  const repo = url?.match(/github\.com[/:]([^/]+\/[^/#?]+?)(?:\.git)?(?:[/#?]|$)/)?.[1];
  if (!repo) return undefined;
  const headers = process.env.GITHUB_TOKEN ? { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` } : {};
  const json = await fetchText(`https://api.github.com/repos/${repo}/license`, { headers });
  return json ? spdxLicense(JSON.parse(json).license?.spdx_id) : undefined;
}

async function podLicense(repo, name, version) {
  let spec;
  if (repo === "trunk") {
    const hash = crypto.createHash("md5").update(name).digest("hex");
    const json = await fetchText(`https://cdn.cocoapods.org/Specs/${hash[0]}/${hash[1]}/${hash[2]}/${name}/${version}/${name}.podspec.json`);
    spec = json && JSON.parse(json).license;
  } else {
    // A spec repo on GitHub, e.g. Regula's. These podspecs are Ruby, so only pick out the licence type.
    const github = repo.match(/github\.com\/([^/]+\/[^/.]+)/)?.[1];
    if (!github) return undefined;
    const podspec = await fetchText(`https://raw.githubusercontent.com/${github}/HEAD/${name}/${version}/${name}.podspec`);
    const type = podspec?.match(/s\.license\s*=\s*(?:\{[^}]*?type:\s*|['"])['"]?([^'",\n]+)/)?.[1];
    spec = type && { type };
  }
  const type = typeof spec === "string" ? spec : spec?.type;
  if (!type) return undefined;
  // Anything that is not an SPDX licence, such as "commercial", is a proprietary licence.
  return spdxLicense(type) ?? { name: `Proprietary (${type})` };
}

// Maps every git package in a pubspec.lock to its repository URL.
function parsePubGitUrls(pubspecLock) {
  const urls = new Map();
  for (const [, name, body] of pubspecLock.matchAll(/^  (\S+):\n((?: {4}.*\n)+)/gm)) {
    const url = body.match(/^ {6}url: "?([^"\n]+)"?$/m)?.[1];
    if (/^ {4}source: git$/m.test(body) && url) urls.set(name, url);
  }
  return urls;
}

async function fetchText(url, options) {
  const response = await fetch(url, { ...options, signal: AbortSignal.timeout(30_000) }).catch((error) => {
    console.warn(`Could not fetch ${url}: ${error.message}`);
  });
  if (!response) return undefined;
  if (!response.ok) {
    console.warn(`Could not fetch ${url}: HTTP ${response.status}`);
    return undefined;
  }
  return response.text();
}
