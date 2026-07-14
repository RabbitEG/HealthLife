import http from '@ohos.net.http';
import router from '@ohos.router';

const BRIDGE_URL: string = 'http://127.0.0.1:8787/chat';
const PAGE_PADDING: number = 16;
const BUBBLE_RADIUS: number = 18;
const USER_ROLE: string = 'user';
const ASSISTANT_ROLE: string = 'assistant';
const MAX_INPUT_LENGTH: number = 4000;

class ChatMessage {
  id: number;
  role: string;
  content: string;
  isLoading: boolean;
  isError: boolean;

  constructor(id: number, role: string, content: string, isLoading: boolean = false, isError: boolean = false) {
    this.id = id;
    this.role = role;
    this.content = content;
    this.isLoading = isLoading;
    this.isError = isError;
  }
}

class ChatRequestPayload {
  message: string;
  conversationId: string;

  constructor(message: string, conversationId: string) {
    this.message = message;
    this.conversationId = conversationId;
  }
}

class ChatResponsePayload {
  conversationId: string = '';
  reply: string = '';
  error: string = '';
}

@Entry
@Component
struct AIDiagnosisPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isGenerating: boolean = false;
  @State conversationId: string = '';
  private messageScroller: Scroller = new Scroller();
  private nextMessageId: number = 1;

  private scrollToBottom(): void {
    setTimeout(() => {
      if (this.messages.length > 0) {
        this.messageScroller.scrollToIndex(this.messages.length - 1, true, ScrollAlign.END);
      }
    }, 80);
  }

  private replaceMessage(id: number, content: string, isError: boolean = false): void {
    this.messages = this.messages.map((message: ChatMessage) => {
      if (message.id === id) {
        return new ChatMessage(id, ASSISTANT_ROLE, content, false, isError);
      }
      return message;
    });
    this.scrollToBottom();
  }

  private async requestReply(message: string): Promise<ChatResponsePayload> {
    const request = http.createHttp();
    try {
      const response = await request.request(BRIDGE_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        extraData: JSON.stringify(new ChatRequestPayload(message, this.conversationId)),
        connectTimeout: 10000,
        readTimeout: 180000
      });
      const rawResult = typeof response.result === 'string'
        ? response.result
        : JSON.stringify(response.result);
      let result = new ChatResponsePayload();
      if (rawResult.length > 0) {
        result = JSON.parse(rawResult) as ChatResponsePayload;
      }
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(result.error || `桥接服务返回错误 ${response.responseCode}`);
      }
      if (!result.reply || result.reply.trim().length === 0) {
        throw new Error('AI 返回了空回复');
      }
      return result;
    } finally {
      request.destroy();
    }
  }

  private sendMessage(): void {
    const content = this.inputText.trim();
    if (content.length === 0 || this.isGenerating) {
      return;
    }

    const userMessage = new ChatMessage(this.nextMessageId++, USER_ROLE, content);
    const loadingMessageId = this.nextMessageId++;
    const loadingMessage = new ChatMessage(loadingMessageId, ASSISTANT_ROLE, '', true);
    this.messages = this.messages.concat([userMessage, loadingMessage]);
    this.inputText = '';
    this.isGenerating = true;
    this.scrollToBottom();

    this.requestReply(content).then((response: ChatResponsePayload) => {
      this.conversationId = response.conversationId;
      this.replaceMessage(loadingMessageId, response.reply);
      this.isGenerating = false;
    }).catch((error: Error) => {
      const detail = error && error.message ? error.message : '未知错误';
      this.replaceMessage(
        loadingMessageId,
        `连接失败：${detail}\n请确认电脑已运行 DevEco GLM-5.1 桥接服务。`,
        true
      );
      this.isGenerating = false;
    });
  }

  @Builder
  private BubbleContent(message: ChatMessage) {
    Column() {
      Text(message.role === USER_ROLE ? $r('app.string.ai_user') : $r('app.string.ai_assistant'))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(message.role === USER_ROLE ? '#DCEEFF' : '#5E6670')
        .margin({ bottom: 6 })
      if (message.isLoading) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#007DFF')
          Text($r('app.string.ai_generating'))
            .fontSize(15)
            .fontColor('#5E6670')
        }
      } else {
        Text(message.content)
          .fontSize(16)
          .lineHeight(24)
          .fontColor(message.isError ? '#C9353F' :
            (message.role === USER_ROLE ? Color.White : '#182431'))
          .copyOption(CopyOptions.LocalDevice)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .constraintSize({ maxWidth: '82%' })
    .padding({ left: 15, right: 15, top: 11, bottom: 12 })
    .backgroundColor(message.isError ? '#FFF0F0' :
      (message.role === USER_ROLE ? '#007DFF' : '#FFFFFF'))
    .borderRadius(BUBBLE_RADIUS)
  }

  @Builder
  private MessageRow(message: ChatMessage) {
    Row() {
      if (message.role === USER_ROLE) {
        Blank()
        this.BubbleContent(message)
      } else {
        this.BubbleContent(message)
        Blank()
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(34)
          .fontColor('#007DFF')
          .onClick(() => router.back())
        Text($r('app.string.ai_chat_title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .margin({ left: 8 })
        Blank()
        Text('GLM-5.1')
          .fontSize(12)
          .fontColor('#007DFF')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#EAF4FF')
          .borderRadius(12)
      }
      .width('100%')
      .height(56)
      .padding({ left: PAGE_PADDING, right: PAGE_PADDING })
      .backgroundColor(Color.White)

      Row({ space: 8 }) {
        Text('ⓘ')
          .fontSize(16)
          .fontColor('#007DFF')
        Text($r('app.string.ai_disclaimer'))
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#5E6670')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 9, bottom: 9 })
      .backgroundColor('#EAF4FF')

      if (this.messages.length === 0) {
        Column({ space: 10 }) {
          Text('AI')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .width(58)
            .height(58)
            .textAlign(TextAlign.Center)
            .backgroundColor('#007DFF')
            .borderRadius(29)
          Text($r('app.string.ai_empty_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
          Text($r('app.string.ai_empty_desc'))
            .fontSize(14)
            .lineHeight(21)
            .fontColor('#7A818A')
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: 40, right: 40 })
      } else {
        List({ space: 12, scroller: this.messageScroller }) {
          ForEach(this.messages, (message: ChatMessage) => {
            ListItem() {
              this.MessageRow(message)
            }
          }, (message: ChatMessage) => `${message.id}`)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: PAGE_PADDING, right: PAGE_PADDING, top: 16, bottom: 16 })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }

      Row({ space: 10 }) {
        TextArea({ text: this.inputText, placeholder: $r('app.string.ai_input_hint') })
          .layoutWeight(1)
          .height(58)
          .maxLength(MAX_INPUT_LENGTH)
          .maxLines(4)
          .fontSize(15)
          .fontColor('#182431')
          .placeholderColor('#9AA0A7')
          .backgroundColor('#F1F3F5')
          .borderRadius(16)
          .padding({ left: 13, right: 13, top: 9, bottom: 9 })
          .enabled(!this.isGenerating)
          .onChange((value: string) => {
            this.inputText = value;
          })
        Button($r('app.string.ai_send'))
          .height(48)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(this.inputText.trim().length > 0 && !this.isGenerating ? '#007DFF' : '#A7CFFF')
          .borderRadius(24)
          .enabled(this.inputText.trim().length > 0 && !this.isGenerating)
          .onClick(() => this.sendMessage())
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
      .padding({ left: PAGE_PADDING, right: PAGE_PADDING, top: 10, bottom: 12 })
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
