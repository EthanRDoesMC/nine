#include "headers.h"

#import <substrate.h>
#import "TCBackgroundViewController.h"
#import <Cephei/HBPreferences.h>

static BOOL alwaysBlurEnabled;
static NSNumber *blurValueHistory;
static NSNumber *blurValueGeneral;
static NSNumber *darkeningValueHistory;
static NSNumber *darkeningValueGeneral;
static UIColor *lockscreenColoring;
static UIColor *notificationCenterColoring;


//----------------------------------------------------------------

extern BOOL isOnLockscreen();
extern BOOL isUILocked();

@implementation TCBackgroundViewController {
    SBUIController *_sbCont;
    //WALockscreenWidgetViewController *_widgetController;
}

- (instancetype) init{
    if(self = [super init]){
        CGRect frame = UIScreen.mainScreen.bounds;
        frame.size.width = (frame.size.width > frame.size.height) ? frame.size.width : frame.size.height;
        frame.size.height = (frame.size.width > frame.size.height) ? frame.size.width : frame.size.height;
        //frame.size.height += 200;

        CGRect screenFrame = UIScreen.mainScreen.bounds;

        _sbCont = [objc_getClass("SBUIController") sharedInstance];
        
        
        // load preferences
        HBPreferences *settings = [[HBPreferences alloc] initWithIdentifier:@"com.thecasle.nineprefs"];
        HBPreferences *colorSettings = [[HBPreferences alloc] initWithIdentifier:@"com.thecasle.nineprefs.color"];
        [settings registerDefaults:@{
                                     @"enableAlwaysBlur": @NO,
                                     @"historyBlurValue": @17,
                                     @"generalBlurValue": @12,
                                     @"generalDarkeningValue":@1,
                                     @"historyDarkeningValue":@4,
                                     }];
        alwaysBlurEnabled = [settings boolForKey:@"enableAlwaysBlur"];
        blurValueHistory = [NSNumber numberWithDouble: [settings doubleForKey:@"historyBlurValue"]];
        blurValueGeneral = [NSNumber numberWithDouble: [settings doubleForKey:@"generalBlurValue"]];
        darkeningValueHistory = [NSNumber numberWithDouble: ([settings doubleForKey:@"historyDarkeningValue"] * .1)];
        darkeningValueGeneral = [NSNumber numberWithDouble: ([settings doubleForKey:@"generalDarkeningValue"] * .1)];
        lockscreenColoring = [UIColor colorFromHexString:[colorSettings objectForKey:@"lockscreenColors"]];
        notificationCenterColoring = [UIColor colorFromHexString:[colorSettings objectForKey:@"notificationCenterColors"]];
        
        //NSLog(@"nine_TWEAK | %@", [colorSettings objectForKey:@"lockscreenColors"]);
        //NSLog(@"nine_TWEAK | %@", lockscreenColoring);
        lockscreenColoring = [UIColor blackColor];
        notificationCenterColoring = [UIColor blackColor];
        
        if(!self.view){
            self.view = [[UIView alloc] initWithFrame:screenFrame];
        }
        
        // Hold both of the blurs
        if(!self.blurView){
            self.blurView = [[UIView alloc] initWithFrame:frame];
            [self.view addSubview:self.blurView];
            //self.blurView.frameY = -200;
        }
        
        // NC blur
        if(!self.blurHistoryEffectView){
            /*
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithBlurRadius:blurValueHistory.doubleValue];
            self.blurHistoryEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            
            self.blurHistoryEffectView.backgroundColor = [notificationCenterColoring colorWithAlphaComponent:darkeningValueHistory.doubleValue];
            */
            
            _UIBackdropViewSettings *settings = [[objc_getClass("_UIBackdropViewSettingsNineHistory") alloc] init];
            self.blurHistoryEffectView = [[objc_getClass("BSUIBackdropView") alloc] initWithSettings:settings];
            self.blurHistoryEffectView.frame = frame;
            self.blurHistoryEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.blurView addSubview:self.blurHistoryEffectView];
        }
        
        // lockscreen blur
        if(!self.blurEffectView){
            
            /*
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithBlurRadius:blurValueGeneral.doubleValue];
            self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            self.blurEffectView.backgroundColor = [lockscreenColoring colorWithAlphaComponent:darkeningValueGeneral.doubleValue];
             */
            
            self.blurEffectView.frame = frame;
            self.blurEffectView.alpha = 0;
            _UIBackdropViewSettings *settings = [[objc_getClass("_UIBackdropViewSettingsNineLock") alloc] init];
            self.blurEffectView = [[objc_getClass("BSUIBackdropView") alloc] initWithSettings:settings];
            self.blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:self.blurEffectView];
        }
        
    }
    return self;
}


+ (instancetype)sharedInstance {
    static TCBackgroundViewController *sharedInstance = nil;
    static dispatch_once_t onceToken; // onceToken = 0
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TCBackgroundViewController alloc] init];
    });
    
    return sharedInstance;
}

-(void) updateSceenShot: (BOOL)content isRevealed: (BOOL)isHistoryRevealed {
    
    // forces the blur always enabled
    if(alwaysBlurEnabled || !isOnLockscreen()){
        content = YES;
    }
    if(isOnLockscreen()){
        isHistoryRevealed = NO;
    }

    if(content == YES && isHistoryRevealed == YES){
        // Notification Center
        /*[UIView animateWithDuration:.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{self.blurHistoryEffectView.alpha = 1;}
                         completion:nil];*/
        self.blurHistoryEffectView.alpha = 1;
        self.blurEffectView.alpha = 0;
    } else if(content == YES && isHistoryRevealed == NO){
        // lockscreen
        [UIView animateWithDuration:.7
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{self.blurEffectView.alpha = 1;}
                         completion:nil];
        [UIView animateWithDuration:.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{self.blurHistoryEffectView.alpha = 0;}
                         completion:nil];
    } else {
        [UIView animateWithDuration:.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{self.blurHistoryEffectView.alpha = 0;}
                         completion:nil];
        [UIView animateWithDuration:.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{self.blurEffectView.alpha = 0;}
                         completion:nil];
    }
}
@end
