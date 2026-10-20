import { OpenAiResponsesProvider, ProviderError } from "./openai_provider.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("Responses provider handles mixed output items and disables provider storage", async () => {
  const captured: { body?: Record<string, unknown>; authorization?: string } = {};
  const provider = new OpenAiResponsesProvider(
    "server-only-key",
    async (_input, init) => {
      captured.body = JSON.parse(String(init?.body));
      captured.authorization = new Headers(init?.headers).get("authorization") ?? "";
      return Response.json({
        status: "completed",
        output: [
          { type: "reasoning", summary: [] },
          {
            type: "message",
            content: [
              { type: "refusal", refusal: "" },
              { type: "output_text", text: "Guten Tag!" },
            ],
          },
        ],
        usage: { input_tokens: 12, output_tokens: 8 },
      });
    },
    100,
    1,
  );
  const result = await provider.complete({
    model: "pinned-model",
    instructions: "Be a tutor.",
    messages: [{ role: "user", content: "Hallo" }],
    maxOutputTokens: 200,
  });
  assert(captured.body !== undefined, "provider request was sent");
  assert(captured.body.store === false, "provider-side response storage is disabled");
  assert(captured.authorization === "Bearer server-only-key", "credential is sent only server-side");
  assert(result.text === "Guten Tag!", "text is extracted from output_text parts");
  assert(result.inputTokens === 12 && result.outputTokens === 8, "token usage is returned");
});

Deno.test("Responses provider retries only controlled transient failures", async () => {
  let attempts = 0;
  const provider = new OpenAiResponsesProvider(
    "test-key",
    async () => {
      attempts++;
      return new Response("temporary", { status: 503 });
    },
    100,
    2,
    async () => {},
  );
  let caught = false;
  try {
    await provider.complete({
      model: "model",
      instructions: "instructions",
      messages: [{ role: "user", content: "test" }],
      maxOutputTokens: 20,
    });
  } catch (error) {
    caught = error instanceof ProviderError;
  }
  assert(caught, "transient upstream error is translated to a safe provider error");
  assert(attempts === 2, "provider makes only the configured bounded attempts");
});

Deno.test("Responses provider does not retry non-transient failures", async () => {
  let attempts = 0;
  const provider = new OpenAiResponsesProvider(
    "test-key",
    async () => {
      attempts++;
      return new Response("invalid key", { status: 401 });
    },
    100,
    2,
    async () => {},
  );
  try {
    await provider.complete({
      model: "model",
      instructions: "instructions",
      messages: [{ role: "user", content: "test" }],
      maxOutputTokens: 20,
    });
  } catch (error) {
    assert(error instanceof ProviderError, "provider error is normalized");
  }
  assert(attempts === 1, "authorization failures are not retried");
});
