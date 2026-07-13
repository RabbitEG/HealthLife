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
import { padTo2Digits } from '../common/utils/Utils';
import TaskInfo, { oneWeek, TaskStatus } from './TaskInfo';
import { TaskMapById, RemindContentMap, ITaskItem } from '../model/TaskInitList';
import PublishReminderInfo from './PublishReminderInfo';

const publishReminder = reminder.publishReminder;
const cancelReminder = reminder.cancelReminder;
const hasNotificationId = reminder.hasNotificationId;
export const taskOriginData: ITaskItem[] = TaskMapById;

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
    publishReminderInfo.daysOfWeek = params?.frequency.split(',').map(item => Number(item));
    publishReminderInfo.title = RemindContentMap[params?.taskID - 1].title;
    publishReminderInfo.content = RemindContentMap[params?.taskID - 1].content;
    publishReminderInfo.notificationId = params?.taskID;
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
    if (params?.isOpen) {
      if (params?.isAlarm) {
        useReminder(params, context);
      } else {
        isHasNotificationId(params?.taskID).then((flag: boolean) => {
          if (flag) {
            useCancelReminder(params.taskID, context);
          }
        });
      }
    } else {
      isHasNotificationId(params?.taskID).then((flag: boolean) => {
        if (flag) {
          useCancelReminder(params.taskID, context);
        }
      });
    }
    const taskDate = targetDate || new Date().toDateString();
    TaskInfoApi.query(taskDate, false, (dateTasks: TaskInfo[]) => {
      const currentTask = dateTasks.find((item: TaskInfo) => item.taskID === params.taskID);
      TaskInfoApi.updateDataByDate(params, (globalFlag: number) => {
        if (!globalFlag) {
          Logger.error('insertTaskSetting', 'update global task setting failed!');
          reject(globalFlag);
          return;
        }
        let taskInfoStr = JSON.stringify(params);
        let taskInfo: TaskInfo = JSON.parse(taskInfoStr);
        taskInfo.date = taskDate;
        // Editing an active task must not erase the selected day's progress. A task that is
        // enabled for the first time (or re-enabled) always starts unfinished.
        if (params.isOpen && currentTask?.isOpen) {
          taskInfo.isDone = currentTask.isDone;
          taskInfo.finValue = currentTask.finValue;
          taskInfo.status = currentTask.status;
        } else {
          taskInfo.isDone = false;
          taskInfo.finValue = '';
          taskInfo.status = TaskStatus.NOT_STARTED;
        }
        TaskInfoApi.updateDataByDate(taskInfo, (dateFlag: number) => {
          if (dateFlag) {
            resolve(dateFlag);
            return;
          }
          // Older dates normally already contain task rows. Keep an insert fallback
          // so adding to an uninitialized date still writes to the selected date.
          TaskInfoApi.insertData(taskInfo, (insertFlag: number) => {
            if (!insertFlag) {
              Logger.error('insertTaskSetting', `save task for ${taskDate} failed!`);
              reject(insertFlag);
              return;
            }
            resolve(insertFlag);
          });
        });
      });
    });
  });
}

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
