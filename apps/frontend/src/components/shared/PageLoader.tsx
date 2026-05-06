"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";

export default function PageLoader() {
  const pathname = usePathname();
  const [loading, setLoading] = useState(false);
  const [width, setWidth] = useState(0);

  useEffect(() => {
    // Trigger on route change
    setLoading(true);
    setWidth(0);

    // Animate to 80% quickly
    const t1 = setTimeout(() => setWidth(80), 50);
    // Then to 95%
    const t2 = setTimeout(() => setWidth(95), 400);
    // Complete and hide
    const t3 = setTimeout(() => {
      setWidth(100);
      setTimeout(() => setLoading(false), 300);
    }, 700);

    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
      clearTimeout(t3);
    };
  }, [pathname]);

  if (!loading) return null;

  return (
    <div className="fixed left-0 top-0 z-[99999] h-[3px] w-full">
      <div
        className="h-full bg-primary-600 transition-all duration-300 ease-out shadow-[0_0_8px_rgba(13,148,136,0.6)]"
        style={{ width: `${width}%` }}
      />
    </div>
  );
}
