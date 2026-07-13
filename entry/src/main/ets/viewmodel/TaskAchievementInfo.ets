/**
 * A milestone belonging to one task. Each multiple represents one complete
 * achievement of that task's target: 1 = 100%, 2 = 200%, and so on.
 */
export class TaskAchievementMilestone {
  multiple: number = 1;
  unlocked: boolean = false;

  constructor(multiple: number, unlocked: boolean) {
    this.multiple = multiple;
    this.unlocked = unlocked;
  }
}

/**
 * Aggregated achievement state for one task.
 */
export default class TaskAchievementInfo {
  taskID: number = 0;
  taskName: string = '';
  completionEquivalent: number = 0;
  totalPercent: number = 0;
  unlockedCount: number = 0;
  milestones: TaskAchievementMilestone[] = [];

  constructor(taskID: number, taskName: string) {
    this.taskID = taskID;
    this.taskName = taskName;
  }
}
