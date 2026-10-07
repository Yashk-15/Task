// src/server.ts — Entry point. Only job: start listening on a port.
//
// All app configuration (middleware, routes, error handlers) lives in app.ts.
// Keeping them separate lets us import `app` in tests without starting a server.

// env.ts must be imported FIRST so that all environment variables are validated
// before anything else runs. If something is missing, the process exits here.
import { env } from "./config/env.js";
import app from "./app.js";

app.listen(env.PORT, () => {
  console.log(`✅ Server running at http://localhost:${env.PORT}`);
  console.log(`   Health check → http://localhost:${env.PORT}/api/health`);
  console.log(`   Environment  → ${env.NODE_ENV}`);
});
