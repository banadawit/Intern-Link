import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  transpilePackages: ["react-calendar-heatmap"],
  turbopack: {
    resolveAlias: {
      "next-intl": "./src/lib/i18n/shim.ts",
    },
  },
};

export default nextConfig;
