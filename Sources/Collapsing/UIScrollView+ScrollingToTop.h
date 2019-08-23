//
//  UIScrollView+ScrollingToTop.h
//  Sundial
//
//  Created by Vladimir Burdukov on 23/04/2018.
//

#import <Foundation/Foundation.h>

@interface UIScrollView (ScrollingToTop)

@property (getter=_isScrollingToTop, nonatomic, readonly) BOOL scrollingToTop;

@end
