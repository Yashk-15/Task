// src/server.ts — Entry point for the Express application.

import "dotenv/config";
// ↑ Reads .env file and injects variables into process.env.
//   Must be the FIRST import so every module below can access process.env.

import express from "express";

// ─── App Setup ───────────────────────────────────────────────────────────────

const app = express();

// express.json() is built-in middleware that parses incoming request bodies
// with Content-Type: application/json and puts the result in req.body.
app.use(express.json());

// ─── Routes ──────────────────────────────────────────────────────────────────

// Health-check endpoint — useful for load balancers and deployment checks.
// Returns 200 OK with { status: "ok" } to confirm the server is alive.
app.get("/api/health", (_req, res) => {
  res.json({ status: "ok" });
});

// ─── Start Server ─────────────────────────────────────────────────────────────

// process.env.PORT lets you configure the port externally (e.g. in .env or CI).
// Falls back to 3000 if PORT is not set.
const PORT = process.env["PORT"] ?? 3000;

app.listen(PORT, () => {
  console.log(`✅ Server running at http://localhost:${PORT}`);
  console.log(`   Health check: http://localhost:${PORT}/api/health`);
});
