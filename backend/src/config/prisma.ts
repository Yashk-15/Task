// src/config/prisma.ts
//
// Why a singleton?
// PrismaClient opens a connection pool to the database. If you create a new
// instance on every request you'll exhaust the connection limit quickly.
// By exporting ONE shared instance the whole app reuses the same pool.

import { PrismaClient } from "../../generated/prisma/index.js";
// ↑ ".js" extension is required when using module:"nodenext" in tsconfig —
//   Node's ESM resolver expects it even though the source file is .ts.

const prisma = new PrismaClient();

export default prisma;
