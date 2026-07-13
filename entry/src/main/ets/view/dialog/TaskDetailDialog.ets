import { CustomDialogCallback } from './CustomDialogView';
import TaskInfo, { TaskTypeEnum, SubTaskInfo } from '../../viewmodel/TaskInfo';
import { TaskMapById } from '../../model/TaskInitList';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import { GlobalContext } from '../../common/utils/GlobalContext';

type VoidCallback = () => void;
type StringCallback = (v: string) => void;
type NumberCallback = (n: number) => void;

@Extend(Text) function textStyle () {
  .fontColor($r('app.color.white'))
  .fontFamily($r('app.string.HarmonyHeiTi'))
}

@Extend(Text) function taskTextStyle () {
  .fontColor($r('app.color.white'))
  .width('100%')
}

@CustomDialog
export struct TaskDetailDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  @Consume currentTask: TaskInfo;
  @Consume dialogCallBack: CustomDialogCallback;
  @State inputVal: string = '';
  @State selectedHour: number = 22;
  @State selectedMinute: number = 0;
  @State subTaskList: SubTaskInfo[] = [];

  aboutToAppear() {
    if (this.currentTask?.taskType === TaskTypeEnum.TIME_POINT && this.currentTask?.finValue) {
      let parts = this.currentTask.finValue.split(':');
      if (parts.length >= 2) {
        this.selectedHour = Number(parts[0]) || 22;
        this.selectedMinute = Number(parts[1]) || 0;
      }
    }
    if (this.currentTask?.taskType === TaskTypeEnum.SUB_TASK && this.currentTask?.subTasks) {
      try {
        this.subTaskList = JSON.parse(this.currentTask.subTasks) as SubTaskInfo[];
      } catch (e) {
        this.subTaskList = [];
      }
    }
  }

  canUndo(): boolean {
    let finVal = this.currentTask?.finValue || '';
    if (finVal.length === 0) {
      return false;
    }
    return Number(finVal) > 0;
  }

  getTaskType(): number {
    return this.currentTask?.taskType || 0;
  }

  doClock(inputVal: string = ''): void {
    GlobalContext.getContext().setObject('taskListChange', true);
    this.dialogCallBack.confirmCallback(this.currentTask, 'clock', inputVal);
    this.controller.close();
  }

  doUndo(): void {
    GlobalContext.getContext().setObject('taskListChange', true);
    this.dialogCallBack.confirmCallback(this.currentTask, 'undo', '');
    this.controller.close();
  }

  doSubTaskClock(): void {
    GlobalContext.getContext().setObject('taskListChange', true);
    let doneCount = 0;
    this.subTaskList.forEach((item: SubTaskInfo) => {
      if (item.isDone) {
        doneCount++;
      }
    });
    this.currentTask.finValue = `${doneCount}`;
    this.currentTask.isDone = doneCount >= Number(this.currentTask.targetValue);
    this.currentTask.subTasks = JSON.stringify(this.subTaskList);
    this.dialogCallBack.confirmCallback(this.currentTask, 'clock', '');
    this.controller.close();
  }

  doTimePointClock(): void {
    let timeStr = `${this.selectedHour}:${this.selectedMinute < 10 ? '0' + this.selectedMinute : this.selectedMinute}`;
    GlobalContext.getContext().setObject('taskListChange', true);
    this.dialogCallBack.confirmCallback(this.currentTask, 'clock', timeStr);
    this.controller.close();
  }

  build() {
    Column() {
      TaskBaseInfo({
        taskName: this.currentTask?.taskName || TaskMapById[this.currentTask?.taskID - 1].taskName
      });

      if (this.getTaskType() === TaskTypeEnum.SUB_TASK) {
        SubTaskView({
          subTaskList: this.subTaskList,
          onConfirm: (): void => this.doSubTaskClock(),
          onClose: (): void => { this.controller.close(); }
        })
      } else if (this.getTaskType() === TaskTypeEnum.TIME_POINT) {
        TimePointView({
          selectedHour: this.selectedHour,
          selectedMinute: this.selectedMinute,
          onHourChange: (h: number): void => { this.selectedHour = h; },
          onMinuteChange: (m: number): void => { this.selectedMinute = m; },
          onConfirm: (): void => this.doTimePointClock(),
          canUndo: this.canUndo(),
          onUndo: (): void => this.doUndo(),
          onClose: (): void => { this.controller.close(); }
        })
      } else if (this.getTaskType() === TaskTypeEnum.VALUE || this.getTaskType() === TaskTypeEnum.DURATION || this.getTaskType() === TaskTypeEnum.AUTO_SYNC) {
        ValueInputView({
          unit: TaskMapById[this.currentTask?.taskID - 1].unit,
          targetValue: this.currentTask?.targetValue || '',
          finValue: this.currentTask?.finValue || '',
          inputVal: this.inputVal,
          onValueChange: (v: string): void => { this.inputVal = v; },
          onConfirm: (): void => {
            if (this.inputVal.length > 0 && Number(this.inputVal) > 0) {
              this.doClock(this.inputVal);
            }
          },
          canUndo: this.canUndo(),
          onUndo: (): void => this.doUndo(),
          onClose: (): void => { this.controller.close(); }
        })
      } else if (this.currentTask?.taskID === 8) {
        SitRemindView({
          onStanding: (): void => {
            this.currentTask.finValue = '1';
            this.currentTask.isDone = true;
            this.doClock();
          },
          onSitting: (): void => {
            this.currentTask.finValue = '0';
            this.currentTask.isDone = false;
            this.doClock();
          },
          canUndo: this.canUndo(),
          onUndo: (): void => this.doUndo(),
          onClose: (): void => { this.controller.close(); }
        })
      } else {
        CountClockView({
          finValue: this.currentTask?.finValue || '',
          targetValue: this.currentTask?.targetValue || '',
          unit: TaskMapById[this.currentTask?.taskID - 1].unit,
          onClock: (): void => this.doClock(),
          canUndo: this.canUndo(),
          onUndo: (): void => this.doUndo(),
          onClose: (): void => { this.controller.close(); }
        })
      }
    }
    .height($r('app.float.default_451'))
    .width($r('app.float.default_316'))
    .backgroundImage(TaskMapById[this.currentTask?.taskID - 1].dialogBg, ImageRepeat.NoRepeat)
    .backgroundImageSize({
      width: '100%',
      height: '100%'
    })
    .justifyContent(FlexAlign.End)
    .padding({
      bottom: $r('app.float.default_12'),
      left: $r('app.float.default_20')
    })
  }
}

@Component
struct TaskBaseInfo {
  taskName: string | Resource = '';

  build() {
    Column({ space: Const.DEFAULT_8 }) {
      Text(this.taskName)
        .fontSize($r('app.float.default_22'))
        .fontWeight(FontWeight.Bold)
        .fontFamily($r('app.string.HarmonyHeiTi_Bold'))
        .taskTextStyle()
        .margin({ left: $r('app.float.default_12') })
    }
    .position({ y: $r('app.float.default_267') })
  }
}

@Component
struct CountClockView {
  finValue: string = '';
  targetValue: string = '';
  unit: string = '';
  onClock: VoidCallback = () => {};
  canUndo: boolean = false;
  onUndo: VoidCallback = () => {};
  onClose: VoidCallback = () => {};

  build() {
    Column({ space: Const.DEFAULT_8 }) {
      Text(`已完成 ${this.finValue || '0'} / ${this.targetValue} ${this.unit}`)
        .fontSize($r('app.float.default_14'))
        .fontWeight(FontWeight.Regular)
        .textStyle()
        .width($r('app.float.default_220'))
        .textAlign(TextAlign.Center)

      Row({ space: Const.DEFAULT_8 }) {
        Button() {
          Text($r('app.string.clock_in'))
            .height($r('app.float.default_36'))
            .fontSize($r('app.float.default_16'))
            .fontWeight(FontWeight.Normal)
            .textStyle()
        }
        .layoutWeight(1)
        .borderRadius($r('app.float.default_24'))
        .backgroundColor('rgba(255,255,255,0.40)')
        .onClick(() => this.onClock())

        if (this.canUndo) {
          Button() {
            Text($r('app.string.undo'))
              .height($r('app.float.default_36'))
              .fontSize($r('app.float.default_16'))
              .fontWeight(FontWeight.Normal)
              .textStyle()
          }
          .layoutWeight(1)
          .borderRadius($r('app.float.default_24'))
          .backgroundColor('rgba(255,255,255,0.25)')
          .onClick(() => this.onUndo())
        }
      }
      .width($r('app.float.default_220'))

      Text($r('app.string.got_it'))
        .fontSize($r('app.float.default_14'))
        .fontWeight(FontWeight.Regular)
        .textStyle()
        .onClick(() => this.onClose())
    }
  }
}

@Component
struct ValueInputView {
  unit: string = '';
  targetValue: string = '';
  finValue: string = '';
  inputVal: string = '';
  onValueChange: StringCallback = (_v: string): void => {};
  onConfirm: VoidCallback = () => {};
  canUndo: boolean = false;
  onUndo: VoidCallback = () => {};
  onClose: VoidCallback = () => {};

  build() {
    Column({ space: Const.DEFAULT_8 }) {
      Text(`当前 ${this.finValue || '0'} / ${this.targetValue} ${this.unit}`)
        .fontSize($r('app.float.default_14'))
        .fontWeight(FontWeight.Regular)
        .textStyle()
        .width($r('app.float.default_220'))
        .textAlign(TextAlign.Center)

      Row({ space: Const.DEFAULT_8 }) {
        TextInput({ placeholder: `输入${this.unit}数`, text: this.inputVal })
          .type(InputType.Number)
          .width($r('app.float.default_120'))
          .height($r('app.float.default_40'))
          .fontSize($r('app.float.default_16'))
          .fontColor($r('app.color.white'))
          .backgroundColor('rgba(255,255,255,0.20)')
          .onChange((value: string): void => {
            this.onValueChange(value);
          })
        Text(this.unit)
          .fontSize($r('app.float.default_14'))
          .fontColor($r('app.color.white'))
      }
      .justifyContent(FlexAlign.Center)

      Row({ space: Const.DEFAULT_8 }) {
        Button() {
          Text($r('app.string.confirm'))
            .height($r('app.float.default_36'))
            .fontSize($r('app.float.default_16'))
            .fontWeight(FontWeight.Normal)
            .textStyle()
        }
        .layoutWeight(1)
        .borderRadius($r('app.float.default_24'))
        .backgroundColor('rgba(255,255,255,0.40)')
        .onClick(() => this.onConfirm())

        if (this.canUndo) {
          Button() {
            Text($r('app.string.undo'))
              .height($r('app.float.default_36'))
              .fontSize($r('app.float.default_16'))
              .fontWeight(FontWeight.Normal)
              .textStyle()
          }
          .layoutWeight(1)
          .borderRadius($r('app.float.default_24'))
          .backgroundColor('rgba(255,255,255,0.25)')
          .onClick(() => this.onUndo())
        }
      }
      .width($r('app.float.default_220'))

      Text($r('app.string.got_it'))
        .fontSize($r('app.float.default_14'))
        .fontWeight(FontWeight.Regular)
        .textStyle()
        .onClick(() => this.onClose())
    }
  }
}

@Component
struct TimePointView {
  selectedHour: number = 22;
  selectedMinute: number = 0;
  onHourChange: NumberCallback = (_h: number): void => {};
  onMinuteChange: NumberCallback = (_m: number): void => {};
  onConfirm: VoidCallback = () => {};
  canUndo: boolean = false;
  onUndo: VoidCallback = () => {};
  onClose: VoidCallback = () => {};

  build() {
    Column({ space: Const.DEFAULT_8 }) {
      Text($r('app.string.select_time'))
        .fontSize($r('app.float.default_14'))
        .fontWeight(FontWeight.Regular)
        .textStyle()
        .width($r('app.float.default_220'))
        .textAlign(TextAlign.Center)

      TimePicker({
        selected: new Date(2026, 0, 1, this.selectedHour, this.selectedMinute)
      })
        .useMilitaryTime(true)
        .onChange((value: TimePickerResult): void => {
          if (value.hour !== undefined) {
            this.onHourChange(value.hour as number);
          }
          if (value.minute !== undefined) {
            this.onMinuteChange(value.minute as number);
          }
        })
        .height($r('app.float.default_120'))

      Row({ space: Const.DEFAULT_8 }) {
        Button() {
          Text($r('app.string.confirm'))
            .height($r('app.float.default_36'))
            .fontSize($r('app.float.default_16'))
            .fontWeight(FontWeight.Normal)
            .textStyle()
        }
        .layoutWeight(1)
        .borderRadius($r('app.float.default_24'))
        .backgroundColor('rgba(255,255,255,0.40)')
        .onClick(() => this.onConfirm())

        if (this.canUndo) {
          Button() {
            Text($r('app.string.undo'))
              .height($r('app.float.default_36'))
              .fontSize($r('app.float.default_16'))
              .fontWeight(FontWeight.Normal)
              .textStyle()
          }
          .layoutWeight(1)
          .borderRadius($r('app.float.default_24'))
          .backgroundColor('rgba(255,255,255,0.25)')
          .onClick(() => this.onUndo())
        }
      }
      .width($r('app.float.default_220'))

      Text($r('app.string.got_it'))
        .fontSize($r('app.float.default_14'))
        .fontWeight(FontWeight.Regular)
        .textStyle()
        .onClick(() => this.onClose())
    }
  }
}

@Component
struct SubTaskView {
  @State subTaskList: SubTaskInfo[] = [];
  onConfirm: VoidCallback = () => {};
  onClose: VoidCallback = () => {};

  build() {
    Column({ space: Const.DEFAULT_8 }) {
      ForEach(this.subTaskList, (item: SubTaskInfo, index: number) => {
        Row({ space: Const.DEFAULT_8 }) {
          Toggle({ type: ToggleType.Checkbox, isOn: item.isDone })
            .onChange((isOn: boolean): void => {
              this.subTaskList[index].isDone = isOn;
            })
            .width($r('app.float.default_20'))
            .height($r('app.float.default_20'))
          Text(item.name)
            .fontSize($r('app.float.default_16'))
            .fontColor($r('app.color.white'))
        }
        .width($r('app.float.default_220'))
      }, (item: SubTaskInfo, index: number): string => `${index}_${item.name}`)

      Button() {
        Text($r('app.string.confirm'))
          .height($r('app.float.default_36'))
          .fontSize($r('app.float.default_16'))
          .fontWeight(FontWeight.Normal)
          .textStyle()
      }
      .width($r('app.float.default_220'))
      .borderRadius($r('app.float.default_24'))
      .backgroundColor('rgba(255,255,255,0.40)')
      .onClick(() => this.onConfirm())

      Text($r('app.string.got_it'))
        .fontSize($r('app.float.default_14'))
        .fontWeight(FontWeight.Regular)
        .textStyle()
        .onClick(() => this.onClose())
    }
  }
}

@Component
struct SitRemindView {
  onStanding: VoidCallback = () => {};
  onSitting: VoidCallback = () => {};
  canUndo: boolean = false;
  onUndo: VoidCallback = () => {};
  onClose: VoidCallback = () => {};

  build() {
    Column({ space: Const.DEFAULT_8 }) {
      Button() {
        Text($r('app.string.clock_standing'))
          .height($r('app.float.default_36'))
          .fontSize($r('app.float.default_16'))
          .fontWeight(FontWeight.Normal)
          .textStyle()
      }
      .width($r('app.float.default_220'))
      .borderRadius($r('app.float.default_24'))
      .backgroundColor('rgba(255,255,255,0.40)')
      .onClick(() => this.onStanding())

      Button() {
        Text($r('app.string.clock_sitting'))
          .height($r('app.float.default_36'))
          .fontSize($r('app.float.default_16'))
          .fontWeight(FontWeight.Normal)
          .textStyle()
      }
      .width($r('app.float.default_220'))
      .borderRadius($r('app.float.default_24'))
      .backgroundColor('rgba(255,255,255,0.25)')
      .onClick(() => this.onSitting())

      if (this.canUndo) {
        Button() {
          Text($r('app.string.undo'))
            .height($r('app.float.default_36'))
            .fontSize($r('app.float.default_16'))
            .fontWeight(FontWeight.Normal)
            .textStyle()
        }
        .width($r('app.float.default_220'))
        .borderRadius($r('app.float.default_24'))
        .backgroundColor('rgba(255,255,255,0.20)')
        .onClick(() => this.onUndo())
      }

      Text($r('app.string.got_it'))
        .fontSize($r('app.float.default_14'))
        .fontWeight(FontWeight.Regular)
        .textStyle()
        .onClick(() => this.onClose())
    }
  }
}
