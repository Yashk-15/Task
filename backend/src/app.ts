// src/app.ts
//
// Builds and exports the Express application.
// This file is ONLY about the app configuration — no server.listen() here.
// Separating app from server makes the app easier to test (you can import it
// without actually starting a server on a port).

import express from "express";
import helmet from "helmet";
import cors from "cors";
import morgan from "morgan";

import { env } from "./config/env.js";
import router from "./routes/index.js";
import { errorHandler } from "./middleware/errorHandler.js";

const app = express();

// ─── Trust Proxy ──────────────────────────────────────────────────────────────
// When deployed behind a reverse proxy (Nginx, load balancer, etc.),
// the real client IP comes in an X-Forwarded-For header.
// Setting trust proxy tells Express to use that header for req.ip,
// which is what express-rate-limit reads to identify clients.
// Without this, all clients would look like the same IP (the proxy).
app.set("trust proxy", 1);

// ─── Security Headers ─────────────────────────────────────────────────────────
// helmet() adds various HTTP headers that protect against common web attacks
// (clickjacking, MIME sniffing, XSS, etc.) with sensible defaults.
app.use(helmet());

// ─── CORS ─────────────────────────────────────────────────────────────────────
// Cross-Origin Resource Sharing — controls which frontend URLs are allowed
// to make requests to this API. Only requests from CORS_ORIGIN are accepted.
app.use(
  cors({
    origin: env.CORS_ORIGIN,
    credentials: true, // Allow cookies and Authorization headers
  })
);

// ─── Request Logging ──────────────────────────────────────────────────────────
// morgan("dev") prints a short log line for each request:
//   GET /api/health 200 2.345 ms - 16
// Very useful during development for seeing what requests are coming in.
app.use(morgan("dev"));

// ─── Body Parsing ─────────────────────────────────────────────────────────────
// Parse incoming request bodies with Content-Type: application/json
// and make the data available on req.body.
app.use(express.json());

// ─── Health Check ─────────────────────────────────────────────────────────────
// A simple endpoint that returns 200 OK.
// Load balancers and uptime monitors ping this to confirm the server is alive.
app.get("/api/health", (_req, res) => {
  res.json({ status: "ok" });
});

// ─── API Routes ───────────────────────────────────────────────────────────────
// Mount all feature routes under /api (e.g. /api/auth/register)
app.use("/api", router);

// ─── 404 Handler ──────────────────────────────────────────────────────────────
// If no route above matched, this runs and sends a 404.
// Must come AFTER all routes but BEFORE the error handler.
app.use((_req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  });
});

// ─── Central Error Handler ────────────────────────────────────────────────────
// Any error passed to next(err) anywhere in the app lands here.
// MUST be the very last middleware (Express detects it by the 4 parameters).
app.use(errorHandler);

export default app;
