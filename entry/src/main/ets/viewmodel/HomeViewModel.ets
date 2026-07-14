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
import { ACHIEVEMENT_LEVEL_KEY } from '../model/AchieveModel';
import { TaskMapById, ITaskItem, ACHIEVEMENT_LEVEL_LIST } from '../model/TaskInitList';
import TaskInfo, { TaskStatus, TaskTypeEnum, SubTaskInfo } from './TaskInfo';
import DayInfo from './DayInfo';
import { dateToStr, weekDateFormat } from '../common/utils/Utils';
import { WeekDateModel, initializeOnStartUp, getPreviousWeek, WEEK_DAY_NUM } from '../model/WeekCalendarModel';
import DatabaseApi from '../model/DatabaseModel';
import TaskInfoTableApi from '../common/database/tables/TaskInfoApi';
import DayInfoApi from '../common/database/tables/DayInfoApi';
import GlobalInfoApi from '../common/database/tables/GlobalInfoApi';
import Logger from '../common/utils/Logger';
import GlobalInfo from './GlobalInfo';
import WeekCalendarInfo from './WeekCalendarInfo';
import AchievementInfo from './AchievementInfo';

@Observed
export class HomeStore {
  public currentDate: Date;
  public dateArr: Array<WeekDateModel> = []; // data source list
  public selectedDay: number; // selected day of on week
  public showDate: number;
  public dateTitle: string;
  public selectedDayInfo: WeekDateModel = new WeekDateModel('', '', new Date()); // task info on selected day

  constructor(currentDate: Date) {
    this.currentDate = currentDate;
    this.showDate = currentDate.getTime();
    this.dateTitle = weekDateFormat(currentDate.getTime());
    this.selectedDay = (new Date().getDay() + WEEK_DAY_NUM - 1) % WEEK_DAY_NUM;
  }

  public initData() {
    let weekCalendarInfo: WeekCalendarInfo = initializeOnStartUp(this.currentDate);
    this.dateArr = weekCalendarInfo.arr;
    // Establish a valid selected date before asynchronous database queries
    // finish, so actions rendered on the first frame can reliably identify
    // today instead of seeing the empty WeekDateModel placeholder.
    const todayInfo = this.dateArr.find((item: WeekDateModel) => {
      return item.dateStr === dateToStr(this.currentDate);
    });
    if (todayInfo) {
      this.selectedDayInfo = todayInfo;
    }
    Logger.info('this.currentDate', this.currentDate.toDateString());
    Logger.info('initWeekData dateArr', JSON.stringify(weekCalendarInfo.strArr))
    // get data form db
    DatabaseApi.query(dateToStr(new Date()), (taskList: TaskInfo[], dayInfo: DayInfo) => {
      Logger.info('Current Day Task Info: ', JSON.stringify(taskList));
      DayInfoApi.queryList(weekCalendarInfo.strArr, (res: DayInfo[]) => {
        let tempList = res.concat(dayInfo);
        Logger.info('initDayInfoList: ', JSON.stringify(res));
        for (let i = 0; i < this.dateArr.length; i++) {
          let tempDayInfo = tempList.find((item: DayInfo) => item.date === this.dateArr[i].dateStr) || new DayInfo(this.dateArr[i].dateStr, 0, 0);
          weekCalendarInfo.arr[i].dayInfo = tempDayInfo;
          if (this.dateArr[i].dateStr === dateToStr(new Date(this.showDate))) {
            // get tasks of showDate
            weekCalendarInfo.arr[i].taskList = taskList;
          }
        }
        this.dateArr = weekCalendarInfo.arr;
        setTimeout(() => {
          this.setSelectedShowDate(this.showDate);
        }, 0)
        this.reconcileHistoricalAchievements();
      })
    })
  }

  public getPreWeekData(date: Date, callback: Function) {
    let weekCalendarInfo: WeekCalendarInfo = getPreviousWeek(date);
    // get data form db
    DayInfoApi.queryList(weekCalendarInfo.strArr, (res: DayInfo[]) => {
      Logger.info('getPreWeekData->DayInfoList: ', JSON.stringify(res));
      if (res.length > 0) {
        for (let i = 0; i < weekCalendarInfo.arr.length; i++) {
          let dayInfo = res.find((item) => item.date === weekCalendarInfo.arr[i].dateStr);
          if (dayInfo) {
            weekCalendarInfo.arr[i].dayInfo = dayInfo;
          }
        }
      }
      this.dateArr = weekCalendarInfo.arr.concat(...this.dateArr);
      callback();
    })
  }

  // check is current day
  public checkCurrentDay(): boolean {
    return dateToStr(new Date()) === this.selectedDayInfo?.dateStr;
  }

  public getFinishedTaskCount(taskList: TaskInfo[]): number {
    return taskList.filter((taskItem: TaskInfo) => taskItem.isDone).length;
  }

  public isTaskListComplete(taskList: TaskInfo[]): boolean {
    return taskList.length > 0 && this.getFinishedTaskCount(taskList) === taskList.length;
  }

  public isDayInfoComplete(dayInfo: DayInfo): boolean {
    return dayInfo.targetTaskNum > 0 && dayInfo.finTaskNum >= dayInfo.targetTaskNum;
  }

  public updateSelectedDayInfo(selectedDayInfo: WeekDateModel) {
    Logger.debug('updateSelectedDayInfo', JSON.stringify(selectedDayInfo));
    // Switch the selected model immediately. Waiting for the database query here
    // leaves the previous day's tasks on screen and makes the calendar appear to
    // react only after the next navigation action.
    const selectedDateStr = selectedDayInfo.dateStr;
    this.selectedDayInfo = selectedDayInfo;
    if (selectedDayInfo.taskList?.length === 0) {
      // Materialize a recurring plan lazily before querying the selected day.
      // This keeps future dates (and dates outside the initial 366-day
      // materialization window) consistent with the global plan.
      DatabaseApi.ensureTasksForDate(selectedDateStr).then(() => {
        TaskInfoTableApi.query(selectedDateStr, true, (res: TaskInfo[]) => {
          Logger.info('Selected TaskInfoList: ', JSON.stringify(res));
          selectedDayInfo.taskList = res;
          const dayInfo = selectedDayInfo.dayInfo || new DayInfo(selectedDateStr, 0, 0);
          dayInfo.date = selectedDateStr;
          dayInfo.targetTaskNum = res.length;
          dayInfo.finTaskNum = this.getFinishedTaskCount(res);
          selectedDayInfo.dayInfo = dayInfo;
          this.persistDayInfo(dayInfo).catch((error: Error) => {
            Logger.error('Selected DayInfo update', JSON.stringify(error));
          });
          this.dateArr = this.dateArr.map((item: WeekDateModel) => {
            if (item.dateStr === selectedDateStr) {
              let taskListStr = JSON.stringify(res);
              item.taskList = JSON.parse(taskListStr);
              item.dayInfo = JSON.parse(JSON.stringify(dayInfo));
              return item;
            } else {
              return item;
            }
          }).slice();
          // A query for an older click may finish after the user has selected a
          // different date. Only refresh the visible selection when it is still
          // the date represented by this result.
          if (dateToStr(new Date(this.showDate)) === selectedDateStr) {
            const currentInfo = this.dateArr.find((item: WeekDateModel) => item.dateStr === selectedDateStr);
            this.selectedDayInfo = currentInfo || selectedDayInfo;
          }
        });
      }).catch((error: Error) => {
        Logger.error('Selected TaskInfoList ensure', JSON.stringify(error));
        TaskInfoTableApi.query(selectedDateStr, true, (res: TaskInfo[]) => {
          selectedDayInfo.taskList = res;
          const dayInfo = selectedDayInfo.dayInfo || new DayInfo(selectedDateStr, 0, 0);
          dayInfo.date = selectedDateStr;
          dayInfo.targetTaskNum = res.length;
          dayInfo.finTaskNum = this.getFinishedTaskCount(res);
          selectedDayInfo.dayInfo = dayInfo;
          this.persistDayInfo(dayInfo).catch(() => {});
        });
      });
    }
    Logger.info("selectedDayTaskInfo: ", JSON.stringify(selectedDayInfo.taskList));
  }

  public updateTaskInfoList(editedTaskInfo: ITaskItem) {
    if (editedTaskInfo?.taskID) {
      // edited task
      let taskID = editedTaskInfo.taskID;
      let targetValue = editedTaskInfo.targetValue;
      let isAlarm = editedTaskInfo.isAlarm;
      let frequency = editedTaskInfo.frequency;
      let startTime = editedTaskInfo.startTime;
      let endTime = editedTaskInfo.endTime;
      let isOpen = editedTaskInfo.isOpen;
      const taskDate = editedTaskInfo.date || dateToStr(new Date(this.showDate));
      let task = TaskInfo.create(taskID, taskDate);
      task.targetValue = targetValue;
      task.isAlarm = isAlarm;
      task.startTime = startTime;
      task.endTime = endTime;
      task.frequency = frequency;
      task.isDone = false;
      task.finValue = '';
      task.isOpen = isOpen;
      task.taskName = editedTaskInfo.taskName;
      task.taskType = editedTaskInfo.taskType;
      task.unit = editedTaskInfo.unit;
      task.status = TaskStatus.NOT_STARTED;
      task.subTasks = editedTaskInfo.subTasks;
      task.cycleDays = editedTaskInfo.cycleDays;
      task.cycleTarget = editedTaskInfo.cycleTarget;
      task.dataSrc = editedTaskInfo.dataSrc;
      task.inputHistory = '';
      task.planStartDate = editedTaskInfo.planStartDate || taskDate;
      task.isRecurring = editedTaskInfo.repeatEnabled === true;
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const selectedTaskDate = new Date(taskDate);
      selectedTaskDate.setHours(0, 0, 0, 0);
      const isHistoricalTask = selectedTaskDate.getTime() < today.getTime();
      this.dateArr = this.dateArr.map((item: WeekDateModel) => {
        if (task.date === item.dateStr) {
          Logger.info('item', JSON.stringify(item));
          let taskList: TaskInfo[] = item.taskList;
          const dayInfo: DayInfo = item.dayInfo;
          const wasDayComplete = this.isTaskListComplete(taskList);
          dayInfo.date = item.dateStr;
          if (editedTaskInfo.isOpen) {
            // add task
            const currentTask = taskList.find((taskItem: TaskInfo) => taskItem.taskID === taskID);
            if (currentTask) {
              task.isDone = currentTask.isDone;
              task.finValue = currentTask.finValue;
              task.status = currentTask.status;
              task.subTasks = currentTask.subTasks;
              task.inputHistory = currentTask.inputHistory;
            } else if (!isHistoricalTask) {
              // The first activation is recorded as completed for the
              // selected date, matching the persisted addTask record.
              task.isDone = true;
              task.finValue = task.targetValue;
              task.status = TaskStatus.COMPLETED;
              if (task.taskType === TaskTypeEnum.SUB_TASK && task.subTasks) {
                try {
                  const subTasks = JSON.parse(task.subTasks) as Array<SubTaskInfo>;
                  subTasks.forEach((subTask) => subTask.isDone = true);
                  task.subTasks = JSON.stringify(subTasks);
                } catch (error) {
                  Logger.warn('updateTaskInfoList', `invalid subTasks: ${JSON.stringify(error)}`);
                }
              }
            }
            taskList = taskList.filter((taskItem) => taskItem.taskID != taskID)
              .concat(task)
              .sort((a, b) => a.taskID - b.taskID);
          } else {
            // delete task
            let taskIndex = taskList.findIndex((taskItem) => taskItem.taskID === taskID);
            Logger.info('taskList[taskIndex]', JSON.stringify(taskList[taskIndex]));
            taskList = taskList.filter((taskItem) => taskItem.taskID != taskID);
          }
          dayInfo.targetTaskNum = taskList.length;
          dayInfo.finTaskNum = this.getFinishedTaskCount(taskList);
          const isDayComplete = this.isTaskListComplete(taskList);
          this.persistDayInfo(dayInfo).then(() => {
            if (wasDayComplete !== isDayComplete) {
              this.updateAchievement().catch((error: Error) => {
                Logger.error('updateTaskInfoList-achievement', JSON.stringify(error));
              });
            }
          }).catch((error: Error) => {
            Logger.error('updateTaskInfoList-dayInfo', JSON.stringify(error));
          });
          Logger.debug("tempDayInfo", JSON.stringify(dayInfo));
          let weekDateModelStr = JSON.stringify(item);
          let currentDayInfo: WeekDateModel = JSON.parse(weekDateModelStr);
          currentDayInfo.date = item.date;
          currentDayInfo.taskList = taskList;
          currentDayInfo.dayInfo = dayInfo;
          if (dateToStr(new Date(this.showDate)) === task.date) {
            this.selectedDayInfo = currentDayInfo;
          }
          return currentDayInfo;
        }
        return item;
      }).slice(0);
    }
  }

  public setSelectedShowDate(showDateTime: number) {
    const selectedDate = new Date(showDateTime);
    this.selectedDay = (selectedDate.getDay() + WEEK_DAY_NUM - 1) % WEEK_DAY_NUM;
    this.showDate = showDateTime;
    this.dateTitle = weekDateFormat(this.showDate);
    let selectedInfo = this.dateArr.find((item: WeekDateModel) => item.dateStr === dateToStr(selectedDate));
    if (selectedInfo) {
      this.updateSelectedDayInfo(selectedInfo);
    }
    Logger.info('dateTitle', this.dateTitle);
  }

  public getDonePercent(): string {
    let taskList = this.getTaskListOfDay();
    if (taskList.length === 0) {
      return '0';
    }
    let totalPercent = 0;
    taskList.forEach((task: TaskInfo) => {
      totalPercent += this.getTaskPercent(task);
    });
    let avg = Math.ceil(totalPercent / taskList.length);
    if (avg >= 100) {
      return `${Const.DEFAULT_100}`;
    }
    return `${avg}`;
  }

  public getTaskPercent(task: TaskInfo): number {
    if (task.isDone) {
      return 100;
    }
    let target = Number(task.targetValue);
    let current = Number(task.finValue);
    if (!target || target <= 0) {
      return 0;
    }
    if (!current || current <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(current / target * 100));
  }

  public getTaskListOfDay(): TaskInfo[] {
    Logger.info('getTaskListOfDay', JSON.stringify(this.selectedDayInfo));
    if (this.selectedDayInfo && this.selectedDayInfo.taskList.length > 0) {
      return this.selectedDayInfo.taskList;
    }
    return [];
  }

  public async taskClock(taskInfo: TaskInfo, action: string = 'clock', inputVal: string = '') {
    const taskDateStr = taskInfo.date || this.selectedDayInfo.dateStr;
    const targetDayInfo: WeekDateModel = this.dateArr.find((item: WeekDateModel) => {
      return item.dateStr === taskDateStr;
    }) || this.selectedDayInfo;
    const wasDayComplete = this.isTaskListComplete(targetDayInfo.taskList);
    let taskItem = await this.updateTask(taskInfo, action, inputVal);
    if (!taskItem) {
      return {
        achievementLevel: 0,
        showAchievement: false
      } as AchievementInfo;
    }

    targetDayInfo.taskList = targetDayInfo.taskList.map((item) => {
      return item.taskID === taskItem?.taskID ? taskItem : item;
    });
    let achievementLevel: number = 0;
    await this.updateDayInfo(targetDayInfo);
    const isDayComplete = this.isTaskListComplete(targetDayInfo.taskList);
    if (wasDayComplete !== isDayComplete) {
      achievementLevel = await this.updateAchievement();
    }
    this.dateArr = this.dateArr.map((item: WeekDateModel) => {
      return taskDateStr === item.dateStr ? targetDayInfo : item;
    }).slice();
    if (this.selectedDayInfo.dateStr === taskDateStr) {
      this.selectedDayInfo = targetDayInfo;
    }
    return {
      achievementLevel: achievementLevel,
      showAchievement: ACHIEVEMENT_LEVEL_LIST.includes(achievementLevel)
    } as AchievementInfo;
  }

  updateTask(task: TaskInfo, action: string = 'clock', inputVal: string = ''): Promise<TaskInfo> {
    return new Promise((resolve, reject) => {
      let taskID = task.taskID;
      let targetValue = task.targetValue;
      let finValue = task.finValue;
      let inputHistory = task.inputHistory || '';
      let updateTask = TaskInfo.create(taskID, task.date);
      updateTask.id = task.id;
      updateTask.targetValue = targetValue;
      updateTask.isAlarm = task.isAlarm;
      updateTask.startTime = task.startTime;
      updateTask.endTime = task.endTime;
      updateTask.frequency = task.frequency;
      updateTask.isOpen = task.isOpen;
      updateTask.taskName = task.taskName;
      updateTask.taskType = task.taskType;
      updateTask.unit = task.unit;
      updateTask.subTasks = task.subTasks;
      updateTask.cycleDays = task.cycleDays;
      updateTask.cycleTarget = task.cycleTarget;
      updateTask.dataSrc = task.dataSrc;
      updateTask.inputHistory = inputHistory;
      updateTask.planStartDate = task.planStartDate;
      updateTask.isRecurring = task.isRecurring;

      let taskType = task.taskType;

      if (action === 'undo') {
        if (taskType === TaskTypeEnum.COUNT || taskType === TaskTypeEnum.TIME_PERIOD || taskType === TaskTypeEnum.CYCLE) {
          let currentVal = Number(finValue) || 0;
          let newVal = currentVal - 1;
          if (newVal <= 0) {
            updateTask.isDone = false;
            updateTask.finValue = '';
            updateTask.status = TaskStatus.NOT_STARTED;
          } else {
            updateTask.isDone = false;
            updateTask.finValue = `${newVal}`;
            updateTask.status = TaskStatus.IN_PROGRESS;
          }
        } else if (taskType === TaskTypeEnum.VALUE || taskType === TaskTypeEnum.DURATION || taskType === TaskTypeEnum.AUTO_SYNC) {
          let entries = inputHistory.split(',').filter((s: string) => s.length > 0);
          if (entries.length > 0) {
            let lastEntry = entries.pop();
            let lastVal = Number(lastEntry) || 0;
            let currentTotal = Number(finValue) || 0;
            let newTotal = currentTotal - lastVal;
            if (newTotal <= 0) {
              updateTask.isDone = false;
              updateTask.finValue = '';
              updateTask.status = TaskStatus.NOT_STARTED;
              updateTask.inputHistory = '';
            } else {
              updateTask.isDone = newTotal >= Number(targetValue);
              updateTask.finValue = `${newTotal}`;
              updateTask.status = updateTask.isDone ? TaskStatus.COMPLETED : TaskStatus.IN_PROGRESS;
              updateTask.inputHistory = entries.join(',');
            }
          } else {
            updateTask.isDone = false;
            updateTask.finValue = '';
            updateTask.status = TaskStatus.NOT_STARTED;
            updateTask.inputHistory = '';
          }
        } else if (taskType === TaskTypeEnum.TIME_POINT) {
          updateTask.isDone = false;
          updateTask.finValue = '';
          updateTask.status = TaskStatus.NOT_STARTED;
        } else if (taskType === TaskTypeEnum.SUB_TASK) {
          updateTask.isDone = false;
          updateTask.finValue = '';
          updateTask.status = TaskStatus.NOT_STARTED;
          updateTask.subTasks = task.subTasks;
        } else {
          updateTask.isDone = false;
          updateTask.finValue = '';
          updateTask.status = TaskStatus.NOT_STARTED;
        }
      } else {
        if (taskType === TaskTypeEnum.COUNT || taskType === TaskTypeEnum.TIME_PERIOD || taskType === TaskTypeEnum.CYCLE) {
          let currentVal = Number(finValue) || 0;
          let newVal = currentVal + 1;
          updateTask.isDone = newVal >= Number(targetValue);
          updateTask.finValue = updateTask.isDone ? targetValue : `${newVal}`;
          updateTask.status = updateTask.isDone ? TaskStatus.COMPLETED : TaskStatus.IN_PROGRESS;
        } else if (taskType === TaskTypeEnum.VALUE || taskType === TaskTypeEnum.DURATION || taskType === TaskTypeEnum.AUTO_SYNC) {
          let addVal = Number(inputVal) || 0;
          if (addVal <= 0) {
            resolve(task);
            return;
          }
          let currentTotal = Number(finValue) || 0;
          let newTotal = currentTotal + addVal;
          let entries = inputHistory.split(',').filter((s: string) => s.length > 0);
          entries.push(`${addVal}`);
          updateTask.inputHistory = entries.join(',');
          updateTask.isDone = newTotal >= Number(targetValue);
          updateTask.finValue = `${newTotal}`;
          updateTask.status = updateTask.isDone ? TaskStatus.COMPLETED : TaskStatus.IN_PROGRESS;
        } else if (taskType === TaskTypeEnum.TIME_POINT) {
          let timeVal = inputVal || finValue;
          updateTask.finValue = timeVal;
          let targetTime = targetValue;
          if (this.isTimeOnOrBefore(timeVal, targetTime)) {
            updateTask.isDone = true;
            updateTask.status = TaskStatus.COMPLETED;
          } else {
            updateTask.isDone = false;
            updateTask.status = TaskStatus.IN_PROGRESS;
          }
        } else if (taskType === TaskTypeEnum.SUB_TASK) {
          updateTask.subTasks = task.subTasks;
          updateTask.finValue = task.finValue;
          updateTask.isDone = task.isDone;
          updateTask.status = task.isDone ? TaskStatus.COMPLETED : (Number(task.finValue) > 0 ? TaskStatus.IN_PROGRESS : TaskStatus.NOT_STARTED);
        } else {
          let currentVal = Number(finValue) || 0;
          let newVal = currentVal + 1;
          updateTask.isDone = newVal >= Number(targetValue);
          updateTask.finValue = `${newVal}`;
          updateTask.status = updateTask.isDone ? TaskStatus.COMPLETED : TaskStatus.IN_PROGRESS;
        }
      }

      TaskInfoTableApi.updateDataByDate(updateTask, (res: number) => {
        if (!res) {
          Logger.error('taskClock-updateTask', JSON.stringify(res));
          reject(res);
          return;
        }
        resolve(updateTask);
      })
    })
  }

  isTimeOnOrBefore(timeStr: string, targetStr: string): boolean {
    let timeParts = timeStr.split(':');
    let targetParts = targetStr.split(':');
    if (timeParts.length < 2 || targetParts.length < 2) {
      return false;
    }
    let timeMin = Number(timeParts[0]) * 60 + Number(timeParts[1]);
    let targetMin = Number(targetParts[0]) * 60 + Number(targetParts[1]);
    return timeMin <= targetMin;
  }

  persistDayInfo(dayInfo: DayInfo): Promise<DayInfo> {
    return new Promise((resolve, reject) => {
      DayInfoApi.updateData(dayInfo, (updateFlag: number) => {
        if (updateFlag) {
          resolve(dayInfo);
          return;
        }
        DayInfoApi.insertData(dayInfo, (insertFlag: number) => {
          if (!insertFlag) {
            reject(new Error(`save DayInfo failed: ${dayInfo.date}`));
            return;
          }
          resolve(dayInfo);
        });
      });
    });
  }

  updateDayInfo(dayModel: WeekDateModel = this.selectedDayInfo): Promise<DayInfo> {
    let dayInfo: DayInfo = dayModel.dayInfo;
    dayInfo.date = dayModel.dateStr;
    dayInfo.finTaskNum = this.getFinishedTaskCount(dayModel.taskList);
    dayInfo.targetTaskNum = dayModel.taskList.length;
    let dayInfoStr = JSON.stringify(dayInfo);
    dayModel.dayInfo = JSON.parse(dayInfoStr);
    return this.persistDayInfo(dayInfo).then((savedDayInfo: DayInfo) => {
      Logger.info('taskClock-updateDayInfo', JSON.stringify(savedDayInfo));
      return savedDayInfo;
    });
  }

  queryAllDayInfo(): Promise<DayInfo[]> {
    return new Promise((resolve) => {
      DayInfoApi.queryAll((dayInfoList: DayInfo[]) => {
        resolve(dayInfoList);
      });
    });
  }

  calculateLongestConsecutiveCheckInDays(dayInfoList: DayInfo[]): number {
    let today = new Date();
    today.setHours(0, 0, 0, 0);
    let completedDates: Date[] = [];
    dayInfoList.forEach((dayInfo: DayInfo) => {
      if (!this.isDayInfoComplete(dayInfo)) {
        return;
      }
      let completedDate = new Date(dayInfo.date);
      if (Number.isNaN(completedDate.getTime())) {
        return;
      }
      completedDate.setHours(0, 0, 0, 0);
      if (completedDate.getTime() <= today.getTime()) {
        completedDates.push(completedDate);
      }
    });
    completedDates.sort((left: Date, right: Date) => left.getTime() - right.getTime());

    const maxTrackedDays = ACHIEVEMENT_LEVEL_LIST[ACHIEVEMENT_LEVEL_LIST.length - 1];
    let longestDays = 0;
    let successiveDays = 0;
    let previousDate = new Date(0);
    let hasPreviousDate = false;
    completedDates.forEach((completedDate: Date) => {
      if (hasPreviousDate) {
        let expectedDate = new Date(previousDate);
        expectedDate.setDate(expectedDate.getDate() + 1);
        successiveDays = dateToStr(expectedDate) === dateToStr(completedDate) ? successiveDays + 1 : 1;
      } else {
        successiveDays = 1;
        hasPreviousDate = true;
      }
      previousDate = completedDate;
      longestDays = Math.max(longestDays, successiveDays);
    });
    return Math.min(longestDays, maxTrackedDays);
  }

  reconcileHistoricalAchievements() {
    this.queryAllDayInfo().then((dayInfoList: DayInfo[]) => {
      if (dayInfoList.some((dayInfo: DayInfo) => this.isDayInfoComplete(dayInfo))) {
        this.updateAchievement().catch((error: Error) => {
          Logger.error('reconcileHistoricalAchievements', JSON.stringify(error));
        });
      }
    }).catch((error: Error) => {
      Logger.error('reconcileHistoricalAchievements-query', JSON.stringify(error));
    });
  }

  updateAchievement(): Promise<number> {
    return new Promise((resolve, reject) => {
      GlobalInfoApi.query((achievementInfo: GlobalInfo) => {
        this.queryAllDayInfo().then((dayInfoList: DayInfo[]) => {
          const successiveDays = this.calculateLongestConsecutiveCheckInDays(dayInfoList);
          achievementInfo.checkInDays = successiveDays;
          let unlockedLevels = (achievementInfo.achievements || '').split(',')
            .filter((level: string) => level.length > 0);
          let newAchievementLevel = 0;
          ACHIEVEMENT_LEVEL_LIST.forEach((level: number) => {
            const levelStr = String(level);
            if (level <= successiveDays && unlockedLevels.indexOf(levelStr) < 0) {
              unlockedLevels.push(levelStr);
              newAchievementLevel = level;
            }
          });
          achievementInfo.achievements = unlockedLevels.join(',');
          let highestUnlockedLevel = 0;
          unlockedLevels.forEach((level: string) => {
            highestUnlockedLevel = Math.max(highestUnlockedLevel, Number(level));
          });
          AppStorage.SetOrCreate(ACHIEVEMENT_LEVEL_KEY, highestUnlockedLevel);
          GlobalInfoApi.updateData(achievementInfo, (updateFlag: number) => {
            if (!updateFlag) {
              Logger.error('taskClock-updateAchievement', JSON.stringify(updateFlag));
              reject(updateFlag);
              return;
            }
            Logger.debug('taskClock-updateAchievement', JSON.stringify(achievementInfo));
            resolve(newAchievementLevel);
          });
        }).catch((error: Error) => {
          reject(error);
        });
      });
    });
  }
}
