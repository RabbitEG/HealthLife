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

@Component
export struct UserBaseInfo {
  @Prop nickname: string = '';
  @Prop signature: string = '';
  @Prop avatarUri: string = '';
  @Prop avatarId: string = '';

  getDefaultAvatar(): Resource {
    switch (this.avatarId) {
      case 'male':
        return $r('app.media.avatar_male');
      case 'female':
        return $r('app.media.avatar_female');
      case 'water':
        return $r('app.media.ic_task_water');
      case 'brush':
        return $r('app.media.ic_task_brush');
      case 'apple':
        return $r('app.media.ic_task_apple');
      case 'smile':
        return $r('app.media.ic_task_smile');
      case 'morning':
        return $r('app.media.ic_task_morning');
      case 'night':
        return $r('app.media.ic_task_night');
      case 'health_01':
        return $r('app.media.avatar_health_01');
      case 'health_02':
        return $r('app.media.avatar_health_02');
      case 'health_03':
        return $r('app.media.avatar_health_03');
      case 'health_04':
        return $r('app.media.avatar_health_04');
      case 'health_05':
        return $r('app.media.avatar_health_05');
      case 'health_06':
        return $r('app.media.avatar_health_06');
      case 'health_07':
        return $r('app.media.avatar_health_07');
      case 'health_08':
        return $r('app.media.avatar_health_08');
      case 'health_09':
        return $r('app.media.avatar_health_09');
      case 'health_10':
        return $r('app.media.avatar_health_10');
      case 'health_11':
        return $r('app.media.avatar_health_11');
      case 'health_12':
        return $r('app.media.avatar_health_12');
      case 'health_13':
        return $r('app.media.avatar_health_13');
      case 'health_14':
        return $r('app.media.avatar_health_14');
      case 'health_15':
        return $r('app.media.avatar_health_15');
      case 'health_16':
        return $r('app.media.avatar_health_16');
      default:
        return $r('app.media.ic_user');
    }
  }

  build() {
    Column() {
      // userIcon
      if (this.avatarUri.length > 0) {
        Image(this.avatarUri)
          .objectFit(ImageFit.Cover)
          .height($r('app.float.default_66'))
          .width($r('app.float.default_66'))
          .borderRadius(33)
          .border({ width: 2, color: '#E0E3E8' })
          .margin({ top: $r('app.float.default_71') })
      } else {
        Image(this.getDefaultAvatar())
          .objectFit(ImageFit.Cover)
          .height($r('app.float.default_66'))
          .width($r('app.float.default_66'))
          .borderRadius(33)
          .border({ width: 2, color: '#E0E3E8' })
          .margin({ top: $r('app.float.default_71') })
      }

      // nickname
      Text(this.nickname)
        .fontSize($r('app.float.default_20'))
        .fontFamily($r('app.string.Helvetica'))
        .margin({ top: $r('app.float.default_12'), bottom: $r('app.float.default_6') })
        .fontWeight(FontWeight.Normal)
        .fontColor($r('app.color.black'))

      // signature
      Text(this.signature).fontSize($r('app.float.default_16')).fontWeight(FontWeight.Normal)
        .fontFamily($r('app.string.PingFangSC_Regular'))
        .fontColor($r('app.color.signatureColor'))
    }
  }
}
