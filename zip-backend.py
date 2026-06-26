#!/usr/bin/env python3
import os, sys, time, zipfile, fnmatch

root = os.path.dirname(os.path.abspath(__file__))
src = os.path.join(root, "backend")
stamp = time.strftime("%Y%m%d-%H%M%S")
out = os.path.join(root, f"backend-laravel-{stamp}.zip")

# Directory names to skip entirely (matched on any path segment under backend/)
SKIP_DIRS = {".git", "node_modules"}
# Glob patterns (relative to backend/) to exclude. NB: fnmatch '*' also matches '/',
# so "storage/app/uploads/*" excludes every uploaded file at any depth.
SKIP_GLOBS = [
    ".env",
    "storage/logs/*.log",
    "storage/framework/cache/data/*",
    "storage/framework/sessions/*",
    "storage/framework/views/*.php",
    # User uploads (attachments + avatars): ship the folder structure (.gitignore
    # markers, kept below) but NEVER the files, so a redeploy can't overwrite them.
    "storage/app/uploads/*",
]
# Basenames always kept even if they match a SKIP_GLOB (so empty folders survive).
KEEP_BASENAMES = {".gitignore", ".gitkeep"}

def excluded(rel):
    if os.path.basename(rel) in KEEP_BASENAMES:
        return False
    return any(fnmatch.fnmatch(rel, g) for g in SKIP_GLOBS)

count = 0
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for dirpath, dirnames, filenames in os.walk(src):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, src).replace(os.sep, "/")
            if excluded(rel):
                continue
            z.write(full, arcname=f"backend/{rel}")
            count += 1

size = os.path.getsize(out)
print(f"WROTE {os.path.basename(out)}")
print(f"files: {count}  size: {size/1024/1024:.1f} MB")
