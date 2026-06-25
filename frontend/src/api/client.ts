import axios from 'axios'
import { useAuthStore } from '@/stores/useAuthStore'

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? '/api/v1',
  timeout: 15000,
  withCredentials: true,
  headers: { 'Content-Type': 'application/json' },
})

apiClient.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// Single-flight refresh: a burst of concurrent 401s (e.g. every project query
// refetching at once after a realtime `task:updated` invalidation) must trigger
// exactly ONE /auth/refresh. The refresh token cookie rotates and is single-use,
// so a second concurrent refresh would present an already-consumed token and fail,
// logging the user out and breaking otherwise-successful requests. All callers
// await the same in-flight promise instead.
let refreshPromise: Promise<string> | null = null

function refreshAccessToken(): Promise<string> {
  if (!refreshPromise) {
    refreshPromise = axios
      .post(`${import.meta.env.VITE_API_URL ?? '/api/v1'}/auth/refresh`, {}, { withCredentials: true })
      .then((res) => {
        const { accessToken } = res.data.data as { accessToken: string }
        useAuthStore.getState().setTokens(accessToken, '')
        return accessToken
      })
      .finally(() => { refreshPromise = null })
  }
  return refreshPromise
}

apiClient.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config
    if (error.response?.status !== 401 || !original || original._retry) {
      return Promise.reject(error)
    }
    original._retry = true
    try {
      const token = await refreshAccessToken()
      original.headers.Authorization = `Bearer ${token}`
      return apiClient(original)
    } catch {
      useAuthStore.getState().logout()
      return Promise.reject(error)
    }
  },
)
