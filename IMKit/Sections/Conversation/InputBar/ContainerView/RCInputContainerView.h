//
//  RCInputContainerView.h
//  RongIMKit
//
//  Created by 张改红 on 2020/5/26.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCButton.h"
#import "RCTextView.h"
#import "RCExtensionKitDefine.h"
#import "RCBaseView.h"
@protocol RCInputContainerViewDelegate;

@interface RCInputContainerView : RCBaseView
/*!
 语音与文本输入切换的按钮
 */
@property (strong, nonatomic) RCButton *switchButton;

/*!
 录制语音消息的按钮
 */
@property (nonatomic, strong) RCButton *recordButton;

/*!
 文本输入框
 */
@property (nonatomic, strong) RCTextView *inputTextView;

/*!
 表情的按钮
 */
@property (nonatomic, strong) RCButton *emojiButton;


@property (nonatomic, strong) RCButton *photoButton;
@property (nonatomic, strong) RCButton *giftButton;
@property (nonatomic, strong) RCButton *voiceButton;
@property (nonatomic, strong) RCButton *videoButton;

@property (nonatomic, assign) KBottomBarStatus currentBottomBarStatus;

/**
 输入框最大输入行数

 @discussion 该变量设置范围为: 1~6, 超过该范围会自动调整为边界值
 */
@property (nonatomic, assign) NSInteger maxInputLines;

// 隐藏表情按钮
@property(nonatomic, assign) BOOL hideEmojiButton;

@property (nonatomic, weak) id<RCInputContainerViewDelegate> delegate;

- (void)setInputBarStyle:(RCChatSessionInputBarControlStyle)style;

- (void)setBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus;

@end

@protocol RCInputContainerViewDelegate <NSObject>

- (void)inputContainerViewSwitchButtonClicked:(RCInputContainerView *)inputContainerView;

- (void)inputContainerViewEmojiButtonClicked:(RCInputContainerView *)inputContainerView;

- (void)inputContainerViewPhotoButtonClicked:(RCInputContainerView *)inputContainerView;
- (void)inputContainerViewGiftButtonClicked:(RCInputContainerView *)inputContainerView;
- (void)inputContainerViewVoiceButtonClicked:(RCInputContainerView *)inputContainerView;
- (void)inputContainerViewVideoButtonClicked:(RCInputContainerView *)inputContainerView;

- (void)inputContainerView:(RCInputContainerView *)inputContainerView forControlEvents:(UIControlEvents)controlEvents;

- (void)inputContainerView:(RCInputContainerView *)inputContainerView didChangeFrame:(CGRect)frame;

- (BOOL)inputTextView:(UITextView *)inputTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

- (void)inputTextViewDidChange:(UITextView *)textView;
@end
