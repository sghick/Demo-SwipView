//
//  ViewController.m
//  Demo-SwipView
//
//  Created by buding on 15/12/4.
//  Copyright © 2015年 buding. All rights reserved.
//

#import "ViewController.h"
#import "WPSwipeView.h"
#import "WCVehicleView.h"

@interface ViewController () <
    WPSwipeViewDataSource,
    WPSwipeViewDelegate >

@property (strong, nonatomic) WPSwipeView *swipeView;

@property (strong, nonatomic) NSArray *swipeDataSource;

@property (assign, nonatomic) CGPoint lastTranslation;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor greenColor];
    
    self.swipeDataSource = @[[UIColor redColor],
                             [UIColor blueColor],
                             [UIColor cyanColor],
                             [UIColor blueColor],
                             [UIColor blueColor],
                             [UIColor cyanColor],
                             [UIColor blueColor],
                             [UIColor blueColor],
                             [UIColor cyanColor],
                             [UIColor blueColor],
                             [UIColor cyanColor]];
    
    [self.view addSubview:self.swipeView];
}

- (WPSwipeView *)swipeView {
    if (_swipeView == nil) {
        WPSwipeView *swipeView = [[WPSwipeView alloc] initWithFrame:CGRectMake(30, 180, 300, 150)];
        swipeView.programaticSwipeRotationRelativeYOffsetFromCenter = 0;
        swipeView.translucenceState = WPTranslucenceStateDescending;
        swipeView.swipeViewAnimate = WPSwipeViewAnimateLadder2;
        swipeView.direction = WPSwipeViewDirectionLeft;
        swipeView.numberOfViewsPrefetched = 5;
        swipeView.isAllowOffsetInPan = NO;
        swipeView.ladderOffset = 3;
        swipeView.ladderMargin = 6;
        swipeView.isRecycle = YES;
        swipeView.delegate = self;
        swipeView.dataSource = self;
        
        _swipeView = swipeView;
    }
    return _swipeView;
}

#pragma mark - WPSwipeViewDataSource, WPSwipeViewDelegate
- (NSInteger)numberOfSwipeView:(WPSwipeView *)swipeView {
    return self.swipeDataSource.count;
}

- (UIView *)swipeView:(WPSwipeView *)swipeView nextViewOfIndex:(NSInteger)index {
    WCVehicleView *view = [[WCVehicleView alloc] initWithFrame:swipeView.bounds];
    view.textLabel.text = [NSString stringWithFormat:@"this is number:%zi", index];
    return view;
}

- (void)swipeView:(WPSwipeView *)swipeView didEndSwipingView:(UIView *)view atLocation:(CGPoint)location translation:(CGPoint)translation {
    self.lastTranslation = translation;
}

- (void)swipeView:(WPSwipeView *)swipeView didSelectedSwipingView:(UIView *)view atIndex:(NSInteger)index {
    [swipeView swipeInViewFromLeft];
}

#pragma mark - actions

@end
