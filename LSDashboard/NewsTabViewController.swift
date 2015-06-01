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

// Controls the news tab
class NewsTabViewController: UITableViewController {
    // table cell identifiers
    let newsCellIdentifier = "newsItemCell"
    let noneCellIdentifier = "noneNewsItemCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Listen for changes to announcements in order to reload table when data is available.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshData:", name: "RefreshAnnouncements", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        // clear any badge that was visible
        self.navigationController?.tabBarItem.badgeValue = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let courses = LearningStudio.api.userData!.courses {
            return courses.count
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let courses = LearningStudio.api.userData!.courses {
            if let announcements = LearningStudio.api.userData!.announcements {
                // display when news retrieved for all courses
                if announcements.count == courses.count {
                    let course = courses[section]
                    let courseId = String(course["id"] as! Int)
                    var courseAnnouncements = announcements[courseId]
                    
                    // Don't leave a section blank if data is loaded
                    if courseAnnouncements!.count == 0 {
                        return 1 // No results == None cell
                    }
                    
                    return courseAnnouncements!.count
                }
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
        
        var announcements = LearningStudio.api.userData!.announcements![courseId]!
        
        // Show the None cell if no news exist for this course
        if announcements.count == 0 {
            var cell = tableView.dequeueReusableCellWithIdentifier(noneCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
            return cell // None
        }
        
        var cell = tableView.dequeueReusableCellWithIdentifier(newsCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        var announcement = announcements[indexPath.row]
 
        cell.textLabel!.text = announcement["subject"] as? String
        
        var originalTime = announcement["startDisplayDate"] as! String
        var postedTime = LearningStudio.api.convertCourseDate(courseId, dateString: originalTime)
        var dateEnd = advance(postedTime.rangeOfString("T")!.startIndex,-1)
        postedTime = postedTime[postedTime.startIndex...dateEnd]
        cell.detailTextLabel?.text = postedTime
        
        // Highlight the row if it didn't exist during the last load.
        if LearningStudio.api.lastLoadTime != nil && originalTime.compare(LearningStudio.api.lastLoadTime!) == NSComparisonResult.OrderedDescending {
            cell.backgroundColor = UIColor.yellowColor()
        }
        else {
            cell.backgroundColor = UIColor.whiteColor() // default?
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            var course = LearningStudio.api.userData!.courses![indexPath.section]
            let courseId = String(course["id"] as! Int)
            var announcementId = String(LearningStudio.api.userData!.announcements![courseId]![indexPath.row]["id"] as! Int)
            LearningStudio.api.userData!.announcements![courseId]!.removeAtIndex(indexPath.row)
            
            // A None cell is being used when data is missing, so use reloadData on last row in section
            if LearningStudio.api.userData!.announcements![courseId]!.count == 0 {
                tableView.reloadData() // this just updates the display
            }
            else { // this way of updating the display requires the row count to change
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            
            LearningStudio.api.markAnnouncementAsRead(courseId, announcementId: announcementId, callback:{ (error) -> Void in
                if error != nil {
                    println("Failed to mark announcement \(announcementId) for course \(courseId) as read")
                }
            })
        }
    }
    
    // Reload the table data when RefreshAnnouncements notification is received
    func refreshData(notification: NSNotification) {
        tableView.reloadData()
    }
    
    // Pass course id and announcement index to detail controller to support details display
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
        let detailController = segue.destinationViewController as! NewsDetailsViewController
        
        var course = LearningStudio.api.userData!.courses![indexPath!.section]
        
        detailController.title = course["title"] as? String
        detailController.courseId = String(course["id"] as! Int)
        detailController.itemIndex = indexPath!.row
    }
    
}