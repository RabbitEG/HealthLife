import common from '@ohos.app.ability.common';
import { dateToStr } from '../common/utils/Utils';
import MoodStorage, { MoodRecord } from '../common/utils/MoodStorage';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { HomeStore } from '../viewmodel/HomeViewModel';

interface MoodDayItem {
  day: number;
  timestamp: number;
  dateStr: string;
  isPlaceholder: boolean;
  mood: string;
  note: string;
}

/** Month grid for mood journal records only. */
@Component
export struct MineIndex {
  @ObjectLink homeStore: HomeStore;
  @Prop @Watch('refreshMonth') refreshToken: number = 0;
  @State monthAnchor: number = new Date().getTime();
  @State monthDays: MoodDayItem[] = [];
  @State showDetail: boolean = false;
  @State detailDateStr: string = '';
  @State detailMood: string = '';
  @State detailNote: string = '';
  private monthLoadId: number = 0;

  aboutToAppear(): void {
    this.loadMonth();
  }

  refreshMonth(): void {
    // Keep the journal's month cursor while refreshing its records. Explicitly
    // clicking a day still synchronizes that date with the home week strip.
    this.showDetail = false;
    this.loadMonth();
  }

  getMonthTitle(): string {
    const date = new Date(this.monthAnchor);
    return `${date.getFullYear()}年${date.getMonth() + 1}月`;
  }

  loadMonth(): void {
    const anchor = new Date(this.monthAnchor);
    const loadId = ++this.monthLoadId;
    const firstDay = new Date(anchor.getFullYear(), anchor.getMonth(), 1);
    const mondayOffset = (firstDay.getDay() + 6) % 7;
    const lastDayOfMonth = new Date(anchor.getFullYear(), anchor.getMonth() + 1, 0);
    const totalRows = Math.ceil((mondayOffset + lastDayOfMonth.getDate()) / 7);
    const totalCells = totalRows * 7;
    const items: MoodDayItem[] = [];
    for (let index = 0; index < totalCells; index++) {
      const day = index - mondayOffset + 1;
      if (day < 1 || day > lastDayOfMonth.getDate()) {
        items.push({
          day: 0,
          timestamp: 0,
          dateStr: `blank-${anchor.getFullYear()}-${anchor.getMonth()}-${index}`,
          isPlaceholder: true,
          mood: '',
          note: ''
        } as MoodDayItem);
        continue;
      }
      const date = new Date(anchor.getFullYear(), anchor.getMonth(), day);
      const dateStr = dateToStr(date);
      items.push({
        day: day,
        timestamp: date.getTime(),
        dateStr: dateStr,
        isPlaceholder: false,
        mood: '',
        note: ''
      } as MoodDayItem);
    }
    MoodStorage.loadAll(getContext(this) as common.UIAbilityContext)
      .then((records: Record<string, MoodRecord>) => {
        if (loadId !== this.monthLoadId) {
          return;
        }
        items.forEach((item: MoodDayItem) => {
          const record = records[item.dateStr];
          if (record) {
            item.mood = record.mood;
            item.note = record.note;
          }
        });
        this.monthDays = items.slice();
      })
      .catch(() => {
        if (loadId === this.monthLoadId) {
          this.monthDays = items.slice();
        }
      });
  }

  changeMonth(offset: number): void {
    const current = new Date(this.monthAnchor);
    this.monthAnchor = new Date(current.getFullYear(), current.getMonth() + offset, 1).getTime();
    this.loadMonth();
  }

  getMoodEmoji(mood: string): string {
    if (!mood) {
      return '';
    }
    const separator = mood.indexOf(' ');
    return separator >= 0 ? mood.substring(separator + 1) : mood;
  }

  getMoodLabel(mood: string): string {
    if (!mood) {
      return '未记录';
    }
    const separator = mood.indexOf(' ');
    return separator >= 0 ? mood.substring(0, separator) : mood;
  }

  getDetailTitle(): string {
    const date = new Date(this.detailDateStr);
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
  }

  openDetail(item: MoodDayItem): void {
    this.detailDateStr = item.dateStr;
    this.detailMood = item.mood;
    this.detailNote = item.note;
    this.showDetail = true;
    this.homeStore.selectCalendarDate(item.timestamp, () => {});
  }

  @Builder
  buildCalendar(): void {
    Row() {
      Text('‹')
        .fontSize(Const.DEFAULT_32)
        .fontColor($r('app.color.blueColor'))
        .onClick(() => this.changeMonth(-1))
      Blank()
      Text(this.getMonthTitle())
        .fontSize($r('app.float.default_20'))
        .fontWeight(Const.FONT_WEIGHT_700)
      Blank()
      Text('›')
        .fontSize(Const.DEFAULT_32)
        .fontColor($r('app.color.blueColor'))
        .onClick(() => this.changeMonth(1))
    }
    .width(Const.FULL_WIDTH)
    .padding({ left: Const.DEFAULT_24, right: Const.DEFAULT_24 })

    Row() {
      Text('今天')
        .fontSize(Const.DEFAULT_14)
        .fontColor($r('app.color.blueColor'))
        .onClick(() => {
          this.monthAnchor = new Date().getTime();
          this.loadMonth();
        })
    }
    .width(Const.FULL_WIDTH)
    .padding({ right: Const.DEFAULT_24 })
    .justifyContent(FlexAlign.End)

    Row() {
      ForEach(['一', '二', '三', '四', '五', '六', '日'], (title: string) => {
        Text(title)
          .width('14.28%')
          .textAlign(TextAlign.Center)
          .fontSize($r('app.float.default_12'))
          .opacity(Const.OPACITY_6)
      }, (title: string) => title)
    }
    .margin({ top: Const.DEFAULT_12, bottom: Const.DEFAULT_8 })

    Grid() {
      ForEach(this.monthDays, (item: MoodDayItem) => {
        GridItem() {
          if (item.isPlaceholder) {
            Blank()
              .width(Const.FULL_WIDTH)
              .height(64)
          } else {
            Column({ space: 4 }) {
              Text(`${item.day}`)
                .fontSize(Const.DEFAULT_14)
                .fontColor($r('app.color.titleColor'))
              Text(this.getMoodEmoji(item.mood) || '·')
                .fontSize(Const.DEFAULT_24)
                .height(Const.DEFAULT_28)
                .opacity(item.mood.length > 0 ? 1 : Const.OPACITY_4)
            }
            .width(Const.FULL_WIDTH)
            .height(64)
            .justifyContent(FlexAlign.Center)
            .onClick(() => this.openDetail(item))
          }
        }
      }, (item: MoodDayItem) => item.dateStr)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(4)
    .width(Const.FULL_WIDTH)
    .layoutWeight(1)
    .padding({ left: Const.DEFAULT_12, right: Const.DEFAULT_12 })
  }

  @Builder
  buildDetail(): void {
    Row() {
      Text('‹')
        .fontSize(Const.DEFAULT_32)
        .fontColor($r('app.color.blueColor'))
        .onClick(() => this.showDetail = false)
      Text(this.getDetailTitle())
        .fontSize(Const.DEFAULT_20)
        .fontWeight(Const.FONT_WEIGHT_700)
        .margin({ left: Const.DEFAULT_12 })
    }
    .width(Const.FULL_WIDTH)
    .padding({ left: Const.DEFAULT_16, top: Const.DEFAULT_8, bottom: Const.DEFAULT_8 })

    Scroll() {
      Column({ space: Const.DEFAULT_16 }) {
        Column() {
          Text(this.getMoodEmoji(this.detailMood) || '—')
            .fontSize(64)
          Text(this.getMoodLabel(this.detailMood))
            .fontSize(Const.DEFAULT_20)
            .fontWeight(Const.FONT_WEIGHT_700)
            .fontColor('#182431')
            .margin({ top: Const.DEFAULT_12 })
        }
        .width(Const.FULL_WIDTH)
        .padding({ top: 36, bottom: 36 })
        .backgroundColor(Color.White)
        .borderRadius(20)

        Column() {
          Text('一句话记录')
            .fontSize(Const.DEFAULT_18)
            .fontWeight(Const.FONT_WEIGHT_700)
            .fontColor('#182431')
          Text(this.detailNote.length > 0 ? this.detailNote : '这一天还没有文字记录')
            .fontSize(Const.DEFAULT_16)
            .fontColor(this.detailNote.length > 0 ? '#182431' : '#7A818A')
            .margin({ top: Const.DEFAULT_12 })
            .lineHeight(24)
        }
        .width(Const.FULL_WIDTH)
        .alignItems(HorizontalAlign.Start)
        .padding(Const.DEFAULT_20)
        .backgroundColor(Color.White)
        .borderRadius(18)
      }
      .width(Const.FULL_WIDTH)
      .padding({ left: Const.DEFAULT_16, right: Const.DEFAULT_16, bottom: Const.DEFAULT_20 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  build() {
    Column() {
      if (this.showDetail) {
        this.buildDetail()
      } else {
        Text('心情日历')
          .fontSize($r('app.float.default_24'))
          .fontWeight(Const.FONT_WEIGHT_700)
          .width(Const.FULL_WIDTH)
          .padding({ left: Const.DEFAULT_24, top: Const.DEFAULT_16, bottom: Const.DEFAULT_8 })
        this.buildCalendar()
      }
    }
    .height(Const.FULL_HEIGHT)
    .backgroundColor($r('app.color.primaryBgColor'))
  }
}
