/*
     MTColorWell.h
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
 @abstract This class defines a custom NSColorWell object.
 */

@class MTColorWell;

/*!
 @protocol      MTColorWellDraggingDelegate
 @abstract      Defines an interface for delegates of MTColorWell to be notified if specific aspects of the color well have changed.
*/
@protocol MTColorWellDraggingDelegate <NSObject>
@optional

/*!
 @method        colorWellDidStartDragging:
 @abstract      Called whenever the color well is dragged.
 @param         colorWell A reference to the MTColorWell instance that is dragged.
 @discussion    Delegates receive this message whenever the color well is dragged.
 */
- (void)colorWellDidStartDragging:(MTColorWell*)colorWell;

/*!
 @method        colorWellDidMove:
 @abstract      Called whenever the color well has been moved.
 @param         colorWell A reference to the MTColorWell instance that has been moved.
 @discussion    Delegates receive this message whenever the color well has been moved.
 */
- (void)colorWellDidMove:(MTColorWell*)colorWell;

/*!
 @method        colorWellDidEndDragging:
 @abstract      Called whenever the color well has been dragged.
 @param         colorWell A reference to the MTColorWell instance that has been dragged.
 @discussion    Delegates receive this message whenever the color well has ended dragging.
 */
- (void)colorWellDidEndDragging:(MTColorWell*)colorWell;

/*!
 @method        colorWellDidChangeColor:oldColor:newColor:
 @abstract      Called whenever the color well's color did change.
 @param         colorWell A reference to the MTColorWell instance that has changed its color.
 @param         oldColor A NSColor object containing the previous color of the color well.
 @param         newColor A NSColor object containing the new (current) color of the color well.
 @discussion    Delegates receive this message whenever the color well has changed its color.
 */
- (void)colorWellDidChangeColor:(MTColorWell*)colorWell oldColor:(NSColor*)oldColor newColor:(NSColor*)newColor;
@end

@interface MTColorWell : NSColorWell <NSDraggingSource>

/*!
 @property      delegate
 @abstract      The receiver's delegate.
 @discussion    The value of this property is an object conforming to the MTColorWellDraggingDelegate protocol.
*/
@property (weak) id <MTColorWellDraggingDelegate> delegate;

/*!
 @property      location
 @abstract      The color well's location.
 @discussion    In some situations the location of the color well (e.g. on a gradient) might be important. Especially if undo/redo functionaltiy is needed. So the location of the color well might be stored using this property. The value of this property is a float.
*/
@property (assign) CGFloat location;

@end

