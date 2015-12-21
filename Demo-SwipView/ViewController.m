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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.swipeDataSource = @[[UIColor redColor], [UIColor blueColor], [UIColor cyanColor]];
    
    [self.view addSubview:self.swipeView];
    
    [self.swipeView reloadData];
}

- (WPSwipeView *)swipeView {
    if (_swipeView == nil) {
        WPSwipeView *swipeView = [[WPSwipeView alloc] initWithFrame:CGRectMake(10, 180, 300, 150)];
        swipeView.programaticSwipeRotationRelativeYOffsetFromCenter = 0;
        swipeView.swipeViewAnimate = WPSwipeViewAnimateLadder2;
        swipeView.direction = WPSwipeViewDirectionNone;
        swipeView.numberOfViewsPrefetched = 4;
        swipeView.isAllowPanGesture = NO;
        swipeView.ladderOffset = 3;
        swipeView.ladderMargin = 6;
        swipeView.isRecycle = YES;
        swipeView.dataSource = self;
        swipeView.delegate = self;
        
        UISwipeGestureRecognizer *swipLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipLeft:)];
        swipLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [swipeView addGestureRecognizer:swipLeft];
        
        UISwipeGestureRecognizer *swipRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipRight:)];
        swipRight.direction = UISwipeGestureRecognizerDirectionRight;
        [swipeView addGestureRecognizer:swipRight];
        
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

#pragma mark - actions
- (void)swipLeft:(UISwipeGestureRecognizer *)sender {
    [self.swipeView swipeOutViewToLeft];
}

- (void)swipRight:(UISwipeGestureRecognizer *)sender {
    [self.swipeView swipeInViewFromLeft];
}

@end
