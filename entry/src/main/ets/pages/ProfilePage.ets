import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import promptAction from '@ohos.promptAction';
import { router } from '@kit.ArkUI';
import ProfileStorage from '../common/utils/ProfileStorage';
import UserProfile from '../model/UserProfile';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { UserBaseInfo } from '../view/UserBaseInfo';
import { ListInfo } from '../view/ListInfo';
import { UserLevelInfo as UserLevelCard } from '../view/UserLevelInfo';
import Logger from '../common/utils/Logger';
import { queryUserLevel, UserLevelInfo } from '../viewmodel/UserLevelViewModel';

const PAGE_PADDING: number = 20;
const CARD_RADIUS: number = 18;
const EDITOR_HEIGHT: number = 48;

interface DefaultAvatarOption {
  id: string;
  label: string;
  image: Resource;
}

const DEFAULT_AVATARS: DefaultAvatarOption[] = [
  { id: 'male', label: '男生', image: $r('app.media.avatar_male') },
  { id: 'female', label: '女生', image: $r('app.media.avatar_female') },
  { id: 'health_01', label: '绿叶', image: $r('app.media.avatar_health_01') },
  { id: 'health_02', label: '水滴', image: $r('app.media.avatar_health_02') },
  { id: 'health_03', label: '牙刷', image: $r('app.media.avatar_health_03') },
  { id: 'health_04', label: '苹果', image: $r('app.media.avatar_health_04') },
  { id: 'health_05', label: '哑铃', image: $r('app.media.avatar_health_05') },
  { id: 'health_06', label: '跑鞋', image: $r('app.media.avatar_health_06') },
  { id: 'health_07', label: '瑜伽垫', image: $r('app.media.avatar_health_07') },
  { id: 'health_08', label: '微笑', image: $r('app.media.avatar_health_08') },
  { id: 'health_09', label: '月亮', image: $r('app.media.avatar_health_09') },
  { id: 'health_10', label: '阳光', image: $r('app.media.avatar_health_10') },
  { id: 'health_11', label: '闹钟', image: $r('app.media.avatar_health_11') },
  { id: 'health_12', label: '爱心', image: $r('app.media.avatar_health_12') },
  { id: 'health_13', label: '单车', image: $r('app.media.avatar_health_13') },
  { id: 'health_14', label: '沙拉', image: $r('app.media.avatar_health_14') },
  { id: 'health_15', label: '药瓶', image: $r('app.media.avatar_health_15') },
  { id: 'health_16', label: '鲜花', image: $r('app.media.avatar_health_16') }
];

@Component
export struct ProfilePage {
  @Prop @Watch('refreshLevel') refreshToken: number = 0;
  @State avatarUri: string = '';
  @State avatarId: string = '';
  @State nickname: string = Const.NICK_NAME;
  @State signature: string = Const.SIGNATURE;
  @State gender: string = '保密';
  @State birthDate: string = '1990-01-01';
  @State heightText: string = '170';
  @State weightText: string = '60';
  @State isSaving: boolean = false;
  @State isEditMode: boolean = false;
  @State showDetails: boolean = false;
  @State showAvatarPicker: boolean = false;
  @State level: number = 0;
  @State currentExperience: number = 0;
  @State completedTaskCount: number = 0;
  @StorageProp(Const.ALLOW_EDIT_PAST_KEY) allowEditPast: boolean = Const.ALLOW_EDIT_PAST_DEFAULT;
  private readonly genderOptions: string[] = ['男', '女', '保密'];
  private levelLoadId: number = 0;

  aboutToAppear(): void {
    this.loadProfile();
    this.loadLevel();
  }

  private refreshLevel(): void {
    this.loadLevel();
  }

  private loadLevel(): void {
    const loadId = ++this.levelLoadId;
    queryUserLevel().then((levelInfo: UserLevelInfo) => {
      if (loadId !== this.levelLoadId) {
        return;
      }
      this.level = levelInfo.level;
      this.currentExperience = levelInfo.currentExperience;
      this.completedTaskCount = levelInfo.completedTaskCount;
    }).catch((error: Error) => {
      Logger.error('ProfilePage', `load user level failed: ${JSON.stringify(error)}`);
    });
  }

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private async loadProfile(): Promise<void> {
    try {
      const profile = await ProfileStorage.load(this.getAbilityContext());
      this.avatarUri = profile.avatarUri;
      this.avatarId = profile.avatarId;
      this.nickname = profile.nickname;
      this.signature = profile.signature;
      this.gender = profile.gender;
      this.birthDate = profile.birthDate;
      this.heightText = profile.height.toString();
      this.weightText = profile.weight.toString();
    } catch (error) {
      promptAction.showToast({ message: '个人资料读取失败，请稍后重试' });
    }
  }

  private async chooseAvatar(): Promise<void> {
    if (!this.isEditMode) {
      return;
    }
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const result = await picker.select(options);
      if (result.photoUris.length === 0) {
        return;
      }
      const targetPath = `${this.getAbilityContext().filesDir}/profile_avatar_${Date.now()}.img`;
      // PhotoViewPicker returns a media URI rather than an application sandbox path.
      // Open the URI while the picker grant is valid, then copy through its file descriptor.
      const sourceFile = await fs.open(result.photoUris[0], fs.OpenMode.READ_ONLY);
      try {
        await fs.copyFile(sourceFile.fd, targetPath);
      } finally {
        await fs.close(sourceFile);
      }
      this.avatarUri = `file://${targetPath}`;
      this.avatarId = '';
      this.showAvatarPicker = false;
    } catch (error) {
      Logger.error('ProfilePage', `choose avatar failed: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: '未能选择头像' });
    }
  }

  private openAvatarPicker(): void {
    if (this.isEditMode) {
      this.showAvatarPicker = true;
    }
  }

  private selectDefaultAvatar(option: DefaultAvatarOption): void {
    if (!this.isEditMode) {
      return;
    }
    this.avatarUri = '';
    this.avatarId = option.id;
    this.showAvatarPicker = false;
  }

  private getDefaultAvatar(): Resource {
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

  private showBirthDatePicker(): void {
    if (!this.isEditMode) {
      return;
    }
    let selected = new Date(this.birthDate);
    if (Number.isNaN(selected.getTime())) {
      selected = new Date(1990, 0, 1);
    }
    DatePickerDialog.show({
      start: new Date(1900, 0, 1),
      end: new Date(),
      selected: selected,
      lunar: false,
      onDateAccept: (value: Date) => {
        this.birthDate = this.formatDate(value);
      }
    });
  }

  private formatDate(value: Date): string {
    const month = (value.getMonth() + 1).toString().padStart(2, '0');
    const day = value.getDate().toString().padStart(2, '0');
    return `${value.getFullYear()}-${month}-${day}`;
  }

  private isValid(): boolean {
    const heightValue = Number(this.heightText);
    const weightValue = Number(this.weightText);
    if (this.nickname.trim().length === 0) {
      promptAction.showToast({ message: '请输入昵称' });
      return false;
    }
    if (!Number.isFinite(heightValue) || heightValue < 50 || heightValue > 250) {
      promptAction.showToast({ message: '身高请输入 50–250 cm' });
      return false;
    }
    if (!Number.isFinite(weightValue) || weightValue < 20 || weightValue > 300) {
      promptAction.showToast({ message: '体重请输入 20–300 kg' });
      return false;
    }
    return true;
  }

  private async saveProfile(): Promise<void> {
    if (this.isSaving || !this.isValid()) {
      return;
    }
    this.isSaving = true;
    const profile = new UserProfile();
    profile.avatarUri = this.avatarUri;
    profile.avatarId = this.avatarId;
    profile.nickname = this.nickname.trim();
    profile.signature = this.signature.trim();
    profile.gender = this.gender;
    profile.birthDate = this.birthDate;
    profile.height = Number(this.heightText);
    profile.weight = Number(this.weightText);
    try {
      await ProfileStorage.save(this.getAbilityContext(), profile);
      this.nickname = profile.nickname;
      this.signature = profile.signature;
      this.gender = profile.gender;
      this.isEditMode = false;
      promptAction.showToast({ message: '个人资料已保存' });
    } catch (error) {
      promptAction.showToast({ message: '保存失败，请稍后重试' });
    } finally {
      this.isSaving = false;
    }
  }

  getBmi(): string {
    const h = Number(this.heightText) / 100;
    const w = Number(this.weightText);
    if (!h || !w || h <= 0) {
      return '--';
    }
    const bmi = w / (h * h);
    return bmi.toFixed(1);
  }

  getBmiLevel(): string {
    const bmi = Number(this.getBmi());
    if (bmi < 18.5) {
      return '偏瘦';
    }
    if (bmi < 24) {
      return '正常';
    }
    if (bmi < 28) {
      return '偏胖';
    }
    return '肥胖';
  }

  @Builder
  private SectionTitle(title: string) {
    Text(title)
      .width('100%')
      .fontSize(14)
      .fontColor('#7A818A')
      .margin({ top: 18, bottom: 8, left: 4 })
  }

  @Builder
  private buildDetails(): void {
    Column() {
      Row() {
        Text('‹')
          .fontSize(34)
          .fontColor('#007DFF')
          .onClick(() => {
            if (this.isEditMode) {
              this.isEditMode = false;
              this.loadProfile();
            }
            this.showDetails = false;
          })
        Text('个人资料')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .margin({ left: 8 })
        Blank()
        if (this.isEditMode) {
          Text('取消')
            .fontSize(16)
            .fontColor('#007DFF')
            .onClick(() => {
              this.isEditMode = false;
              this.loadProfile();
            })
        } else {
          Text('编辑')
            .fontSize(16)
            .fontColor('#007DFF')
            .onClick(() => {
              this.isEditMode = true;
            })
        }
      }
      .width('100%')
      .margin({ top: 14, bottom: 12 })

      Scroll() {
        Column() {
          Column() {
            Stack({ alignContent: Alignment.BottomEnd }) {
              if (this.avatarUri.length > 0) {
                Image(this.avatarUri)
                  .width(92)
                  .height(92)
                  .borderRadius(46)
                  .objectFit(ImageFit.Cover)
              } else {
                Image(this.getDefaultAvatar())
                  .width(92)
                  .height(92)
                  .borderRadius(46)
                  .objectFit(ImageFit.Cover)
              }
              if (this.isEditMode) {
                Text('✎')
                  .width(30)
                  .height(30)
                  .textAlign(TextAlign.Center)
                  .fontSize(17)
                  .fontColor(Color.White)
                  .backgroundColor('#007DFF')
                  .borderRadius(15)
                  .border({ width: 2, color: Color.White })
              }
            }
            .onClick(() => this.openAvatarPicker())

            if (this.isEditMode) {
              Text('选择头像')
                .fontSize(13)
                .fontColor('#007DFF')
                .margin({ top: 10 })
                .onClick(() => this.openAvatarPicker())
            }
          }
          .width('100%')
          .padding({ top: 22, bottom: 20 })
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)

          this.SectionTitle('基本信息')
          Column() {
            if (this.isEditMode) {
              Column() {
                Text('昵称')
                  .fontSize(14)
                  .fontColor('#5E6670')
                  .width('100%')
              TextInput({ text: this.nickname, placeholder: '请输入昵称' })
                  .height(EDITOR_HEIGHT)
                  .fontSize(17)
                  .fontColor('#182431')
                  .backgroundColor(Color.Transparent)
                  .padding({ left: 0, right: 0 })
                  .maxLength(20)
                  .onChange((value: string) => {
                  this.nickname = value;
                  })
              }

              Divider().color('#EEF0F2')

              Column() {
                Text('个性签名')
                  .fontSize(14)
                  .fontColor('#5E6670')
                  .width('100%')
                TextInput({ text: this.signature, placeholder: '请输入一句话介绍自己' })
                  .height(EDITOR_HEIGHT)
                  .fontSize(17)
                  .fontColor('#182431')
                  .backgroundColor(Color.Transparent)
                  .padding({ left: 0, right: 0 })
                  .maxLength(40)
                  .onChange((value: string) => {
                    this.signature = value;
                  })
              }

              Divider().color('#EEF0F2')

              Column() {
                Text('性别')
                  .fontSize(14)
                  .fontColor('#5E6670')
                  .width('100%')
                  .margin({ top: 14, bottom: 10 })
                Row({ space: 10 }) {
                  ForEach(this.genderOptions, (item: string) => {
                    Text(item)
                      .layoutWeight(1)
                      .height(38)
                      .textAlign(TextAlign.Center)
                      .fontSize(15)
                      .fontColor(this.gender === item ? Color.White : '#5E6670')
                      .backgroundColor(this.gender === item ? '#007DFF' : '#F1F3F5')
                      .borderRadius(19)
                      .onClick(() => {
                        this.gender = item;
                      })
                  }, (item: string) => item)
                }
                .width('100%')
                .margin({ bottom: 16 })
              }

              Divider().color('#EEF0F2')

              Row() {
                Column() {
                  Text('出生日期')
                    .fontSize(14)
                    .fontColor('#5E6670')
                  Text(this.birthDate)
                    .fontSize(17)
                    .fontColor('#182431')
                    .margin({ top: 6 })
                }
                .alignItems(HorizontalAlign.Start)
                Text('›')
                  .fontSize(28)
                  .fontColor('#9AA0A7')
              }
              .width('100%')
              .height(68)
              .justifyContent(FlexAlign.SpaceBetween)
              .onClick(() => this.showBirthDatePicker())
            } else {
              Row() {
                Text('昵称')
                  .fontSize(14)
                  .fontColor('#5E6670')
                Text(this.nickname)
                  .fontSize(17)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(52)
              .justifyContent(FlexAlign.SpaceBetween)

              Divider().color('#EEF0F2')

              Row() {
                Text('个性签名')
                  .fontSize(14)
                  .fontColor('#5E6670')
                Text(this.signature.length > 0 ? this.signature : '未设置')
                  .fontSize(17)
                  .fontColor('#182431')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(52)
              .justifyContent(FlexAlign.SpaceBetween)

              Divider().color('#EEF0F2')

              Row() {
                Text('性别')
                  .fontSize(14)
                  .fontColor('#5E6670')
                Text(this.gender)
                  .fontSize(17)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(52)
              .justifyContent(FlexAlign.SpaceBetween)

              Divider().color('#EEF0F2')

              Row() {
                Text('出生日期')
                  .fontSize(14)
                  .fontColor('#5E6670')
                Text(this.birthDate)
                  .fontSize(17)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(52)
              .justifyContent(FlexAlign.SpaceBetween)
            }
          }
          .width('100%')
          .padding({ left: 18, right: 18 })
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)

          this.SectionTitle('身体数据')
          Column() {
            if (this.isEditMode) {
              Row() {
                Text('身高')
                  .fontSize(16)
                  .fontColor('#182431')
                Row() {
                  TextInput({ text: this.heightText, placeholder: '170' })
                    .width(90)
                    .height(EDITOR_HEIGHT)
                    .textAlign(TextAlign.End)
                    .fontSize(17)
                    .type(InputType.NUMBER_DECIMAL)
                    .backgroundColor(Color.Transparent)
                    .onChange((value: string) => {
                      this.heightText = value;
                    })
                  Text('cm').fontSize(14).fontColor('#7A818A')
                }
              }
              .width('100%')
              .height(60)
              .justifyContent(FlexAlign.SpaceBetween)

              Divider().color('#EEF0F2')

              Row() {
                Text('体重')
                  .fontSize(16)
                  .fontColor('#182431')
                Row() {
                  TextInput({ text: this.weightText, placeholder: '60' })
                    .width(90)
                    .height(EDITOR_HEIGHT)
                    .textAlign(TextAlign.End)
                    .fontSize(17)
                    .type(InputType.NUMBER_DECIMAL)
                    .backgroundColor(Color.Transparent)
                    .onChange((value: string) => {
                      this.weightText = value;
                    })
                  Text('kg').fontSize(14).fontColor('#7A818A')
                }
              }
              .width('100%')
              .height(60)
              .justifyContent(FlexAlign.SpaceBetween)
            } else {
              Row() {
                Text('身高')
                  .fontSize(14)
                  .fontColor('#5E6670')
                Text(`${this.heightText} cm`)
                  .fontSize(17)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(52)
              .justifyContent(FlexAlign.SpaceBetween)

              Divider().color('#EEF0F2')

              Row() {
                Text('体重')
                  .fontSize(14)
                  .fontColor('#5E6670')
                Text(`${this.weightText} kg`)
                  .fontSize(17)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(52)
              .justifyContent(FlexAlign.SpaceBetween)

              Divider().color('#EEF0F2')

              Row() {
                Text('BMI')
                  .fontSize(14)
                  .fontColor('#5E6670')
                Text(`${this.getBmi()} (${this.getBmiLevel()})`)
                  .fontSize(17)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(52)
              .justifyContent(FlexAlign.SpaceBetween)
            }
          }
          .width('100%')
          .padding({ left: 18, right: 18 })
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)

          this.SectionTitle('设置')
          Column() {
            Row() {
              Column() {
                Text($r('app.string.allow_edit_past'))
                  .fontSize(16)
                  .fontColor('#182431')
                Text('开启后可修改过去日期的任务记录')
                  .fontSize(12)
                  .fontColor('#7A818A')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.allowEditPast })
                .selectedColor('#007DFF')
                .onChange((isOn: boolean) => {
                  AppStorage.SetOrCreate(Const.ALLOW_EDIT_PAST_KEY, isOn);
                })
            }
            .width('100%')
            .height(68)
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .padding({ left: 18, right: 18 })
          .backgroundColor(Color.White)
          .borderRadius(CARD_RADIUS)

          if (this.isEditMode) {
            Button(this.isSaving ? '保存中…' : '保存资料')
              .width('100%')
              .height(50)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(this.isSaving ? '#A7CFFF' : '#007DFF')
              .borderRadius(25)
              .margin({ top: 24, bottom: 28 })
              .enabled(!this.isSaving)
              .onClick(() => this.saveProfile())
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      if (this.showAvatarPicker) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .position({ x: 0, y: 0 })
          .zIndex(10)
          .onClick(() => this.showAvatarPicker = false)

        Column({ space: 14 }) {
          Row() {
            Text('选择头像')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
            Blank()
            Text('×')
              .fontSize(26)
              .fontColor('#7A818A')
              .onClick(() => this.showAvatarPicker = false)
          }
          .width('100%')

          Scroll() {
            Grid() {
              ForEach(DEFAULT_AVATARS, (option: DefaultAvatarOption) => {
                GridItem() {
                  Column({ space: 4 }) {
                    Image(option.image)
                      .width(48)
                      .height(48)
                      .borderRadius(24)
                      .objectFit(ImageFit.Contain)
                      .backgroundColor('#F1F3F5')
                    Text(option.label)
                      .fontSize(12)
                      .fontColor('#182431')
                  }
                  .width('100%')
                  .onClick(() => this.selectDefaultAvatar(option))
                }
              }, (option: DefaultAvatarOption) => option.id)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .rowsGap(8)
            .columnsGap(4)
          }
          .height(300)
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Vertical)

          Button('从图库选择')
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#007DFF')
            .borderRadius(23)
            .onClick(() => {
              this.showAvatarPicker = false;
              this.chooseAvatar();
            })
        }
        .width('90%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(20)
        .position({ x: '5%', y: '18%' })
        .zIndex(11)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: PAGE_PADDING, right: PAGE_PADDING })
    .backgroundColor('#F1F3F5')
  }

  @Builder
  private buildOverview(): void {
    Column() {
      UserBaseInfo({
        nickname: this.nickname,
        signature: this.signature.length > 0 ? this.signature : Const.SIGNATURE,
        avatarUri: this.avatarUri,
        avatarId: this.avatarId
      })

      UserLevelCard({
        level: this.level,
        currentExperience: this.currentExperience,
        completedTaskCount: this.completedTaskCount
      })

      ListInfo({
        onItemClick: (id: string) => {
          if (id === '1') {
            this.showDetails = true;
            this.isEditMode = false;
            this.loadProfile();
          } else if (id === '2') {
            promptAction.showToast({ message: '当前已经是最新版本' });
          } else {
            router.pushUrl({ url: 'pages/AboutPage' });
          }
        }
      })
    }
    .height(Const.FULL_HEIGHT)
    .backgroundColor($r('app.color.mineBgColor'))
  }

  build(): void {
    if (this.showDetails) {
      this.buildDetails()
    } else {
      this.buildOverview()
    }
  }
}
