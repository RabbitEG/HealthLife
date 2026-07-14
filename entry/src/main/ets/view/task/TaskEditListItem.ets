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

import { ITaskItem } from '../../model/TaskInitList';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import { TaskTypeEnum } from '../../viewmodel/TaskInfo';

@Extend(Text) function targetSetCommon() {
  .fontSize(Const.DEFAULT_16)
  .flexGrow(1)
  .margin({ right: Const.DEFAULT_8 })
  .align(Alignment.End)
}

@Extend(Text) function targetSettingStyle(isOpen: boolean, taskName: string, taskType: number) {
  .fontColor(isOpen && taskType !== TaskTypeEnum.SUB_TASK ?
  $r('app.color.titleColor') :
  $r('app.color.disabledColor'))
}

@Extend(Text) function remindTimeStyle(isOpen: boolean, isAlarm: boolean) {
  .fontColor(isOpen && isAlarm ? $r('app.color.titleColor') : $r('app.color.disabledColor'))
}

@Extend(Text) function frequencyStyle(isOpen: boolean, isAlarm: boolean) {
  .fontSize(Const.DEFAULT_12)
  .flexGrow(1)
  .margin({ right: Const.DEFAULT_8 })
  .textAlign(TextAlign.End)
  .fontColor(isOpen && isAlarm ? $r('app.color.titleColor') : $r('app.color.disabledColor'))
}


@Component
export struct TaskChooseItem {
  @Consume settingParams: ITaskItem;

  build() {
    Row() {
      Text(this.settingParams.taskName).fontSize(Const.DEFAULT_20).fontWeight(FontWeight.Medium)
      Toggle({ type: ToggleType.Switch, isOn: this.settingParams.isOpen })
        .width(Const.DEFAULT_56)
        .height(Const.DEFAULT_32)
        .selectedColor($r('app.color.blueColor'))
        .onChange((isOn) => {
          this.settingParams.isOpen = isOn;
        })
    }
    .width(Const.THOUSANDTH_1000)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

@Component
export struct TargetSetItem {
  @Consume settingParams: ITaskItem;

  build() {
    Row() {
      Text($r('app.string.target_setting'))
        .fontSize(Const.DEFAULT_20)
        .fontWeight(FontWeight.Medium)

      Blank()
        .layoutWeight(1)
      if (this.settingParams?.unit === '') {
        Text(`${this.settingParams?.targetValue}`)
          .targetSetCommon()
          .targetSettingStyle(this.settingParams?.isOpen, this.settingParams?.taskName,
            this.settingParams?.taskType)
      } else {
        Text(`${this.settingParams?.targetValue} ${this.settingParams?.unit} ${Const.PER_DAY}`)
          .targetSetCommon()
          .targetSettingStyle(this.settingParams?.isOpen, this.settingParams?.taskName,
            this.settingParams?.taskType)
      }
      Image($r('app.media.ic_right_grey')).width(Const.DEFAULT_8).height(Const.DEFAULT_16);
    }
    .width(Const.THOUSANDTH_1000)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

@Component
export struct OpenRemindItem {
  @Consume settingParams: ITaskItem;
  @State alarmToggle: boolean = false;
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: RemindConfirmDialog({
      onAgree: () => {
        this.alarmToggle = true;
        this.settingParams.isAlarm = true;
      },
      onRefuse: () => {
        this.alarmToggle = false;
        this.settingParams.isAlarm = false;
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
    cancel: () => {
      this.alarmToggle = false;
      this.settingParams.isAlarm = false;
    }
  });

  aboutToAppear() {
    this.alarmToggle = this.settingParams?.isAlarm ?? false;
  }

  build() {
    Row() {
      Text($r('app.string.open_reminder'))
        .fontSize(Const.DEFAULT_20)
        .fontWeight(FontWeight.Medium)

      Toggle({ type: ToggleType.Switch, isOn: this.alarmToggle })
        .width(Const.DEFAULT_56)
        .height(Const.DEFAULT_32)
        .selectedColor($r('app.color.blueColor'))
        .onChange((isOn) => {
          if (isOn) {
            this.alarmToggle = true;
            this.dialogController.open();
          } else {
            this.alarmToggle = false;
            this.settingParams.isAlarm = false;
          }
        })
    }
    .width(Const.THOUSANDTH_1000)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

@CustomDialog
struct RemindConfirmDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  onAgree: () => void = () => {};
  onRefuse: () => void = () => {};

  build() {
    Column() {
      Text('开启提醒')
        .fontSize(Const.DEFAULT_20)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: Const.DEFAULT_16 })
      Text('开启提醒将连接日历或闹钟应用为您发送提醒通知，是否同意？')
        .fontSize(Const.DEFAULT_14)
        .margin({ bottom: Const.DEFAULT_24 })
      Row({ space: Const.DEFAULT_24 }) {
        Button('不同意')
          .fontSize(Const.DEFAULT_16)
          .fontColor($r('app.color.titleColor'))
          .backgroundColor($r('app.color.btnBgColor'))
          .layoutWeight(1)
          .onClick(() => {
            this.onRefuse();
            this.controller.close();
          })
        Button('同意')
          .fontSize(Const.DEFAULT_16)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.blueColor'))
          .layoutWeight(1)
          .onClick(() => {
            this.onAgree();
            this.controller.close();
          })
      }
      .width(Const.THOUSANDTH_1000)
    }
    .padding(Const.DEFAULT_24)
  }
}

@Component
export struct RemindTimeItem {
  @Consume settingParams: ITaskItem;

  build() {
    Row() {
      Text($r('app.string.remind_time')).fontSize(Const.DEFAULT_20).fontWeight(FontWeight.Medium)
      Blank()
        .layoutWeight(1)
      Text(this.settingParams?.startTime)
        .targetSetCommon()
        .remindTimeStyle(this.settingParams?.isOpen, this.settingParams?.isAlarm)
      Image($r('app.media.ic_right_grey')).width(Const.DEFAULT_8).height(Const.DEFAULT_16)
    }
    .width(Const.THOUSANDTH_1000)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

@Component
export struct FrequencyItem {
  @Consume settingParams: ITaskItem;
  @Consume frequency: string;

  build() {
    Row() {
      Text($r('app.string.frequency')).fontSize(Const.DEFAULT_20).fontWeight(FontWeight.Medium)
      Text(this.frequency)
        .targetSetCommon()
        .frequencyStyle(this.settingParams?.isOpen, this.settingParams?.isAlarm)
      Image($r('app.media.ic_right_grey')).width(Const.DEFAULT_8).height(Const.DEFAULT_16)
    }
    .width(Const.THOUSANDTH_1000)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

@Component
export struct EffectiveRangeItem {
  @Consume settingParams: ITaskItem;

  build() {
    Column({ space: Const.DEFAULT_8 }) {
      Text('生效范围')
        .fontSize(Const.DEFAULT_20)
        .fontWeight(FontWeight.Medium)
        .width(Const.THOUSANDTH_1000)
        .textAlign(TextAlign.Start)
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
        Text('仅所选日期')
          .fontSize(Const.DEFAULT_14)
          .fontColor(this.settingParams.repeatEnabled === false ? $r('app.color.white') : $r('app.color.titleColor'))
          .backgroundColor(this.settingParams.repeatEnabled === false ? $r('app.color.blueColor') : $r('app.color.btnBgColor'))
          .borderRadius(Const.DEFAULT_8)
          .padding({ left: Const.DEFAULT_12, right: Const.DEFAULT_12, top: Const.DEFAULT_8, bottom: Const.DEFAULT_8 })
          .margin({ right: Const.DEFAULT_8, bottom: Const.DEFAULT_8 })
          .onClick(() => {
            this.settingParams.repeatEnabled = false;
          })
        Text('从所选日期开始，按频率重复')
          .fontSize(Const.DEFAULT_14)
          .fontColor(this.settingParams.repeatEnabled !== false ? $r('app.color.white') : $r('app.color.titleColor'))
          .backgroundColor(this.settingParams.repeatEnabled !== false ? $r('app.color.blueColor') : $r('app.color.btnBgColor'))
          .borderRadius(Const.DEFAULT_8)
          .padding({ left: Const.DEFAULT_12, right: Const.DEFAULT_12, top: Const.DEFAULT_8, bottom: Const.DEFAULT_8 })
          .margin({ bottom: Const.DEFAULT_8 })
          .onClick(() => {
            this.settingParams.repeatEnabled = true;
            this.settingParams.planStartDate = this.settingParams.date || new Date().toDateString();
          })
      }
      .width(Const.THOUSANDTH_1000)
    }
    .width(Const.THOUSANDTH_1000)
  }
}
