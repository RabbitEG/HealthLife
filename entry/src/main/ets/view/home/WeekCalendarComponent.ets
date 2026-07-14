import display from '@ohos.display';
import { ScrollTo } from '../../viewmodel/CalendarViewModel';
import { HomeStore } from '../../viewmodel/HomeViewModel';
import HealthText from '../../view/HealthTextComponent';
import { WeekDateModel, WEEK_DAY_NUM } from '../../model/WeekCalendarModel';
import { sameDate, dateToStr } from '../../common/utils/Utils';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import Logger from '../../common/utils/Logger';

export const WEEK_DAY_WIDTH: number = 100 / Const.WEEK_DAY_NUM;

const DEFAULT_SCROLL_WIDTH = 336;
const DEFAULT_SCROLL_PERCENT = 0.934;
const WEEK_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];

@Component
export struct WeekCalendar {
  @ObjectLink homeStore: HomeStore;
  @Prop navigationTarget: number = 0;
  @Prop @Watch('syncCalendarNavigation') navigationRequest: number = 0;
  openMonthAction: Function = () => {};
  currentPage: number = 0;
  private scroller: Scroller = new Scroller();
  scrollWidth: number = DEFAULT_SCROLL_WIDTH;
  private isLoadMore: boolean = false;
  private isPageScroll: boolean = false;

  aboutToAppear() {
    try {
      let displayClass = display.getDefaultDisplaySync();
      this.scrollWidth = displayClass.width / displayClass.densityPixels * DEFAULT_SCROLL_PERCENT;
      Logger.info('HomeIndex', 'get the window scrollWidth: ' + this.scrollWidth);
    } catch (err) {
      Logger.error('HomeIndex->onScrollEnd', JSON.stringify(err));
    }
  }

  getProgressImg(item: WeekDateModel): Resource {
    let finNum = item.dayInfo?.finTaskNum || 0;
    if (finNum === 0) {
      return $r('app.media.ic_home_undone');
    }
    if (finNum === (item.dayInfo?.targetTaskNum || 0)) {
      return $r('app.media.ic_home_all_done');
    }
    return $r('app.media.ic_home_half_done');
  }

  getCurrentWeekStartIndex(): number {
    const selectedDateStr = dateToStr(new Date(this.homeStore.showDate));
    const selectedIndex = this.homeStore.dateArr.findIndex((item: WeekDateModel) => item.dateStr === selectedDateStr);
    if (selectedIndex >= 0) {
      return Math.floor(selectedIndex / Const.WEEK_DAY_NUM) * Const.WEEK_DAY_NUM;
    }
    let page = Math.round(this.scroller.currentOffset().xOffset / this.scrollWidth);
    page = (this.isLoadMore === true) ? page + 1 : page;
    return Const.WEEK_DAY_NUM * page;
  }

  getDateIndex(dateTime: number): number {
    const dateStr = dateToStr(new Date(dateTime));
    return this.homeStore.dateArr.findIndex((item: WeekDateModel) => item.dateStr === dateStr);
  }

  scrollToDate(dateTime: number) {
    const targetIndex = this.getDateIndex(dateTime);
    if (targetIndex < 0) {
      return;
    }
    const page = Math.floor(targetIndex / Const.WEEK_DAY_NUM);
    this.currentPage = Math.max(0,
      Math.floor(this.homeStore.dateArr.length / Const.WEEK_DAY_NUM) - page - 1);
    this.scroller.scrollTo({ xOffset: page * this.scrollWidth, yOffset: 0 } as ScrollTo);
  }

  syncCalendarNavigation(): void {
    // Wait until ArkUI has rebuilt the strip after its week data changes.
    setTimeout((): void => {
      this.scrollToDate(this.navigationTarget);
    }, 0);
  }

  gotoPreviousWeek() {
    this.isPageScroll = true;
    let date: Date = new Date(this.homeStore.showDate);
    const targetDate = new Date(date);
    targetDate.setDate(targetDate.getDate() - Const.WEEK_DAY_NUM);
    const targetTime = targetDate.getTime();
    if (this.getDateIndex(targetTime) < 0) {
      this.homeStore.getPreWeekData(date, () => {
        this.homeStore.setSelectedShowDate(targetTime);
        this.scrollToDate(targetTime);
        this.isPageScroll = false;
      });
    } else {
      this.homeStore.setSelectedShowDate(targetTime);
      this.scrollToDate(targetTime);
      this.isPageScroll = false;
    }
  }

  goToNextWeek() {
    const targetDate = new Date(this.homeStore.showDate);
    targetDate.setDate(targetDate.getDate() + Const.WEEK_DAY_NUM);
    const targetTime = targetDate.getTime();
    // The current week already contains dates later than today. Whether the
    // right arrow is available is therefore determined by loaded calendar
    // data, not by comparing the selected weekday with the current instant.
    if (this.getDateIndex(targetTime) < 0 && this.isAfterCurrentWeek(targetTime)) {
      return;
    }
    this.isPageScroll = true;
    if (this.getDateIndex(targetTime) < 0) {
      this.homeStore.getNextWeekData(new Date(this.homeStore.showDate), () => {
        this.homeStore.setSelectedShowDate(targetTime);
        this.scrollToDate(targetTime);
        this.isPageScroll = false;
      });
    } else {
      this.homeStore.setSelectedShowDate(targetTime);
      this.scrollToDate(targetTime);
      this.isPageScroll = false;
    }
  }

  isAfterCurrentWeek(dateTime: number): boolean {
    const targetDate = new Date(dateTime);
    const today = new Date();
    const targetDay = (targetDate.getDay() + WEEK_DAY_NUM - 1) % WEEK_DAY_NUM;
    const todayDay = (today.getDay() + WEEK_DAY_NUM - 1) % WEEK_DAY_NUM;
    targetDate.setDate(targetDate.getDate() - targetDay);
    today.setDate(today.getDate() - todayDay);
    targetDate.setHours(0, 0, 0, 0);
    today.setHours(0, 0, 0, 0);
    return targetDate.getTime() > today.getTime();
  }

  goBackToToday() {
    const today = new Date();
    // Use the same navigation path as a date picked from the month calendar.
    // It loads today's week first when necessary and only then asks the week
    // strip to scroll, avoiding a scroll against stale children.
    this.homeStore.selectCalendarDate(today.getTime(), (): void => {});
  }

  onWeekLabelClick(dayIndex: number) {
    let startIdx = this.getCurrentWeekStartIndex();
    let targetIdx = startIdx + dayIndex;
    if (targetIdx >= 0 && targetIdx < this.homeStore.dateArr.length) {
      let item = this.homeStore.dateArr[targetIdx];
      this.homeStore.setSelectedShowDate(item.date.getTime());
    }
  }

  isTodayShown(): boolean {
    return sameDate(new Date(), this.homeStore.showDate);
  }

  build() {
    Row() {
      Column() {
        Row() {
          Row() {
            Image($r('app.media.ic_right_grey'))
              .width($r('app.float.default_6'))
              .height($r('app.float.default_12'))
          }
          .width($r('app.float.default_28'))
          .height($r('app.float.default_28'))
          .rotate({ z: 1, angle: Const.DEFAULT_180 })
          .justifyContent(FlexAlign.Center)
          .borderRadius(Const.DEFAULT_14)
          .onClick(() => this.gotoPreviousWeek())

          HealthText({ title: this.homeStore.dateTitle, fontSize: $r('app.float.default_14') })
            .margin({ left: $r('app.float.default_8'), right: $r('app.float.default_8') })

          Row() {
            Image($r('app.media.ic_right_grey'))
              .width($r('app.float.default_6'))
              .height($r('app.float.default_12'))
          }
          .width($r('app.float.default_28'))
          .height($r('app.float.default_28'))
          .justifyContent(FlexAlign.Center)
          .borderRadius(Const.DEFAULT_14)
          .onClick(() => this.goToNextWeek())

          Image($r('app.media.ic_tabs_calendar_sel'))
            .width($r('app.float.default_20'))
            .height($r('app.float.default_20'))
            .objectFit(ImageFit.Contain)
            .margin({ left: $r('app.float.default_12') })
            .onClick(() => this.openMonthAction())

          if (!this.isTodayShown()) {
            Text($r('app.string.back_to_today'))
              .fontSize($r('app.float.default_12'))
              .fontColor($r('app.color.blueColor'))
              .margin({ left: $r('app.float.default_12') })
              .onClick(() => this.goBackToToday())
          }
        }
        .justifyContent(FlexAlign.Center)

        Row() {
          ForEach(WEEK_LABELS, (title: string, index?: number) => {
            Text(title)
              .width(`${WEEK_DAY_WIDTH}%`)
              .textAlign(TextAlign.Center)
              .fontSize($r('app.float.default_12'))
              .fontWeight(Const.FONT_WEIGHT_500)
              .fontColor(this.getSelectedWeekDayIndex() === index ?
                $r('app.color.blueColor') : $r('app.color.titleColor'))
              .fontFamily($r('app.string.HarmonyHeiTi_Medium'))
              .opacity(Const.OPACITY_6)
              .onClick(() => {
                if (index !== undefined) {
                  this.onWeekLabelClick(index);
                }
              })
          }, (title: string, index?: number) => `${title}_${index}`)
        }
        .width(Const.THOUSANDTH_1000)
        .margin({ top: $r('app.float.default_8') })

        Scroll(this.scroller) {
          Row() {
            ForEach(this.homeStore.dateArr, (item: WeekDateModel, index?: number) => {
              Column() {
                Divider()
                  .margin({ bottom: $r('app.float.default_4') })
                  .width($r('app.float.default_12'))
                  .color(sameDate(item.date, this.homeStore.showDate) ? $r('app.color.blueColor') : $r('app.color.white'))
                Image(this.getProgressImg(item))
                  .height($r('app.float.default_28'))
                  .objectFit(ImageFit.Contain)
                  .margin({ top: Const.THOUSANDTH_80 })
              }
              .width(`${WEEK_DAY_WIDTH}%`)
              .justifyContent(FlexAlign.SpaceBetween)
              .onClick(() => this.homeStore.setSelectedShowDate(item.date.getTime()))
            })
          }
        }
        .scrollBar(BarState.Off)
        .scrollable(ScrollDirection.Horizontal)
        .width(Const.THOUSANDTH_1000)
        .onScrollStop(() => this.onScrollEndAction())
        .onScrollEdge((event) => this.onScrollEdgeAction(event))
      }
      .borderRadius($r('app.float.default_24'))
      .backgroundColor($r('app.color.white'))
      .width(Const.THOUSANDTH_1000)
      .height(Const.THOUSANDTH_1000)
      .padding({ top: Const.THOUSANDTH_50, bottom: Const.THOUSANDTH_120 })

    }
    .width(Const.THOUSANDTH_1000)
    .height(Const.THOUSANDTH_420)
    .padding(Const.THOUSANDTH_33)
  }

  getSelectedWeekDayIndex(): number {
    let selectedDate = new Date(this.homeStore.showDate);
    let dayOfWeek = selectedDate.getDay();
    return dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  }

  onScrollEndAction() {
    if (this.isPageScroll === false) {
      let page = Math.round(this.scroller.currentOffset().xOffset / this.scrollWidth);
      page = (this.isLoadMore === true) ? page + 1 : page;
      if (this.scroller.currentOffset().xOffset % this.scrollWidth != 0 || this.isLoadMore === true) {
        let xOffset = page * this.scrollWidth;
        this.scroller.scrollTo({ xOffset, yOffset: 0 } as ScrollTo);
        this.isLoadMore = false;
      }
      this.currentPage = this.homeStore.dateArr.length / Const.WEEK_DAY_NUM - page - 1;
      Logger.info('HomeIndex', 'onScrollEnd: page ' + page + ', listLength ' + this.homeStore.dateArr.length);
      let dayModel: WeekDateModel = this.homeStore.dateArr[Const.WEEK_DAY_NUM * page + this.homeStore.selectedDay];
      Logger.info('HomeIndex', 'currentItem: ' + JSON.stringify(dayModel) + ', selectedDay  ' + this.homeStore.selectedDay);
      this.homeStore!.setSelectedShowDate(dayModel!.date!.getTime());
    }
    this.isPageScroll = false;
  }

  onScrollEdgeAction(side: Edge) {
    if (side === Edge.Top && this.isPageScroll === false) {
      Logger.info('HomeIndex', 'onScrollEdge: currentPage ' + this.currentPage);
      if ((this.currentPage + 2) * Const.WEEK_DAY_NUM >= this.homeStore.dateArr.length) {
        Logger.info('HomeIndex', 'onScrollEdge: load more data');
        let date: Date = new Date(this.homeStore.showDate);
        this.homeStore.getPreWeekData(date, () => {});
        this.isLoadMore = true;
      }
    }
  }
}
