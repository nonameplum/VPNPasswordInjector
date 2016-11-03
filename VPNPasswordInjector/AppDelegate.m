//
//  AppDelegate.m
//  StatusBarApp
//
//  Created by Łukasz Śliwiński on 02/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import "AppDelegate.h"
#import "FocusObserver.h"
#import "PopoverContentViewController.h"

@interface AppDelegate () <PopoverContentViewControllerDelegate, NSMenuDelegate>

@property (strong) FocusObserver *focusObserver;
@property (strong) NSMenu *statusMenu;
@property (strong) NSStatusItem *statusBarItem;
@property (strong) NSPopover *popover;
@property (strong, nullable) id popoverEventMonitor;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self complainIfNeeded];
    
    self.focusObserver = [[FocusObserver alloc] init];
    [self.focusObserver startObservingApplicationsActivation];
    
    [self setupStatusItem];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark - Accessibility

- (void) complainIfNeeded {
    BOOL enabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)@{(__bridge id)kAXTrustedCheckOptionPrompt: @(YES)});
    
    if (!enabled) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Enable Accessibility First";
        alert.informativeText = @"Find the little popup right behind this one, click \"Open System Preferences\" and enable VPNPasswordInjector. Then launch VPNPasswordInjector again.";
        [alert runModal];
        
        BOOL enabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)@{(__bridge id)kAXTrustedCheckOptionPrompt: @(YES)});
        if (!enabled) {
            [NSApp terminate:self];
        }
    }
}

# pragma mark - Status Bar Menu

- (void)setupStatusItem {
    self.statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusBarItem setHighlightMode:YES];
    self.statusBarItem.highlightMode = YES;
    self.statusBarItem.title = @"⤽";
    self.statusBarItem.button.font = [NSFont systemFontOfSize:20];
    
    self.statusMenu = [[NSMenu alloc] init];
    self.statusMenu.delegate = self;
    self.statusBarItem.menu = self.statusMenu;
    
    NSMenuItem *configurationMenuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences"
                                                                   action:@selector(preferencesMenuActionHandler)
                                                            keyEquivalent:@""];
    configurationMenuItem.target = self;
    
    [self.statusMenu addItem:configurationMenuItem];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quick"
                                                          action:@selector(quitMenuActionHandler)
                                                   keyEquivalent:@""];
    quitMenuItem.target = self;
    
    [self.statusMenu addItem:quitMenuItem];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(darkModeChanged:)
                                                            name:@"AppleInterfaceThemeChangedNotification"
                                                          object:nil];
}

- (void)preferencesMenuActionHandler {
    [self openPopover];
}

- (void)quitMenuActionHandler {
    [NSApp terminate:self];
}

- (void)darkModeChanged:(NSNotification *)notification {
    [self.statusBarItem.button setNeedsDisplay];
    [self.statusBarItem.button displayIfNeeded];
}

# pragma mark - Popover

- (void)openPopover {
    if (!self.popover) {
        self.popover = [[NSPopover alloc] init];
        PopoverContentViewController *popoverContentViewController = [[PopoverContentViewController alloc] init];
        popoverContentViewController.delegate = self;
        self.popover.contentViewController = popoverContentViewController;
    }
    
    [self.popover showRelativeToRect:NSZeroRect ofView:self.statusBarItem.button preferredEdge:NSMinYEdge];
    
    self.popoverEventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseUp handler:^(NSEvent * _Nonnull event) {
        [self closePopover];
    }];
}

- (void)closePopover {
    [self.popover close];
    
    if (!self.popoverEventMonitor) {
        [NSEvent removeMonitor:self.popoverEventMonitor];
    }
}

# pragma mark - NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu {
    [self closePopover];
}

# pragma mark - Popover Delegate

- (void)saveButtonClicked {
    [self closePopover];
}

@end
