// Welcome screen shown to new / unauthenticated visitors.
// Displays app branding, feature highlights, and a smooth 3.2-second progress bar
// before automatically forwarding to the registration page (/register).
import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import api from "../services/api";

export function WelcomePage() {
  const navigate = useNavigate();
  const { user, loading } = useAuth();
  const [progress, setProgress] = useState(0);

  // If already authenticated, redirect straight to dashboard
  useEffect(() => {
    if (!loading && user) {
      navigate("/dashboard", { replace: true });
    }
  }, [user, loading, navigate]);

  // Background warm-up ping for the backend (free tier cold-start wakeup)
  useEffect(() => {
    api.get("/health").catch(() => {
      // Ignored: silent warm-up ping
    });
  }, []);

  // 3.2-second smooth progress animation
  useEffect(() => {
    const totalDurationMs = 3200;
    const intervalMs = 32;
    const step = 100 / (totalDurationMs / intervalMs);

    const timer = setInterval(() => {
      setProgress((prev) => {
        const next = prev + step;
        if (next >= 100) {
          clearInterval(timer);
          navigate("/register", { replace: true });
          return 100;
        }
        return next;
      });
    }, intervalMs);

    return () => clearInterval(timer);
  }, [navigate]);

  return (
    <main className="relative flex min-h-screen flex-col items-center justify-between overflow-hidden bg-gradient-to-br from-indigo-700 via-indigo-800 to-purple-900 p-6 text-white selection:bg-indigo-500 selection:text-white">
      {/* Decorative background glows */}
      <div
        className="pointer-events-none absolute -left-24 -top-24 h-96 w-96 rounded-full bg-indigo-500/20 blur-3xl"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none absolute -bottom-24 -right-24 h-96 w-96 rounded-full bg-purple-500/20 blur-3xl"
        aria-hidden="true"
      />

      {/* Top Header / Skip */}
      <header className="z-10 flex w-full max-w-5xl items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-white/15 backdrop-blur-md">
            <svg className="h-5 w-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2.5"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
          <span className="text-lg font-bold tracking-tight text-white">ProjectFlow</span>
        </div>

        <div className="flex items-center gap-3">
          <Link
            to="/login"
            className="rounded-lg px-3 py-1.5 text-xs font-semibold text-white/80 transition hover:bg-white/10 hover:text-white sm:text-sm"
          >
            Sign In
          </Link>
          <Link
            to="/register"
            className="rounded-lg bg-white/20 px-3.5 py-1.5 text-xs font-semibold text-white backdrop-blur-md transition hover:bg-white/30 sm:text-sm"
          >
            Get Started →
          </Link>
        </div>
      </header>

      {/* Center Branding & Showcase */}
      <section className="z-10 my-auto flex max-w-2xl flex-col items-center text-center">
        {/* Animated App Icon */}
        <div className="relative mb-6">
          <div className="absolute -inset-2 animate-pulse rounded-full bg-white/15 blur-md" />
          <div className="relative flex h-24 w-24 items-center justify-center rounded-3xl border border-white/30 bg-white/15 shadow-2xl backdrop-blur-xl">
            <svg className="h-12 w-12 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2.5"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
        </div>

        <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl lg:text-6xl">
          Project Manager
        </h1>
        <p className="mt-3 text-lg font-medium text-white/80 sm:text-xl">
          Organize. Track. Deliver.
        </p>

        <p className="mt-4 max-w-lg text-sm text-white/70 sm:text-base">
          A unified, cross-platform workspace for managing projects, organizing tasks, and tracking
          real-time progress on Web and Mobile.
        </p>

        {/* Feature Pills */}
        <div className="mt-8 flex flex-wrap justify-center gap-2.5">
          {[
            { label: "Projects", icon: "📁" },
            { label: "Tasks", icon: "⚡" },
            { label: "Live Analytics", icon: "📊" },
            { label: "Mobile Sync", icon: "📱" },
          ].map((pill) => (
            <span
              key={pill.label}
              className="inline-flex items-center gap-1.5 rounded-full border border-white/20 bg-white/10 px-3.5 py-1.5 text-xs font-medium text-white/90 backdrop-blur-sm"
            >
              <span>{pill.icon}</span>
              <span>{pill.label}</span>
            </span>
          ))}
        </div>
      </section>

      {/* Bottom Progress Bar & Loading Message */}
      <footer className="z-10 flex w-full max-w-md flex-col items-center gap-3 pb-4">
        <p className="text-xs font-medium text-white/75 sm:text-sm">
          Getting your workspace ready…
        </p>

        {/* Determinate progress track */}
        <div
          role="progressbar"
          aria-valuenow={Math.round(progress)}
          aria-valuemin={0}
          aria-valuemax={100}
          className="h-1.5 w-full overflow-hidden rounded-full bg-white/20 backdrop-blur-sm"
        >
          <div
            className="h-full rounded-full bg-white transition-all duration-75 ease-out shadow-sm"
            style={{ width: `${progress}%` }}
          />
        </div>

        <div className="flex w-full items-center justify-between text-xs text-white/60">
          <span>Waking up cloud server</span>
          <button
            onClick={() => navigate("/register", { replace: true })}
            className="underline transition hover:text-white"
          >
            Skip intro
          </button>
        </div>
      </footer>
    </main>
  );
}
