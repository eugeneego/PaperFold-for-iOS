//
//  PaperFoldSwipeHintView.m
//  SGBusArrivals
//
//  Created by honcheng on 13/10/12.
//
//

#import "PaperFoldSwipeHintView.h"

@implementation PaperFoldSwipeHintView

#define TAG_VIEW 2090

- (id)initWithPaperFoldSwipeHintViewMode:(PaperFoldSwipeHintViewMode)mode
{
  self = [super initWithFrame:CGRectZero];
  if(self) {
    _mode = mode;

    UIImage *image = nil;
    if(_mode == PaperFoldSwipeHintViewModeSwipeLeft)
      image = [UIImage imageNamed:@"PaperFoldResources.bundle/swipe_guide_left.png"];
    else if(_mode == PaperFoldSwipeHintViewModeSwipeRight)
      image = [UIImage imageNamed:@"PaperFoldResources.bundle/swipe_guide_right.png"];

    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [self addSubview:_imageView];
    _imageView.image = image;
    self.userInteractionEnabled = NO;

    self.tag = TAG_VIEW;
  }
  return self;
}

- (void)showInView:(UIView *)view
{
  // remove any existing view if available
  UIView *oldView = [view viewWithTag:TAG_VIEW];
  if(oldView)
    [oldView removeFromSuperview];

  self.frame = view.frame;

  CGRect imageViewFrame = self.imageView.frame;
  imageViewFrame.origin.x = (view.frame.size.width - imageViewFrame.size.width) / 2;
  imageViewFrame.origin.y = (view.frame.size.height - imageViewFrame.size.height) / 2;
  self.imageView.frame = imageViewFrame;

  [view addSubview:self];

  self.alpha = 0.0;
  [UIView animateWithDuration:0.2 animations:^
  {
    self.alpha = 1.0;
  }];
}

- (void)hide
{
  self.alpha = 1.0;
  [UIView animateWithDuration:0.2
    animations:^
    {
      self.alpha = 0.0;
    }
    completion:^(BOOL finished)
    {
      [self removeFromSuperview];
    }];
}

+ (void)hidePaperFoldHintViewInView:(UIView *)view
{
  PaperFoldSwipeHintView *hintView = (PaperFoldSwipeHintView *)[view viewWithTag:TAG_VIEW];
  [hintView hide];
}

@end
