/*
     MTGradientPickerView.m
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

#import "MTGradientPickerView.h"

@interface MTGradientPickerView ()
@property (nonatomic, strong, readwrite) MTColorWellContainerView *colorWellContainer;
@property (nonatomic, strong, readwrite) NSString *colorWellToolTip;
@property (assign) CGFloat previousColorWellLocation;
@end

@implementation MTGradientPickerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) { [self setUpView]; }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) { [self setUpView]; }
    
    return self;
}

- (void)setUpView
{
    [self setWantsLayer:YES];

    // add the gradient layer
    _gradientView = [[MTGradientView alloc] initWithFrame:NSInsetRect([self bounds], 6, 6)];
    [_gradientView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_gradientView setBorderColor:[NSColor lightGrayColor]];
    [_gradientView setWantsLayer:YES];
    [[_gradientView layer] setMasksToBounds:YES];
    [self addSubview:_gradientView];
    
    NSLayoutConstraint *gradientLeft = [NSLayoutConstraint constraintWithItem:_gradientView
                                                            attribute:NSLayoutAttributeLeading
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeLeading
                                                           multiplier:1
                                                             constant:6];
    
    NSLayoutConstraint *gradientTop = [NSLayoutConstraint constraintWithItem:_gradientView
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1
                                                            constant:6];
    
    NSLayoutConstraint *gradientRight = [NSLayoutConstraint constraintWithItem:_gradientView
                                                           attribute:NSLayoutAttributeTrailing
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeTrailing
                                                          multiplier:1
                                                            constant:-6];
    
    NSLayoutConstraint *gradientBottom = [NSLayoutConstraint constraintWithItem:_gradientView
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeBottom
                                                          multiplier:1
                                                            constant:-6];

    [self addConstraints:[NSArray arrayWithObjects:
                                   gradientLeft,
                                   gradientRight,
                                   gradientTop,
                                   gradientBottom,
                                   nil]];
    
    _colorWellContainer = [[MTColorWellContainerView alloc] initWithFrame:[self bounds]];
    [_colorWellContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self addSubview:_colorWellContainer];
    
    NSLayoutConstraint *containerLeft = [NSLayoutConstraint constraintWithItem:_colorWellContainer
                                                            attribute:NSLayoutAttributeLeading
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeLeading
                                                           multiplier:1
                                                             constant:0];
    
    NSLayoutConstraint *containerTop = [NSLayoutConstraint constraintWithItem:_colorWellContainer
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1
                                                            constant:0];
    
    NSLayoutConstraint *containerRight = [NSLayoutConstraint constraintWithItem:_colorWellContainer
                                                           attribute:NSLayoutAttributeTrailing
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeTrailing
                                                          multiplier:1
                                                            constant:0];
    
    NSLayoutConstraint *containerBottom = [NSLayoutConstraint constraintWithItem:_colorWellContainer
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeBottom
                                                          multiplier:1
                                                            constant:0];

    [self addConstraints:[NSArray arrayWithObjects:
                                   containerLeft,
                                   containerRight,
                                   containerTop,
                                   containerBottom,
                                   nil]];
    
    // add color wells for starting and ending color
    [self addColorWellAtPosition:NSMakePoint(0, 0) usingColor:[NSColor whiteColor]];
    [self addColorWellAtPosition:NSMakePoint(NSMaxX([_colorWellContainer frame]), 0) usingColor:[NSColor blackColor]];
    
    [self updateGradient:nil];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

}

- (void)mouseDown:(NSEvent*)event
{
    if ([_colorWellContainer isInsideTrackingArea]) {
        
        // add a new color well
        NSPoint cursorPoint = [_colorWellContainer convertPoint:[event locationInWindow] fromView:nil];
        MTColorWell *newColorWell = [self addColorWellAtPosition:cursorPoint usingColor:nil];
        [self updateGradient:nil];
        
        if (newColorWell && _delegate && [_delegate respondsToSelector:@selector(gradientPicker:didAddColor:atLocation:)]) {
            [_delegate gradientPicker:self didAddColor:[newColorWell color] atLocation:[newColorWell location]];
        }
        
        // make sure our cursor looks correct
        [[NSCursor arrowCursor] set];
        
        // make the new color well active
        [newColorWell activate:YES];
    }
}

- (MTColorWell*)addColorWellAtPosition:(NSPoint)cursorPoint usingColor:(NSColor*)aColor
{
    if (cursorPoint.x < (kMTColorWellWidth / 2.0)) {
        cursorPoint.x = (kMTColorWellWidth / 2.0);
    } else if (cursorPoint.x > NSWidth([_colorWellContainer frame]) - (kMTColorWellWidth / 2.0)) {
        cursorPoint.x = NSWidth([_colorWellContainer frame]) - (kMTColorWellWidth / 2.0);
    }
    
    MTColorWell *addedColorWell = [[MTColorWell alloc] initWithFrame:NSMakeRect(
                                                                                cursorPoint.x - (kMTColorWellWidth / 2.0),
                                                                                0,
                                                                                kMTColorWellWidth,
                                                                                NSHeight([_colorWellContainer frame])
                                                                                )
    ];
    
    CGFloat colorLocation = [self colorLocationForColorWell:addedColorWell];
    
    // if we got a color, we use it, otherwise we use
    // the interpolated color at the given location
    if (!aColor) { aColor = [_gradientView colorAtLocation:colorLocation]; }

    if (aColor) {
        
        [addedColorWell setColor:aColor];
        [addedColorWell setAction:@selector(updateGradient:)];
        [addedColorWell setTarget:self];
        [addedColorWell setContinuous:YES];
        [addedColorWell setDelegate:self];
        [addedColorWell setToolTip:_colorWellToolTip];
        [addedColorWell setBordered:YES];
        [addedColorWell setLocation:colorLocation];
        [_colorWellContainer addSubview:addedColorWell];
        
    } else {
        addedColorWell = nil;
    }
    
    return addedColorWell;
}

- (void)setColorWellToolTip:(NSString*)toolTip
{
    _colorWellToolTip = toolTip;
}

- (IBAction)updateGradient:(id)sender
{
    NSMutableArray *colorArray = [[NSMutableArray alloc] init];
    NSMutableArray *locationArray = [[NSMutableArray alloc] init];
    
    // loop over all color wells an get their colors and positions
    for (MTColorWell *colorWell in [self colorWells]) {
        
        [colorArray addObject:[colorWell color]];
        [locationArray addObject:[NSNumber numberWithFloat:[colorWell location]]];
    }

    [_gradientView setColors:colorArray andLocations:locationArray];

    if (_delegate && [_delegate respondsToSelector:@selector(gradientPickerDidChangeColors:)]) {
        [_delegate gradientPickerDidChangeColors:self];
    }
}

- (CGFloat)colorLocationForColorWell:(MTColorWell*)colorWell
{
    CGFloat colorLocation = 0;
    
    if (colorWell) {
        
        CGFloat colorWellOriginX = NSMinX([colorWell frame]);
        
        if (colorWellOriginX == NSWidth([_colorWellContainer frame]) - kMTColorWellWidth) {
            colorLocation = 1;
            
        } else if (colorWellOriginX > 0) {
            colorLocation = (1.0 / NSWidth([_colorWellContainer frame])) * (colorWellOriginX + NSWidth([colorWell frame]) / 2);
        }
    }
    
    return colorLocation;
}

- (void)setColors:(NSArray*)colors andLocations:(NSArray*)locations
{
    if (colors && locations) {
        
        // set the colors
        [_gradientView setColors:colors andLocations:locations];
    
        // remove all color wells
        [_colorWellContainer setSubviews:[NSArray array]];
        
        CGFloat containerWidth = NSWidth([self->_colorWellContainer frame]);
        
        [colors enumerateObjectsUsingBlock:^(NSColor * _Nonnull aColor, NSUInteger idx, BOOL * _Nonnull stop) {
                            
            CGFloat colorLocation = [[locations objectAtIndex:idx] floatValue];
            CGFloat colorWellPosition = colorLocation * containerWidth;
            [self addColorWellAtPosition:NSMakePoint(colorWellPosition, 0) usingColor:aColor];
        }];
    }
}

#pragma mark undo/redo stuff
- (void)addColor:(NSColor*)color atLocation:(CGFloat)location
{
    CGFloat colorWellLocation = NSWidth([_colorWellContainer frame]) * location;
    [self addColorWellAtPosition:NSMakePoint(colorWellLocation, 0) usingColor:color];
    
    [self updateGradient:nil];
}

- (void)changeColorLocation:(CGFloat)oldLocation toLocation:(CGFloat)newLocation
{
    NSArray *filteredArray = [[self colorWells] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        MTColorWell *obj = (MTColorWell*)evaluatedObject;
            return [[NSNumber numberWithFloat:[obj location]] isEqualTo:[NSNumber numberWithFloat:oldLocation]];
        }
    ]];
    
    if ([filteredArray count] == 1) {

        MTColorWell *colorWell = [filteredArray firstObject];
        [self addColor:[colorWell color] atLocation:newLocation];
        [colorWell removeFromSuperview];
        
        [self updateGradient:nil];
    }
}

- (void)removeColorAtLocation:(CGFloat)location
{
    NSArray *filteredArray = [[self colorWells] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        MTColorWell *obj = (MTColorWell*)evaluatedObject;
            return [[NSNumber numberWithFloat:[obj location]] isEqualTo:[NSNumber numberWithFloat:location]];
        }
    ]];
    
    if ([filteredArray count] == 1) {
        
        MTColorWell *colorWell = [filteredArray firstObject];
        [colorWell removeFromSuperview];
        
        [self updateGradient:nil];
    }
}

- (void)replaceColorAtLocation:(CGFloat)location withColor:(NSColor*)color
{
    NSArray *filteredArray = [[self colorWells] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        MTColorWell *obj = (MTColorWell*)evaluatedObject;
            return [[NSNumber numberWithFloat:[obj location]] isEqualTo:[NSNumber numberWithFloat:location]];
        }
    ]];
        
    if ([filteredArray count] == 1) {

        MTColorWell *colorWell = [filteredArray firstObject];
        [colorWell setColor:color];
        
        [self updateGradient:nil];
    }
}

- (NSArray*)colorWells
{
    NSMutableArray *allColorWells = [[NSMutableArray alloc] init];
    
    for (NSView *aView in [_colorWellContainer subviews]) {
        
        if ([aView isKindOfClass:[MTColorWell class]]) {
            [allColorWells addObject:aView];
        }
    }
    
    return allColorWells;
}

- (void)colorWellDidChangeColor:(MTColorWell *)colorWell oldColor:(nonnull NSColor *)oldColor newColor:(nonnull NSColor *)newColor
{
    if (_delegate && [_delegate respondsToSelector:@selector(gradientPicker:didChangeColor:toColor:atLocation:)]) {
        [_delegate gradientPicker:self didChangeColor:oldColor toColor:newColor atLocation:[colorWell location]];
    }
}

- (void)colorWellDidEndDragging:(nonnull MTColorWell *)colorWell
{
    [self updateGradient:nil];
    [_colorWellContainer generateTrackingAreas];
    
    if ([[_colorWellContainer subviews] containsObject:colorWell]) {
    
        if (_delegate && [_delegate respondsToSelector:@selector(gradientPicker:didMoveColor:fromLocation:toLocation:)]) {
            [_delegate gradientPicker:self didMoveColor:[colorWell color] fromLocation:_previousColorWellLocation toLocation:[colorWell location]];
        }
        
    } else {
        
        if (_delegate && [_delegate respondsToSelector:@selector(gradientPicker:didRemoveColor:atLocation:)]) {
            [_delegate gradientPicker:self didRemoveColor:[colorWell color] atLocation:[colorWell location]];
        }
    }
}

- (void)colorWellDidMove:(nonnull MTColorWell *)colorWell
{
    // update the color well's location
    [colorWell setLocation:[self colorLocationForColorWell:colorWell]];
    
    [self updateGradient:nil];
}

- (void)colorWellDidStartDragging:(nonnull MTColorWell *)colorWell
{
    // save the color well's location
    _previousColorWellLocation = [colorWell location];
    
    [_colorWellContainer removeAllTrackingAreas];
}

@end
