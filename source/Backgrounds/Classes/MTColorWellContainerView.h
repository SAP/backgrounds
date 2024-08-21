/*
     MTColorWellContainerView.h
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
 @abstract This class defines a container view for holding our color wells.
 */

@class MTColorWellContainerView;

/*!
 @protocol      MTColorWellContainerViewDelegate
 @abstract      Defines an interface for delegates of MTColorWellContainerView to be notified if specific aspects of the view have changed.
*/
@protocol MTColorWellContainerViewDelegate <NSObject>
@optional

/*!
 @method        containerView:didAddSubview:
 @abstract      Called whenever a new subview has been added to the container view.
 @param         view A reference to the MTColorWellContainerView instance that has changed.
 @param         subview A reference to the view that has been added.
 @discussion    Delegates receive this message whenever a new subview has been added to the container view.
 */
- (void)containerView:(MTColorWellContainerView*)view didAddSubview:(NSView*)subview;

/*!
 @method        containerView:didRemoveSubview:
 @abstract      Called whenever a subview has been removed from the container view.
 @param         view A reference to the MTColorWellContainerView instance that has changed.
 @param         subview A reference to the view that has been removed.
 @discussion    Delegates receive this message whenever a subview has been removed from the container view.
 */
- (void)containerView:(MTColorWellContainerView*)view didRemoveSubview:(NSView*)subview;

@end

@interface MTColorWellContainerView : NSView

/*!
 @property      delegate
 @abstract      The receiver's delegate.
 @discussion    The value of this property is an object conforming to the MTColorWellContainerViewDelegate protocol.
*/
@property (weak) id <MTColorWellContainerViewDelegate> delegate;

/*!
 @method        generateTrackingAreas
 @abstract      Generate tracking areas between all color wells.
 @discussion    This method generates tracking areas between all color wells (subviews) contained in the container view.
 */
- (void)generateTrackingAreas;

/*!
 @method        removeAllTrackingAreas
 @abstract      Remove all tracking areas from the container view.
 @discussion    This method removes all tracking areas from the container view.
 */
- (void)removeAllTrackingAreas;

/*!
 @method        isInsideTrackingArea
 @abstract      A boolean indicating if the mouse pointer is inside one of the container view's tracking areas or not.
 @discussion    Returns YES if the mouse pointer is inside one of the container view's tracking areas, otherwise returns NO.
 */
- (BOOL)isInsideTrackingArea;

@end
