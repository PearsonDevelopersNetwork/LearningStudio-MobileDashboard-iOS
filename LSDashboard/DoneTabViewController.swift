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

// Controls the Done tab
class DoneTabViewController: UITableViewController {
    // table cell identifiers
    let doneCellIdentifier = "doneItemCell"
    let noneCellIdentifier = "noneDoneItemCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Listen for changes to happenings in order to reload table when data is available.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshData:", name: "RefreshHappenings", object: nil)
    }
    
    deinit { // cleanup
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        // Show section for each course
        if let courses = LearningStudio.api.userData!.courses {
            return courses.count
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let courses = LearningStudio.api.userData!.courses {
            // count happenings for course
            if let allHappenings = LearningStudio.api.userData!.happenings {
                let course = courses[section]
                let courseId = String(course["id"] as! Int)
                var happenings = allHappenings[courseId]
                
                // Don't leave a section blank if data is loaded
                if happenings == nil || happenings!.count == 0 {
                    return 1 // No results == None cell
                }
            
                return happenings!.count
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
        
        var happenings = LearningStudio.api.userData!.happenings![courseId]
        
        // Show the None cell if no happenings exist for this course
        if happenings == nil || happenings!.count == 0 {
            var cell = tableView.dequeueReusableCellWithIdentifier(noneCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
            return cell // None
        }
        
        var cell = tableView.dequeueReusableCellWithIdentifier(doneCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        var happening = happenings![indexPath.row]
        var happeningObject = happening["object"] as! [String:AnyObject]
        
        if happeningObject["title"] != nil {
            cell.textLabel!.text = happeningObject["title"] as? String
        }
        else {
            var happeningTarget = happening["target"] as! [String:AnyObject]
            cell.textLabel!.text = happeningTarget["title"] as? String
        }
        
        var originalTime = happening["postedTime"] as! String
        var postedTime = LearningStudio.api.convertCourseDate(courseId, dateString: originalTime)
        var dateEnd = advance(postedTime.rangeOfString("T")!.startIndex,-1)
        postedTime = postedTime[postedTime.startIndex...dateEnd]
        cell.detailTextLabel?.text = postedTime
        
        // Highlight the row if it didn't exist during the last load.
        if LearningStudio.api.lastLoadTime != nil && originalTime.compare(LearningStudio.api.lastLoadTime!) == NSComparisonResult.OrderedDescending {
            cell.backgroundColor = UIColor.yellowColor()
        }
        else {
            cell.backgroundColor = UIColor.whiteColor() // default color
        }
        
        return cell
    }
    
    
    // Reload the table data when RefreshHappenings notification is received
    func refreshData(notification: NSNotification) {
        tableView.reloadData()
    }
    
    // Pass course id and happening index to detail controller to support details display
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
        let detailController = segue.destinationViewController as! DoneDetailsViewController
        
        var course = LearningStudio.api.userData!.courses![indexPath!.section]
        
        detailController.title = course["title"] as? String
        detailController.courseId = String(course["id"] as! Int)
        detailController.itemIndex = indexPath!.row
    }

}
