//
//  MGSplitCornersView.h
//  MGSplitView
//
//  Created by Matt Gemmell on 28/07/2010.
//  Copyright 2010 Instinctive Code.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MGCornersPosition) {
	MGCornersPositionLeadingVertical	= 0, // top of screen for a left/right split.
	MGCornersPositionTrailingVertical	= 1, // bottom of screen for a left/right split.
	MGCornersPositionLeadingHorizontal	= 2, // left of screen for a top/bottom split.
	MGCornersPositionTrailingHorizontal	= 3  // right of screen for a top/bottom split.
};

@class MGSplitViewController;

@interface MGSplitCornersView : UIView
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, weak) MGSplitViewController *splitViewController;
@property (nonatomic, assign) MGCornersPosition cornersPosition; // don't change this manually; let the splitViewController manage it.
@property (nonatomic, strong) UIColor *cornerBackgroundColor;
@end
