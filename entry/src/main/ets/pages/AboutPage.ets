import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import promptAction from '@ohos.promptAction';

const PAGE_PADDING: number = 20;
const CARD_RADIUS: number = 18;
const CARD_GAP: number = 12;
const ITEM_HEIGHT: number = 56;
const APP_VERSION: string = '0.6.0';
const GITHUB_URL: string = 'https://github.com/RabbitEG/HealthLife';
const PROJECT_URL: string = 'https://gitee.com/gudehe/healthy_-life';

@Entry
@Component
struct AboutPage {
  private openLink(url: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.openLink(url, { appLinkingOnly: false });
    } catch (error) {
      const err = error as BusinessError;
      promptAction.showToast({ message: `无法打开链接: ${err.message}` });
    }
  }

  @Builder
  private SectionTitle(title: ResourceStr) {
    Text(title)
      .width('100%')
      .fontSize(14)
      .fontColor('#7A818A')
      .margin({ top: 18, bottom: 8, left: 4 })
  }

  @Builder
  private InfoRow(label: ResourceStr, value: ResourceStr, clickable: boolean, action: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#5E6670')
      Text(value)
        .fontSize(17)
        .fontColor('#007DFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .margin({ left: 12 })
      if (clickable) {
        Text('›')
          .fontSize(28)
          .fontColor('#9AA0A7')
          .margin({ left: 4 })
      }
    }
    .width('100%')
    .height(ITEM_HEIGHT)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .onClick(() => action())
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(34)
          .fontColor('#007DFF')
          .onClick(() => {
            router.back();
          })
        Text($r('app.string.about_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 14, bottom: 12 })

      Scroll() {
        Column({ space: CARD_GAP }) {
          Column() {
            Image($r('app.media.app_icon'))
              .width(80)
              .height(80)
              .borderRadius(20)
              .margin({ top: 24 })
            Text('HealthLife')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
              .margin({ top: 14 })
            Text($r('app.string.about_app_desc'))
              .fontSize(14)
              .fontColor('#7A818A')
              .margin({ top: 6, bottom: 20 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)

          Column() {
            this.InfoRow($r('app.string.about_version'), `v${APP_VERSION}`, false, () => {})
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)

          Column() {
            this.InfoRow($r('app.string.about_author'), $r('app.string.about_author_name'), false, () => {})
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)

          Column() {
            this.InfoRow($r('app.string.about_project_name'), PROJECT_URL, true, () => {
              this.openLink(PROJECT_URL);
            })
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)

          Column() {
            this.InfoRow($r('app.string.about_github'), GITHUB_URL, true, () => {
              this.openLink(GITHUB_URL);
            })
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)

          Column() {
            Row() {
              Column() {
                Text($r('app.string.about_buy_coffee'))
                  .fontSize(16)
                  .fontColor('#182431')
                Text('☕')
                  .fontSize(28)
                  .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Center)
              .layoutWeight(1)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 20, bottom: 20 })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            promptAction.showToast({
              message: $r('app.string.about_sponsor_maintaining'),
              duration: 2500
            });
          })

          Row() {
            Text('© 2026 Chen Zhiyi. All rights reserved.')
              .fontSize(12)
              .fontColor('#B0B4BA')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 28, bottom: 16 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .padding({ left: PAGE_PADDING, right: PAGE_PADDING })
    .backgroundColor('#F1F3F5')
  }
}
