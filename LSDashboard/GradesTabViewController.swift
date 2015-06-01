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

// Controls Grades Tab
class GradesTabViewController: UITableViewController {
    // table cell identifiers
    let gradeCellIdentifier = "gradeItemCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for changes to GradesToDate in order to reload table when data is available.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshData:", name: "RefreshGradesToDate", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        // clear any badge that was visible
        self.navigationController?.tabBarItem.badgeValue = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let courses = LearningStudio.api.userData?.courses {
            // display grades only if courses exist
            if courses.count == 0 {
                return 0
            }
    
            var gradesToDate = LearningStudio.api.userData!.gradesToDate
            
            // display when all grades are available
            if gradesToDate != nil && gradesToDate!.count == courses.count {
                return gradesToDate!.count
            }
        }
        
        return 0
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(gradeCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        var course = LearningStudio.api.userData!.courses![indexPath.row]
        let courseId = String(course["id"] as! Int)
        
        cell.textLabel!.text = course["title"] as? String
        
        // Display letter grade as detail
        var gradeToDate = LearningStudio.api.userData!.gradesToDate![courseId]!
        var letterGrade = gradeToDate["letterGrade"] as! [String:String]
        cell.detailTextLabel?.text = letterGrade["letterGrade"]
        
        return cell
    }
    
    // Reload the table data when RefreshGradesToDate notification is received
    func refreshData(notification: NSNotification) {
        tableView.reloadData()
    }
    
    // Pass course id to detail controller to support details display
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  
        let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
        let detailController = segue.destinationViewController as! GradesDetailsViewController
        
        var course = LearningStudio.api.userData!.courses![indexPath!.section]
        
        detailController.title = course["title"] as? String
        detailController.courseId = String(course["id"] as! Int)
    }
    
}
