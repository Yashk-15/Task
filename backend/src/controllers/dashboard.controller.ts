// src/controllers/dashboard.controller.ts
//
// HTTP route handler for Dashboard metrics.
// Returns aggregate stats strictly for the authenticated user.

import type { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler.js";
import * as dashboardService from "../services/dashboard.service.js";

// GET /api/dashboard
export const getDashboard = asyncHandler(
  async (req: Request, res: Response) => {
    const stats = await dashboardService.getDashboardStats(req.user!.id);

    res.status(200).json({
      success: true,
      data: stats,
    });
  }
);
