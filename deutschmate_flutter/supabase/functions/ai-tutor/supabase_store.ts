import type {
  QuotaResult,
  TutorConversation,
  TutorMessage,
  TutorStore,
  TutorUser,
} from "./types.ts";

export class SupabaseTutorStore implements TutorStore {
  constructor(
    private readonly projectUrl: string,
    private readonly serviceRoleKey: string,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  async authenticate(accessToken: string, publishableKey: string): Promise<TutorUser | null> {
    const response = await this.fetcher(`${this.projectUrl}/auth/v1/user`, {
      headers: {
        apikey: publishableKey,
        authorization: `Bearer ${accessToken}`,
      },
    });
    if (response.status === 401 || response.status === 403) return null;
    if (!response.ok) throw new Error("auth_service_unavailable");
    const user: unknown = await response.json();
    if (user === null || typeof user !== "object") return null;
    const id = (user as Record<string, unknown>).id;
    return typeof id === "string" ? { id } : null;
  }

  async findConversation(
    userId: string,
    conversationId: string,
  ): Promise<TutorConversation | null> {
    const query = new URLSearchParams({
      select: "id",
      id: `eq.${conversationId}`,
      user_id: `eq.${userId}`,
      limit: "1",
    });
    const rows = await this.rest("ai_conversations?" + query.toString());
    return Array.isArray(rows) && typeof rows[0]?.id === "string"
      ? { id: rows[0].id }
      : null;
  }

  async createConversation(
    userId: string,
    locale: string,
    cefrLevel: string,
  ): Promise<TutorConversation> {
    const rows = await this.rest("ai_conversations?select=id", {
      method: "POST",
      headers: { prefer: "return=representation" },
      body: JSON.stringify({ user_id: userId, locale, cefr_level: cefrLevel }),
    });
    if (!Array.isArray(rows) || typeof rows[0]?.id !== "string") {
      throw new Error("conversation_create_failed");
    }
    return { id: rows[0].id };
  }

  async recentMessages(
    userId: string,
    conversationId: string,
    limit: number,
  ): Promise<TutorMessage[]> {
    const query = new URLSearchParams({
      select: "role,content",
      user_id: `eq.${userId}`,
      conversation_id: `eq.${conversationId}`,
      order: "created_at.desc",
      limit: String(Math.min(12, Math.max(1, limit))),
    });
    const rows = await this.rest("ai_messages?" + query.toString());
    if (!Array.isArray(rows)) throw new Error("conversation_read_failed");
    return rows.reverse().flatMap((row) =>
      (row.role === "user" || row.role === "assistant") &&
          typeof row.content === "string"
        ? [{ role: row.role, content: row.content.slice(0, 2000) }]
        : []
    );
  }

  async reserveRequest(input: {
    userId: string;
    requestId: string;
    model: string;
    dailyLimit: number;
    perMinuteLimit: number;
    userDailyBudgetMicroUsd: number;
    projectDailyBudgetMicroUsd: number;
    reserveCostMicroUsd: number;
  }): Promise<QuotaResult> {
    const result = await this.rest("rpc/reserve_ai_request", {
      method: "POST",
      body: JSON.stringify({
        p_user_id: input.userId,
        p_request_id: input.requestId,
        p_model: input.model,
        p_daily_limit: input.dailyLimit,
        p_per_minute_limit: input.perMinuteLimit,
        p_user_daily_budget_microusd: input.userDailyBudgetMicroUsd,
        p_project_daily_budget_microusd: input.projectDailyBudgetMicroUsd,
        p_reserve_cost_microusd: input.reserveCostMicroUsd,
      }),
    });
    if (
      result === "reserved" || result === "rate_limit" || result === "daily_limit" ||
      result === "budget_exceeded" || result === "duplicate_request"
    ) return result;
    throw new Error("quota_response_invalid");
  }

  async settleRequest(input: {
    requestId: string;
    conversationId: string;
    userMessage: string;
    inputTokens: number;
    outputTokens: number;
    costMicroUsd: number;
    reply: string;
  }): Promise<void> {
    const settled = await this.rest("rpc/settle_ai_request", {
      method: "POST",
      body: JSON.stringify({
        p_request_id: input.requestId,
        p_conversation_id: input.conversationId,
        p_user_message: input.userMessage,
        p_input_tokens: input.inputTokens,
        p_output_tokens: input.outputTokens,
        p_cost_microusd: input.costMicroUsd,
        p_reply: input.reply,
      }),
    });
    if (settled !== true) throw new Error("usage_settlement_failed");
  }

  async releaseRequest(requestId: string, failureCode: string): Promise<void> {
    await this.rest("rpc/release_ai_request", {
      method: "POST",
      body: JSON.stringify({
        p_request_id: requestId,
        p_failure_code: failureCode,
      }),
    });
  }

  private async rest(path: string, init: RequestInit = {}): Promise<any> {
    const response = await this.fetcher(`${this.projectUrl}/rest/v1/${path}`, {
      ...init,
      headers: {
        apikey: this.serviceRoleKey,
        authorization: `Bearer ${this.serviceRoleKey}`,
        "content-type": "application/json",
        ...init.headers,
      },
    });
    if (!response.ok) throw new Error("database_operation_failed");
    const text = await response.text();
    return text.length === 0 ? null : JSON.parse(text);
  }
}
