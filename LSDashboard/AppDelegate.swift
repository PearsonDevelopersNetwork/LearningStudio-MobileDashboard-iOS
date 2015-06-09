/*
* LearningStudio Mobile Dashboard for iOS
*
* Need Help or Have Questions?
* Please use the PDN Developer Community at https://community.pdn.pearson.com
*
* @category   LearningStudio Sample Application - Mobile
* @author     Wes Williams <wes.williams@pearson.com>
* @author     Pearson Developer Services Team <apisupport@pearson.com>
* @copyright  2015 Pearson Education, Inc.
* @license    http://www.apache.org/licenses/LICENSE-2.0  Apache 2.0
* @version    1.0
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* Portions of this work are reproduced from work created and
* shared by Apple and used according to the terms described in
* the License. Apple is not otherwise affiliated with the
* development of this work.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        
        // We need permission to update the icon's badge
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Badge, categories: nil))
        
        // Let background fetch fire as often as it can. We'll throttlle the API usage during the call
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        var badgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber
        if badgeNumber > 0 {
            if LearningStudio.api.restoreCredentials() {
                (window?.rootViewController as! MainViewController).showLoading()
            }
            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        
        // called by simulator despite comment in applicationDidEnterBackground
        LearningStudio.api.removeUserDataArchive()
    }



    func application(application: UIApplication,
        performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
            
            // going to check for new activity if login is possible
            if LearningStudio.api.restoreCredentials() {
                // going to make 3 calls, and will respond when all have completed
                // Should have plenty of time, so no need to ask for extra time
                let dataParts = 3 // happenings, events, announcements
                var partsSearched = 0
                var partsFound = 0
                
                // last time we checked is stored as a user default
                // this is set during first login and everytime data is refreshed
                var lastActivityTime = NSUserDefaults.standardUserDefaults().objectForKey(LearningStudio.api.defaultLastActivityTimeKey) as? String
                
                // this current time will replace the lastActivityTime if this succeeds
                var dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = LearningStudio.api.normalDateFormat
                dateFormatter.timeZone = NSTimeZone(name: LearningStudio.api.defaultTimeZone)
                var now = NSDate()
                let thisActivityTime = dateFormatter.stringFromDate(now)
                
                // just exit if lastActivityDate is missing or not as expected
                if lastActivityTime == nil || dateFormatter.dateFromString(lastActivityTime!) == nil {
                    NSUserDefaults.standardUserDefaults().setValue(thisActivityTime, forKey: LearningStudio.api.defaultLastActivityTimeKey)
                    completionHandler(UIBackgroundFetchResult.NoData)
                    return
                }
                
                // There's no need to check more than once an hour.
                // Otherwise, background fetch might be unnecessarily querying
                var hourAgoTime = dateFormatter.stringFromDate(now.dateByAddingTimeInterval(-1 * 60 * 60))
                if hourAgoTime.compare(lastActivityTime!) == NSComparisonResult.OrderedAscending {
                    completionHandler(UIBackgroundFetchResult.NoData)
                    return
                }
                
                // can't respond until all are done...
                // and doing them in parallel should be faster than chaining them
                // this is the logic for the time when all of them are complete
                var whenDone =  { () -> Void in
                    NSUserDefaults.standardUserDefaults().setValue(thisActivityTime, forKey: LearningStudio.api.defaultLastActivityTimeKey)
                    if  partsFound > 0 {
                        UIApplication.sharedApplication().applicationIconBadgeNumber += partsFound
                        completionHandler(UIBackgroundFetchResult.NewData)
                    }
                    else {
                        completionHandler(UIBackgroundFetchResult.NoData)
                    }
                }

                // what's been done
                LearningStudio.api.getHappeningsSince(lastActivityTime!, callback: { (data, error) -> Void in

                    if data != nil {
                        var happenings = data as! [AnyObject]
                        
                        if happenings.count > 0  {
                            partsFound += happenings.count
                        }
                    }

                    // check if this is the last one
                    if ++partsSearched ==  dataParts {
                       whenDone()
                    }
                })
                // what's coming due
                LearningStudio.api.getEventsSince(lastActivityTime!, callback: { (data, error) -> Void in
                    
                    if data != nil {
                        var activities = data as! [AnyObject]
                        
                        if activities.count > 0  {
                            partsFound += activities.count
                        }
                    }
                    
                    // check if this is the last one
                    if ++partsSearched ==  dataParts {
                        whenDone()
                    }
                })
                // what's been announced
                LearningStudio.api.getAnnouncementsSince(lastActivityTime!, callback: { (data, error) -> Void in
                    
                    if data != nil {
                        var announcements = data as! [AnyObject]
                        
                        if announcements.count > 0  {
                            partsFound += announcements.count
                        }
                    }
                    
                    // check if this is the last one
                    if ++partsSearched ==  dataParts {
                        whenDone()
                    }
                })

            }
            else {
                completionHandler(UIBackgroundFetchResult.NoData);
            }
            
    }
}

