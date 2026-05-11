import { createClient } from "@supabase/supabase-js";
import * as bcrypt from "bcrypt";

type UserRole = "administrator" | "treasurer" | "member";
type StaffRole = "administrator" | "treasurer";

type SessionContext = {
  tokenHash: string;
  user: {
    id: string;
    username: string;
    display_name: string;
    role: UserRole;
    member_id: string | null;
  };
};

class ApiError extends Error {
  constructor(message: string, readonly status = 400) {
    super(message);
  }
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, x-pqr-session",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error("Missing Supabase Edge Function environment variables.");
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return json({ ok: true });
  }

  try {
    const route = routeParts(req);

    if (req.method === "POST" && route[0] === "login") {
      return json(await login(req));
    }

    if (req.method === "POST" && route[0] === "signup") {
      return json(await signUp(req));
    }

    const session = await requireSession(req);

    if (req.method === "POST" && route[0] === "logout") {
      return json(await logout(session));
    }

    if (req.method === "GET" && route[0] === "bootstrap") {
      return json(await bootstrap(session));
    }

    if (route[0] === "members") {
      return json(await membersRoute(req, route, session));
    }

    if (route[0] === "savings-transactions") {
      return json(await savingsRoute(req, session));
    }

    if (route[0] === "loans") {
      return json(await loansRoute(req, route, session));
    }

    if (route[0] === "users") {
      return json(await usersRoute(req, route, session));
    }

    if (route[0] === "member-accounts") {
      return json(await memberAccountsRoute(req, route, session));
    }

    if (route[0] === "backups") {
      return json(await backupsRoute(req, session));
    }

    throw new ApiError("Route was not found.", 404);
  } catch (error) {
    if (error instanceof ApiError) {
      return json({ error: error.message }, error.status);
    }

    console.error(error);
    return json({ error: "Unexpected backend error." }, 500);
  }
});

async function login(req: Request) {
  const body = await readJson(req);
  const username = cleanUsername(body.username, "Username is required.");
  const password = requiredString(body.password, "Password is required.");

  const user = await findUserByUsername(username);
  if (
    !user?.is_active ||
    !user.password_hash ||
    !(await bcrypt.compare(password, user.password_hash))
  ) {
    throw new ApiError("Invalid username or password.", 401);
  }

  const token = await createSession(user.id);
  await audit(user.id, "login", "app_users", user.id);
  return { token, user: publicUser(user) };
}

async function signUp(req: Request) {
  const body = await readJson(req);
  const fullName = requiredString(body.full_name, "Full name is required.");
  const address = requiredString(body.address, "Address is required.");
  const phone = requiredString(body.phone, "Phone is required.");
  const username = cleanUsername(body.username, "Username is required.");
  const password = requiredString(body.password, "Password is required.");

  await ensureUsernameAvailable(username);

  const { data: member, error: memberError } = await supabase
    .from("members")
    .insert({ full_name: fullName, address, phone, status: "active" })
    .select()
    .single();
  throwIfDb(memberError);

  const { data: user, error: userError } = await supabase
    .from("app_users")
    .insert({
      display_name: fullName,
      username,
      password_hash: await bcrypt.hash(password),
      role: "member",
      member_id: member.id,
    })
    .select()
    .single();

  if (userError || !user) {
    await supabase.from("members").delete().eq("id", member.id);
    throwIfDb(userError);
    throw new ApiError("Unable to create member account.", 500);
  }

  const token = await createSession(user.id);
  await audit(user.id, "member_signup", "app_users", user.id, {
    member_id: member.id,
    username,
  });
  return { token, user: publicUser(user) };
}

async function logout(session: SessionContext) {
  const { error } = await supabase
    .from("app_sessions")
    .update({ revoked_at: new Date().toISOString() })
    .eq("token_hash", session.tokenHash);

  throwIfDb(error);
  await audit(session.user.id, "logout", "app_sessions", session.tokenHash);
  return { ok: true };
}

async function bootstrap(session: SessionContext) {
  if (session.user.role === "member") {
    return await memberBootstrap(session);
  }

  const [users, members, savingsTransactions, loans, repayments, backupRuns] =
    await Promise.all([
      selectAll("app_users", "created_at", true),
      selectAll("members", "member_code"),
      selectAll("savings_transactions", "occurred_at", false),
      selectAll("loans", "applied_at", false),
      selectAll("repayments", "paid_at", false),
      selectAll("backup_runs", "created_at", false),
    ]);

  return {
    users: users.map(publicUser),
    members,
    savings_transactions: savingsTransactions,
    loans,
    repayments,
    backup_runs: backupRuns,
  };
}

async function memberBootstrap(session: SessionContext) {
  const memberId = session.user.member_id;
  if (!memberId) {
    throw new ApiError("Member account is not linked.", 403);
  }

  const [members, savingsTransactions, loans, users] = await Promise.all([
    selectBy("members", "id", memberId, "member_code"),
    selectBy(
      "savings_transactions",
      "member_id",
      memberId,
      "occurred_at",
      false,
    ),
    selectBy("loans", "member_id", memberId, "applied_at", false),
    selectBy("app_users", "id", session.user.id, "created_at", true),
  ]);

  const loanIds = loans.map((loan: any) => loan.id).filter(Boolean);
  const repayments = loanIds.length > 0
    ? await selectIn("repayments", "loan_id", loanIds, "paid_at", false)
    : [];

  return {
    users: users.map(publicUser),
    members,
    savings_transactions: savingsTransactions,
    loans,
    repayments,
    backup_runs: [],
  };
}

async function membersRoute(
  req: Request,
  route: string[],
  session: SessionContext,
) {
  if (req.method === "GET") {
    if (session.user.role === "member") {
      if (!session.user.member_id) {
        return [];
      }
      return await selectBy(
        "members",
        "id",
        session.user.member_id,
        "member_code",
      );
    }
    return await selectAll("members", "member_code");
  }

  requireAdministrator(session);

  if (req.method === "POST" && route.length === 1) {
    const body = await readJson(req);
    const { data, error } = await supabase
      .from("members")
      .insert({
        full_name: requiredString(body.full_name, "Full name is required."),
        address: requiredString(body.address, "Address is required."),
        phone: requiredString(body.phone, "Phone is required."),
        status: body.status ?? "active",
      })
      .select()
      .single();

    throwIfDb(error);
    await audit(session.user.id, "create_member", "members", data.id, data);
    return data;
  }

  if (route.length !== 2) {
    throw new ApiError("Member ID is required.", 404);
  }

  const memberId = route[1];

  if (req.method === "PATCH") {
    const body = await readJson(req);
    const updates: Record<string, unknown> = {};
    for (const key of ["full_name", "address", "phone", "status"]) {
      if (body[key] !== undefined) {
        updates[key] = body[key];
      }
    }

    const { data, error } = await supabase
      .from("members")
      .update(updates)
      .eq("id", memberId)
      .select()
      .single();

    throwIfDb(error);
    await audit(session.user.id, "update_member", "members", memberId, updates);
    return data;
  }

  if (req.method === "DELETE") {
    const { error } = await supabase.from("members").delete().eq(
      "id",
      memberId,
    );
    throwIfDb(error);
    await audit(session.user.id, "delete_member", "members", memberId);
    return { deleted: true, id: memberId };
  }

  throw new ApiError("Method is not allowed.", 405);
}

async function savingsRoute(req: Request, session: SessionContext) {
  if (req.method === "GET") {
    if (session.user.role === "member") {
      if (!session.user.member_id) {
        return [];
      }
      return await selectBy(
        "savings_transactions",
        "member_id",
        session.user.member_id,
        "occurred_at",
        false,
      );
    }
    return await selectAll("savings_transactions", "occurred_at", false);
  }

  if (req.method === "POST") {
    requireStaff(session);
    const body = await readJson(req);
    const { data, error } = await supabase.rpc("record_savings_transaction", {
      p_actor_id: session.user.id,
      p_member_id: requiredString(body.member_id, "Member is required."),
      p_type: requiredString(body.type, "Transaction type is required."),
      p_amount: requiredPositiveNumber(body.amount, "Amount is required."),
      p_note: `${body.note ?? ""}`,
    });

    throwIfDb(error);
    return data;
  }

  throw new ApiError("Method is not allowed.", 405);
}

async function loansRoute(
  req: Request,
  route: string[],
  session: SessionContext,
) {
  if (req.method === "GET" && route.length === 1) {
    if (session.user.role === "member") {
      if (!session.user.member_id) {
        return [];
      }
      return await selectBy(
        "loans",
        "member_id",
        session.user.member_id,
        "applied_at",
        false,
      );
    }
    return await selectAll("loans", "applied_at", false);
  }

  if (req.method === "POST" && route.length === 1) {
    const body = await readJson(req);
    const memberId = session.user.role === "member"
      ? session.user.member_id
      : requiredString(body.member_id, "Member is required.");
    if (!memberId) {
      throw new ApiError("Member account is not linked.", 403);
    }

    const insert = {
      member_id: memberId,
      principal: requiredPositiveNumber(
        body.principal,
        "Principal is required.",
      ),
      term_months: optionalInteger(
        body.term_months,
        "Term must be a whole number of months.",
      ),
      applied_at: new Date().toISOString(),
      status: "pending",
    };

    const { data, error } = await supabase
      .from("loans")
      .insert(insert)
      .select()
      .single();

    throwIfDb(error);
    await audit(session.user.id, "create_loan", "loans", data.id, data);
    return data;
  }

  if (route.length === 3 && route[2] === "status" && req.method === "PATCH") {
    requireStaff(session);
    const body = await readJson(req);
    const status = requiredString(body.status, "Status is required.");
    if (!["pending", "approved", "paid", "rejected"].includes(status)) {
      throw new ApiError("Invalid loan status.");
    }

    const updates: Record<string, unknown> = { status };
    if (status === "approved") {
      const annualInterestRate = requiredNonNegativeNumber(
        body.annual_interest_rate,
        "Interest rate is required.",
      );
      const termMonths = requiredInteger(body.term_months, "Term is required.");
      const approvedAt = new Date();
      const dueDate = new Date(approvedAt);
      dueDate.setMonth(dueDate.getMonth() + termMonths);
      updates.annual_interest_rate = annualInterestRate;
      updates.term_months = termMonths;
      updates.approved_at = approvedAt.toISOString();
      updates.due_date = dueDate.toISOString();
    }

    const { data, error } = await supabase
      .from("loans")
      .update(updates)
      .eq("id", route[1])
      .select()
      .single();

    throwIfDb(error);
    await audit(
      session.user.id,
      "update_loan_status",
      "loans",
      route[1],
      updates,
    );
    return data;
  }

  if (
    route.length === 3 && route[2] === "repayments" && req.method === "POST"
  ) {
    requireStaff(session);
    const body = await readJson(req);
    const { data, error } = await supabase.rpc("record_loan_repayment", {
      p_actor_id: session.user.id,
      p_loan_id: route[1],
      p_amount: requiredPositiveNumber(body.amount, "Amount is required."),
      p_note: `${body.note ?? ""}`,
    });

    throwIfDb(error);
    return data;
  }

  throw new ApiError("Method is not allowed.", 405);
}

async function usersRoute(
  req: Request,
  route: string[],
  session: SessionContext,
) {
  requireAdministrator(session);

  if (req.method === "GET") {
    const users = await selectAll("app_users", "created_at", true);
    return users.map(publicUser);
  }

  if (req.method === "POST" && route.length === 1) {
    const body = await readJson(req);
    const username = cleanUsername(body.username, "Username is required.");
    await ensureUsernameAvailable(username);
    const { data, error } = await supabase
      .from("app_users")
      .insert({
        display_name: requiredString(
          body.display_name,
          "Display name is required.",
        ),
        username,
        password_hash: await bcrypt.hash(
          requiredString(body.password, "Password is required."),
        ),
        role: requiredString(body.role, "Role is required."),
      })
      .select()
      .single();

    throwIfDb(error);
    await audit(
      session.user.id,
      "create_user",
      "app_users",
      data.id,
      publicUser(data),
    );
    return publicUser(data);
  }

  if (req.method === "PATCH" && route.length === 2) {
    const body = await readJson(req);
    const username = cleanUsername(body.username, "Username is required.");
    await ensureUsernameAvailable(username, route[1]);
    const password = `${body.password ?? ""}`.trim();
    const updates: Record<string, unknown> = {
      display_name: requiredString(
        body.display_name,
        "Display name is required.",
      ),
      username,
      role: requiredString(body.role, "Role is required."),
      is_active: body.is_active ?? true,
    };
    if (password !== "") {
      updates.password_hash = await bcrypt.hash(password);
    }

    const { data, error } = await supabase
      .from("app_users")
      .update(updates)
      .eq("id", route[1])
      .select()
      .single();

    throwIfDb(error);
    await audit(
      session.user.id,
      "update_user",
      "app_users",
      route[1],
      publicUser(data),
    );
    return publicUser(data);
  }

  throw new ApiError("Method is not allowed.", 405);
}

async function memberAccountsRoute(
  req: Request,
  route: string[],
  session: SessionContext,
) {
  requireAdministrator(session);

  if (req.method !== "POST" || route.length !== 1) {
    throw new ApiError("Method is not allowed.", 405);
  }

  const body = await readJson(req);
  const fullName = requiredString(body.full_name, "Full name is required.");
  const address = requiredString(body.address, "Address is required.");
  const phone = requiredString(body.phone, "Phone is required.");
  const username = cleanUsername(body.username, "Username is required.");
  const password = requiredString(body.password, "Password is required.");
  await ensureUsernameAvailable(username);

  const { data: member, error: memberError } = await supabase
    .from("members")
    .insert({
      full_name: fullName,
      address,
      phone,
      status: "active",
    })
    .select()
    .single();
  throwIfDb(memberError);

  const { data: user, error: userError } = await supabase
    .from("app_users")
    .insert({
      display_name: fullName,
      username,
      password_hash: await bcrypt.hash(password),
      role: "member",
      member_id: member.id,
    })
    .select()
    .single();
  if (userError) {
    await supabase.from("members").delete().eq("id", member.id);
    throwIfDb(userError);
  }
  if (!user) {
    await supabase.from("members").delete().eq("id", member.id);
    throw new ApiError("Unable to create member user.", 500);
  }

  await audit(session.user.id, "create_member", "members", member.id, member);
  await audit(
    session.user.id,
    "create_member_user",
    "app_users",
    user.id,
    {
      member_id: member.id,
      username,
    },
  );

  return publicUser(user);
}

async function backupsRoute(req: Request, session: SessionContext) {
  requireStaff(session);

  if (req.method === "GET") {
    return await selectAll("backup_runs", "created_at", false);
  }

  if (req.method === "POST") {
    const [members, savingsTransactions, loans, repayments] = await Promise.all(
      [
        selectAll("members", "member_code"),
        selectAll("savings_transactions", "occurred_at", false),
        selectAll("loans", "applied_at", false),
        selectAll("repayments", "paid_at", false),
      ],
    );

    const summary = {
      generated_at: new Date().toISOString(),
      total_members: members.length,
      active_members: members.filter((member: any) =>
        member.status === "active"
      ).length,
      savings_transactions: savingsTransactions.length,
      loans: loans.length,
      repayments: repayments.length,
    };

    const { data, error } = await supabase
      .from("backup_runs")
      .insert({
        requested_by: session.user.id,
        status: "completed",
        summary,
      })
      .select()
      .single();

    throwIfDb(error);
    await audit(session.user.id, "run_backup", "backup_runs", data.id, summary);
    return data;
  }

  throw new ApiError("Method is not allowed.", 405);
}

async function requireSession(req: Request): Promise<SessionContext> {
  const authHeader = req.headers.get("authorization") ?? "";
  const bearer = authHeader.match(/^Bearer\s+(.+)$/i)?.[1];
  const token = bearer ?? req.headers.get("x-pqr-session");

  if (!token) {
    throw new ApiError("Authentication is required.", 401);
  }

  const tokenHash = await sha256Hex(token);
  const data = await findSession(tokenHash);

  const user = (Array.isArray(data?.user) ? data?.user[0] : data?.user) as
    | any
    | null;
  if (
    !data ||
    data.revoked_at ||
    new Date(data.expires_at).getTime() <= Date.now() ||
    !user?.is_active
  ) {
    throw new ApiError("Session has expired. Please sign in again.", 401);
  }

  await supabase
    .from("app_sessions")
    .update({ last_seen_at: new Date().toISOString() })
    .eq("token_hash", tokenHash);

  return {
    tokenHash,
    user: {
      id: user.id,
      username: user.username,
      display_name: user.display_name,
      role: user.role,
      member_id: user.member_id ?? null,
    },
  };
}

async function findSession(tokenHash: string) {
  const withMemberId = await supabase
    .from("app_sessions")
    .select(
      "token_hash, expires_at, revoked_at, user:app_users(id, username, display_name, role, member_id, is_active)",
    )
    .eq("token_hash", tokenHash)
    .maybeSingle();

  if (!withMemberId.error) {
    return withMemberId.data;
  }

  const message = `${withMemberId.error.message ?? ""}`;
  if (!message.includes("member_id")) {
    throwIfDb(withMemberId.error);
  }

  const withoutMemberId = await supabase
    .from("app_sessions")
    .select(
      "token_hash, expires_at, revoked_at, user:app_users(id, username, display_name, role, is_active)",
    )
    .eq("token_hash", tokenHash)
    .maybeSingle();

  throwIfDb(withoutMemberId.error);
  return withoutMemberId.data;
}

async function selectAll(table: string, order: string, ascending = true) {
  const { data, error } = await supabase
    .from(table)
    .select("*")
    .order(order, { ascending });

  throwIfDb(error);
  return data ?? [];
}

async function selectBy(
  table: string,
  column: string,
  value: string,
  order: string,
  ascending = true,
) {
  const { data, error } = await supabase
    .from(table)
    .select("*")
    .eq(column, value)
    .order(order, { ascending });

  throwIfDb(error);
  return data ?? [];
}

async function selectIn(
  table: string,
  column: string,
  values: string[],
  order: string,
  ascending = true,
) {
  const { data, error } = await supabase
    .from(table)
    .select("*")
    .in(column, values)
    .order(order, { ascending });

  throwIfDb(error);
  return data ?? [];
}

async function findUserByUsername(username: string) {
  const withMemberId = await supabase
    .from("app_users")
    .select(
      "id, username, display_name, role, member_id, is_active, password_hash, created_at, updated_at",
    )
    .ilike("username", username)
    .maybeSingle();

  if (!withMemberId.error) {
    return withMemberId.data;
  }

  const message = `${withMemberId.error.message ?? ""}`;
  if (!message.includes("member_id")) {
    throwIfDb(withMemberId.error);
  }

  const withoutMemberId = await supabase
    .from("app_users")
    .select(
      "id, username, display_name, role, is_active, password_hash, created_at, updated_at",
    )
    .ilike("username", username)
    .maybeSingle();

  throwIfDb(withoutMemberId.error);
  return withoutMemberId.data;
}

async function ensureUsernameAvailable(
  username: string,
  currentUserId?: string,
) {
  const existing = await findUserByUsername(username);
  if (existing && existing.id !== currentUserId) {
    throw new ApiError("Username already exists.", 400);
  }
}

async function createSession(userId: string) {
  const token = randomHex(32);
  const { error } = await supabase.from("app_sessions").insert({
    token_hash: await sha256Hex(token),
    user_id: userId,
    expires_at: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
  });

  throwIfDb(error);
  return token;
}

async function audit(
  actorId: string,
  eventType: string,
  tableName: string,
  recordId: string,
  details: Record<string, unknown> = {},
) {
  const { error } = await supabase.from("audit_events").insert({
    actor_id: actorId,
    event_type: eventType,
    table_name: tableName,
    record_id: recordId,
    details,
  });

  if (error) {
    console.error("Audit insert failed", error);
  }
}

function publicUser(user: any) {
  return {
    id: user.id,
    username: user.username,
    display_name: user.display_name,
    role: user.role,
    member_id: user.member_id,
    is_active: user.is_active,
    created_at: user.created_at,
    updated_at: user.updated_at,
  };
}

function requireAdministrator(session: SessionContext) {
  if (session.user.role !== "administrator") {
    throw new ApiError("Administrator access is required.", 403);
  }
}

function requireStaff(
  session: SessionContext,
): asserts session is SessionContext & {
  user: SessionContext["user"] & { role: StaffRole };
} {
  if (session.user.role === "member") {
    throw new ApiError("Staff access is required.", 403);
  }
}

function throwIfDb(error: any) {
  if (!error) {
    return;
  }

  const message = `${error.message ?? ""}`;
  if (
    message.includes("app_users_username_lower_key") ||
    message.includes("duplicate key value violates unique constraint")
  ) {
    throw new ApiError("Username already exists.", 400);
  }
  if (
    message.includes("exceeds") ||
    message.includes("already exists") ||
    message.includes("duplicate key value") ||
    error.code === "P0001"
  ) {
    throw new ApiError(error.message, 400);
  }

  throw new ApiError(error.message ?? "Database operation failed.", 500);
}

async function readJson(req: Request) {
  if (req.method === "GET" || req.method === "DELETE") {
    return {};
  }

  try {
    return await req.json();
  } catch (_) {
    throw new ApiError("Request body must be valid JSON.");
  }
}

function requiredString(value: unknown, message: string) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new ApiError(message);
  }
  return value.trim();
}

function cleanUsername(value: unknown, message: string) {
  return requiredString(value, message).toLowerCase();
}

function requiredPositiveNumber(value: unknown, message: string) {
  const numberValue = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(numberValue) || numberValue <= 0) {
    throw new ApiError(message);
  }
  return numberValue;
}

function requiredNonNegativeNumber(value: unknown, message: string) {
  const numberValue = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(numberValue) || numberValue < 0) {
    throw new ApiError(message);
  }
  return numberValue;
}

function requiredInteger(value: unknown, message: string) {
  const numberValue = requiredPositiveNumber(value, message);
  if (!Number.isInteger(numberValue)) {
    throw new ApiError(message);
  }
  return numberValue;
}

function optionalInteger(value: unknown, message: string) {
  if (value === undefined || value === null || value === "") {
    return null;
  }
  return requiredInteger(value, message);
}

function routeParts(req: Request) {
  const parts = new URL(req.url).pathname.split("/").filter(Boolean);
  const routeIndex = parts.findIndex((part) => routeNames.has(part));
  return routeIndex === -1 ? [] : parts.slice(routeIndex);
}

const routeNames = new Set([
  "login",
  "signup",
  "logout",
  "bootstrap",
  "members",
  "savings-transactions",
  "loans",
  "users",
  "member-accounts",
  "backups",
]);

async function sha256Hex(value: string) {
  const bytes = new TextEncoder().encode(value);
  const hash = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(hash))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function randomHex(byteCount: number) {
  const bytes = crypto.getRandomValues(new Uint8Array(byteCount));
  return Array.from(bytes)
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Connection": "keep-alive",
    },
  });
}
