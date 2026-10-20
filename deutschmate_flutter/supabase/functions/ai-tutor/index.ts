import { createTutorHandler } from "./handler.ts";
import { OpenAiResponsesProvider } from "./openai_provider.ts";
import { SupabaseTutorStore } from "./supabase_store.ts";
import type { TutorConfig } from "./types.ts";

function required(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing server secret/configuration: ${name}`);
  return value;
}

function positiveInteger(name: string, fallback: number): number {
  const raw = Deno.env.get(name);
  if (raw == null || raw.trim() === "") return fallback;
  const value = Number(raw);
  if (!Number.isSafeInteger(value) || value < 1) {
    throw new Error(`Invalid server configuration: ${name}`);
  }
  return value;
}

const projectUrl = required("SUPABASE_URL").replace(/\/$/, "");
const publishableKey = required("SUPABASE_ANON_KEY");
const serviceRoleKey = required("SUPABASE_SERVICE_ROLE_KEY");
const openAiKey = required("OPENAI_API_KEY");
const model = required("OPENAI_MODEL");
const inputCost = positiveInteger("AI_INPUT_MICROUSD_PER_MILLION", 0);
const outputCost = positiveInteger("AI_OUTPUT_MICROUSD_PER_MILLION", 0);
const dailyUserBudget = positiveInteger("AI_USER_DAILY_BUDGET_MICROUSD", 100_000);
const dailyProjectBudget = positiveInteger("AI_PROJECT_DAILY_BUDGET_MICROUSD", 10_000_000);
const dailyLimit = positiveInteger("AI_DAILY_REQUEST_LIMIT", 20);
const perMinuteLimit = positiveInteger("AI_PER_MINUTE_REQUEST_LIMIT", 4);
const maxOutputTokens = positiveInteger("AI_MAX_OUTPUT_TOKENS", 600);
const maxInputTokens = positiveInteger("AI_MAX_INPUT_TOKENS", 30_000);
if (maxOutputTokens > 1_000 || maxInputTokens > 40_000) {
  throw new Error("AI token caps exceed the supported safety ceiling.");
}
if (maxOutputTokens < 16) {
  throw new Error("AI_MAX_OUTPUT_TOKENS must be at least 16.");
}
if (inputCost < 1 || outputCost < 1) {
  throw new Error("Set model token prices in micro-USD per million tokens.");
}
const reserveCost = Math.ceil(
  (maxInputTokens * inputCost + maxOutputTokens * outputCost) / 1_000_000,
);
const config: TutorConfig = {
  model,
  dailyLimit,
  perMinuteLimit,
  userDailyBudgetMicroUsd: dailyUserBudget,
  projectDailyBudgetMicroUsd: dailyProjectBudget,
  reserveCostMicroUsd: reserveCost,
  inputCostMicroUsdPerMillion: inputCost,
  outputCostMicroUsdPerMillion: outputCost,
  maxOutputTokens,
  allowedOrigins: (Deno.env.get("AI_ALLOWED_ORIGINS") ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean),
};

const store = new SupabaseTutorStore(projectUrl, serviceRoleKey);
const provider = new OpenAiResponsesProvider(openAiKey);

Deno.serve(createTutorHandler({
  authenticate: (accessToken) => store.authenticate(accessToken, publishableKey),
  store,
  provider,
  config,
}));
