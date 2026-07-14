import dataRdb from '@ohos.data.relationalStore';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import RdbUtils from '../common/database/rdb/RdbUtils';

export const EXPERIENCE_PER_TASK: number = 20;
export const EXPERIENCE_PER_LEVEL: number = 100;

/** Snapshot of the user's level calculated from completed task records. */
export class UserLevelInfo {
  level: number = 0;
  currentExperience: number = 0;
  totalExperience: number = 0;
  completedTaskCount: number = 0;

  constructor(level: number, currentExperience: number, totalExperience: number, completedTaskCount: number) {
    this.level = level;
    this.currentExperience = currentExperience;
    this.totalExperience = totalExperience;
    this.completedTaskCount = completedTaskCount;
  }
}

/** Pure level calculation: every fully completed task is worth 20 experience. */
export function calculateUserLevel(completedTaskCount: number): UserLevelInfo {
  const safeCompletedCount = Math.max(0, Math.floor(completedTaskCount));
  const totalExperience = safeCompletedCount * EXPERIENCE_PER_TASK;
  return new UserLevelInfo(
    Math.floor(totalExperience / EXPERIENCE_PER_LEVEL),
    totalExperience % EXPERIENCE_PER_LEVEL,
    totalExperience,
    safeCompletedCount
  );
}

/**
 * Reconcile the level against task history. Global task templates are not real
 * task occurrences, so only completed date-specific records grant experience.
 */
export function queryUserLevel(): Promise<UserLevelInfo> {
  const tableName = Const.TASK_INFO.tableName as string;
  const predicates = new dataRdb.RdbPredicates(tableName);
  predicates.notEqualTo('date', Const.GLOBAL_KEY);
  predicates.equalTo('isDone', true);
  return RdbUtils.query(predicates, ['id']).then(resultSet => {
    return calculateUserLevel(resultSet.rowCount);
  });
}
