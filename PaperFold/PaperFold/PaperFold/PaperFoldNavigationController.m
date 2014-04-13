//
//  PaperFoldNavigationController.m
//  PaperFold-ContainmentView
//
//  Created by honcheng on 10/8/12.
//  Copyright (c) 2012 honcheng. All rights reserved.
//

#import "PaperFoldNavigationController.h"

@implementation PaperFoldNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
  self = [super init];
  if(self) {
    self.view.autoresizesSubviews = YES;

    CGSize size = self.view.bounds.size;

    _paperFoldView = [[PaperFoldView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    [self.view addSubview:_paperFoldView];
    _paperFoldView.delegate = self;
    _paperFoldView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    _rootViewController = rootViewController;
    _rootViewController.view.frame = CGRectMake(0, 0, size.width, size.height);
    _rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _paperFoldView.centerContentView = _rootViewController.view;
  }
  return self;
}

- (void)setRightViewController:(UIViewController *)rightViewController width:(float)width rightViewFoldCount:(int)rightViewFoldCount rightViewPullFactor:(float)rightViewPullFactor
{
  _rightViewController = rightViewController;

  self.rightViewController.view.frame = CGRectMake(0, 0, width, [self.view bounds].size.height);
  [self.paperFoldView setRightFoldContentView:self.rightViewController.view foldCount:rightViewFoldCount pullFactor:rightViewFoldCount];
}

- (void)setLeftViewController:(UIViewController *)leftViewController width:(float)width
{
  _leftViewController = leftViewController;

  self.leftViewController.view.frame = CGRectMake(0, 0, width, [self.view bounds].size.height);
  [self.paperFoldView setLeftFoldContentView:self.leftViewController.view foldCount:3 pullFactor:0.9];
}

- (void)paperFoldView:(id)paperFoldView didFoldAutomatically:(BOOL)automated toState:(PaperFoldState)paperFoldState
{
  if(paperFoldState == PaperFoldStateDefault) {
    if(self.leftViewController) {
      [self.leftViewController viewWillDisappear:YES];
      [self.leftViewController viewDidDisappear:YES];
    }
    if(self.rightViewController) {
      [self.rightViewController viewWillDisappear:YES];
      [self.rightViewController viewDidDisappear:YES];
    }
    [self.rootViewController viewWillAppear:YES];
    [self.rootViewController viewDidAppear:YES];
  } else if(paperFoldState == PaperFoldStateLeftUnfolded) {
    [self.rootViewController viewWillDisappear:YES];
    [self.rootViewController viewDidDisappear:YES];
    [self.leftViewController viewWillAppear:YES];
    [self.leftViewController viewDidAppear:YES];
  } else if(paperFoldState == PaperFoldStateRightUnfolded) {
    [self.rootViewController viewWillDisappear:YES];
    [self.rootViewController viewDidDisappear:YES];
    [self.rightViewController viewWillAppear:YES];
    [self.rightViewController viewDidAppear:YES];
  }
}

@end
