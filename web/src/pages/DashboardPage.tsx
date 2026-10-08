// The dashboard fetches aggregate metrics, greeting the user with color-coded stat cards.
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { dashboardService } from "../services/dashboardService";
import { useAuth } from "../context/AuthContext";
import type { DashboardStats } from "../types";
import { ErrorState, Skeleton } from "../components/ui";

interface MetricConfig {
  key: keyof DashboardStats;
  label: string;
  colorBg: string;
  colorText: string;
  borderColor: string;
  icon: (className?: string) => React.ReactNode;
}

const metrics: MetricConfig[] = [
  {
    key: "totalProjects",
    label: "Total Projects",
    colorBg: "bg-indigo-50",
    colorText: "text-indigo-600",
    borderColor: "border-indigo-100",
    icon: (c = "h-5 w-5") => (
      <svg className={c} fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
        />
      </svg>
    ),
  },
  {
    key: "totalTasks",
    label: "Total Tasks",
    colorBg: "bg-sky-50",
    colorText: "text-sky-600",
    borderColor: "border-sky-100",
    icon: (c = "h-5 w-5") => (
      <svg className={c} fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
        />
      </svg>
    ),
  },
  {
    key: "completedTasks",
    label: "Completed Tasks",
    colorBg: "bg-emerald-50",
    colorText: "text-emerald-600",
    borderColor: "border-emerald-100",
    icon: (c = "h-5 w-5") => (
      <svg className={c} fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
        />
      </svg>
    ),
  },
  {
    key: "pendingTasks",
    label: "Pending Tasks",
    colorBg: "bg-amber-50",
    colorText: "text-amber-600",
    borderColor: "border-amber-100",
    icon: (c = "h-5 w-5") => (
      <svg className={c} fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
        />
      </svg>
    ),
  },
  {
    key: "projectsInProgress",
    label: "Projects In Progress",
    colorBg: "bg-purple-50",
    colorText: "text-purple-600",
    borderColor: "border-purple-100",
    icon: (c = "h-5 w-5") => (
      <svg className={c} fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          d="M13 10V3L4 14h7v7l9-11h-7z"
        />
      </svg>
    ),
  },
];

export function DashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [failed, setFailed] = useState(false);

  const load = useCallback(() => {
    setFailed(false);
    dashboardService.get().then(setStats).catch(() => setFailed(true));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const firstName = user?.fullName ? user.fullName.split(" ")[0] : "there";

  return (
    <section className="space-y-6">
      {/* Greeting Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 sm:text-3xl">
            Hello, {firstName}! 👋
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            Welcome back. Here is the latest overview of your workspace.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <Link
            to="/projects"
            className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3.5 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
          >
            <span>View Projects</span>
          </Link>
          <Link
            to="/tasks"
            className="inline-flex items-center gap-1.5 rounded-lg bg-indigo-600 px-3.5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-indigo-700"
          >
            <span>Manage Tasks →</span>
          </Link>
        </div>
      </div>

      {/* Overview Stat Cards Grid */}
      {failed ? (
        <ErrorState onRetry={load} />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
          {metrics.map((m) => {
            if (!stats) {
              return <Skeleton key={m.key} className="h-32" />;
            }

            const val = stats[m.key];
            return (
              <article
                key={m.key}
                className={`relative overflow-hidden rounded-2xl border bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md ${m.borderColor}`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold tracking-wide text-slate-500 uppercase">
                    {m.label}
                  </span>
                  <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${m.colorBg} ${m.colorText}`}>
                    {m.icon("h-5 w-5")}
                  </div>
                </div>

                <div className="mt-3">
                  <p className="text-3xl font-extrabold tracking-tight text-slate-900">
                    {val}
                  </p>
                </div>
              </article>
            );
          })}
        </div>
      )}
    </section>
  );
}

