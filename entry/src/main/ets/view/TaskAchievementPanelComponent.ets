import { CommonConstants as Const } from '../common/constants/CommonConstants';
import Logger from '../common/utils/Logger';
import { queryTaskAchievementItems } from '../viewmodel/AchievementViewModel';
import TaskAchievementInfo, { TaskAchievementMilestone } from '../viewmodel/TaskAchievementInfo';

@Component
export struct TaskAchievementPanel {
  @State achievementItems: TaskAchievementInfo[] = [];
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadAchievements();
  }

  loadAchievements() {
    this.isLoading = true;
    queryTaskAchievementItems().then((items: TaskAchievementInfo[]) => {
      this.achievementItems = items;
      this.isLoading = false;
    }).catch((error: Error) => {
      Logger.error('TaskAchievementPanel', `load achievement failed: ${JSON.stringify(error)}`);
      this.achievementItems = [];
      this.isLoading = false;
    });
  }

  @Builder
  milestoneBadge(milestone: TaskAchievementMilestone) {
    Column({ space: 4 }) {
      Text(milestone.unlocked ? '★' : '☆')
        .fontSize($r('app.float.default_28'))
        .fontColor(milestone.unlocked ? '#C99411' : $r('app.color.statusTipColor'))
      Text(`${milestone.multiple * 100}%`)
        .fontSize($r('app.float.default_12'))
        .fontWeight(Const.FONT_WEIGHT_700)
        .fontColor(milestone.unlocked ? $r('app.color.titleColor') : $r('app.color.statusTipColor'))
      Text(milestone.unlocked ? $r('app.string.achievement_unlocked') : $r('app.string.achievement_locked'))
        .fontSize($r('app.float.default_10'))
        .fontColor(milestone.unlocked ? '#A66D00' : $r('app.color.statusTipColor'))
    }
    .width($r('app.float.default_72'))
    .height($r('app.float.default_100'))
    .justifyContent(FlexAlign.Center)
    .borderRadius($r('app.float.default_16'))
    .border({
      width: $r('app.float.default_1'),
      color: milestone.unlocked ? '#E9BD55' : $r('app.color.borderColor')
    })
    .backgroundColor(milestone.unlocked ? $r('app.color.achievementUnlockedBg') : $r('app.color.achievementLockedBg'))
  }

  @Builder
  taskAchievementCard(item: TaskAchievementInfo) {
    Column({ space: Const.DEFAULT_12 }) {
      Row() {
        Column({ space: 4 }) {
          Text(item.taskName)
            .fontSize($r('app.float.default_16'))
            .fontWeight(Const.FONT_WEIGHT_700)
            .fontColor($r('app.color.titleColor'))
          Text(item.unlockedCount > 0 ?
            `累计达成 ${item.unlockedCount} 次目标（${item.totalPercent}%）` : '完成目标即可解锁首枚奖章')
            .fontSize($r('app.float.default_12'))
            .fontColor($r('app.color.statusTipColor'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(item.unlockedCount > 0 ? `×${item.unlockedCount}` : '待解锁')
          .fontSize($r('app.float.default_14'))
          .fontWeight(Const.FONT_WEIGHT_700)
          .fontColor(item.unlockedCount > 0 ? '#A66D00' : $r('app.color.statusTipColor'))
          .padding({ left: Const.DEFAULT_8, right: Const.DEFAULT_8, top: 4, bottom: 4 })
          .borderRadius($r('app.float.default_12'))
          .backgroundColor(item.unlockedCount > 0 ? $r('app.color.achievementUnlockedBg') :
            $r('app.color.achievementLockedBg'))
      }
      .width(Const.FULL_WIDTH)

      Scroll() {
        Row({ space: Const.DEFAULT_10 }) {
          ForEach(item.milestones, (milestone: TaskAchievementMilestone) => {
            this.milestoneBadge(milestone)
          }, (milestone: TaskAchievementMilestone) => `${item.taskID}-${milestone.multiple}`)
        }
      }
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Horizontal)
      .width(Const.FULL_WIDTH)
    }
    .width(Const.FULL_WIDTH)
    .padding(Const.DEFAULT_16)
    .borderRadius($r('app.float.default_16'))
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column({ space: Const.DEFAULT_12 }) {
      Row() {
        Text('单项任务奖章')
          .fontSize($r('app.float.default_20'))
          .fontWeight(Const.FONT_WEIGHT_700)
          .fontColor($r('app.color.white'))
        Blank()
        Text('每达成一次目标 +100%')
          .fontSize($r('app.float.default_12'))
          .fontColor($r('app.color.statusTipColor'))
      }
      .width(Const.FULL_WIDTH)

      if (this.isLoading) {
        Text('正在计算成就…')
          .fontSize($r('app.float.default_14'))
          .fontColor($r('app.color.statusTipColor'))
          .width(Const.FULL_WIDTH)
          .textAlign(TextAlign.Center)
          .padding(Const.DEFAULT_20)
      } else if (this.achievementItems.length === 0) {
        Text('添加并完成任务后，即可解锁对应的单项奖章')
          .fontSize($r('app.float.default_14'))
          .fontColor($r('app.color.statusTipColor'))
          .width(Const.FULL_WIDTH)
          .textAlign(TextAlign.Center)
          .padding(Const.DEFAULT_20)
      } else {
        ForEach(this.achievementItems, (item: TaskAchievementInfo) => {
          this.taskAchievementCard(item)
        }, (item: TaskAchievementInfo) => `${item.taskID}-${item.totalPercent}`)
      }
    }
    .width(Const.FULL_WIDTH)
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
      if (isVisible) {
        this.loadAchievements();
      }
    })
  }
}
