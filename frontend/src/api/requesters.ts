import { apiClient } from './client'

export interface Requester {
  id: string
  projectId: string
  name: string
  color: string
}

export const requestersApi = {
  list: (projectId: string) =>
    apiClient.get<{ success: true; data: Requester[] }>(`/projects/${projectId}/requesters`).then((r) => r.data.data),
  create: (projectId: string, dto: { name: string; color: string }) =>
    apiClient.post<{ success: true; data: Requester }>(`/projects/${projectId}/requesters`, dto).then((r) => r.data.data),
  update: (projectId: string, id: string, dto: { name?: string; color?: string }) =>
    apiClient.patch<{ success: true; data: Requester }>(`/projects/${projectId}/requesters/${id}`, dto).then((r) => r.data.data),
  delete: (projectId: string, id: string) =>
    apiClient.delete(`/projects/${projectId}/requesters/${id}`),
}
