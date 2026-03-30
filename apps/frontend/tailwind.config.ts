import type { Config } from "tailwindcss";
import forms from '@tailwindcss/forms';
import typography from '@tailwindcss/typography';

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        // Primary Brand Colors (Teal-based for trust & professionalism)
        primary: {
          50: "#E6F7F5",
          100: "#CCEFEA",
          200: "#99DFD6",
          300: "#66CFC1",
          400: "#33BFAD",
          500: "#00AF98",
          600: "#0D9488", // Base primary
          700: "#0F766E", // Hover state
          800: "#115E59", // Active state
          900: "#0A4B47",
          // Semantic aliases used by dashboard components (bg-primary-base, text-primary-base, etc.)
          base: "#0D9488",
          light: "#E6F7F5",
        },
        
        // Status Colors (Essential for internship workflows)
        success: {
          50: "#F0FDF4",
          100: "#DCFCE7",
          200: "#BBF7D0",
          300: "#86EFAC",
          400: "#4ADE80",
          500: "#22C55E",
          600: "#16A34A",
          700: "#15803D",
          800: "#166534",
          900: "#14532D",
        },
        warning: {
          50: "#FFFBEB",
          100: "#FEF3C7",
          200: "#FDE68A",
          300: "#FCD34D",
          400: "#FBBF24",
          500: "#F59E0B", // Base warning
          600: "#D97706",
          700: "#B45309",
          800: "#92400E",
          900: "#78350F",
        },
        error: {
          50: "#FEF2F2",
          100: "#FEE2E2",
          200: "#FECACA",
          300: "#FCA5A5",
          400: "#F87171",
          500: "#EF4444",
          600: "#DC2626",
          700: "#B91C1C",
          800: "#991B1B",
          900: "#7F1A1A",
        },
        info: {
          50: "#EFF6FF",
          100: "#DBEAFE",
          200: "#BFDBFE",
          300: "#93C5FD",
          400: "#60A5FA",
          500: "#3B82F6",
          600: "#2563EB",
          700: "#1D4ED8",
          800: "#1E40AF",
          900: "#1E3A8A",
        },
        
        // Neutral/Slate Colors (Typography & Surfaces)
        slate: {
          50: "#F8FAFC",  // Secondary surface (page background)
          100: "#F1F5F9", // Card hover, tertiary surfaces
          200: "#E2E8F0", // Borders, dividers
          300: "#CBD5E1",
          400: "#94A3B8",
          500: "#64748B",
          600: "#475569", // Body text
          700: "#334155",
          800: "#1E293B",
          900: "#0F172A", // Headings, dark surfaces
        },

        // Dashboard semantic tokens (Student / SuperAdmin UI)
        // e.g. bg-bg-main, bg-bg-secondary, text-text-heading, border-border-default
        bg: {
          main: "#FFFFFF",
          secondary: "#F8FAFC",
          tertiary: "#F1F5F9",
        },
        border: {
          default: "#E2E8F0",
        },
        text: {
          heading: "#0F172A",
          body: "#475569",
          muted: "#64748B",
        },
        status: {
          success: "#22C55E",
          warning: "#EAB308",
          error: "#EF4444",
        },
        /** focus ring token: ring-ring-focus */
        "ring-focus": "#0D9488",
      },
      
      // Typography
      fontFamily: {
        sans: ["Inter", "system-ui", "-apple-system", "BlinkMacSystemFont", "Segoe UI", "Roboto", "sans-serif"],
        display: ["Inter", "system-ui", "sans-serif"],
      },
      fontSize: {
        xs: ["0.75rem", { lineHeight: "1rem" }],
        sm: ["0.875rem", { lineHeight: "1.25rem" }],
        base: ["1rem", { lineHeight: "1.5rem" }],
        lg: ["1.125rem", { lineHeight: "1.75rem" }],
        xl: ["1.25rem", { lineHeight: "1.75rem" }],
        "2xl": ["1.5rem", { lineHeight: "2rem" }],
        "3xl": ["1.875rem", { lineHeight: "2.25rem" }],
        "4xl": ["2.25rem", { lineHeight: "2.5rem" }],
      },
      
      // Spacing (Custom values for consistent layouts)
      spacing: {
        "18": "4.5rem",
        "88": "22rem",
        "120": "30rem",
        "128": "32rem",
      },
      
      // Shadows
      boxShadow: {
        // Your custom soft shadow
        soft: "0 2px 15px -3px rgba(15, 23, 42, 0.07), 0 4px 6px -2px rgba(15, 23, 42, 0.05)",
        
        // Additional useful shadows
        card: "0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)",
        "card-hover": "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
        dropdown: "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
        modal: "0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)",
      },
      
      // Border Radius
      borderRadius: {
        "4xl": "2rem",
      },
      
      // Animation (For better UX feedback)
      animation: {
        "fade-in": "fadeIn 0.3s ease-in-out",
        "slide-up": "slideUp 0.3s ease-out",
        "slide-down": "slideDown 0.2s ease-out",
        "pulse-slow": "pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite",
      },
      keyframes: {
        fadeIn: {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        slideUp: {
          "0%": { transform: "translateY(10px)", opacity: "0" },
          "100%": { transform: "translateY(0)", opacity: "1" },
        },
        slideDown: {
          "0%": { transform: "translateY(-10px)", opacity: "0" },
          "100%": { transform: "translateY(0)", opacity: "1" },
        },
      },
      
      // Background Image (Optional gradient for hero sections)
      backgroundImage: {
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        "gradient-primary": "linear-gradient(135deg, #0D9488 0%, #115E59 100%)",
      },
    },
  },
  plugins: [
    // Add any custom plugins here
    forms, // Optional: Better form styling
    typography, // Optional: For rich text content
  ],
};

export default config;