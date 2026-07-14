import AchievementMapInfo from '../viewmodel/AchievementMapInfo';

import TaskInfo, { TaskTypeEnum, TaskStatus } from '../viewmodel/TaskInfo';
import { CommonConstants as Const } from '../common/constants/CommonConstants';

export interface ITaskItem {
  date?: string;
  repeatEnabled?: boolean;
  planStartDate?: string;
  taskID: number;
  taskName: string;
  taskType: number;
  isOpen: boolean;
  unit: string;
  icon: Resource;
  dialogBg: Resource;
  targetValue: string;
  isAlarm: boolean;
  startTime: string;
  endTime: string;
  frequency: string;
  isInit: boolean;
  step: number;
  subTasks: string;
  cycleDays: string;
  cycleTarget: number;
  dataSrc: string;
  status: number;
}

export interface RemindContentItem {
  title: string;
  content: string;
}

export interface FrequencyContentType {
  id: number,
  label: string,
  isChecked: boolean
}

export const TaskList: TaskInfo[] = [
  new TaskInfo(0, '', 1, '每日刷牙', TaskTypeEnum.TIME_PERIOD, '2', '', '次', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '', '', 0, ''),
  new TaskInfo(1, '', 2, '每日微笑', TaskTypeEnum.COUNT, '1', '', '次', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '', '', 0, ''),
  new TaskInfo(2, '', 3, '每日喝水', TaskTypeEnum.VALUE, '1500', '', 'mL', true, '08:00', '', '', false, true, TaskStatus.NOT_STARTED, '', '', 0, ''),
  new TaskInfo(3, '', 4, '每日步数', TaskTypeEnum.AUTO_SYNC, '8000', '', '步', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '', '', 0, 'step_counter'),
  new TaskInfo(4, '', 5, '每日运动', TaskTypeEnum.DURATION, '30', '', '分钟', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '', '', 0, ''),
  new TaskInfo(5, '', 6, '早睡', TaskTypeEnum.TIME_POINT, '23:30', '', '', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '', '', 0, ''),
  new TaskInfo(6, '', 7, '保证睡眠', TaskTypeEnum.AUTO_SYNC, '8', '', '小时', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '', '', 0, 'sleep_tracker'),
  new TaskInfo(7, '', 8, '久坐提醒', TaskTypeEnum.TIME_PERIOD, '1', '', '次/60分钟', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '', '', 0, ''),
  new TaskInfo(8, '', 9, '每日拉伸', TaskTypeEnum.SUB_TASK, '3', '', '项', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '[{"name":"颈部","isDone":false},{"name":"腰背","isDone":false},{"name":"腿部","isDone":false}]', '', 0, ''),
  new TaskInfo(9, '', 10, '健康饮食', TaskTypeEnum.SUB_TASK, '4', '', '项', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '[{"name":"早餐","isDone":false},{"name":"蔬菜","isDone":false},{"name":"水果","isDone":false},{"name":"少糖","isDone":false}]', '', 0, ''),
  new TaskInfo(10, '', 11, '情绪记录', TaskTypeEnum.COUNT, '1', '', '次', true, '', '', '', false, true, TaskStatus.NOT_STARTED, '', '', 0, ''),
  new TaskInfo(11, '', 12, '定期测体重', TaskTypeEnum.CYCLE, '1', '', '次', false, '07:00', '', '1,3,5', false, false, TaskStatus.NOT_STARTED, '', '1,3,5', 2, ''),
  new TaskInfo(12, '', 13, '跑步1公里', TaskTypeEnum.VALUE, '1', '', '公里', false, '07:30', '22:00', '1,2,3,4,5,6,7', false, false, TaskStatus.NOT_STARTED, '', '', 0, '')
]

let achievementMap = new AchievementMapInfo();
export const AchievementMap = achievementMap;

export const TaskMapById: Array<ITaskItem> = [
  {
    taskID: 1,
    taskName: '每日刷牙',
    taskType: TaskTypeEnum.TIME_PERIOD,
    icon: $r("app.media.ic_task_brush"),
    dialogBg: $r('app.media.ic_dialog_brush_teeth'),
    targetValue: '2',
    isOpen: false,
    unit: '次',
    step: 1,
    isInit: true,
    isAlarm: false,
    startTime: '07:00',
    endTime: '22:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 2,
    taskName: '每日微笑',
    taskType: TaskTypeEnum.COUNT,
    icon: $r("app.media.ic_task_smile"),
    dialogBg: $r('app.media.ic_dialog_smile'),
    targetValue: '1',
    isOpen: false,
    unit: '次',
    step: 1,
    isInit: true,
    isAlarm: false,
    startTime: '08:00',
    endTime: '00:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 3,
    taskName: '每日喝水',
    taskType: TaskTypeEnum.VALUE,
    icon: $r("app.media.ic_task_water"),
    dialogBg: $r('app.media.ic_dialog_drink'),
    targetValue: '1500',
    isOpen: false,
    unit: 'mL',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '08:00',
    endTime: '22:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 4,
    taskName: '每日步数',
    taskType: TaskTypeEnum.AUTO_SYNC,
    icon: $r("app.media.ic_task_water"),
    dialogBg: $r('app.media.ic_dialog_drink'),
    targetValue: '8000',
    isOpen: false,
    unit: '步',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '00:00',
    endTime: '23:59',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: 'step_counter',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 5,
    taskName: '每日运动',
    taskType: TaskTypeEnum.DURATION,
    icon: $r("app.media.ic_task_morning"),
    dialogBg: $r('app.media.ic_dialog_getup'),
    targetValue: '30',
    isOpen: false,
    unit: '分钟',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '08:00',
    endTime: '22:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 6,
    taskName: '早睡',
    taskType: TaskTypeEnum.TIME_POINT,
    icon: $r("app.media.ic_task_night"),
    dialogBg: $r('app.media.ic_dialog_sleep'),
    targetValue: '23:30',
    isOpen: false,
    unit: '',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '20:00',
    endTime: '23:30',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 7,
    taskName: '保证睡眠',
    taskType: TaskTypeEnum.AUTO_SYNC,
    icon: $r("app.media.ic_task_night"),
    dialogBg: $r('app.media.ic_dialog_sleep'),
    targetValue: '8',
    isOpen: false,
    unit: '小时',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '22:00',
    endTime: '07:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: 'sleep_tracker',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 8,
    taskName: '久坐提醒',
    taskType: TaskTypeEnum.TIME_PERIOD,
    icon: $r("app.media.ic_task_morning"),
    dialogBg: $r('app.media.ic_dialog_getup'),
    targetValue: '1',
    isOpen: false,
    unit: '次/60分钟',
    step: 1,
    isInit: true,
    isAlarm: false,
    startTime: '08:00',
    endTime: '22:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 9,
    taskName: '每日拉伸',
    taskType: TaskTypeEnum.SUB_TASK,
    icon: $r("app.media.ic_task_smile"),
    dialogBg: $r('app.media.ic_dialog_smile'),
    targetValue: '3',
    isOpen: false,
    unit: '项',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '08:00',
    endTime: '22:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '[{"name":"颈部","isDone":false},{"name":"腰背","isDone":false},{"name":"腿部","isDone":false}]',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 10,
    taskName: '健康饮食',
    taskType: TaskTypeEnum.SUB_TASK,
    icon: $r("app.media.ic_task_apple"),
    dialogBg: $r('app.media.ic_dialog_eat_apples'),
    targetValue: '4',
    isOpen: false,
    unit: '项',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '07:00',
    endTime: '22:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '[{"name":"早餐","isDone":false},{"name":"蔬菜","isDone":false},{"name":"水果","isDone":false},{"name":"少糖","isDone":false}]',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 11,
    taskName: '情绪记录',
    taskType: TaskTypeEnum.COUNT,
    icon: $r("app.media.ic_task_smile"),
    dialogBg: $r('app.media.ic_dialog_smile'),
    targetValue: '1',
    isOpen: false,
    unit: '次',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '20:00',
    endTime: '22:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 12,
    taskName: '定期测体重',
    taskType: TaskTypeEnum.CYCLE,
    icon: $r("app.media.ic_task_water"),
    dialogBg: $r('app.media.ic_dialog_drink'),
    targetValue: '1',
    isOpen: false,
    unit: '次',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '07:00',
    endTime: '22:00',
    frequency: '1, 3, 5',
    subTasks: '',
    cycleDays: '1,3,5',
    cycleTarget: 2,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  },
  {
    taskID: 13,
    taskName: '跑步1公里',
    taskType: TaskTypeEnum.VALUE,
    icon: $r("app.media.ic_task_morning"),
    dialogBg: $r('app.media.ic_dialog_getup'),
    targetValue: '1',
    isOpen: false,
    unit: '公里',
    step: 0,
    isInit: true,
    isAlarm: false,
    startTime: '07:30',
    endTime: '22:00',
    frequency: '1, 2, 3, 4, 5, 6, 7',
    subTasks: '',
    cycleDays: '',
    cycleTarget: 0,
    dataSrc: '',
    status: TaskStatus.NOT_STARTED
  }
]

export const TaskItem = new TaskInfo(1, '', 0, '', 0, '7:00', '', '', false, '', '', '', false, false, 0, '', '', 0, '');

export const RemindContentMap: Array<RemindContentItem> = [
  {
    title: Const.BRUSH_TEETH_TASK_NAME_NEW,
    content: Const.BRUSH_TEETH_CONTENT_NEW
  },
  {
    title: Const.SMILE_TASK_NAME,
    content: Const.SMILE_CONTENT
  },
  {
    title: Const.DRINK_TASK_NAME,
    content: Const.DRINK_CONTENT
  },
  {
    title: Const.STEP_TASK_NAME,
    content: Const.STEP_CONTENT
  },
  {
    title: Const.EXERCISE_TASK_NAME,
    content: Const.EXERCISE_CONTENT
  },
  {
    title: Const.SLEEP_EARLY_TASK_NAME,
    content: Const.SLEEP_EARLY_CONTENT
  },
  {
    title: Const.SLEEP_ENSURE_TASK_NAME,
    content: Const.SLEEP_ENSURE_CONTENT
  },
  {
    title: Const.SIT_REMIND_TASK_NAME,
    content: Const.SIT_REMIND_CONTENT
  },
  {
    title: Const.STRETCH_TASK_NAME,
    content: Const.STRETCH_CONTENT
  },
  {
    title: Const.DIET_TASK_NAME,
    content: Const.DIET_CONTENT
  },
  {
    title: Const.MOOD_TASK_NAME,
    content: Const.MOOD_CONTENT
  },
  {
    title: Const.WEIGHT_TASK_NAME,
    content: Const.WEIGHT_CONTENT
  },
  {
    title: Const.RUN_TASK_NAME,
    content: Const.RUN_CONTENT
  }
];

export const ACHIEVEMENT_LEVEL_LIST = [1, 3, 7, 30, 50, 73, 99];
