// prisma/seed.ts
//
// Database seed script.
// Populates the database with initial sample data for development and testing.
//
// Rules:
// 1. Cleans up ONLY its own test users ("alice@example.com", "bob@example.com")
//    before inserting so it can be re-run safely multiple times.
// 2. Cascades automatically clean up projects and tasks linked to these test users.
// 3. Password "Test1234" is hashed with bcryptjs (cost 12) just like in auth.service.

import { PrismaClient, ProjectStatus, Priority, TaskStatus } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

const TEST_EMAILS = ["alice@example.com", "bob@example.com"];

async function main() {
  console.log("🌱 Starting database seeding...");

  // ── Step 1: Clean up only test users ───────────────────────────────────────
  // Because User -> Project and Project -> Task have onDelete: Cascade,
  // deleting these test users automatically deletes all their projects and tasks.
  const deletedUsers = await prisma.user.deleteMany({
    where: {
      email: { in: TEST_EMAILS },
    },
  });
  console.log(`🧹 Cleaned up ${deletedUsers.count} existing test user(s)`);

  // ── Step 2: Hash test password ──────────────────────────────────────────────
  const passwordHash = await bcrypt.hash("Test1234", 12);

  // ── Step 3: Create User 1 (Alice) with sample projects and tasks ───────────
  const alice = await prisma.user.create({
    data: {
      fullName: "Alice Johnson",
      email: "alice@example.com",
      passwordHash,
      projects: {
        create: [
          {
            name: "Website Redesign",
            description: "Modernize marketing website with new branding",
            status: ProjectStatus.IN_PROGRESS,
            startDate: new Date("2026-10-01T09:00:00Z"),
            endDate: new Date("2026-11-15T18:00:00Z"),
            tasks: {
              create: [
                {
                  name: "Create Figma wireframes",
                  description: "Design desktop and mobile layouts",
                  priority: Priority.HIGH,
                  status: TaskStatus.COMPLETED,
                  dueDate: new Date("2026-10-10T17:00:00Z"),
                },
                {
                  name: "Implement landing page",
                  description: "Code the hero and features section with CSS",
                  priority: Priority.MEDIUM,
                  status: TaskStatus.IN_PROGRESS,
                  dueDate: new Date("2026-10-25T17:00:00Z"),
                },
                {
                  name: "Setup Google Analytics",
                  description: "Configure event tracking and conversion goals",
                  priority: Priority.LOW,
                  status: TaskStatus.PENDING,
                  dueDate: new Date("2026-11-05T17:00:00Z"),
                },
              ],
            },
          },
          {
            name: "Mobile App MVP",
            description: "Build first version of mobile companion app",
            status: ProjectStatus.NOT_STARTED,
            startDate: new Date("2026-11-01T09:00:00Z"),
            endDate: new Date("2026-12-31T18:00:00Z"),
            tasks: {
              create: [
                {
                  name: "Design app navigation architecture",
                  description: "Define tab bar and stack routes",
                  priority: Priority.MEDIUM,
                  status: TaskStatus.PENDING,
                  dueDate: new Date("2026-11-10T17:00:00Z"),
                },
              ],
            },
          },
        ],
      },
    },
  });
  console.log(`✅ Seeded user: ${alice.fullName} (${alice.email})`);

  // ── Step 4: Create User 2 (Bob) with sample projects and tasks ─────────────
  const bob = await prisma.user.create({
    data: {
      fullName: "Bob Smith",
      email: "bob@example.com",
      passwordHash,
      projects: {
        create: [
          {
            name: "Cloud Database Migration",
            description: "Migrate on-prem PostgreSQL database to managed cloud instance",
            status: ProjectStatus.IN_PROGRESS,
            startDate: new Date("2026-10-05T08:00:00Z"),
            endDate: new Date("2026-10-20T20:00:00Z"),
            tasks: {
              create: [
                {
                  name: "Perform database backup",
                  description: "Export full pg_dump snapshot",
                  priority: Priority.HIGH,
                  status: TaskStatus.COMPLETED,
                  dueDate: new Date("2026-10-06T12:00:00Z"),
                },
                {
                  name: "Run data verification tests",
                  description: "Verify row counts and checksum integrity",
                  priority: Priority.HIGH,
                  status: TaskStatus.PENDING,
                  dueDate: new Date("2026-10-15T18:00:00Z"),
                },
              ],
            },
          },
          {
            name: "API Documentation",
            description: "Produce developer documentation and guides",
            status: ProjectStatus.COMPLETED,
            startDate: new Date("2026-09-01T09:00:00Z"),
            endDate: new Date("2026-09-30T17:00:00Z"),
            tasks: {
              create: [
                {
                  name: "Write OpenAPI v3 specification",
                  description: "Document all authentication and CRUD endpoints",
                  priority: Priority.MEDIUM,
                  status: TaskStatus.COMPLETED,
                  dueDate: new Date("2026-09-20T17:00:00Z"),
                },
              ],
            },
          },
        ],
      },
    },
  });
  console.log(`✅ Seeded user: ${bob.fullName} (${bob.email})`);

  console.log("🎉 Seeding completed successfully!");
}

main()
  .catch((e) => {
    console.error("❌ Seeding failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
