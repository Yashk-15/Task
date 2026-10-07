// src/routes/index.ts
//
// The "root router" — mounts all feature routers under their base paths.
// app.ts imports this single file instead of each individual router,
// so adding a new feature only requires adding one line here.

import { Router } from "express";
import authRouter from "./auth.routes.js";
import projectRouter from "./project.routes.js";
import taskRouter from "./task.routes.js";
import dashboardRouter from "./dashboard.routes.js";

const router = Router();

// Mount feature routers under their paths
// Combined with app.use("/api", router) in app.ts, routes become:
//   /api/auth/*
//   /api/projects/*
//   /api/tasks/*
//   /api/dashboard
router.use("/auth", authRouter);
router.use("/projects", projectRouter);
router.use("/tasks", taskRouter);
router.use("/dashboard", dashboardRouter);

export default router;
