// src/middleware/auth.middleware.ts
//
// Protects routes that require the user to be logged in.
//
// How it works:
//   1. Look for an "Authorization: Bearer <token>" header.
//   2. Extract and verify the JWT token.
//   3. Load the user from the database to confirm they still exist.
//   4. Attach { id, email } to req.user so controllers can use it.
//   5. If anything is wrong (no token, invalid, expired), return 401.

import type { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import prisma from "../config/prisma.js";
import { env } from "../config/env.js";
import { AppError } from "../utils/AppError.js";

// ─── Extend Express Request type ─────────────────────────────────────────────
// By default, Express's Request type doesn't have a `user` field.
// We add it here so TypeScript knows `req.user` is valid in protected routes.
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
      };
    }
  }
}

// ─── JWT Payload Shape ────────────────────────────────────────────────────────
// This is what we store inside the token when signing it.
interface JwtPayload {
  userId: string;
}

export const authenticate = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // ── Step 1: Extract the token from the Authorization header ─────────────
    const authHeader = req.headers.authorization;

    // The header must look like "Bearer eyJhbGci..."
    if (!authHeader?.startsWith("Bearer ")) {
      throw new AppError("Authentication required", 401);
    }

    // Split "Bearer <token>" and take the token part (index 1)
    const token = authHeader.split(" ")[1];

    if (!token) {
      throw new AppError("Authentication required", 401);
    }

    // ── Step 2: Verify the token ─────────────────────────────────────────────
    // jwt.verify() throws if the token is tampered with or expired.
    let payload: JwtPayload;
    try {
      payload = jwt.verify(token, env.JWT_SECRET) as JwtPayload;
    } catch (err) {
      // JsonWebTokenError = invalid/tampered
      // TokenExpiredError = past expiry time
      if (err instanceof jwt.TokenExpiredError) {
        throw new AppError("Token expired", 401);
      }
      throw new AppError("Invalid token", 401);
    }

    // ── Step 3: Check the user still exists in the database ──────────────────
    // This catches cases where an account was deleted after the token was issued.
    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      select: { id: true, email: true }, // Only fetch what we need
    });

    if (!user) {
      throw new AppError("User no longer exists", 401);
    }

    // ── Step 4: Attach user info to the request ───────────────────────────────
    // Controllers can now read req.user.id or req.user.email
    req.user = user;

    next(); // All checks passed — continue to the route handler
  } catch (err) {
    next(err); // Forward errors to the central error handler
  }
};
