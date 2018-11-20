#import "AppDelegate.h"
#import "Constants.h"
#import "Hyperbation-Swift.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self registerDefaultsFromSettingsBundle];
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    BOOL sendUsageData = [[NSUserDefaults standardUserDefaults] boolForKey:useAnalyticsKey];
    [[AnalyticsManager sharedInstance] initializeWithSendUsageData:sendUsageData];
    
    return YES;
}

- (void)registerDefaultsFromSettingsBundle {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = settings[@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = prefSpecification[@"Key"];
        if(key) {
            defaultsToRegister[key] = prefSpecification[@"DefaultValue"];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:secondsInBackgroundKey] == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:sessionInBackgroundDefaultTimeInSeconds forKey:secondsInBackgroundKey];
    }
    
    if ([[NSUserDefaults standardUserDefaults] floatForKey:distantAnchorsDistanceKey] == 0.0) {
        [[NSUserDefaults standardUserDefaults] setFloat:distantAnchorsDefaultDistanceInMeters forKey:distantAnchorsDistanceKey];
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    //Be ready to open URLs like "hyperbation://ios-viewer.webxrexperiments.com/viewer.html"
    if ([[url scheme] isEqualToString:@"hyperbation"]) {
        // Extract the scheme part of the URL
        NSString* urlString = [[url absoluteString] substringFromIndex:14];
        urlString = [NSString stringWithFormat:@"http://%@", urlString];
        
        DDLogDebug(@"AA Zoo opened with URL: %@", urlString);
        
        [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:REQUESTED_URL_KEY];

        return YES;
    }
    return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[AnalyticsManager sharedInstance] sendEventWithCategory:EventCategoryAction method:EventMethodForeground object:EventObjectApp];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[AnalyticsManager sharedInstance] sendEventWithCategory:EventCategoryAction method:EventMethodBackground object:EventObjectApp];
}

@end
