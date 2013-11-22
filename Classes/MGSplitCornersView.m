//
//  MGSplitCornersView.m
//  MGSplitView
//
//  Created by Matt Gemmell on 28/07/2010.
//  Copyright 2010 Instinctive Code.
//

#import "MGSplitCornersView.h"

double deg2Rad(double degrees);
double deg2Rad(double degrees)
{
	// Converts degrees to radians.
	return degrees * (M_PI / 180.0);
}

double rad2Deg(double radians);
double rad2Deg(double radians)
{
	// Converts radians to degrees.
	return radians * (180 / M_PI);
}


@implementation MGSplitCornersView

#pragma mark -
#pragma mark Setup and teardown


- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		self.contentMode = UIViewContentModeRedraw;
		self.userInteractionEnabled = NO;
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.cornerRadius = 0.0; // actual value is set by the splitViewController.
		self.cornersPosition = MGCornersPositionLeadingVertical;

        [self addObserver:self forKeyPath:@"cornerRadius" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"splitViewController" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"cornersPosition" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"cornerBackgroundColor" options:0 context:NULL];
    }

    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"cornerRadius"];
    [self removeObserver:self forKeyPath:@"splitViewController"];
    [self removeObserver:self forKeyPath:@"cornersPosition"];
    [self removeObserver:self forKeyPath:@"cornerBackgroundColor"];

    self.cornerBackgroundColor = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Drawing

- (UIBezierPath*)pathForLeadingVerticalCorner
{
    float maxX = CGRectGetMaxX(self.bounds);
    float maxY = CGRectGetMaxY(self.bounds);

    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint pt = CGPointZero;

    [path moveToPoint:pt];
    pt.y += self.cornerRadius;
    [path appendPath:[UIBezierPath bezierPathWithArcCenter:pt radius:self.cornerRadius startAngle:(CGFloat)deg2Rad(90.0) endAngle:(CGFloat)0.0 clockwise:YES]];
    pt.x += self.cornerRadius;
    pt.y -= self.cornerRadius;
    [path addLineToPoint:pt];
    [path addLineToPoint:CGPointZero];
    [path closePath];

    pt.x = maxX - self.cornerRadius;
    pt.y = 0;
    [path moveToPoint:pt];
    pt.y = maxY;
    [path addLineToPoint:pt];
    pt.x += self.cornerRadius;
    [path appendPath:[UIBezierPath bezierPathWithArcCenter:pt radius:self.cornerRadius startAngle:(CGFloat)deg2Rad(180.0) endAngle:(CGFloat)deg2Rad(90) clockwise:YES]];
    pt.y -= self.cornerRadius;
    [path addLineToPoint:pt];
    pt.x -= self.cornerRadius;
    [path addLineToPoint:pt];
    [path closePath];

    return path;
}

- (UIBezierPath*)pathForTrailingVerticalCorner {
    float maxX = CGRectGetMaxX(self.bounds);
    float maxY = CGRectGetMaxY(self.bounds);
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint pt = CGPointZero;

    pt.y = maxY;
    [path moveToPoint:pt];
    pt.y -= self.cornerRadius;
    [path appendPath:[UIBezierPath bezierPathWithArcCenter:pt radius:self.cornerRadius startAngle:(CGFloat)deg2Rad(270) endAngle:(CGFloat)deg2Rad(360) clockwise:NO]];
    pt.x += self.cornerRadius;
    pt.y += self.cornerRadius;
    [path addLineToPoint:pt];
    pt.x -= self.cornerRadius;
    [path addLineToPoint:pt];
    [path closePath];

    pt.x = maxX - self.cornerRadius;
    pt.y = maxY;
    [path moveToPoint:pt];
    pt.y -= self.cornerRadius;
    [path addLineToPoint:pt];
    pt.x += self.cornerRadius;
    [path appendPath:[UIBezierPath bezierPathWithArcCenter:pt radius:self.cornerRadius startAngle:(CGFloat)deg2Rad(180) endAngle:(CGFloat)deg2Rad(270) clockwise:NO]];
    pt.y += self.cornerRadius;
    [path addLineToPoint:pt];
    pt.x -= self.cornerRadius;
    [path addLineToPoint:pt];
    [path closePath];

    return path;
}

- (UIBezierPath*)pathForLeadingHorizontalCorner {
    float maxY = CGRectGetMaxY(self.bounds);
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint pt = CGPointZero;

    pt.x = 0;
    pt.y = self.cornerRadius;
    [path moveToPoint:pt];
    pt.y -= self.cornerRadius;
    [path addLineToPoint:pt];
    pt.x += self.cornerRadius;
    [path appendPath:[UIBezierPath bezierPathWithArcCenter:pt radius:self.cornerRadius startAngle:(CGFloat)deg2Rad(180) endAngle:(CGFloat)deg2Rad(270) clockwise:NO]];
    pt.y += self.cornerRadius;
    [path addLineToPoint:pt];
    pt.x -= self.cornerRadius;
    [path addLineToPoint:pt];
    [path closePath];

    pt.x = 0;
    pt.y = maxY - self.cornerRadius;
    [path moveToPoint:pt];
    pt.y = maxY;
    [path addLineToPoint:pt];
    pt.x += self.cornerRadius;
    [path appendPath:[UIBezierPath bezierPathWithArcCenter:pt radius:self.cornerRadius startAngle:(CGFloat)deg2Rad(180) endAngle:(CGFloat)deg2Rad(90) clockwise:YES]];
    pt.y -= self.cornerRadius;
    [path addLineToPoint:pt];
    pt.x -= self.cornerRadius;
    [path addLineToPoint:pt];
    [path closePath];

    return path;
}

- (UIBezierPath*)pathForTrailingHorizontalCorner {
    float maxY = CGRectGetMaxY(self.bounds);
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint pt = CGPointZero;


    pt.y = self.cornerRadius;
    [path moveToPoint:pt];
    pt.y -= self.cornerRadius;
    [path appendPath:[UIBezierPath bezierPathWithArcCenter:pt radius:self.cornerRadius startAngle:(CGFloat)deg2Rad(270) endAngle:(CGFloat)deg2Rad(360) clockwise:NO]];
    pt.x += self.cornerRadius;
    pt.y += self.cornerRadius;
    [path addLineToPoint:pt];
    pt.x -= self.cornerRadius;
    [path addLineToPoint:pt];
    [path closePath];

    pt.y = maxY - self.cornerRadius;
    [path moveToPoint:pt];
    pt.y += self.cornerRadius;
    [path appendPath:[UIBezierPath bezierPathWithArcCenter:pt radius:self.cornerRadius startAngle:(CGFloat)deg2Rad(90) endAngle:(CGFloat)0 clockwise:YES]];
    pt.x += self.cornerRadius;
    pt.y -= self.cornerRadius;
    [path addLineToPoint:pt];
    pt.x -= self.cornerRadius;
    [path addLineToPoint:pt];
    [path closePath];

    return path;
}

- (void)drawRect:(CGRect)rect
{
	// Draw two appropriate corners, with cornerBackgroundColor behind them.
	if (self.cornerRadius > 0) {
		if (NO) { // just for debugging.
			[[UIColor redColor] set];
			UIRectFill(self.bounds);
		}

		UIBezierPath *path = [UIBezierPath bezierPath];

		switch (self.cornersPosition) {

			case MGCornersPositionLeadingVertical:
                // top of screen for a left/right split
                path = [self pathForLeadingVerticalCorner];
                break;

			case MGCornersPositionTrailingVertical:
                // bottom of screen for a left/right split
                path = [self pathForTrailingVerticalCorner];
				break;

			case MGCornersPositionLeadingHorizontal:
                // left of screen for a top/bottom split
				path = [self pathForLeadingHorizontalCorner];
				break;

			case MGCornersPositionTrailingHorizontal:
                // right of screen for a top/bottom split
                path = [self pathForTrailingHorizontalCorner];
				break;
				
			default:
				break;
		}
		
		[self.cornerBackgroundColor set];
		[path fill];
	}
}

@end
