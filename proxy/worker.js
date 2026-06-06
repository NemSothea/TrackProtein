/**
 * TrackProtein AI proxy — Cloudflare Worker.
 *
 * Keeps the Anthropic API key off-device and constrains the endpoint to one job:
 * protein estimation from a meal photo or text description. The prompt and JSON
 * schema are fixed server-side so the app (or anyone who finds the URL) cannot
 * use this as a general-purpose Claude proxy.
 *
 * Setup: see proxy/README.md
 * Secrets: ANTHROPIC_API_KEY (required), APP_SECRET (recommended), MODEL (optional override)
 */

const SYSTEM_PROMPT = `You are a nutrition expert estimating the protein content of meals.
Given a meal photo or a text description, identify each protein-containing food and estimate its protein in grams, assuming realistic portion sizes.
Be honest about uncertainty: lowGrams/highGrams should bracket a realistic range, and confidence reflects how clearly you can assess portions and ingredients.
If the input contains no identifiable food, return an empty items array with totalGrams 0 and a note explaining why.`;

const SCHEMA = {
  type: "object",
  properties: {
    items: {
      type: "array",
      items: {
        type: "object",
        properties: {
          name: { type: "string", description: "Food name, e.g. 'Grilled chicken breast'" },
          grams: { type: "number", description: "Estimated grams of protein in this item" },
        },
        required: ["name", "grams"],
        additionalProperties: false,
      },
    },
    totalGrams: { type: "number", description: "Best single estimate of total protein in grams" },
    lowGrams: { type: "number", description: "Low end of the realistic range" },
    highGrams: { type: "number", description: "High end of the realistic range" },
    confidence: { type: "string", enum: ["low", "medium", "high"] },
    notes: { type: "string", description: "One short sentence of caveats, or empty" },
  },
  required: ["items", "totalGrams", "lowGrams", "highGrams", "confidence", "notes"],
  additionalProperties: false,
};

function json(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }
    if (env.APP_SECRET && request.headers.get("x-app-secret") !== env.APP_SECRET) {
      return json({ error: "unauthorized" }, 401);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "invalid_json" }, 400);
    }

    let userContent;
    if (body.type === "photo" && typeof body.image === "string") {
      // ~1024px JPEG from the app ≈ well under Workers/API body limits
      userContent = [
        {
          type: "image",
          source: {
            type: "base64",
            media_type: body.mediaType === "image/png" ? "image/png" : "image/jpeg",
            data: body.image,
          },
        },
        { type: "text", text: "Estimate the protein content of this meal." },
      ];
    } else if (body.type === "text" && typeof body.text === "string" && body.text.trim()) {
      userContent = [
        { type: "text", text: `Estimate the protein content of: ${body.text.slice(0, 500)}` },
      ];
    } else {
      return json({ error: "invalid_request" }, 400);
    }

    const upstream = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        // Haiku per PLAN.md §3 (cost-efficient vision); override with the MODEL var if needed.
        model: env.MODEL || "claude-haiku-4-5",
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        output_config: { format: { type: "json_schema", schema: SCHEMA } },
        messages: [{ role: "user", content: userContent }],
      }),
    });

    if (!upstream.ok) {
      const detail = await upstream.text();
      console.error("anthropic error", upstream.status, detail.slice(0, 500));
      return json({ error: "upstream_error", status: upstream.status }, 502);
    }

    const data = await upstream.json();
    const text = data.content?.find((block) => block.type === "text")?.text;
    if (!text) {
      return json({ error: "empty_response" }, 502);
    }
    // output_config.format guarantees the text block is valid JSON matching SCHEMA.
    return new Response(text, { headers: { "content-type": "application/json" } });
  },
};
