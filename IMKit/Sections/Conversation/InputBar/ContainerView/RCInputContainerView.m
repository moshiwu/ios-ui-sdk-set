//
//  RCInputContainerView.m
//  RongIMKit
//
//  Created by 张改红 on 2020/5/26.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCInputContainerView.h"
#import "RCKitCommonDefine.h"
#import "RCChatSessionInputBarControl.h"
#import "RCExtensionService.h"
#import "RCKitConfig.h"
#import <Masonry/Masonry.h>

#define TextViewLineHeight 20.f              //输入框每行文字高度
#define TextViewSpaceHeight_LessThanMax 17.f //输入框小于最大行时除文字外上下空隙高度
#define TextViewSpaceHeight 13.f             //输入框大于等于最大行时除文字外上下空隙高度
#define TextViewRectY 7
#define TextViewMaxInputLines 6 //输入框最大行数设置
#define TextViewMinInputLines 1 //输入框最小行数设置
@interface RCInputContainerView ()<UITextViewDelegate, RCTextViewDelegate>
{
    BOOL _hideEmojiButton;
}
@property (nonatomic, strong) NSMutableArray *inputContainerSubViewConstraints;
@property (nonatomic, assign) BOOL textViewBeginEditing;
@property (nonatomic, assign) RCChatSessionInputBarControlStyle style;
@end
@implementation RCInputContainerView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self rcinit];
    }
    return self;
}

- (void)rcinit {
    self.maxInputLines = 4;
}

- (BOOL)hideEmojiButton {
    return _hideEmojiButton;
}

- (void)setHideEmojiButton:(BOOL)hideEmojiButton {
    if (hideEmojiButton != _hideEmojiButton) {
        _hideEmojiButton = hideEmojiButton;
        [self resetInputContainerView];
        [self setupSubViews];
        [self setLayoutForInputContainerView:self.style];
    }
}
#pragma mark - Public API
- (void)setInputBarStyle:(RCChatSessionInputBarControlStyle)style {
    self.style = style;
    [self resetInputContainerView];
    [self setupSubViews];
    [self setLayoutForInputContainerView:style];
}

- (void)setBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus {
    _currentBottomBarStatus = bottomBarStatus;
    switch (bottomBarStatus) {
    case KBottomBarRecordStatus: {
        [self inputTextViewBecomeFirstResponder:NO];
        [self switchToRecord];
    } break;
    case KBottomBarKeyboardStatus: {
        [self inputTextViewBecomeFirstResponder:YES];
        [self showInputTextView];
    } break;
    case KBottomBarDefaultStatus:
    case KBottomBarPluginStatus:
    case KBottomBarEmojiStatus:
    case KBottomBarCommonPhrasesStatus:
    default:
        [self inputTextViewBecomeFirstResponder:NO];
        [self showInputTextView];
        break;
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    BOOL isShould = [self.delegate inputTextView:textView shouldChangeTextInRange:range replacementText:text];
    if ([text isEqualToString:@"\n"]) {
        self.inputTextView.text = @"";
        [self textViewDidChange:textView];
    }else{
        [self changeInputTextViewRange];
    }
    
    [[RCExtensionService sharedService] inputTextViewDidChange:textView inInputBar:(RCChatSessionInputBarControl *)self.superview];
    return isShould;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
     DebugLog(@"%s, %@", __FUNCTION__, textView);
    self.textViewBeginEditing = YES;
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    DebugLog(@"%s, %@", __FUNCTION__, textView.text);
    self.textViewBeginEditing = NO;
    // filter the space
}

- (void)textViewDidChange:(UITextView *)textView {
    [self inputTextViewDidChange:textView];
}

#pragma mark - RCTextViewDelegate
- (void)rctextView:(RCTextView *)textView textDidChange:(NSString *)text {
    [self.inputTextView layoutIfNeeded];
    [self inputTextViewDidChange:textView];
}

#pragma mark - Target Action
- (void)switchInputBoxOrRecord {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerViewSwitchButtonClicked:)]) {
        [self.delegate inputContainerViewSwitchButtonClicked:self];
    }
}

- (void)voiceRecordButtonTouchDown:(UIButton *)sender {
    sender.backgroundColor = RCDYCOLOR(0xe0e2e3,0x323232);
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchDown];
    }
}

- (void)voiceRecordButtonTouchUpInside:(UIButton *)sender {
    sender.backgroundColor = RCDYCOLOR(0xffffff,0x2d2d2d);
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)voiceRecordButtonTouchCancel:(UIButton *)sender {
    sender.backgroundColor = RCDYCOLOR(0xffffff,0x2d2d2d);
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchCancel];
    }
}

- (void)voiceRecordButtonTouchDragExit:(UIButton *)sender {
    sender.backgroundColor = RCDYCOLOR(0xffffff,0x2d2d2d);
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchDragExit];
    }
}

- (void)voiceRecordButtonTouchDragEnter:(UIButton *)sender {
    sender.backgroundColor = RCDYCOLOR(0xe0e2e3,0x323232);
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchDragEnter];
    }
}

- (void)voiceRecordButtonTouchUpOutside:(UIButton *)sender {
    sender.backgroundColor = RCDYCOLOR(0xffffff,0x323232);
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchUpOutside];
    }
}

- (void)didTouchEmojiDown:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerViewEmojiButtonClicked:)]) {
        [self.delegate inputContainerViewEmojiButtonClicked:self];
    }
}

- (void)didTouchPhotoDown:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerViewPhotoButtonClicked:)]) {
        [self.delegate inputContainerViewPhotoButtonClicked:self];
    }
}

- (void)didTouchGiftDown:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerViewGiftButtonClicked:)]) {
        [self.delegate inputContainerViewGiftButtonClicked:self];
    }
}

- (void)didTouchVoiceDown:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerViewVoiceButtonClicked:)]) {
        [self.delegate inputContainerViewVoiceButtonClicked:self];
    }
}

- (void)didTouchVideoDown:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerViewVideoButtonClicked:)]) {
        [self.delegate inputContainerViewVideoButtonClicked:self];
    }
}

#pragma mark - Private Methods
- (void)inputTextViewDidChange:(UITextView *)textView{
    [self changeInputTextViewRange];
    [[RCExtensionService sharedService] inputTextViewDidChange:textView inInputBar:(RCChatSessionInputBarControl *)self.superview];
    if ([self.delegate respondsToSelector:@selector(inputTextViewDidChange:)]) {
        [self.delegate inputTextViewDidChange:textView];
    }
}

- (void)inputTextViewBecomeFirstResponder:(BOOL)isBecome {
    if (isBecome && ![self.inputTextView isFirstResponder]) {
        [self.inputTextView becomeFirstResponder];
    }
    if (!isBecome && [self.inputTextView isFirstResponder]) {
        [self.inputTextView resignFirstResponder];
    }
}

#pragma mark - UI
- (void)setupSubViews {
    [self addSubview:self.switchButton];
    [self addSubview:self.inputTextView];
    [self addSubview:self.recordButton];
    [self addSubview:self.emojiButton];
    
    CGFloat spacing = ((SCREEN_WIDTH - 50 * 2) - 24 * 4) / 3;
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = spacing;
    [self insertSubview:stackView atIndex:0];
    
    [stackView addArrangedSubview:self.photoButton];
    [stackView addArrangedSubview:self.giftButton];
    [stackView addArrangedSubview:self.voiceButton];
    [stackView addArrangedSubview:self.videoButton];
    
    [@[self.photoButton, self.giftButton, self.voiceButton, self.videoButton] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.width.equalTo(@24);
        }];
    }];
    
    [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@46);
        make.centerX.equalTo(self);
        make.width.equalTo(self).offset(-50 * 2);
        make.bottom.equalTo(self);
    }];
}

- (void)showInputTextView {
    [self layoutInputBoxUIIfNeed];
    [self updateButtonImage];
}

- (void)switchToRecord {
    if (self.inputTextView.hidden) {
        return;
    }
    [self layoutInputBoxUIIfNeed];
    [self updateButtonImage];
}

- (void)updateButtonImage {
    if (self.currentBottomBarStatus != KBottomBarEmojiStatus) {
        [self.emojiButton setImage:[UIImage imageNamed:@"icon_message_emoji"] forState:UIControlStateNormal];
    } else {
        [self.emojiButton setImage:[UIImage imageNamed:@"icon_message_keyboard"] forState:UIControlStateNormal];
    }

    [self.switchButton setImage:[UIImage imageNamed:self.recordButton.hidden ? @"icon_message_microphone" : @"icon_message_keyboard"] forState:UIControlStateNormal];
}

- (void)layoutInputBoxUIIfNeed {
    CGFloat changedBeforeHeight = self.frame.size.height;
     CGRect rectFrame = self.frame;
    if (self.currentBottomBarStatus == KBottomBarRecordStatus) {
        self.inputTextView.hidden = YES;
        self.recordButton.hidden = NO;
        rectFrame.size.height = RC_ChatSessionInputBar_Height;
    }else{
        self.recordButton.hidden = YES;
        self.inputTextView.hidden = NO;

        self.inputTextView.frame = [self getInputTextViewFrame];
        rectFrame.size.height = RC_ChatSessionInputBar_Height +
                                (self.inputTextView.frame.size.height - [self getTextViewHeightWithLines:1]);
    }
    
    if (changedBeforeHeight != rectFrame.size.height) {
        self.frame = rectFrame;
        if (self.delegate && [self.delegate respondsToSelector:@selector(inputContainerView:didChangeFrame:)]) {
            [self.delegate inputContainerView:self didChangeFrame:self.frame];
        }
    }
}

- (void)changeInputTextViewRange {
    CGFloat changedBeforeHeight = self.frame.size.height;
    [self layoutInputBoxUIIfNeed];
    if (changedBeforeHeight != self.frame.size.height && self.inputTextView.text > 0) {
        [UIView animateWithDuration:0.5 animations:^{
            [self.inputTextView scrollRangeToVisible:[self.inputTextView selectedRange]];
        }];
    }
}

- (CGRect)getInputTextViewFrame {
    CGFloat inputTextview_height = [self getTextViewHeightWithLines:1];
    if (self.inputTextView.contentSize.height > [self getTextViewHeightWithLines:1] &&
        self.inputTextView.contentSize.height <= [self getTextViewHeightWithLines:self.maxInputLines - 1]) {
        inputTextview_height = self.inputTextView.contentSize.height;
    }
    if (self.inputTextView.contentSize.height > [self getTextViewHeightWithLines:self.maxInputLines - 1]) {
        inputTextview_height = [self getTextViewHeightWithLines:self.maxInputLines];
    }
    CGRect inputTextRect = self.inputTextView.frame;
    inputTextRect.size.height = inputTextview_height;
    inputTextRect.origin.y = TextViewRectY;
    return inputTextRect;
}

- (CGFloat)getTextViewHeightWithLines:(NSInteger)lines {
    CGFloat totalHeight = lines * TextViewLineHeight + TextViewSpaceHeight_LessThanMax;
    if (lines >= self.maxInputLines) {
        totalHeight = lines * TextViewLineHeight + TextViewSpaceHeight;
    }
    return totalHeight;
}

- (void)resetInputContainerView {
    if (self.inputContainerSubViewConstraints.count > 0) {
        [self removeConstraints:self.inputContainerSubViewConstraints];
        [self.inputContainerSubViewConstraints removeAllObjects];
    }

    if (self.switchButton) {
        [self.switchButton removeFromSuperview];
        self.switchButton = nil;
    }
    if (self.recordButton) {
        [self.recordButton removeFromSuperview];
        self.recordButton = nil;
    }
    if (self.inputTextView) {
        [self.inputTextView removeFromSuperview];
        if (self.inputTextView.text.length <= 0) {
            self.inputTextView = nil;
        }
    }
    if (self.emojiButton) {
        [self.emojiButton removeFromSuperview];
        self.emojiButton = nil;
    }
}

- (void)setLayoutForInputContainerView:(RCChatSessionInputBarControlStyle)style {
    self.switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.emojiButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputTextView.translatesAutoresizingMaskIntoConstraints = NO;

    NSDictionary *_bindingViews = NSDictionaryOfVariableBindings(_switchButton, _inputTextView, _recordButton, _emojiButton);

    NSString *format;

    switch (style) {
    case RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION:
        format = @"H:|-8-[_switchButton(BUTTONWIDTH)]-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-|";
        break;
    case RC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER_SWITCH:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton(BUTTONWIDTH)]-8-|";
        break;
    case RC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH_EXTENTION:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton(BUTTONWIDTH)]-8-|";
        break;
    case RC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION_SWITCH:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton(BUTTONWIDTH)]-8-|";
        break;
    case RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER:
        format = @"H:|-8-[_switchButton(BUTTONWIDTH)]-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-|";
        break;
    case RC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton(BUTTONWIDTH)]-8-|";
        break;
    case RC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton(0)]-8-|";
        break;
    case RC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton(0)]-8-|";
        break;
    case RC_CHAT_INPUT_BAR_STYLE_CONTAINER:
        format = @"H:|-0-[_switchButton(0)]-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-|";
        break;
    default:
        break;
    }

    NSInteger emojiBtnWidth = self.hideEmojiButton ? 0 : 30;
    [self.inputContainerSubViewConstraints
        addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:format
                                                                    options:0
                                                                    metrics:@{@"BUTTONWIDTH":@(30), @"EMOJIBUTTONWIDTH":@(emojiBtnWidth)}
                                                                      views:_bindingViews]];
// 13+30+13+46 = 102
    [self.inputContainerSubViewConstraints
        addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_switchButton(BUTTONWIDTH)]-59-|"
                                                                    options:0
                                                                    metrics:@{@"BUTTONWIDTH":@(30)}
                                                                      views:_bindingViews]];
    [self.inputContainerSubViewConstraints
        addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-9-[_recordButton(38)]-55-|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:_bindingViews]];

    [self.inputContainerSubViewConstraints
        addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_emojiButton(BUTTONWIDTH)]-59-|"
                                                                    options:kNilOptions
                                                                    metrics:@{@"BUTTONWIDTH":@(30)}
                                                                      views:_bindingViews]];

    [self.inputContainerSubViewConstraints addObjectsFromArray:@[[NSLayoutConstraint constraintWithItem:self.recordButton attribute:NSLayoutAttributeLeft relatedBy:(NSLayoutRelationEqual) toItem:self.inputTextView attribute:NSLayoutAttributeLeft multiplier:1 constant:0]]];
    
    [self.inputContainerSubViewConstraints addObjectsFromArray:@[[NSLayoutConstraint constraintWithItem:self.recordButton attribute:NSLayoutAttributeRight relatedBy:(NSLayoutRelationEqual) toItem:self.inputTextView attribute:NSLayoutAttributeRight multiplier:1 constant:0]]];
    
    [self.inputContainerSubViewConstraints addObjectsFromArray:@[[NSLayoutConstraint constraintWithItem:self.recordButton attribute:NSLayoutAttributeTop relatedBy:(NSLayoutRelationEqual) toItem:self.inputTextView attribute:NSLayoutAttributeTop multiplier:1 constant:0]]];
    
    [self.inputContainerSubViewConstraints addObjectsFromArray:@[[NSLayoutConstraint constraintWithItem:self.inputTextView attribute:NSLayoutAttributeBottom relatedBy:(NSLayoutRelationEqual) toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-6-46]]];

    [self addConstraints:self.inputContainerSubViewConstraints];

    [self updateConstraintsIfNeeded];
    [self layoutIfNeeded];
}

#pragma mark - Getter & Setter
- (RCButton *)switchButton {
    if (!_switchButton) {
        _switchButton = [[RCButton alloc] initWithFrame:CGRectZero];
        [_switchButton setImage:[UIImage imageNamed:@"icon_message_microphone"]
                       forState:UIControlStateNormal];
        [_switchButton addTarget:self
                          action:@selector(switchInputBoxOrRecord)
                forControlEvents:UIControlEventTouchUpInside];
        [_switchButton setExclusiveTouch:YES];
    }
    return _switchButton;
}

- (RCTextView *)inputTextView {
    if (!_inputTextView) {
        _inputTextView = [[RCTextView alloc] initWithFrame:CGRectZero];
        _inputTextView.delegate = self;
        _inputTextView.textChangeDelegate = self;
        UIEdgeInsets textEdge = self.inputTextView.textContainerInset;
        textEdge.left = 10;
        textEdge.right = 10;
        _inputTextView.textContainerInset = textEdge;
        [_inputTextView setExclusiveTouch:YES];
        [_inputTextView setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x000000) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
        [_inputTextView setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        [_inputTextView setReturnKeyType:UIReturnKeySend];
        _inputTextView.backgroundColor = RCDYCOLOR(0xffffff, 0x2d2d2d);
        _inputTextView.enablesReturnKeyAutomatically = YES;
        _inputTextView.layer.borderColor = HEXCOLOR(0xD8D8D8).CGColor;
        _inputTextView.layer.borderWidth = 1;
        _inputTextView.layer.cornerRadius = 20;
        _inputTextView.layer.masksToBounds = YES;
        [_inputTextView setAccessibilityLabel:@"chat_input_textView"];
    }
    return _inputTextView;
}

- (RCButton *)recordButton {
    if (!_recordButton) {
        _recordButton = [[RCButton alloc] initWithFrame:CGRectZero];
        [_recordButton setExclusiveTouch:YES];
        [_recordButton setHidden:YES];
        [_recordButton setTitle:RCLocalizedString(@"hold_to_talk_title") forState:UIControlStateNormal];
        _recordButton.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
        [_recordButton setTitle:RCLocalizedString(@"release_to_send_title")
                       forState:UIControlStateHighlighted];
        [_recordButton setTitleColor:RCDYCOLOR(0x000000, 0xffffff) forState:UIControlStateNormal];
        _recordButton.backgroundColor = RCDYCOLOR(0xffffff,0x2d2d2d);
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchDown:)
                forControlEvents:UIControlEventTouchDown];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchUpInside:)
                forControlEvents:UIControlEventTouchUpInside];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchUpOutside:)
                forControlEvents:UIControlEventTouchUpOutside];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchDragExit:)
                forControlEvents:UIControlEventTouchDragExit];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchDragEnter:)
                forControlEvents:UIControlEventTouchDragEnter];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchCancel:)
                forControlEvents:UIControlEventTouchCancel];
        _recordButton.layer.borderColor = HEXCOLOR(0x000000).CGColor;
        _recordButton.layer.borderWidth = 1;
        _recordButton.layer.cornerRadius = 20;
        _recordButton.layer.masksToBounds = YES;
    }
    return _recordButton;
}

- (RCButton *)emojiButton {
    if (!_emojiButton) {
        _emojiButton = [[RCButton alloc] initWithFrame:CGRectZero];
        [_emojiButton setImage:[UIImage imageNamed:@"icon_message_emoji"] forState:UIControlStateNormal];
        [_emojiButton setExclusiveTouch:YES];
        [_emojiButton addTarget:self action:@selector(didTouchEmojiDown:) forControlEvents:UIControlEventTouchUpInside];
        _emojiButton.hidden = self.hideEmojiButton;
    }
    return _emojiButton;
}

- (RCButton *)photoButton {
    if (!_photoButton) {
        _photoButton = [[RCButton alloc] initWithFrame:CGRectZero];
        _photoButton.adjustsImageWhenHighlighted = NO;
        [_photoButton setImage:[UIImage imageNamed:@"icon_message_photo"] forState:UIControlStateNormal];
        [_photoButton setExclusiveTouch:YES];
        [_photoButton addTarget:self action:@selector(didTouchPhotoDown:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _photoButton;
}

- (RCButton *)giftButton {
    if (!_giftButton) {
        _giftButton = [[RCButton alloc] initWithFrame:CGRectZero];
        _giftButton.adjustsImageWhenHighlighted = NO;
        [_giftButton setImage:[UIImage imageNamed:@"icon_message_gift"] forState:UIControlStateNormal];
        [_giftButton setExclusiveTouch:YES];
        [_giftButton addTarget:self action:@selector(didTouchGiftDown:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _giftButton;
}

- (RCButton *)voiceButton {
    if (!_voiceButton) {
        _voiceButton = [[RCButton alloc] initWithFrame:CGRectZero];
        _voiceButton.adjustsImageWhenHighlighted = NO;
        [_voiceButton setImage:[UIImage imageNamed:@"icon_message_voice"] forState:UIControlStateNormal];
        [_voiceButton setExclusiveTouch:YES];
        [_voiceButton addTarget:self action:@selector(didTouchVoiceDown:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _voiceButton;
}

- (RCButton *)videoButton {
    if (!_videoButton) {
        _videoButton = [[RCButton alloc] initWithFrame:CGRectZero];
        _videoButton.adjustsImageWhenHighlighted = NO;
        [_videoButton setImage:[UIImage imageNamed:@"icon_message_video"] forState:UIControlStateNormal];
        [_videoButton setExclusiveTouch:YES];
        [_videoButton addTarget:self action:@selector(didTouchVideoDown:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _videoButton;
}


- (NSMutableArray *)inputContainerSubViewConstraints {
    if (!_inputContainerSubViewConstraints) {
        _inputContainerSubViewConstraints = [[NSMutableArray alloc] init];
    }
    return _inputContainerSubViewConstraints;
}

- (void)setMaxInputLines:(NSInteger)maxInputLines {
    if (maxInputLines > TextViewMaxInputLines) {
        maxInputLines = TextViewMaxInputLines;
    }
    if (maxInputLines < TextViewMinInputLines) {
        maxInputLines = TextViewMinInputLines;
    }
    _maxInputLines = maxInputLines;
}
@end
