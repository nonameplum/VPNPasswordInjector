//
//  PopoverContentViewController.h
//  VPNPasswordInjector
//
//  Created by Łukasz Śliwiński on 02/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PopoverContentViewControllerDelegate <NSObject>

- (void)saveButtonClicked;

@end

@interface PopoverContentViewController : NSViewController

@property (weak) id<PopoverContentViewControllerDelegate> delegate;

@end
