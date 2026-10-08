// Shows a visible banner across the top if the user's internet connection drops.
import { useEffect, useState } from "react";

export function OfflineBanner() {
  const [isOnline, setIsOnline] = useState(
    typeof navigator !== "undefined" ? navigator.onLine : true,
  );
  const [wasOffline, setWasOffline] = useState(false);

  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true);
      // Briefly show back-online state then clear
      setTimeout(() => setWasOffline(false), 3000);
    };

    const handleOffline = () => {
      setIsOnline(false);
      setWasOffline(true);
    };

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, []);

  if (isOnline && !wasOffline) return null;

  if (!isOnline) {
    return (
      <aside
        role="alert"
        aria-live="assertive"
        className="sticky top-0 z-50 flex items-center justify-center gap-2 bg-amber-600 px-4 py-2 text-center text-xs font-semibold text-white shadow-md sm:text-sm"
      >
        <svg
          className="h-4 w-4 shrink-0 animate-pulse"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.828m2.829 2.828L12 12m0 0L5.636 5.636m12.728 0L12 12m0 0l-2.828 2.828M3.636 18.364a9 9 0 010-12.728"
          />
        </svg>
        <span>No internet connection. Changes may not be saved until you reconnect.</span>
      </aside>
    );
  }

  return (
    <aside
      role="status"
      aria-live="polite"
      className="sticky top-0 z-50 flex items-center justify-center gap-2 bg-emerald-600 px-4 py-1.5 text-center text-xs font-semibold text-white shadow-md sm:text-sm"
    >
      <svg className="h-4 w-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7" />
      </svg>
      <span>Back online! Reconnected to server.</span>
    </aside>
  );
}
