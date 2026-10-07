// src/controllers/project.controller.ts
//
// HTTP route handlers for Project endpoints.
// Controllers extract data from request, call the service layer, and respond.
// Wrapped in asyncHandler to automatically route errors to errorHandler.

import type { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler.js";
import * as projectService from "../services/project.service.js";
import type {
  CreateProjectInput,
  UpdateProjectInput,
  ProjectQueryInput,
} from "../validators/project.validator.js";

// GET /api/projects
export const getProjects = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await projectService.getProjects(
      req.user!.id,
      req.query as unknown as ProjectQueryInput
    );

    res.status(200).json({
      success: true,
      data: result.projects,
      pagination: result.pagination,
    });
  }
);

// GET /api/projects/:id
export const getProject = asyncHandler(
  async (req: Request, res: Response) => {
    const project = await projectService.getProjectById(
      req.user!.id,
      req.params["id"] as string
    );

    res.status(200).json({
      success: true,
      data: { project },
    });
  }
);

// POST /api/projects
export const createProject = asyncHandler(
  async (req: Request, res: Response) => {
    const project = await projectService.createProject(
      req.user!.id,
      req.body as CreateProjectInput
    );

    res.status(201).json({
      success: true,
      data: { project },
    });
  }
);

// PUT /api/projects/:id
export const updateProject = asyncHandler(
  async (req: Request, res: Response) => {
    const project = await projectService.updateProject(
      req.user!.id,
      req.params["id"] as string,
      req.body as UpdateProjectInput
    );

    res.status(200).json({
      success: true,
      data: { project },
    });
  }
);

// DELETE /api/projects/:id
export const deleteProject = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await projectService.deleteProject(
      req.user!.id,
      req.params["id"] as string
    );

    res.status(200).json({
      success: true,
      message: result.message,
    });
  }
);
