import DayInfoApi from '../../common/database/tables/DayInfoApi';
import DayInfo from '../../viewmodel/DayInfo';
import { dateToStr, sameMonth } from '../../common/utils/Utils';
import { HomeStore } from '../../viewmodel/HomeViewModel';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import DatabaseApi from '../../model/DatabaseModel';
import TaskInfoApi from '../../common/database/tables/TaskInfoApi';
import TaskInfo from '../../viewmodel/TaskInfo';

interface MonthDayItem {
  day: number;
  timestamp: number;
  dateStr: string;
  inCurrentMonth: boolean;
  progress: number;
}

@Component
export struct MonthCalendarView {
  @ObjectLink homeStore: HomeStore;
  closeAction: Function = () => {};
  @State monthAnchor: number = new Date().getTime();
  @State monthDays: MonthDayItem[] = [];
  private monthLoadId: number = 0;

  aboutToAppear() {
    this.monthAnchor = this.homeStore.showDate;
    this.loadMonth();
  }

  getMonthTitle(): string {
    const date = new Date(this.monthAnchor);
    return `${date.getFullYear()}年${date.getMonth() + 1}月`;
  }

  loadMonth() {
    const anchor = new Date(this.monthAnchor);
    const loadId = ++this.monthLoadId;
    const firstDay = new Date(anchor.getFullYear(), anchor.getMonth(), 1);
    const mondayOffset = (firstDay.getDay() + 6) % 7;
    const gridStart = new Date(anchor.getFullYear(), anchor.getMonth(), 1 - mondayOffset);
    const lastDayOfMonth = new Date(anchor.getFullYear(), anchor.getMonth() + 1, 0);
    const lastMondayOffset = (lastDayOfMonth.getDay() + 6) % 7;
    const totalRows = Math.ceil((mondayOffset + lastDayOfMonth.getDate()) / 7);
    const totalCells = totalRows * 7;
    const dates: string[] = [];
    const items: MonthDayItem[] = [];
    for (let index = 0; index < totalCells; index++) {
      const date = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + index);
      const dateStr = dateToStr(date);
      dates.push(dateStr);
      items.push({
        day: date.getDate(),
        timestamp: date.getTime(),
        dateStr: dateStr,
        inCurrentMonth: sameMonth(date, anchor),
        progress: 0
      } as MonthDayItem);
    }
    DayInfoApi.queryList(dates, (records: DayInfo[]) => {
      if (loadId !== this.monthLoadId) {
        return;
      }
      // Most dates already have a dayInfo summary.  The leading/trailing
      // cells of a month grid can be outside the viewed month, however, and
      // those dates may not have been visited by the week view yet.  Lazily
      // materialize the plan and calculate the missing summary from the
      // date-specific task rows so their badges are consistent as well.
      const missingItems = items.filter((item: MonthDayItem) => {
        return !records.some((value: DayInfo) => value.date === item.dateStr);
      });
      const queryTasks = (date: string): Promise<TaskInfo[]> => {
        return new Promise((resolve: (tasks: TaskInfo[]) => void) => {
          TaskInfoApi.query(date, false, (tasks: TaskInfo[]) => resolve(tasks));
        });
      };
      const missingProgress = missingItems.map((item: MonthDayItem) => {
        return DatabaseApi.ensureTasksForDate(item.dateStr)
          .catch(() => {
            // A missing plan must still be rendered as an empty day when the
            // database is temporarily unavailable.
          })
          .then(() => queryTasks(item.dateStr))
          .then((tasks: TaskInfo[]) => {
            const openTasks = tasks.filter((task: TaskInfo) => task.isOpen);
            const finishedTasks = openTasks.filter((task: TaskInfo) => task.isDone).length;
            const dayInfo = new DayInfo(item.dateStr, openTasks.length, finishedTasks);
            item.progress = dayInfo.targetTaskNum > 0
              ? Math.min(100, Math.round(dayInfo.finTaskNum / dayInfo.targetTaskNum * 100))
              : 0;
            // Keep the summary table in sync for later month/week renders.
            return new Promise<void>((resolve: () => void) => {
              DayInfoApi.updateData(dayInfo, (updated: number) => {
                if (updated) {
                  resolve();
                } else {
                  DayInfoApi.insertData(dayInfo, () => resolve());
                }
              });
            });
          })
          .catch(() => {
            item.progress = 0;
          });
      });
      Promise.all(missingProgress).then(() => {
        if (loadId !== this.monthLoadId) {
          return;
        }
        items.forEach((item: MonthDayItem) => {
          const record = records.find((value: DayInfo) => value.date === item.dateStr);
          if (record && record.targetTaskNum > 0) {
            item.progress = Math.min(100, Math.round(record.finTaskNum / record.targetTaskNum * 100));
          }
        });
        this.monthDays = items.slice();
      });
    });
  }

  changeMonth(offset: number) {
    const current = new Date(this.monthAnchor);
    this.monthAnchor = new Date(current.getFullYear(), current.getMonth() + offset, 1).getTime();
    this.loadMonth();
  }

  getCurrentProgress(item: MonthDayItem): number {
    const liveDate = this.homeStore.dateArr.find((dateItem) => dateItem.dateStr === item.dateStr);
    if (liveDate) {
      if (liveDate.dayInfo && liveDate.dayInfo.targetTaskNum > 0) {
        return Math.min(100,
          Math.round(liveDate.dayInfo.finTaskNum / liveDate.dayInfo.targetTaskNum * 100));
      }
    }
    return item.progress;
  }

  getProgressImg(item: MonthDayItem): Resource {
    const progress = this.getCurrentProgress(item);
    if (progress <= 0) {
      return $r('app.media.ic_home_undone');
    }
    if (progress >= 100) {
      return $r('app.media.ic_home_all_done');
    }
    return $r('app.media.ic_home_half_done');
  }

  build() {
    Column() {
      Row() {
        Text('取消')
          .fontSize($r('app.float.default_16'))
          .fontColor($r('app.color.blueColor'))
          .onClick(() => this.closeAction())
        Blank()
        Text(this.getMonthTitle())
          .fontSize($r('app.float.default_20'))
          .fontWeight(Const.FONT_WEIGHT_700)
        Blank()
        Text('今天')
          .fontSize($r('app.float.default_14'))
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.monthAnchor = new Date().getTime();
            this.loadMonth();
          })
      }
      .width(Const.FULL_WIDTH)
      .height($r('app.float.default_56'))
      .padding({ left: $r('app.float.default_20'), right: $r('app.float.default_20') })

      Row() {
        Text('‹').fontSize(Const.DEFAULT_32).onClick(() => this.changeMonth(-1))
        Blank()
        Text('月度打卡状态').fontSize($r('app.float.default_16')).opacity(Const.OPACITY_6)
        Blank()
        Text('›').fontSize(Const.DEFAULT_32).onClick(() => this.changeMonth(1))
      }
      .width(Const.FULL_WIDTH)
      .padding({ left: $r('app.float.default_24'), right: $r('app.float.default_24') })

      Row() {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (title: string) => {
          Text(title)
            .width('14.28%')
            .textAlign(TextAlign.Center)
            .fontSize($r('app.float.default_12'))
            .opacity(Const.OPACITY_6)
        })
      }.margin({ top: $r('app.float.default_12'), bottom: $r('app.float.default_8') })

      Grid() {
        ForEach(this.monthDays, (item: MonthDayItem) => {
          GridItem() {
            Column({ space: 4 }) {
              Text(`${item.day}`)
                .fontSize($r('app.float.default_14'))
                .fontColor(item.inCurrentMonth ? $r('app.color.titleColor') : $r('app.color.disabledColor'))
              Image(this.getProgressImg(item))
                .width($r('app.float.default_28'))
                .height($r('app.float.default_28'))
                .objectFit(ImageFit.Contain)
            }
            .width(Const.FULL_WIDTH)
            .height($r('app.float.default_64'))
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              if (item.timestamp <= new Date().getTime()) {
                this.homeStore.setSelectedShowDate(item.timestamp);
                this.closeAction();
              }
            })
          }
        }, (item: MonthDayItem) => item.dateStr)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsGap($r('app.float.default_4'))
      .width(Const.FULL_WIDTH)
      .layoutWeight(1)
      .padding({ left: $r('app.float.default_12'), right: $r('app.float.default_12') })
    }
    .width(Const.FULL_WIDTH)
    .height(Const.FULL_HEIGHT)
    .backgroundColor($r('app.color.white'))
  }
}
