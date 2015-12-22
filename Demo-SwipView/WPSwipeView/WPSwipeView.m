//
//  WPSwipeView.m
//  WisdomPark
//
//  Created by 丁治文 on 15/4/8.
//  Copyright (c) 2015年 com.wp. All rights reserved.
//

#import "WPSwipeView.h"

WPSwipeViewDirection WPDirectionVectorToSwipeViewDirection(CGVector directionVector) {
    WPSwipeViewDirection direction = WPSwipeViewDirectionNone;
    if (ABS(directionVector.dx) > ABS(directionVector.dy)) {
        if (directionVector.dx > 0) {
            direction = WPSwipeViewDirectionRight;
        } else {
            direction = WPSwipeViewDirectionLeft;
        }
    } else {
        if (directionVector.dy > 0) {
            direction = WPSwipeViewDirectionDown;
        } else {
            direction = WPSwipeViewDirectionUp;
        }
    }
    return direction;
}

@interface WPSwipeView () <UICollisionBehaviorDelegate, UIDynamicAnimatorDelegate>

// UIDynamicAnimators
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UISnapBehavior *swipeViewSnapBehavior;
@property (strong, nonatomic) UIAttachmentBehavior *swipeViewAttachmentBehavior;
@property (strong, nonatomic) UIAttachmentBehavior *anchorViewAttachmentBehavior;
// AnchorView
@property (strong, nonatomic) UIView *anchorContainerView;
@property (strong, nonatomic) UIView *anchorView;
@property (nonatomic) BOOL isAnchorViewVisible;
// ContainerView
@property (strong, nonatomic) UIView *reuseCoverContainerView;
@property (strong, nonatomic) UIView *containerView;

// 加载的view个数，默认为-1，表未无限制
@property (assign, nonatomic) NSInteger numberOfView;
// 加载的index
@property (assign, nonatomic) NSInteger loadIndex;
// 反向加载的index
@property (assign, nonatomic) NSInteger lastLoadIndex;

@end

@implementation WPSwipeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // 默认4个
    self.numberOfViewsPrefetched = 4;
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    self.animator.delegate = self;
    self.anchorContainerView =
    [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [self addSubview:self.anchorContainerView];
    self.isAnchorViewVisible = NO;
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.containerView];
    self.reuseCoverContainerView = [[UIView alloc] initWithFrame:self.bounds];
    self.reuseCoverContainerView.userInteractionEnabled = false;
    [self addSubview:self.reuseCoverContainerView];
    
    // Default properties
    self.isAllowPanGesture = YES;
    self.isRotationEnabled = YES;
    self.rotationDegree = 1;
    self.rotationRelativeYOffsetFromCenter = 0.3;
    
    self.direction = WPSwipeViewDirectionAll;
    self.pushVelocityMagnitude = 1000;
    self.escapeVelocityThreshold = 750;
    self.relativeDisplacementThreshold = 0.25;
    
    self.programaticSwipeRotationRelativeYOffsetFromCenter = -0.2;
    self.swipeViewsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.swipeViewsCenterInitial = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.collisionRect = [self defaultCollisionRect];
    
    self.ladderOffset = 10.0f;
    self.ladderMargin = 10.0f;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.anchorContainerView.frame = CGRectMake(0, 0, 1, 1);
    self.containerView.frame = self.bounds;
    self.reuseCoverContainerView.frame = self.bounds;
    self.swipeViewsCenterInitial = CGPointMake(
                                                   self.bounds.size.width/2 + self.swipeViewsCenterInitial.x -
                                                   self.swipeViewsCenter.x,
                                                   self.bounds.size.height/2 + self.swipeViewsCenterInitial.y -
                                                   self.swipeViewsCenter.y
                                               );
    self.swipeViewsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

- (void)setSwipeViewsCenter:(CGPoint)swipeViewsCenter {
    _swipeViewsCenter = swipeViewsCenter;
    [self animateSwipeViewsIfNeeded];
}

#pragma mark - DataSource
- (void)reloadData{
    [self discardAllSwipeViews];
    _numberOfView = -1;
    _loadIndex = 0;
    _lastLoadIndex = -1;
    if ([self.dataSource respondsToSelector:@selector(numberOfSwipeView:)]) {
        _numberOfView = [self.dataSource numberOfSwipeView:self];
    }
    [self loadNextSwipeViewsIfNeeded:NO];
}

- (void)discardAllSwipeViews {
    [self.animator removeBehavior:self.anchorViewAttachmentBehavior];
    for (UIView *view in self.containerView.subviews) {
        [view removeFromSuperview];
    }
}

- (void)loadNextSwipeViewsIfNeeded:(BOOL)animated {
    NSInteger numViews = self.containerView.subviews.count;
    NSMutableSet *newViews = [NSMutableSet set];
    for (NSInteger i = numViews; i < self.numberOfViewsPrefetched; i++) {
        UIView *nextView = [self nextSwipeView];
        if (nextView) {
            [self.containerView addSubview:nextView];
            [self.containerView sendSubviewToBack:nextView];
            nextView.center = self.swipeViewsCenterInitial;
            [newViews addObject:nextView];
        }
    }
    // 回调当前显示的view
    if ([self.delegate respondsToSelector:@selector(swipeView:didShowSwipingView:atIndex:)]) {
        [self.delegate swipeView:self didShowSwipingView:[self topSwipeView] atIndex:self.showIndex];
    }
    
    if (animated) {
        NSTimeInterval maxDelay = 0.3;
        NSTimeInterval delayStep = maxDelay/self.numberOfViewsPrefetched;
        NSTimeInterval aggregatedDelay = maxDelay;
        NSTimeInterval animationDuration = 0.25;
        for (UIView *view in newViews) {
            view.center = CGPointMake(view.center.x, -view.frame.size.height);
            [UIView animateWithDuration:animationDuration delay:aggregatedDelay options:UIViewAnimationOptionCurveEaseIn animations:^{
                view.center = self.swipeViewsCenter;
            } completion:nil];
            aggregatedDelay -= delayStep;
        }
        [self performSelector:@selector(animateSwipeViewsIfNeeded) withObject:nil afterDelay:animationDuration];
    }
    else {
        [self animateSwipeViewsIfNeeded];
    }
}

- (void)loadLastSwipeViewsIfNeeded:(BOOL)animated {
    NSMutableSet *newViews = [NSMutableSet set];
    UIView *nextView = [self lastSwipeView];
    if (nextView) {
        [self.containerView addSubview:nextView];
        nextView.center = self.swipeViewsCenterInitial;
        [newViews addObject:nextView];
    }
    NSInteger needRemoveCount = self.containerView.subviews.count - self.numberOfViewsPrefetched;
    for (int i = 0; i < needRemoveCount; i++) {
        [self.containerView.subviews.firstObject removeFromSuperview];
    }
    // 回调当前显示的view
    if ([self.delegate respondsToSelector:@selector(swipeView:didShowSwipingView:atIndex:)]) {
        [self.delegate swipeView:self didShowSwipingView:[self topSwipeView] atIndex:self.showIndex];
    }
    
    if (animated) {
        NSTimeInterval maxDelay = 0.0;
        NSTimeInterval delayStep = maxDelay/self.numberOfViewsPrefetched;
        NSTimeInterval aggregatedDelay = maxDelay;
        NSTimeInterval animationDuration = 0.25;
        [self performSelector:@selector(animateSwipeViewsIfNeeded) withObject:nil afterDelay:aggregatedDelay];
        for (UIView *view in newViews) {
            view.center = CGPointMake(view.center.x, -view.frame.size.height);
            [UIView animateWithDuration:animationDuration delay:aggregatedDelay options:UIViewAnimationOptionCurveEaseIn animations:^{
                view.center = self.swipeViewsCenter;
            } completion:nil];
            aggregatedDelay -= delayStep;
        }
    }
    else {
        [self animateSwipeViewsIfNeeded];
    }
}

- (void)animateSwipeViewsIfNeeded {
    UIView *topSwipeView = [self topSwipeView];
    if (!topSwipeView) {
        return;
    }
    
    for (UIView *cover in self.containerView.subviews) {
        cover.userInteractionEnabled = NO;
    }
    topSwipeView.userInteractionEnabled = YES;
    
    for (UIGestureRecognizer *recognizer in topSwipeView.gestureRecognizers) {
        if (recognizer.state != UIGestureRecognizerStatePossible) {
            return;
        }
    }
    
    if (self.isRotationEnabled) {
        // rotation
        NSUInteger numSwipeViews = self.containerView.subviews.count;
        for (int i = 1; i <= self.numberOfViewsPrefetched; i++) {
            // 刷新动画行为
            [self.animator removeBehavior:self.swipeViewSnapBehavior];
            UIView * topView = self.containerView.subviews[numSwipeViews - 1];
            self.swipeViewSnapBehavior = [self snapBehaviorThatSnapView:topView toPoint:self.swipeViewsCenter];
            [self.animator addBehavior:self.swipeViewSnapBehavior];
            // 设置view偏移量
            if (numSwipeViews >= i) {
                UIView * view = self.containerView.subviews[numSwipeViews - i];
                // 效果
                switch (self.swipeViewAnimate) {
                        // 散布效果
                    case WPSwipeViewAnimatePoker: {
                        CGPoint rotationCenterOffset = {0, CGRectGetHeight(topSwipeView.frame)*self.rotationRelativeYOffsetFromCenter};
                        [self rotateView:view forDegree:self.rotationDegree atOffsetFromCenter:rotationCenterOffset animated:YES];
                    }break;
                        // 天梯效果
                    case WPSwipeViewAnimateLadder: {
                        CGFloat scale = 1 - self.ladderMargin/self.frame.size.height*2*(i-1);
                        CGPoint scalePoint = CGPointMake(scale, scale);
                        CGPoint offset = CGPointMake(0, -(self.ladderOffset + self.ladderMargin)*2*(i-1));
                        [self ladderView:view atScale:scalePoint atOffsetFromCenter:offset animated:YES];
                    }break;
                        // 天梯效果2
                    case WPSwipeViewAnimateLadder2: {
                        CGFloat scale = 1 - self.ladderMargin/self.frame.size.height*2*(i-1);
                        CGPoint scalePoint = CGPointMake(scale, scale);
                        CGPoint offset = CGPointMake((self.ladderOffset + self.ladderMargin)*2*(i-1), 0);
                        [self ladderView:view atScale:scalePoint atOffsetFromCenter:offset animated:YES];
                    }break;
                    default:
                        break;
                }
            }
        }
    }
}

#pragma mark - Action
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    CGPoint location = [recognizer locationInView:self];
    UIView *swipeView = recognizer.view;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self createAnchorViewForCover:swipeView atLocation:location shouldAttachAnchorViewToPoint:YES];
        if ([self.delegate respondsToSelector:@selector(swipeView:didStartSwipingView:atLocation:)]) {
            [self.delegate swipeView:self didStartSwipingView:swipeView atLocation:location];
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        self.anchorViewAttachmentBehavior.anchorPoint = location;
        if ([self.delegate respondsToSelector:@selector(swipeView:swipingView:atLocation:translation:)]) {
            [self.delegate swipeView:self swipingView:swipeView atLocation:location translation:translation];
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGPoint velocity = [recognizer velocityInView:self];
        CGFloat velocityMagnitude = sqrtf(powf(velocity.x, 2) + powf(velocity.y, 2));
        CGPoint normalizedVelocity = CGPointMake(velocity.x / velocityMagnitude, velocity.y / velocityMagnitude);
        CGFloat scale = velocityMagnitude > self.escapeVelocityThreshold ? velocityMagnitude : self.pushVelocityMagnitude;
        CGFloat translationMagnitude = sqrtf(translation.x * translation.x + translation.y * translation.y);
        CGVector directionVector = CGVectorMake(
                                                translation.x / translationMagnitude * scale,
                                                translation.y / translationMagnitude * scale
                                                );
        
        if ((WPDirectionVectorToSwipeViewDirection(directionVector) & self.direction) > 0 &&
            (ABS(translation.x) > self.relativeDisplacementThreshold * self.bounds.size.width || // displacement
             velocityMagnitude > self.escapeVelocityThreshold) && // velocity
            (signum(translation.x) == signum(normalizedVelocity.x)) && // sign X
            (signum(translation.y) == signum(normalizedVelocity.y)) // sign Y
            ) {
            [self pushAnchorViewForCover:swipeView inDirection:directionVector andCollideInRect:self.collisionRect];
        } else {
            [self.animator removeBehavior:self.swipeViewAttachmentBehavior];
            [self.animator removeBehavior:self.anchorViewAttachmentBehavior];
            
            [self.anchorView removeFromSuperview];
            self.swipeViewSnapBehavior = [self snapBehaviorThatSnapView:swipeView
                                                                    toPoint:self.swipeViewsCenter];
            [self.animator addBehavior:self.swipeViewSnapBehavior];
            
            if ([self.delegate respondsToSelector:@selector(swipeView:didCancelSwipe:)]) {
                [self.delegate swipeView:self didCancelSwipe:swipeView];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(swipeView:didEndSwipingView:atLocation:)]) {
            [self.delegate swipeView:self didEndSwipingView:swipeView atLocation:location];
        }
    }
}

- (void)handleTap:(UITapGestureRecognizer *)tap{
    if ([self.delegate respondsToSelector:@selector(swipeView:didSelectedSwipingView:atIndex:)]) {
        [self.delegate swipeView:self didSelectedSwipingView:[self topSwipeView] atIndex:self.showIndex];
    }
}

#pragma mark - swipe out
- (void)swipeOutViewToLeft {
    [self swipeOutViewToLeft:YES];
}

- (void)swipeOutViewToRight {
    [self swipeOutViewToLeft:NO];
}

- (void)swipeOutViewToUp {
    [self swipeOutViewToUp:YES];
}

- (void)swipeOutViewToDown {
    [self swipeOutViewToUp:NO];
}

#pragma mark - swipe in
- (void)swipeInViewFromLeft {
    [self swipeInViewFromLeft:YES];
}

- (void)swipeInViewFromRight {
    [self swipeInViewFromLeft:NO];
}

- (void)swipeInViewFromUp {
    [self swipeInViewFromUp:YES];
}

- (void)swipeInViewFromDown {
    [self swipeInViewFromUp:NO];
}

#pragma mark - swipe
- (void)swipeOutViewToLeft:(BOOL)left {
    UIView *topSwipeView = [self topSwipeView];
    if (!topSwipeView) {
        return;
    }
    
    CGPoint location = CGPointMake(
                                   topSwipeView.center.x,
                                   topSwipeView.center.y*(1 + self.programaticSwipeRotationRelativeYOffsetFromCenter)
                                   );
    [self createAnchorViewForCover:topSwipeView atLocation:location shouldAttachAnchorViewToPoint:YES];
    CGVector direction = CGVectorMake((left ? -1 : 1) * self.escapeVelocityThreshold, 0);
    [self pushAnchorViewForCover:topSwipeView inDirection:direction andCollideInRect:self.collisionRect];
}

- (void)swipeOutViewToUp:(BOOL)up {
    UIView *topSwipeView = [self topSwipeView];
    if (!topSwipeView) {
        return;
    }
    
    CGPoint location = CGPointMake(
                                   topSwipeView.center.x,
                                   topSwipeView.center.y*(1 + self.programaticSwipeRotationRelativeYOffsetFromCenter)
                                   );
    [self createAnchorViewForCover:topSwipeView atLocation:location shouldAttachAnchorViewToPoint:YES];
    CGVector direction = CGVectorMake(0, (up ? -1 : 1) * self.escapeVelocityThreshold);
    [self pushAnchorViewForCover:topSwipeView inDirection:direction andCollideInRect:self.collisionRect];
}

- (void)swipeInViewFromLeft:(BOOL)left {
    CGVector direction = CGVectorMake(0, (left ? -1 : 1) * self.escapeVelocityThreshold);
    [self popAnchorViewInDirection:direction];
}

- (void)swipeInViewFromUp:(BOOL)up {
    CGVector direction = CGVectorMake(0, (up ? -1 : 1) * self.escapeVelocityThreshold);
    [self popAnchorViewInDirection:direction];
}

#pragma mark - UIDynamicAnimationHelpers

- (UICollisionBehavior *)collisionBehaviorThatBoundsView:(UIView *)view inRect:(CGRect)rect {
    if (!view) {
        return nil;
    }
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[view]];
    UIBezierPath *collisionBound = [UIBezierPath bezierPathWithRect:rect];
    [collisionBehavior addBoundaryWithIdentifier:@"coll" forPath:collisionBound];
    [collisionBehavior setCollisionMode:UICollisionBehaviorModeBoundaries];
    return collisionBehavior;
}

- (UIPushBehavior *)pushBehaviorThatPushView:(UIView *)view toDirection:(CGVector)direction {
    if (!view) {
        return nil;
    }
    UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[view] mode:UIPushBehaviorModeInstantaneous];
    pushBehavior.pushDirection = direction;
    return pushBehavior;
}

- (UISnapBehavior *)snapBehaviorThatSnapView:(UIView *)view toPoint:(CGPoint)point {
    if (!view) {
        return nil;
    }
    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:view snapToPoint:point];
    snapBehavior.damping = 0.75f;
    return snapBehavior;
}

- (UIAttachmentBehavior *)attachmentBehaviorThatAnchorsView:(UIView *)aView toView:(UIView *)anchorView {
    if (!aView) {
        return nil;
    }
    CGPoint anchorPoint = anchorView.center;
    CGPoint p = [self convertPoint:aView.center toView:self];
    UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc]
                                        initWithItem:aView
                                        offsetFromCenter:UIOffsetMake(-(p.x - anchorPoint.x), -(p.y - anchorPoint.y))
                                        attachedToItem:anchorView
                                        offsetFromCenter:UIOffsetMake(0, 0)
                                        ];
    attachment.length = 0;
    return attachment;
}

- (UIAttachmentBehavior *)attachmentBehaviorThatAnchorsView:(UIView *)aView toPoint:(CGPoint)aPoint {
    if (!aView) {
        return nil;
    }
    
    CGPoint p = aView.center;
    UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc]
                                                initWithItem:aView
                                                offsetFromCenter:UIOffsetMake(-(p.x - aPoint.x), -(p.y - aPoint.y))
                                                attachedToAnchor:aPoint
                                                ];
    attachmentBehavior.damping = 100;
    attachmentBehavior.length = 0;
    return attachmentBehavior;
}

- (void)createAnchorViewForCover:(UIView *)swipeView atLocation:(CGPoint)location shouldAttachAnchorViewToPoint:(BOOL)shouldAttachToPoint {
    [self.animator removeBehavior:self.swipeViewSnapBehavior];
    self.swipeViewSnapBehavior = nil;
    
    self.anchorView =
    [[UIView alloc] initWithFrame:CGRectMake(location.x - 500, location.y - 500, 1000, 1000)];
    [self.anchorView setBackgroundColor:[UIColor blueColor]];
    [self.anchorView setHidden:!self.isAnchorViewVisible];
    [self.anchorContainerView addSubview:self.anchorView];
    UIAttachmentBehavior *attachToView = [self attachmentBehaviorThatAnchorsView:swipeView toView:self.anchorView];
    [self.animator addBehavior:attachToView];
    self.swipeViewAttachmentBehavior = attachToView;
    
    if (shouldAttachToPoint) {
        UIAttachmentBehavior *attachToPoint = [self attachmentBehaviorThatAnchorsView:self.anchorView toPoint:location];
        [self.animator addBehavior:attachToPoint];
        self.anchorViewAttachmentBehavior = attachToPoint;
    }
}

- (void)pushAnchorViewForCover:(UIView *)swipeView inDirection:(CGVector)directionVector andCollideInRect:(CGRect)collisionRect {
    WPSwipeViewDirection direction = WPDirectionVectorToSwipeViewDirection(directionVector);
    
    if ([self.delegate respondsToSelector:@selector(swipeView:didSwipeView:inDirection:)]) {
        [self.delegate swipeView:self didSwipeView:swipeView inDirection:direction];
    }
    
    [self.animator removeBehavior:self.anchorViewAttachmentBehavior];
    
    UICollisionBehavior *collisionBehavior = [self collisionBehaviorThatBoundsView:self.anchorView inRect:collisionRect];
    collisionBehavior.collisionDelegate = self;
    [self.animator addBehavior:collisionBehavior];
    
    UIPushBehavior *pushBehavior = [self pushBehaviorThatPushView:self.anchorView toDirection:directionVector];
    [self.animator addBehavior:pushBehavior];
    
    [self.reuseCoverContainerView addSubview:self.anchorView];
    [self.reuseCoverContainerView addSubview:swipeView];
    [self.reuseCoverContainerView sendSubviewToBack:swipeView];
    
    self.anchorView = nil;
    [self loadNextSwipeViewsIfNeeded:NO];
    _lastLoadIndex = _loadIndex - self.containerView.subviews.count - 1;
    NSLog(@"del %zi:%zi", self.lastReloadIndex, self.reloadIndex);
}

- (void)popAnchorViewInDirection:(CGVector)directionVector {
    [self loadLastSwipeViewsIfNeeded:YES];
    _loadIndex = _lastLoadIndex + self.containerView.subviews.count + 1;
    NSLog(@"add %zi:%zi", self.lastReloadIndex, self.reloadIndex);
}

#pragma mark - UICollisionBehaviorDelegate

- (void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id <UIDynamicItem>)item withBoundaryIdentifier:(id <NSCopying>)identifier {
    NSMutableSet *viewsToRemove = [[NSMutableSet alloc] init];
    
    for (id aBehavior in self.animator.behaviors) {
        if ([aBehavior isKindOfClass:[UIAttachmentBehavior class]]) {
            NSArray *items = ((UIAttachmentBehavior *) aBehavior).items;
            if ([items containsObject:item]) {
                [self.animator removeBehavior:aBehavior];
                [viewsToRemove addObjectsFromArray:items];
            }
        }
        if ([aBehavior isKindOfClass:[UIPushBehavior class]]) {
            NSArray *items = ((UIPushBehavior *) aBehavior).items;
            if ([((UIPushBehavior *) aBehavior).items containsObject:item]) {
                if ([items containsObject:item]) {
                    [self.animator removeBehavior:aBehavior];
                    [viewsToRemove addObjectsFromArray:items];
                }
            }
        }
        if ([aBehavior isKindOfClass:[UICollisionBehavior class]]) {
            NSArray *items = ((UICollisionBehavior *) aBehavior).items;
            if ([((UICollisionBehavior *) aBehavior).items containsObject:item]) {
                if ([items containsObject:item]) {
                    [self.animator removeBehavior:aBehavior];
                    [viewsToRemove addObjectsFromArray:items];
                }
            }
        }
    }
    
    for (UIView *view in viewsToRemove) {
        for (UIGestureRecognizer *aGestureRecognizer in view.gestureRecognizers) {
            if ([aGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
                [view removeGestureRecognizer:aGestureRecognizer];
            }
        }
        [view removeFromSuperview];
    }
}

#pragma mark - 效果自定义
// 扑克散布效果
- (void)rotateView:(UIView *)view forDegree:(float)degree atOffsetFromCenter:(CGPoint)offset animated:(BOOL)animated {
    float duration = animated ? 0.4 : 0;
    float rotationRadian = [self degreesToRadians:degree];
    [UIView animateWithDuration:duration animations:^{
        view.center = self.swipeViewsCenter;
        CGAffineTransform transform = CGAffineTransformMakeTranslation(offset.x, offset.y);
        transform = CGAffineTransformRotate(transform, rotationRadian);
        transform = CGAffineTransformTranslate(transform, -offset.x, -offset.y);
        view.transform = transform;
    }];
}

// 梯形效果
- (void)ladderView:(UIView *)view atScale:(CGPoint)scale atOffsetFromCenter:(CGPoint)offset animated:(BOOL)animated {
    float duration = animated ? 0.4 : 0;

    [UIView animateWithDuration:duration animations:^{
        CGAffineTransform transform = CGAffineTransformMakeScale(1, 1);
        transform = CGAffineTransformTranslate(transform, offset.x, offset.y);
        transform = CGAffineTransformScale(transform, scale.x, scale.y);
        view.transform = transform;
    }];
}

- (CGFloat)degreesToRadians:(CGFloat)degrees {
    return degrees * M_PI/180.0f;
}

- (CGFloat)radiansToDegrees:(CGFloat)radians {
    return radians * 180.0f/M_PI;
}

int signum(CGFloat n) {
    return (n < 0) ? -1 : (n > 0) ? +1 : 0;
}

- (CGRect)defaultCollisionRect {
    CGSize viewSize = [UIScreen mainScreen].bounds.size;
    CGFloat collisionSizeScale = 6;
    CGSize collisionSize = CGSizeMake(viewSize.width*collisionSizeScale, viewSize.height* collisionSizeScale);
    CGRect collisionRect = CGRectMake(-collisionSize.width/2 + viewSize.width/2, -collisionSize.height/2 + viewSize.height/2, collisionSize.width, collisionSize.height);
    return collisionRect;
}

- (UIView *)nextSwipeView {
    UIView *nextView = nil;
    // 循环展示
    if (_isRecycle) {
        _loadIndex = _loadIndex%_numberOfView;
    }
    // 加载
    if ((_numberOfView == -1) || (_numberOfView > _loadIndex)) {
        // 加载swipingView
        if ([self.dataSource respondsToSelector:@selector(swipeView:nextViewOfIndex:)]) {
            nextView = [self.dataSource swipeView:self nextViewOfIndex:_loadIndex];
        }
        // 添加手势
        if (nextView) {
            // 添加滑动手势
            if (self.isAllowPanGesture) {
                [nextView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];
            }
            // 添加轻击手势
            [nextView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
            // 加载swipingView成功
            if ([self.delegate respondsToSelector:@selector(swipeView:didLoadSwipingView:atIndex:)]) {
                [self.delegate swipeView:self didLoadSwipingView:nextView atIndex:_loadIndex];
            }
            // 增加索引
            _loadIndex++;
        }
    }
    return nextView;
}

- (UIView *)lastSwipeView {
    UIView *lastView = nil;
    // 循环展示
    if (_isRecycle) {
        _lastLoadIndex = (_numberOfView + _lastLoadIndex)%_numberOfView;
    }
    // 加载
    if ((_numberOfView == -1) || (_lastLoadIndex >= 0)) {
        // 加载swipingView
        if ([self.dataSource respondsToSelector:@selector(swipeView:nextViewOfIndex:)]) {
            lastView = [self.dataSource swipeView:self nextViewOfIndex:_lastLoadIndex];
        }
        // 添加手势
        if (lastView) {
            // 添加滑动手势
            if (self.isAllowPanGesture) {
                [lastView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];
            }
            // 添加轻击手势
            [lastView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
            // 加载swipingView成功
            if ([self.delegate respondsToSelector:@selector(swipeView:didLoadSwipingView:atIndex:)]) {
                [self.delegate swipeView:self didLoadSwipingView:lastView atIndex:_lastLoadIndex];
            }
            // 增加索引
            _lastLoadIndex--;
        }
    }
    return lastView;
}

- (UIView *)topSwipeView {
    return self.containerView.subviews.lastObject;
}




#pragma mark - getters/setters
- (NSInteger)reloadIndex {
    if (_isRecycle) {
        _loadIndex = _loadIndex%_numberOfView;
    }
    return _loadIndex;
}

- (NSInteger)lastReloadIndex {
    if (_isRecycle) {
        _lastLoadIndex = (_numberOfView + _lastLoadIndex)%_numberOfView;
    }
    return _lastLoadIndex;
}

- (NSInteger)showIndex{
    NSUInteger numSwipeViews = self.containerView.subviews.count;
    numSwipeViews = (numSwipeViews<=_loadIndex) ? numSwipeViews : (numSwipeViews - _numberOfView);
    NSInteger index =  (_loadIndex - numSwipeViews);
    return index;
}

- (void)setDataSource:(id <WPSwipeViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self reloadData];
}

@end

