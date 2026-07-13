import { oneWeekDictFunc } from '../common/utils/Utils';

export class SubTaskInfo {
  name: string = '';
  isDone: boolean = false;
}

export enum TaskTypeEnum {
  COUNT = 1,
  VALUE = 2,
  DURATION = 3,
  TIME_POINT = 4,
  TIME_PERIOD = 5,
  SUB_TASK = 6,
  AUTO_SYNC = 7,
  CYCLE = 8
}

export enum TaskStatus {
  NOT_STARTED = 0,
  IN_PROGRESS = 1,
  COMPLETED = 2,
  SKIPPED = 3,
  EXPIRED = 4,
  PAUSED = 5
}

export default class TaskInfo {
  id: number = 0;
  date: string = '';
  taskID: number = 0;
  taskName: string = '';
  taskType: number = 0;
  targetValue: string = '';
  finValue: string = '';
  unit: string = '';
  isAlarm: boolean = false;
  startTime: string = '';
  endTime: string = '';
  frequency: string = '';
  isDone: boolean = false;
  isOpen: boolean = false;
  status: number = 0;
  subTasks: string = '';
  cycleDays: string = '';
  cycleTarget: number = 0;
  dataSrc: string = '';
  inputHistory: string = '';

  constructor(
    id: number, date: string, taskID: number, taskName: string, taskType: number,
    targetValue: string, finValue: string, unit: string, isAlarm: boolean,
    startTime: string, endTime: string, frequency: string, isDone: boolean,
    isOpen: boolean, status: number, subTasks: string, cycleDays: string,
    cycleTarget: number, dataSrc: string
  ) {
    this.id = id;
    this.date = date;
    this.taskID = taskID;
    this.taskName = taskName;
    this.taskType = taskType;
    this.targetValue = targetValue;
    this.finValue = finValue;
    this.unit = unit;
    this.isAlarm = isAlarm;
    this.startTime = startTime;
    this.endTime = endTime;
    this.frequency = frequency;
    this.isDone = isDone;
    this.isOpen = isOpen;
    this.status = status;
    this.subTasks = subTasks;
    this.cycleDays = cycleDays;
    this.cycleTarget = cycleTarget;
    this.dataSrc = dataSrc;
  }

  static create(taskID: number, date: string): TaskInfo {
    return new TaskInfo(
      0, date, taskID, '', 0, '', '', '', false,
      '', '', '', false, false, TaskStatus.NOT_STARTED,
      '', '', 0, ''
    );
  }
}

export const oneWeek = oneWeekDictFunc();
