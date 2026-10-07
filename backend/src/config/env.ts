// src/config/env.ts
//
// This file loads and VALIDATES all environment variables when the server starts.
// If any required variable is missing or wrong (e.g. JWT_SECRET too short),
// the app crashes immediately with a clear error message instead of silently
// failing later during a request.

import "dotenv/config"; // Reads .env file and puts values into process.env
import { z } from "zod";

// ─── Validation Schema ────────────────────────────────────────────────────────
// z.object() defines the shape and rules for our environment variables.
const envSchema = z.object({
  // DATABASE_URL must be present (any non-empty string)
  DATABASE_URL: z.string().min(1, "DATABASE_URL is required"),

  // JWT_SECRET must be at least 32 characters long for security.
  // A short secret makes it easy for attackers to guess or brute-force.
  JWT_SECRET: z
    .string()
    .min(32, "JWT_SECRET must be at least 32 characters long"),

  // JWT_EXPIRES_IN controls how long a token is valid, e.g. "1d", "7d", "2h"
  JWT_EXPIRES_IN: z.string().min(1, "JWT_EXPIRES_IN is required"),

  // CORS_ORIGIN is one or more comma-separated frontend URLs.
  CORS_ORIGIN: z
    .string()
    .min(1, "CORS_ORIGIN is required")
    .transform((value) => value.split(",").map((origin) => origin.trim()).filter(Boolean))
    .refine(
      (origins) => origins.length > 0 && origins.every((origin) => z.url().safeParse(origin).success),
      "CORS_ORIGIN must contain one or more valid URLs separated by commas"
    ),

  // PORT is optional — defaults to "3000" if not set.
  // .coerce.number() converts the string "5000" to the number 5000.
  PORT: z.coerce.number().default(3000),

  // NODE_ENV tells the app if it's running in development or production.
  // "development" is the default if not set.
  NODE_ENV: z
    .enum(["development", "production", "test"])
    .default("development"),
});

// ─── Parse & Crash Early ──────────────────────────────────────────────────────
// safeParse() won't throw — it returns { success, data, error }
const result = envSchema.safeParse(process.env);

if (!result.success) {
  // If validation fails, print all problems clearly and exit.
  console.error("❌ Invalid environment variables:");
  console.error(result.error.flatten().fieldErrors);
  process.exit(1); // Exit code 1 means "error" — stops the Node process
}

// Export the validated, typed env object.
// From now on, anywhere you import `env`, TypeScript knows every field's type.
export const env = result.data;
