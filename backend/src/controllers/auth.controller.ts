// src/controllers/auth.controller.ts
//
// Controllers receive the HTTP request, call the service to do the work,
// and send back the HTTP response. They contain no business logic themselves.
//
// All controllers are wrapped in asyncHandler so any thrown error
// automatically reaches the central error handler.

import type { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler.js";
import {
  registerUser,
  loginUser,
  getCurrentUser,
} from "../services/auth.service.js";
import type { RegisterInput, LoginInput } from "../validators/auth.validator.js";

// ─── POST /api/auth/register ──────────────────────────────────────────────────
// Creates a new account and returns the user + token.
// req.body has already been validated and cleaned by the validate middleware.
export const register = asyncHandler(async (req: Request, res: Response) => {
  const data = req.body as RegisterInput;

  const { user, token } = await registerUser(data);

  // 201 Created — used when a new resource is successfully created
  res.status(201).json({
    success: true,
    data: { user, token },
  });
});

// ─── POST /api/auth/login ─────────────────────────────────────────────────────
// Verifies credentials and returns the user + token.
export const login = asyncHandler(async (req: Request, res: Response) => {
  const data = req.body as LoginInput;

  const { user, token } = await loginUser(data);

  // 200 OK — the resource already existed, we're just fetching access
  res.status(200).json({
    success: true,
    data: { user, token },
  });
});

// ─── POST /api/auth/logout ────────────────────────────────────────────────────
// This endpoint is stateless — the server doesn't store sessions or tokens,
// so there's nothing to invalidate on the server side.
// The CLIENT is responsible for deleting the token from localStorage /
// sessionStorage / cookies. This endpoint just confirms the action.
//
// If you need true server-side logout in the future, you'd implement a
// "token blocklist" in Redis, but that's beyond the scope of this project.
export const logout = asyncHandler(async (_req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: "Logged out successfully",
  });
});

// ─── GET /api/auth/me ─────────────────────────────────────────────────────────
// Returns the currently logged-in user's profile.
// req.user is attached by the authenticate middleware before this runs.
export const getMe = asyncHandler(async (req: Request, res: Response) => {
  // req.user is guaranteed to exist here because authenticate middleware
  // already verified the token and attached user info.
  const user = await getCurrentUser(req.user!.id);

  res.status(200).json({
    success: true,
    data: { user },
  });
});
