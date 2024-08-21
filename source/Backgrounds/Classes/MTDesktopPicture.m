/*
     MTDesktopPicture.m
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

#import "MTDesktopPicture.h"
#import "MTGradientView.h"
#import "MTImage.h"
#import "Constants.h"

@interface MTDesktopPicture ()
@property (nonatomic, strong, readwrite) MTGradientView *gradientView;
@end

@implementation MTDesktopPicture

- (id)initWithGradientView:(MTGradientView*)gradientView
{
    self = [super init];
    
    if (self) {
        _gradientView = gradientView;
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dictionary forFrame:(NSRect)frame
{
    self = [self initWithGradientView:[[MTGradientView alloc] initWithDictionary:dictionary forFrame:frame]];
        
    if (self) {
        _logoName = [dictionary valueForKey:kMTDefaultsLogoName];
        _logoSize = [[dictionary valueForKey:kMTDefaultsLogoSize] doubleValue];
        _logoPosition.x = [[dictionary valueForKey:kMTDefaultsLogoXPosition] doubleValue];
        _logoPosition.y = [[dictionary valueForKey:kMTDefaultsLogoYPosition] doubleValue];
    }

    return self;
}

- (NSImage*)composedImage
{
    // remove all subviews
    [_gradientView setSubviews:[NSArray array]];
    
    // embed a logo (if needed)
    if ([_logoImage isValid]) {
        
        CGFloat imageInsetX = NSWidth([_gradientView frame]) * ((100 - _logoSize) / 200.0);
        CGFloat imageInsetY = NSHeight([_gradientView frame]) * ((100 - _logoSize) / 200.0);
        NSRect imageRect = NSInsetRect([_gradientView frame], imageInsetX, imageInsetY);
        
        NSImageView *logoImageView = [[NSImageView alloc] initWithFrame:imageRect];
        [logoImageView setImageScaling:NSImageScaleProportionallyUpOrDown];
        [logoImageView setImage:_logoImage];
        [logoImageView setFrameOrigin:NSMakePoint(
                                                  NSWidth([_gradientView frame]) / 100.0 * _logoPosition.x - (NSWidth(imageRect) / 100 * _logoPosition.x),
                                                  NSHeight([_gradientView frame]) / 100.0 * _logoPosition.y - (NSHeight(imageRect) / 100 * _logoPosition.y)
                                                  )
        ];
        
        // add logo subview
        [_gradientView addSubview:logoImageView];
    }

    return [_gradientView image];
}

- (NSDictionary*)dictionary
{
    NSMutableDictionary *backgroundDict = [[NSMutableDictionary alloc] init];
    [backgroundDict addEntriesFromDictionary:[_gradientView dictionary]];

    // add logo information
    if (_logoName) {
        [backgroundDict setValue:_logoName forKey:kMTDefaultsLogoName];
        [backgroundDict setValue:[NSNumber numberWithDouble:_logoSize] forKey:kMTDefaultsLogoSize];
        [backgroundDict setValue:[NSNumber numberWithDouble:_logoPosition.x] forKey:kMTDefaultsLogoXPosition];
        [backgroundDict setValue:[NSNumber numberWithDouble:_logoPosition.y] forKey:kMTDefaultsLogoYPosition];
    }
    
    return backgroundDict;
}

- (BOOL)writeToURL:(NSURL*)url
{
    BOOL success = NO;
    
    if (url) {
        NSData *imageData = [[self composedImage] pngData];
        if (imageData) { success = [imageData writeToURL:url atomically:YES]; }
    }
    
    return success;
}

+ (BOOL)setDesktopPictureWithURL:(NSURL*)url forScreen:(NSScreen*)screen options:(NSDictionary<NSWorkspaceDesktopImageOptionKey, id> *)options
{
    BOOL success = [[NSWorkspace sharedWorkspace] setDesktopImageURL:url
                                                           forScreen:screen
                                                             options:options
                                                               error:nil
    ];
    
    return success;
}

+ (NSURL*)imageURLWithScreen:(NSScreen*)screen
{
    NSURL *imageURL = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
               
    if (paths) {
        
        NSString *picturesDirectory = [paths firstObject];
        
        BOOL isDirectory;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:picturesDirectory
                                                 isDirectory:&isDirectory] && isDirectory) {
            
            NSString *fileName = [NSString stringWithFormat:@"Background_id%@_%.f.png", [[screen deviceDescription] valueForKey:@"NSScreenNumber"], [[NSDate date] timeIntervalSince1970]];
            imageURL = [NSURL fileURLWithPath:[picturesDirectory stringByAppendingPathComponent:fileName]];
        }
    }
    
    return imageURL;
}

@end
