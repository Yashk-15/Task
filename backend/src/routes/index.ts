// src/routes/index.ts
//
// The "root router" — mounts all feature routers under their base paths.
// app.ts imports this single file instead of each individual router,
// so adding a new feature only requires adding one line here.

import { Router } from "express";
import authRouter from "./auth.routes.js";

const router = Router();

// Mount auth routes at /auth
// Combined with the /api prefix in app.ts, full paths become:
//   POST /api/auth/register
//   POST /api/auth/login
//   POST /api/auth/logout
//   GET  /api/auth/me
router.use("/auth", authRouter);

export default router;
