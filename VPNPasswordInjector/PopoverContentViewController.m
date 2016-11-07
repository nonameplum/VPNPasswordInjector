//
//  PopoverContentViewController.m
//  StatusBarApp
//
//  Created by Łukasz Śliwiński on 02/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import "PopoverContentViewController.h"

NSString *const VPN_PASSWORD_KEYPATH = @"vpnPasswordKeyPath";

@interface PopoverContentViewController () <NSTextFieldDelegate>

@property (weak) IBOutlet NSTextField *vpnPasswordTextField;

@end

@implementation PopoverContentViewController

# pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizePasswordTextField:self.vpnPasswordTextField];
    
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:VPN_PASSWORD_KEYPATH];
    self.vpnPasswordTextField.stringValue = password ? password : @"";
}

- (void)viewWillAppear {
    [super viewWillAppear];
    
    BOOL isDark = [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"]  isEqual: @"Dark"];
    
    self.vpnPasswordTextField.layer.backgroundColor = isDark ? [NSColor colorWithWhite:0.5 alpha:0.5].CGColor : [NSColor colorWithWhite:0.95 alpha:1.0].CGColor;
    self.vpnPasswordTextField.layer.borderColor = isDark ? [[NSColor colorWithWhite:0.5 alpha:0.55] CGColor] : [[NSColor colorWithWhite:0.9 alpha:1.0] CGColor];
}

# pragma mark - Customization

- (void)customizePasswordTextField:(NSTextField *)textField {
    textField.drawsBackground = NO;
    textField.wantsLayer = YES;
    textField.bezeled = NO;
    textField.focusRingType = NSFocusRingTypeNone;
    textField.delegate = self;
    textField.layer.borderWidth = 1;
    textField.layer.cornerRadius = 3;
}

# pragma mark - Actions

- (IBAction)saveButtonAction:(NSButton *)sender {
    [[NSUserDefaults standardUserDefaults] setValue:self.vpnPasswordTextField.stringValue forKeyPath:VPN_PASSWORD_KEYPATH];
    
    [self.delegate saveButtonClicked];
    
}

# pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        [self saveButtonAction:nil];
        return YES;
    }
    
    return NO;
}

@end
