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

// Controls the login view
class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        passwordTextField.secureTextEntry=true
        loginMessageLabel.numberOfLines=0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func pressedLogin(sender: UIButton) {
        
        sender.enabled=false // prevent double taps
        
        // trim username and password
        var usernameText = usernameTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        var passwordText = passwordTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        // check if credentials provided
        if usernameText == "" || passwordText == "" {
            loginMessageLabel.text = "Enter credentials before login"
            sender.enabled=true
            return
        }
        
        // set credentials
        LearningStudio.api.setCredentials(username: usernameText, password: passwordText)
        // verify user with credentials
        LearningStudio.api.getMe({ (error) -> Void in
            
            dispatch_async(dispatch_get_main_queue()) {
                if error == nil {
                    LearningStudio.api.saveCredentials()
                    (self.presentingViewController as! MainViewController).showLoading()
                    self.loginMessageLabel.text = ""
                    self.passwordTextField.text = ""
                    self.usernameTextField.text = ""
                }
                else {
                    self.loginMessageLabel.text = "Try again!"
                }
            
                sender.enabled=true
            }
        })
    }
}
