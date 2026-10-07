// src/routes/auth.routes.ts
//
// Defines all HTTP routes for authentication.
// Each route is composed of middleware layers applied left to right:
//   authRateLimiter → validate(schema) → controller
//
// The route file itself has NO logic — it just wires things together.

import { Router } from "express";
import { register, login, logout, getMe } from "../controllers/auth.controller.js";
import { validate } from "../middleware/validate.js";
import { authenticate } from "../middleware/auth.middleware.js";
import { authRateLimiter } from "../middleware/rateLimiter.js";
import { registerSchema, loginSchema } from "../validators/auth.validator.js";

const router = Router();

// POST /api/auth/register
// 1. authRateLimiter  — reject if too many attempts from this IP
// 2. validate(...)    — ensure body has valid fullName, email, password
// 3. register         — create the user and return a token
router.post("/register", authRateLimiter, validate(registerSchema), register);

// POST /api/auth/login
// 1. authRateLimiter  — same brute-force protection
// 2. validate(...)    — ensure body has email and password
// 3. login            — verify credentials and return a token
router.post("/login", authRateLimiter, validate(loginSchema), login);

// POST /api/auth/logout
// 1. authenticate  — require a valid JWT (user must be logged in to log out)
// 2. logout        — send confirmation (the client deletes its token)
router.post("/logout", authenticate, logout);

// GET /api/auth/me
// 1. authenticate  — require a valid JWT
// 2. getMe         — return the current user's profile
router.get("/me", authenticate, getMe);

export default router;
