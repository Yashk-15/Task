// src/routes/project.routes.ts
//
// Project endpoints router.
// All endpoints are protected by `authenticate` (requires valid JWT in Authorization header).
// Inputs are validated via validateQuery, validateParams, and validateBody.

import { Router } from "express";
import { authenticate } from "../middleware/auth.middleware.js";
import {
  validateBody,
  validateParams,
  validateQuery,
} from "../middleware/validate.js";
import { idParamSchema } from "../validators/common.validator.js";
import {
  createProjectSchema,
  updateProjectSchema,
  projectQuerySchema,
} from "../validators/project.validator.js";
import {
  getProjects,
  getProject,
  createProject,
  updateProject,
  deleteProject,
} from "../controllers/project.controller.js";

const router = Router();

// Apply auth middleware to all project routes
router.use(authenticate);

// GET /api/projects - list user's projects with filtering, sorting, pagination
router.get("/", validateQuery(projectQuerySchema), getProjects);

// GET /api/projects/:id - get single project (404 if not found or not owned)
router.get("/:id", validateParams(idParamSchema), getProject);

// POST /api/projects - create a new project
router.post("/", validateBody(createProjectSchema), createProject);

// PUT /api/projects/:id - update owned project
router.put(
  "/:id",
  validateParams(idParamSchema),
  validateBody(updateProjectSchema),
  updateProject
);

// DELETE /api/projects/:id - delete owned project (cascades tasks)
router.delete("/:id", validateParams(idParamSchema), deleteProject);

export default router;
