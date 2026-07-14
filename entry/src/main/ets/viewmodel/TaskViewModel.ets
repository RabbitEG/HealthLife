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

import { CommonConstants as Const } from '../common/constants/CommonConstants';
import Logger from '../common/utils/Logger';
import reminder from '../service/ReminderAgent';
import TaskInfoApi from '../common/database/tables/TaskInfoApi';
import { dateToStr, padTo2Digits } from '../common/utils/Utils';
import TaskInfo, { oneWeek, TaskStatus } from './TaskInfo';
import { TaskMapById, RemindContentMap, ITaskItem } from '../model/TaskInitList';
import PublishReminderInfo from './PublishReminderInfo';

const publishReminder = reminder.publishReminder;
const cancelReminder = reminder.cancelReminder;
const hasNotificationId = reminder.hasNotificationId;
export const taskOriginData: ITaskItem[] = TaskMapById;

const PLAN_HORIZON_DAYS = 366;

function dateAtMidnight(dateStr: string): Date {
  let date = new Date(dateStr);
  date.setHours(0, 0, 0, 0);
  return date;
}

function isPastDate(dateStr: string): boolean {
  return dateAtMidnight(dateStr).getTime() < dateAtMidnight(new Date().toDateString()).getTime();
}

function isFutureDate(dateStr: string): boolean {
  return dateAtMidnight(dateStr).getTime() > dateAtMidnight(new Date().toDateString()).getTime();
}

function isFrequencyDate(date: Date, frequency: string): boolean {
  if (!frequency || frequency.trim().length === 0) {
    return true;
  }
  const frequencyIds = frequency.split(',')
    .map((item: string) => Number(item.trim()))
    .filter((item: number) => !Number.isNaN(item));
  if (frequencyIds.length === 0) {
    return true;
  }
  // The setting dialog uses Monday=1 ... Sunday=7 while Date.getDay()
  // uses Sunday=0 ... Saturday=6.
  const dayId = date.getDay() === 0 ? 7 : date.getDay();
  return frequencyIds.indexOf(dayId) >= 0;
}

function queryTasksOfDate(date: string): Promise<TaskInfo[]> {
  return new Promise((resolve) => {
    TaskInfoApi.query(date, false, (tasks: TaskInfo[]) => resolve(tasks));
  });
}

function saveTaskRecord(taskInfo: TaskInfo): Promise<number> {
  return new Promise((resolve, reject) => {
    TaskInfoApi.updateDataByDate(taskInfo, (updateFlag: number) => {
      if (updateFlag) {
        resolve(updateFlag);
        return;
      }
      TaskInfoApi.insertData(taskInfo, (insertFlag: number) => {
        if (!insertFlag) {
          reject(new Error(`save task failed: ${taskInfo.date}/${taskInfo.taskID}`));
          return;
        }
        resolve(insertFlag);
      });
    });
  });
}

function copyTaskProgress(target: TaskInfo, source: TaskInfo): void {
  target.isDone = source.isDone;
  target.finValue = source.finValue;
  target.status = source.status;
  target.subTasks = source.subTasks;
  target.inputHistory = source.inputHistory;
}

/**
 * @description Get all task status
 * @return object[] Database query results
 */
export const getAllTask = () => {
  return new Promise<TaskInfo[]>((resolve) => {
    TaskInfoApi.query(Const.GLOBAL_KEY, true, (res: TaskInfo[]) => {
      if (res?.length === 0) {
        Logger.warn('queryTaskList', 'has no data!!');
        resolve(res ?? []);
      }
      resolve(res);
    })
  });
}

/**
 * @description Call notification capability
 * @param params {
 *  hour: Hour
 *  minute: Minute
 *  daysOfWeek: Frequency of a week
 *  title: Notice Title
 *  content: Contents of notice
 *  notificationId: Notification ID
 */
const useReminder = (params: TaskInfo, context: Context) => {
  try {
    let publishReminderInfo = new PublishReminderInfo();
    publishReminderInfo.hour = Number(params?.startTime.split(':')[0]);
    publishReminderInfo.minute = Number(params?.startTime.split(':')[1]);
    publishReminderInfo.daysOfWeek = params?.frequency && params.frequency.trim().length > 0
      ? params.frequency.split(',').map(item => Number(item.trim()))
      : [1, 2, 3, 4, 5, 6, 7];
    publishReminderInfo.title = RemindContentMap[params?.taskID - 1].title;
    publishReminderInfo.content = RemindContentMap[params?.taskID - 1].content;
    publishReminderInfo.notificationId = params?.taskID;
    publishReminderInfo.oneOffDate = params?.isRecurring ? '' : (params?.planStartDate || params?.date || '');
    publishReminder(publishReminderInfo, context);
  } catch (error) {
    Logger.error('publishReminder', JSON.stringify(error));
  }
}

/**
 * @description Call cancel notification capability
 * @param reminderId Notification ID
 */
const useCancelReminder = (reminderId: number, context: Context) => {
  try {
    cancelReminder(reminderId, context);
  } catch (error) {
    Logger.error('cancelReminder', JSON.stringify(error));
  }
}

/**
 * @description Determine whether there is a notification
 * @param notificationId Notification ID
 */
const isHasNotificationId = (notificationId: number) => {
  return new Promise<boolean>((resolve) => {
    resolve(hasNotificationId(notificationId));
  });
}

/**
 * @param params:TaskInfo
 */
export const addTask = (params: TaskInfo, context: Context, targetDate?: string) => {
  if (!params) {
    Logger.error('addTask', 'params is null!');
    return new Promise<number>((resolve) => {
      resolve(-1);
    });
  }
  return new Promise<number>(async (resolve, reject) => {
    Logger.info('TaskViewModel', 'addTask');
    const taskDate = targetDate || params.date || new Date().toDateString();
    const pastDate = isPastDate(taskDate);
    // Historical entries are always one-off. For today and future dates the
    // UI defaults to a recurring plan unless the user explicitly selects the
    // one-off option.
    const isRecurringPlan = !pastDate && params.repeatEnabled !== false;
    const planStartDate = params.planStartDate || taskDate;
    const planStartsInFuture = isFutureDate(planStartDate);

    const saveDateTask = async (date: string, preserveProgress: boolean): Promise<number> => {
      const dateTasks = await queryTasksOfDate(date);
      const currentTask = dateTasks.find((item: TaskInfo) => item.taskID === params.taskID);
      const taskInfo = JSON.parse(JSON.stringify(params)) as TaskInfo;
      taskInfo.date = date;
      taskInfo.planStartDate = isRecurringPlan ? planStartDate : date;
      taskInfo.isRecurring = isRecurringPlan;
      taskInfo.isDone = false;
      taskInfo.finValue = '';
      taskInfo.status = TaskStatus.NOT_STARTED;
      taskInfo.inputHistory = '';
      // Editing an active record keeps that day's independent progress. New
      // records, including the first occurrence, always start at zero.
      if (preserveProgress && params.isOpen && currentTask?.isOpen) {
        copyTaskProgress(taskInfo, currentTask);
      }
      return saveTaskRecord(taskInfo);
    };

    try {
      if (isRecurringPlan) {
        const globalTask = JSON.parse(JSON.stringify(params)) as TaskInfo;
        globalTask.date = Const.GLOBAL_KEY;
        globalTask.planStartDate = planStartDate;
        globalTask.isRecurring = true;
        globalTask.isDone = false;
        globalTask.finValue = '';
        globalTask.status = TaskStatus.NOT_STARTED;
        globalTask.inputHistory = '';
        await saveTaskRecord(globalTask);

        // Materialize a year of occurrences immediately. DatabaseModel also
        // lazily creates later dates from this global plan when they are first
        // opened, so the plan is not limited to this window.
        let cursor = dateAtMidnight(planStartDate);
        for (let index = 0; index < PLAN_HORIZON_DAYS; index++) {
          if (isFrequencyDate(cursor, params.frequency)) {
            // Every already-created occurrence owns its own progress. Keep
            // that progress when a plan is edited; only genuinely new rows
            // are initialized as unfinished by saveDateTask.
            await saveDateTask(dateToStr(cursor), true);
          }
          cursor.setDate(cursor.getDate() + 1);
        }
      } else {
        // A historical entry and an explicit one-off entry only touch the
        // selected date. In particular, they never rewrite the global plan.
        await saveDateTask(taskDate, true);
        if (!pastDate && !isRecurringPlan) {
          // Turning an existing current/future plan off also stops future
          // occurrences; the selected one-off record above remains local.
          const globalTask = JSON.parse(JSON.stringify(params)) as TaskInfo;
          globalTask.date = Const.GLOBAL_KEY;
          globalTask.isOpen = false;
          globalTask.isAlarm = false;
          globalTask.isRecurring = false;
          globalTask.planStartDate = '';
          await saveTaskRecord(globalTask);
        }
      }

      // Historical edits never touch reminders. A one-off future task can be
      // represented by a calendar reminder immediately, while a recurring
      // plan whose start date is still in the future is synchronized when its
      // start date arrives. Turning a non-historical task off always cancels
      // any reminder that may belong to the previous plan.
      const canPublishReminder = !pastDate && params?.isOpen && params?.isAlarm
        && (!isRecurringPlan || !planStartsInFuture);
      const shouldCancelReminder = !pastDate && (!params?.isOpen || !params?.isAlarm);
      if (canPublishReminder) {
        useReminder(params, context);
      } else if (shouldCancelReminder) {
        isHasNotificationId(params?.taskID).then((flag: boolean) => {
          if (flag) {
            useCancelReminder(params.taskID, context);
          }
        });
      }
      resolve(1);
    } catch (error) {
      Logger.error('insertTaskSetting', JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Activate reminders for plans whose start date has arrived. Future plans are
 * deliberately ignored until this check runs on or after their start date.
 */
export const syncPlanReminders = (context: Context): void => {
  TaskInfoApi.query(Const.GLOBAL_KEY, false, (globalTasks: TaskInfo[]) => {
    const today = dateAtMidnight(new Date().toDateString());
    globalTasks.forEach((task: TaskInfo) => {
      if (!task.isOpen || !task.isAlarm) {
        return;
      }
      const startDate = dateAtMidnight(task.planStartDate || today.toDateString());
      if (startDate.getTime() <= today.getTime()) {
        useReminder(task, context);
      }
    });

    // One-off tasks are stored only on their selected date. Once that date
    // arrives, publish its reminder as well; they are intentionally not
    // scheduled while the selected date is still in the future.
    TaskInfoApi.query(today.toDateString(), false, (todayTasks: TaskInfo[]) => {
      todayTasks.forEach((task: TaskInfo) => {
        if (!task.isOpen || !task.isAlarm || task.isRecurring) {
          return;
        }
        const taskDate = dateAtMidnight(task.planStartDate || task.date);
        if (taskDate.getTime() <= today.getTime()) {
          useReminder(task, context);
        }
      });
    });
  });
};

/**
 * @description Used to initialize task list data from database data
 * @param taskInitList Task list initial data
 * @param taskInfoData Database query data
 */
export const taskIndexDataInit = (taskInitList: ITaskItem[], taskInfoData: TaskInfo[]) => {
  const afterInitData = taskInitList.map((content) => {
    taskInfoData.forEach((item) => {
      if (item?.taskID === content?.taskID) {
        content.isOpen = item?.isOpen;
        content.targetValue = item?.targetValue;
        content.isAlarm = item?.isAlarm;
        content.startTime = item?.startTime;
        content.endTime = item?.endTime;
        content.frequency = item?.frequency;
        content.taskName = item?.taskName;
        content.taskType = item?.taskType;
        content.unit = item?.unit;
        content.status = item?.status;
        content.subTasks = item?.subTasks;
        content.cycleDays = item?.cycleDays;
        content.cycleTarget = item?.cycleTarget;
        content.dataSrc = item?.dataSrc;
        content.planStartDate = item?.planStartDate;
        if (item?.isRecurring) {
          content.repeatEnabled = true;
        } else if (item?.planStartDate) {
          content.repeatEnabled = false;
        } else {
          content.repeatEnabled = undefined;
        }
      }
    });
    return content;
  });
  return afterInitData;
}

/**
 * @description format data as json string
 * @param params = {}
 */
export const formatParams = (params: ITaskItem) => {
  return JSON.stringify(params);
}

/**
 * @description Initialization frequency string
 * @param frequencyIdCollection
 * @return string Frequency string
 */
export const initFrequencyString = (frequencyIdCollection: string) => {
  if (frequencyIdCollection === '') {
    return Const.EVERYDAY;
  }
  const frequencyIdArray: Array<number> = frequencyIdCollection.split(',').map(item => Number(item) - 1);
  const length = frequencyIdArray.length;
  if (length === 7) {
    return Const.EVERYDAY;
  }
  const frequencyString = frequencyIdArray.reduce((pre, current) => {
    return pre + ' ' + oneWeek[current];
  }, '')
  return frequencyString;
}

/**
 * @description Returns the timestamp of today's selected time
 * @param currentTime
 * @return timestamp
 */
export function returnTimeStamp(currentTime: string) {
  const timeString = `${new Date().toDateString()} ${currentTime}`;
  return new Date(timeString).getTime();
}

/**
 * @description It is used for formatting time and displayed in the form of HH: mm
 * @param value
 */
export const formatTime = (value: TimePickerResult) => {
  let hour = value?.hour ? value?.hour : 8;
  let minute = value?.minute ? value?.minute : 0;
  return `${padTo2Digits(hour)}:${padTo2Digits(minute)}`;
}

/**
 * @description Range of generated drinking water 250 - 5000 mL
 * @return Array<string>
 */
export const createDrinkRange = () => {
  const drinkRangeArr: Array<string> = []
  for (let i = 250; i <= 5000; i += 250) {
    drinkRangeArr.push(`${i} mL`);
  }
  return drinkRangeArr;
}

/**
 * @description Generate the range of eating apples 1 - 100
 * @return Array<string>
 */
export const createAppleRange = () => {
  const appleRangeArr: Array<string> = [];
  for (let i = 1; i <= Const.EAT_APPLE_RANGE; i++) {
    appleRangeArr.push(`${i} 个`);
  }
  return appleRangeArr;
}
