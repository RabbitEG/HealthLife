import TaskInfo, { SubTaskInfo, TaskTypeEnum } from '../../viewmodel/TaskInfo';
import { TaskMapById } from '../../model/TaskInitList';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';

@Component
export struct CalendarTaskCard {
  @Prop taskInfoStr: string = '';
  @State taskInfo: TaskInfo = TaskInfo.create(-1, '');
  @State subTasks: SubTaskInfo[] = [];

  aboutToAppear() {
    this.taskInfo = JSON.parse(this.taskInfoStr) as TaskInfo;
    if (this.taskInfo.taskType === TaskTypeEnum.SUB_TASK && this.taskInfo.subTasks) {
      try {
        this.subTasks = JSON.parse(this.taskInfo.subTasks) as SubTaskInfo[];
      } catch (error) {
        this.subTasks = [];
      }
    }
  }

  getProgress(): number {
    const target = Number(this.taskInfo.targetValue);
    const current = Number(this.taskInfo.finValue);
    if (this.taskInfo.isDone) {
      return 100;
    }
    if (!target || !current) {
      return 0;
    }
    return Math.min(100, Math.round(current / target * 100));
  }

  build() {
    Column({ space: Const.DEFAULT_8 }) {
      Row() {
        Row({ space: Const.DEFAULT_8 }) {
          Image(TaskMapById[this.taskInfo.taskID - 1].icon)
            .width($r('app.float.default_28'))
            .height($r('app.float.default_28'))
          Text(this.taskInfo.taskName || TaskMapById[this.taskInfo.taskID - 1].taskName)
            .fontSize($r('app.float.default_16'))
            .fontWeight(Const.FONT_WEIGHT_500)
        }
        Blank()
        Text(`${this.taskInfo.finValue || 0} / ${this.taskInfo.targetValue} ${this.taskInfo.unit}`)
          .fontSize($r('app.float.default_12'))
          .opacity(Const.OPACITY_6)
      }.width(Const.FULL_WIDTH)

      Progress({ value: this.getProgress(), total: 100, style: ProgressStyle.Linear })
        .width(Const.FULL_WIDTH)
        .height($r('app.float.default_6'))
        .color($r('app.color.blueColor'))

      if (this.subTasks.length > 0) {
        ForEach(this.subTasks, (item: SubTaskInfo) => {
          Row({ space: Const.DEFAULT_8 }) {
            Text(item.name)
              .fontSize($r('app.float.default_12'))
              .width('24%')
            Progress({ value: item.isDone || this.taskInfo.isDone ? 100 : 0, total: 100, style: ProgressStyle.Linear })
              .layoutWeight(1)
              .height($r('app.float.default_4'))
              .color($r('app.color.blueColor'))
            Text(item.isDone || this.taskInfo.isDone ? '100%' : '0%')
              .fontSize($r('app.float.default_10'))
              .opacity(Const.OPACITY_6)
          }.width(Const.FULL_WIDTH)
        }, (item: SubTaskInfo) => item.name)
      }
    }
    .width(Const.FULL_WIDTH)
    .padding($r('app.float.default_16'))
    .borderRadius($r('app.float.default_20'))
    .backgroundColor($r('app.color.white'))
  }
}
