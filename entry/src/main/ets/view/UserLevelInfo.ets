import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { EXPERIENCE_PER_LEVEL } from '../viewmodel/UserLevelViewModel';

@Component
export struct UserLevelInfo {
  @Prop level: number = 0;
  @Prop currentExperience: number = 0;
  @Prop completedTaskCount: number = 0;

  build() {
    Row() {
      Column({ space: Const.DEFAULT_12 }) {
        Row() {
          Text('等级')
            .fontSize($r('app.float.default_16'))
            .fontWeight(Const.FONT_WEIGHT_700)
            .fontColor($r('app.color.titleColor'))
          Blank()
          Text(`Lv${this.level}`)
            .fontSize($r('app.float.default_16'))
            .fontWeight(Const.FONT_WEIGHT_700)
            .fontColor($r('app.color.blueColor'))
            .padding({ left: Const.DEFAULT_12, right: Const.DEFAULT_12, top: 4, bottom: 4 })
            .borderRadius($r('app.float.default_12'))
            .backgroundColor('#E6F0FF')
        }
        .width(Const.FULL_WIDTH)

        Progress({
          value: this.currentExperience,
          total: EXPERIENCE_PER_LEVEL,
          style: ProgressStyle.Linear
        })
          .width(Const.FULL_WIDTH)
          .height($r('app.float.default_8'))
          .color($r('app.color.blueColor'))

        Row() {
          Text(`当前经验 ${this.currentExperience} / ${EXPERIENCE_PER_LEVEL}`)
            .fontSize($r('app.float.default_12'))
            .fontColor($r('app.color.signatureColor'))
          Blank()
          Text(`已完成 ${this.completedTaskCount} 个任务`)
            .fontSize($r('app.float.default_12'))
            .fontColor($r('app.color.signatureColor'))
        }
        .width(Const.FULL_WIDTH)
      }
      .layoutWeight(1)
      .padding(Const.DEFAULT_16)
      .borderRadius($r('app.float.default_16'))
      .backgroundColor($r('app.color.white'))
    }
    .width(Const.FULL_WIDTH)
    .padding({ left: Const.DEFAULT_24, right: Const.DEFAULT_24 })
    .margin({ top: Const.DEFAULT_24 })
  }
}
