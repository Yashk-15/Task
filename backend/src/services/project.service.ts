// src/services/project.service.ts
//
// Business logic for Project management.
//
// 🔒 CRITICAL SECURITY RULES:
// 1. Every database query MUST be scoped to the authenticated user's `userId`.
// 2. If a project does not exist OR belongs to another user, return 404
//    (never return 403, as 403 would reveal that the resource exists to unauthorized callers).
// 3. Never trust any `userId` passed in request payloads — always use the verified token ID.

import { Prisma } from "@prisma/client";
import prisma from "../config/prisma.js";
import { AppError } from "../utils/AppError.js";
import type {
  CreateProjectInput,
  UpdateProjectInput,
  ProjectQueryInput,
} from "../validators/project.validator.js";

/**
 * Helper to normalize project response with taskCount
 */
const formatProject = <T extends { _count?: { tasks: number } }>(project: T) => {
  const taskCount = project._count ? project._count.tasks : 0;
  return {
    ...project,
    taskCount,
  };
};

/**
 * Retrieve a paginated list of projects owned by the authenticated user.
 */
export const getProjects = async (userId: string, query: ProjectQueryInput) => {
  const { page, limit, search, status, sortBy, order } = query;
  const skip = (page - 1) * limit;

  // Build the filter: must match logged-in user
  const where: Prisma.ProjectWhereInput = {
    userId,
    ...(status && { status }),
    ...(search && {
      name: {
        contains: search,
        mode: "insensitive", // case-insensitive search
      },
    }),
  };

  // Ensure sortBy column is valid on the Project model (fallback to createdAt if not)
  const validSortFields = ["createdAt", "name", "endDate"];
  const sortField = validSortFields.includes(sortBy) ? sortBy : "createdAt";

  // Run queries in parallel for efficiency: data fetch + total count
  const [projects, total] = await Promise.all([
    prisma.project.findMany({
      where,
      skip,
      take: limit,
      orderBy: { [sortField]: order },
      include: {
        _count: {
          select: { tasks: true },
        },
      },
    }),
    prisma.project.count({ where }),
  ]);

  const totalPages = Math.ceil(total / limit) || 1;

  return {
    projects: projects.map(formatProject),
    pagination: {
      page,
      limit,
      total,
      totalPages,
    },
  };
};

/**
 * Fetch a single project by ID, strictly verifying ownership.
 */
export const getProjectById = async (userId: string, id: string) => {
  const project = await prisma.project.findFirst({
    where: {
      id,
      userId, // Must belong to this user
    },
    include: {
      _count: {
        select: { tasks: true },
      },
    },
  });

  if (!project) {
    // 404 prevents leaking the existence of other users' projects
    throw new AppError("Project not found", 404);
  }

  return formatProject(project);
};

/**
 * Create a new project for the authenticated user.
 */
export const createProject = async (
  userId: string,
  data: CreateProjectInput
) => {
  const project = await prisma.project.create({
    data: {
      userId, // Always from verified session, never trusted from client
      name: data.name,
      description: data.description ?? null,
      status: data.status,
      startDate: data.startDate ? new Date(data.startDate) : null,
      endDate: data.endDate ? new Date(data.endDate) : null,
    },
    include: {
      _count: {
        select: { tasks: true },
      },
    },
  });

  return formatProject(project);
};

/**
 * Update an existing project owned by the user.
 * Validates dates against stored values when only one date is provided.
 */
export const updateProject = async (
  userId: string,
  id: string,
  data: UpdateProjectInput
) => {
  // Step 1: Verify the project exists and is owned by the user
  const existingProject = await prisma.project.findFirst({
    where: { id, userId },
  });

  if (!existingProject) {
    throw new AppError("Project not found", 404);
  }

  // Step 2: Date cross-validation with stored values
  const effectiveStartDate =
    data.startDate !== undefined
      ? data.startDate
        ? new Date(data.startDate)
        : null
      : existingProject.startDate;

  const effectiveEndDate =
    data.endDate !== undefined
      ? data.endDate
        ? new Date(data.endDate)
        : null
      : existingProject.endDate;

  if (
    effectiveStartDate &&
    effectiveEndDate &&
    effectiveEndDate < effectiveStartDate
  ) {
    throw new AppError("endDate must not be before startDate", 400);
  }

  // Step 3: Perform the update
  const updatedProject = await prisma.project.update({
    where: { id },
    data: {
      ...(data.name !== undefined && { name: data.name }),
      ...(data.description !== undefined && {
        description: data.description,
      }),
      ...(data.status !== undefined && { status: data.status }),
      ...(data.startDate !== undefined && {
        startDate: data.startDate ? new Date(data.startDate) : null,
      }),
      ...(data.endDate !== undefined && {
        endDate: data.endDate ? new Date(data.endDate) : null,
      }),
    },
    include: {
      _count: {
        select: { tasks: true },
      },
    },
  });

  return formatProject(updatedProject);
};

/**
 * Delete a project owned by the user.
 * Associated tasks are automatically deleted via PostgreSQL CASCADE.
 */
export const deleteProject = async (userId: string, id: string) => {
  // Verify ownership before deleting
  const existingProject = await prisma.project.findFirst({
    where: { id, userId },
  });

  if (!existingProject) {
    throw new AppError("Project not found", 404);
  }

  await prisma.project.delete({
    where: { id },
  });

  return { message: "Project deleted successfully" };
};
