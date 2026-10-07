// A small fallback helps users recover from a mistyped URL.
import { Link } from "react-router-dom";
export function NotFoundPage() { return <main className="grid min-h-screen place-items-center p-4 text-center"><div><p className="text-6xl font-bold text-indigo-600">404</p><h1 className="mt-3 text-2xl font-bold">Page not found</h1><Link className="mt-5 inline-block font-semibold text-indigo-600" to="/dashboard">Go to dashboard</Link></div></main>; }
