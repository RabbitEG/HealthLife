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

import { ACHIEVEMENT_LEVEL_LIST } from './TaskInitList';
import GlobalInfo from '../viewmodel/GlobalInfo';
import GlobalInfoApi from '../common/database/tables/GlobalInfoApi';

export const ACHIEVEMENT_LEVEL_KEY = 'AchievementLevelKey';

export function getAchievementLevel() {
  GlobalInfoApi.query((res: GlobalInfo) => {
    let globalInfo: GlobalInfo = res;

    let achievementStr = globalInfo.achievements??'';
    let achievements = achievementStr.split(',').filter((level: string) => level.length > 0);
    if (achievements.length > 0) {
      let highestLevel = 0;
      achievements.forEach((level: string) => {
        highestLevel = Math.max(highestLevel, Number(level));
      });
      AppStorage.Set<Number>(ACHIEVEMENT_LEVEL_KEY, highestLevel);
    }
  })

}

export function isReachNewAchievement(globalInfo: GlobalInfo): boolean {
  let achievementStr = globalInfo.achievements??'';
  let achievements = achievementStr.split(',');

  if (ACHIEVEMENT_LEVEL_LIST.indexOf(globalInfo.checkInDays) >= 0 && achievements.indexOf(String(globalInfo.checkInDays)) < 0) {
    return true;
  }
  return false;
}
