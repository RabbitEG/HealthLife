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
import common from '@ohos.app.ability.common';
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
import MoodStorage, { MoodRecord } from '../common/utils/MoodStorage';

const WHITE_COLOR_0X = 255;
const MOOD_OPTIONS: string[] = ['开心 😊', '平静 😌', '一般 😐', '难过 😔', '生气 😡'];

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
  @Link moodRefreshToken: number;
  @State showMonthCalendar: boolean = false;
  @State showMoodPicker: boolean = false;
  @State selectedMood: string = '';
  @State moodNote: string = '';
  private scroller: Scroller = new Scroller();
  private yOffset: number = 0;

  @StorageProp(Const.ALLOW_EDIT_PAST_KEY) allowEditPast: boolean = Const.ALLOW_EDIT_PAST_DEFAULT;

  taskChange() {
    this.homeStore.updateTaskInfoList(this.editedTaskInfo).then((achievementInfo: AchievementInfo) => {
      this.showAchievement(achievementInfo);
    }).catch((error: Error) => {
      Logger.error('HomeIndex', `update task info failed: ${JSON.stringify(error)}`);
    });
  }

  showAchievement(achievementInfo: AchievementInfo): void {
    if (achievementInfo.showAchievement && achievementInfo.achievementLevel) {
      this.broadCast.emit(BroadCastType.SHOW_ACHIEVEMENT_DIALOG, achievementInfo.achievementLevel);
    }
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

  isFutureDate(): boolean {
    let today = new Date();
    today.setHours(0, 0, 0, 0);
    let selected = new Date(this.homeStore.showDate);
    selected.setHours(0, 0, 0, 0);
    return selected.getTime() > today.getTime();
  }

  canSetMood(): boolean {
    return !this.isFutureDate() && (!this.isPastDate() || this.allowEditPast);
  }

  openMoodPicker(): void {
    if (this.isFutureDate()) {
      promptAction.showToast({ message: '未来日期不能设置心情' });
      return;
    }
    if (this.isPastDate() && !this.allowEditPast) {
      promptAction.showToast({ message: $r('app.string.past_edit_disabled') });
      return;
    }
    const selectedDate = dateToStr(new Date(this.homeStore.showDate));
    MoodStorage.load(getContext(this) as common.UIAbilityContext, selectedDate)
      .then((record: MoodRecord) => {
        this.selectedMood = record.mood;
        this.moodNote = record.note;
        this.showMoodPicker = true;
      })
      .catch(() => {
        this.selectedMood = '';
        this.moodNote = '';
        this.showMoodPicker = true;
      });
  }

  saveMood(): void {
    if (this.selectedMood.length === 0) {
      promptAction.showToast({ message: '请先选择一种心情' });
      return;
    }
    const selectedDate = dateToStr(new Date(this.homeStore.showDate));
    MoodStorage.save(getContext(this) as common.UIAbilityContext, selectedDate, this.selectedMood, this.moodNote)
      .then(() => {
        this.showMoodPicker = false;
        this.moodRefreshToken += 1;
        promptAction.showToast({ message: '当天心情已保存' });
      })
      .catch(() => {
        promptAction.showToast({ message: '心情保存失败，请稍后重试' });
      });
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
      editTask.planStartDate = item.planStartDate;
      if (item.isRecurring) {
        editTask.repeatEnabled = true;
      } else if (item.planStartDate) {
        editTask.repeatEnabled = false;
      }
      router.pushUrl({ url: 'pages/TaskEditPage', params: { params: JSON.stringify(editTask) } });
    }
  }

  //confirm clockL
  onConfirm(task: TaskInfo, action: string = 'clock', inputVal: string = '') {
    this.homeStore.taskClock(task, action, inputVal).then((res: AchievementInfo) => {
      this.showAchievement(res);
    }).catch((error: Error) => {
      Logger.error('HomeIndex', `clock task failed: ${JSON.stringify(error)}`);
    });
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
      promptAction.showToast({ message: $r('app.string.past_task_edit_disabled') });
      return;
    }
    router.pushUrl({
      url: 'pages/TaskListPage',
      params: { targetDate: dateToStr(new Date(this.homeStore.showDate)) }
    }).catch((error: Error) => {
      Logger.error('HomeIndex', `open task list failed: ${JSON.stringify(error)}`);
    });
  }

  openAIDiagnosis(): void {
    router.pushUrl({ url: 'pages/AIDiagnosisPage' }).catch((error: Error) => {
      Logger.error('HomeIndex', `open AI diagnosis failed: ${JSON.stringify(error)}`);
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
      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Text('☺')
          .fontSize(Const.DEFAULT_20)
          .fontColor('#007DFF')
      }
      .width($r('app.float.default_48'))
      .height($r('app.float.default_48'))
      .backgroundColor(Color.White)
      .position({ x: Const.THOUSANDTH_830, y: Const.THOUSANDTH_800 })
      .zIndex(Const.HOME_BTN_Z)
      .onClick(() => this.openMoodPicker())
      Row() {
        Text($r('app.string.EntryAbility_label'))
          .fontSize($r('app.float.default_24'))
          .fontWeight(Const.FONT_WEIGHT_500)
          .fontFamily($r('app.string.HarmonyHeiTi_Medium'))
          .fontColor($r(`app.element.color.titleColor`))
          .padding({ left: Const.THOUSANDTH_66 })
        Blank()
        Button($r('app.string.ai_diagnosis'))
          .height(32)
          .fontSize(14)
          .fontWeight(Const.FONT_WEIGHT_500)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .borderRadius(18)
          .padding({ left: 14, right: 14 })
          .margin({ right: Const.THOUSANDTH_33 })
          .onClick(() => this.openAIDiagnosis())
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.DEFAULT_56)
      .position({ x: 0, y: 0 })
      .backgroundColor(`rgba(${WHITE_COLOR_0X},${WHITE_COLOR_0X},${WHITE_COLOR_0X},${this.naviAlpha})`)
      .zIndex(Const.HOME_BTN_Z)

      CustomDialogView()
      if (this.showMoodPicker) {
        Column({ space: Const.DEFAULT_12 }) {
          Row() {
            Text('设置当天心情')
              .fontSize(Const.DEFAULT_18)
              .fontWeight(Const.FONT_WEIGHT_700)
              .fontColor('#182431')
            Blank()
            Text('×')
              .fontSize(Const.DEFAULT_24)
              .fontColor('#7A818A')
              .onClick(() => this.showMoodPicker = false)
          }
          ForEach(MOOD_OPTIONS, (mood: string) => {
            Button(mood)
              .width(Const.FULL_WIDTH)
              .height(Const.DEFAULT_48)
              .fontSize(Const.DEFAULT_16)
              .fontColor('#182431')
              .backgroundColor(this.selectedMood === mood ? '#DCEEFF' : '#F1F3F5')
              .borderRadius(22)
              .onClick(() => this.selectedMood = mood)
          }, (mood: string) => mood)
          TextInput({ text: this.moodNote, placeholder: '用一句话记录这一天（可选）' })
            .width(Const.FULL_WIDTH)
            .height(Const.DEFAULT_48)
            .fontSize(Const.DEFAULT_14)
            .maxLength(80)
            .backgroundColor('#F1F3F5')
            .borderRadius(12)
            .onChange((value: string) => this.moodNote = value)
          Button('保存心情')
            .width(Const.FULL_WIDTH)
            .height(Const.DEFAULT_48)
            .fontSize(Const.DEFAULT_16)
            .fontColor(Color.White)
            .backgroundColor(this.selectedMood.length > 0 ? '#007DFF' : '#A7CFFF')
            .borderRadius(24)
            .enabled(this.selectedMood.length > 0)
            .onClick(() => this.saveMood())
        }
        .width('88%')
        .padding(Const.DEFAULT_20)
        .backgroundColor(Color.White)
        .borderRadius(20)
        .position({ x: '6%', y: '18%' })
        .zIndex(Const.HOME_BTN_Z + 2)
      }
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

