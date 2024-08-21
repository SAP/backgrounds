/*
     MTColorWell.m
     Copyright 2022-2024 SAP SE
     
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

#import "MTColorWell.h"

@interface MTColorWell ()
@property (nonatomic, strong, readwrite) NSColorPanel *colorPanel;
@property (nonatomic, strong, readwrite) NSColor *previousColor;
@property (assign) BOOL shouldBeRemoved;
@end

@implementation MTColorWell


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) { [self setUpColorWell]; }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) { [self setUpColorWell]; }
    
    return self;
}

- (void)setUpColorWell
{
    [self setWantsLayer:YES];
    _colorPanel = [NSColorPanel sharedColorPanel];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath *colorStopPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 2.0, 2.0)
                                                                  xRadius:3.0
                                                                  yRadius:3.0];
    [[self color] setFill];
    [colorStopPath fill];

    if ([self isBordered]) {
        
        // we adjust the border color to make it visible regardless
        // of whath the view's current color is
        NSColor *grayColor = [[self color] colorUsingColorSpace:[NSColorSpace genericGrayColorSpace]];
        CGFloat borderColor = 0.8 - (0.2 * [grayColor whiteComponent]);
        [[NSColor colorWithWhite:borderColor alpha:1.0] setStroke];
        [colorStopPath setLineWidth:1.5];
        [colorStopPath stroke];
    }
}

- (void)setColor:(NSColor *)color
{
    _previousColor = [self color];
    [super setColor:color];
}

- (BOOL)sendAction:(SEL)selector to:(id)target
{
    BOOL success = [super sendAction:selector to:target];
    
    if (_delegate && [_delegate respondsToSelector:@selector(colorWellDidChangeColor:oldColor:newColor:)]) {
        [_delegate colorWellDidChangeColor:self oldColor:_previousColor newColor:[self color]];
    }

    return success;
}

- (void)mouseDown:(NSEvent*)event
{
    if ([self isActive]) {

        [_colorPanel close];
        [self deactivate];

    } else {

        [self activate:YES];
        [NSApp orderFrontColorPanel:self];
    }
       
    id propertyListRep = [[self color] pasteboardPropertyListForType:NSPasteboardTypeColor];
    NSPasteboardItem *pbItem = [[NSPasteboardItem alloc] initWithPasteboardPropertyList:propertyListRep ofType:NSPasteboardTypeColor];
    NSDraggingItem *draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
    
    NSBitmapImageRep *colorImageRep = [self bitmapImageRepForCachingDisplayInRect:[self bounds]];
    [colorImageRep setSize:[self frame].size];
    [self cacheDisplayInRect:[self bounds] toBitmapImageRep:colorImageRep];
    NSImage *dragImage = [[NSImage alloc]initWithSize:[self frame].size] ;
    [dragImage addRepresentation:colorImageRep];
    [draggingItem setDraggingFrame:[self bounds] contents:dragImage];
    
    [self beginDraggingSessionWithItems:[NSArray arrayWithObject:draggingItem] event:event source:self];
}

- (NSDragOperation)draggingSession:(nonnull NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    return NSDragOperationMove;
}

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint
{
    _shouldBeRemoved = NO;
    [self setAlphaValue:0.0];
    [self setAllowsExpansionToolTips:NO];
    [session setAnimatesToStartingPositionsOnCancelOrFail:NO];
    
    if (_delegate && [_delegate respondsToSelector:@selector(colorWellDidStartDragging:)]) {
        [_delegate colorWellDidStartDragging:self];
    }
}

- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint
{
    NSPoint pointInWindow = [[self window] convertPointFromScreen:screenPoint];
    NSPoint cursorPoint = [[self superview] convertPoint:pointInWindow fromView:nil];
    
    if (!NSMouseInRect(cursorPoint, NSInsetRect([[self superview] frame], -NSHeight([[self superview] frame]), -NSHeight([[self superview] frame])), NO) && [[[self superview] subviews] count] > 2) {
        
        _shouldBeRemoved = YES;
        [[NSCursor disappearingItemCursor] set];
        
    } else {
        
        _shouldBeRemoved = NO;
        [[NSCursor closedHandCursor] set];

        if (cursorPoint.x - NSMidX([self bounds]) < 0) {
            cursorPoint.x = 0;
        } else if (cursorPoint.x + NSMidX([self bounds]) >= NSWidth([[self superview] frame])) {
            cursorPoint.x = NSWidth([[self superview] frame]) - NSWidth([self frame]);
        } else {
            cursorPoint.x -= NSMidX([self bounds]);
        }

        [self setFrameOrigin:NSMakePoint(cursorPoint.x, NSMinY([self frame]))];
        
        if (_delegate && [_delegate respondsToSelector:@selector(colorWellDidMove:)]) {
            [_delegate colorWellDidMove:self];
        }
    }
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    if (_shouldBeRemoved) {

        // close the color panel
        if ([self isActive]) { [_colorPanel close]; }
        
        // remove the color well
        [self removeFromSuperview];
        
        // show the "poof" animation
        NSShowAnimationEffect(NSAnimationEffectPoof, [NSEvent mouseLocation], NSZeroSize, nil, nil, NULL);
        
        
    } else {

        [self setAllowsExpansionToolTips:YES];
    }
    
    [self setAlphaValue:1.0];
    
    if (_delegate && [_delegate respondsToSelector:@selector(colorWellDidEndDragging:)]) {
        [_delegate colorWellDidEndDragging:self];
    }
}

@end
