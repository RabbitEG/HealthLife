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

import prompt from '@system.prompt';
import { ITaskItem } from '../../model/TaskInitList';
import { frequencyRange } from '../../common/utils/Utils';
import { returnTimeStamp, createDrinkRange, formatTime } from '../../viewmodel/TaskViewModel';
import { TaskTypeEnum } from '../../viewmodel/TaskInfo';
import { CommonConstants as Const } from '../..//common/constants/CommonConstants';
import { FrequencyContentType } from '../../model/TaskInitList';

@CustomDialog
export struct TargetSettingDialog {
  @Consume settingParams: ITaskItem;
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  drinkRange: string[] = createDrinkRange();
  countRange: string[] = ['1 次', '2 次', '3 次'];
  runRange: string[] = ['0.5 公里', '1 公里', '1.5 公里', '2 公里', '3 公里', '5 公里', '10 公里'];
  durationRange: string[] = ['5 分钟', '10 分钟', '15 分钟', '20 分钟', '30 分钟', '45 分钟', '60 分钟', '90 分钟', '120 分钟'];
  stepRange: string[] = ['1000 步', '3000 步', '5000 步', '8000 步', '10000 步', '15000 步', '20000 步'];
  hourRange: string[] = ['1 小时', '2 小时', '4 小时', '6 小时', '7 小时', '8 小时', '9 小时', '10 小时', '12 小时'];
  genericRange: string[] = ['1 次', '2 次', '3 次', '4 次', '5 次', '6 次', '7 次', '8 次', '9 次', '10 次'];
  currentValue: string = this.settingParams.targetValue;
  currentTime: string = this.settingParams.taskType === TaskTypeEnum.TIME_POINT ?
    this.settingParams.targetValue : Const.DEFAULT_TIME;

  isLimitedCountTask(): boolean {
    return this.settingParams?.taskName === Const.BRUSH_TEETH_TASK_NAME ||
      this.settingParams?.taskName === Const.SMILE_TASK_NAME;
  }

  getTargetRange(): string[] {
    if (this.isLimitedCountTask()) {
      return this.countRange;
    }
    if (this.settingParams?.unit === '公里') {
      return this.runRange;
    }
    if (this.settingParams?.unit === 'mL') {
      return this.drinkRange;
    }
    if (this.settingParams?.unit === '分钟') {
      return this.durationRange;
    }
    if (this.settingParams?.unit === '步') {
      return this.stepRange;
    }
    if (this.settingParams?.unit === '小时') {
      return this.hourRange;
    }
    return this.genericRange;
  }

  getSelectedIndex(): number {
    const range = this.getTargetRange();
    const index = range.findIndex((item: string) => item.split(' ')[0] === this.settingParams?.targetValue);
    return index < 0 ? 0 : index;
  }

  compareTime(startTime: string, endTime: string) {
    if (returnTimeStamp(this.currentTime) < returnTimeStamp(startTime) ||
    returnTimeStamp(this.currentTime) > returnTimeStamp(endTime)) {
      prompt.showToast({
        message: Const.CHOOSE_TIME_OUT_RANGE
      })
      return false;
    }
    return true;
  }

  setTargetValue() {
    if (this.settingParams?.taskType === TaskTypeEnum.TIME_POINT) {
      if (!this.compareTime(Const.SLEEP_EARLY_TIME, Const.SLEEP_LATE_TIME)) {
        return;
      }
      this.settingParams.targetValue = this.currentTime;
      return;
    }
    this.settingParams.targetValue = this.currentValue;
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.target_setting')).fontSize(Const.DEFAULT_20).margin({ right: Const.DEFAULT_12 })
        Text(this.settingParams?.taskType === TaskTypeEnum.TIME_POINT ?
        Const.SLEEP_TIME_RANGE : '')
          .fontSize(Const.DEFAULT_16)
      }
      .width(Const.THOUSANDTH_1000)
      .justifyContent(FlexAlign.Start)

      if (this.settingParams?.taskType === TaskTypeEnum.TIME_POINT) {
        TimePicker({
          selected: new Date(`${new Date().toDateString()} ${this.currentTime}:00`),
        })
          .height(Const.THOUSANDTH_800)
          .useMilitaryTime(true)
          .onChange((value: TimePickerResult) => {
            this.currentTime = formatTime(value);
          })
      } else {
        TextPicker({ range: this.getTargetRange(), selected: this.getSelectedIndex() })
          .width(Const.THOUSANDTH_900,)
          .height(Const.THOUSANDTH_800,)
          .onChange((value) => {
            this.currentValue =  (value as string)?.split(' ')[0];
          })
      }

      Row() {
        Text($r('app.string.cancel')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.currentTime = Const.DEFAULT_TIME;
            this.currentValue = '';
            this.controller.close();
          })

        Text($r('app.string.confirm')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.setTargetValue();
            this.controller.close();
          })
      }
      .justifyContent(FlexAlign.SpaceAround)
      .width(Const.THOUSANDTH_1000)
      .height(Const.DEFAULT_28)
      .margin({ bottom: Const.DEFAULT_20 })
    }
    .justifyContent(FlexAlign.Center)
    .height(Const.THOUSANDTH_560)
    .padding(Const.DEFAULT_12)
  }
}

@CustomDialog
export struct RemindTimeDialog {
  @Consume settingParams: ITaskItem;
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  currentTime: string = this.settingParams.startTime || Const.DEFAULT_TIME;

  build() {
    Column() {
      Column() {
        Text($r('app.string.remind_time'))
          .fontSize(Const.DEFAULT_20)
          .margin({ top: Const.DEFAULT_10 })
          .width(Const.THOUSANDTH_1000)
          .textAlign(TextAlign.Start)
      }
      .width(Const.THOUSANDTH_900)

      TimePicker({
        selected: new Date(`${new Date().toDateString()} ${this.currentTime}:00`),
      })
        .height(Const.THOUSANDTH_800)
        .useMilitaryTime(true)
        .onChange((value: TimePickerResult) => {
          this.currentTime = formatTime(value);
        })

      Row() {
        Text($r('app.string.cancel')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.currentTime = Const.DEFAULT_TIME;
            this.controller.close();
          })

        Text($r('app.string.confirm')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.settingParams.startTime = this.currentTime;
            this.controller.close();
          })
      }
      .justifyContent(FlexAlign.SpaceAround)
      .width(Const.THOUSANDTH_1000)
      .height(Const.DEFAULT_28)
      .margin({ bottom: Const.DEFAULT_20 })
    }
    .justifyContent(FlexAlign.Center)
    .height(Const.THOUSANDTH_560)
    .padding(Const.DEFAULT_12)
  }
}

@CustomDialog
export struct FrequencyDialog {
  @Consume settingParams: ITaskItem;
  @Consume frequency: string;
  private controller: CustomDialogController = new CustomDialogController({ builder: '' });
  private currentFrequency: string = Const.EVERYDAY;
  private frequencyChooseRange: FrequencyContentType[] = frequencyRange();

  aboutToAppear() {
    const frequencyIds: number[] = this.settingParams?.frequency === '' ? [] :
      this.settingParams.frequency.split(',').map((item: string) => Number(item.trim()));
    this.frequencyChooseRange.forEach((item: FrequencyContentType) => {
      item.isChecked = frequencyIds.length === 0 || frequencyIds.indexOf(item.id) >= 0;
    });
    this.currentFrequency = this.frequency;
  }

  setFrequency() {
    const checkedArr = this.frequencyChooseRange.filter((item) => item?.isChecked)
    if (checkedArr.length === this.frequencyChooseRange.length || checkedArr.length === Const.NO_LENGTH) {
      this.currentFrequency = Const.EVERYDAY;
      this.settingParams.frequency = Const.INIT_WEEK_IDS;
      return;
    }
    this.currentFrequency = checkedArr.reduce((sum, current) => {
      return sum + ' ' + current?.label;
    }, '')
    this.settingParams.frequency = checkedArr.reduce((sum, current) => {
      return sum === '' ? sum + current?.id : sum + ',' + current?.id;
    }, '')
  }

  build() {
    Column() {
      Column() {
        Text($r('app.string.set_your_frequency'))
          .fontSize(Const.DEFAULT_20)
          .margin({ top: Const.DEFAULT_10 })
          .width(Const.THOUSANDTH_1000)
          .textAlign(TextAlign.Start)
      }
      .width(Const.THOUSANDTH_900)

      List() {
        ForEach(this.frequencyChooseRange, (item: FrequencyContentType) => {
          ListItem() {
            Row() {
              Text(item?.label).fontSize(Const.DEFAULT_20)
              Toggle({ type: ToggleType.Checkbox, isOn: item.isChecked })
                .onChange((isOn) => {
                  item.isChecked = isOn;
                })
            }
            .width(Const.THOUSANDTH_1000)
            .justifyContent(FlexAlign.SpaceBetween)
            .height(Const.DEFAULT_60)
          }
        }, (item: FrequencyContentType) => JSON.stringify(item))
      }
      .divider({
        strokeWidth: Const.DEFAULT_2,
        color: $r('app.color.btnBgColor')
      })
      .flexGrow(1)
      .padding(Const.DEFAULT_12)
      .width(Const.THOUSANDTH_1000)

      Row() {
        Text($r('app.string.cancel')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.controller.close();
          })

        Text($r('app.string.confirm')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.setFrequency();
            this.frequency = this.currentFrequency;
            this.controller.close();
          })
      }
      .justifyContent(FlexAlign.SpaceAround)
      .width(Const.THOUSANDTH_900)
      .height(Const.DEFAULT_28)
      .margin({ bottom: Const.DEFAULT_16 })
    }
    .justifyContent(FlexAlign.Center)
    .height(Const.THOUSANDTH_900)
    .padding(Const.DEFAULT_12)
  }
}
