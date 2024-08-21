/*
     MTGradientView.h
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

#import <Cocoa/Cocoa.h>

/*!
 @abstract This class defines an NSView containing a gradient.
 */

@interface MTGradientView : NSView

/*!
 @property      borderColor
 @abstract      The color of the receiver's border.
 @discussion    The value of this property is a NSColor object.
*/
@property (nonatomic, strong, readwrite) NSColor *borderColor;

/*!
 @property      radialGradient
 @abstract      Returns YES if the receiver's gradient is of type radial, otherwise returns NO.
 @discussion    The value of this boolean.
*/
@property (nonatomic, readonly, getter=isRadialGradiant) BOOL radialGradient;

/*!
 @property      delegate
 @abstract      The angle of the receiver's linear gradient.
 @discussion    The value of this property is a float.
*/
@property (nonatomic, assign, readonly, getter=angle) CGFloat gradientAngle;

/*!
 @property      centerPosition
 @abstract      The center position of receiver's radial gradient.
 @discussion    The value of this property is a NSPoint object.
*/
@property (nonatomic, assign, readonly) NSPoint centerPosition;

/*!
 @method        initWithFrame:colors:locations:angle:
 @abstract      Initializer for a linear gradient view.
 @param         frame A NSRect specifying the gradient's frame.
 @param         colors An array of NSColor objects representing the colors in the gradient.
 @param         locations An array of CGFloat values containing the location for each color in the gradient.
 Each value must be in the range 0.0 to 1.0. There must be the same number of locations as are colors in the colorArray parameter.
 @param         angle The angle of the linear gradient, specified in degrees. Positive values indicate rotation in the counter-clockwise direction relative to the horizontal axis.
 @discussion    Returns an initialized MTGradientView object.
 */
- (id)initWithFrame:(NSRect)frame colors:(NSArray*)colors locations:(NSArray*)locations angle:(CGFloat)angle;

/*!
 @method        initWithFrame:colors:locations:centerPosition:
 @abstract      Initializer for a radial gradient.
 @param         frame A NSRect specifying the gradient's frame.
 @param         colors An array of NSColor objects representing the colors in the gradient.
 @param         locations An array of CGFloat values containing the location for each color in the gradient.
 Each value must be in the range 0.0 to 1.0. There must be the same number of locations as are colors in the colorArray parameter.
 @param         centerPosition The relative location within the rectangle to use as the center point of the gradient’s end circle. Each coordinate must contain a value between -1.0 and 1.0. A coordinate value of 0 represents the center of rect along the given axis. In the default coordinate system, a value of -1.0 corresponds to the bottom or left edge of the rectangle and a value of 1.0 corresponds to the top or right edge.
 @discussion    Returns an initialized MTGradientView object.
 */
- (id)initWithFrame:(NSRect)frame colors:(NSArray*)colors locations:(NSArray*)locations centerPosition:(NSPoint)centerPosition;

/*!
 @method        initWithDictionary:forFrame:
 @abstract      Initializer for a gradient specified using a NSDictionary.
 @param         dictionary A NSDictionary specifying the gradient.
 @param         frame A NSRect specifying the gradient's frame.
 @discussion    Returns an initialized MTGradientView object.
 */
- (id)initWithDictionary:(NSDictionary*)dictionary forFrame:(NSRect)frame;

/*!
 @method        setColors:andLocations:
 @abstract      Set the receiver's gradient with the given colors and color locations.
 @param         colors An NSArray of NSColor objects specifying the colors.
 @param         locations An NSArray of float numbers specifying the color locations.
 */
- (void)setColors:(NSArray*)colors andLocations:(NSArray*)locations;

/*!
 @method        setColor:atLocation:
 @abstract      Set the color to the receiver's gradient at the given location.
 @param         color An NSColor object specifying the color.
 @param         location A float specifying the color location.
 @discussion    If a color already exists on the specified location, it is changed to the given color. Otherwise a new
 color is added to the gradient at the given location.
 */
- (void)setColor:(NSColor*)color atLocation:(CGFloat)location;

/*!
 @method        colorAtLocation:
 @abstract      Returns the color of the gradient at the given location.
 @param         location The location value for the color you want. This value must be between 0.0 and 1.0.
 @discussion    This method computes the value that would be drawn at the specified location. The start color of the gradient is always located at 0.0 and the end color is always at 1.0.
 */
- (NSColor*)colorAtLocation:(CGFloat)location;

/*!
 @method        image
 @abstract      Returns a NSImage object of the gradient.
 */
- (NSImage*)image;

/*!
 @method        colors
 @abstract      Returns a NSArray containing all NSColor objects of the gradient.
 */
- (NSArray*)colors;

/*!
 @method        locations
 @abstract      Returns a NSArray containing float numbers specifying the locations of the gradient's colors.
 */
- (NSArray*)locations;

/*!
 @method        dictionary
 @abstract      Returns a NSDictionary containing the information needed to draw the gradient.
 */
- (NSDictionary*)dictionary;

/*!
 @method        setAngle:
 @abstract      Set the angle of a linear gradient.
 @param         angle The angle of the linear gradient, specified in degrees. Positive values indicate rotation in the counter-clockwise direction relative to the horizontal axis.
 */
- (void)setAngle:(CGFloat)angle;

/*!
 @method        setCenterPosition:
 @abstract      Set the center position of a radial gradient.
 @param         centerPosition The relative location within the rectangle to use as the center point of the gradient’s end circle. Each coordinate must contain a value between -1.0 and 1.0. A coordinate value of 0 represents the center of rect along the given axis. In the default coordinate system, a value of -1.0 corresponds to the bottom or left edge of the rectangle and a value of 1.0 corresponds to the top or right edge.
 */
- (void)setCenterPosition:(NSPoint)centerPosition;

@end
