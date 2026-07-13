/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import HealthText from './HealthTextComponent';
import AddBtn from '../view/home/AddBtnComponent';
import { TaskCard } from '../view/home//TaskCardComponent';
import HomeTopView from '../view/home/HomeTopComponent';
import { CustomDialogView, CustomDialogCallback } from '../view/dialog/CustomDialogView';
import TaskInfo from '../viewmodel/TaskInfo';
import { HomeStore } from '../viewmodel/HomeViewModel';
import { ITaskItem, TaskMapById } from '../model/TaskInitList';
import { HealthDataSrcMgr } from '../common/utils/HealthDataSrcMgr';
import { BroadCast, BroadCastType } from '../common/utils/BroadCast';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import AchievementInfo from '../viewmodel/AchievementInfo';
import { MonthCalendarView } from './home/MonthCalendarComponent';
import Logger from '../common/utils/Logger';
import { dateToStr } from '../common/utils/Utils';

const WHITE_COLOR_0X = 255;

@Styles
function allSize() {
  .width(Const.THOUSANDTH_1000)
  .height(Const.THOUSANDTH_1000)
}

@Extend(Text)
function titleTextStyle() {
  .fontSize($r('app.float.default_16'))
  .fontWeight(Const.FONT_WEIGHT_500)
  .width(Const.THOUSANDTH_1000)
  .fontFamily($r('app.string.HarmonyHeiTi_Medium'))
  .fontColor($r(`app.element.color.titleColor`))
  .padding({
    top: Const.THOUSANDTH_15,
    bottom: Const.THOUSANDTH_15,
    left: Const.THOUSANDTH_33
  })
}

@Component
export default struct HomeIndex {
  @Provide broadCast: BroadCast = HealthDataSrcMgr.getInstance().getBroadCast();
  @State naviAlpha: number = 0;
  @ObjectLink homeStore: HomeStore;
  @Link editedTaskInfo: ITaskItem;
  @Link @Watch('taskChange') editedTaskID: string;
  @State showMonthCalendar: boolean = false;
  private scroller: Scroller = new Scroller();
  private yOffset: number = 0;

  @StorageProp(Const.ALLOW_EDIT_PAST_KEY) allowEditPast: boolean = Const.ALLOW_EDIT_PAST_DEFAULT;

  taskChange() {
    this.homeStore.updateTaskInfoList(this.editedTaskInfo);
  }

  isPastDate(): boolean {
    if (this.homeStore.checkCurrentDay()) {
      return false;
    }
    let today = new Date();
    today.setHours(0, 0, 0, 0);
    let selected = new Date(this.homeStore.showDate);
    selected.setHours(0, 0, 0, 0);
    return selected.getTime() < today.getTime();
  }

  taskItemAction(item: TaskInfo, isClick: boolean): void {
    if (this.isPastDate() && !this.allowEditPast) {
      return;
    }
    if (isClick) {
      // click to clock
      let callback: CustomDialogCallback = { confirmCallback: (taskTemp: TaskInfo, action: string, inputVal: string) => {
        this.onConfirm(taskTemp, action, inputVal)
      }, cancelCallback: () => {
      } };
      this.broadCast.emit(BroadCastType.SHOW_TASK_DETAIL_DIALOG, [item, callback]);
    } else {
      // edit task
      let editTaskStr: string = JSON.stringify(TaskMapById[item.taskID - 1]);
      let editTask: ITaskItem = JSON.parse(editTaskStr);
      editTask.targetValue = item?.targetValue;
      editTask.isAlarm = item.isAlarm;
      editTask.startTime = item.startTime;
      editTask.frequency = item.frequency;
      editTask.isOpen = item.isOpen;
      editTask.date = dateToStr(new Date(this.homeStore.showDate));
      router.pushUrl({ url: 'pages/TaskEditPage', params: { params: JSON.stringify(editTask) } });
    }
  }

  //confirm clockL
  onConfirm(task: TaskInfo, action: string = 'clock', inputVal: string = '') {
    this.homeStore.taskClock(task, action, inputVal).then((res: AchievementInfo) => {
      if (res.showAchievement) {
        let achievementLevel = res.achievementLevel;
        if (achievementLevel) {
          this.broadCast.emit(BroadCastType.SHOW_ACHIEVEMENT_DIALOG, achievementLevel);
        } else {
          this.broadCast.emit(BroadCastType.SHOW_ACHIEVEMENT_DIALOG);
        }
      }
    })
  }

  // change navigator alpha when scrolling the Scroll component
  onScrollAction() {
    this.yOffset = this.scroller.currentOffset().yOffset;
    if (this.yOffset > Const.DEFAULT_56) {
      this.naviAlpha = 1;
    } else {
      this.naviAlpha = this.yOffset / Const.DEFAULT_56;
    }
  }

  editTaskAction(): void {
    if (this.isPastDate() && !this.allowEditPast) {
      promptAction.showToast({ message: $r('app.string.past_edit_disabled') });
      return;
    }
    router.pushUrl({
      url: 'pages/TaskListPage',
      params: { targetDate: dateToStr(new Date(this.homeStore.showDate)) }
    }).catch((error: Error) => {
      Logger.error('HomeIndex', `open task list failed: ${JSON.stringify(error)}`);
    });
  }

  build() {
    Stack() {
      Scroll(this.scroller) {
        Column() {
          HomeTopView({
            homeStore: this.homeStore,
            openMonthAction: () => this.showMonthCalendar = true
          })
          Text($r('app.string.task_list')).titleTextStyle()
          if (this.homeStore.getTaskListOfDay().length > 0) {
            Column({ space: Const.DEFAULT_8 }) {
              ForEach(this.homeStore.getTaskListOfDay(), (item: TaskInfo) => {
                TaskCard({
                  taskInfoStr: JSON.stringify(item),
                  clickAction: (isClick: boolean) => this.taskItemAction(item, isClick)
                })
                  .margin({ bottom: Const.DEFAULT_12 })
                  .height($r('app.float.default_64'))
              }, (item: TaskInfo) => JSON.stringify(item))
            }
            .onAppear(() => {
              this.scroller.scrollTo({ xOffset: 0, yOffset: this.yOffset });
            })
            .padding({
              top: Const.THOUSANDTH_15,
              left: Const.THOUSANDTH_33,
              right: Const.THOUSANDTH_33
            })
            .width(Const.THOUSANDTH_1000)
          } else {
            Column({ space: Const.DEFAULT_8 }) {
              Image($r('app.media.ic_no_data'))
                .width($r('app.float.default_132'))
                .height($r('app.float.default_100'));
              HealthText({ title: '', titleResource: $r('app.string.no_task'), fontSize: $r('app.float.default_14') })
                .opacity(Const.OPACITY_4)
            }
            .margin({ top: Const.DEFAULT_48 })
          }
        }
      }
      .scrollBar(BarState.Off)
      .allSize()
      .onScroll(() => {
        this.onScrollAction()
      })
      .align(Alignment.TopStart)

      AddBtn({ clickAction: () => {
        this.editTaskAction()
      } })
      Row() {
        Text($r('app.string.EntryAbility_label'))
          .titleTextStyle()
          .fontSize($r('app.float.default_24'))
          .padding({ left: Const.THOUSANDTH_66 })
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.DEFAULT_56)
      .position({ x: 0, y: 0 })
      .backgroundColor(`rgba(${WHITE_COLOR_0X},${WHITE_COLOR_0X},${WHITE_COLOR_0X},${this.naviAlpha})`)

      CustomDialogView()
      if (this.showMonthCalendar) {
        MonthCalendarView({
          homeStore: this.homeStore,
          closeAction: () => this.showMonthCalendar = false
        })
          .position({ x: 0, y: 0 })
          .zIndex(Const.HOME_BTN_Z + 1)
      }
    }
    .allSize()
    .backgroundColor($r('app.color.primaryBgColor'))
  }
}

