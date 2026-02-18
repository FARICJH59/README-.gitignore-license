$root = "$env:USERPROFILE\Projects\axiomcore\frontend"

Write-Host "Scaffolding AxiomCore Enterprise Frontend..." -ForegroundColor Cyan

# Structure
$folders = @(
    "src\app",
    "src\app\dashboard",
    "src\app\api\health",
    "src\components",
    "src\lib"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path (Join-Path $root $folder) -Force | Out-Null
}

# layout.tsx
@"
import "./globals.css"
import Navbar from "../components/Navbar"
import Sidebar from "../components/Sidebar"

export default function RootLayout({ children }) {
  return (
    <html>
        <body>{children}</body>
    </html>
  )
}
"@ | Set-Content "$root\src\app\layout.tsx"

# page.tsx
@"
export default function Home() {
  return (
    <>
      <h1>🚀 AxiomCore Control Plane</h1>
      <p>System Status: Operational</p>
    </>
  )
}
"@ | Set-Content "$root\src\app\page.tsx"

# API health
@"
export async function GET() {
  return Response.json({
    status: "ok",
    service: "axiomcore-frontend",
    timestamp: new Date().toISOString(),
  })
}
"@ | Set-Content "$root\src\app\api\health\route.ts"

# Install deps
Set-Location $root
npm install

Write-Host "Starting dev server..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command cd `"$root`"; npm run dev"

Start-Process "http://localhost:3000"

Write-Host "AxiomCore Enterprise Frontend Ready." -ForegroundColor Green
