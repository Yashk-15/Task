// src/routes/dashboard.routes.ts
//
// Dashboard endpoints router.
// Protected by `authenticate` — returns aggregate metrics for the logged-in user.

import { Router } from "express";
import { authenticate } from "../middleware/auth.middleware.js";
import { getDashboard } from "../controllers/dashboard.controller.js";

const router = Router();

// GET /api/dashboard - retrieve overview metrics
router.get("/", authenticate, getDashboard);

export default router;
