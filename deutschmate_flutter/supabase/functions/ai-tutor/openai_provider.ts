import type { TutorCompletion, TutorMessage, TutorProvider } from "./types.ts";

export class ProviderError extends Error {
  constructor(readonly retryable: boolean) {
    super("AI provider request failed");
  }
}

export class OpenAiResponsesProvider implements TutorProvider {
  constructor(
    private readonly apiKey: string,
    private readonly fetcher: typeof fetch = fetch,
    private readonly timeoutMs = 25_000,
    private readonly maxAttempts = 2,
    private readonly sleep: (ms: number) => Promise<void> = (ms) =>
      new Promise((resolve) => setTimeout(resolve, ms)),
  ) {}

  async complete(input: {
    model: string;
    messages: TutorMessage[];
    instructions: string;
    maxOutputTokens: number;
  }): Promise<TutorCompletion> {
    let lastError: unknown;
    for (let attempt = 1; attempt <= this.maxAttempts; attempt++) {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), this.timeoutMs);
      try {
        const response = await this.fetcher("https://api.openai.com/v1/responses", {
          method: "POST",
          headers: {
            authorization: `Bearer ${this.apiKey}`,
            "content-type": "application/json",
          },
          body: JSON.stringify({
            model: input.model,
            instructions: input.instructions,
            input: input.messages.map((message) => ({
              role: message.role,
              content: message.content,
            })),
            max_output_tokens: input.maxOutputTokens,
            store: false,
          }),
          signal: controller.signal,
        });
        if (!response.ok) {
          const retryable = response.status === 429 || response.status >= 500;
          if (retryable && attempt < this.maxAttempts) {
            await this.sleep(200 * attempt);
            continue;
          }
          throw new ProviderError(retryable);
        }
        const payload: unknown = await response.json();
        return parseResponse(payload);
      } catch (error) {
        lastError = error;
        if (error instanceof ProviderError && !error.retryable) throw error;
        if (attempt < this.maxAttempts) {
          await this.sleep(200 * attempt);
          continue;
        }
      } finally {
        clearTimeout(timeout);
      }
    }
    throw lastError instanceof ProviderError
      ? lastError
      : new ProviderError(true);
  }
}

function parseResponse(value: unknown): TutorCompletion {
  if (value === null || typeof value !== "object") throw new ProviderError(false);
  const response = value as Record<string, unknown>;
  if (response.status !== "completed" || !Array.isArray(response.output)) {
    throw new ProviderError(false);
  }
  const text = response.output.flatMap((item) => {
    if (item === null || typeof item !== "object") return [];
    const outputItem = item as Record<string, unknown>;
    if (outputItem.type !== "message" || !Array.isArray(outputItem.content)) return [];
    return outputItem.content.flatMap((part) => {
      if (part === null || typeof part !== "object") return [];
      const outputPart = part as Record<string, unknown>;
      return outputPart.type === "output_text" && typeof outputPart.text === "string"
        ? [outputPart.text]
        : [];
    });
  }).join("\n").trim();
  const usage = response.usage;
  if (!text || usage === null || typeof usage !== "object") {
    throw new ProviderError(false);
  }
  const usageRecord = usage as Record<string, unknown>;
  const inputTokens = usageRecord.input_tokens;
  const outputTokens = usageRecord.output_tokens;
  if (
    typeof inputTokens !== "number" || !Number.isSafeInteger(inputTokens) || inputTokens < 0 ||
    typeof outputTokens !== "number" || !Number.isSafeInteger(outputTokens) || outputTokens < 0
  ) {
    throw new ProviderError(false);
  }
  return { text, inputTokens, outputTokens };
}
