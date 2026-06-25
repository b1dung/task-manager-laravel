#!/usr/bin/env python3
import glob, os, zipfile
f = sorted(glob.glob("backend-laravel-*.zip"), key=os.path.getmtime)[-1]
print("FILE:", f)
z = zipfile.ZipFile(f)
data = z.read("backend/vendor/composer/platform_check.php").decode()
for line in data.splitlines():
    if "PHP_VERSION_ID" in line or "require a PHP version" in line:
        print("  " + line.strip())
