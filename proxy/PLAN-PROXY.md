# AI Proxy — Completion Plan

> **⚠️ SUPERSEDED (2026-07-02):** decision made to replace the Haiku proxy with our own
> on-device Core ML model trained on Nutrition5k — see `ml/PLAN-ML.md`. This plan is kept
> for reference only; Phase A was never deployed (no Worker exists on Cloudflare, no secrets
> were ever set). `proxy/` code stays until ML Phase M5 removes the app's dependency on it.

Status of the code today: `proxy/worker.js` (Cloudflare Worker, complete) and the app client
`TrackProtein/Core/Services/AIEstimationService.swift` already exist and match each other's
contract. **Nothing is deployed** — `proxyURL`/`appSecret` in the app are empty strings.
This plan covers the remaining work: deploy, entitlement gating, accuracy evaluation, hardening.

---

## Your three questions, answered first

### 1. How many phases?

**Four** (A–D below). A and C are doable right now with a free Cloudflare account and an
Anthropic API key. B is blocked until the paid Apple Developer account exists (App Store
Connect products are a prerequisite for real signed transactions). Total effort ≈ **2.5–3 days**.

| Phase | What | Effort | Blocked by |
|---|---|---|---|
| A | Deploy the existing Worker + wire up the app | ~0.5 day | nothing |
| B | App Store entitlement gate (StoreKit 2 JWS verification) | ~1 day | paid Apple dev account |
| C | Accuracy eval against real ground-truth photos | ~0.5–1 day | Phase A |
| D | Hardening: rate limits, size caps, spend alarms | ~0.5 day | Phase A |

### 2. Do we need to *train* a model? (No.)

`claude-haiku-4-5` is a **hosted, closed-weights API model**. There is no training, no
fine-tuning, no GPU, and no training dataset in this project — you cannot train it and you
don't need to. Accuracy improves by iterating the **server-side system prompt** in
`worker.js` (portion-size guidance, few-shot examples, uncertainty calibration) and
**measuring** each iteration against photos with known protein content. That measuring is
what the datasets below are for — **evaluation only, never training**.

(A locally *trained* estimator — e.g. fine-tuning an open VLM — would be a separate
research project with GPU costs and worse accuracy than Haiku for this use case. Out of scope.)

### 3. Free datasets / open source (verified 2026-07-02)

| Resource | What it gives us | Verified |
|---|---|---|
| **[Nutrition5k](https://github.com/google-research-datasets/Nutrition5k)** (Google Research) | 5,006 real cafeteria dishes; overhead RGB images + **per-dish protein grams** ground truth (weighed, not estimated). CC BY 4.0, commercial use OK. Full set is 181 GB but the GCS bucket (`gs://nutrition5k_dataset/`) allows selective `gsutil` download — we only need ~50 overhead frames + the metadata CSV (a few hundred MB). ⚠️ Repo archived April 2026 (read-only) — data still downloadable; if the bucket ever disappears, Kaggle mirrors exist. | ✅ fetched repo directly |
| **[SNAPMe](https://agdatacommons.nal.usda.gov/articles/dataset/SNAPMe_A_Benchmark_Dataset_of_Food_Photos_with_Food_Records_for_Evaluation_of_Computer_Vision_Algorithms_in_the_Context_of_Dietary_Assessment/24856449)** (USDA) | 3,311 real **smartphone** meal photos paired with ASA24 food records (nutrients incl. protein). Closer to TrackProtein's actual input than Nutrition5k's rig photos. Publicly free per USDA Ag Data Commons + the [MDPI paper](https://www.mdpi.com/2072-6643/15/23/4972). | ⚠️ page blocks bots (403 on automated fetch) — listing + paper confirm public; verify download manually in a browser |
| **[USDA FoodData Central API](https://fdc.nal.usda.gov/)** | Free nutrient lookup — ground truth for the **text path** ("2 eggs and a greek yogurt" has a known protein answer). Already planned for Phase 2 food search. | ✅ already in PLAN.md |
| Methodology: [Prompt Engineering and Model Selection for LLM-Based Nutritional Estimation from Food Images](https://doi.org/10.3390/nu18122017) (Nutrients, 2026) | Peer-reviewed eval of Claude models **including Haiku 4.5** on exactly this task — use its prompt findings to seed our prompt iterations. | ✅ found via search; DOI resolves |

---

## Phase A — Deploy what exists (~0.5 day)

1. Add `proxy/wrangler.toml`:
   ```toml
   name = "trackprotein-ai"
   main = "worker.js"
   compatibility_date = "2026-07-02"
   ```
2. Login (interactive — run it yourself): `! npx wrangler login`
3. Deploy from `proxy/`: `npx wrangler deploy`
4. Secrets — entered interactively, **never** typed into a command line or committed:
   ```bash
   npx wrangler secret put ANTHROPIC_API_KEY   # paste sk-ant-... at the prompt
   npx wrangler secret put APP_SECRET          # paste output of: openssl rand -hex 24
   ```
5. Smoke test (text, then photo — see skill for the curl commands). Expected: JSON with
   `items/totalGrams/lowGrams/highGrams/confidence`.
6. **Only Swift change in this whole plan:** set `proxyURL` + `appSecret` in
   `AIEstimationService.swift`, rebuild, verify the AI Logging screen end-to-end in the
   Simulator with a real meal photo.

**Done when:** a photo logged through the app produces a saved `ProteinEntry` with source `.ai`.

## Phase B — Entitlement gate (~1 day; needs paid Apple dev account)

Goal per PLAN.md §3: proxy "checks an App Store receipt" so only premium users spend API money.

- App sends `Transaction.jwsRepresentation` (StoreKit 2) for the active premium
  product in a new `x-transaction-jws` header. `AIEstimationService` already centralizes the
  request — one-line header addition **when this phase starts, not before**.
- Worker verifies the JWS with **WebCrypto only** (keep `worker.js` dependency-free):
  x5c chain → embedded Apple Root CA G3 cert, then check `bundleId == com.sothea.trackprotein`,
  `productId ∈ {monthly, yearly, lifetime}`, and `expiresDate > now` (skip expiry for lifetime,
  it's a non-consumable). Reject with 403 `{"error":"not_entitled"}`.
- Keep `APP_SECRET` as a second factor. Sandbox transactions (`environment: "Sandbox"`) accepted
  behind an `ALLOW_SANDBOX` var for TestFlight testing.
- Prerequisites: paid Apple Developer account → App Store Connect products created → real/sandbox
  signed transactions exist. **Until then this phase is specced, not started.**

**Done when:** a request without a valid premium JWS is rejected; a sandbox-subscribed test user succeeds.

## Phase C — Accuracy eval (~0.5–1 day; eval-only, no training)

1. `proxy/eval/` — gitignore the downloaded data.
2. Pull ~50 Nutrition5k overhead frames + `dish_metadata` CSV via selective `gsutil cp`
   (few hundred MB, not 181 GB). Optionally add ~20 SNAPMe phone photos later for realism.
3. `proxy/eval/run-eval.mjs` (Node, no deps): for each photo → downscale to ~1024px → POST to
   the deployed Worker (or `wrangler dev` locally) → record estimate vs ground truth.
4. Metrics: **MAE** (grams), **range coverage** (% of dishes where truth ∈ [lowGrams, highGrams] —
   target ≥ 80%, this is what the app shows users), confidence calibration (high-confidence MAE
   should beat low-confidence MAE).
5. Iterate `SYSTEM_PROMPT` in worker.js against these numbers. Also run ~20 text-path cases
   scored against USDA FDC values.
6. Cost note: 50 Haiku photo calls ≈ **$0.10–0.15 per full eval run**. Negligible, but don't loop it blindly.

**Done when:** baseline metrics are recorded in `proxy/eval/RESULTS.md` and at least one
prompt iteration measurably improved them (or baseline is confirmed good enough to ship).

## Phase D — Hardening (~0.5 day)

- Reject request bodies > ~5 MB before reading (base64 of a 1024px JPEG is well under this).
- Per-device daily cap: honest free-tier note — Workers KV free tier allows only ~1k writes/day,
  which itself caps abuse at low volume; a `x-device-id` counter in KV is fine for launch scale.
  Durable Objects are the clean answer if volume grows.
- Anthropic console: set a **monthly spend limit** on the API key (the real backstop).
- `npx wrangler tail` for live logs; Cloudflare dashboard alert on error-rate spike.

**Done when:** oversized/over-quota requests are rejected and a spend limit exists on the key.

---

## Standing rules (all phases)

- Secrets live **only** in Worker secrets (`wrangler secret put`) — never in git, the app binary,
  Info.plist, or this repo's docs. `APP_SECRET` in the app binary is obfuscation, not security —
  Phase B's JWS check is the real gate.
- The Worker stays single-file and dependency-free; the fixed server-side prompt + schema is the
  abuse containment (can't be repurposed as a general Claude proxy) — keep it that way.
- Every worker.js change: deploy → smoke test → (after Phase C exists) eval run before calling it done.
