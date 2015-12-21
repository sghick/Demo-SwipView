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
        self.layer.borderWidth = 3;
        self.layer.borderColor = [UIColor redColor].CGColor;
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

@end
