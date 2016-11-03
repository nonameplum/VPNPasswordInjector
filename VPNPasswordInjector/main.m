//
//  main.m
//  VPNPasswordInjector
//
//  Created by Łukasz Śliwiński on 03/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [app setDelegate:delegate];
    [app finishLaunching];
    [app run];
}
