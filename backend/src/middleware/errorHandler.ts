// src/middleware/errorHandler.ts
//
// Central error handler — all errors in the app eventually land here.
// Express recognises this as an error handler because it takes 4 parameters:
// (err, req, res, next). Always keep it as the LAST middleware in app.ts.
//
// This handler covers 4 cases:
//   1. AppError   — our own intentional errors (e.g. "Email already taken")
//   2. ZodError   — validation failures from zod schemas (400 Bad Request)
//   3. Prisma P2002 — unique-constraint violation (409 Conflict)
//   4. Everything else — unexpected crashes (500 Internal Server Error)

import type { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { Prisma } from "@prisma/client";
import { AppError } from "../utils/AppError.js";
import { env } from "../config/env.js";

export const errorHandler = (
  err: unknown,
  _req: Request,
  res: Response,
  // `next` is required by Express even if we don't use it — removing it
  // breaks Express's ability to recognise this as an error handler.
  _next: NextFunction
): void => {
  // ── Case 1: Our own AppError ─────────────────────────────────────────────
  if (err instanceof AppError) {
    const body: {
      success: false;
      message: string;
      errors?: { field: string; message: string }[];
    } = {
      success: false,
      message: err.message,
    };
    if (err.errors !== undefined) {
      body.errors = err.errors;
    }
    res.status(err.statusCode).json(body);
    return;
  }

  // ── Case 2: Zod validation error ─────────────────────────────────────────
  // Zod throws a ZodError when a value doesn't pass its schema.
  // In Zod v4, issues are accessed via `.issues` (not `.errors`).
  if (err instanceof ZodError) {
    const errors = err.issues.map((issue) => ({
      field: issue.path.join("."), // e.g. "email" or "address.city"
      message: issue.message,
    }));
    res.status(400).json({
      success: false,
      message: "Validation failed",
      errors,
    });
    return;
  }

  // ── Case 3: Prisma unique-constraint violation (P2002) ───────────────────
  // P2002 means we tried to insert a value that must be unique but already exists,
  // e.g. registering with an email that's already in the database.
  if (
    err instanceof Prisma.PrismaClientKnownRequestError &&
    err.code === "P2002"
  ) {
    const fields = Array.isArray(err.meta?.["target"])
      ? (err.meta["target"] as string[]).join(", ")
      : "field";
    res.status(409).json({
      success: false,
      message: `A record with this ${fields} already exists.`,
    });
    return;
  }

  // ── Case 4: Unexpected error (crash / bug) ───────────────────────────────
  console.error("Unexpected error:", err);

  const message =
    env.NODE_ENV === "production"
      ? "An unexpected error occurred. Please try again later."
      : err instanceof Error
        ? err.message
        : "An unexpected error occurred.";

  res.status(500).json({
    success: false,
    message,
  });
};
