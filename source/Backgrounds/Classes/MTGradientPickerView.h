/*
     MTGradientPickerView.h
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
#import "MTColorWellContainerView.h"
#import "MTGradientView.h"
#import "MTColorWell.h"
#import "Constants.h"

/*!
 @abstract This class defines the gradient picker.
 */

@class MTGradientPickerView;

/*!
 @protocol      MTGradientPickerDelegate
 @abstract      Defines an interface for delegates of MTGradientPickerView to be notified if specific aspects of the view have changed.
*/
@protocol MTGradientPickerDelegate <NSObject>
@optional

/*!
 @method        gradientPickerDidChangeColors:
 @abstract      Called whenever the colors of the gradient picker have changed.
 @param         view A reference to the MTGradientPickerView instance that has changed.
 @discussion    Delegates receive this message whenever the colors of the gradient picker have changed.
 */
- (void)gradientPickerDidChangeColors:(MTGradientPickerView*)view;

/*!
 @method        gradientPicker:didAddColor:atLocation:
 @abstract      Called whenever a color stop has been added to the gradient picker.
 @param         view A reference to the MTGradientPickerView instance that has changed.
 @discussion    Delegates receive this message whenever a color stop has been added to the gradient picker.
 */
- (void)gradientPicker:(MTGradientPickerView*)view didAddColor:(NSColor*)color atLocation:(CGFloat)location;

/*!
 @method        gradientPicker:didRemoveColor:atLocation:
 @abstract      Called whenever a color stop has been removed from the gradient picker.
 @param         view A reference to the MTGradientPickerView instance that has changed.
 @discussion    Delegates receive this message whenever a color stop has been removed from the gradient picker.
 */
- (void)gradientPicker:(MTGradientPickerView*)view didRemoveColor:(NSColor*)color atLocation:(CGFloat)location;

/*!
 @method        gradientPicker:didMoveColor:fromLocation:toLocation:
 @abstract      Called whenever a color stop has been moved to a new location.
 @param         view A reference to the MTGradientPickerView instance that has changed.
 @discussion    Delegates receive this message whenever a color stop has been moved to a new location.
 */
- (void)gradientPicker:(MTGradientPickerView*)view didMoveColor:(NSColor*)color fromLocation:(CGFloat)oldLocation toLocation:(CGFloat)newLocation;

/*!
 @method        gradientPicker:didChangeColor:toColor:atLocation:
 @abstract      Called whenever the color of a color stop has changed.
 @param         view A reference to the MTGradientPickerView instance that has changed.
 @discussion    Delegates receive this message whenever the color of a color stop has changed.
 */
- (void)gradientPicker:(MTGradientPickerView*)view didChangeColor:(NSColor*)oldColor toColor:(NSColor*)newColor atLocation:(CGFloat)location;

@end

@interface MTGradientPickerView : NSView <MTColorWellDraggingDelegate>

/*!
 @property      delegate
 @abstract      The receiver's delegate.
 @discussion    The value of this property is an object conforming to the MTGradientPickerDelegate protocol.
*/
@property (weak) id <MTGradientPickerDelegate> delegate;

/*!
 @property      gradientView
 @abstract      The receiver's gradient view.
 @discussion    The value of this property is an MTGradientView object.
*/
@property (nonatomic, strong, readonly) MTGradientView *gradientView;

/*!
 @method        setColors:andLocations:
 @abstract      Set the receiver's gradient with the given colors and color locations.
 @param         colors An NSArray of NSColor objects specifying the colors.
 @param         locations An NSArray of float numbers specifying the color locations.
 */
- (void)setColors:(NSArray*)colors andLocations:(NSArray*)locations;

/*!
 @method        addColor:atLocation:
 @abstract      Add a color to the receiver's gradient at the given location.
 @param         color An NSColor object specifying the color.
 @param         location A float specifying the color location.
 */
- (void)addColor:(NSColor*)color atLocation:(CGFloat)location;

/*!
 @method        removeColorAtLocation:
 @abstract      Remove a color from the receiver's gradient at the given location.
 @param         location A float specifying the color location.
 */
- (void)removeColorAtLocation:(CGFloat)location;

/*!
 @method        changeColorLocation:toLocation:
 @abstract      Change the location of a color at the receiver's gradient to the given location.
 @param         oldLocation A float specifying the current location of the color.
 @param         newLocation A float specifying the new location of the color.
 */
- (void)changeColorLocation:(CGFloat)oldLocation toLocation:(CGFloat)newLocation;

/*!
 @method        replaceColorAtLocation:withColor:
 @abstract      Replace a color at a given location of the receiver's gradient by a new color.
 @param         location A float specifying the location of the color.
 @param         color An NSColor object specifying the new color.
 */
- (void)replaceColorAtLocation:(CGFloat)location withColor:(NSColor*)color;

/*!
 @method        setColorWellToolTip:
 @abstract      Called whenever a subview has been removed from the container view.
 @param         toolTip A NSString object containing the text for the tooltip.
 */
- (void)setColorWellToolTip:(NSString*)toolTip;

@end

