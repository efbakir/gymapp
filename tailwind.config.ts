import type { Config } from "tailwindcss"

const config: Config = {
  darkMode: "class",
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        unit: {
          background: "var(--unit-background)",
          elevated: "var(--unit-elevated)",
          card: "var(--unit-card)",
          accent: "var(--unit-accent)",
          "accent-soft": "var(--unit-accent-soft)",
          "text-primary": "var(--unit-text-primary)",
          "text-secondary": "var(--unit-text-secondary)",
          border: "var(--unit-border)",
          ghost: "var(--unit-ghost)",
          progress: "var(--unit-progress)",
          failure: "var(--unit-failure)",
          deload: "var(--unit-deload)",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 4px)",
        sm: "calc(var(--radius) - 6px)",
      },
      fontFamily: {
        sans: ["var(--font-inter)", "system-ui", "sans-serif"],
      },
      spacing: {
        "unit-xxs": "4px",
        "unit-xs": "8px",
        "unit-sm": "12px",
        "unit-md": "16px",
        "unit-lg": "24px",
        "unit-xl": "32px",
        "unit-xxl": "48px",
        "unit-xxxl": "64px",
      },
    },
  },
  plugins: [],
}
export default config
