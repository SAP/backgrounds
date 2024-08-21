/*
     MTDesktopPicture.h
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
#import "MTGradientView.h"

/*!
 @abstract This class defines methods to create, save and set a desktop picture (wallpaper).
 */

@interface MTDesktopPicture : NSObject

/*!
 @property      logoImage
 @abstract      The logo image of the desktop picture.
 @discussion    Use this propery to set and get the logo image of the desktop picture.
 The value of this property is a NSImage object. Might be nil.
*/
@property (nonatomic, strong, readwrite) NSImage *logoImage;

/*!
 @property      logoName
 @abstract      The name of the logo.
 @discussion    This property contains the name of the logo image (e.g. as specified in a .bgexport file).
 Use this name to provide the actual image data using the logoImage property. The value of this property is a
 NSString object. Might be nil.
*/
@property (nonatomic, strong, readwrite) NSString *logoName;

/*!
 @property      logoSize
 @abstract      The size of the logo image.
 @discussion    Use this property to specify the size of the logo image (in percent of the whole desktop picture).
 The value of this property is a float.
*/
@property (assign) CGFloat logoSize;

/*!
 @property      logoPosition
 @abstract      The position of the logo image.
 @discussion    Use this property to specify the positiion of the logo image. A value of {0, 0} specifies a bottom-left
 position, {.5, .5} a center position and {1, 1} a top-right position. The value of this property is a NSPoint object.
*/
@property (assign) NSPoint logoPosition;

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithGradientView: or initWithDictionary: instead.
 */
- (id)init NS_UNAVAILABLE;

/*!
 @method        initWithGradientView:
 @abstract      Create a desktop picture from a given MTGradientView.
 @param         gradientView A reference to a MTGradientView object.
 @discussion    Creates a desktop picture from the given gradient view. The gradient view specifies the size of the desktop picture.
 */
- (id)initWithGradientView:(MTGradientView*)gradientView NS_DESIGNATED_INITIALIZER;

/*!
 @method        initWithDictionary:forFrame:
 @abstract      Create a desktop picture from a given NSDictionary for the given frame size.
 @param         dictionary A NSDictionary containing background data (e.g. from a .bgexport file).
 @param         frame A NSRect specifying the frame for the desktop picture.
 @discussion    Creates a desktop picture from the given dictionary and with the given frame.
 */
- (id)initWithDictionary:(NSDictionary*)dictionary forFrame:(NSRect)frame;

/*!
 @method        composedImage
 @abstract      Returns the composed desktop picture (including logo image).
 @discussion    Returns an NSImage object containing the composed desktop picture (including logo image).
 */
- (NSImage*)composedImage;

/*!
 @method        writeToURL:
 @abstract      Write the composed desktop picture to disk.
 @param         url The file url where the desktop picture should be written to.
 @discussion    Returns YES if the desktop picture has been successfully written to disk, otherwise returns NO.
 */
- (BOOL)writeToURL:(NSURL*)url;

/*!
 @method        dictionary
 @abstract      Returns an NSDictionary of the current deskop picture.
 @discussion    Returns an NSDictionary containing the information for the current deskop picture.
 */
- (NSDictionary*)dictionary;

/*!
 @method        setDesktopPictureWithURL:forScreen:options:
 @abstract      Set the deskop picture with the given url for the given screen with options.
 @param         url The file url where the desktop picture is located.
 @param         screen A reference to the screen where the deskop picture should be set for.
 @param         options A NSDictionary of NSWorkspaceDesktopImageOptionKey and values.
 @discussion    Returns YES if the desktop picture has been successfully set, otherwise returns NO.
 */
+ (BOOL)setDesktopPictureWithURL:(NSURL*)url forScreen:(NSScreen*)screen options:(NSDictionary<NSWorkspaceDesktopImageOptionKey, id> *)options;

/*!
 @method        imageURLWithScreen:
 @abstract      Returns a unique url that may be used to write the desktop picture to.
 @param         screen A reference to the screen where the deskop picture should be set for.
 @discussion    Returns an NSURL object or nil, if an error occurred.
 */
+ (NSURL*)imageURLWithScreen:(NSScreen*)screen;

@end
