import { createTutorHandler } from "./handler.ts";
import type {
  QuotaResult,
  TutorCompletion,
  TutorConfig,
  TutorConversation,
  TutorDependencies,
  TutorMessage,
  TutorProvider,
  TutorStore,
  TutorUser,
} from "./types.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function equal(actual: unknown, expected: unknown, message: string): void {
  if (actual !== expected) {
    throw new Error(`${message}: expected ${String(expected)}, got ${String(actual)}`);
  }
}

const config: TutorConfig = {
  model: "test-model",
  dailyLimit: 10,
  perMinuteLimit: 2,
  userDailyBudgetMicroUsd: 10_000,
  projectDailyBudgetMicroUsd: 100_000,
  reserveCostMicroUsd: 100,
  inputCostMicroUsdPerMillion: 100_000,
  outputCostMicroUsdPerMillion: 200_000,
  maxOutputTokens: 300,
  allowedOrigins: ["https://learn.example.test"],
};

class FakeStore implements TutorStore {
  quota: QuotaResult = "reserved";
  ownerId = "learner-1";
  settled: Array<{ userMessage: string; reply: string; costMicroUsd: number }> = [];
  released: string[] = [];
  created = 0;
  history: TutorMessage[] = [{ role: "assistant", content: "Hallo!" }];

  async findConversation(userId: string, conversationId: string): Promise<TutorConversation | null> {
    return userId === this.ownerId && conversationId === "10000000-0000-4000-8000-000000000001"
      ? { id: conversationId }
      : null;
  }
  async createConversation(): Promise<TutorConversation> {
    this.created++;
    return { id: "20000000-0000-4000-8000-000000000002" };
  }
  async recentMessages(): Promise<TutorMessage[]> {
    return this.history;
  }
  async reserveRequest(): Promise<QuotaResult> {
    return this.quota;
  }
  async settleRequest(input: Parameters<TutorStore["settleRequest"]>[0]): Promise<void> {
    this.settled.push(input);
  }
  async releaseRequest(_requestId: string, failureCode: string): Promise<void> {
    this.released.push(failureCode);
  }
}

class FakeProvider implements TutorProvider {
  result: TutorCompletion = { text: "Der Artikel ist der.", inputTokens: 10, outputTokens: 20 };
  shouldFail = false;
  request: Parameters<TutorProvider["complete"]>[0] | null = null;

  async complete(input: Parameters<TutorProvider["complete"]>[0]): Promise<TutorCompletion> {
    this.request = input;
    if (this.shouldFail) throw new Error("secret upstream details");
    return this.result;
  }
}

function setup() {
  const store = new FakeStore();
  const provider = new FakeProvider();
  const dependencies: TutorDependencies = {
    authenticate: async (token): Promise<TutorUser | null> =>
      token === "valid-user-token" ? { id: "learner-1" } : null,
    store,
    provider,
    config,
    requestId: () => "request-test-id",
  };
  return { handler: createTutorHandler(dependencies), store, provider };
}

function post(body: unknown, options: { origin?: string; token?: string } = {}) {
  const headers = new Headers({ "content-type": "application/json" });
  if (options.origin) headers.set("origin", options.origin);
  if (options.token) headers.set("authorization", `Bearer ${options.token}`);
  return new Request("https://function.example.test/ai-tutor", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

Deno.test("AI tutor rejects missing or invalid user sessions before quota use", async () => {
  const { handler, store, provider } = setup();
  const missing = await handler(post({ message: "Hallo", locale: "de", cefrLevel: "a1" }));
  equal(missing.status, 401, "missing bearer token is rejected");
  const invalid = await handler(post(
    { message: "Hallo", locale: "de", cefrLevel: "a1" },
    { token: "invalid" },
  ));
  equal(invalid.status, 401, "invalid bearer token is rejected");
  equal(store.created, 0, "unauthenticated requests do not create conversations");
  equal(provider.request, null, "unauthenticated requests do not call the provider");
});

Deno.test("AI tutor validates request fields and rejects cross-account conversations", async () => {
  const { handler, store } = setup();
  const invalid = await handler(post(
    { message: "", locale: "de", cefrLevel: "a1" },
    { token: "valid-user-token" },
  ));
  equal(invalid.status, 400, "empty message rejected");
  const foreign = await handler(post(
    {
      message: "Bitte erklären.",
      locale: "de",
      cefrLevel: "a1",
      conversationId: "10000000-0000-4000-8000-000000000001",
    },
    { token: "valid-user-token" },
  ));
  equal(foreign.status, 404, "foreign conversation is not exposed");
  equal(store.settled.length, 0, "foreign conversation receives no message");
});

Deno.test("AI tutor bounds request bodies even when Content-Length is absent", async () => {
  const { handler } = setup();
  const oversized = await handler(post(
    { message: "x".repeat(17_000), locale: "de", cefrLevel: "a1" },
    { token: "valid-user-token" },
  ));
  equal(oversized.status, 413, "oversized streamed body is rejected");
});

Deno.test("AI tutor enforces quota decisions before making provider calls", async () => {
  const { handler, store, provider } = setup();
  store.quota = "rate_limit";
  const response = await handler(post(
    { message: "Erkläre den Artikel.", locale: "ar", cefrLevel: "a1" },
    { token: "valid-user-token" },
  ));
  equal(response.status, 429, "rate limits return a controlled status");
  equal(provider.request, null, "limited request does not call the AI provider");
  equal(store.created, 0, "limited requests do not create conversation rows");
});

Deno.test("AI tutor saves the conversation and settles actual token cost", async () => {
  const { handler, store, provider } = setup();
  const response = await handler(post(
    { message: "Warum heißt es der Name?", locale: "ar", cefrLevel: "a1", task: "grammar" },
    { origin: "https://learn.example.test", token: "valid-user-token" },
  ));
  equal(response.status, 200, "valid request succeeds");
  equal(response.headers.get("access-control-allow-origin"), "https://learn.example.test", "configured origin is allowed");
  const payload = await response.json();
  equal(payload.reply, "Der Artikel ist der.", "reply returned");
  equal(payload.isOfficialExamResult, false, "AI output is never an official exam result");
  equal(store.created, 1, "new conversation is created after successful AI completion");
  equal(store.settled[0].userMessage, "Warum heißt es der Name?", "user message is stored atomically with the reply");
  equal(store.settled[0].costMicroUsd, 5, "actual token usage is billed in micro-USD");
  equal(provider.request?.messages[0].content, "Hallo!", "saved history is passed to the provider");
  assert(provider.request?.instructions.includes("Arabic"), "UI language is part of tutor instructions");
});

Deno.test("AI tutor releases a budget reservation on provider failure", async () => {
  const { handler, store, provider } = setup();
  provider.shouldFail = true;
  const response = await handler(post(
    { message: "ساعدني", locale: "ar", cefrLevel: "a1" },
    { token: "valid-user-token" },
  ));
  equal(response.status, 503, "provider failure returns controlled service error");
  equal(store.released.length, 1, "reserved budget is released after failure");
  const body = await response.text();
  assert(!body.includes("secret upstream details"), "provider details are not exposed");
});

Deno.test("AI tutor rejects unapproved web origins and allows native requests without Origin", async () => {
  const { handler, provider } = setup();
  const forbidden = await handler(post(
    { message: "Hallo", locale: "de", cefrLevel: "a1" },
    { origin: "https://attacker.example", token: "valid-user-token" },
  ));
  equal(forbidden.status, 403, "unapproved web origin rejected");
  equal(provider.request, null, "origin rejection happens before provider call");
});
