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
import Foundation

// Controls the Due Tab
class DueTabViewController: UITableViewController {
    // table cell identifiers
    let dueCellIdentifier = "dueItemCell"
    let noneCellIdentifier = "noneDueItemCell"
    
    // dates to use for navigation
    var todayDate : String?
    var tomorrowDate : String?
    var nextDayDate : String?
    var lastDayDate : String?
    
    // date currently being viewed
    var viewDateStart : String?
    var viewDateEnd : String?
    var viewDateIndexes : [String:[Int]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // This due tab is presented on launch, so data might not be loaded at first.
        // Listen for changes to upcoming events in order to reload table when data is available.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshData:", name: "RefreshUpcomingEvents", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var date = NSDate() // today
        
        // Navigation by due data is possible. Lets establish the dates to use
        if todayDate == nil || todayDate! != dateFormatter.stringFromDate(date) {
            todayDate = dateFormatter.stringFromDate(date)      // today
            date = date.dateByAddingTimeInterval(24 * 60 * 60)  // tomorrow
            tomorrowDate = dateFormatter.stringFromDate(date)
            date = date.dateByAddingTimeInterval(24 * 60 * 60)  // next day
            nextDayDate = dateFormatter.stringFromDate(date)
            date = date.dateByAddingTimeInterval(7300 * 24 * 60 * 60) //  20 years out - never loaded this far out
            lastDayDate = dateFormatter.stringFromDate(date)
        
            // keep track of whether today, tomorrow, or later is showing
            viewDateStart = todayDate
            viewDateEnd = tomorrowDate
            self.navigationItem.leftBarButtonItem?.enabled = false
            self.navigationItem.rightBarButtonItem?.enabled = true
            self.navigationItem.title = "Due Today"
        }
        
        // clear any badge that was visible
        self.navigationController?.tabBarItem.badgeValue = nil
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        // Release all the state variables when screen is not in use
        if !(self.isViewLoaded()  && self.view.window != nil) {
            viewDateIndexes = [:]
            todayDate = nil
            tomorrowDate = nil
            nextDayDate = nil
            lastDayDate = nil
            viewDateStart = nil
            viewDateEnd  = nil
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Show section for each course
        if let courses = LearningStudio.api.userData!.courses {
            return courses.count
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let courses = LearningStudio.api.userData!.courses {
            let course = courses[section]
            let courseId = String(course["id"] as! Int)
            var upcomingEvents = LearningStudio.api.userData?.upcomingEvents?[courseId]
            
            // count events for course during the current time period
            if upcomingEvents != nil {
                var newIndexes: [Int] = []
                // iterate events to compare dates
                for (i, upcomingEvent) in enumerate(upcomingEvents!) {
                    var when = upcomingEvent["when"] as! [String:String]
                    var eventTime = LearningStudio.api.convertCourseDate(courseId, dateString: when["time"]!, humanize: true)
                    
                    // decide whether course is applicable to the time period on display
                    if viewDateStart!.compare(eventTime) == NSComparisonResult.OrderedAscending &&
                        viewDateEnd!.compare(eventTime) == NSComparisonResult.OrderedDescending {
                        newIndexes.append(i)
                    }
                }
                // keep track of event indexes by course for the current time period
                viewDateIndexes[courseId] = newIndexes
                
                // Don't leave a section blank if data is loaded
                if viewDateIndexes[courseId]!.count == 0 {
                    return 1 // No results == None cell
                }
                
                return viewDateIndexes[courseId]!.count
            }
            else {
                // Don't leave a section blank if data is loaded
                return 1 // No results == None cell
            }
        }
   
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection: Int) -> String? {
        var course = LearningStudio.api.userData!.courses![titleForHeaderInSection]
        return course["title"] as? String
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        var course = LearningStudio.api.userData!.courses![indexPath.section]
        let courseId = String(course["id"] as! Int)
        var upcomingEvents = LearningStudio.api.userData?.upcomingEvents?[courseId]
        
        // Show the None cell if no events exist for this course during the current time period
        if upcomingEvents == nil || viewDateIndexes[courseId] == nil || viewDateIndexes[courseId]!.count == 0 {
            var cell = tableView.dequeueReusableCellWithIdentifier(noneCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
            return cell // None
        }
        
        var cell = tableView.dequeueReusableCellWithIdentifier(dueCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        var upcomingEvent = upcomingEvents![viewDateIndexes[courseId]![indexPath.row]]
        
        cell.textLabel!.text = upcomingEvent["title"] as? String
        
        var when = upcomingEvent["when"] as! [String:String]
        var originalTime = when["time"]!
        var eventTime = LearningStudio.api.convertCourseDate(courseId, dateString: originalTime)
        var dateEnd = advance(eventTime.rangeOfString("T")!.startIndex,-1)
        eventTime = eventTime[eventTime.startIndex...dateEnd]
        cell.detailTextLabel?.text = eventTime
        
        var schedule = upcomingEvent["schedule"] as! [String:AnyObject]
        var accessSchedule = schedule["accessSchedule"] as! [String:AnyObject]
        var startDateTime = accessSchedule["startDateTime"] as? String
        var accessBefore = accessSchedule["canAccessBeforeStartDateTime"] as! Bool
        
        // Highlight the row if it didn't exist during the last load.
        // Must have just become available. Might not occur if future time window is small
        if startDateTime != nil && LearningStudio.api.lastLoadTime != nil &&
            startDateTime!.compare(LearningStudio.api.lastLoadTime!) == NSComparisonResult.OrderedDescending &&
            accessBefore == false {
            cell.backgroundColor = UIColor.yellowColor()
        }
        else {
            cell.backgroundColor = UIColor.whiteColor() // default color
        }
        
        return cell
    }
    

    // Reload the table data when RefreshUpcomingEvent notification is received
    func refreshData(notification: NSNotification) {
        tableView.reloadData()
    }
    
    // Pass course id and event index to detail controller to support display
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
        let detailController = segue.destinationViewController as! DueDetailsViewController
        
        var course = LearningStudio.api.userData!.courses![indexPath!.section]
        var courseId = String(course["id"] as! Int)
        
        detailController.title = course["title"] as? String
        detailController.courseId = courseId
        detailController.itemIndex = viewDateIndexes[courseId]![indexPath!.row]
    }

    // MARK: - Past and Future time navigation methods
    
    // move the time window backwards when left nav button pressed
    @IBAction func pressedPreviousDay(sender: UIBarButtonItem) {
        if viewDateStart! ==  tomorrowDate! {
            viewDateStart = todayDate!
            viewDateEnd = tomorrowDate!
            self.navigationItem.leftBarButtonItem?.enabled = false
            self.navigationItem.title = "Due Today"
        }
        else if viewDateStart! ==  nextDayDate! {
            viewDateStart = tomorrowDate!
            viewDateEnd = nextDayDate!
            self.navigationItem.rightBarButtonItem?.enabled = true
            self.navigationItem.title = "Due Tomorrow"
        }
        
        tableView.reloadData()
    }
    
    // move the time window forwards when right nav button pressed
    @IBAction func pressedNextDay(sender: UIBarButtonItem) {
        if viewDateStart! ==  todayDate! {
            viewDateStart = tomorrowDate!
            viewDateEnd = nextDayDate!
            self.navigationItem.leftBarButtonItem?.enabled = true
            self.navigationItem.title = "Due Tomorrow"
        }
        else if viewDateStart! ==  tomorrowDate! {
            viewDateStart = nextDayDate!
            viewDateEnd = lastDayDate!
            self.navigationItem.rightBarButtonItem?.enabled = false
            self.navigationItem.title = "Due Later"
        }
        
        tableView.reloadData()
    }
}
