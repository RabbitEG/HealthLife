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

import { ITaskItem } from '../model/TaskInitList';
import TaskList from '../view/task/TaskListComponent';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { getAllTask, taskIndexDataInit, taskOriginData } from '../viewmodel/TaskViewModel';
import TaskInfo from '../viewmodel/TaskInfo';
import router from '@ohos.router';
import TaskInfoApi from '../common/database/tables/TaskInfoApi';

@Entry
@Component
@Preview
struct TaskIndex {
  @Provide taskList: ITaskItem[] = taskOriginData;

  updateTaskList(taskData: TaskInfo[]): void {
    let deepCopyDataStr = JSON.stringify(this.taskList);
    let deepCopyData: ITaskItem[] = JSON.parse(deepCopyDataStr);
    this.taskList = taskIndexDataInit(deepCopyData, taskData);
  }

  onPageShow() {
    const routeParams = (router.getParams() || {}) as Record<string, Object>;
    const targetDate = routeParams.targetDate ? routeParams.targetDate as string : '';
    if (targetDate) {
      // The add list must reflect the selected day's enabled state, not today's
      // global state, otherwise an already-open label can prevent a past-day add.
      TaskInfoApi.query(targetDate, false, (res: TaskInfo[]) => {
        this.updateTaskList(res);
      });
      return;
    }
    getAllTask().then((res: TaskInfo[]) => {
      this.updateTaskList(res);
    })
  }

  build() {
    Row() {
      Navigation() {
        Column() {
          TaskList()
        }
        .width(Const.THOUSANDTH_1000)
        .justifyContent(FlexAlign.Center)
      }
      .size({ width: Const.THOUSANDTH_1000, height: Const.THOUSANDTH_1000 })
      .title(Const.ADD_TASK_TITLE)
      .titleMode(NavigationTitleMode.Mini)
    }
    .backgroundColor($r('app.color.primaryBgColor'))
    .height(Const.THOUSANDTH_1000)
  }
}
