// The responsive navigation is shared by every protected route.
import { Link, NavLink, useNavigate } from "react-router-dom";
import { useState } from "react";
import { useAuth } from "../context/AuthContext";

export function Navbar() {
  const [open, setOpen] = useState(false);
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const leave = async () => {
    await logout();
    navigate("/login");
  };

  const links = [
    { to: "/dashboard", label: "Dashboard" },
    { to: "/projects", label: "Projects" },
    { to: "/tasks", label: "Tasks" },
  ];

  const userInitial = user?.fullName ? user.fullName.trim()[0].toUpperCase() : "U";

  return (
    <header className="sticky top-0 z-40 border-b border-slate-200 bg-white/95 backdrop-blur-md">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3 sm:px-6">
        {/* Brand */}
        <Link to="/dashboard" className="flex items-center gap-2.5 transition hover:opacity-85">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-600 text-white shadow-sm">
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2.5"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
          <span className="text-lg font-bold tracking-tight text-slate-900">ProjectFlow</span>
        </Link>

        {/* Mobile menu toggle */}
        <button
          className="rounded-lg p-1.5 text-slate-500 hover:bg-slate-100 hover:text-slate-800 md:hidden"
          onClick={() => setOpen(!open)}
          aria-label={open ? "Close menu" : "Open menu"}
        >
          {open ? (
            <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          ) : (
            <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          )}
        </button>

        {/* Nav Links + User Profile */}
        <nav
          className={`${
            open ? "absolute left-0 right-0 top-14 flex border-b bg-white p-4 shadow-lg" : "hidden"
          } flex-col gap-3 md:static md:flex md:flex-row md:items-center md:border-0 md:p-0 md:shadow-none`}
        >
          {/* Page Links */}
          <div className="flex flex-col gap-1 md:flex-row md:items-center">
            {links.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                className={({ isActive }) =>
                  `rounded-lg px-3 py-1.5 text-sm font-medium transition ${
                    isActive
                      ? "bg-indigo-50 font-semibold text-indigo-700"
                      : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
                  }`
                }
                onClick={() => setOpen(false)}
              >
                {link.label}
              </NavLink>
            ))}
          </div>

          <div className="my-1 border-t border-slate-100 md:my-0 md:mx-2 md:h-5 md:w-px md:border-t-0 md:bg-slate-200" />

          {/* User profile & Logout */}
          <div className="flex items-center justify-between gap-3 md:justify-start">
            <div className="flex items-center gap-2">
              <div className="flex h-7 w-7 items-center justify-center rounded-full bg-indigo-100 text-xs font-bold text-indigo-700">
                {userInitial}
              </div>
              <span className="text-xs font-medium text-slate-700 sm:text-sm">
                {user?.fullName || "User"}
              </span>
            </div>

            <button
              className="rounded-lg px-2.5 py-1 text-xs font-semibold text-rose-600 transition hover:bg-rose-50 hover:text-rose-700 sm:text-sm"
              onClick={leave}
            >
              Sign Out
            </button>
          </div>
        </nav>
      </div>
    </header>
  );
}

