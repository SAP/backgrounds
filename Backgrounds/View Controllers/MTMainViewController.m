/*
     MTMainViewController.m
     Copyright 2022 SAP SE
     
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

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "MTMainViewController.h"
#import "MTCollectionViewHeader.h"
#import "MTBackgroundCollection.h"
#import "MTFilePromiseProvider.h"
#import "MTSlider.h"
#import "MTPopUpButton.h"
#import "MTLogoCollection.h"

@interface MTMainViewController ()
@property (weak) IBOutlet NSImageView *imagePreview;

@property (weak) IBOutlet MTSlider *gradientAngleSlider;
@property (weak) IBOutlet MTSlider *gradientXPositionSlider;
@property (weak) IBOutlet MTSlider *gradientYPositionSlider;
@property (weak) IBOutlet MTSlider *logoSizeSlider;
@property (weak) IBOutlet MTSlider *logoXPositionSlider;
@property (weak) IBOutlet MTSlider *logoYPositionSlider;

@property (weak) IBOutlet MTCollectionView *collectionView;
@property (weak) IBOutlet MTGradientPickerView *gradientPickerView;
@property (weak) IBOutlet NSArrayController *logoArrayController;

@property (weak) IBOutlet NSButton *allScreensButton;
@property (weak) IBOutlet NSButton *linearGradientButton;
@property (weak) IBOutlet NSButton *radialGradientButton;
@property (weak) IBOutlet MTPopUpButton *logoPopupButton;
@property (weak) IBOutlet NSBox *logoControls;
@property (weak) IBOutlet NSLayoutConstraint *logoControlsHeight;
@property (weak) IBOutlet NSLayoutConstraint *logoControlsTop;

@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) MTBackgroundCollection *backgroundCollection;
@property (nonatomic, strong, readwrite) MTLogoCollection *logoCollection;
@property (nonatomic, strong, readwrite) NSMutableArray *logoArray;
@end

@implementation MTMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *defaultSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithDouble:kMTLogoSizeDefault], kMTDefaultsSelectedLogoSize,
                                     [NSNumber numberWithDouble:kMTLogoXPositionDefault], kMTDefaultsSelectedLogoXPosition,
                                     [NSNumber numberWithDouble:kMTLogoYPositionDefault], kMTDefaultsSelectedLogoYPosition,
                                     nil
                                     ];
    [_userDefaults registerDefaults:defaultSettings];

    // match the aspect ratio of the preview image with
    // the aspect ratio of the screen
    [self windowDidChangeScreen:nil];
        
    // make us a delegate for the gradient picker, so
    // we get updates whenever the picker's colors change
    [_gradientPickerView setDelegate:self];
    
    // add toolips to our slider and the color wells
    [self changeGradientAngle:nil];
    [self changeGradientPosition:nil];
    [_gradientPickerView setColorWellToolTip:NSLocalizedString(@"colorWellToolTip", nil)];
    
    // generate the logo menu
    MTLogoCollection *logoCollection = [[MTLogoCollection alloc] init];
    NSArray *allLogos = [logoCollection logos];

    if ([allLogos count] > 0) {
        
        _logoArray = [[NSMutableArray alloc] init];

        // add the "none" entry
        [_logoArrayController addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"noLogoEntry", nil), kMTDefaultsLogoName, nil]];
        
        // add the logos (sorted by name)
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:kMTDefaultsLogoName
                                                                                          ascending:YES
                                                                                           selector:@selector(localizedCaseInsensitiveCompare:)]];
        [_logoArrayController addObjects:[allLogos sortedArrayUsingDescriptors:sortDescriptors]];
        
    } else {
        
        // if no logo images are configured, remove
        // the constraints of all our subviews, so we
        // can set the height of our box to 0
        for (NSView *aSubview in [_logoControls subviews]) { [aSubview removeConstraints:[aSubview constraints]]; }
        [_logoControls setBoxType:NSBoxCustom];
        [_logoControls setTransparent:YES];
        [_logoControls setBorderWidth:0];
        [_logoControlsTop setConstant:0];
        [_logoControlsHeight setConstant:0];
    }
    
    // initialize our backgrounds collection
    _backgroundCollection = [[MTBackgroundCollection alloc] init];
    
    // set a menu delegate for our collection view
    [_collectionView setMenuDelegate:self];
    
    // set dragging operation
    [_collectionView registerForDraggedTypes:[NSArray arrayWithObjects:kMTFileTypeExport, NSPasteboardTypeFileURL, nil]];
    [_collectionView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    
    // select the first item of our collection view
    NSInteger firstSection = -1;

    for (NSInteger x = 0; x < [_collectionView numberOfSections]; x++) {
        if ([_collectionView numberOfItemsInSection:x] > 0) {
            firstSection = x;
            break;
        }
    }

    if (firstSection >= 0 && [_collectionView numberOfItemsInSection:firstSection] > 0) {
        
        NSIndexPath *firstItem = [NSIndexPath indexPathForItem:0 inSection:firstSection];
        
        if ([[_backgroundCollection predefinedBackgrounds] count] > 0) {
            [_collectionView selectItemsAtIndexPaths:[NSSet setWithCollectionViewIndexPath:firstItem]
                                                scrollPosition:NSCollectionViewScrollPositionNone];
            
            // apply the selected background
            NSDictionary *backgroundDict = [_backgroundCollection backgroundAtIndexPath:firstItem];
            [self applyBackgroundDict:backgroundDict];
        }
        
    } else {
        
        [self updatePreview:nil];
    }
    
    // observe display changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screensDidChange:)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil
    ];
    
    // we also want to get notified if the main window is moved to another screen
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidChangeScreen:)
                                                 name:NSWindowDidChangeScreenNotification
                                               object:[[self view] window]
    ];
    
    // get notified if the user clicked a file in Finder
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(importGradientsFromFile:)
                                                 name:@"corp.sap.Backgrounds.importFile"
                                               object:nil
    ];
    
    // show/hide our buttons depending on how many displays are connected
    [self screensDidChange:nil];
}

- (void)dealloc
{    
    // remove our observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationDidChangeScreenParametersNotification
                                                  object:nil
    ];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowDidChangeScreenNotification
                                                  object:nil
    ];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"corp.sap.Backgrounds.importFile"
                                                  object:nil
    ];
}

- (NSImage*)logoForSelectionIndex:(NSInteger)selectionIndex
{
    NSImage *logoImage = nil;
    
    if (selectionIndex >= 0 && selectionIndex < [[_logoArrayController arrangedObjects] count]) {
        
        NSDictionary *selectedObject = [[_logoArrayController arrangedObjects] objectAtIndex:selectionIndex];
        logoImage = [MTLogoCollection logoImageWithDictionary:selectedObject];
    }
    
    return logoImage;
}

- (BOOL)setDesktopPictureWithURL:(NSURL*)url forScreen:(NSScreen*)screen options:(NSDictionary<NSWorkspaceDesktopImageOptionKey, id> *)options
{
    BOOL success = NO;
    
    // get the current desktop picture's url and options so
    // we can undo the change we'll make
    NSDictionary *currentOptions = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:screen];
    NSURL *currentURL = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:screen];

    success = [MTDesktopPicture setDesktopPictureWithURL:url forScreen:screen options:options];

    // undo/redo
    if (success) {
        [[[self undoManager] prepareWithInvocationTarget:self] setDesktopPictureWithURL:currentURL forScreen:screen options:currentOptions ];
    }
    
    return success;
}

- (NSDictionary*)currentBackgroundDict
{
    MTGradientView *gradientView = nil;
        
    if ([_linearGradientButton state] == NSControlStateValueOff) {
        
        gradientView = [[MTGradientView alloc] initWithFrame:NSZeroRect
                                                      colors:[[_gradientPickerView gradientView] colors]
                                                   locations:[[_gradientPickerView gradientView] locations]
                                              centerPosition:NSMakePoint([_gradientXPositionSlider doubleValue], [_gradientYPositionSlider doubleValue])
        ];
        
    } else {
        
        gradientView = [[MTGradientView alloc] initWithFrame:NSZeroRect
                                                      colors:[[_gradientPickerView gradientView] colors]
                                                   locations:[[_gradientPickerView gradientView] locations]
                                                       angle:[_gradientAngleSlider doubleValue]
        ];
    }
    
    MTDesktopPicture *desktopPicture = [[MTDesktopPicture alloc] initWithGradientView:gradientView];
    
    if ([_logoPopupButton indexOfSelectedItem] > 0) {
        [desktopPicture setLogoName:[[_logoPopupButton selectedItem] title]];
        [desktopPicture setLogoSize:[_logoSizeSlider doubleValue]];
        [desktopPicture setLogoPosition:NSMakePoint([_logoXPositionSlider doubleValue], [_logoYPositionSlider doubleValue])];
    }

    return [desktopPicture dictionary];
}

- (void)applyBackgroundDict:(NSDictionary*)dictionary
{
    MTGradientView *gradientView = [[MTGradientView alloc] initWithDictionary:dictionary forFrame:NSZeroRect];

    [_gradientPickerView setColors:[gradientView colors] andLocations:[gradientView locations]];

    if ([gradientView isRadialGradiant]) {
        
        [_radialGradientButton setState:NSControlStateValueOn];
        [_linearGradientButton setState:NSControlStateValueOff];
        [_gradientXPositionSlider setDoubleValue:[gradientView centerPosition].x];
        [_gradientYPositionSlider setDoubleValue:[gradientView centerPosition].y];
        
        [self changeGradientPosition:nil];
        
    } else {
        
        [_radialGradientButton setState:NSControlStateValueOff];
        [_linearGradientButton setState:NSControlStateValueOn];
        [_gradientAngleSlider setDoubleValue:[gradientView angle]];
        
        [self changeGradientAngle:nil];
    }

    if ([_logoControlsHeight constant] > 0) {

       // if the selected background contains a logo, we make sure it
       // is displayed. if the user manually selected a logo and the
       // selected background does not contain a logo, we use the logo
       // the user selected.
       NSString *logoName = [dictionary valueForKey:kMTDefaultsLogoName];

       if (logoName) {

           // set popup button and sliders
           [_logoArrayController setSelectionIndex:[_logoPopupButton indexOfItemWithTitle:logoName]];

           [_logoSizeSlider setDoubleValue:[[dictionary valueForKey:kMTDefaultsLogoSize] doubleValue]];
           [_logoXPositionSlider setDoubleValue:[[dictionary valueForKey:kMTDefaultsLogoXPosition] doubleValue]];
           [_logoYPositionSlider setDoubleValue:[[dictionary valueForKey:kMTDefaultsLogoYPosition] doubleValue]];

           [self changeLogoSizeOrPosition:nil];

       } else {

           // select the "none" entry
           [_logoArrayController setSelectionIndex:0];
       }

       [self selectLogo:nil];

    } else {

       [self updatePreview:nil];
    }
}

- (void)reloadPredefinedBackgrounds
{
    [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:kMTSectionPredefined]];
}

- (void)reloadUserDefinedBackgrounds
{
    [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:kMTSectionUserDefined]];
}

#pragma mark Notification handlers
- (void)screensDidChange:(NSNotification*)aNotification
{
    ([[NSScreen screens] count] > 1) ? [_allScreensButton setHidden:NO] : [_allScreensButton setHidden:YES];
}

- (void)windowDidChangeScreen:(NSNotification *)notification
{
    // match the aspect ratio of the preview image with
    // the aspect ratio of the screen
    NSRect screenFrame = NSZeroRect;
    
    if (notification == nil) {
        screenFrame = [[NSScreen mainScreen] frame];
    } else {
        NSWindow *mainWindow = [notification object];
        if (mainWindow) { screenFrame = [[mainWindow screen] frame]; }
    }
    
    CGFloat newMultiplier = NSWidth(screenFrame) / NSHeight(screenFrame);
    
    if (newMultiplier > 0) {
        
        // update the image view
        NSArray *imageViewConstraints = [_imagePreview constraints];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d AND secondAttribute = %d", NSLayoutAttributeWidth, NSLayoutAttributeHeight];
        NSArray <NSLayoutConstraint*> *filteredArray = [imageViewConstraints filteredArrayUsingPredicate:predicate];
        
        [filteredArray enumerateObjectsWithOptions:NSEnumerationConcurrent
                                        usingBlock:^(NSLayoutConstraint * _Nonnull existingConstraint, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem:[existingConstraint firstItem]
                                                                             attribute:[existingConstraint firstAttribute]
                                                                             relatedBy:[existingConstraint relation]
                                                                                toItem:[existingConstraint secondItem]
                                                                             attribute:[existingConstraint secondAttribute]
                                                                            multiplier:newMultiplier
                                                                              constant:[existingConstraint constant]
            ];
            
            [newConstraint setPriority:[existingConstraint priority]];
            [newConstraint setIdentifier:[existingConstraint identifier]];
            [newConstraint setShouldBeArchived:[existingConstraint shouldBeArchived]];
            
            // deactivate the existing contraint and activate the new one
            [NSLayoutConstraint deactivateConstraints:[NSArray arrayWithObject:existingConstraint]];
            [NSLayoutConstraint activateConstraints:[NSArray arrayWithObject:newConstraint]];
        }];
        
        [_imagePreview layoutSubtreeIfNeeded];
        [self updatePreview:nil];
    }
}

- (void)importGradientsFromFile:(NSNotification*)notification
{
    NSAlert *theAlert = [[NSAlert alloc] init];
    [theAlert setMessageText:NSLocalizedString(@"importFromFileAlert", nil)];
    [theAlert addButtonWithTitle:NSLocalizedString(@"yesButton", nil)];
    [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
    [theAlert setAlertStyle:NSAlertStyleInformational];
    [theAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {

        if (returnCode == NSAlertFirstButtonReturn) {

            NSArray *filePaths = [notification object];
            
            for (NSString *path in filePaths) {
                [self->_backgroundCollection importBackgroundsWithURL:[NSURL fileURLWithPath:path]];
            }
            
            [self reloadUserDefinedBackgrounds];
        }
    }];
}

#pragma mark IB actions
- (IBAction)showOrHidePredefinedGradients:(id)sender
{
    BOOL hidePredefinedGradients = [_userDefaults boolForKey:kMTDefaultsPredefinedHide];
    [_userDefaults setBool:!hidePredefinedGradients forKey:kMTDefaultsPredefinedHide];
    [self reloadPredefinedBackgrounds];
}

- (IBAction)deleteCollectionViewItem:(id)sender
{
    NSSet *selectedInSection = [_collectionView selectionIndexesInSection:kMTSectionUserDefined];
    
    if ([selectedInSection count] > 0) {
        
        NSAlert *theAlert = [[NSAlert alloc] init];
        
        if ([selectedInSection count] == 1) {
            [theAlert setMessageText:NSLocalizedString(@"removeBackgroundAlert", nil)];
        } else if ([selectedInSection count] == [_backgroundCollection numberOfBackgroundsInSection:kMTSectionUserDefined]) {
            [theAlert setMessageText:NSLocalizedString(@"removeAllBackgroundsAlert", nil)];
        } else {
            [theAlert setMessageText:NSLocalizedString(@"removeMultipleBackgroundsAlert", nil)];
        }
        
        [theAlert setInformativeText:NSLocalizedString(@"noUndoAlertText", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"deleteButton", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
        [theAlert setAlertStyle:NSAlertStyleInformational];
        [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
            
            if (returnCode == NSAlertFirstButtonReturn) {

                NSMutableIndexSet *removeIndexes = [[NSMutableIndexSet alloc] init];
                for (NSIndexPath *selectedItem in selectedInSection) { [removeIndexes addIndex:[selectedItem item]]; }
                [self->_backgroundCollection removeUserDefinedBackgroundsAtIndexes:removeIndexes];
                [self->_backgroundCollection synchronize];
                [self reloadUserDefinedBackgrounds];
            }
        }];
    }
}

- (IBAction)saveBackground:(id)sender
{
    NSDictionary *backgroundDict = [self currentBackgroundDict];
    
    if (backgroundDict) {
        [_backgroundCollection addUserDefinedBackground:backgroundDict];
        [_backgroundCollection synchronize];
        [self reloadUserDefinedBackgrounds];
    }
}

- (IBAction)selectLogo:(id)sender
{
    if (sender) {
        
        // undo/redo
        [[self undoManager] setActionName:NSLocalizedString(@"undoChangeLogo", nil)];
        [[[self undoManager] prepareWithInvocationTarget:self] selectLogo:sender];
        [[[self undoManager] prepareWithInvocationTarget:self.logoArrayController] setSelectionIndex:[_logoPopupButton previousSelectionIndex]];
    }
    
    NSDictionary *selectedObject = [[_logoArrayController selectedObjects] firstObject];

    if (selectedObject) {
        
        NSImage *selectedLogo = [self logoForSelectionIndex:[_logoPopupButton indexOfSelectedItem]];
        
        if ([selectedLogo isValid] && sender) {
            
            // set size and position
            if ([selectedObject objectForKey:kMTDefaultsLogoSize]) {
                [_logoSizeSlider setDoubleValue:[[selectedObject valueForKey:kMTDefaultsLogoSize] doubleValue]];
            } else {
                [_logoSizeSlider setDoubleValue:[_userDefaults doubleForKey:kMTDefaultsSelectedLogoSize]];
            }
            
            if ([selectedObject objectForKey:kMTDefaultsLogoXPosition]) {
                [_logoXPositionSlider setDoubleValue:[[selectedObject valueForKey:kMTDefaultsLogoXPosition] doubleValue]];
            } else {
                [_logoXPositionSlider setDoubleValue:[_userDefaults doubleForKey:kMTDefaultsSelectedLogoXPosition]];
            }
            
            if ([selectedObject objectForKey:kMTDefaultsLogoYPosition]) {
                [_logoYPositionSlider setDoubleValue:[[selectedObject valueForKey:kMTDefaultsLogoYPosition] doubleValue]];
            } else {
                [_logoYPositionSlider setDoubleValue:[_userDefaults doubleForKey:kMTDefaultsSelectedLogoYPosition]];
            }
            
            // update the slider's tooltips
            [self changeLogoSizeOrPosition:nil];
        }
        
        // update the user defaults accordingly
        [_userDefaults setDouble:[_logoSizeSlider doubleValue] forKey:kMTDefaultsSelectedLogoSize];
        [_userDefaults setDouble:[_logoXPositionSlider doubleValue] forKey:kMTDefaultsSelectedLogoXPosition];
        [_userDefaults setDouble:[_logoYPositionSlider doubleValue] forKey:kMTDefaultsSelectedLogoYPosition];
    }
        
    [self updatePreview:sender];
}

- (IBAction)updatePreview:(id)sender
{
    // make sure we unselect the items in our collection view,
    // whenever something has been changed using ui elements.
    if (sender) {
        [_collectionView deselectAll:nil];
        [_collectionView takeSelectionSnaphot];
    }
    
    // generate a new preview image
    MTDesktopPicture *desktopPicture = [[MTDesktopPicture alloc] initWithDictionary:[self currentBackgroundDict] forFrame:[_imagePreview bounds]];
    [desktopPicture setLogoImage:[self logoForSelectionIndex:[_logoPopupButton indexOfSelectedItem]]];
    NSImage *previewImage = [desktopPicture composedImage];
    
    if ([previewImage isValid]) { [_imagePreview setImage:previewImage]; }
}

- (IBAction)setDesktopPicture:(id)sender
{
    NSArray <NSScreen*> *allScreens = ([sender tag] == 1) ? [NSScreen screens] : [NSArray arrayWithObject:[NSScreen mainScreen]];
    
    if ([sender tag] == 1) {
        [[self undoManager] setActionName:NSLocalizedString(@"undoSetBackgroundForAll", nil)];
    } else {
        [[self undoManager] setActionName:NSLocalizedString(@"undoSetBackgroundForScreen", nil)];
    }
    
    [[self undoManager] beginUndoGrouping];
    
    NSDictionary *currentBackgroundDict = [self currentBackgroundDict];
    NSImage *logoImage = [self logoForSelectionIndex:[self->_logoPopupButton indexOfSelectedItem]];

    for (NSScreen *aScreen in allScreens) {
            
        MTDesktopPicture *desktopPicture = [[MTDesktopPicture alloc] initWithDictionary:currentBackgroundDict forFrame:[aScreen frame]];
        [desktopPicture setLogoImage:logoImage];
        
        NSURL *imageURL = [MTDesktopPicture imageURLWithScreen:aScreen];
        
        if ([desktopPicture writeToURL:imageURL]) {
            
            // set the desktop picture
            NSDictionary *wallpaperOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInteger:NSImageScaleNone],
                                              NSWorkspaceDesktopImageScalingKey,
                                              nil];
            
            [self setDesktopPictureWithURL:imageURL forScreen:aScreen options:wallpaperOptions];
        }
    }
    
    [[self undoManager] endUndoGrouping];
}

- (IBAction)exportSelectedGradients:(id)sender
{
    NSSet *selectedInSection = [_collectionView selectionIndexesInSection:kMTSectionUserDefined];

    if ([selectedInSection count] > 0) {
                
        NSSavePanel *panel = [NSSavePanel savePanel];
        [panel setPrompt:NSLocalizedString(@"exportButton", nil)];
        [panel setNameFieldStringValue:NSLocalizedString(@"exportFileName", nil)];
        [panel setAllowedContentTypes:[NSArray arrayWithObjects:[UTType typeWithIdentifier:kMTFileTypeExport], nil]];
        [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result){
            
            if (result == NSModalResponseOK) {
                [self->_backgroundCollection exportBackgroundsAtIndexPaths:selectedInSection toURL:[panel URL]];
            }
        }];
    }
}

- (IBAction)importGradients:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt:NSLocalizedString(@"importButton", nil)];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    [panel setCanCreateDirectories:NO];
    [panel setAllowedContentTypes:[NSArray arrayWithObject:[UTType typeWithIdentifier:kMTFileTypeExport]]];
    [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        
        if (result == NSModalResponseOK) {
            
            for (NSURL *url in [panel URLs]) {
                [self->_backgroundCollection importBackgroundsWithURL:url];
            }
                            
            [self reloadUserDefinedBackgrounds];
        }
    }];
}

- (IBAction)changeGradientType:(id)sender
{
    if (sender) {

        [[self undoManager] setActionName:NSLocalizedString(@"undoChangeGradientType", nil)];
        
        if ([_linearGradientButton state] == NSControlStateValueOn) {

            // undo/redo
            [[[self undoManager] prepareWithInvocationTarget:self] changeGradientType:_radialGradientButton];
            [[[self undoManager] prepareWithInvocationTarget:self.radialGradientButton] setState:NSControlStateValueOn];
            
            [self changeGradientAngle:nil];
            
        } else {

            // undo/redo
            [[[self undoManager] prepareWithInvocationTarget:self] changeGradientType:_linearGradientButton];
            [[[self undoManager] prepareWithInvocationTarget:self.linearGradientButton] setState:NSControlStateValueOn];
            
            [self changeGradientPosition:nil];
        }

        [self updatePreview:sender];
    }
}

- (IBAction)changeGradientAngle:(id)sender
{
    NSMeasurementFormatter *angleFormatter = [[NSMeasurementFormatter alloc] init];
    [[angleFormatter numberFormatter] setMaximumFractionDigits:1];
    
    NSMeasurement *angleMeasurement = [[NSMeasurement alloc] initWithDoubleValue:[_gradientAngleSlider doubleValue] unit:[NSUnitAngle degrees]];
    [_gradientAngleSlider setToolTip:[NSString localizedStringWithFormat:NSLocalizedString(@"angleSliderToolTip", nil), [angleFormatter stringFromMeasurement:angleMeasurement]]];
    
    if (sender) {

        [self updatePreview:sender];
            
        NSEventType eventType = [[[NSApplication sharedApplication] currentEvent] type];
        
        if (eventType == NSEventTypeLeftMouseUp || eventType == NSEventTypeKeyDown) {

            // undo/redo
            [[self undoManager] setActionName:NSLocalizedString(@"undoChangeGradientAngle", nil)];
            [[[self undoManager] prepareWithInvocationTarget:self] changeGradientAngle:sender];
            [[[self undoManager] prepareWithInvocationTarget:self.gradientAngleSlider] setDoubleValue:[_gradientAngleSlider previousValue]];
        }
    }
}

- (IBAction)changeGradientPosition:(id)sender
{
    NSNumberFormatter *percentFormatter = [[NSNumberFormatter alloc] init];
    [percentFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    [percentFormatter setMaximumFractionDigits:1];
    
    if (!sender || [sender tag] == 1) {
        
        double sliderPercentValue = ([_gradientXPositionSlider doubleValue] + 1) / 2;
        [_gradientXPositionSlider setToolTip:[NSString localizedStringWithFormat:NSLocalizedString(@"xPositionSliderToolTip", nil), [percentFormatter stringFromNumber:[NSNumber numberWithDouble:sliderPercentValue]]]];
    }
    
    if (!sender || [sender tag] == 2) {
        
        double sliderPercentValue = ([_gradientYPositionSlider doubleValue] + 1) / 2;
        [_gradientYPositionSlider setToolTip:[NSString localizedStringWithFormat:NSLocalizedString(@"yPositionSliderToolTip", nil), [percentFormatter stringFromNumber:[NSNumber numberWithDouble:sliderPercentValue]]]];
    }
    
    if (sender) {
        
        [self updatePreview:sender];
        
        NSEventType eventType = [[[NSApplication sharedApplication] currentEvent] type];
        
        if (eventType == NSEventTypeLeftMouseUp || eventType == NSEventTypeKeyDown) {

            // undo/redo
            [[self undoManager] setActionName:NSLocalizedString(@"undoChangeGradientPosition", nil)];
            [[[self undoManager] prepareWithInvocationTarget:self] changeGradientPosition:sender];
            
            if ([sender tag] == 1) {
                [[[self undoManager] prepareWithInvocationTarget:self.gradientXPositionSlider] setDoubleValue:[_gradientXPositionSlider previousValue]];
                
            } else if ([sender tag] == 2) {
                [[[self undoManager] prepareWithInvocationTarget:self.gradientYPositionSlider] setDoubleValue:[_gradientYPositionSlider previousValue]];
            }
        }
    }
}

- (IBAction)changeLogoSizeOrPosition:(id)sender
{
    NSNumberFormatter *percentFormatter = [[NSNumberFormatter alloc] init];
    [percentFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    [percentFormatter setMaximumFractionDigits:1];
    [percentFormatter setMultiplier:@1];

    if (!sender || [sender tag] == 1) {
        
        [_logoSizeSlider setToolTip:[NSString localizedStringWithFormat:NSLocalizedString(@"logoSizeSliderToolTip", nil), [percentFormatter stringFromNumber:[NSNumber numberWithDouble:[_logoSizeSlider doubleValue]]]]];
    }
    
    if (!sender || [sender tag] == 2) {
        
        [_logoXPositionSlider setToolTip:[NSString localizedStringWithFormat:NSLocalizedString(@"xLogoPositionSliderToolTip", nil), [percentFormatter stringFromNumber:[NSNumber numberWithDouble:[_logoXPositionSlider doubleValue]]]]];
    }
    
    if (!sender || [sender tag] == 3) {
        
        [_logoYPositionSlider setToolTip:[NSString localizedStringWithFormat:NSLocalizedString(@"yLogoPositionSliderToolTip", nil), [percentFormatter stringFromNumber:[NSNumber numberWithDouble:[_logoYPositionSlider doubleValue]]]]];
    }
    
    if (sender) {

        [self updatePreview:sender];
        
        NSEventType eventType = [[[NSApplication sharedApplication] currentEvent] type];
        
        if (eventType == NSEventTypeLeftMouseUp || eventType == NSEventTypeKeyDown) {

            // undo/redo
            [[[self undoManager] prepareWithInvocationTarget:self] changeLogoSizeOrPosition:sender];
            
            if ([sender tag] == 1) {
                [[self undoManager] setActionName:NSLocalizedString(@"undoChangeLogoSize", nil)];
                [[[self undoManager] prepareWithInvocationTarget:self.logoSizeSlider] setDoubleValue:[_logoSizeSlider previousValue]];
                
            } else if ([sender tag] == 2) {
                [[self undoManager] setActionName:NSLocalizedString(@"undoChangeLogoPosition", nil)];
                [[[self undoManager] prepareWithInvocationTarget:self.logoXPositionSlider] setDoubleValue:[_logoXPositionSlider previousValue]];
                
            } else if ([sender tag] == 3) {
                [[self undoManager] setActionName:NSLocalizedString(@"undoChangeLogoPosition", nil)];
                [[[self undoManager] prepareWithInvocationTarget:self.logoYPositionSlider] setDoubleValue:[_logoYPositionSlider previousValue]];
            }
        }
    }
}

#pragma mark NSMenuValidation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    // make sure the "Export Selected" entry in Main Menu is
    // only enabled if at least one user-defined background
    // has been selected
    BOOL enableItem = YES;
    
    if ([menuItem tag] == 2000) {
        enableItem = ([[_collectionView selectionIndexesInSection:kMTSectionUserDefined] count] > 0) ? YES : NO;
    }
    
    return enableItem;
}

#pragma mark MTGradientPickerDelegate
- (void)gradientPickerDidChangeColors:(MTGradientPickerView*)view
{
    [self updatePreview:nil];
}

- (void)gradientPicker:(MTGradientPickerView*)view didChangeColor:(NSColor*)oldColor toColor:(NSColor*)newColor atLocation:(CGFloat)location
{
    [[self undoManager] setActionName:NSLocalizedString(@"undoChangeGradientColor", nil)];
    [[[self undoManager] prepareWithInvocationTarget:self] updatePreview:view];
    [[[self undoManager] prepareWithInvocationTarget:self] gradientPicker:view replaceColor:newColor withColor:oldColor atLocation:location];
    
    [_collectionView deselectAll:nil];
    [_collectionView takeSelectionSnaphot];
}

- (void)gradientPicker:(MTGradientPickerView*)view didAddColor:(NSColor*)color atLocation:(CGFloat)location
{
    [[self undoManager] setActionName:NSLocalizedString(@"undoAddGradientColor", nil)];
    [[[self undoManager] prepareWithInvocationTarget:self] updatePreview:view];
    [[[self undoManager] prepareWithInvocationTarget:self] gradientPicker:view removeColor:color atLocation:location];
    
    [_collectionView deselectAll:nil];
    [_collectionView takeSelectionSnaphot];
}

- (void)gradientPicker:(MTGradientPickerView*)view didRemoveColor:(NSColor*)color atLocation:(CGFloat)location
{
    [[self undoManager] setActionName:NSLocalizedString(@"undoRemoveGradientColor", nil)];
    [[[self undoManager] prepareWithInvocationTarget:self] updatePreview:view];
    [[[self undoManager] prepareWithInvocationTarget:self] gradientPicker:view addColor:color atLocation:location];
    
    [_collectionView deselectAll:nil];
    [_collectionView takeSelectionSnaphot];
}

- (void)gradientPicker:(MTGradientPickerView*)view didMoveColor:(NSColor*)color fromLocation:(CGFloat)oldLocation toLocation:(CGFloat)newLocation;
{
    [[self undoManager] setActionName:NSLocalizedString(@"undoMoveGradientColor", nil)];
    [[[self undoManager] prepareWithInvocationTarget:self] updatePreview:view];
    [[[self undoManager] prepareWithInvocationTarget:self] gradientPicker:view changeColorLocation:newLocation toLocation:oldLocation];

    [_collectionView deselectAll:nil];
    [_collectionView takeSelectionSnaphot];
}

#pragma mark NSUndoManager
- (void)gradientPicker:(MTGradientPickerView *)view replaceColor:(NSColor*)oldColor withColor:(NSColor*)newColor atLocation:(CGFloat)location
{
    [[[self undoManager] prepareWithInvocationTarget:self] updatePreview:view];
    [[[self undoManager] prepareWithInvocationTarget:self] gradientPicker:view replaceColor:newColor withColor:oldColor atLocation:location];
    
    [view replaceColorAtLocation:location withColor:newColor];
}

- (void)gradientPicker:(MTGradientPickerView *)view removeColor:(NSColor*)color atLocation:(CGFloat)location
{
    [[[self undoManager] prepareWithInvocationTarget:self] updatePreview:view];
    [[[self undoManager] prepareWithInvocationTarget:self] gradientPicker:view addColor:color atLocation:location];
    
    [view removeColorAtLocation:location];
}

- (void)gradientPicker:(MTGradientPickerView *)view addColor:(NSColor*)color atLocation:(CGFloat)location
{
    [[[self undoManager] prepareWithInvocationTarget:self] updatePreview:view];
    [[[self undoManager] prepareWithInvocationTarget:self] gradientPicker:view removeColor:color atLocation:location];
    
    [view addColor:color atLocation:location];
}

- (void)gradientPicker:(MTGradientPickerView *)view changeColorLocation:(CGFloat)oldLocation toLocation:(CGFloat)newLocation
{
    [[[self undoManager] prepareWithInvocationTarget:self] updatePreview:view];
    [[[self undoManager] prepareWithInvocationTarget:self] gradientPicker:view changeColorLocation:newLocation toLocation:oldLocation];
    
    [view changeColorLocation:oldLocation toLocation:newLocation];
}

- (void)collectionView:(MTCollectionView *)collectionView moveUserDefinedBackgroundsAtIndexes:(NSArray*)fromIndexes toIndexes:(NSArray*)toIndexes
{
    // undo/redo
    // we must revert the changes from the last item we changed to the first one
    [[[self undoManager] prepareWithInvocationTarget:self] collectionView:collectionView
                                      moveUserDefinedBackgroundsAtIndexes:[[toIndexes reverseObjectEnumerator] allObjects]
                                                                toIndexes:[[fromIndexes reverseObjectEnumerator] allObjects]];
    
    if ([fromIndexes count] == [toIndexes count]) {
                
        [[collectionView animator] performBatchUpdates:^{
            
            [fromIndexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSInteger fromIndex = [obj integerValue];
                NSInteger toIndex = [[toIndexes objectAtIndex:idx] integerValue];

                [self->_backgroundCollection moveBackgroundFromIndex:fromIndex toIndex:toIndex inSection:kMTSectionUserDefined];
                [collectionView moveItemAtIndexPath:[NSIndexPath indexPathForItem:fromIndex inSection:kMTSectionUserDefined]
                                        toIndexPath:[NSIndexPath indexPathForItem:toIndex inSection:kMTSectionUserDefined]];
            }];
            
        } completionHandler:^(BOOL finished) {
            
            [self->_backgroundCollection synchronize];
        }];
    }
}

- (void)collectionView:(MTCollectionView *)collectionView didChangeSelection:(NSSet <NSIndexPath*> *)oldSelection toSelection:(NSSet <NSIndexPath*> *)newSelection
{
    [[self undoManager] setActionName:NSLocalizedString(@"undoChangeSelection", nil)];
    [[[self undoManager] prepareWithInvocationTarget:self] collectionView:collectionView didChangeSelection:newSelection toSelection:oldSelection];

    if ([oldSelection count] > 0) {
        [[[self undoManager] prepareWithInvocationTarget:collectionView] selectItemsAtIndexPaths:oldSelection scrollPosition:NSCollectionViewScrollPositionNone];
    } else {
        [[[self undoManager] prepareWithInvocationTarget:self] applyBackgroundDict:[self currentBackgroundDict]];
    }
    
    [[[self undoManager] prepareWithInvocationTarget:collectionView] deselectAll:nil];
    
    if ([newSelection count] == 1) {
        
        NSDictionary *backgroundDict = [_backgroundCollection backgroundAtIndexPath:[[newSelection allObjects] firstObject]];
        [self applyBackgroundDict:backgroundDict];
    }
}

#pragma mark NSCollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(MTCollectionView *)collectionView
{
    return [_backgroundCollection numberOfSections];
}

- (NSInteger)collectionView:(MTCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfItems = 0;
    
    if (![_userDefaults boolForKey:kMTDefaultsPredefinedHide] || section == kMTSectionUserDefined) {
        numberOfItems = [_backgroundCollection numberOfBackgroundsInSection:section];
    }
    
    return numberOfItems;
}

- (NSCollectionViewItem *)collectionView:(MTCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    MTCollectionViewItem *anItem = [collectionView makeItemWithIdentifier:@"MTCollectionViewItem"
                                                             forIndexPath:indexPath];

    NSDictionary *backgroundDict = [_backgroundCollection backgroundAtIndexPath:indexPath];
    MTGradientView *gradientView = [[MTGradientView alloc] initWithDictionary:backgroundDict forFrame:[[anItem imageView] bounds]];
    MTDesktopPicture *desktopPicture = [[MTDesktopPicture alloc] initWithGradientView:gradientView];
    
    NSString *logoName = [backgroundDict valueForKey:kMTDefaultsLogoName];
        
    if (logoName) {
        
        NSArray *filteredArray = [[_logoArrayController arrangedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", kMTDefaultsLogoName, logoName]];
        NSDictionary *logoDict = [filteredArray firstObject];
        NSInteger logoIndex = [[_logoArrayController arrangedObjects] indexOfObject:logoDict];
        
        if (logoIndex != NSNotFound) {
            
            [desktopPicture setLogoName:[backgroundDict valueForKey:kMTDefaultsLogoName]];
            [desktopPicture setLogoImage:[self logoForSelectionIndex:logoIndex]];
            [desktopPicture setLogoSize:[[backgroundDict valueForKey:kMTDefaultsLogoSize] doubleValue]];
            [desktopPicture setLogoPosition:NSMakePoint([[backgroundDict valueForKey:kMTDefaultsLogoXPosition] doubleValue], [[backgroundDict valueForKey:kMTDefaultsLogoYPosition] doubleValue])];
            
        } else {
            
            // display a small caution icon for the missing logo image
            [desktopPicture setLogoImage:[NSImage imageNamed:NSImageNameCaution]];
            [desktopPicture setLogoSize:25];
            [desktopPicture setLogoPosition:NSMakePoint(90, 10)];
        }
    }

    [anItem setImage:[desktopPicture composedImage]
         withTooltip:[backgroundDict valueForKey:kMTDefaultsBackgroundName]
    ];
    
    return anItem;
}

- (NSView *)collectionView:(MTCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSCollectionViewSupplementaryElementKind)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSString *content = nil;
    NSString *identifier = kMTCollectionViewGapItem;

    if ([kind isEqualTo:NSCollectionElementKindSectionHeader] && [_backgroundCollection numberOfBackgroundsInSection:[indexPath section]]) {
        
        identifier = kMTCollectionViewHeader;
        
        switch ([indexPath section]) {
                
            case 0:
                content = (![_userDefaults boolForKey:kMTDefaultsPredefinedHide]) ? NSLocalizedString(@"headerPredefined", nil) : nil;
                break;
                
            case 1:
                content = NSLocalizedString(@"headerUserDefined", nil);
                break;
        }
    }
    
    id view = [collectionView makeSupplementaryViewOfKind:kind withIdentifier:identifier forIndexPath:indexPath];
    
    if (content && [kind isEqualTo:NSCollectionElementKindSectionHeader]) {
        NSTextField *titleTextField = [(MTCollectionViewHeader*)view headerTitleField];
        [titleTextField setStringValue:content];
    }
    
    return view;
}

#pragma mark NSCollectionViewDelegate
- (NSSet<NSIndexPath *> *)collectionView:(MTCollectionView *)collectionView shouldSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    // take a snapshot of our current selection
    if ([[collectionView selectionIndexPaths] count] > 0) { [collectionView takeSelectionSnaphot]; }
    
    // we don't allow multiple selections in section 0. So if
    // only one new item in section 0 has been selected, we
    // deselect all items in the collection view and select
    // just the new item. If items from section 0 and 1 have
    // been selected (e.g. by pressing CMD+A), we filter out
    // all items in section 0 and select just the items in
    // section 1.
    NSSet *selectedInSection = [indexPaths filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"section == %d", kMTSectionPredefined]];
    
    if ([selectedInSection count] == 1) {
        
        [collectionView setLastSelectedIndexPath:nil];
        [collectionView deselectAll:nil];
        
    } else if ([selectedInSection count] > 1) {
        
        indexPaths = [indexPaths filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"section == %d", kMTSectionUserDefined]];
    }
        
    // for items in section 1 we allow multiple selections but
    // only within this section
    if ([indexPaths count] > 0) {
        
        // deselect items in section 0
        NSSet *selectedInSection = [collectionView selectionIndexesInSection:kMTSectionPredefined];
        if ([selectedInSection count] > 0) { [collectionView deselectItemsAtIndexPaths:selectedInSection]; }
        
        NSIndexPath *newSelection = [[indexPaths allObjects] firstObject];
        
        // is the shift key pressed and are there already
        // items in section 1 selected?
        selectedInSection = [collectionView selectionIndexesInSection:kMTSectionUserDefined];
        
        if ([selectedInSection count] > 0 && ([NSEvent modifierFlags] & NSEventModifierFlagShift)) {
            
            NSMutableSet *newIndexPaths = [NSMutableSet set];
            NSInteger startIndex = 0;
            NSInteger endIndex = 0;
            
            // if the new selection is before the previously selected
            // items, we use the first of the new items, otherwise we
            // use the last one
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"item" ascending:YES];
            NSArray<NSIndexPath*> *selectedIndexPaths = [[selectedInSection allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            if ([[[indexPaths allObjects] firstObject] item] < [[selectedIndexPaths firstObject] item] && [[[indexPaths allObjects] lastObject] item] > [[selectedIndexPaths lastObject] item]) {

                startIndex = [[[indexPaths allObjects] firstObject] item];
                endIndex = [[[indexPaths allObjects] lastObject] item];
                
            } else if ([[[indexPaths allObjects] firstObject] item] < [[selectedIndexPaths firstObject] item]) {

                startIndex = [[collectionView lastSelectedIndexPath] item];
                endIndex = [newSelection item];
                
            } else {

                newSelection = [[indexPaths allObjects] lastObject];
                startIndex = [[collectionView lastSelectedIndexPath] item];
                endIndex = [newSelection item];
            }
                        
            // if the newly selected element is before the one
            // selected before, we swap start and end index so
            // we can always count up in our loop
            if (startIndex > endIndex) {
                startIndex += endIndex;
                endIndex = startIndex - endIndex;
                startIndex -= endIndex;
            }
            
            for (NSInteger index = startIndex; index <= endIndex; ++index) {
                NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:kMTSectionUserDefined];
                [newIndexPaths addObject:path];
            }
            
            indexPaths = [NSSet setWithSet:newIndexPaths];
        }
        
        [collectionView setLastSelectedIndexPath:newSelection];
    }
    
    return indexPaths;
}

- (NSSet<NSIndexPath *> *)collectionView:(MTCollectionView *)collectionView shouldDeselectItemsAtIndexPaths:(NSSet<NSIndexPath*> *)indexPaths
{
    // take a snapshot of our current selection
    [collectionView takeSelectionSnaphot];
    
    if ([collectionView lastSelectedIndexPath] != nil) {
        
        NSIndexPath *itemToDeselect = [[indexPaths allObjects] firstObject];
        NSInteger itemSection = [itemToDeselect section];
        
        if (itemSection == kMTSectionUserDefined) {
            
            if ([NSEvent modifierFlags] & NSEventModifierFlagShift) {
                indexPaths = [NSSet set];
                
            } else if ([NSEvent modifierFlags] & NSEventModifierFlagCommand) {

                NSSet *selectedInSection = [collectionView selectionIndexesInSection:kMTSectionUserDefined];
                
                if ([selectedInSection count] > 1) {
                    
                    // get the last selected item before the one
                    // we want to deselect
                    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"item" ascending:YES];
                    NSArray *selectedIndexPaths = [[selectedInSection allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
                    [collectionView setLastSelectedIndexPath:[selectedIndexPaths objectAtIndex:[selectedIndexPaths count] - 2]];

                } else {
                    [collectionView setLastSelectedIndexPath:nil];
                }
                
            } else {
                [collectionView setLastSelectedIndexPath:nil];
            }
            
        } else {
            [collectionView setLastSelectedIndexPath:nil];
        }
    }

    return indexPaths;
}

- (void)collectionView:(MTCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    if ([indexPaths count] == 1) {
        
        // undo/redo
        [self collectionView:collectionView didChangeSelection:[collectionView lastSelection] toSelection:indexPaths];
    }
}

- (BOOL)collectionView:(MTCollectionView *)collectionView canDragItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths withEvent:(NSEvent *)event
{
    NSSet *selectedInSection = [indexPaths filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"section == %d", kMTSectionPredefined]];

    return ([selectedInSection count] > 0) ? NO : YES;
}

- (id<NSPasteboardWriting>)collectionView:(MTCollectionView *)collectionView pasteboardWriterForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UTType *typeIdentifier = [UTType typeWithIdentifier:kMTFileTypeExport];
    NSFilePromiseProvider *promiseProvider = [[MTFilePromiseProvider alloc] initWithFileType:[typeIdentifier identifier] delegate:self];
    NSData *indexPathData = [NSKeyedArchiver archivedDataWithRootObject:indexPath requiringSecureCoding:NO error:nil];
    [promiseProvider setUserInfo:[NSDictionary dictionaryWithObject:indexPathData forKey:kMTFileProviderIndexPathKey]];

    return promiseProvider;
}

- (NSString *)filePromiseProvider:(MTFilePromiseProvider *)filePromiseProvider fileNameForType:(NSString *)fileType
{
    return NSLocalizedString(@"exportFileName", nil);
}

- (void)filePromiseProvider:(MTFilePromiseProvider *)filePromiseProvider writePromiseToURL:(NSURL *)url completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
    NSData *indexPathData = [filePromiseProvider pasteboardPropertyListForType:kMTFileTypeExport];
    
    if (indexPathData) {
        
        NSIndexPath *indexPath = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSIndexPath class] fromData:indexPathData error:nil];
        
        // this is a bit hacky. as we want to write our whole selection into
        // a single export file (and not a file per selected item) we actually
        // just write a file while we process the first item of our selection.
        // for the rest of the selected items, we do nothing.
        NSSet *selectedItems = [_collectionView selectionIndexPaths];
        
        if ([indexPath isEqualTo:[[selectedItems allObjects] firstObject]]) {
            [_backgroundCollection exportBackgroundsAtIndexPaths:selectedItems toURL:url];
        }
    }
    
    completionHandler(nil);
}

- (void)collectionView:(MTCollectionView *)collectionView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    for (NSIndexPath *indexPath in indexPaths) {
        [[[collectionView itemAtIndexPath:indexPath] view] setHidden:NO];
        
        [[NSAnimationContext currentContext] setDuration:.5];
        [[[[collectionView itemAtIndexPath:indexPath] view] animator] setAlphaValue:.5];
    }
}

- (void)collectionView:(MTCollectionView *)collectionView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation
{
    for (NSIndexPath *indexPath in [collectionView selectionIndexPaths]) {
        [[NSAnimationContext currentContext] setDuration:.5];
        [[[[collectionView itemAtIndexPath:indexPath] view] animator] setAlphaValue:1];
    }
}

- (NSDragOperation)collectionView:(MTCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndexPath:(NSIndexPath * _Nonnull __autoreleasing *)proposedDropIndexPath dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    NSDragOperation dragOperation = NSDragOperationNone;

    // drop came from our collection view
    if ([[draggingInfo draggingSource] isEqualTo:collectionView]) {
        
        // we only allow drops in user-defined backgrounds
        // and only between items (not on items)
        if ([*proposedDropIndexPath section] == kMTSectionUserDefined && *proposedDropOperation == NSCollectionViewDropBefore) {
            
            NSMutableIndexSet *allIndexPaths = [[NSMutableIndexSet alloc] init];
            
            for (NSIndexPath *indexPath in [collectionView selectionIndexesInSection:kMTSectionUserDefined]) {
                [allIndexPaths addIndex:[indexPath item]];
            }
            
            // no drop on the original item or a single range
            NSInteger firstRange = [allIndexPaths countOfIndexesInRange:NSMakeRange([allIndexPaths firstIndex], [allIndexPaths count])];
            if (firstRange != [allIndexPaths count] || [allIndexPaths lastIndex] != [*proposedDropIndexPath item] - 1) {
                dragOperation = NSDragOperationMove;
            }
        }
        
    // drop came from outside our collection view
    } else {

        NSDictionary *pasterboardReadingOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey,
                                                   [NSArray arrayWithObject:kMTFileTypeExport], NSPasteboardURLReadingContentsConformToTypesKey,
                                                   nil];
        
        NSArray *acceptedURLs = [[draggingInfo draggingPasteboard] readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
                                                                                 options:pasterboardReadingOptions];
        
        if ([acceptedURLs count] > 0) {
            
            if ([*proposedDropIndexPath section] == kMTSectionUserDefined || [collectionView numberOfItemsInSection:kMTSectionUserDefined] == 0) {
                dragOperation = NSDragOperationCopy;
            }
        }
    }

    return dragOperation;
}

- (BOOL)collectionView:(MTCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo indexPath:(NSIndexPath *)indexPath dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    if ([[draggingInfo draggingSource] isEqualTo:collectionView]) {
        
        // move items within our collection view
        NSMutableArray *moveFromIndexes = [[NSMutableArray alloc] init];
        
        [draggingInfo enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
                                                forView:collectionView
                                                classes:[NSArray arrayWithObject:[NSPasteboardItem class]]
                                          searchOptions:[NSDictionary dictionary]
                                             usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {

            NSPasteboardItem *pasteboardItem = [draggingItem item];
            NSData *indexPathData = [pasteboardItem dataForType:kMTFileTypeExport];

            if (indexPathData) {

                NSIndexPath *oldIndexPath = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSIndexPath class] fromData:indexPathData error:nil];
                if (oldIndexPath && [oldIndexPath section] == kMTSectionUserDefined) {
                    [moveFromIndexes addObject:[NSNumber numberWithInteger:[oldIndexPath item]]];
                }
            }
        }];
        
        __block NSInteger toIndex = [indexPath item];
        NSMutableArray *moveToIndexes = [[NSMutableArray alloc] init];
        NSMutableArray *adjustedMoveFromIndexes = [[NSMutableArray alloc] init];
        
        [moveFromIndexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            NSInteger fromItemIndex = [obj integerValue];
            
            if (fromItemIndex > toIndex) {
                [adjustedMoveFromIndexes addObject:[NSNumber numberWithInteger:fromItemIndex]];
                [moveToIndexes addObject:[NSNumber numberWithInteger:toIndex++]];
            }
        }];
       
        toIndex = [indexPath item] - 1;
        [moveFromIndexes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSInteger fromItemIndex = [obj integerValue];
            
            if (fromItemIndex < toIndex) {
                [adjustedMoveFromIndexes addObject:[NSNumber numberWithInteger:fromItemIndex]];
                [moveToIndexes addObject:[NSNumber numberWithInteger:toIndex--]];
            }
        }];
        
        [[self undoManager] setActionName:NSLocalizedString(@"undoRearrange", nil)];
        [self collectionView:collectionView moveUserDefinedBackgroundsAtIndexes:adjustedMoveFromIndexes toIndexes:moveToIndexes];
    
    } else {
        
        // import files
        [draggingInfo enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
                                                forView:collectionView
                                                classes:[NSArray arrayWithObject:[NSPasteboardItem class]]
                                          searchOptions:[NSDictionary dictionary]
                                             usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {
            
            NSPasteboardItem *pasteboardItem = [draggingItem item];
            NSPasteboardType itemType = [pasteboardItem availableTypeFromArray:[NSArray arrayWithObject:NSPasteboardTypeFileURL]];
            NSString *filePath = [pasteboardItem stringForType:itemType];
            
            if (filePath) {
                
                NSURL *fileURL = [NSURL URLWithString:[pasteboardItem stringForType:itemType]];
                NSDictionary *resourceValues = [fileURL resourceValuesForKeys:[NSArray arrayWithObject:NSURLContentTypeKey] error:nil];
                UTType *contentIdentifier = [resourceValues valueForKey:NSURLContentTypeKey];
                
                if ([contentIdentifier conformsToType:[UTType typeWithIdentifier:kMTFileTypeExport]]) {
                
                    // if there are no user-defined backgrounds we just add the imported
                    // backgrounds, otherwise we insert the backgrounds at the index
                    // the user selected during drag operation
                    if ([indexPath section] == kMTSectionUserDefined) {
                        [self->_backgroundCollection importBackgroundsWithURL:fileURL atIndexPath:indexPath];
                    } else {
                        [self->_backgroundCollection importBackgroundsWithURL:fileURL];
                    }
                }
                
                [self reloadUserDefinedBackgrounds];
            }
        }];
    }

    return YES;
}

#pragma mark NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(MTCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    CGFloat headerViewHeight = (([_userDefaults boolForKey:kMTDefaultsPredefinedHide] && section == 0) || [collectionView numberOfItemsInSection:section] == 0) ? 0 : kMTHeaderViewHeight;
    return NSMakeSize(10000, headerViewHeight);
}

- (NSEdgeInsets)collectionView:(MTCollectionView *)collectionView layout:(NSCollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat topSpace = ([_userDefaults boolForKey:kMTDefaultsPredefinedHide] && section == 0) ? 0 : 10;
    CGFloat bottomSpace = ([_userDefaults boolForKey:kMTDefaultsPredefinedHide] && section == 0) ? 0 : 10;
    
    return NSEdgeInsetsMake(topSpace, 10, bottomSpace, 10);
}


#pragma mark MTCollectionViewDelegate
- (void)collectionView:(MTCollectionView *)collectionView willDeleteItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    [self deleteCollectionViewItem:nil];
}

#pragma mark MTCollectionViewMenuDelegate
- (NSMenu *)collectionView:(MTCollectionView *)collectionView willOpenMenuAtIndexPath:(NSIndexPath *)indexPath
{
    NSMenu *theMenu = nil;
    NSInteger itemSection = [indexPath section];
    
    if (!indexPath || itemSection == kMTSectionPredefined) {
        
        if (![_userDefaults objectIsForcedForKey:kMTDefaultsPredefinedHide]) {
      
            NSString *itemTitle = ([_userDefaults boolForKey:kMTDefaultsPredefinedHide]) ? NSLocalizedString(@"showPredefinedBackgroundsEntry", nil) : NSLocalizedString(@"hidePredefinedBackgroundsEntry", nil);
            theMenu = [[NSMenu alloc] init];
            [theMenu addItemWithTitle:itemTitle
                               action:@selector(showOrHidePredefinedGradients:)
                        keyEquivalent:@""
                ];
            }
            
    } else {
        
        if (![[collectionView itemAtIndexPath:indexPath] isSelected]) {
            [collectionView deselectAll:nil];
            [collectionView selectItemsAtIndexPaths:[NSSet setWithCollectionViewIndexPath:indexPath]
                                     scrollPosition:NSCollectionViewScrollPositionNone
            ];
        }
            
        theMenu = [[NSMenu alloc] init];

        NSInteger selectedItems = [[collectionView selectionIndexPaths] count];
        NSMenuItem *removeItem = [[NSMenuItem alloc] init];
                                  
        if (selectedItems == 1) {
            [removeItem setTitle:NSLocalizedString(@"removeBackgroundEntry", nil)];
        } else if (selectedItems == [_backgroundCollection numberOfBackgroundsInSection:kMTSectionUserDefined]) {
            [removeItem setTitle:NSLocalizedString(@"removeAllBackgroundsEntry", nil)];
        } else {
            [removeItem setTitle:NSLocalizedString(@"removeMultipleBackgroundsEntry", nil)];
        }
                                  
        [removeItem setAction:@selector(deleteCollectionViewItem:)];
        [removeItem setKeyEquivalent:@""];
        [theMenu addItem:removeItem];
        
        if ([_backgroundCollection numberOfBackgroundsInSection:kMTSectionUserDefined] > 1 && [_backgroundCollection numberOfBackgroundsInSection:kMTSectionUserDefined] != selectedItems) {
            
            NSMenuItem *removeAll = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"removeAllBackgroundsEntry", nil)
                                                               action:@selector(deleteCollectionViewItem:)
                                                        keyEquivalent:@""];
            [removeAll setAlternate:YES];
            [removeAll setKeyEquivalentModifierMask:NSEventModifierFlagOption];
            [theMenu addItem:removeAll];
        }
    }
    
    return theMenu;
}

@end
