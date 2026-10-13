#!/usr/bin/env bash
# Build every example (and examples/local/*), then check: the page script parses, and every
# node / edge / table a scenario mentions exists. Usage: scripts/check.sh [out_dir]
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$(mktemp -d)}"; mkdir -p "$out"
shopt -s nullglob
status=0
for data in "$here"/examples/*.data.js "$here"/examples/local/*.data.js; do
  name="$(basename "$data" .data.js)"
  python3 "$here/build.py" "$data" "$out/$name.html" >/dev/null
  if ! node - "$data" "$out/$name.html" <<'JS'
const fs = require('fs');
const [data, page] = process.argv.slice(2);
const html = fs.readFileSync(page, 'utf8');
new Function(html.split('<script>')[1].split('</script>')[0]);          // page script parses
global.window = {}; require(data); const R = window.RIDE, bad = [];
const T = R.tables || {};
for (const [k, s] of Object.entries(R.scenarios)) s.steps.forEach((st, i) => {
  [st.who, st.to, ...(st.n || [])].forEach(n => R.nodes[n] || bad.push(`${k}#${i + 1} unknown node ${n}`));
  st.e.forEach(e => R.edges[e.replace('<', '')] || bad.push(`${k}#${i + 1} unknown edge ${e}`));
  (st.tables || []).forEach(([t, op]) => { T[t] || bad.push(`${k}#${i + 1} unknown table ${t}`); ['read', 'write', 'change'].includes(op) || bad.push(`${k}#${i + 1} bad op ${op}`); });
});
for (const [k, e] of Object.entries(R.edges)) [e[0], e[1]].forEach(n => R.nodes[n] || bad.push(`edge ${k}: unknown node ${n}`));
for (const [t, v] of Object.entries(T)) R.nodes[v.node] || bad.push(`table ${t}: unknown node ${v.node}`);
if (bad.length) { console.error(bad.join('\n')); process.exit(1); }
console.log(`ok  ${require('path').basename(data)}: ${Object.keys(R.nodes).length} nodes, ${Object.keys(R.scenarios).length} scenarios`);
JS
  then status=1; fi
done
echo "built pages in $out"
exit $status
