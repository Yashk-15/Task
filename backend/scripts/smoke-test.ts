// scripts/smoke-test.ts
//
// Automated API smoke test suite.
// Uses only Node.js built-in fetch — no external test runners or dependencies required.
//
// Usage:
//   npm run smoke
//   BASE_URL=http://localhost:5000/api npm run smoke
//   npm run smoke -- --ratelimit

const BASE_URL = process.env.BASE_URL || "http://localhost:5000/api";

// ─── Test Result Counters ─────────────────────────────────────────────────────
let passed = 0;
let failed = 0;

function pass(name: string): void {
  passed++;
  console.log(`PASS  ${name}`);
}

function fail(name: string, expected: string, got: string | number): void {
  failed++;
  console.log(`FAIL  ${name} (expected ${expected}, got ${got})`);
}

// ─── HTTP Helper ──────────────────────────────────────────────────────────────
interface FetchOptions {
  method?: string;
  token?: string;
  body?: unknown;
  ip?: string;
}

const runClientIp = `198.51.100.${Math.floor(Math.random() * 200) + 1}`;

async function api(path: string, options: FetchOptions = {}): Promise<{ status: number; body: any }> {
  const url = `${BASE_URL}${path}`;
  const headers: Record<string, string> = {
    "X-Forwarded-For": options.ip || runClientIp,
  };

  if (options.token) {
    headers["Authorization"] = `Bearer ${options.token}`;
  }
  if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
  }

  try {
    const res = await fetch(url, {
      method: options.method || "GET",
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });

    let body: any = null;
    const text = await res.text();
    if (text) {
      try {
        body = JSON.parse(text);
      } catch {
        body = text;
      }
    }

    return { status: res.status, body };
  } catch (err: any) {
    return { status: 0, body: { error: err.message } };
  }
}

// ─── Main Test Runner ─────────────────────────────────────────────────────────
async function runSmokeTests() {
  console.log("==================================================");
  console.log("🚀 API Smoke Tests");
  console.log(`Target: ${BASE_URL}`);
  console.log("==================================================\n");

  const timestamp = Date.now();
  const emailA = `a_${timestamp}@test.com`;
  const emailB = `b_${timestamp}@test.com`;
  const password = "Password123";

  let tokenA = "";
  let tokenB = "";
  const createdProjectIds: string[] = [];
  let projectAId = "";
  let taskAId = "";

  try {
    // ═════════════════════════════════════════════════════════════════════════
    // AUTH CHECKS
    // ═════════════════════════════════════════════════════════════════════════
    console.log("--- AUTH ---");

    // 1. Register User A [201]
    const regARes = await api("/auth/register", {
      method: "POST",
      body: { fullName: "User Alpha", email: emailA, password },
    });
    if (regARes.status === 201 && regARes.body?.data?.token) {
      tokenA = regARes.body.data.token;
      pass("register A [201]");
    } else {
      fail("register A [201]", "201 with token", regARes.status);
    }

    // Register User B to get tokenB (needed for ownership checks)
    const regBRes = await api("/auth/register", {
      method: "POST",
      body: { fullName: "User Beta", email: emailB, password },
    });
    if (regBRes.status === 201 && regBRes.body?.data?.token) {
      tokenB = regBRes.body.data.token;
    }

    // 2. Duplicate email [409]
    const dupRes = await api("/auth/register", {
      method: "POST",
      body: { fullName: "User Duplicate", email: emailA, password },
    });
    if (dupRes.status === 409) {
      pass("duplicate email [409]");
    } else {
      fail("duplicate email [409]", "409", dupRes.status);
    }

    // 3. Invalid register body [400]
    const invRegRes = await api("/auth/register", {
      method: "POST",
      body: { fullName: "", email: "not-an-email", password: "short" },
    });
    if (invRegRes.status === 400) {
      pass("invalid register body [400]");
    } else {
      fail("invalid register body [400]", "400", invRegRes.status);
    }

    // 4. Login A correct [200]
    const loginRes = await api("/auth/login", {
      method: "POST",
      body: { email: emailA, password },
    });
    if (loginRes.status === 200 && loginRes.body?.data?.token) {
      pass("login A correct [200]");
    } else {
      fail("login A correct [200]", "200", loginRes.status);
    }

    // 5. Login wrong password [401]
    const wrongPassRes = await api("/auth/login", {
      method: "POST",
      body: { email: emailA, password: "WrongPassword999" },
    });
    if (wrongPassRes.status === 401) {
      pass("login wrong password [401]");
    } else {
      fail("login wrong password [401]", "401", wrongPassRes.status);
    }

    // 6. GET /auth/me with token [200] and NO passwordHash
    const meRes = await api("/auth/me", { token: tokenA });
    const meBodyStr = JSON.stringify(meRes.body);
    const hasPasswordHash = meBodyStr.includes("passwordHash");
    if (meRes.status === 200 && !hasPasswordHash) {
      pass("GET /auth/me with token [200] without passwordHash");
    } else if (meRes.status !== 200) {
      fail("GET /auth/me with token [200] without passwordHash", "200", meRes.status);
    } else {
      fail("GET /auth/me with token [200] without passwordHash", "response without passwordHash", "found passwordHash in body");
    }

    // 7. GET /auth/me without token [401]
    const meNoTokenRes = await api("/auth/me");
    if (meNoTokenRes.status === 401) {
      pass("GET /auth/me without token [401]");
    } else {
      fail("GET /auth/me without token [401]", "401", meNoTokenRes.status);
    }

    // 8. GET /auth/me with garbage token [401]
    const meGarbageRes = await api("/auth/me", { token: "garbage.token.here" });
    if (meGarbageRes.status === 401) {
      pass("GET /auth/me with garbage token [401]");
    } else {
      fail("GET /auth/me with garbage token [401]", "401", meGarbageRes.status);
    }

    // 9. POST /auth/logout with token [200]
    const logoutRes = await api("/auth/logout", { method: "POST", token: tokenA });
    if (logoutRes.status === 200) {
      pass("POST /auth/logout with token [200]");
    } else {
      fail("POST /auth/logout with token [200]", "200", logoutRes.status);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // PROJECTS (as User A)
    // ═════════════════════════════════════════════════════════════════════════
    console.log("\n--- PROJECTS ---");

    // 10. Create project [201]
    const createProjRes = await api("/projects", {
      method: "POST",
      token: tokenA,
      body: {
        name: "Smoke Test Project A",
        description: "Initial description for testing",
        status: "NOT_STARTED",
        startDate: "2026-10-01T00:00:00.000Z",
        endDate: "2026-10-31T00:00:00.000Z",
      },
    });
    if (createProjRes.status === 201 && createProjRes.body?.data?.project?.id) {
      projectAId = createProjRes.body.data.project.id;
      createdProjectIds.push(projectAId);
      pass("create project [201]");
    } else {
      fail("create project [201]", "201", createProjRes.status);
    }

    // 11. List projects [200] contains it
    const listProjRes = await api("/projects", { token: tokenA });
    const containsCreated = Array.isArray(listProjRes.body?.data) &&
      listProjRes.body.data.some((p: any) => p.id === projectAId);
    if (listProjRes.status === 200 && containsCreated) {
      pass("list projects [200] contains it");
    } else {
      fail("list projects [200] contains it", "200 and project in list", `${listProjRes.status} (found: ${containsCreated})`);
    }

    // 12. Get project by id [200]
    const getProjRes = await api(`/projects/${projectAId}`, { token: tokenA });
    if (getProjRes.status === 200 && getProjRes.body?.data?.project?.id === projectAId) {
      pass("get project by id [200]");
    } else {
      fail("get project by id [200]", "200", getProjRes.status);
    }

    // 13. Update project [200]
    const updateProjRes = await api(`/projects/${projectAId}`, {
      method: "PUT",
      token: tokenA,
      body: {
        name: "Smoke Test Project A Updated",
        status: "IN_PROGRESS",
      },
    });
    if (updateProjRes.status === 200 && updateProjRes.body?.data?.project?.name === "Smoke Test Project A Updated") {
      pass("update project [200]");
    } else {
      fail("update project [200]", "200", updateProjRes.status);
    }

    // 14. Search by name [200] finds it
    const searchProjRes = await api("/projects?search=Updated", { token: tokenA });
    const foundBySearch = Array.isArray(searchProjRes.body?.data) &&
      searchProjRes.body.data.some((p: any) => p.id === projectAId);
    if (searchProjRes.status === 200 && foundBySearch) {
      pass("search by name [200] finds it");
    } else {
      fail("search by name [200] finds it", "200 with matching project", searchProjRes.status);
    }

    // 15. Filter by status [200]
    const filterProjRes = await api("/projects?status=IN_PROGRESS", { token: tokenA });
    const allInProgress = Array.isArray(filterProjRes.body?.data) &&
      filterProjRes.body.data.every((p: any) => p.status === "IN_PROGRESS");
    if (filterProjRes.status === 200 && allInProgress) {
      pass("filter by status [200]");
    } else {
      fail("filter by status [200]", "200 with IN_PROGRESS projects", filterProjRes.status);
    }

    // 16. Invalid status [400]
    const invStatusRes = await api("/projects", {
      method: "POST",
      token: tokenA,
      body: { name: "Invalid Status Project", status: "NOT_A_VALID_STATUS" },
    });
    if (invStatusRes.status === 400) {
      pass("invalid status [400]");
    } else {
      fail("invalid status [400]", "400", invStatusRes.status);
    }

    // 17. endDate before startDate [400]
    const badDatesRes = await api("/projects", {
      method: "POST",
      token: tokenA,
      body: {
        name: "Bad Dates Project",
        startDate: "2026-10-20T00:00:00.000Z",
        endDate: "2026-10-10T00:00:00.000Z",
      },
    });
    if (badDatesRes.status === 400) {
      pass("endDate before startDate [400]");
    } else {
      fail("endDate before startDate [400]", "400", badDatesRes.status);
    }

    // 18. Empty name [400]
    const emptyNameRes = await api("/projects", {
      method: "POST",
      token: tokenA,
      body: { name: "   " },
    });
    if (emptyNameRes.status === 400) {
      pass("empty name [400]");
    } else {
      fail("empty name [400]", "400", emptyNameRes.status);
    }

    // 19. Invalid uuid in URL [400]
    const invUuidProjRes = await api("/projects/not-a-valid-uuid", { token: tokenA });
    if (invUuidProjRes.status === 400) {
      pass("invalid uuid in the URL [400]");
    } else {
      fail("invalid uuid in the URL [400]", "400", invUuidProjRes.status);
    }

    // 20. Request without token [401]
    const noTokenProjRes = await api("/projects");
    if (noTokenProjRes.status === 401) {
      pass("request without token [401]");
    } else {
      fail("request without token [401]", "401", noTokenProjRes.status);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // TASKS (as User A)
    // ═════════════════════════════════════════════════════════════════════════
    console.log("\n--- TASKS ---");

    // 21. Create task [201]
    const createTaskRes = await api("/tasks", {
      method: "POST",
      token: tokenA,
      body: {
        projectId: projectAId,
        name: "Smoke Test Task 1",
        description: "Task description for testing",
        priority: "HIGH",
        status: "PENDING",
        dueDate: "2026-10-25T00:00:00.000Z",
      },
    });
    if (createTaskRes.status === 201 && createTaskRes.body?.data?.task?.id) {
      taskAId = createTaskRes.body.data.task.id;
      pass("create task [201]");
    } else {
      fail("create task [201]", "201", createTaskRes.status);
    }

    // 22. List tasks [200]
    const listTasksRes = await api("/tasks", { token: tokenA });
    const containsTask = Array.isArray(listTasksRes.body?.data) &&
      listTasksRes.body.data.some((t: any) => t.id === taskAId);
    if (listTasksRes.status === 200 && containsTask) {
      pass("list tasks [200]");
    } else {
      fail("list tasks [200]", "200 with created task", listTasksRes.status);
    }

    // 23. Get task by id [200]
    const getTaskRes = await api(`/tasks/${taskAId}`, { token: tokenA });
    if (getTaskRes.status === 200 && getTaskRes.body?.data?.task?.id === taskAId) {
      pass("get task by id [200]");
    } else {
      fail("get task by id [200]", "200", getTaskRes.status);
    }

    // 24. Update to COMPLETED [200] and status is COMPLETED
    const updateTaskRes = await api(`/tasks/${taskAId}`, {
      method: "PUT",
      token: tokenA,
      body: { status: "COMPLETED" },
    });
    if (updateTaskRes.status === 200 && updateTaskRes.body?.data?.task?.status === "COMPLETED") {
      pass("update to COMPLETED [200] and status is COMPLETED");
    } else {
      fail("update to COMPLETED [200] and status is COMPLETED", "200 with status COMPLETED", updateTaskRes.status);
    }

    // 25. Filter by status and priority [200]
    const filterTaskRes = await api("/tasks?status=COMPLETED&priority=HIGH", { token: tokenA });
    if (filterTaskRes.status === 200 && Array.isArray(filterTaskRes.body?.data)) {
      pass("filter by status and priority [200]");
    } else {
      fail("filter by status and priority [200]", "200", filterTaskRes.status);
    }

    // 26. Invalid priority [400]
    const invPriorityRes = await api("/tasks", {
      method: "POST",
      token: tokenA,
      body: {
        projectId: projectAId,
        name: "Invalid Priority Task",
        priority: "CRITICAL_MAX",
      },
    });
    if (invPriorityRes.status === 400) {
      pass("invalid priority [400]");
    } else {
      fail("invalid priority [400]", "400", invPriorityRes.status);
    }

    // 27. Create with nonexistent projectId [404 or 400]
    const nonExistProjRes = await api("/tasks", {
      method: "POST",
      token: tokenA,
      body: {
        projectId: "00000000-0000-0000-0000-000000000000",
        name: "Orphan Task",
      },
    });
    if (nonExistProjRes.status === 404 || nonExistProjRes.status === 400) {
      pass("create with nonexistent projectId [404 or 400]");
    } else {
      fail("create with nonexistent projectId [404 or 400]", "404 or 400", nonExistProjRes.status);
    }

    // 28. Delete task [204 or 200] (using a temporary task so taskAId remains for cascade test)
    const tempTaskRes = await api("/tasks", {
      method: "POST",
      token: tokenA,
      body: {
        projectId: projectAId,
        name: "Temporary Task To Delete",
      },
    });
    const tempTaskId = tempTaskRes.body?.data?.task?.id;
    if (tempTaskId) {
      const delTaskRes = await api(`/tasks/${tempTaskId}`, {
        method: "DELETE",
        token: tokenA,
      });
      if (delTaskRes.status === 200 || delTaskRes.status === 204) {
        pass("delete task [204 or 200]");
      } else {
        fail("delete task [204 or 200]", "200 or 204", delTaskRes.status);
      }
    } else {
      fail("delete task [204 or 200]", "temporary task created", tempTaskRes.status);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // DASHBOARD
    // ═════════════════════════════════════════════════════════════════════════
    console.log("\n--- DASHBOARD ---");

    // 29. GET /dashboard as A [200] with the five numeric fields and totalProjects >= 1
    const dashRes = await api("/dashboard", { token: tokenA });
    const dashData = dashRes.body?.data;
    const hasNumericFields =
      dashData &&
      typeof dashData.totalProjects === "number" &&
      typeof dashData.totalTasks === "number" &&
      typeof dashData.completedTasks === "number" &&
      typeof dashData.pendingTasks === "number" &&
      typeof dashData.projectsInProgress === "number";
    const projGteOne = hasNumericFields && dashData.totalProjects >= 1;

    if (dashRes.status === 200 && projGteOne) {
      pass("GET /dashboard as A [200] with 5 numeric fields and totalProjects >= 1");
    } else {
      fail("GET /dashboard as A [200] with 5 numeric fields and totalProjects >= 1", "200 with totalProjects >= 1", `${dashRes.status} (fields: ${hasNumericFields}, gte1: ${projGteOne})`);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // OWNERSHIP (User B using A's ids; all must be 404)
    // ═════════════════════════════════════════════════════════════════════════
    console.log("\n--- OWNERSHIP ---");

    // 30. Get A's project as B [404]
    const bGetProj = await api(`/projects/${projectAId}`, { token: tokenB });
    if (bGetProj.status === 404) {
      pass("ownership: get A's project as B [404]");
    } else {
      fail("ownership: get A's project as B [404]", "404", bGetProj.status);
    }

    // 31. Update A's project as B [404]
    const bUpdProj = await api(`/projects/${projectAId}`, {
      method: "PUT",
      token: tokenB,
      body: { name: "Attempted Hack By B" },
    });
    if (bUpdProj.status === 404) {
      pass("ownership: update A's project as B [404]");
    } else {
      fail("ownership: update A's project as B [404]", "404", bUpdProj.status);
    }

    // 32. Delete A's project as B [404]
    const bDelProj = await api(`/projects/${projectAId}`, {
      method: "DELETE",
      token: tokenB,
    });
    if (bDelProj.status === 404) {
      pass("ownership: delete A's project as B [404]");
    } else {
      fail("ownership: delete A's project as B [404]", "404", bDelProj.status);
    }

    // 33. Get A's task as B [404]
    const bGetTask = await api(`/tasks/${taskAId}`, { token: tokenB });
    if (bGetTask.status === 404) {
      pass("ownership: get A's task as B [404]");
    } else {
      fail("ownership: get A's task as B [404]", "404", bGetTask.status);
    }

    // 34. Update A's task as B [404]
    const bUpdTask = await api(`/tasks/${taskAId}`, {
      method: "PUT",
      token: tokenB,
      body: { name: "Attempted Task Hack By B" },
    });
    if (bUpdTask.status === 404) {
      pass("ownership: update A's task as B [404]");
    } else {
      fail("ownership: update A's task as B [404]", "404", bUpdTask.status);
    }

    // 35. Delete A's task as B [404]
    const bDelTask = await api(`/tasks/${taskAId}`, {
      method: "DELETE",
      token: tokenB,
    });
    if (bDelTask.status === 404) {
      pass("ownership: delete A's task as B [404]");
    } else {
      fail("ownership: delete A's task as B [404]", "404", bDelTask.status);
    }

    // 36. Create a task in A's project as B [404]
    const bCreateTask = await api("/tasks", {
      method: "POST",
      token: tokenB,
      body: { projectId: projectAId, name: "Intruder Task" },
    });
    if (bCreateTask.status === 404) {
      pass("ownership: create task in A's project as B [404]");
    } else {
      fail("ownership: create task in A's project as B [404]", "404", bCreateTask.status);
    }

    // 37. B's project list must be empty
    const bProjectsRes = await api("/projects", { token: tokenB });
    const bProjectsEmpty =
      bProjectsRes.status === 200 &&
      Array.isArray(bProjectsRes.body?.data) &&
      bProjectsRes.body.data.length === 0;
    if (bProjectsEmpty) {
      pass("ownership: B's project list must be empty [200]");
    } else {
      fail("ownership: B's project list must be empty [200]", "200 with 0 items", `${bProjectsRes.status} (length: ${bProjectsRes.body?.data?.length})`);
    }

    // 38. B's dashboard must be all zeros
    const bDashRes = await api("/dashboard", { token: tokenB });
    const bDash = bDashRes.body?.data;
    const bAllZeros =
      bDashRes.status === 200 &&
      bDash &&
      bDash.totalProjects === 0 &&
      bDash.totalTasks === 0 &&
      bDash.completedTasks === 0 &&
      bDash.pendingTasks === 0 &&
      bDash.projectsInProgress === 0;
    if (bAllZeros) {
      pass("ownership: B's dashboard must be all zeros [200]");
    } else {
      fail("ownership: B's dashboard must be all zeros [200]", "200 with all zeros", `${bDashRes.status} (${JSON.stringify(bDash)})`);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // CASCADE
    // ═════════════════════════════════════════════════════════════════════════
    console.log("\n--- CASCADE ---");

    // 39. Delete A's project [200 or 204]
    const delProjARes = await api(`/projects/${projectAId}`, {
      method: "DELETE",
      token: tokenA,
    });
    if (delProjARes.status === 200 || delProjARes.status === 204) {
      pass("cascade: delete A's project [200 or 204]");
      // Mark as deleted from cleanup list
      const idx = createdProjectIds.indexOf(projectAId);
      if (idx !== -1) createdProjectIds.splice(idx, 1);
    } else {
      fail("cascade: delete A's project [200 or 204]", "200 or 204", delProjARes.status);
    }

    // 40. GET A's task by id must be 404
    const getCascadedTask = await api(`/tasks/${taskAId}`, { token: tokenA });
    if (getCascadedTask.status === 404) {
      pass("cascade: GET A's task by id must be 404");
    } else {
      fail("cascade: GET A's task by id must be 404", "404", getCascadedTask.status);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // RATE LIMIT (Optional flag: --ratelimit)
    // ═════════════════════════════════════════════════════════════════════════
    if (process.argv.includes("--ratelimit")) {
      console.log("\n--- RATE LIMIT ---");
      let triggered429 = false;
      const rateLimitIp = `198.51.100.${Math.floor(Math.random() * 200) + 1}`;
      for (let i = 0; i < 12; i++) {
        const rlRes = await api("/auth/login", {
          method: "POST",
          ip: rateLimitIp,
          body: { email: emailA, password: "BadPasswordAttempt" },
        });
        if (rlRes.status === 429) {
          triggered429 = true;
          break;
        }
      }
      if (triggered429) {
        pass("rate limit: triggers 429 on rapid login attempts");
      } else {
        fail("rate limit: triggers 429 on rapid login attempts", "at least one 429", "no 429 received in 12 attempts");
      }
    }
  } finally {
    // ─── Cleanup: Delete any remaining projects created during tests ─────────
    for (const pId of createdProjectIds) {
      try {
        await api(`/projects/${pId}`, { method: "DELETE", token: tokenA });
      } catch {
        // ignore cleanup errors
      }
    }
  }

  // ─── Summary ───────────────────────────────────────────────────────────────
  console.log("\n==================================================");
  console.log(`Summary: ${passed} passed, ${failed} failed`);
  console.log("==================================================");

  if (failed > 0) {
    process.exit(1);
  }
}

runSmokeTests().catch((err) => {
  console.error("Unexpected smoke test runner error:", err);
  process.exit(1);
});
