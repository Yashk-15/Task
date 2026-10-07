// src/validators/auth.validator.ts
//
// Zod schemas define exactly what shape the request body must be.
// They also automatically CLEAN the data:
//   - .trim() removes leading/trailing spaces
//   - .toLowerCase() normalises emails so "User@EXAMPLE.COM" → "user@example.com"
//
// These schemas are used by the `validate` middleware — if the body doesn't
// match the schema, a 400 error is returned automatically before the
// controller even runs.
//
// Note: This project uses Zod v4. In v4, `required_error` was removed from
// z.string() params. Use `.min(1, "message")` to catch missing/empty fields.

import { z } from "zod";

// ─── Register Schema ──────────────────────────────────────────────────────────
export const registerSchema = z.object({
  // Full name: strip whitespace, must be 2–100 characters
  fullName: z
    .string()
    .trim()
    .min(2, "Full name must be at least 2 characters")
    .max(100, "Full name must be at most 100 characters"),

  // Email: strip whitespace, lowercase, must be a valid email format
  email: z
    .string()
    .trim()
    .toLowerCase()
    .email("Please enter a valid email address"),

  // Password: 8–72 characters, must contain at least one letter AND one number.
  // 72 chars is bcrypt's maximum input length.
  password: z
    .string()
    .min(8, "Password must be at least 8 characters")
    .max(72, "Password must be at most 72 characters")
    .regex(
      /^(?=.*[a-zA-Z])(?=.*\d)/,
      "Password must contain at least one letter and one number"
    ),
});

// ─── Login Schema ─────────────────────────────────────────────────────────────
export const loginSchema = z.object({
  // Same email normalisation as register
  email: z
    .string()
    .trim()
    .toLowerCase()
    .email("Please enter a valid email address"),

  // Password just must not be empty — we don't validate rules here
  // (wrong password will fail in the service layer)
  password: z.string().min(1, "Password is required"),
});

// ─── Inferred TypeScript Types ────────────────────────────────────────────────
// z.infer<> gives us a TypeScript type from a Zod schema for free.
// We can use these types in the service to get autocomplete and type safety.
export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
