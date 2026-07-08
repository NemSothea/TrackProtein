---
name: trackprotein-proxy
description: Deploy, update, test, or evaluate the TrackProtein AI proxy (Cloudflare Worker fronting the Claude API for photo/text protein estimation). Use when the user asks to deploy the proxy/worker, rotate its secrets, smoke-test or tail it, add the receipt/entitlement check, or run the accuracy eval. Covers proxy/worker.js, proxy/wrangler.toml, proxy/eval/.
---

# TrackProtein AI Proxy — Operations

Roadmap and phase status: `proxy/PLAN-PROXY.md` (read it first — it says what's deployed
and what's still pending). Architecture rationale: `proxy/README.md`.

## Layout
- `proxy/worker.js` — the entire backend. Single file, **no npm dependencies** (WebCrypto only). Keep it that way.
- `proxy/wrangler.toml` — worker name `trackprotein-ai`, `main = "worker.js"`.
- `proxy/eval/` — accuracy eval script + downloaded ground-truth data (data is gitignored).
- Client: `TrackProtein/Core/Services/AIEstimationService.swift` — its `AIEstimate` struct must
  stay in lockstep with `SCHEMA` in worker.js. Change one → change both.

## Deploy / update
```bash
cd proxy
npx wrangler deploy                 # deploy current worker.js
npx wrangler deployments list      # history
npx wrangler rollback              # revert to previous deployment
npx wrangler tail                  # live logs (leave running while testing from the app)
```
First-time login is interactive — the user runs `! npx wrangler login` themselves.

## Secrets — hard rules
- Set interactively so values never hit shell history or git:
  `npx wrangler secret put ANTHROPIC_API_KEY` · `npx wrangler secret put APP_SECRET`
- Generate APP_SECRET with `openssl rand -hex 24`.
- **NEVER** write a secret value into any file in this repo, any commit, any doc, or any
  command-line argument. If a secret leaks, rotate it in the Cloudflare dashboard AND the app.
- `MODEL` is a plain var (not secret), defaults to `claude-haiku-4-5`.

## Smoke tests (after every deploy)
```bash
# Text path — expect JSON: items[], totalGrams, lowGrams, highGrams, confidence, notes
curl -s -X POST "$PROXY_URL" \
  -H "content-type: application/json" -H "x-app-secret: $APP_SECRET" \
  -d '{"type":"text","text":"2 eggs and a protein shake"}'

# Photo path
IMG=$(base64 -i /path/to/meal.jpg | tr -d '\n')
curl -s -X POST "$PROXY_URL" \
  -H "content-type: application/json" -H "x-app-secret: $APP_SECRET" \
  -d "{\"type\":\"photo\",\"image\":\"$IMG\",\"mediaType\":\"image/jpeg\"}"

# Auth check — expect {"error":"unauthorized"} (401)
curl -s -X POST "$PROXY_URL" -H "content-type: application/json" -d '{"type":"text","text":"egg"}'
```
Export `PROXY_URL`/`APP_SECRET` in the current shell for testing only — don't persist them.

## Wire up the app (Phase A only)
Set `proxyURL` + `appSecret` in `AIEstimationService.swift`, then build and verify the AI
Logging screen end-to-end in the Simulator (use the `trackprotein-run-sim` skill, drive to
AI logging, real photo).
This is the **only** Swift file this skill ever touches.

## Accuracy eval (Phase C — evaluation, never training)
`claude-haiku-4-5` is a hosted model: nothing is trained. Improve accuracy by editing
`SYSTEM_PROMPT` in worker.js and re-measuring:
```bash
cd proxy/eval
node run-eval.mjs          # POSTs ground-truth photos to the worker, prints MAE + range coverage
```
- Ground truth: Nutrition5k overhead frames + metadata CSV (selective `gsutil cp` from
  `gs://nutrition5k_dataset/` — never the full 181 GB). See PLAN-PROXY.md Phase C.
- Record every run in `proxy/eval/RESULTS.md` (date, prompt version, MAE, range coverage).
- A full 50-photo run costs ≈ $0.10–0.15 — fine to run per prompt iteration, not in a loop.
- Regression rule: don't ship a prompt change that lowers range coverage below 80%.

## Entitlement gate (Phase B — blocked until paid Apple dev account)
JWS verification spec is in PLAN-PROXY.md Phase B. Do not start it before App Store Connect
products exist; do not add npm packages for it (WebCrypto + embedded Apple Root CA G3).

## Checkpoints
- Stop and ask before: rotating secrets, deleting the Worker, changing `SCHEMA` (breaks the
  shipped app's decoder), or any Swift edit beyond the two Phase-A constants.
- After every worker.js change: deploy → smoke tests → (once eval exists) eval run.
