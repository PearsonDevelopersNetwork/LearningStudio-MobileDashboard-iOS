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

// Controls display of details for items from Grades tab
class GradesDetailsViewController: UITableViewController {
    // table cell identifiers
    let gradeDetailsCellIdentifier = "gradeDetailsItemCell"
    
    // reference to item for display
    var courseId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        // detail identifiers can be released if not displayed
        if !(self.isViewLoaded()  && self.view.window != nil) {
            courseId = nil
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 5 // Average, Earned, Possible, Extra Credit, Letter
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(gradeDetailsCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        var gradeToDate = LearningStudio.api.userData!.gradesToDate![courseId!]!
        
        var key = ""
        var value = ""
        
        // extract main (key) and detail (value) labels for row
        switch indexPath.row {
        case 0:
            key = "Average"
            value = String(gradeToDate["average"] as! Int)
        case 1:
            key = "Earned"
            value = String(gradeToDate["earned"] as! Int)
        case 2:
            key = "Possible"
            value = String(gradeToDate["possible"] as! Int)
        case 3:
            key = "Extra Credit"
            value = String(gradeToDate["extraCredit"] as! Int)
        case 4:
            key = "Letter"
            var letterGrade = gradeToDate["letterGrade"] as! [String:String]
            value = letterGrade["letterGrade"]!
        default:
            key = ""
        }
        
        cell.textLabel!.text = key
        cell.detailTextLabel?.text = value
        
        return cell
    }
    
}
