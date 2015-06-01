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

// Controls display of options from the settings tab
class SettingOptionsViewController: UITableViewController {
    // table cell identifiers
    let optionCellIdentifier = "optionsItemCell"
    
    var options : [[String:String]]? // options to display
    var optionKey: String? // key for storing the selected options
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options!.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var option = options![indexPath.row]
        
        var cell = tableView.dequeueReusableCellWithIdentifier(optionCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        cell.textLabel?.text = option["title"]
        cell.detailTextLabel?.text = option["detail"]
            
        return cell
   
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // store the settings option
        var option = options![indexPath.row]
        NSUserDefaults.standardUserDefaults().setValue(option["value"], forKey: optionKey!)
        
        // return to previous screen
        self.navigationController?.popViewControllerAnimated(true)
        
        // alert of the settings option change
        NSNotificationCenter.defaultCenter().postNotificationName("RefreshOptions", object:self)
    }
}
