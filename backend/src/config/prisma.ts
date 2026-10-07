// src/config/prisma.ts
//
// Why a singleton?
// PrismaClient opens a connection pool to the database. If you create a new
// instance on every request you'll exhaust the connection limit quickly.
// By exporting ONE shared instance, the whole application reuses the same pool.

import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export default prisma;
