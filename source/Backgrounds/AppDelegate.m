/*
     AppDelegate.m
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

#import "AppDelegate.h"
#import "MTDesktopPicture.h"
#import "MTColor.h"
#import "Constants.h"
#import "MTBackgroundCollection.h"
#import "MTLogoCollection.h"

@interface AppDelegate ()
@property (nonatomic, strong, readwrite) NSArray *queuedImportFiles;
@property (nonatomic, strong, readwrite) NSWindowController *mainWindowController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    NSArray *appArguments = [[NSProcessInfo processInfo] arguments];
    
    if ([appArguments containsObject:@"--setBackground"] || [appArguments containsObject:@"--listBackgrounds"] || [appArguments containsObject:@"--help"]) {
    
        MTBackgroundCollection *backgroundCollection = [[MTBackgroundCollection alloc] init];

#pragma mark "Set Background"
        NSInteger commandIndex = [appArguments indexOfObject:@"--setBackground"];
                            
        if (commandIndex != NSNotFound) {
            
            if ([appArguments count] > ++commandIndex) {
                                
                NSString *backgroundName = [appArguments objectAtIndex:commandIndex];
                
                if (backgroundName) {
                
                    NSDictionary *backgroundDict = [backgroundCollection predefinedBackgroundWithName:backgroundName];
                   
                    if (backgroundDict) {
                        
                        NSImage *logoImage = nil;
                        CGFloat logoSize = 0;
                        CGFloat logoXPosition = 0;
                        CGFloat logoYPosition = 0;
                        NSString *logoName = [backgroundDict valueForKey:kMTDefaultsLogoName];
                        
                        if (logoName) {
                            
                            MTLogoCollection *logoCollection = [[MTLogoCollection alloc] init];
                            NSDictionary *logoDict = [logoCollection logoWithName:logoName];
                            
                            if (logoDict) {
                                
                                logoSize = [[backgroundDict valueForKey:kMTDefaultsLogoSize] doubleValue];
                                logoXPosition = [[backgroundDict valueForKey:kMTDefaultsLogoXPosition] doubleValue];
                                logoYPosition = [[backgroundDict valueForKey:kMTDefaultsLogoYPosition] doubleValue];
                                logoImage = [MTLogoCollection logoImageWithDictionary:logoDict];
                            }
                        }
                        
#pragma mark "All Screens"
                        NSArray *allScreens = ([appArguments containsObject:@"--allScreens"]) ? [NSScreen screens] : [NSArray arrayWithObject:[NSScreen mainScreen]];
                        
                        for (NSScreen *aScreen in allScreens) {
                            
                            MTGradientView *gradientView = [[MTGradientView alloc] initWithDictionary:backgroundDict forFrame:[aScreen frame]];
                            MTDesktopPicture *desktopPicture = [[MTDesktopPicture alloc] initWithGradientView:gradientView];
                            [desktopPicture setLogoImage:logoImage];
                            [desktopPicture setLogoSize:logoSize];
                            [desktopPicture setLogoPosition:NSMakePoint(logoXPosition, logoYPosition)];
                            
                            NSURL *imageURL = [MTDesktopPicture imageURLWithScreen:aScreen];
                            BOOL success = [desktopPicture writeToURL:imageURL];
                            
                            if (success) {
                                
                                // set the desktop picture
                                NSDictionary *wallpaperOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                  [NSNumber numberWithInteger:NSImageScaleNone],
                                                                  NSWorkspaceDesktopImageScalingKey,
                                                                  nil];
                                
                                success = [MTDesktopPicture setDesktopPictureWithURL:imageURL forScreen:aScreen options:wallpaperOptions];
                                
                                uint32_t displayID = [[[aScreen deviceDescription] valueForKey:@"NSScreenNumber"] unsignedIntValue];
                                
                                if (success) {
                                    fprintf(stderr, "Successfully changed background for screen with id %u\n", displayID);
                                } else {
                                    fprintf(stderr, "ERROR! Failed to change background for screen with id %u\n", displayID);
                                }
                            }                            
                        }
                        
                    } else {
                        fprintf(stderr, "ERROR! Unable to find background with name \"%s\"\n", [backgroundName UTF8String]);
                    }
                    
                } else {
                    [self printUsage];
                }
                
            } else {
                [self printUsage];
            }
            
        } else {
            
#pragma mark "List Backgrounds"
            NSInteger commandIndex = [appArguments indexOfObject:@"--listBackgrounds"];
    
            if (commandIndex != NSNotFound) {
        
                for (NSDictionary *backgroundDict in [backgroundCollection predefinedBackgrounds]) {
                    NSString *backgroundName = [backgroundDict valueForKey:kMTDefaultsBackgroundName];
                    if (backgroundName) { fprintf(stdout, "%s\n", [backgroundName UTF8String]); }
                }
        
            } else {
                [self printUsage];
            }
        }
                                
        [NSApp terminate:self];
        
    } else {
        
        // make sure we are frontmost
        [NSApp activateIgnoringOtherApps:YES];
        
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        _mainWindowController = [storyboard instantiateControllerWithIdentifier:@"corp.sap.BackgroundsController"];
        [_mainWindowController showWindow:self];
        [[_mainWindowController window] makeKeyWindow];
        
        // have we been launched by double-clicking an export file?
        if ([_queuedImportFiles count]) {
            [self showImportWarningWithPath:_queuedImportFiles];
            _queuedImportFiles = nil;
        }
    }
}

- (void)printUsage
{
    fprintf(stderr, "\nUsage: Backgrounds --listBackgrounds\n");
    fprintf(stderr, "       Backgrounds --setBackground <name> [--allScreens]\n\n");
    fprintf(stderr, "   --listBackgrounds          Print the names of all available backgrounds.\n\n");
    fprintf(stderr, "   --setBackground <name>     Set the Desktop to the predefined background\n");
    fprintf(stderr, "                              with the given name. The predefined backgrounds\n");
    fprintf(stderr, "                              may be found in the Predefined.plist inside\n");
    fprintf(stderr, "                              the Resources folder of the Backgrounds app\n");
    fprintf(stderr, "                              or may be deployed via configuration profile.\n\n");
    fprintf(stderr, "   --allScreens               Set the Desktop picture as background for all\n");
    fprintf(stderr, "                              attached screens, instead of just for the\n");
    fprintf(stderr, "                              main screen.\n\n");
    fprintf(stderr, "   --help                     Shows this help.\n\n");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app
{
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)filenames
{
    // if our window controller is already there, we display
    // a dialog to ask the user if he/she wants to import the
    // file, otherwise we queue the file name and process it
    // later in applicationDidFinishLaunching:
    
    if (_mainWindowController) {
        [self showImportWarningWithPath:filenames];
    } else {
        _queuedImportFiles = filenames;
    }

    [NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

- (void)showImportWarningWithPath:(NSArray*)importFiles
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"corp.sap.Backgrounds.importFile"
                                                        object:importFiles
                                                      userInfo:nil
    ];
}

@end
