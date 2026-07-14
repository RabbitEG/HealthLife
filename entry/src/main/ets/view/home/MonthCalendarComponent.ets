import DayInfoApi from '../../common/database/tables/DayInfoApi';
import DayInfo from '../../viewmodel/DayInfo';
import { dateToStr } from '../../common/utils/Utils';
import { HomeStore } from '../../viewmodel/HomeViewModel';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import DatabaseApi from '../../model/DatabaseModel';
import TaskInfoApi from '../../common/database/tables/TaskInfoApi';
import TaskInfo from '../../viewmodel/TaskInfo';

interface MonthDayItem {
  day: number;
  timestamp: number;
  dateStr: string;
  isPlaceholder: boolean;
  progress: number;
}

interface CalendarRow {
  renderKey: string;
  items: MonthDayItem[];
}

@Component
export struct MonthCalendarView {
  @ObjectLink homeStore: HomeStore;
  closeAction: Function = () => {};
  @State monthAnchor: number = new Date().getTime();
  @State calendarRows: CalendarRow[] = [];
  private monthLoadId: number = 0;

  aboutToAppear() {
    this.monthAnchor = this.homeStore.showDate;
    this.loadMonth();
  }

  getMonthTitle(): string {
    const date = new Date(this.monthAnchor);
    return `${date.getFullYear()}年${date.getMonth() + 1}月`;
  }

  buildCalendarRows(items: MonthDayItem[], totalRows: number): CalendarRow[] {
    const rows: CalendarRow[] = [];
    for (let r = 0; r < totalRows; r++) {
      const rowItems: MonthDayItem[] = [];
      for (let c = 0; c < 7; c++) {
        const idx = r * 7 + c;
        if (idx < items.length) {
          rowItems.push(items[idx]);
        }
      }
      // ArkUI reuses a ForEach branch while its key remains unchanged.  A row
      // number (0, 1, 2...) is identical in every month, which left the old
      // date cells on screen after switching months.  Include both the actual
      // dates and their progress in the key so month and async data changes
      // always rebuild the affected row.
      const renderKey = rowItems
        .map((item: MonthDayItem) => `${item.dateStr}:${item.progress}`)
        .join('|');
      rows.push({ renderKey: renderKey, items: rowItems } as CalendarRow);
    }
    return rows;
  }

  loadMonth() {
    const anchor = new Date(this.monthAnchor);
    const loadId = ++this.monthLoadId;
    const year = anchor.getFullYear();
    const month = anchor.getMonth();
    const firstDay = new Date(year, month, 1);
    const startDow = (firstDay.getDay() + 6) % 7;
    const lastDate = new Date(year, month + 1, 0).getDate();
    const totalRows = Math.ceil((startDow + lastDate) / 7);
    const totalCells = totalRows * 7;
    const dates: string[] = [];
    const items: MonthDayItem[] = [];
    for (let index = 0; index < totalCells; index++) {
      const day = index - startDow + 1;
      if (day < 1 || day > lastDate) {
        items.push({
          day: 0,
          timestamp: 0,
          dateStr: `blank-${year}-${month}-${index}`,
          isPlaceholder: true,
          progress: 0
        } as MonthDayItem);
        continue;
      }
      const date = new Date(year, month, day);
      const dateStr = dateToStr(date);
      dates.push(dateStr);
      items.push({
        day: day,
        timestamp: date.getTime(),
        dateStr: dateStr,
        isPlaceholder: false,
        progress: 0
      } as MonthDayItem);
    }
    this.calendarRows = this.buildCalendarRows(items, totalRows);
    DayInfoApi.queryList(dates, (records: DayInfo[]) => {
      if (loadId !== this.monthLoadId) {
        return;
      }
      const missingItems = items.filter((item: MonthDayItem) => {
        return !item.isPlaceholder && !records.some((value: DayInfo) => value.date === item.dateStr);
      });
      const queryTasks = (date: string): Promise<TaskInfo[]> => {
        return new Promise((resolve: (tasks: TaskInfo[]) => void) => {
          TaskInfoApi.query(date, false, (tasks: TaskInfo[]) => resolve(tasks));
        });
      };
      const missingProgress = missingItems.map((item: MonthDayItem) => {
        return DatabaseApi.ensureTasksForDate(item.dateStr)
          .catch(() => {})
          .then(() => queryTasks(item.dateStr))
          .then((tasks: TaskInfo[]) => {
            const openTasks = tasks.filter((task: TaskInfo) => task.isOpen);
            const finishedTasks = openTasks.filter((task: TaskInfo) => task.isDone).length;
            const dayInfo = new DayInfo(item.dateStr, openTasks.length, finishedTasks);
            item.progress = dayInfo.targetTaskNum > 0
              ? Math.min(100, Math.round(dayInfo.finTaskNum / dayInfo.targetTaskNum * 100))
              : 0;
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
        this.calendarRows = this.buildCalendarRows(items, totalRows);
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
    if (liveDate?.dayInfo && liveDate.dayInfo.targetTaskNum > 0) {
      return Math.min(100,
        Math.round(liveDate.dayInfo.finTaskNum / liveDate.dayInfo.targetTaskNum * 100));
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

  @Builder
  dayCell(item: MonthDayItem) {
    Column({ space: 4 }) {
      Text(`${item.day}`)
        .fontSize($r('app.float.default_14'))
        .fontColor($r('app.color.titleColor'))
      Image(this.getProgressImg(item))
        .width($r('app.float.default_28'))
        .height($r('app.float.default_28'))
        .objectFit(ImageFit.Contain)
    }
    .width('14.28%')
    .height($r('app.float.default_64'))
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (item.timestamp <= new Date().getTime()) {
        this.homeStore.selectCalendarDate(item.timestamp, (): void => {
          this.closeAction();
        });
      }
    })
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

      Column() {
        ForEach(this.calendarRows, (row: CalendarRow) => {
          Row() {
            ForEach(row.items, (item: MonthDayItem) => {
              if (item.isPlaceholder) {
                Blank()
                  .width('14.28%')
                  .height($r('app.float.default_64'))
              } else {
                this.dayCell(item)
              }
            }, (item: MonthDayItem) => item.dateStr)
          }
          .width(Const.FULL_WIDTH)
        }, (row: CalendarRow) => row.renderKey)
      }
      .width(Const.FULL_WIDTH)
      .padding({ left: $r('app.float.default_12'), right: $r('app.float.default_12') })
    }
    .width(Const.FULL_WIDTH)
    .height(Const.FULL_HEIGHT)
    .backgroundColor($r('app.color.white'))
  }
}
