/**
 * Copyright (c) 2012 Muh Hon Cheng
 * Created by honcheng on 6/2/12.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject
 * to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
 * WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT
 * SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 * IN CONNECTION WITH THE SOFTWARE OR
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * @author 		Muh Hon Cheng <honcheng@gmail.com>
 * @copyright	2012	Muh Hon Cheng
 * @version
 *
 */


#import "PaperFoldView.h"

@interface PaperFoldView ()

@property (nonatomic, copy) CompletionBlock completionBlock;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *leftFoldPanGestureRecognizer;

// indicate if the divider line should be visible
@property (nonatomic, assign) BOOL showDividerLines;

- (void)onContentViewPannedHorizontally:(UIPanGestureRecognizer *)gesture;
- (void)onContentViewPannedVertically:(UIPanGestureRecognizer *)gesture;

@end

@implementation PaperFoldView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self) {
    [self initialize];
  }
  return self;
}

- (void)awakeFromNib
{
  [self initialize];
}

- (void)initialize
{
  _useOptimizedScreenshot = YES;

  self.backgroundColor = [UIColor darkGrayColor];
  self.autoresizesSubviews = YES;
  self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

  _contentView = [[TouchThroughUIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
  _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self addSubview:_contentView];
  _contentView.backgroundColor = [UIColor whiteColor];
  _contentView.autoresizesSubviews = YES;

  self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onContentViewPanned:)];
  self.panGestureRecognizer.delegate = self;
  [_contentView addGestureRecognizer:self.panGestureRecognizer];

  self.leftFoldPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onContentViewPanned:)];
  self.leftFoldPanGestureRecognizer.delegate = self;

  _state = PaperFoldStateDefault;
  _lastState = _state;
  _enableRightFoldDragging = NO;
  _enableLeftFoldDragging = NO;
  _enableBottomFoldDragging = NO;
  _enableTopFoldDragging = NO;
  _restrictedDraggingRect = CGRectNull;
  _showDividerLines = NO;
}

- (void)setFrame:(CGRect)frame
{
  [super setFrame:frame];

  CGRect leftFoldViewFrame = self.leftFoldView.frame;
  leftFoldViewFrame.size.height = frame.size.height;
  self.leftFoldView.frame = leftFoldViewFrame;

  CGRect rightFoldViewFrame = self.rightFoldView.frame;
  rightFoldViewFrame.size.height = frame.size.height;
  self.rightFoldView.frame = rightFoldViewFrame;
}

- (void)setEnabled:(BOOL)enabled
{
  _enabled = enabled;
  self.userInteractionEnabled = enabled;
  self.panGestureRecognizer.enabled = enabled;
  self.leftFoldPanGestureRecognizer.enabled = enabled;
}

- (void)setCenterContentView:(UIView *)view
{
  view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  [self.contentView addSubview:view];
}

- (void)setLeftFoldContentView:(UIView *)view foldCount:(int)leftViewFoldCount pullFactor:(float)leftViewPullFactor
{
  if(self.leftFoldView)
    [self.leftFoldView removeFromSuperview];

  self.leftFoldView = [[MultiFoldView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, self.frame.size.height) foldDirection:FoldDirectionHorizontalLeftToRight folds:leftViewFoldCount pullFactor:leftViewPullFactor];
  self.leftFoldView.delegate = self;
  self.leftFoldView.useOptimizedScreenshot = self.useOptimizedScreenshot;
  self.leftFoldView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  [self insertSubview:self.leftFoldView belowSubview:self.contentView];
  self.leftFoldView.content = view;
  self.leftFoldView.hidden = YES;
  view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  [self.leftFoldView addGestureRecognizer:self.leftFoldPanGestureRecognizer];

  /*UIView *line = [[UIView alloc] initWithFrame:CGRectMake(-1,0,1,self.frame.size.height)];
  [line setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
  [self.contentView addSubview:line];
  [line setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:0.5]];
  line.alpha = 0;
  self.leftDividerLine = line;*/

  self.enableLeftFoldDragging = YES;
}

- (void)setBottomFoldContentView:(UIView *)view
{
  if(self.bottomFoldView)
    [self.bottomFoldView removeFromSuperview];

  self.bottomFoldView = [[FoldView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - view.frame.size.height, view.frame.size.width, view.frame.size.height) foldDirection:FoldDirectionVertical];
  self.bottomFoldView.useOptimizedScreenshot = self.useOptimizedScreenshot;
  self.bottomFoldView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self insertSubview:self.bottomFoldView belowSubview:self.contentView];
  self.bottomFoldView.content = view;
  self.bottomFoldView.hidden = YES;
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth;

  /*UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 1)];
  [line setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
  [self.contentView addSubview:line];
  [line setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:0.5]];
  line.alpha = 0;
  self.bottomDividerLine = line;*/

  self.enableBottomFoldDragging = YES;
}

- (void)setRightFoldContentView:(UIView *)view foldCount:(int)rightViewFoldCount pullFactor:(float)rightViewPullFactor
{
  self.rightFoldView = [[MultiFoldView alloc] initWithFrame:CGRectMake(self.frame.size.width, 0, view.frame.size.width, self.frame.size.height) foldDirection:FoldDirectionHorizontalRightToLeft folds:rightViewFoldCount pullFactor:rightViewPullFactor];
  self.rightFoldView.delegate = self;
  self.rightFoldView.useOptimizedScreenshot = self.useOptimizedScreenshot;
  self.rightFoldView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
  [self.contentView insertSubview:self.rightFoldView atIndex:0];
  self.rightFoldView.content = view;
  self.rightFoldView.hidden = YES;
  view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

  /*UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width, 0, 1, self.frame.size.height)];
  [line setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
  [self.contentView addSubview:line];
  [line setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight];
  [line setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:0.5]];
  line.alpha = 0;
  self.rightDividerLine = line;*/

  self.enableRightFoldDragging = YES;
}

- (void)setTopFoldContentView:(UIView *)view topViewFoldCount:(int)topViewFoldCount topViewPullFactor:(float)topViewPullFactor
{
  self.topFoldView = [[MultiFoldView alloc] initWithFrame:CGRectMake(0, -1 * view.frame.size.height, view.frame.size.width, view.frame.size.height) foldDirection:FoldDirectionVertical folds:topViewFoldCount pullFactor:topViewPullFactor];
  self.topFoldView.delegate = self;
  self.topFoldView.useOptimizedScreenshot = self.useOptimizedScreenshot;
  self.topFoldView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
  [self.contentView insertSubview:self.topFoldView atIndex:0];
  self.topFoldView.content = view;
  self.topFoldView.hidden = YES;
  view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

  /*UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, -1, self.contentView.frame.size.width, 1)];
  [line setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
  [self.contentView addSubview:line];
  [line setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight];
  [line setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:0.5]];
  line.alpha = 0;
  self.topDividerLine = line;*/

  self.enableTopFoldDragging = YES;
}

- (void)onContentViewPanned:(UIPanGestureRecognizer *)gesture
{
  // cancel gesture if another animation has not finished yet
  if([self.animationTimer isValid])
    return;

  BOOL isVoiceOverRunning = UIAccessibilityIsVoiceOverRunning();

  if([gesture state] == UIGestureRecognizerStateBegan) {
    // show the divider while dragging
    [self setShowDividerLines:YES animated:YES];

    CGPoint velocity = [gesture velocityInView:self];
    if(fabs(velocity.x) > fabs(velocity.y)) {
      if(self.state == PaperFoldStateDefault) {
        self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionHorizontal;

        if(isVoiceOverRunning) {
          if(velocity.x > 0)
            [self setPaperFoldState:PaperFoldStateLeftUnfolded animated:YES];
          else if(velocity.x < 0)
            [self setPaperFoldState:PaperFoldStateRightUnfolded animated:YES];
        }
      } else {
        if(isVoiceOverRunning)
          [self setPaperFoldState:PaperFoldStateDefault animated:YES];

        if(self.enableHorizontalEdgeDragging) {
          CGPoint location = [gesture locationInView:self.contentView];
          if(location.x < kEdgeScrollWidth || location.x > (self.contentView.frame.size.width - kEdgeScrollWidth))
            self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionHorizontal;
          else
            self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionVertical;
        } else
          self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionHorizontal;
      }
    } else {
      if(self.state == PaperFoldStateDefault)
        self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionVertical;
    }
  } else if(!isVoiceOverRunning) {
    if(self.paperFoldInitialPanDirection == PaperFoldInitialPanDirectionHorizontal)
      [self onContentViewPannedHorizontally:gesture];
    else
      [self onContentViewPannedVertically:gesture];

    if(gesture.state != UIGestureRecognizerStateChanged) {
      // hide the divider line
      [self setShowDividerLines:NO animated:YES];
    }
  }
}

- (void)onContentViewPannedVertically:(UIPanGestureRecognizer *)gesture
{
  self.rightFoldView.hidden = YES;
  self.leftFoldView.hidden = YES;
  self.bottomFoldView.hidden = NO;
  self.topFoldView.hidden = NO;

  CGPoint point = [gesture translationInView:self];
  UIGestureRecognizerState gestureState = gesture.state;
  if(gestureState == UIGestureRecognizerStateChanged) {
    if(_state == PaperFoldStateDefault) {
      // animate folding when panned
      [self animateWithContentOffset:point panned:YES];
    } else if(_state == PaperFoldStateBottomUnfolded) {
      CGPoint adjustedPoint = CGPointMake(point.x, point.y - self.bottomFoldView.frame.size.height);
      [self animateWithContentOffset:adjustedPoint panned:YES];
    } else if(_state == PaperFoldStateTopUnfolded) {
      CGPoint adjustedPoint = CGPointMake(point.x, point.y + self.topFoldView.frame.size.height);
      [self animateWithContentOffset:adjustedPoint panned:YES];
    }
  } else if(gestureState == UIGestureRecognizerStateEnded || gestureState == UIGestureRecognizerStateCancelled) {
    float y = point.y;
    if(y <= 0.0) { // offset to the top
      if((-y >= kBottomViewUnfoldThreshold * self.bottomFoldView.frame.size.height && _state == PaperFoldStateDefault) || -self.contentView.frame.origin.y == self.bottomFoldView.frame.size.height) {
        if(self.enableBottomFoldDragging) {
          // if offset more than threshold, open fully
          self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(unfoldBottomView:) userInfo:nil repeats:YES];
          return;
        }
      }
    } else if(y > 0) {
      if((y >= kTopViewUnfoldThreshold * self.topFoldView.frame.size.height && _state == PaperFoldStateDefault) || self.contentView.frame.origin.y == self.topFoldView.frame.size.height) {
        if(self.enableTopFoldDragging) {
          // if offset more than threshold, open fully
          self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(unfoldTopView:) userInfo:nil repeats:YES];
          return;
        }
      }
    }
    // after panning completes
    // if offset does not exceed threshold
    // use NSTimer to create manual animation to restore view
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(restoreView:) userInfo:nil repeats:YES];
    //[self setPaperFoldState:PaperFoldStateDefault];
  }
}

- (void)onContentViewPannedHorizontally:(UIPanGestureRecognizer *)gesture
{
  self.rightFoldView.hidden = NO;
  self.leftFoldView.hidden = NO;
  self.bottomFoldView.hidden = YES;
  self.topFoldView.hidden = YES;

  CGPoint point = [gesture translationInView:self];
  UIGestureRecognizerState gestureState = gesture.state;
  if(gestureState == UIGestureRecognizerStateChanged) {
    if(_state == PaperFoldStateDefault) {
      // animate folding when panned
      [self animateWithContentOffset:point panned:YES];
    } else if(_state == PaperFoldStateLeftUnfolded) {
      CGPoint adjustedPoint = CGPointMake(point.x + self.leftFoldView.frame.size.width, point.y);
      [self animateWithContentOffset:adjustedPoint panned:YES];
    } else if(_state == PaperFoldStateRightUnfolded) {
      CGPoint adjustedPoint = CGPointMake(point.x - self.rightFoldView.frame.size.width, point.y);
      [self animateWithContentOffset:adjustedPoint panned:YES];
    }
  } else if(gestureState == UIGestureRecognizerStateEnded || gestureState == UIGestureRecognizerStateCancelled) {
    float x = point.x;
    if(x >= 0.0) { // offset to the right
      if((x >= kLeftViewUnfoldThreshold * self.leftFoldView.frame.size.width && _state == PaperFoldStateDefault) || self.contentView.frame.origin.x == self.leftFoldView.frame.size.width) {
        if(self.enableLeftFoldDragging) {
          // if offset more than threshold, open fully
          self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(unfoldLeftView:) userInfo:nil repeats:YES];
          return;
        }
      }
    } else if(x < 0) {
      if((x <= -kRightViewUnfoldThreshold * self.rightFoldView.frame.size.width && _state == PaperFoldStateDefault) || self.contentView.frame.origin.x == -self.rightFoldView.frame.size.width) {
        if(self.enableRightFoldDragging) {
          // if offset more than threshold, open fully
          self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(unfoldRightView:) userInfo:nil repeats:YES];
          return;
        }
      }
    }

    // after panning completes
    // if offset does not exceed threshold
    // use NSTimer to create manual animation to restore view
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(restoreView:) userInfo:nil repeats:YES];
    //self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionNone;
  }
}

- (void)animateWithContentOffset:(CGPoint)point panned:(BOOL)panned
{
  if(self.paperFoldInitialPanDirection == PaperFoldInitialPanDirectionHorizontal) {
    float x = point.x;
    // if offset to the right, show the left view
    // if offset to the left, show the right multi-fold view

    if(self.state != self.lastState)
      self.lastState = self.state;

    if(x > 0.0) {
      if(self.enableLeftFoldDragging || !panned) {
        // set the limit of the right offset
        if(x >= self.leftFoldView.frame.size.width) {
          self.lastState = self.state;
          self.state = PaperFoldStateLeftUnfolded;
          x = self.leftFoldView.frame.size.width;
          if(self.lastState != PaperFoldStateLeftUnfolded)
            [self finishForState:PaperFoldStateLeftUnfolded];
        }
        self.contentView.transform = CGAffineTransformMakeTranslation(x, 0);
        //[self.leftFoldView unfoldWithParentOffset:-x];
        [self.leftFoldView unfoldWithParentOffset:x];

        if([self.delegate respondsToSelector:@selector(paperFoldView:viewDidOffset:)])
          [self.delegate paperFoldView:self viewDidOffset:CGPointMake(x, 0)];
      }
    } else if(x < 0.0) {
      if(self.enableRightFoldDragging || !panned) {
        // set the limit of the left offset
        // original x value not changed, to be sent to multi-fold view
        float x1 = x;
        if(x1 <= -self.rightFoldView.frame.size.width) {
          self.lastState = self.state;
          self.state = PaperFoldStateRightUnfolded;
          x1 = -self.rightFoldView.frame.size.width;
          if(self.lastState != PaperFoldStateRightUnfolded)
            [self finishForState:PaperFoldStateRightUnfolded];
        }
        self.contentView.transform = CGAffineTransformMakeTranslation(x1, 0);
        [self.rightFoldView unfoldWithParentOffset:x];

        if([self.delegate respondsToSelector:@selector(paperFoldView:viewDidOffset:)])
          [self.delegate paperFoldView:self viewDidOffset:CGPointMake(x, 0)];
      }
    } else {
      self.contentView.transform = CGAffineTransformMakeTranslation(0, 0);
      [self.leftFoldView unfoldWithParentOffset:-x];
      [self.rightFoldView unfoldWithParentOffset:x];
      self.state = PaperFoldStateDefault;

      if([self.delegate respondsToSelector:@selector(paperFoldView:viewDidOffset:)])
        [self.delegate paperFoldView:self viewDidOffset:CGPointMake(x, 0)];
    }
  } else if(self.paperFoldInitialPanDirection == PaperFoldInitialPanDirectionVertical) {
    float y = point.y;
    // if offset to the top, show the bottom view
    // if offset to the bottom, show the top multi-fold view

    if(self.state != self.lastState)
      self.lastState = self.state;

    if(y < 0.0) {
      if(self.enableBottomFoldDragging || !panned) {
        // set the limit of the top offset
        if(-y >= self.bottomFoldView.frame.size.height) {
          self.lastState = self.state;
          self.state = PaperFoldStateBottomUnfolded;
          y = -self.bottomFoldView.frame.size.height;
        }
        self.contentView.transform = CGAffineTransformMakeTranslation(0, y);
        [self.bottomFoldView unfoldWithParentOffset:y];

        if([self.delegate respondsToSelector:@selector(paperFoldView:viewDidOffset:)])
          [self.delegate paperFoldView:self viewDidOffset:CGPointMake(0, y)];
      }
    } else if(y > 0.0) {
      if(self.enableTopFoldDragging || !panned) {
        // set the limit of the bottom offset
        // original y value not changed, to be sent to multi-fold view
        float y1 = y;
        if(y1 >= self.topFoldView.frame.size.height) {
          self.lastState = self.state;
          self.state = PaperFoldStateTopUnfolded;
          y1 = self.topFoldView.frame.size.height;
        }
        self.contentView.transform = CGAffineTransformMakeTranslation(0, y1);
        [self.topFoldView unfoldWithParentOffset:y];

        if([self.delegate respondsToSelector:@selector(paperFoldView:viewDidOffset:)])
          [self.delegate paperFoldView:self viewDidOffset:CGPointMake(0, y)];
      }
    } else {
      self.contentView.transform = CGAffineTransformMakeTranslation(0, 0);
      [self.bottomFoldView unfoldWithParentOffset:y];
      [self.topFoldView unfoldWithParentOffset:y];
      self.state = PaperFoldStateDefault;

      if([self.delegate respondsToSelector:@selector(paperFoldView:viewDidOffset:)])
        [self.delegate paperFoldView:self viewDidOffset:CGPointMake(0, y)];
    }
  }
}

- (void)unfoldBottomView:(NSTimer *)timer
{
  if(self.animationTimer != timer) {
    [timer invalidate];
    return;
  }

  if([self checkAnimationTimer:timer state:PaperFoldStateBottomUnfolded])
    return;

  self.topFoldView.hidden = NO;
  self.bottomFoldView.hidden = NO;
  self.leftFoldView.hidden = YES;
  self.rightFoldView.hidden = YES;

  self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionVertical;

  CGAffineTransform transform = self.contentView.transform;
  float y = transform.ty - (self.bottomFoldView.frame.size.height + transform.ty) / 4;
  transform = CGAffineTransformMakeTranslation(0, y);
  self.contentView.transform = transform;

  if(-y >= self.bottomFoldView.frame.size.height - 2) {
    [timer invalidate];
    transform = CGAffineTransformMakeTranslation(0, -self.bottomFoldView.frame.size.height);
    self.contentView.transform = transform;

    if(self.lastState != PaperFoldStateBottomUnfolded)
      [self finishForState:PaperFoldStateBottomUnfolded];
  }

  // use the x value to animate folding
  [self animateWithContentOffset:CGPointMake(0, self.contentView.frame.origin.y) panned:NO];
}

// unfold the top view
- (void)unfoldTopView:(NSTimer *)timer
{
  if(self.animationTimer != timer) {
    [timer invalidate];
    return;
  }

  if([self checkAnimationTimer:timer state:PaperFoldStateTopUnfolded])
    return;

  self.topFoldView.hidden = NO;
  self.bottomFoldView.hidden = NO;
  self.leftFoldView.hidden = YES;
  self.rightFoldView.hidden = YES;

  self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionVertical;

  CGAffineTransform transform = self.contentView.transform;
  float y = transform.ty + (self.topFoldView.frame.size.height - transform.ty) / 8;
  transform = CGAffineTransformMakeTranslation(0, y);
  self.contentView.transform = transform;

  if(y >= self.topFoldView.frame.size.height - 2) {
    [timer invalidate];
    transform = CGAffineTransformMakeTranslation(0, self.topFoldView.frame.size.height);
    self.contentView.transform = transform;

    if(self.lastState != PaperFoldStateTopUnfolded)
      [self finishForState:PaperFoldStateTopUnfolded];
  }

  // use the x value to animate folding
  [self animateWithContentOffset:CGPointMake(0, self.contentView.frame.origin.y) panned:NO];
}

// unfold the left view
- (void)unfoldLeftView:(NSTimer *)timer
{
  if(self.animationTimer != timer) {
    [timer invalidate];
    return;
  }

  if([self checkAnimationTimer:timer state:PaperFoldStateLeftUnfolded])
    return;

  self.topFoldView.hidden = YES;
  self.bottomFoldView.hidden = YES;
  self.leftFoldView.hidden = NO;
  self.rightFoldView.hidden = NO;

  CGAffineTransform transform = self.contentView.transform;
  CGFloat width = self.leftFoldView.frame.size.width;
  float x = transform.tx + (width - transform.tx) / 8;
  transform = CGAffineTransformMakeTranslation(x, 0);
  self.contentView.transform = transform;
  if(x >= width - 2) {
    [timer invalidate];
    transform = CGAffineTransformMakeTranslation(width, 0);
    self.contentView.transform = transform;
  }

  // use the x value to animate folding
  [self animateWithContentOffset:CGPointMake(self.contentView.frame.origin.x, 0) panned:NO];
}

// unfold the right view
- (void)unfoldRightView:(NSTimer *)timer
{
  if(self.animationTimer != timer) {
    [timer invalidate];
    return;
  }

  if([self checkAnimationTimer:timer state:PaperFoldStateRightUnfolded])
    return;

  self.topFoldView.hidden = YES;
  self.bottomFoldView.hidden = YES;
  self.leftFoldView.hidden = NO;
  self.rightFoldView.hidden = NO;

  CGAffineTransform transform = self.contentView.transform;
  CGFloat width = self.rightFoldView.frame.size.width;
  float x = transform.tx - (transform.tx + width) / 8;
  transform = CGAffineTransformMakeTranslation(x, 0);
  self.contentView.transform = transform;

  if(x <= -width + 2) {
    [timer invalidate];
    transform = CGAffineTransformMakeTranslation(-width, 0);
    self.contentView.transform = transform;
  }

  // use the x value to animate folding
  [self animateWithContentOffset:CGPointMake(self.contentView.frame.origin.x, 0) panned:NO];
}

// restore contentView back to original position
- (void)restoreView:(NSTimer *)timer
{
  if(self.animationTimer != timer) {
    [timer invalidate];
    return;
  }

  if([self checkAnimationTimer:timer state:PaperFoldStateDefault])
    return;

  if(self.paperFoldInitialPanDirection == PaperFoldInitialPanDirectionHorizontal) {
    CGAffineTransform transform = self.contentView.transform;
    // restoring the x position 3/4 of the last x translation
    float x = transform.tx / 8 * 7;
    transform = CGAffineTransformMakeTranslation(x, 0);
    self.contentView.transform = transform;

    // if -5<x<5, stop timer animation
    if((x >= 0 && x < 2) || (x <= 0 && x > -2)) {
      [timer invalidate];
      transform = CGAffineTransformMakeTranslation(0, 0);
      self.contentView.transform = transform;
      [self animateWithContentOffset:CGPointMake(0, 0) panned:NO];

      if(self.lastState != PaperFoldStateDefault)
        [self finishForState:PaperFoldStateDefault];
      self.state = PaperFoldStateDefault;
    } else {
      // use the x value to animate folding
      [self animateWithContentOffset:CGPointMake(self.contentView.frame.origin.x, 0) panned:NO];
    }
  } else if(self.paperFoldInitialPanDirection == PaperFoldInitialPanDirectionVertical) {
    CGAffineTransform transform = self.contentView.transform;
    // restoring the y position 3/4 of the last y translation
    float y = transform.ty / 4 * 3;
    transform = CGAffineTransformMakeTranslation(0, y);
    self.contentView.transform = transform;

    // if -5<x<5, stop timer animation
    if((y >= 0 && y < 2) || (y <= 0 && y > -2)) {
      [timer invalidate];
      transform = CGAffineTransformMakeTranslation(0, 0);
      self.contentView.transform = transform;
      [self animateWithContentOffset:CGPointMake(0, 0) panned:NO];

      if(self.lastState != PaperFoldStateDefault)
        [self finishForState:PaperFoldStateDefault];
      self.state = PaperFoldStateDefault;
    } else {
      // use the x value to animate folding
      [self animateWithContentOffset:CGPointMake(0, self.contentView.frame.origin.y) panned:NO];
    }
  }
}

- (BOOL)checkAnimationTimer:(NSTimer *)timer state:(PaperFoldState)state
{
  NSDate *startDate = timer.userInfo;
  NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:startDate];
  if(elapsedTime > 1.0) {
    [timer invalidate];
    [self setPaperFoldState:state animated:NO];
    return YES;
  }
  return NO;
}

- (void)setPaperFoldState:(PaperFoldState)state animated:(BOOL)animated
{
  if([self.animationTimer isValid]) {
    [self.animationTimer invalidate];
    self.animationTimer = nil;
  }

  if(self.state == state) {
    [self finishForState:state];
    return;
  }

  if(animated) {
    self.paperFoldState = state;
  } else {
    self.topFoldView.hidden = YES;
    self.bottomFoldView.hidden = YES;
    self.leftFoldView.hidden = YES;
    self.rightFoldView.hidden = YES;

    self.lastState = self.state;
    self.state = state;

    if(state == PaperFoldStateDefault) {
      CGAffineTransform transform = CGAffineTransformMakeTranslation(0, 0);
      self.contentView.transform = transform;
    } else if(state == PaperFoldStateLeftUnfolded) {
      self.leftFoldView.hidden = NO;
      CGAffineTransform transform = CGAffineTransformMakeTranslation(self.leftFoldView.frame.size.width, 0);
      self.contentView.transform = transform;
      [self.leftFoldView unfoldWithoutAnimation];
    } else if(state == PaperFoldStateRightUnfolded) {
      self.rightFoldView.hidden = NO;
      CGAffineTransform transform = CGAffineTransformMakeTranslation(-self.rightFoldView.frame.size.width, 0);
      self.contentView.transform = transform;
      [self.rightFoldView unfoldWithoutAnimation];
    }
    [self finishForState:state];
  }
}

- (void)setPaperFoldState:(PaperFoldState)state
{
  if([self.animationTimer isValid]) {
    [self.animationTimer invalidate];
    self.animationTimer = nil;
  }

  if(self.state == state) {
    [self finishForState:state];
    return;
  }

  self.isAutomatedFolding = YES;
  self.animationTimer = nil;

  SEL selector = nil;
  switch(state) {
    case PaperFoldStateDefault:
      selector = @selector(restoreView:);
      break;
    case PaperFoldStateLeftUnfolded:
      selector = @selector(unfoldLeftView:);
      break;
    case PaperFoldStateRightUnfolded:
      selector = @selector(unfoldRightView:);
      break;
    case PaperFoldStateTopUnfolded:
      selector = @selector(unfoldTopView:);
      break;
    case PaperFoldStateBottomUnfolded:
      selector = @selector(unfoldBottomView:);
      break;
    default:
      break;
  }

  if(selector)
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:selector userInfo:[NSDate date] repeats:YES];
}

- (void)setPaperFoldState:(PaperFoldState)state animated:(BOOL)animated completion:(void (^)())completion
{
  self.completionBlock = completion;
  [self setPaperFoldState:state animated:animated];
}

- (void)finishForState:(PaperFoldState)state
{
  [self setShowDividerLines:NO animated:YES];

  if(self.completionBlock) {
    self.completionBlock();
    self.completionBlock = nil;
  }

  if([self.delegate respondsToSelector:@selector(paperFoldView:didFoldAutomatically:toState:)])
    [self.delegate paperFoldView:self didFoldAutomatically:self.isAutomatedFolding toState:state];

  // no more animations
  self.isAutomatedFolding = NO;
  [self.animationTimer invalidate];
  self.animationTimer = nil;
}

- (void)setShowDividerLines:(BOOL)showDividerLines
{
  [self setShowDividerLines:showDividerLines animated:NO];
}

- (void)setShowDividerLines:(BOOL)showDividerLines animated:(BOOL)animated
{
  if(_showDividerLines == showDividerLines)
    return;

  _showDividerLines = showDividerLines;
  /*CGFloat alpha = showDividerLines ? 1 : 0;
  [UIView animateWithDuration:animated ? 0.25 : 0 animations:^
  {
    self.leftDividerLine.alpha = alpha;
    self.topDividerLine.alpha = alpha;
    self.rightDividerLine.alpha = alpha;
    self.bottomDividerLine.alpha = alpha;
  }];*/
}

#pragma mark - MultiFoldView delegate

- (CGFloat)displacementOfMultiFoldView:(id)multiFoldView
{
  if(multiFoldView == self.rightFoldView) {
    return self.contentView.frame.origin.x;
  } else if(multiFoldView == self.leftFoldView) {
    return -1 * self.contentView.frame.origin.x;
  } else if(multiFoldView == self.topFoldView) {
    if([self.contentView isKindOfClass:[UIScrollView class]])
      return -1 * ((UIScrollView *)self.contentView).contentOffset.y;
    else
      return self.contentView.frame.origin.y;
  } else if(multiFoldView == self.bottomFoldView) {
    if([self.contentView isKindOfClass:[UIScrollView class]])
      return -1 * ((UIScrollView *)self.contentView).contentOffset.y;
    else
      return self.contentView.frame.origin.y;
  }
  return 0.0;
}

#pragma mark - Gesture recogniser delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  if(self.enableHorizontalEdgeDragging) {
    CGPoint location = [gestureRecognizer locationInView:self.contentView];
    if(location.x < kEdgeScrollWidth || location.x > (self.contentView.frame.size.width - kEdgeScrollWidth))
      return NO;
    else
      return YES;
  } else
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  // only allow panning if we didn't restrict it to start at a certain rect
  if(!CGRectIsNull(self.restrictedDraggingRect) && !CGRectContainsPoint(self.restrictedDraggingRect, [gestureRecognizer locationInView:self]))
    return NO;
  else
    return YES;
}

@end
