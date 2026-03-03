import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./frontend/index.html", "./frontend/src/**/*.{js,jsx,ts,tsx}", "./frontend/pages/**/*.{js,jsx}"],
  theme: {
    extend: {},
  },
  plugins: [],
};

export default config;
