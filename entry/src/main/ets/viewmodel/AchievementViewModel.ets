/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import CardInfo from './CardInfo';
import RdbUtils from '../common/database/rdb/RdbUtils';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { TaskMapById } from '../model/TaskInitList';
import TaskAchievementInfo, { TaskAchievementMilestone } from './TaskAchievementInfo';

import { ACHIEVEMENT_LEVEL_LIST, AchievementMap } from '../model/TaskInitList';

const DEFAULT_VISIBLE_MULTIPLIER: number = 4;
const MAX_VISIBLE_MILESTONES: number = 12;

export function getBadgeCardItems(successiveDays: number): Array<CardInfo> {
  let badgeMileStones = ACHIEVEMENT_LEVEL_LIST;
  let cardItems: Array<CardInfo> = [];
  for (let i = 0; i < badgeMileStones.length; i++) {
    let onOrOff = successiveDays >= badgeMileStones[i] ? 'on' : 'off';
    let titleContent = String(badgeMileStones[i]);
    let cardInfo: CardInfo = new CardInfo();
    cardInfo.titleContent = titleContent;
    cardInfo.achievement = getAchievement(`${ onOrOff }_${ badgeMileStones[i] }`);
    cardItems.push(cardInfo);
  }
  return cardItems;
}

function getAchievement(key: string) {
  let result = $r('app.string.empty');
  switch (key) {
    case 'off_1':
      result = AchievementMap.off_1;
      break;
    case 'on_1':
      result = AchievementMap.on_1;
      break;
    case 'off_3':
      result = AchievementMap.off_3;
      break;
    case 'on_3':
      result = AchievementMap.on_3;
      break;
    case 'off_7':
      result = AchievementMap.off_7;
      break;
    case 'on_7':
      result = AchievementMap.on_7;
      break;
    case 'off_30':
      result = AchievementMap.off_30;
      break;
    case 'on_30':
      result = AchievementMap.on_30;
      break;
    case 'off_50':
      result = AchievementMap.off_50;
      break;
    case 'on_50':
      result = AchievementMap.on_50;
      break;
    case 'off_73':
      result = AchievementMap.off_73;
      break;
    case 'on_73':
      result = AchievementMap.on_73;
      break;
    case 'off_99':
      result = AchievementMap.off_99;
      break;
    case 'on_99':
      result = AchievementMap.on_99;
      break;
    default:
      break;
  }
  return result;
}

/**
 * Load the task history and calculate task-specific achievements without a
 * schema migration. A completed daily target contributes 100%; an over-target
 * record contributes its real target multiple. Partial, unfinished records do
 * not unlock a medal.
 */
export function queryTaskAchievementItems(): Promise<TaskAchievementInfo[]> {
  return RdbUtils.queryAll(Const.TASK_INFO.tableName as string).then(resultSet => {
    let achievementMap: Map<number, TaskAchievementInfo> = new Map<number, TaskAchievementInfo>();
    let count = resultSet.rowCount;

    if (count > 0 && typeof count !== 'string') {
      resultSet.goToFirstRow();
      for (let i = 0; i < count; i++) {
        let taskID = resultSet.getDouble(resultSet.getColumnIndex('taskID'));
        let date = resultSet.getString(resultSet.getColumnIndex('date'));
        let taskName = resultSet.getString(resultSet.getColumnIndex('taskName'));
        let isOpen = resultSet.getDouble(resultSet.getColumnIndex('isOpen')) > 0;
        let currentItem = achievementMap.get(taskID);

        if (date === Const.GLOBAL_KEY) {
          if (isOpen) {
            currentItem = currentItem ?? new TaskAchievementInfo(taskID, getTaskName(taskID, taskName));
            currentItem.taskName = getTaskName(taskID, taskName);
            achievementMap.set(taskID, currentItem);
          }
        } else if (isOpen) {
          let isDone = resultSet.getDouble(resultSet.getColumnIndex('isDone')) > 0;
          let targetValue = resultSet.getString(resultSet.getColumnIndex('targetValue'));
          let finValue = resultSet.getString(resultSet.getColumnIndex('finValue'));
          let equivalent = calculateCompletionEquivalent(targetValue, finValue, isDone);

          if (equivalent > 0 || currentItem) {
            currentItem = currentItem ?? new TaskAchievementInfo(taskID, getTaskName(taskID, taskName));
            currentItem.completionEquivalent += equivalent;
            achievementMap.set(taskID, currentItem);
          }
        }
        resultSet.goToNextRow();
      }
    }

    let result: TaskAchievementInfo[] = [];
    achievementMap.forEach((item: TaskAchievementInfo) => {
      item.totalPercent = Math.floor(item.completionEquivalent * 100);
      item.unlockedCount = Math.floor(item.completionEquivalent);
      item.milestones = createVisibleMilestones(item.unlockedCount);
      result.push(item);
    });
    result.sort((left: TaskAchievementInfo, right: TaskAchievementInfo) => left.taskID - right.taskID);
    return result;
  });
}

/**
 * Pure calculation helper kept public so the 100%/200%/300% rules can be
 * verified independently from the database.
 */
export function calculateCompletionEquivalent(targetValue: string, finValue: string, isDone: boolean): number {
  if (!isDone) {
    return 0;
  }
  let target = Number(targetValue);
  let finished = Number(finValue);
  if (!Number.isNaN(target) && target > 0 && !Number.isNaN(finished) && finished > 0) {
    return Math.max(1, finished / target);
  }
  return 1;
}

/**
 * The achievement level itself is unlimited. To keep the page responsive for
 * long-running users, the UI shows the first levels plus the latest unlocked
 * levels and the next locked level after level 12.
 */
export function createVisibleMilestones(unlockedCount: number): TaskAchievementMilestone[] {
  let visibleEnd = Math.max(DEFAULT_VISIBLE_MULTIPLIER, unlockedCount + 1);
  let result: TaskAchievementMilestone[] = [];
  if (visibleEnd <= MAX_VISIBLE_MILESTONES) {
    for (let multiple = 1; multiple <= visibleEnd; multiple++) {
      result.push(new TaskAchievementMilestone(multiple, multiple <= unlockedCount));
    }
    return result;
  }

  for (let multiple = 1; multiple <= DEFAULT_VISIBLE_MULTIPLIER; multiple++) {
    result.push(new TaskAchievementMilestone(multiple, true));
  }
  result.push(new TaskAchievementMilestone(unlockedCount - 1, true));
  result.push(new TaskAchievementMilestone(unlockedCount, true));
  result.push(new TaskAchievementMilestone(unlockedCount + 1, false));
  return result;
}

function getTaskName(taskID: number, storedName: string): string {
  if (storedName) {
    return storedName;
  }
  let templateIndex = taskID - 1;
  if (templateIndex >= 0 && templateIndex < TaskMapById.length) {
    return TaskMapById[templateIndex].taskName;
  }
  return `任务 ${taskID}`;
}
