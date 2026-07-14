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
import DayInfo from '../viewmodel/DayInfo';
import GlobalInfo from '../viewmodel/GlobalInfo';
import TaskInfo from '../viewmodel/TaskInfo';
import DayInfoApi from '../common/database/tables/DayInfoApi';
import GlobalInfoApi from '../common/database/tables/GlobalInfoApi';
import TaskInfoApi from '../common/database/tables/TaskInfoApi';
import Logger from '../common/utils/Logger';
import { TaskList } from './TaskInitList';

function normalizeDate(dateStr: string): Date {
  let date = new Date(dateStr);
  date.setHours(0, 0, 0, 0);
  return date;
}

function matchesFrequency(date: Date, frequency: string): boolean {
  if (!frequency || frequency.trim().length === 0) {
    return true;
  }
  const ids = frequency.split(',')
    .map((item: string) => Number(item.trim()))
    .filter((item: number) => !Number.isNaN(item));
  if (ids.length === 0) {
    return true;
  }
  const dayId = date.getDay() === 0 ? 7 : date.getDay();
  return ids.indexOf(dayId) >= 0;
}

function upsertTask(task: TaskInfo): Promise<number> {
  return new Promise((resolve, reject) => {
    TaskInfoApi.updateDataByDate(task, (updateFlag: number) => {
      if (updateFlag) {
        resolve(updateFlag);
        return;
      }
      TaskInfoApi.insertData(task, (insertFlag: number) => {
        if (!insertFlag) {
          reject(new Error(`save task failed: ${task.date}/${task.taskID}`));
          return;
        }
        resolve(insertFlag);
      });
    });
  });
}

export class DatabaseModel {
  /**
   * Init when open the app
   *
   * @param date
   * @param callback
   */
  query(date: string, callback: Function) {
    let result: TaskInfo[] = [];
    let self = this;
    GlobalInfoApi.query((globalResult: GlobalInfo) => {
      if (!globalResult.firstDate) { // if global information is not found, it is written
        let globalInfo: GlobalInfo = new GlobalInfo(date, date, 0, '');
        GlobalInfoApi.insertData(globalInfo, (isDone: number) => {
          if (isDone) {
            Logger.info('AppStart', 'Insert globalInfo success: ' + JSON.stringify(globalInfo));
          }
        });
        self.insertGlobalTask();
        let dayInfo: DayInfo = new DayInfo(date, 0, 0);
        DayInfoApi.insertData(dayInfo, (isDone: number) => {
          if (isDone) {
            Logger.info('AppStart', 'Insert dayInfo success: ' + JSON.stringify(dayInfo));
          }
        })
        self.insertTask(date);
        callback(result, dayInfo);
      } else { // if global information is found, the task information for the day is queried
        let newGlobalInfo = globalResult;
        let preDate = globalResult.lastDate;
        newGlobalInfo.lastDate = date;
        GlobalInfoApi.updateData(newGlobalInfo, (isDone: number) => {
          if (isDone) {
            Logger.info('AppStart', 'update globalInfo success: ' + JSON.stringify(newGlobalInfo));
          }
        });
        Promise.all([
          self.ensureTasksForDate(Const.GLOBAL_KEY),
          self.ensureTasksForDate(date)
        ]).then(() => {
          self.queryPreInfo(date, preDate, result, callback);
        });
      }
    });
  }

  ensureTasksForDate(date: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      TaskInfoApi.query(date, false, (existing: TaskInfo[]) => {
        // The global template is maintained only for today/future recurring
        // plans. A historical date is never copied back into it.
        if (date === Const.GLOBAL_KEY) {
          const missing = TaskList.filter((template: TaskInfo) => {
            return !existing.some((item: TaskInfo) => item.taskID === template.taskID);
          });
          Promise.all(missing.map((template: TaskInfo) => {
            const task = JSON.parse(JSON.stringify(template)) as TaskInfo;
            task.id = 0;
            task.date = date;
            task.isOpen = false;
            task.isAlarm = false;
            task.isDone = false;
            task.finValue = '';
            task.planStartDate = '';
            task.isRecurring = false;
            return upsertTask(task);
          })).then(() => resolve()).catch((error: Error) => reject(error));
          return;
        }

        TaskInfoApi.query(Const.GLOBAL_KEY, false, (globalTasks: TaskInfo[]) => {
          const today = normalizeDate(new Date().toDateString());
          const targetDate = normalizeDate(date);
          const operations: Promise<number>[] = [];

          TaskList.forEach((template: TaskInfo) => {
            const current = existing.find((item: TaskInfo) => item.taskID === template.taskID);
            const globalTask = globalTasks.find((item: TaskInfo) => item.taskID === template.taskID);
            const legacyPlan = globalTask?.isOpen && !globalTask?.planStartDate;
            const hasPlan = globalTask?.isOpen && (globalTask?.isRecurring || legacyPlan);
            const startDate = normalizeDate(globalTask?.planStartDate || today.toDateString());
            const isScheduled = hasPlan && targetDate.getTime() >= startDate.getTime()
              && matchesFrequency(targetDate, globalTask?.frequency || '');

            if (isScheduled && globalTask) {
              const task = JSON.parse(JSON.stringify(globalTask)) as TaskInfo;
              task.id = current?.id || 0;
              task.date = date;
              task.isOpen = true;
              task.planStartDate = globalTask.planStartDate || today.toDateString();
              task.isRecurring = true;
              task.isDone = false;
              task.finValue = '';
              task.status = 0;
              task.inputHistory = '';
              if (current?.isOpen && current?.isRecurring
                && current.planStartDate === task.planStartDate) {
                task.isDone = current.isDone;
                task.finValue = current.finValue;
                task.status = current.status;
                task.inputHistory = current.inputHistory;
                task.subTasks = current.subTasks;
              }
              operations.push(upsertTask(task));
            } else if (!current) {
              const task = JSON.parse(JSON.stringify(template)) as TaskInfo;
              task.id = 0;
              task.date = date;
              task.isOpen = false;
              task.isAlarm = false;
              task.isDone = false;
              task.finValue = '';
              task.planStartDate = '';
              task.isRecurring = false;
              operations.push(upsertTask(task));
            } else if (current.isRecurring && targetDate.getTime() >= today.getTime()
              && !isScheduled) {
              // A changed frequency or a stopped plan must not leave stale
              // future occurrences visible. Historical records are retained.
              const task = JSON.parse(JSON.stringify(current)) as TaskInfo;
              task.isOpen = false;
              task.isRecurring = false;
              operations.push(upsertTask(task));
            }
          });
          Promise.all(operations).then(() => resolve()).catch((error: Error) => reject(error));
        });
      });
    });
  }

  insertGlobalTask() {
    for (let i = 0; i < Const.TASK_NUM; i++) {
      let tmp = JSON.parse(JSON.stringify(TaskList[i])) as TaskInfo;
      tmp.id = 0;
      tmp.date = Const.GLOBAL_KEY;
      tmp.isOpen = false;
      tmp.isAlarm = false;
      TaskInfoApi.insertData(tmp, (isDone: number) => {
        if (isDone) {
          Logger.info('AppStart', 'Insert taskGlobalInfo success: ' + JSON.stringify(tmp));
        }
      });
    }
  }

  insertTask(date: string) {
    for (let i = 0; i < Const.TASK_NUM; i++) {
      let tmp = JSON.parse(JSON.stringify(TaskList[i])) as TaskInfo;
      tmp.id = 0;
      tmp.date = date;
      tmp.isOpen = false;
      tmp.isAlarm = false;
      TaskInfoApi.insertData(tmp, (isDone: number) => {
        if (isDone) {
          Logger.info('AppStart', 'Insert taskInfo success: ' + JSON.stringify(tmp));
        }
      });
    }
  }

  queryPreInfo(date: string, preDate: string, result: TaskInfo[], callback: Function) {
    TaskInfoApi.query(date, false, async (taskResult: TaskInfo[]) => { // query the task information for the day
      let dayInfo: DayInfo = new DayInfo(date, 0, 0);
      if (taskResult.length === 0) { // if task information for the day is not found, the global task information is queried
        let curDate = new Date(preDate);
        curDate.setDate(curDate.getDate() + 1);
        Logger.info('AppStart', 'insert data begin: ' + curDate.toDateString())
        let finDate = new Date(date);
        finDate.setDate(finDate.getDate() + 1);
        Logger.info('AppStart', 'insert data end: ' + finDate.toDateString())
        TaskInfoApi.query(Const.GLOBAL_KEY, false, async (globalTaskResult: TaskInfo[]) => {
          result = globalTaskResult;
          dayInfo.targetTaskNum = this.calTaskNum(result);
          this.insertPreInfo(curDate, finDate, result, dayInfo);
          let finResult: TaskInfo[] = [];
          for (let i = 0; i < Const.TASK_NUM; i++) {
            if (result[i].isOpen === true) {
              finResult.push(result[i]);
            }
          }
          callback(finResult, dayInfo);
        })
      } else {
        let dayInfoList: DayInfo = this.calFinishNum(taskResult, result);
        dayInfo.targetTaskNum = dayInfoList.targetTaskNum;
        dayInfo.finTaskNum = dayInfoList.finTaskNum;
        callback(result, dayInfo);
      }
    });
  }

  calTaskNum(result: TaskInfo[]) {
    let taskNum = 0;
    for (let i = 0; i < Const.TASK_NUM; i++) {
      if (result[i]?.isOpen) {
        taskNum += 1;
      }
    }
    return taskNum;
  }

  insertPreInfo(curDate: Date, finDate: Date, result: TaskInfo[], dayInfo: DayInfo) {
    while (curDate.toDateString() !== finDate.toDateString()) {
      dayInfo.date = curDate.toDateString();
      DayInfoApi.insertData(dayInfo, (isDone: number) => {
        if (isDone) {
          Logger.info('AppStart', 'insert dayInfo success: ' + JSON.stringify(dayInfo));
        }
      })
      for (let i = 0; i < Const.TASK_NUM; i++) {
        let tmp = TaskInfo.create(0, '');
        tmp = result[i];
        tmp.date = curDate.toDateString();
        TaskInfoApi.insertData(tmp, (isDone: number) => {
          if (isDone) {
            Logger.info('AppStart', 'insert taskInfo success: ' + JSON.stringify(tmp));
          }
        })
      }
      curDate.setDate(curDate.getDate() + 1);
    }
  }

  calFinishNum(taskResult: TaskInfo[], result: TaskInfo[]) {
    let taskNum = 0;
    let finishNum = 0;
    for (let i = 0; i < Const.TASK_NUM; i++) {
      if (taskResult[i].isOpen) {
        result.push(taskResult[i]);
        taskNum += 1;
        if (taskResult[i].isDone) {
          finishNum += 1;
        }
      }
    }
    return new DayInfo('', taskNum, finishNum);
  }
}

let DatabaseModelApi = new DatabaseModel();

export default DatabaseModelApi as DatabaseModel;
