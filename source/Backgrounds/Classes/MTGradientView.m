/*
     MTGradientView.m
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

#import "MTGradientView.h"
#import "MTColor.h"
#import "Constants.h"

@interface MTGradientView ()
@property (nonatomic, strong, readwrite) NSMutableArray *gradientColors;
@property (nonatomic, strong, readwrite) NSMutableArray *gradientLocations;
@property (nonatomic, strong, readwrite) NSGradient *gradient;
@property (nonatomic, assign) BOOL radialGradient;
@property (nonatomic, assign) CGFloat gradientAngle;
@property (nonatomic, assign) NSPoint centerPosition;
@end

@implementation MTGradientView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) { [self setUpView]; }
    
    return self;
}

- (id)initWithFrame:(NSRect)frame colors:(NSArray*)colors locations:(NSArray*)locations angle:(CGFloat)angle
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _gradientColors = [NSMutableArray arrayWithArray:colors];
        _gradientLocations = [NSMutableArray arrayWithArray:locations];
        _gradientAngle = angle;
        _radialGradient = NO;
    }
    
    return self;
}

- (id)initWithFrame:(NSRect)frame colors:(NSArray*)colors locations:(NSArray*)locations centerPosition:(NSPoint)centerPosition
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _gradientColors = [NSMutableArray arrayWithArray:colors];
        _gradientLocations = [NSMutableArray arrayWithArray:locations];
        _centerPosition = centerPosition;
        _radialGradient = YES;
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dictionary forFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        // read in the color integer values and convert them into NSColor objects
        NSMutableArray *colors = [[NSMutableArray alloc] init];
        
        for (id colorValue in [dictionary valueForKey:kMTDefaultsGradientColors]) {
            NSColor *aColor = [NSColor colorFromInteger:[colorValue integerValue]];
            if (aColor) { [colors addObject:aColor]; }
        }

        _gradientColors = colors;
        _gradientLocations = [dictionary valueForKey:kMTDefaultsGradientLocations];
        _radialGradient = [[dictionary valueForKey:kMTDefaultsGradientIsRadial] boolValue];
        
        if (_radialGradient) {
            CGFloat xPosition = [[dictionary valueForKey:kMTDefaultsGradientXPosition] doubleValue];
            CGFloat yPosition = [[dictionary valueForKey:kMTDefaultsGradientYPosition] doubleValue];
            _centerPosition = NSMakePoint(xPosition, yPosition);
        } else {
            _gradientAngle = [[dictionary valueForKey:kMTDefaultsGradientAngle] doubleValue];
        }
    }
    
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
    _gradientColors = [NSMutableArray arrayWithObjects:
                       [NSColor whiteColor],
                       [NSColor blackColor],
                       nil];
    
    _gradientLocations = [NSMutableArray arrayWithObjects:
                          [NSNumber numberWithFloat:0.0],
                          [NSNumber numberWithFloat:1.0],
                          nil];
    _gradientAngle = 0;
    _centerPosition = NSMakePoint(0, 0);
}

- (void)drawRect:(NSRect)dirtyRect
{
    // create a CGFloat array from our NSArray
    CGFloat *cgfloatArray = (CGFloat*)malloc([_gradientLocations count] * sizeof(CGFloat));

    // draw the gradient
    for (NSInteger i = 0; i < [_gradientLocations count]; i++) {
        cgfloatArray[i] = [[_gradientLocations objectAtIndex:i] floatValue];
    }
    
    _gradient = [[NSGradient alloc] initWithColors:_gradientColors
                                       atLocations:cgfloatArray
                                        colorSpace:[NSColorSpace genericRGBColorSpace]
    ];
    
    if (_radialGradient) {
        [_gradient drawInRect:dirtyRect relativeCenterPosition:_centerPosition];
    } else {
        [_gradient drawInRect:dirtyRect angle:_gradientAngle];
    }
    

    free(cgfloatArray);
    
    // draw the border
    if (_borderColor) {
        [_borderColor setStroke];
        [NSBezierPath strokeRect:dirtyRect];
    }
}

- (void)setColors:(NSArray*)colors andLocations:(NSArray*)locations
{
    if (colors && locations) {
        _gradientColors = [NSMutableArray arrayWithArray:colors];
        _gradientLocations = [NSMutableArray arrayWithArray:locations];
        [self setNeedsDisplay:YES];
    }
}

- (void)setColor:(NSColor*)color atLocation:(CGFloat)location
{
    if (color) {

        NSNumber *locationObject = [NSNumber numberWithFloat:location];
        
        // check if there's already a color defined at the specified location
        if ([_gradientLocations containsObject:locationObject]) {

            // change color at the existing location
            NSInteger elementIndex = [_gradientLocations indexOfObject:locationObject];
            [_gradientColors replaceObjectAtIndex:elementIndex withObject:color];
            
        } else {
            
            // add color and location
            [_gradientColors addObject:color];
            [_gradientLocations addObject:locationObject];
        }
        
        [self setNeedsDisplay:YES];
    }
}

- (void)setAngle:(CGFloat)angle
{
    _gradientAngle = angle;
    [self setNeedsDisplay:YES];
}

- (void)setCenterPosition:(NSPoint)centerPosition
{
    _centerPosition = centerPosition;
    [self setNeedsDisplay:YES];
}

- (NSColor*)colorAtLocation:(CGFloat)location
{
    return [_gradient interpolatedColorAtLocation:location];
}

- (NSImage*)image
{
  NSSize imageSize = NSMakeSize(NSWidth([self bounds]), NSHeight([self bounds]));

  NSBitmapImageRep *imageRepresentation = [self bitmapImageRepForCachingDisplayInRect:[self bounds]];
  [imageRepresentation setSize:imageSize];
  [self cacheDisplayInRect:[self bounds] toBitmapImageRep:imageRepresentation];

  NSImage* image = [[NSImage alloc] initWithSize:imageSize] ;
  [image addRepresentation:imageRepresentation];

  return image;
}

- (NSArray*)colors
{
    return _gradientColors;
}

- (NSArray*)locations
{
    return _gradientLocations;
}

- (NSDictionary*)dictionary
{
    NSMutableDictionary *gradientDict = [[NSMutableDictionary alloc] init];
    
    // convert our NSColor objects into integer values
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    for (NSColor *color in [self colors]) { [colors addObject:[NSNumber numberWithInteger:[color integerValue]]]; }
    [gradientDict setValue:colors forKey:kMTDefaultsGradientColors];

    [gradientDict setValue:[self locations] forKey:kMTDefaultsGradientLocations];
    [gradientDict setValue:[NSNumber numberWithBool:[self isRadialGradiant]] forKey:kMTDefaultsGradientIsRadial];
        
    if ([self isRadialGradiant]) {
        [gradientDict setValue:[NSNumber numberWithDouble:_centerPosition.x] forKey:kMTDefaultsGradientXPosition];
        [gradientDict setValue:[NSNumber numberWithDouble:_centerPosition.y] forKey:kMTDefaultsGradientYPosition];
    } else {
        [gradientDict setValue:[NSNumber numberWithDouble:_gradientAngle] forKey:kMTDefaultsGradientAngle];
    }
    
    return [gradientDict copy];
}

@end
