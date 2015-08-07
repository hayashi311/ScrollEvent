//
// Created by hayashi311 on 15/08/06.
// Copyright (c) 2015 hayashi311. All rights reserved.
//

#import "HRTouchDelayGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>


@implementation HRTouchDelayGestureRecognizer {
    NSTimer* _timer;

}

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    self = [super initWithTarget:target action:action];
    if (self) {
        self.delaysTouchesBegan = YES;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(fail) userInfo:nil repeats:NO];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self fail];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self fail];
}


- (void)fail {
    self.state = UIGestureRecognizerStateFailed;
}

- (void)reset {
    [_timer invalidate];
    _timer = nil;
}


@end

