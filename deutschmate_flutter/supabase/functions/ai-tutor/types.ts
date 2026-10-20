export type TutorRole = "user" | "assistant";

export interface TutorMessage {
  role: TutorRole;
  content: string;
}

export interface TutorUser {
  id: string;
}

export interface TutorConversation {
  id: string;
}

export interface TutorCompletion {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

export type QuotaResult =
  | "reserved"
  | "rate_limit"
  | "daily_limit"
  | "budget_exceeded"
  | "duplicate_request";

export interface TutorStore {
  findConversation(
    userId: string,
    conversationId: string,
  ): Promise<TutorConversation | null>;
  createConversation(
    userId: string,
    locale: string,
    cefrLevel: string,
  ): Promise<TutorConversation>;
  recentMessages(
    userId: string,
    conversationId: string,
    limit: number,
  ): Promise<TutorMessage[]>;
  reserveRequest(input: {
    userId: string;
    requestId: string;
    model: string;
    dailyLimit: number;
    perMinuteLimit: number;
    userDailyBudgetMicroUsd: number;
    projectDailyBudgetMicroUsd: number;
    reserveCostMicroUsd: number;
  }): Promise<QuotaResult>;
  settleRequest(input: {
    requestId: string;
    conversationId: string;
    userMessage: string;
    inputTokens: number;
    outputTokens: number;
    costMicroUsd: number;
    reply: string;
  }): Promise<void>;
  releaseRequest(requestId: string, failureCode: string): Promise<void>;
}

export interface TutorProvider {
  complete(input: {
    model: string;
    messages: TutorMessage[];
    instructions: string;
    maxOutputTokens: number;
  }): Promise<TutorCompletion>;
}

export interface TutorConfig {
  model: string;
  dailyLimit: number;
  perMinuteLimit: number;
  userDailyBudgetMicroUsd: number;
  projectDailyBudgetMicroUsd: number;
  reserveCostMicroUsd: number;
  inputCostMicroUsdPerMillion: number;
  outputCostMicroUsdPerMillion: number;
  maxOutputTokens: number;
  allowedOrigins: string[];
}

export interface TutorDependencies {
  authenticate(accessToken: string): Promise<TutorUser | null>;
  store: TutorStore;
  provider: TutorProvider;
  config: TutorConfig;
  requestId?: () => string;
}
