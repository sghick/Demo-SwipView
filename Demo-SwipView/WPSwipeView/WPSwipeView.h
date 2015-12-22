//
//  WPSwipeView.h
//  WisdomPark
//
//  Created by 丁治文 on 15/4/8.
//  Copyright (c) 2015年 com.wp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WPSwipeViewAnimate) {
    WPSwipeViewAnimatePoker,
    WPSwipeViewAnimateLadder,  // 天梯效果
    WPSwipeViewAnimateLadder2  // 天梯效果2（方向向右）
};

typedef NS_ENUM(NSUInteger, WPSwipeViewDirection) {
    WPSwipeViewDirectionNone = 0,
    WPSwipeViewDirectionLeft = (1 << 0),
    WPSwipeViewDirectionRight = (1 << 1),
    WPSwipeViewDirectionHorizontal = WPSwipeViewDirectionLeft|WPSwipeViewDirectionRight,
    WPSwipeViewDirectionUp = (1 << 2),
    WPSwipeViewDirectionDown = (1 << 3),
    WPSwipeViewDirectionVertical = WPSwipeViewDirectionUp|WPSwipeViewDirectionDown,
    WPSwipeViewDirectionAll = WPSwipeViewDirectionLeft|WPSwipeViewDirectionRight|WPSwipeViewDirectionUp|WPSwipeViewDirectionDown,
};

@class WPSwipeView;

/// Delegate
@protocol WPSwipeViewDelegate <NSObject>
@optional
- (void)swipeView:(WPSwipeView *)swipeView didSwipeView:(UIView *)view inDirection:(WPSwipeViewDirection)direction;

- (void)swipeView:(WPSwipeView *)swipeView didCancelSwipe:(UIView *)view;

- (void)swipeView:(WPSwipeView *)swipeView didStartSwipingView:(UIView *)view atLocation:(CGPoint)location;

- (void)swipeView:(WPSwipeView *)swipeView swipingView:(UIView *)view atLocation:(CGPoint)location translation:(CGPoint)translation;

- (void)swipeView:(WPSwipeView *)swipeView didEndSwipingView:(UIView *)view atLocation:(CGPoint)location;

- (void)swipeView:(WPSwipeView *)swipeView didShowSwipingView:(UIView *)view atIndex:(NSInteger)index;

- (void)swipeView:(WPSwipeView *)swipeView didLoadSwipingView:(UIView *)view atIndex:(NSInteger)index;

- (void)swipeView:(WPSwipeView *)swipeView didSelectedSwipingView:(UIView *)view atIndex:(NSInteger)index;
@end

// DataSource
@protocol WPSwipeViewDataSource <NSObject>

@optional
- (NSInteger)numberOfSwipeView:(WPSwipeView *)swipeView;

@required
- (UIView *)swipeView:(WPSwipeView *)swipeView nextViewOfIndex:(NSInteger)index;

@end

@interface WPSwipeView : UIView

@property (assign, nonatomic) id<WPSwipeViewDataSource> dataSource;

@property (assign, nonatomic) id<WPSwipeViewDelegate> delegate;

// 允许view跟随手势，默认YES
@property (assign, nonatomic) BOOL isAllowPanGesture;
// 是否允许后面的view旋转，默认YES
@property (assign, nonatomic) BOOL isRotationEnabled;
// 后面的view旋转的角度大小
@property (assign, nonatomic) float rotationDegree;
// 旋转的偏移量 默认0.3f
@property (assign, nonatomic) float rotationRelativeYOffsetFromCenter;
// view划出的方向，默认支持所有方向
@property (assign, nonatomic) WPSwipeViewDirection direction;
// 每秒偏移的量
@property (assign, nonatomic) CGFloat escapeVelocityThreshold;
// 相对距离
@property (assign, nonatomic) CGFloat relativeDisplacementThreshold;
// 划出的相对速度
@property (assign, nonatomic) CGFloat pushVelocityMagnitude;
// 初始时加载view的位置
@property (assign, nonatomic) CGPoint swipeViewsCenter;
// 显示时加载view的位置
@property (assign, nonatomic) CGPoint swipeViewsCenterInitial;
// 滑动的view到这个rect中会被销毁
@property (assign, nonatomic) CGRect collisionRect;
// 划出的view的y轴偏移量
@property (assign, nonatomic) CGFloat programaticSwipeRotationRelativeYOffsetFromCenter;
// 动画展示效果
@property (assign, nonatomic) WPSwipeViewAnimate swipeViewAnimate;
// 一屏最多展示view个数 默认4个
@property (assign, nonatomic) NSInteger numberOfViewsPrefetched;
// 加载的index
@property (assign, nonatomic, readonly) NSInteger reloadIndex;
// 反向加载的index
@property (assign, nonatomic, readonly) NSInteger lastReloadIndex;
// 显示的index
@property (assign, nonatomic, readonly) NSInteger showIndex;
// 是否循环展示
@property (assign, nonatomic) BOOL isRecycle;
// 偏移量（天梯效果，默认10）
@property (assign, nonatomic) CGFloat ladderOffset;
// 偏移边距（天梯效果，默认10）
@property (assign, nonatomic) CGFloat ladderMargin;

// 重新加载view
- (void)reloadData;

// 销毁所有view
- (void)discardAllSwipeViews;

// 向左划出
- (void)swipeOutViewToLeft;
// 向右划出
- (void)swipeOutViewToRight;
// 向上划出
- (void)swipeOutViewToUp;
// 向下划出
- (void)swipeOutViewToDown;

// 从上次划出方向划入
- (void)swipeInView;
// 从左划入
- (void)swipeInViewFromLeft;
// 从右划入
- (void)swipeInViewFromRight;
// 从上划入
- (void)swipeInViewFromUp;
// 从下划入
- (void)swipeInViewFromDown;


@end
