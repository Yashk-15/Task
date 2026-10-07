// src/routes/task.routes.ts
//
// Task endpoints router.
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
  createTaskSchema,
  updateTaskSchema,
  taskQuerySchema,
} from "../validators/task.validator.js";
import {
  getTasks,
  getTask,
  createTask,
  updateTask,
  deleteTask,
} from "../controllers/task.controller.js";

const router = Router();

// Apply auth middleware to all task routes
router.use(authenticate);

// GET /api/tasks - list tasks from owned projects with filtering, sorting, pagination
router.get("/", validateQuery(taskQuerySchema), getTasks);

// GET /api/tasks/:id - get single task (404 if not found or parent project not owned)
router.get("/:id", validateParams(idParamSchema), getTask);

// POST /api/tasks - create new task (verifies parent project ownership)
router.post("/", validateBody(createTaskSchema), createTask);

// PUT /api/tasks/:id - update task (verifies ownership; cannot change projectId)
router.put(
  "/:id",
  validateParams(idParamSchema),
  validateBody(updateTaskSchema),
  updateTask
);

// DELETE /api/tasks/:id - delete task (verifies ownership)
router.delete("/:id", validateParams(idParamSchema), deleteTask);

export default router;
