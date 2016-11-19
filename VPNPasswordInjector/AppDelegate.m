//
//  AppDelegate.m
//  VPNPasswordInjector
//
//  Created by Łukasz Śliwiński on 02/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "VPNPasswordInjector.h"
#import "PopoverContentViewController.h"

static CGFloat const ANIMATION_DURATION = 0.5;

@interface AppDelegate () <VPNPasswordInjectorDelegate, PopoverContentViewControllerDelegate, NSMenuDelegate>

@property (strong) VPNPasswordInjector *vpnPasswordInjector;
@property (strong) NSMenu *statusMenu;
@property (strong) NSStatusItem *statusBarItem;
@property (strong) NSPopover *popover;
@property (strong, nullable) id popoverEventMonitor;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self complainIfNeeded];
    
    self.vpnPasswordInjector = [[VPNPasswordInjector alloc] init];
    [self.vpnPasswordInjector startWatchingToFillVPNPassword];
    
    [self setupStatusItem];
    
    self.vpnPasswordInjector.delegate = self;
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
        alert.informativeText = @"Find the little popup right behind this one, click \"Open System Preferences\" and enable VPNPasswordInjector.";
        [alert runModal];
        
        BOOL enabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)@{(__bridge id)kAXTrustedCheckOptionPrompt: @(YES)});
        if (!enabled) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Enable Accessibility First";
            alert.informativeText = @"You did not enabled accessibility for the VPNPasswordInjector. Application will be closed";
            [NSApp terminate:self];
        }
    }
}

# pragma mark - Status Bar Menu

- (void)setupStatusItem {
    self.statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBarItem.highlightMode = YES;
    self.statusBarItem.title = @"⤽";
    self.statusBarItem.button.font = [NSFont systemFontOfSize:20];
    
    self.statusMenu = [[NSMenu alloc] init];
    self.statusMenu.delegate = self;
    self.statusBarItem.menu = self.statusMenu;
    self.statusBarItem.button.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSMenuItem *configurationMenuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences"
                                                                   action:@selector(preferencesMenuActionHandler)
                                                            keyEquivalent:@"p"];
    configurationMenuItem.target = self;
    
    [self.statusMenu addItem:configurationMenuItem];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quick VPNPasswordInjector"
                                                          action:@selector(quitMenuActionHandler)
                                                   keyEquivalent:@"q"];
    quitMenuItem.target = self;
    
    [self.statusMenu addItem:quitMenuItem];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(darkModeChanged:)
                                                            name:@"AppleInterfaceThemeChangedNotification"
                                                          object:nil];
    
    self.statusBarItem.button.wantsLayer = YES;
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

# pragma mark - VPNPasswordInjectorDelegate

- (void)startedFillPassword {
    if ([self.statusBarItem.button.layer animationForKey:@"spinAnimation"]) {
        [self finishedFillPassword];
    } else {
        [self.statusBarItem.button.layer removeAllAnimations];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.fromValue = @0.0;
        animation.toValue = @(M_PI * 2.0);
        animation.duration = ANIMATION_DURATION;
        animation.repeatCount = INFINITY;
        
        [self.statusBarItem.button.layer addAnimation:animation forKey:@"spinAnimation"];
    }
}

- (void)finishedFillPassword {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGFloat currentAngle = [[self.statusBarItem.button valueForKeyPath:@"layer.presentationLayer.transform.rotation.z"] floatValue];
        if (currentAngle < 0) {
            currentAngle = M_PI * 2 + currentAngle;
        }
        
        [self.statusBarItem.button.layer removeAllAnimations];
        
        CGFloat neededTimeToCompleteAnimation = ((M_PI * 2.0) - currentAngle) * ANIMATION_DURATION / (M_PI * 2);
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.fromValue = [NSNumber numberWithFloat:currentAngle];
        animation.toValue = @(M_PI * 2.0);
        animation.duration = neededTimeToCompleteAnimation;
        animation.repeatCount = 1;
        [self.statusBarItem.button.layer addAnimation:animation forKey:@"spinAnimationCompletion"];
    });
}

# pragma mark - Popover Delegate

- (void)saveButtonClicked {
    [self closePopover];
}

# pragma mark - NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu {
    [self closePopover];
}

@end
