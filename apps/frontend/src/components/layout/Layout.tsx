import React from "react";
import { Outlet } from "react-router-dom";

export default function Layout({ sidebar }: { sidebar: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      {sidebar}
      <main className="min-w-0 flex-1">
        <Outlet />
      </main>
    </div>
  );
}
