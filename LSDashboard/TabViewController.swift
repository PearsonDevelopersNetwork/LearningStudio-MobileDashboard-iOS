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

// Controls the tabs view presented after login
class TabViewController: UITabBarController {
    let dueTabIndex = 0
    let doneTabIndex = 1
    let newsTabIndex = 2
    let gradesTabIndex = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        // Monitor for new activity
        // Differences are discovered during data refershes, and these events are fired
        // Need to add indicator tabs, so the new activity doesn't go unnoticed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "diffUpcomingEvents:", name: "DiffUpcomingEvents", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "diffHappenings:", name: "DiffHappenings", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "diffAnnouncements:", name: "DiffAnnouncements", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "diffGrades:", name: "DiffGrades", object: nil)

    }
    
    deinit { // cleanup
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewWillAppear(animated: Bool) {
        self.selectedIndex = dueTabIndex
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Event Observers

    // Responds to new upcoming events by adding badge to the Due tab
    func diffUpcomingEvents(notification: NSNotification) {
        self.viewControllers![dueTabIndex].tabBarItem!.badgeValue = String(notification.userInfo!["count"] as! Int)
    }
    
    // Responds to new happenings by adding badge to the Done tab
    func diffHappenings(notification: NSNotification) {
        self.viewControllers![doneTabIndex].tabBarItem!.badgeValue = String(notification.userInfo!["count"] as! Int)
    }
    
    // Responds to new announcements by adding badge to News tab
    func diffAnnouncements(notification: NSNotification) {
        self.viewControllers![newsTabIndex].tabBarItem!.badgeValue = String(notification.userInfo!["count"] as! Int)
    }
    
    // Responds to new grades by adding badge to Grades tab.
    // These events are not fired right now
    func diffGrades(notification: NSNotification) {
        self.viewControllers![gradesTabIndex].tabBarItem!.badgeValue = String(notification.userInfo!["count"] as! Int)
    }
    
}
