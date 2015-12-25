//
//  WCVehicleView.m
//  Demo-SwipView
//
//  Created by buding on 15/12/4.
//  Copyright © 2015年 buding. All rights reserved.
//

#import "WCVehicleView.h"

@interface WCVehicleView ()

@end

@implementation WCVehicleView

@synthesize textLabel = _textLabel;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 3;
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [UIColor colorWithRed:33/255.0 green:33/255.0 blue:33/255.0 alpha:0.5].CGColor;

        [WCVehicleView showReflection:self];
        [self addSubview:self.textLabel];
    }
    return self;
}

- (UILabel *)textLabel {
    if (_textLabel == nil) {
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 200, 50)];
        _textLabel = textLabel;
    }
    return _textLabel;
}

// 添加layer及其“倒影”
+ (void)showReflection:(UIView *)view {
    // 制作reflection
    CALayer *reflectLayer = [CALayer layer];
    reflectLayer.contents = view.layer.contents;
    reflectLayer.bounds = view.layer.bounds;
    reflectLayer.position = CGPointMake(view.layer.bounds.size.width/2, view.layer.bounds.size.height*1.5);
    reflectLayer.transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);
    
    // 给该reflection加个半透明的layer
    CALayer *blackLayer = [CALayer layer];
    blackLayer.cornerRadius = view.layer.cornerRadius;
    blackLayer.borderWidth = view.layer.borderWidth;
    blackLayer.borderColor = view.layer.borderColor;
    blackLayer.backgroundColor = [UIColor redColor].CGColor;
    blackLayer.bounds = reflectLayer.bounds;
    blackLayer.position = CGPointMake(blackLayer.bounds.size.width/2, blackLayer.bounds.size.height/2);
    blackLayer.opacity = 0.2;
    [reflectLayer addSublayer:blackLayer];
    
    // 给该reflection加个mask
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.bounds = reflectLayer.bounds;
    mask.position = CGPointMake(mask.bounds.size.width/2, mask.bounds.size.height/2);
    mask.colors = [NSArray arrayWithObjects:
                   (__bridge id)[UIColor clearColor].CGColor,
                   (__bridge id)[UIColor whiteColor].CGColor, nil];
    mask.startPoint = CGPointMake(0.5, 0.35);
    mask.endPoint = CGPointMake(0.5, 1.0);
    reflectLayer.mask = mask;
    
    // 作为layer的sublayer
    [view.layer addSublayer:reflectLayer];
}

@end
