// src/services/dashboard.service.ts
//
// Dashboard metrics service.
// Runs aggregate count queries strictly scoped to the logged-in user.
// Queries run in parallel using Promise.all for fast response times.

import prisma from "../config/prisma.js";

export const getDashboardStats = async (userId: string) => {
  // Execute all 5 count queries concurrently
  const [
    totalProjects,
    totalTasks,
    completedTasks,
    pendingTasks,
    projectsInProgress,
  ] = await Promise.all([
    // Total projects owned by user
    prisma.project.count({
      where: { userId },
    }),
    // Total tasks in projects owned by user
    prisma.task.count({
      where: { project: { userId } },
    }),
    // Tasks marked COMPLETED in projects owned by user
    prisma.task.count({
      where: {
        project: { userId },
        status: "COMPLETED",
      },
    }),
    // Tasks marked PENDING in projects owned by user
    prisma.task.count({
      where: {
        project: { userId },
        status: "PENDING",
      },
    }),
    // Projects marked IN_PROGRESS owned by user
    prisma.project.count({
      where: {
        userId,
        status: "IN_PROGRESS",
      },
    }),
  ]);

  return {
    totalProjects,
    totalTasks,
    completedTasks,
    pendingTasks,
    projectsInProgress,
  };
};
