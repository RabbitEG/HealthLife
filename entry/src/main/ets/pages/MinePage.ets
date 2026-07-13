import DayInfoApi from '../common/database/tables/DayInfoApi';
import DayInfo from '../viewmodel/DayInfo';
import { dateToStr } from '../common/utils/Utils';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { HomeStore } from '../viewmodel/HomeViewModel';
import { CalendarTaskCard } from '../view/home/CalendarTaskCardComponent';
import TaskInfo from '../viewmodel/TaskInfo';

interface MonthDayItem {
  day: number;
  timestamp: number;
  dateStr: string;
  inCurrentMonth: boolean;
  progress: number;
}

@Component
export struct MineIndex {
  @ObjectLink homeStore: HomeStore;
  @State monthAnchor: number = new Date().getTime();
  @State monthDays: MonthDayItem[] = [];
  @State selectedDateStr: string = '';
  @State showDayDetail: boolean = false;

  aboutToAppear() {
    this.monthAnchor = this.homeStore.showDate;
    this.loadMonth();
    this.updateSelectedDate();
  }

  updateSelectedDate() {
    this.selectedDateStr = dateToStr(new Date(this.homeStore.showDate));
  }

  getMonthTitle(): string {
    const date = new Date(this.monthAnchor);
    return `${date.getFullYear()}年${date.getMonth() + 1}月`;
  }

  loadMonth() {
    const anchor = new Date(this.monthAnchor);
    const firstDay = new Date(anchor.getFullYear(), anchor.getMonth(), 1);
    const mondayOffset = (firstDay.getDay() + 6) % 7;
    const gridStart = new Date(anchor.getFullYear(), anchor.getMonth(), 1 - mondayOffset);
    const dates: string[] = [];
    const items: MonthDayItem[] = [];
    for (let index = 0; index < 42; index++) {
      const date = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + index);
      const dateStr = dateToStr(date);
      dates.push(dateStr);
      items.push({
        day: date.getDate(),
        timestamp: date.getTime(),
        dateStr: dateStr,
        inCurrentMonth: date.getMonth() === anchor.getMonth(),
        progress: 0
      } as MonthDayItem);
    }
    DayInfoApi.queryList(dates, (records: DayInfo[]) => {
      items.forEach((item: MonthDayItem) => {
        const record = records.find((value: DayInfo) => value.date === item.dateStr);
        if (record && record.targetTaskNum > 0) {
          item.progress = Math.min(100, Math.round(record.finTaskNum / record.targetTaskNum * 100));
        }
      });
      this.monthDays = items.slice();
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
      if (!liveDate.dayInfo || liveDate.dayInfo.targetTaskNum <= 0) {
        return 0;
      }
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

  build() {
    Column() {
      Text($r('app.string.calendar_title'))
        .fontSize($r('app.float.default_24'))
        .fontWeight(Const.FONT_WEIGHT_700)
        .width(Const.FULL_WIDTH)
        .padding({ left: $r('app.float.default_24'), top: $r('app.float.default_16') })

      if (this.showDayDetail) {
        Row() {
          Text('‹')
            .fontSize(Const.DEFAULT_28)
            .fontColor($r('app.color.blueColor'))
            .onClick(() => {
              this.showDayDetail = false;
            })
          Text(this.selectedDateStr)
            .fontSize($r('app.float.default_16'))
            .fontWeight(Const.FONT_WEIGHT_500)
            .margin({ left: $r('app.float.default_12') })
        }
        .width(Const.FULL_WIDTH)
        .padding({ left: $r('app.float.default_16'), top: $r('app.float.default_8'), bottom: $r('app.float.default_8') })

        Scroll() {
          Column({ space: Const.DEFAULT_8 }) {
            if (this.homeStore.getTaskListOfDay().length > 0) {
              ForEach(this.homeStore.getTaskListOfDay(), (item: TaskInfo) => {
                CalendarTaskCard({ taskInfoStr: JSON.stringify(item) })
              }, (item: TaskInfo) => JSON.stringify(item))
            } else {
              Text($r('app.string.calendar_no_record'))
                .fontSize($r('app.float.default_14'))
                .opacity(Const.OPACITY_6)
                .margin({ top: Const.DEFAULT_20 })
            }
          }.padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16') })
        }.layoutWeight(1)
      } else {
        Row() {
          Text('‹').fontSize(Const.DEFAULT_32).onClick(() => this.changeMonth(-1))
          Blank()
          Text(this.getMonthTitle()).fontSize($r('app.float.default_20')).fontWeight(Const.FONT_WEIGHT_700)
          Blank()
          Text('›').fontSize(Const.DEFAULT_32).onClick(() => this.changeMonth(1))
        }
        .width(Const.FULL_WIDTH)
        .padding({ left: $r('app.float.default_24'), right: $r('app.float.default_24') })

        Row() {
          Text('今天')
            .fontSize($r('app.float.default_14'))
            .fontColor($r('app.color.blueColor'))
            .onClick(() => {
              this.monthAnchor = new Date().getTime();
              this.loadMonth();
            })
        }
        .width(Const.FULL_WIDTH)
        .padding({ right: $r('app.float.default_24') })
        .justifyContent(FlexAlign.End)

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
                  this.updateSelectedDate();
                  this.showDayDetail = true;
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
    }
    .height(Const.FULL_HEIGHT)
    .backgroundColor($r('app.color.primaryBgColor'))
  }
}
