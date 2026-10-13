---
name: ride-the-system
description: Build an interactive "ride the system" architecture walkthrough as a published artifact. It shows an AWS-style map of a system's services, queues and stores, with scenarios that play like a video. Each step shows who asks whom, what they want in plain language, and the real message, along with play/pause, step, speed, keyboard shortcuts (← → Space F + − 0), full screen, zoom and pan, clickable build-status filters, and the database tables each step reads, writes or triggers on. Use when the user asks to visualize, explain or walk through how a system or architecture works end to end, wants an architecture playground or animated flow, or invokes /ride-the-system.
argument-hint: "[system, repo or scope to map]"
---

# Ride the system

This skill produces one self-contained HTML page from two pieces:
- `template.html` — the engine: map rendering, player, envelope animation, plain-language message cards, conversation log, keyboard shortcuts, full screen, and an optional status board;
- a data file you write — `window.RIDE = {...}` describing *this* system.

`build.py` inlines the data into the template. **Never edit `template.html` for one system.** Everything system-specific goes in the data file.

The reference example is `examples/online-store.data.js`, a fictional online store on AWS with 20 services, 4 scenarios and 3 tables. Also read any private examples in `examples/local/*.data.js`; that folder is git-ignored, for real systems that must not be published. Read one before writing a new data file, and copy its shape.

## 1. Scope it

`$ARGUMENTS` names the system, repo or flow. If it's empty or vague, ask one question: which system, and for whom (engineers or non-technical stakeholders). Otherwise proceed.

## 2. Learn the real system (read-only)

Ground every box and message in the code and infra. Don't invent anything.
- **Components:** look at infrastructure-as-code (Terraform, CDK, SAM, serverless.yml), Dockerfiles and CI deploy targets. List every service a request passes through: APIs, Lambdas/containers, queues and their DLQs, event buses, schedulers, pipes/CDC, databases and tables, buckets, external systems, and the people or teams who trigger things.
- **Messages:** for each hop, find the real payload shape in the handler or schema (SQS message body, HTTP request, DB write, event). Note who sends it and why.
- **Scenarios:** pick 3–6 real end-to-end flows people care about, such as "a new file arrives", "a nightly job runs" or "an admin turns something on". Include one that shows a failure path or a safety net if the system has one.
- **Status (optional):** if the user wants built / in-progress / left, take it from tickets, open PRs and docs. If you can't verify a status, leave `status` off the node.

For a large repo, fan the survey out to Explore agents (components, message shapes, scenarios), but write the data file yourself.

## 3. Write the data file

Write it in the session scratchpad, e.g. `<scratchpad>/<system>.data.js`. Schema:

```js
window.RIDE = {
  title: 'Short page name',                 // also the <title>; a name, not a sentence
  eyebrow: 'Org · system · as of <date>',
  lede: 'Two sentences: what the system does for whom.',
  intro: [['1 · Heading', 'one plain sentence'], ...],   // 3–4 cards, optional
  canvas: { w: 1620, h: 1000 },             // SVG units; grow it rather than cramming
  legend: [['compute','Compute'], ['msg','Messaging & events'], ['db','Database'], ['storage','Storage'], ['ext','Outside AWS']], // optional
  colors: { mykey: '#hex' },                // optional extra/override tile colours
  nodes: {
    id: { x, y, kind, c, t: 'Title', s: 'subtitle · service type', status?: 'built'|'recent'|'progress'|'left',
          what: 'What it does, one or two plain sentences.', facts: ['short, verified facts', ...] },
  },
  edges: { id: ['fromNode', 'toNode', [[x,y], ...] /* optional waypoints */] },
  groups: [{ x, y, w, h, label: 'Dashed group box' }],   // optional
  tables: {                                // optional but recommended when a database is central
    'schema.table': { node: 'dbNodeId', what: 'What one row means, and why it matters (one sentence).' },
  },
  scenarios: {
    key: { name: 'A new file arrives', real: 'What actually happened in a real run (optional, verified only).',
      steps: [
        { who: 'nodeId', to: 'nodeId', name?: 'Speaker name override (e.g. a district, a person)',
          e: ['edgeId', '<edgeId' /* "<" = travel the edge backwards, e.g. a reply */],
          n: ['extraNodeToLightUp'],
          tables: [['schema.table', 'read'|'write'|'change', 'why, in a few words'], ...], // change = this row change is what wakes the next service (CDC/streams)
          says: 'What the sender says, first person, plain words, no jargon.',
          msg: { Kind: 'Charge request', Amount: '$178.00', 'Safe to retry': 'yes' }, // plain-language card
          raw: '{ "type": "reconcile_district", ... }' },   // the real message shape
      ] },
  },
  board?: [{ c: 'recent'|'progress'|'left'|'built', h: 'Column title', items: [['Title', 'TICKET-1 · PR #2', 'one line']] }],
  boardTitle?: "What's built, what's moving, what's left", boardNote?: 'Where the keys/sources come from.',
};
```

**Tile kinds** (`kind`): `lambda`, `ecs`, `s3`, `sqs`, `sns`, `rds`, `dynamodb`, `neptune`, `sched` (EventBridge Scheduler), `bus` (EventBridge bus), `pipes`, `stepfn`, `apigw`, `kinesis`, `cloudwatch`, `cognito`, `web`, `person`, `github`, `mule`, `drive`, `box` (fallback).
**Colour keys** (`c`), using AWS category colours: `compute` (Lambda, ECS, EC2), `msg` (SQS, SNS, EventBridge, Step Functions, Pipes), `db`, `storage`, `net`, `security`, `ext` (outside AWS), `mule`, `drive`. A raw hex also works.

**Layout rules (this is what keeps it uncramped):**
- Use a grid: columns about 230 apart (e.g. x = 110, 340, 570, 800, 1030, 1260, 1490) and rows about 180 apart (y = 110, 290, 470, 650, 850). Each node needs about ±75 horizontally and 36 above to 66 below its (x, y) for icon and labels.
- Flow mostly left to right: sources → ingestion/events → processing → engines → outputs. Put shared databases in a band along the bottom, with the tables a writer touches placed under that writer.
- Waypoints run edges through **corridors**, the gaps halfway between columns or rows (x = 225, 455, 685, 915, 1145, 1375; or a free row such as y = 760 or 955). Never route a line through another node. Long writes to the database band go down a corridor, then along a free row.
- Add `groups` for real boundaries (a runtime, a VPC part, a database), drawn at least 20 units outside their nodes.
- Grow `canvas` before squeezing spacing. Wider than 1620 is fine, because the map scrolls inside its own box.

**Writing rules:**
- `says` is spoken by the sender, in the first person, for a non-technical reader. For example: "Payments: stock is held. Please charge the customer." Not "publish StockReserved".
- `msg` is the message in plain words. Use labels a non-engineer understands: Kind, Who, What, Why, How many.
- `raw` is the real shape (JSON, HTTP line, SQL verb and table, S3 key). Use real field names and placeholder values. **Never include secrets, tokens, passwords, or personal data** (names, emails, birthdates). Use truncated IDs like `d1a45dd6…`.
- One hop or one decision per step; about 4–13 steps per scenario. A reply is its own step with a `<edge`.
- `tables`: when the system has a database, tag each step with the tables it touches. Use the real `schema.table` names from the code, and say which map node each table belongs to. `read` means it looks rows up, `write` means it saves rows, `change` means a row change there triggers the next hop. These drive the tags on the map, the "Tables touched" list on each step, and a "Which tables matter, and when" index. Include the tables that explain *why* something happens (e.g. the pointer table whose update starts a job), not just the ones a step writes.
- `real` and `facts` hold only things you verified (counts, timings, ticket keys). If unsure, leave them out.

## 4. Build and check

```bash
python3 ~/.claude/skills/ride-the-system/build.py <scratchpad>/<system>.data.js <scratchpad>/<system>-ride.html
# add --standalone for a complete HTML file you can open locally or host (GitHub Pages, S3…)
```

Then check it. Copy the data file into `examples/local/` first (git-ignored), or run the checks on a temp copy:

```bash
~/.claude/skills/ride-the-system/scripts/check.sh /tmp/ride-check   # builds every example; checks the script parses and every node/edge/table reference resolves
```

Fix every reported problem before publishing.

## 5. Publish

Publish the built HTML with the Artifact tool, following its rules (its quickstart for a new artifact; `icon: "flow"`; a one-sentence `description`). Re-publish the same file path to update it. Take at most one look in the browser: check that the map isn't cramped, the bubble sits next to the speaker, and the envelope moves.

## 6. Report

Give the user:
- the link;
- the scenario list;
- how to use it: ▶ or **Space** to play/pause, **←/→** to step, **F** for full screen (Esc exits), **+ / − / 0** or pinch / Ctrl-scroll to zoom (drag to pan; the view follows each step while zoomed), click a build-status chip to highlight those components, see which tables each step reads/writes (and the table index below the player), click a service for its details, and "Show the real message" for the payload;
- anything you couldn't verify and so left out.

## Changing this skill

If the engine itself needs a change (a new feature, a layout fix, a new tile kind), don't patch a generated page. Use the `update-ride-the-system` skill. It edits `template.html` here, re-runs the checks, refreshes the README visuals, and pushes to the public repo `github.com/shradayshakya/ride-the-system`.
