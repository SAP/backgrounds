/*
     MTColorWellContainerView.m
     Copyright 2022 SAP SE
     
     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at
     
     http://www.apache.org/licenses/LICENSE-2.0
     
     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
*/

#import "MTColorWellContainerView.h"

@interface MTColorWellContainerView ()
@property (nonatomic, assign) BOOL insideTrackingArea;
@end

@implementation MTColorWellContainerView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)didAddSubview:(NSView *)subview
{
    [super didAddSubview:subview];

    [self generateTrackingAreas];
    
    if (self->_delegate && [self->_delegate respondsToSelector:@selector(containerView:didAddSubview:)]) {
        [_delegate containerView:self didAddSubview:subview];
    }
}

- (void)willRemoveSubview:(NSView *)subview
{
    [super willRemoveSubview:subview];
    
    // make sure we call the callback AFTER the subview has been removed
    dispatch_async(dispatch_get_main_queue(),^{
        [self generateTrackingAreas];
        
        if (self->_delegate && [self->_delegate respondsToSelector:@selector(containerView:didRemoveSubview:)]) {
            [self->_delegate containerView:self didRemoveSubview:subview];
        }
    });
}

NSComparisonResult compareViews(NSView *firstView, NSView *secondView, void *context) {
    
    NSComparisonResult comparsionResult = NSOrderedSame;
    
    CGFloat firstFrameOrigin = NSMinX([firstView frame]);
    CGFloat secondFrameOrigin = NSMinX([secondView frame]);

    if (firstFrameOrigin < secondFrameOrigin) {
        comparsionResult = NSOrderedAscending;
    } else if (firstFrameOrigin > secondFrameOrigin) {
        comparsionResult = NSOrderedDescending;
    }
    
    return comparsionResult;
}

- (void)removeAllTrackingAreas
{
    // remove all tracking areas
    for (NSTrackingArea *trackingArea in [self trackingAreas]) {
        [self removeTrackingArea:trackingArea];
    }
}

- (void)generateTrackingAreas
{
    // remove all tracking areas
    [self removeAllTrackingAreas];
        
    // define the options for our tracking areas
    NSTrackingAreaOptions options = (
                                     NSTrackingMouseEnteredAndExited |
                                     NSTrackingCursorUpdate |
                                     NSTrackingActiveInKeyWindow
                                     );
    
    // sort the subviews by their origin (x)
    [self sortSubviewsUsingFunction:(NSComparisonResult (*)(NSView*, NSView*, void*))compareViews context:nil];
    
    CGFloat areaOriginX = 0;
    CGFloat areaOriginY = 0;
    CGFloat areaHeight = NSHeight([self frame]);
    
    for (NSView *aView in [self subviews]) {
        
        CGFloat areaWidth = NSMinX([aView frame]) - areaOriginX;
        NSRect areaRect = NSMakeRect(areaOriginX, areaOriginY, areaWidth, areaHeight);
        areaOriginX += (areaWidth + NSWidth([aView frame]));
        
        NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:areaRect
                                                            options:options
                                                              owner:self
                                                           userInfo:nil
        ];
        
        [self addTrackingArea:area];
    }
    
    // add a tracking area after the last subview if needed
    if (areaOriginX < NSMinX([self frame]) + NSWidth([self frame])) {
    
        CGFloat areaWidth = NSMinX([self frame]) + NSWidth([self frame]) - areaOriginX;
        NSRect areaRect = NSMakeRect(areaOriginX, areaOriginY, areaWidth, areaHeight);
        
        NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:areaRect
                                                            options:options
                                                              owner:self
                                                           userInfo:nil
        ];
        
        [self addTrackingArea:area];
    }
    
    _insideTrackingArea = NO;
}

- (void)cursorUpdate:(NSEvent*)event
{
    if ([[self trackingAreas] count] > 0) {
        (_insideTrackingArea) ? [[NSCursor dragCopyCursor] set] : [[NSCursor arrowCursor] set];
    }
}

- (void)mouseEntered:(NSEvent*)event
{
    _insideTrackingArea = YES;
}

- (void)mouseExited:(NSEvent*)event
{
    _insideTrackingArea = NO;
}

- (BOOL)isInsideTrackingArea
{
    return _insideTrackingArea;
}

@end
