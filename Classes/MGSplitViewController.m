//
//  MGSplitViewController.m
//  MGSplitView
//
//  Created by Matt Gemmell on 26/07/2010.
//  Copyright 2010 Instinctive Code.
//

#import "MGSplitViewController.h"
#import "MGSplitDividerView.h"
#import "MGSplitCornersView.h"

CGFloat const kMGDefaultSplitPosition        = 320.f;                  // default width of master view in UISplitViewController.
CGFloat const kMGDefaultSplitWidth           = 1.f;                    // default width of split-gutter in UISplitViewController.
CGFloat const kMGDefaultCornerRadius         = 5.f;                    // default corner-radius of overlapping split-inner corners on the master and detail views.
#define kMGDefaultCornerColor                  [UIColor blackColor];   // default color of intruding inner corners (and divider background).

CGFloat const kMGPaneSplitterCornerRadius    = 0.f;                    // corner-radius of split-inner corners for MGSplitViewDividerStylePaneSplitter style.
CGFloat const kMGPaneSplitterSplitWidth      = 25.f;                   // width of split-gutter for MGSplitViewDividerStylePaneSplitter style.
CGFloat const kMGMinViewWidth                = 200.f;                  // minimum width a view is allowed to become as a result of changing the splitPosition.

NSString* kMGChangeSplitOrientationAnimation = @"ChangeSplitOrientation"; // Animation ID for internal use.
NSString* kMGChangeSubviewsOrderAnimation    = @"ChangeSubviewsOrder"; // Animation ID for internal use.


@interface MGSplitViewController ()
@property(nonatomic,strong) UIBarButtonItem *barButtonItem; // To be compliant with wacky UISplitViewController behaviour.
@property(nonatomic,strong) UIPopoverController *hiddenPopoverController; // Popover used to hold the master view if it's not always visible.
@property(nonatomic,strong) NSArray *cornerViews; // Views to draw the inner rounded corners between master and detail views.
@property(nonatomic,assign) BOOL reconfigurePopup;
@end


@implementation MGSplitViewController


#pragma mark -
#pragma mark Orientation helpers


- (NSString *)nameOfInterfaceOrientation:(UIInterfaceOrientation)theOrientation
{
	NSString *orientationName = nil;
	switch (theOrientation) {
		case UIInterfaceOrientationPortrait:
			orientationName = @"Portrait"; // Home button at bottom
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			orientationName = @"Portrait (Upside Down)"; // Home button at top
			break;
		case UIInterfaceOrientationLandscapeLeft:
			orientationName = @"Landscape (Left)"; // Home button on left
			break;
		case UIInterfaceOrientationLandscapeRight:
			orientationName = @"Landscape (Right)"; // Home button on right
			break;
		default:
			break;
	}
	
	return orientationName;
}


- (BOOL)isLandscape
{
	return UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
}


- (BOOL)shouldShowMasterForInterfaceOrientation:(UIInterfaceOrientation)theOrientation
{
	// Returns YES if master view should be shown directly embedded in the splitview, instead of hidden in a popover.
	return ((UIInterfaceOrientationIsLandscape(theOrientation)) ? self.showsMasterInLandscape : self.showsMasterInPortrait);
}


- (BOOL)shouldShowMaster
{
	return [self shouldShowMasterForInterfaceOrientation:self.interfaceOrientation];
}


- (BOOL)isShowingMaster
{
	return [self shouldShowMaster] && self.masterViewController && self.masterViewController.view && ([self.masterViewController.view superview] == self.view);
}


#pragma mark -
#pragma mark Setup and Teardown


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		[self setup];
	}
	
	return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self setup];
	}
	
	return self;
}


- (void)setup
{
	// Configure default behaviour.
	self.splitWidth = kMGDefaultSplitWidth;
	self.showsMasterInPortrait = NO;
	self.showsMasterInLandscape = YES;
	self.reconfigurePopup = NO;
	self.vertical = YES;
	self.masterBeforeDetail = YES;
	self.splitPosition = kMGDefaultSplitPosition;
	CGRect divRect = self.view.bounds;
	if (self.vertical) {
		divRect.origin.y = self.splitPosition;
		divRect.size.height = self.splitWidth;
	} else {
		divRect.origin.x = self.splitPosition;
		divRect.size.width = self.splitWidth;
	}
	self.dividerView = [[MGSplitDividerView alloc] initWithFrame:divRect];
	self.dividerView.splitViewController = self;
	self.dividerView.backgroundColor = kMGDefaultCornerColor;
	self.dividerStyle = MGSplitViewDividerStyleThin;
}


- (void)dealloc
{
	self.delegate = nil;
	[self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}


#pragma mark -
#pragma mark View management


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (self.masterViewController && self.detailViewController) {
        return [self.masterViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation] && [self.detailViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    else if (self.masterViewController) {
        return [self.masterViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    else if (self.detailViewController) {
        return [self.detailViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    else {
        return YES;
    }
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.masterViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.detailViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.masterViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self.detailViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
										 duration:(NSTimeInterval)duration
{
	[self.masterViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.detailViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	// Hide popover.
	if (self.hiddenPopoverController && self.hiddenPopoverController.popoverVisible) {
		[self.hiddenPopoverController dismissPopoverAnimated:NO];
	}
	
	// Re-tile views.
	self.reconfigurePopup = YES;
	[self layoutSubviewsForInterfaceOrientation:toInterfaceOrientation withAnimation:YES];
}


- (void)willAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.masterViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.detailViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


- (void)didAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	[self.masterViewController didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];
	[self.detailViewController didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];
}


- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.masterViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
	[self.detailViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
}


- (CGSize)splitViewSizeForOrientation:(UIInterfaceOrientation)theOrientation
{
	UIScreen *screen = [UIScreen mainScreen];
	CGRect fullScreenRect = screen.bounds; // always implicitly in Portrait orientation.
	CGRect appFrame = screen.applicationFrame;
	
	// Find status bar height by checking which dimension of the applicationFrame is narrower than screen bounds.
	// Little bit ugly looking, but it'll still work even if they change the status bar height in future.
	float statusBarHeight = MAX((fullScreenRect.size.width - appFrame.size.width), (fullScreenRect.size.height - appFrame.size.height));
	
	// Initially assume portrait orientation.
	float width = fullScreenRect.size.width;
	float height = fullScreenRect.size.height;
	
	// Correct for orientation.
	if (UIInterfaceOrientationIsLandscape(theOrientation)) {
		width = height;
		height = fullScreenRect.size.width;
	}
	
	// Account for status bar, which always subtracts from the height (since it's always at the top of the screen).
	height -= statusBarHeight;
	
	return CGSizeMake(width, height);
}


- (void)layoutSubviewsForInterfaceOrientation:(UIInterfaceOrientation)theOrientation withAnimation:(BOOL)animate
{
	if (self.reconfigurePopup) {
		[self reconfigureForMasterInPopover:![self shouldShowMasterForInterfaceOrientation:theOrientation]];
	}
	
	// Layout the master, detail and divider views appropriately, adding/removing subviews as needed.
	// First obtain relevant geometry.
	CGSize fullSize = [self splitViewSizeForOrientation:theOrientation];
	float width = fullSize.width;
	float height = fullSize.height;
	
	if (NO) { // Just for debugging.
		NSLog(@"Target orientation is %@, dimensions will be %.0f x %.0f", 
			  [self nameOfInterfaceOrientation:theOrientation], width, height);
	}
	
	// Layout the master, divider and detail views.
	CGRect newFrame = CGRectMake(0, 0, width, height);
	UIViewController *controller;
	UIView *theView;
	BOOL shouldShowMaster = [self shouldShowMasterForInterfaceOrientation:theOrientation];
	if (self.vertical) {
		// Master on left, detail on right (or vice versa).
		CGRect masterRect, dividerRect, detailRect;
		if (self.masterBeforeDetail) {
			if (!shouldShowMaster) {
				// Move off-screen.
				newFrame.origin.x -= (self.splitPosition + self.splitWidth);
			}
			
			newFrame.size.width = self.splitPosition;
			masterRect = newFrame;
			
			newFrame.origin.x += newFrame.size.width;
			newFrame.size.width = self.splitWidth;
			dividerRect = newFrame;
			
			newFrame.origin.x += newFrame.size.width;
			newFrame.size.width = width - newFrame.origin.x;
			detailRect = newFrame;
			
		} else {
			if (!shouldShowMaster) {
				// Move off-screen.
				newFrame.size.width += (self.splitPosition + self.splitWidth);
			}
			
			newFrame.size.width -= (self.splitPosition + self.splitWidth);
			detailRect = newFrame;
			
			newFrame.origin.x += newFrame.size.width;
			newFrame.size.width = self.splitWidth;
			dividerRect = newFrame;
			
			newFrame.origin.x += newFrame.size.width;
			newFrame.size.width = self.splitPosition;
			masterRect = newFrame;
		}
		
		// Position master.
		controller = self.masterViewController;
		if (controller && [controller isKindOfClass:[UIViewController class]])  {
			theView = controller.view;
			if (theView) {
				theView.frame = masterRect;
				if (!theView.superview) {
					[controller viewWillAppear:NO];
					[self.view addSubview:theView];
					[controller viewDidAppear:NO];
				}
			}
		}
		
		// Position divider.
		theView = self.dividerView;
		theView.frame = dividerRect;
		if (!theView.superview) {
			[self.view addSubview:theView];
		}
		
		// Position detail.
		controller = self.detailViewController;
		if (controller && [controller isKindOfClass:[UIViewController class]])  {
			theView = controller.view;
			if (theView) {
				theView.frame = detailRect;
				if (!theView.superview) {
					[self.view insertSubview:theView aboveSubview:self.masterViewController.view];
				} else {
					[self.view bringSubviewToFront:theView];
				}
			}
		}
		
	} else {
		// Master above, detail below (or vice versa).
		CGRect masterRect, dividerRect, detailRect;
		if (self.masterBeforeDetail) {
			if (!shouldShowMaster) {
				// Move off-screen.
				newFrame.origin.y -= (self.splitPosition + self.splitWidth);
			}
			
			newFrame.size.height = self.splitPosition;
			masterRect = newFrame;
			
			newFrame.origin.y += newFrame.size.height;
			newFrame.size.height = self.splitWidth;
			dividerRect = newFrame;
			
			newFrame.origin.y += newFrame.size.height;
			newFrame.size.height = height - newFrame.origin.y;
			detailRect = newFrame;
			
		} else {
			if (!shouldShowMaster) {
				// Move off-screen.
				newFrame.size.height += (self.splitPosition + self.splitWidth);
			}
			
			newFrame.size.height -= (self.splitPosition + self.splitWidth);
			detailRect = newFrame;
			
			newFrame.origin.y += newFrame.size.height;
			newFrame.size.height = self.splitWidth;
			dividerRect = newFrame;
			
			newFrame.origin.y += newFrame.size.height;
			newFrame.size.height = self.splitPosition;
			masterRect = newFrame;
		}
		
		// Position master.
		controller = self.masterViewController;
		if (controller && [controller isKindOfClass:[UIViewController class]])  {
			theView = controller.view;
			if (theView) {
				theView.frame = masterRect;
				if (!theView.superview) {
					[controller viewWillAppear:NO];
					[self.view addSubview:theView];
					[controller viewDidAppear:NO];
				}
			}
		}
		
		// Position divider.
		theView = self.dividerView;
		theView.frame = dividerRect;
		if (!theView.superview) {
			[self.view addSubview:theView];
		}
		
		// Position detail.
		controller = self.detailViewController;
		if (controller && [controller isKindOfClass:[UIViewController class]])  {
			theView = controller.view;
			if (theView) {
				theView.frame = detailRect;
				if (!theView.superview) {
					[self.view insertSubview:theView aboveSubview:self.masterViewController.view];
				} else {
					[self.view bringSubviewToFront:theView];
				}
			}
		}
	}
	
	// Create corner views if necessary.
	MGSplitCornersView *leadingCorners; // top/left of screen in vertical/horizontal split.
	MGSplitCornersView *trailingCorners; // bottom/right of screen in vertical/horizontal split.
	if (!self.cornerViews) {
		CGRect cornerRect = CGRectMake(0, 0, 10, 10); // arbitrary, will be resized below.
		leadingCorners = [[MGSplitCornersView alloc] initWithFrame:cornerRect];
		leadingCorners.splitViewController = self;
		leadingCorners.cornerBackgroundColor = kMGDefaultCornerColor;
		leadingCorners.cornerRadius = kMGDefaultCornerRadius;
		trailingCorners = [[MGSplitCornersView alloc] initWithFrame:cornerRect];
		trailingCorners.splitViewController = self;
		trailingCorners.cornerBackgroundColor = kMGDefaultCornerColor;
		trailingCorners.cornerRadius = kMGDefaultCornerRadius;
		self.cornerViews = @[leadingCorners, trailingCorners];
		
	} else if (self.cornerViews.count == 2) {
		leadingCorners = self.cornerViews[0];
		trailingCorners = self.cornerViews[1];
	}
	
	// Configure and layout the corner-views.
	leadingCorners.cornersPosition = (self.vertical) ? MGCornersPositionLeadingVertical : MGCornersPositionLeadingHorizontal;
	trailingCorners.cornersPosition = (self.vertical) ? MGCornersPositionTrailingVertical : MGCornersPositionTrailingHorizontal;
	leadingCorners.autoresizingMask = (self.vertical) ? UIViewAutoresizingFlexibleBottomMargin : UIViewAutoresizingFlexibleRightMargin;
	trailingCorners.autoresizingMask = (self.vertical) ? UIViewAutoresizingFlexibleTopMargin : UIViewAutoresizingFlexibleLeftMargin;
	
	float x, y, cornersWidth, cornersHeight;
	CGRect leadingRect, trailingRect;
	float radius = leadingCorners.cornerRadius;
	if (self.vertical) { // left/right split
		cornersWidth = (radius * 2.0) + self.splitWidth;
		cornersHeight = radius;
		x = ((shouldShowMaster) ? (self.masterBeforeDetail ? self.splitPosition : width - (self.splitPosition + self.splitWidth)) : (0 - self.splitWidth)) - radius;
		y = 0;
		leadingRect = CGRectMake(x, y, cornersWidth, cornersHeight); // top corners
		trailingRect = CGRectMake(x, (height - cornersHeight), cornersWidth, cornersHeight); // bottom corners
		
	} else { // top/bottom split
		x = 0;
		y = ((shouldShowMaster) ? (self.masterBeforeDetail ? self.splitPosition : height - (self.splitPosition + self.splitWidth)) : (0 - self.splitWidth)) - radius;
		cornersWidth = radius;
		cornersHeight = (radius * 2.0) + self.splitWidth;
		leadingRect = CGRectMake(x, y, cornersWidth, cornersHeight); // left corners
		trailingRect = CGRectMake((width - cornersWidth), y, cornersWidth, cornersHeight); // right corners
	}
	
	leadingCorners.frame = leadingRect;
	trailingCorners.frame = trailingRect;
	
	// Ensure corners are visible and frontmost.
	if (!leadingCorners.superview) {
		[self.view insertSubview:leadingCorners aboveSubview:self.detailViewController.view];
		[self.view insertSubview:trailingCorners aboveSubview:self.detailViewController.view];
	} else {
		[self.view bringSubviewToFront:leadingCorners];
		[self.view bringSubviewToFront:trailingCorners];
	}
}


- (void)layoutSubviewsWithAnimation:(BOOL)animate
{
	[self layoutSubviewsForInterfaceOrientation:self.interfaceOrientation withAnimation:animate];
}


- (void)layoutSubviews
{
	[self layoutSubviewsForInterfaceOrientation:self.interfaceOrientation withAnimation:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([self isShowingMaster]) {
		[self.masterViewController viewWillAppear:animated];
	}
	[self.detailViewController viewWillAppear:animated];
	
	self.reconfigurePopup = YES;
	[self layoutSubviews];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if ([self isShowingMaster]) {
		[self.masterViewController viewDidAppear:animated];
	}
	[self.detailViewController viewDidAppear:animated];

    // TODO: add this here and remove from L497 per https://github.com/mattgemmell/MGSplitViewController/pull/73 ?
    [self layoutSubviews];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if ([self isShowingMaster]) {
		[self.masterViewController viewWillDisappear:animated];
	}
	[self.detailViewController viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	if ([self isShowingMaster]) {
		[self.masterViewController viewDidDisappear:animated];
	}
	[self.detailViewController viewDidDisappear:animated];
}


#pragma mark -
#pragma mark Popover handling


- (void)reconfigureForMasterInPopover:(BOOL)inPopover
{
	self.reconfigurePopup = NO;
	
	if ((inPopover && self.hiddenPopoverController) || (!inPopover && !self.hiddenPopoverController) || !self.masterViewController) {
		// Nothing to do.
		return;
	}
	
	if (inPopover && !self.hiddenPopoverController && !self.barButtonItem) {
		// Create and configure popover for our masterViewController.
		self.hiddenPopoverController = nil;
		[self.masterViewController viewWillDisappear:NO];
		self.hiddenPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.masterViewController];
		[self.masterViewController viewDidDisappear:NO];
		
		// Create and configure _barButtonItem.
		self.barButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Master", nil)
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(showMasterPopover:)];
		
		// Inform delegate of this state of affairs.
		if (self.delegate && [self.delegate respondsToSelector:@selector(splitViewController:willHideViewController:withBarButtonItem:forPopoverController:)]) {
			[(NSObject <MGSplitViewControllerDelegate> *)self.delegate splitViewController:self
                                                                    willHideViewController:self.masterViewController
                                                                         withBarButtonItem:self.barButtonItem
                                                                      forPopoverController:self.hiddenPopoverController];
		}
		
	} else if (!inPopover && self.hiddenPopoverController && self.barButtonItem) {
		// I know this looks strange, but it fixes a bizarre issue with UIPopoverController leaving masterViewController's views in disarray.
		[self.hiddenPopoverController presentPopoverFromRect:CGRectZero inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
		
		// Remove master from popover and destroy popover, if it exists.
		[self.hiddenPopoverController dismissPopoverAnimated:NO];
		self.hiddenPopoverController = nil;
		
		// Inform delegate that the _barButtonItem will become invalid.
		if (self.delegate && [self.delegate respondsToSelector:@selector(splitViewController:willShowViewController:invalidatingBarButtonItem:)]) {
			[(NSObject <MGSplitViewControllerDelegate> *)self.delegate splitViewController:self
																willShowViewController:self.masterViewController 
															 invalidatingBarButtonItem:self.barButtonItem];
		}
		
		// Destroy _barButtonItem.
		self.barButtonItem = nil;
		
		// Move master view.
		UIView *masterView = self.masterViewController.view;
		if (masterView && masterView.superview != self.view) {
			[masterView removeFromSuperview];
		}
	}
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[self reconfigureForMasterInPopover:NO];
}


- (void)notePopoverDismissed
{
	[self popoverControllerDidDismissPopover:self.hiddenPopoverController];
}


#pragma mark -
#pragma mark Animations


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	if (([animationID isEqualToString:kMGChangeSplitOrientationAnimation] || 
		 [animationID isEqualToString:kMGChangeSubviewsOrderAnimation])
		&& self.cornerViews) {
		for (UIView *corner in self.cornerViews) {
			corner.hidden = NO;
		}
		self.dividerView.hidden = NO;
	}
}


#pragma mark -
#pragma mark IB Actions


- (IBAction)toggleSplitOrientation:(id)sender
{
	BOOL showingMaster = [self isShowingMaster];
	if (showingMaster) {
		if (self.cornerViews) {
			for (UIView *corner in self.cornerViews) {
				corner.hidden = YES;
			}
			self.dividerView.hidden = YES;
		}
		[UIView beginAnimations:kMGChangeSplitOrientationAnimation context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	}
	self.vertical = (!self.vertical);
	if (showingMaster) {
		[UIView commitAnimations];
	}
}


- (IBAction)toggleMasterBeforeDetail:(id)sender
{
	BOOL showingMaster = [self isShowingMaster];
	if (showingMaster) {
		if (self.cornerViews) {
			for (UIView *corner in self.cornerViews) {
				corner.hidden = YES;
			}
			self.dividerView.hidden = YES;
		}
		[UIView beginAnimations:kMGChangeSubviewsOrderAnimation context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	}
	self.masterBeforeDetail = (!self.masterBeforeDetail);
	if (showingMaster) {
		[UIView commitAnimations];
	}
}


- (IBAction)toggleMasterView:(id)sender
{
	if (self.hiddenPopoverController && self.hiddenPopoverController.popoverVisible) {
		[self.hiddenPopoverController dismissPopoverAnimated:NO];
	}
	
	if (![self isShowingMaster]) {
		// We're about to show the master view. Ensure it's in place off-screen to be animated in.
		self.reconfigurePopup = YES;
		[self reconfigureForMasterInPopover:NO];
		[self layoutSubviews];
	}
	
	// This action functions on the current primary orientation; it is independent of the other primary orientation.
	[UIView beginAnimations:@"toggleMaster" context:nil];
	if (self.isLandscape) {
		self.showsMasterInLandscape = !self.showsMasterInLandscape;
	} else {
		self.showsMasterInPortrait = !self.showsMasterInPortrait;
	}
	[UIView commitAnimations];
}


- (IBAction)showMasterPopover:(id)sender
{
    if (self.hiddenPopoverController) {

        if (self.hiddenPopoverController.popoverVisible) {
            [self.hiddenPopoverController dismissPopoverAnimated:YES];
        }
        else {
            // Inform delegate.
            if (self.delegate && [self.delegate respondsToSelector:@selector(splitViewController:popoverController:willPresentViewController:)]) {
                [(NSObject <MGSplitViewControllerDelegate> *)self.delegate splitViewController:self
                                                                         popoverController:self.hiddenPopoverController
                                                                 willPresentViewController:self.masterViewController];
            }

            // Show popover.
            [self.hiddenPopoverController presentPopoverFromBarButtonItem:self.barButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
	}
}


#pragma mark -
#pragma mark Accessors and properties

- (void)setShowsMasterInPortrait:(BOOL)flag
{
	if (flag != _showsMasterInPortrait) {
		_showsMasterInPortrait = flag;
		
		if (!self.isLandscape) { // i.e. if this will cause a visual change.
			if (self.hiddenPopoverController && self.hiddenPopoverController.popoverVisible) {
				[self.hiddenPopoverController dismissPopoverAnimated:NO];
			}
			
			// Rearrange views.
			self.reconfigurePopup = YES;
			[self layoutSubviews];
		}
	}
}

- (void)setShowsMasterInLandscape:(BOOL)flag
{
	if (flag != _showsMasterInLandscape) {
		_showsMasterInLandscape = flag;
		
		if ([self isLandscape]) { // i.e. if this will cause a visual change.
			if (self.hiddenPopoverController && self.hiddenPopoverController.popoverVisible) {
				[self.hiddenPopoverController dismissPopoverAnimated:NO];
			}
			
			// Rearrange views.
			self.reconfigurePopup = YES;
			[self layoutSubviews];
		}
	}
}


- (void)setVertical:(BOOL)flag
{
	if (flag != _vertical) {
		if (self.hiddenPopoverController && self.hiddenPopoverController.popoverVisible) {
			[self.hiddenPopoverController dismissPopoverAnimated:NO];
		}
		
		_vertical = flag;
		
		// Inform delegate.
		if (self.delegate && [self.delegate respondsToSelector:@selector(splitViewController:willChangeSplitOrientationToVertical:)]) {
			[self.delegate splitViewController:self willChangeSplitOrientationToVertical:self.vertical];
		}
		
		[self layoutSubviews];
	}
}

- (void)setMasterBeforeDetail:(BOOL)flag
{
	if (flag != self.masterBeforeDetail) {
		if (self.hiddenPopoverController && self.hiddenPopoverController.popoverVisible) {
			[self.hiddenPopoverController dismissPopoverAnimated:NO];
		}
		
		_masterBeforeDetail = flag;
		
		if ([self isShowingMaster]) {
			[self layoutSubviews];
		}
	}
}

- (void)setSplitPosition:(float)posn
{
	// Check to see if delegate wishes to constrain the position.
	float newPosn = posn;
	BOOL constrained = NO;
	CGSize fullSize = [self splitViewSizeForOrientation:self.interfaceOrientation];
	if (_delegate && [_delegate respondsToSelector:@selector(splitViewController:constrainSplitPosition:splitViewSize:)]) {
		newPosn = [_delegate splitViewController:self constrainSplitPosition:newPosn splitViewSize:fullSize];
		constrained = YES; // implicitly trust delegate's response.
		
	} else {
		// Apply default constraints if delegate doesn't wish to participate.
		float minPos = kMGMinViewWidth;
		float maxPos = ((self.vertical) ? fullSize.width : fullSize.height) - (kMGMinViewWidth + self.splitWidth);
		constrained = (newPosn != _splitPosition && newPosn >= minPos && newPosn <= maxPos);
	}
	
	if (constrained) {
		if (self.hiddenPopoverController && self.hiddenPopoverController.popoverVisible) {
			[self.hiddenPopoverController dismissPopoverAnimated:NO];
		}
		
		_splitPosition = newPosn;
		
		// Inform delegate.
		if (self.delegate && [self.delegate respondsToSelector:@selector(splitViewController:willMoveSplitToPosition:)]) {
			[self.delegate splitViewController:self willMoveSplitToPosition:_splitPosition];
		}
		
		if ([self isShowingMaster]) {
			[self layoutSubviews];
		}
	}
}


- (void)setSplitPosition:(float)posn animated:(BOOL)animate
{
	BOOL shouldAnimate = (animate && [self isShowingMaster]);
	if (shouldAnimate) {
		[UIView beginAnimations:@"SplitPosition" context:nil];
	}
	[self setSplitPosition:posn];
	if (shouldAnimate) {
		[UIView commitAnimations];
	}
}

- (void)setSplitWidth:(float)width
{
	if (width != _splitWidth && width >= 0) {
		_splitWidth = width;
		if ([self isShowingMaster]) {
			[self layoutSubviews];
		}
	}
}

- (void)setMasterViewController:(UIViewController *)master
{
	if (_masterViewController) {
        [_masterViewController.view removeFromSuperview];
    }

    if (_masterViewController != master) {
        _masterViewController = master;
        [self layoutSubviews];
    }
}

- (void)setDetailViewController:(UIViewController *)detail
{
    if (_detailViewController) {
        [_detailViewController.view removeFromSuperview];
    }

    if (_detailViewController != detail) {
        _detailViewController = detail;
        [self layoutSubviews];
    }
}

- (void)setDividerView:(MGSplitDividerView *)divider
{
	if (divider != _dividerView) {
		[_dividerView removeFromSuperview];
		_dividerView = divider;
		_dividerView.splitViewController = self;
		_dividerView.backgroundColor = kMGDefaultCornerColor;
		if ([self isShowingMaster]) {
			[self layoutSubviews];
		}
	}
}


- (BOOL)allowsDraggingDivider
{
	if (self.dividerView) {
		return self.dividerView.userInteractionEnabled;
	}
	
	return NO;
}


- (void)setAllowsDraggingDivider:(BOOL)flag
{
	if (self.allowsDraggingDivider != flag && self.dividerView) {
		self.dividerView.userInteractionEnabled = flag;
	}
}

- (void)setDividerStyle:(MGSplitViewDividerStyle)newStyle
{
	if (self.hiddenPopoverController && self.hiddenPopoverController.popoverVisible) {
		[self.hiddenPopoverController dismissPopoverAnimated:NO];
	}
	
	// We don't check to see if newStyle equals _dividerStyle, because it's a meta-setting.
	// Aspects could have been changed since it was set.
	_dividerStyle = newStyle;
	
	// Reconfigure general appearance and behaviour.
	CGFloat cornerRadius = kMGDefaultCornerRadius;
    
	if (_dividerStyle == MGSplitViewDividerStyleThin) {
		_splitWidth = kMGDefaultSplitWidth;
		self.allowsDraggingDivider = NO;
		
	} else if (_dividerStyle == MGSplitViewDividerStylePaneSplitter) {
		cornerRadius = kMGPaneSplitterCornerRadius;
		_splitWidth = kMGPaneSplitterSplitWidth;
		self.allowsDraggingDivider = YES;
	}
	
	// Update divider and corners.
	[_dividerView setNeedsDisplay];
	if (self.cornerViews) {
		for (MGSplitCornersView *corner in self.cornerViews) {
			corner.cornerRadius = cornerRadius;
		}
	}
	
	// Layout all views.
	[self layoutSubviews];
}


- (void)setDividerStyle:(MGSplitViewDividerStyle)newStyle animated:(BOOL)animate
{
	BOOL shouldAnimate = (animate && [self isShowingMaster]);
	if (shouldAnimate) {
		[UIView beginAnimations:@"DividerStyle" context:nil];
	}
	[self setDividerStyle:newStyle];
	if (shouldAnimate) {
		[UIView commitAnimations];
	}
}

@end
