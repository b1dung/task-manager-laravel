export declare const SocketEvents: {
    readonly TASK_CREATED: "task:created";
    readonly TASK_UPDATED: "task:updated";
    readonly TASK_MOVED: "task:moved";
    readonly TASK_DELETED: "task:deleted";
    readonly COMMENT_ADDED: "comment:added";
    readonly NOTIFICATION_NEW: "notification:new";
};
export type SocketEventName = (typeof SocketEvents)[keyof typeof SocketEvents];
export interface TaskMovedPayload {
    taskId: string;
    projectId: string;
    fromColumnId: string;
    toColumnId: string;
    position: number;
}
