# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: laravel-board.spec.ts >> Laravel board receives task updates through Reverb
- Location: src/e2e/laravel-board.spec.ts:3:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5174/login
Call log:
  - navigating to "http://localhost:5174/login", waiting until "load"

```

# Test source

```ts
  1  | import { test, expect } from '@playwright/test'
  2  | 
  3  | test('Laravel board receives task updates through Reverb', async ({ page }) => {
> 4  |   await page.goto('/login')
     |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5174/login
  5  |   await page.locator('input[type="email"]').fill('admin@taskboard.dev')
  6  |   await page.locator('input[type="password"]').fill('password123')
  7  | 
  8  |   const loginResponsePromise = page.waitForResponse((response) => response.url().includes('/api/v1/auth/login') && response.request().method() === 'POST')
  9  |   await page.locator('button[type="submit"]').click()
  10 |   const loginPayload = await (await loginResponsePromise).json()
  11 |   const token = loginPayload.data.accessToken as string
  12 |   await expect(page).toHaveURL(/\/projects/, { timeout: 10_000 })
  13 | 
  14 |   const headers = { Authorization: `Bearer ${token}`, Accept: 'application/json' }
  15 |   const projectResponse = await page.request.post('/api/v1/projects', { headers, data: { name: `E2E Realtime ${Date.now()}` } })
  16 |   expect(projectResponse.ok()).toBeTruthy()
  17 |   const projectId = (await projectResponse.json()).data.id as string
  18 |   const columns = (await (await page.request.get(`/api/v1/projects/${projectId}/columns`, { headers })).json()).data
  19 |   const columnId = columns[0].id as string
  20 | 
  21 |   await page.request.post(`/api/v1/projects/${projectId}/tasks`, { headers, data: { columnId, title: 'Initial Laravel Task' } })
  22 |   await page.goto(`/projects/${projectId}/tasks`)
  23 |   await expect(page.getByText('Initial Laravel Task')).toBeVisible({ timeout: 10_000 })
  24 | 
  25 |   await page.request.post(`/api/v1/projects/${projectId}/tasks`, { headers, data: { columnId, title: 'Realtime Laravel Task' } })
  26 |   await expect(page.getByText('Realtime Laravel Task')).toBeVisible({ timeout: 10_000 })
  27 | })
  28 | 
```