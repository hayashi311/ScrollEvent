//
//  ViewController.m
//  ScrollEvent
//
//  Created by hayashi311 on 2015/08/05.
//  Copyright (c) 2015年 hayashi311. All rights reserved.
//

#import "ViewController.h"
#import "HRTouchDelayGestureRecognizer.h"

static const NSUInteger numberOfTaskList = 3;
static const CGFloat taskHeight = 60;

@interface HRTaskListView : UIScrollView

//@property (nonatomic, readonly) NSArray *taskViews;

@end

@implementation HRTaskListView {
    NSMutableArray *_taskViews;
    NSUInteger _indexOfSpace;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _taskViews = [NSMutableArray array];
        self.alwaysBounceVertical = YES;
        _indexOfSpace = NSUIntegerMax;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
    }
    return self;
}

- (void)appendTaskView:(UIView *)taskView {
    [_taskViews addObject:taskView];
}

- (void)setSpaceAtPoint:(CGPoint)point {
    NSUInteger indexOfSpace = [self indexAtPoint:point];
    if (_indexOfSpace != indexOfSpace) {
        _indexOfSpace = indexOfSpace;
        [self setNeedsLayout];
    }
}

- (void)resetSpace {
    if (_indexOfSpace == NSUIntegerMax) {
        return;
    }
    _indexOfSpace = NSUIntegerMax;
    [self setNeedsLayout];
}

- (void)insertTaskView:(UIView *)taskView atPoint:(CGPoint)point {
    NSUInteger indexOfSpace = [self indexAtPoint:point];
    [_taskViews insertObject:taskView atIndex:indexOfSpace];
}

- (void)removeTaskView:(UIView *)taskView {
    [_taskViews removeObject:taskView];
}

- (NSUInteger)indexAtPoint:(CGPoint)point {
    CGFloat y = point.y;
    y -= 50;
    NSInteger index = (NSInteger) (y / taskHeight);
    index = MAX(0, index);
    index = MIN(index, _taskViews.count);
    return (NSUInteger) index;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (NSUInteger j = 0; j < _taskViews.count; ++j) {
        UILabel *taskView = _taskViews[j];
        CGFloat top = taskHeight * j + 50;
        if (j >= _indexOfSpace) {
            top += taskHeight;
        }
        CGRect rect = CGRectMake(0, top, CGRectGetWidth(self.frame), taskHeight);
        taskView.frame = CGRectInset(rect, 5, 5);
    }

    self.contentSize = CGSizeMake(CGRectGetWidth(self.frame), taskHeight * _taskViews.count + 100);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer.view isKindOfClass:[UIScrollView class]] && [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        return YES;
    }
    return NO;
}

@end


@interface ViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSArray *taskListViews;

@property (nonatomic) CGPoint grabbingTouchStartPoint;
@property (nonatomic) CGPoint grabbingTouchPoint;
@property (nonatomic, strong) CADisplayLink *displayLink;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.scrollView = [[UIScrollView alloc] init];
    [self.view addSubview:self.scrollView];

    self.taskListViews = @[
            [[HRTaskListView alloc] init],
            [[HRTaskListView alloc] init],
            [[HRTaskListView alloc] init]
    ];

    for (NSUInteger i = 0; i < _taskListViews.count; ++i) {
        HRTaskListView *taskListView = _taskListViews[i];
        taskListView.backgroundColor = [UIColor whiteColor];
        [self.scrollView addSubview:taskListView];

        [self addTaskView:[NSString stringWithFormat:@"hogehoge %@", @(i)]
               toListView:taskListView];
        [self addTaskView:[NSString stringWithFormat:@"fugafuga %@", @(i)]
               toListView:taskListView];
        [self addTaskView:[NSString stringWithFormat:@"piyopiyo %@", @(i)]
               toListView:taskListView];

        [self addTaskView:[NSString stringWithFormat:@"# hogehoge %@", @(i)]
               toListView:taskListView];
        [self addTaskView:[NSString stringWithFormat:@"# fugafuga %@", @(i)]
               toListView:taskListView];
        [self addTaskView:[NSString stringWithFormat:@"# piyopiyo %@", @(i)]
               toListView:taskListView];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.scrollView.frame = (CGRect) {.origin = CGPointZero, .size = self.view.frame.size};
    CGFloat taskListWidth = 280;
    CGFloat height = CGRectGetHeight(self.scrollView.frame);
    self.scrollView.contentSize = CGSizeMake(taskListWidth * numberOfTaskList, height);

    for (NSUInteger i = 0; i < _taskListViews.count; ++i) {
        UIView *taskListView = _taskListViews[i];
        taskListView.frame = CGRectMake(taskListWidth * i, 0, taskListWidth, height);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)addTaskView:(NSString *)taskName toListView:(HRTaskListView *)taskListView {
    UILabel *taskView = [[UILabel alloc] init];
    taskView.backgroundColor = [UIColor whiteColor];
    taskView.text = taskName;
    taskView.textAlignment = NSTextAlignmentCenter;
    taskView.userInteractionEnabled = YES;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.cancelsTouchesInView = NO;
    longPress.minimumPressDuration = 0.2;
    [taskView addGestureRecognizer:longPress];

    [taskListView appendTaskView:taskView];
    [taskListView addSubview:taskView];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    UIView *taskView = gesture.view;
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [self grabTaskView:taskView withGesture:gesture];
            break;
        case UIGestureRecognizerStateChanged:
            [self moveTaskView:taskView withGesture:gesture];
            break;
        case UIGestureRecognizerStateEnded:
            [self dropTaskView:taskView withGesture:gesture];
            break;
        default:
            break;
    }
}

#pragma mark TaskViewの移動

- (void)grabTaskView:(UIView *)taskView withGesture:(UIGestureRecognizer *)gesture {
    HRTaskListView *taskListView = (HRTaskListView *) taskView.superview;
    [taskListView removeTaskView:taskView];
    [taskListView setNeedsLayout];
    self.grabbingTouchPoint = [gesture locationInView:self.view];
    self.grabbingTouchStartPoint = self.grabbingTouchPoint;
    taskView.center = [self.view convertPoint:taskView.center fromView:taskView.superview];
    [self.view addSubview:taskView];
    [UIView animateWithDuration:0.2
                     animations:^{
                         taskView.transform = CGAffineTransformMakeRotation((CGFloat) (M_PI * (10/180.f)));
                         taskView.layer.shadowOpacity = 0.5;
                         taskView.layer.shadowRadius = 4;
                         taskView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1].CGColor;
                         taskView.layer.shadowOffset = CGSizeZero;
                         [self.view layoutIfNeeded];
                         [self moveTaskView:taskView withGesture:gesture];
                     }];
    [self startTrackingTouchPoint];
}

- (void)moveTaskView:(UIView *)taskView withGesture:(UIGestureRecognizer *)gesture {
    CGPoint touchPoint = [gesture locationInView:self.view];
    taskView.center = touchPoint;
    self.grabbingTouchPoint = [gesture locationInView:self.view];

    HRTaskListView *currentTaskList = nil;
    for (HRTaskListView *taskListView in _taskListViews) {
        CGPoint locationInTaskList = [gesture locationInView:taskListView];
        if (CGRectContainsPoint([taskListView bounds], locationInTaskList)) {
            currentTaskList = taskListView;
            [currentTaskList setSpaceAtPoint:locationInTaskList];
        }
    }

    for (HRTaskListView *taskListView in _taskListViews) {
        if (taskListView != currentTaskList) {
            [taskListView resetSpace];
        }
    }

    [UIView animateWithDuration:0.2
                     animations:^{
                         [self.view layoutIfNeeded];
                     }];

}

- (void)dropTaskView:(UIView *)taskView withGesture:(UIGestureRecognizer *)gesture {
    self.grabbingTouchPoint = CGPointZero;

    for (HRTaskListView *taskListView in _taskListViews) {
        CGPoint locationInTaskList = [gesture locationInView:taskListView];
        if (CGRectContainsPoint([taskListView bounds], locationInTaskList)) {
            [taskListView insertTaskView:taskView atPoint:locationInTaskList];
            [taskListView addSubview:taskView];
            [taskListView resetSpace];
            [taskListView setNeedsLayout];
        }
    }

    [UIView animateWithDuration:0.2
                     animations:^{
                         taskView.transform = CGAffineTransformIdentity;
                         taskView.alpha = 1;
                         taskView.layer.shadowOpacity = 0;
                         taskView.layer.shadowRadius = 0;
                         taskView.layer.shadowColor = nil;
                         [self.view layoutIfNeeded];
                     }];

    [self stopTrackingTouchPoint];
}

- (void)startTrackingTouchPoint {
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollWithGrabbingTouchPoint)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopTrackingTouchPoint {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)scrollWithGrabbingTouchPoint {
    if (!CGPointEqualToPoint(CGPointZero, self.grabbingTouchPoint)) {

        CGRect left = CGRectMake(0, 0, CGRectGetWidth(self.view.frame) / 4.f, CGRectGetHeight(self.view.frame));
        CGRect right = CGRectMake(
                (CGRectGetWidth(self.view.frame) / 4.f) * 3.f, 0,
                CGRectGetWidth(self.view.frame) / 4.f, CGRectGetHeight(self.view.frame)
        );

        CGPoint contentOffset = self.scrollView.contentOffset;
        if (CGRectContainsPoint(left, self.grabbingTouchPoint) && self.grabbingTouchPoint.x < self.grabbingTouchStartPoint.x) {
            contentOffset.x -= 8;
            if (contentOffset.x > 0) {
                [self.scrollView setContentOffset:contentOffset animated:NO];
            }
        } else if (CGRectContainsPoint(right, self.grabbingTouchPoint) && self.grabbingTouchPoint.x > self.grabbingTouchStartPoint.x) {
            contentOffset.x += 8;
            if ((contentOffset.x + CGRectGetWidth(self.scrollView.frame)) <= self.scrollView.contentSize.width) {
                [self.scrollView setContentOffset:contentOffset animated:NO];
            }
        }
    }
}

@end

