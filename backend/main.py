from pathlib import Path
import os

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles


BASE_DIR = Path(__file__).parent
STATIC_DIR = BASE_DIR / "static"

app = FastAPI(title="GPT-5 Dashboard", version="1.0.0")

# Serve built frontend assets when present
if STATIC_DIR.exists():
    assets_dir = STATIC_DIR / "assets"
    if assets_dir.exists():
        app.mount("/assets", StaticFiles(directory=assets_dir, html=False), name="assets")
    app.mount("/static", StaticFiles(directory=STATIC_DIR, html=True), name="static")


@app.get("/health", tags=["system"])
async def health() -> dict:
    return {"status": "healthy"}


@app.get("/api/ping", tags=["system"])
async def ping() -> dict:
    return {"message": "pong"}


@app.get("/", include_in_schema=False)
async def serve_index():
    index_path = STATIC_DIR / "index.html"
    if index_path.exists():
        return FileResponse(index_path)
    return JSONResponse(
        {
            "status": "ok",
            "message": "Frontend build not found. Run `npm run build` in /frontend.",
        }
    )


@app.get("/{full_path:path}", include_in_schema=False)
async def spa_handler(full_path: str):
    asset_path = STATIC_DIR / full_path
    if asset_path.exists() and asset_path.is_file():
        return FileResponse(asset_path)

    index_path = STATIC_DIR / "index.html"
    if index_path.exists():
        return FileResponse(index_path)
    raise HTTPException(status_code=404, detail="Not Found")


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8080")),
        reload=False,
    )
