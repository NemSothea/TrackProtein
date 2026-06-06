# TrackProtein AI Proxy

A single Cloudflare Worker that fronts the Claude API for AI protein estimation. The Anthropic API key lives only here — never in the app.

## Deploy (~10 minutes, free tier)

1. **Get an Anthropic API key**: https://console.anthropic.com → API Keys → Create Key.
2. **Create the Worker**: https://dash.cloudflare.com → Workers & Pages → Create → Worker. Name it `trackprotein-ai`, deploy the hello-world, then **Edit code** and paste the contents of `worker.js`. Deploy.
3. **Set secrets** (Worker → Settings → Variables and Secrets):
   | Name | Type | Value |
   |---|---|---|
   | `ANTHROPIC_API_KEY` | Secret | your `sk-ant-...` key |
   | `APP_SECRET` | Secret | any long random string (e.g. `openssl rand -hex 24`) |
   | `MODEL` | Variable (optional) | defaults to `claude-haiku-4-5` |
4. **Point the app at it** — in `TrackProtein/Core/Services/AIEstimationService.swift` set:
   ```swift
   static let proxyURL = "https://trackprotein-ai.<your-subdomain>.workers.dev"
   static let appSecret = "<the same APP_SECRET value>"
   ```
5. **Smoke test**:
   ```bash
   curl -s -X POST https://trackprotein-ai.<your-subdomain>.workers.dev \
     -H "content-type: application/json" -H "x-app-secret: <APP_SECRET>" \
     -d '{"type":"text","text":"2 eggs and a protein shake"}'
   # → {"items":[{"name":"Eggs (2)","grams":12},...],"totalGrams":37,...}
   ```

## API

`POST /` with JSON body:
- Photo: `{"type":"photo","image":"<base64 jpeg>","mediaType":"image/jpeg"}`
- Text: `{"type":"text","text":"2 eggs and a shake"}`

Returns the estimate JSON (see `SCHEMA` in worker.js) or `{"error":...}`.

## Cost

Haiku 4.5 ($1/M input, $5/M output): a photo estimate ≈ $0.002, a text estimate ≈ $0.0005. The free Cloudflare tier (100k requests/day) costs nothing.

## Why prompt-on-server

The Worker only accepts an image or a ≤500-char food description and always applies the fixed system prompt + JSON schema. Even with the URL and APP_SECRET leaked, it can't be repurposed as a general Claude proxy.
