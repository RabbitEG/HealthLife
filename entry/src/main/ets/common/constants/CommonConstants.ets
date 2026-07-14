import CommonConstantsInfo from '../../viewmodel/CommonConstantsInfo';

export class CommonConstants {
  // The schema is incompatible with the six-task demo database; use a new
  // database file so upgrades do not try to read missing HealthLife columns.
  static readonly RDB_NAME = { dbName: 'healthLife_v3.db' } as CommonConstantsInfo;

  static readonly DAY_INFO = {
    tableName: 'dayInfo',
    columns: ['date', 'targetTaskNum', 'finTaskNum']
  } as CommonConstantsInfo

  static readonly GLOBAL_INFO = {
    tableName: 'globalInfo',
    columns: ['id', 'firstDate', 'lastDate', 'checkInDays', 'achievements']
  } as CommonConstantsInfo

  static readonly TASK_INFO = {
    tableName: 'taskInfo',
    columns: [
      'id',
      'date',
      'taskID',
      'taskName',
      'taskType',
      'targetValue',
      'finValue',
      'unit',
      'isAlarm',
      'startTime',
      'endTime',
      'frequency',
      'isDone',
      'isOpen',
      'status',
      'subTasks',
      'cycleDays',
      'cycleTarget',
      'dataSrc',
      'inputHistory',
      'planStartDate',
      'isRecurring'
    ]
  } as CommonConstantsInfo

  static readonly FORM_INFO = {
    tableName: 'formInfo',
    columns: ['id', 'formId', 'formName', 'formDimension']
  } as CommonConstantsInfo

  static readonly TASK_NUM = 13;

  static readonly THOUSANDTH_15: string = '1.5%';
  static readonly THOUSANDTH_12: string = '2.2%';
  static readonly THOUSANDTH_33: string = '3.3%';
  static readonly THOUSANDTH_50: string = '5%';
  static readonly THOUSANDTH_66: string = '6.6%';
  static readonly THOUSANDTH_80: string = '8%';
  static readonly THOUSANDTH_100: string = '10%';
  static readonly THOUSANDTH_120: string = '12%';
  static readonly THOUSANDTH_160: string = '16%';
  static readonly THOUSANDTH_400: string = '40%';
  static readonly THOUSANDTH_420: string = '42%';
  static readonly THOUSANDTH_500: string = '50%';
  static readonly THOUSANDTH_560: string = '56%';
  static readonly THOUSANDTH_800: string = '80%';
  static readonly THOUSANDTH_830: string = '83%';
  static readonly THOUSANDTH_880: string = '88%';
  static readonly THOUSANDTH_900: string = '90%';
  static readonly THOUSANDTH_940: string = '94%';
  static readonly THOUSANDTH_1000: string = '100%';

  static readonly DEFAULT_2: number = 2;

  static readonly DEFAULT_6: number = 6;

  static readonly DEFAULT_8: number = 8;

  static readonly DEFAULT_12: number = 12;

  static readonly DEFAULT_14: number = 14;

  static readonly DEFAULT_10: number = 10;

  static readonly DEFAULT_16: number = 16;

  static readonly DEFAULT_18: number = 18;

  static readonly DEFAULT_20: number = 20;

  static readonly DEFAULT_24: number = 24;

  static readonly DEFAULT_28: number = 28;

  static readonly DEFAULT_32: number = 32;

  static readonly DEFAULT_48: number = 48;

  static readonly DEFAULT_56: number = 56;

  static readonly DEFAULT_60: number = 60;

  static readonly DEFAULT_100: number = 100;

  static readonly DEFAULT_180: number = 180;

  static readonly FONT_WEIGHT_400: number = 400;

  static readonly FONT_WEIGHT_500: number = 500;

  static readonly FONT_WEIGHT_700: number = 700;

  static readonly FONT_WEIGHT_900: number = 900;


  static readonly OPACITY_4: number = 0.4;

  static readonly OPACITY_6: number = 0.6;

  static readonly BORDER_RADIUS_PERCENT_50: string = '50%';

  static readonly AD_DURATION: number = 5;
  static readonly LAUNCHER_DELAY_TIME: number = 2000;
  static readonly DURATION_1000: number = 1000;
  static readonly DURATION_800: number = 800;
  static readonly DURATION_100: number = 100;


  static readonly LIST_ITEM_SPACE: number = 2;

  static readonly SPACE_4: number = 4;

  static readonly ADD_TASK_TITLE: string = '添加任务';

  static readonly EDIT_TASK_TITLE: string = '编辑任务';

  static readonly SETTING_FINISHED_MESSAGE = '设置完成！！！';

  static readonly SETTING_FINISH_FAILED_MESSAGE = '网络连接错误';

  static readonly CHOOSE_TIME_OUT_RANGE: string = '选择时间超出范围';

  static readonly NICK_NAME = '健康生活家';

  static readonly SIGNATURE = '把健康变成日常';

  static readonly HOME_BTN_Z = 2;

  static readonly DEFAULT_TIME: string = '08:00';

  static readonly GET_UP_TIME_RANGE: string = '(06:00 - 09:00)';

  static readonly SLEEP_TIME_RANGE: string = '(20:00 - 23:00)';

  static readonly GET_UP_EARLY_TIME: string = '06:00';

  static readonly GET_UP_LATE_TIME: string = '09:00';

  static readonly SLEEP_EARLY_TIME: string = '20:00';

  static readonly SLEEP_LATE_TIME: string = '23:00';

  static readonly EVERYDAY: string = '每天';

  static readonly NO_LENGTH: number = 0;

  static readonly INIT_WEEK_IDS: string = '1, 2, 3, 4, 5, 6, 7';

  static readonly PER_DAY: string = '/ 天';

  static readonly GLOBAL_KEY: string = 'global';

  static readonly GET_UP_TASK_NAME: string = '早起';

  static readonly DRINK_TASK_NAME: string = '喝水';

  static readonly EAT_APPLE_TASK_NAME: string = '吃苹果';

  static readonly SMILE_TASK_NAME: string = '每日微笑';

  static readonly BRUSH_TEETH_TASK_NAME: string = '每日刷牙';

  static readonly SLEEP_TASK_NAME: string = '早睡';

  static readonly GET_UP_CONTENT: string = '该早起啦';

  static readonly DRINK_CONTENT: string = '该喝水啦';

  static readonly EAT_APPLE_CONTENT: string = '该吃苹果啦';

  static readonly SMILE_CONTENT: string = '请保持微笑';

  static readonly BRUSH_TEETH_CONTENT: string = '每日刷牙';

  static readonly SLEEP_CONTENT: string = '早睡';

  static readonly H_STORE: string = 'healthAppStore';

  static readonly REMINDER_AGENT_TAG: string = 'reminderAgent';

  static readonly PACKAGE_NAME: string = 'com.example.healthy_life';

  static readonly ENTRY_ABILITY: string = 'EntryAbility';

  static readonly ZERO: number = 0;

  static readonly MINUS_20: number = -20;

  static readonly HAS_NO_INDEX: number = -1;

  static readonly OFFSET_24: number = -24;

  static readonly DRINK_STEP: number = 25;

  static readonly DRINK_MAX_RANGE: number = 500;

  static readonly TIMES_50: number = 50;

  static readonly TIMES_100: number = 100;

  static readonly EAT_APPLE_RANGE: number = 100;

  static readonly LETTER_1: number = 0.1;

  static readonly LETTER_34: number = 3.4;

  static readonly ACHIEVE_CARD_IMG_HEIGHT: number = 88;

  static readonly ACHIEVE_CARD_TOP: number = 38;

  static readonly ACHIEVE_CARD_BOTTOM: number = 10;

  static readonly ACHIEVE_SPLIT_RATIO: number = 1 / 3;

  static readonly ACHIEVE_TITLE_BAR_LEFT: number = 20;

  static readonly ACHIEVE_TITLE_BAR_TOP: number = 15;

  static readonly FULL_WIDTH: string = '100%';

  static readonly FULL_HEIGHT: string = '100%';

  static readonly WEEK_DAY_NUM: number = 7;

  static readonly WEEK_DAY_TIME: number = 7 * 24 * 60 * 60 * 1000;

  static readonly TAG = "UpdateFormUtils";
  static readonly FORM_PARAM_IDENTITY_KEY = "ohos.extra.param.key.form_identity";
  static readonly FORM_PARAM_DIMENSION_KEY = "ohos.extra.param.key.form_dimension";
  static readonly FORM_PARAM_NAME_KEY = "ohos.extra.param.key.form_name";
  static readonly DEFAULT_DIMENSION_2X2 = 2;
  static readonly DEFAULT_DIMENSION_2X4 = 3;
  static readonly WIDGET_NAME_AGENCY = "agency";
  static readonly WIDGET_NAME_PROGRESS = "progress";

  static readonly TASK_TYPE_COUNT: number = 1;
  static readonly TASK_TYPE_VALUE: number = 2;
  static readonly TASK_TYPE_DURATION: number = 3;
  static readonly TASK_TYPE_TIME_POINT: number = 4;
  static readonly TASK_TYPE_TIME_PERIOD: number = 5;
  static readonly TASK_TYPE_SUB_TASK: number = 6;
  static readonly TASK_TYPE_AUTO_SYNC: number = 7;
  static readonly TASK_TYPE_CYCLE: number = 8;

  static readonly TASK_STATUS_NOT_STARTED: number = 0;
  static readonly TASK_STATUS_IN_PROGRESS: number = 1;
  static readonly TASK_STATUS_COMPLETED: number = 2;
  static readonly TASK_STATUS_SKIPPED: number = 3;
  static readonly TASK_STATUS_EXPIRED: number = 4;
  static readonly TASK_STATUS_PAUSED: number = 5;

  static readonly DEFAULT_STATUS: number = 0;
  static readonly DEFAULT_SUB_TASKS: string = '';
  static readonly DEFAULT_CYCLE_DAYS: string = '';
  static readonly DEFAULT_CYCLE_TARGET: number = 0;
  static readonly DEFAULT_DATA_SRC: string = '';
  static readonly DEFAULT_TASK_NAME: string = '';
  static readonly DEFAULT_TASK_TYPE: number = 0;
  static readonly DEFAULT_UNIT: string = '';

  static readonly ACHIEVEMENT_TYPE_CHECK_IN: string = 'checkIn';
  static readonly ACHIEVEMENT_TYPE_TASK_DONE: string = 'taskDone';
  static readonly ACHIEVEMENT_TYPE_STREAK: string = 'streak';

  static readonly CALENDAR_WEEK_DAYS: number = 7;
  static readonly CALENDAR_MONTHS: number = 12;
  static readonly CALENDAR_ROWS: number = 6;

  static readonly BRUSH_TEETH_TASK_NAME_NEW: string = '每日刷牙';
  static readonly STEP_TASK_NAME: string = '每日步数';
  static readonly EXERCISE_TASK_NAME: string = '每日运动';
  static readonly SLEEP_EARLY_TASK_NAME: string = '早睡';
  static readonly SLEEP_ENSURE_TASK_NAME: string = '保证睡眠';
  static readonly SIT_REMIND_TASK_NAME: string = '久坐提醒';
  static readonly STRETCH_TASK_NAME: string = '每日拉伸';
  static readonly DIET_TASK_NAME: string = '健康饮食';
  static readonly MOOD_TASK_NAME: string = '情绪记录';
  static readonly WEIGHT_TASK_NAME: string = '定期测体重';
  static readonly RUN_TASK_NAME: string = '跑步1公里';

  static readonly BRUSH_TEETH_CONTENT_NEW: string = '早晚各刷牙1次';
  static readonly STEP_CONTENT: string = '今日步数未达标';
  static readonly EXERCISE_CONTENT: string = '运动时间到啦';
  static readonly SLEEP_EARLY_CONTENT: string = '早睡早起身体好';
  static readonly SLEEP_ENSURE_CONTENT: string = '保证睡眠时间';
  static readonly SIT_REMIND_CONTENT: string = '该起来活动一下';
  static readonly STRETCH_CONTENT: string = '该做拉伸运动了';
  static readonly DIET_CONTENT: string = '注意健康饮食';
  static readonly MOOD_CONTENT: string = '记录今天的心情';
  static readonly WEIGHT_CONTENT: string = '该测体重了';
  static readonly RUN_CONTENT: string = '今天的跑步目标还未完成';

  static readonly ALLOW_EDIT_PAST_KEY: string = 'allowEditPast';
  static readonly ALLOW_EDIT_PAST_DEFAULT: boolean = false;
}

export enum TaskType {
  BrushTeeth = 'brushTeeth',
  Smile = 'smile',
  DrinkWater = 'drinkWater',
  Step = 'step',
  Exercise = 'exercise',
  SleepEarly = 'sleepEarly',
  SleepEnsure = 'sleepEnsure',
  SitRemind = 'sitRemind',
  Stretch = 'stretch',
  Diet = 'diet',
  Mood = 'mood',
  Weight = 'weight',
  Run = 'run'
}

export enum Unit {
  Liter = 'L',
  Pcs = '个',
  Times = '次',
  Minute = '分钟',
  Hour = '小时',
  Step = '步',
  Kilometer = '公里',
  Empty = ''
}
