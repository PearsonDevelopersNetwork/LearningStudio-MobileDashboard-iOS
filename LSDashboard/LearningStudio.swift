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

import Foundation
import UIKit

// Provides access to API and loaded data
class LearningStudio {
    
    // Singleton allow access to variables from anywhere in the app.
    class var api: LearningStudio {
        struct Static {
            static var token: dispatch_once_t = 0
            static var instance: LearningStudio!
        }
        dispatch_once(&Static.token) {
            Static.instance = LearningStudio()
        }
        return Static.instance
    }
    
    // MARK: - Constants
    
    // reusable api related constants
    let apiDomain = "https://api.learningstudio.com"
    let defaultTimeZone = "UTC"
    let shortDateFormat = "MM/dd/yyyy"
    let normalDateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    let longDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    let dataArchiveFilename = "UserDataArchive.plist"
    
    // user preferences defaults
    let pastViewDaysDefault = 3
    let futureViewDaysDefault = 7
    
    // user defaults keys
    let defaultUsernameKey = "username"     // String - username for last login
    let defaultIgnoredCoursesKey = "coursesToIgnore"    // [String:Bool] Indicator of whether to display courses
    let defaultCourseStartRangeKey = "courseStartRange" // String - "{date},{date}" for course start dates
    let defaultCourseEndRangeKey = "courseEndRange" // String - "{date},{date}" for course end dates
    let defaultFutureViewDaysKey = "futureViewDaysPreference" // String - # of days to query into future
    let defaultPastViewDaysKey = "pastViewDaysPreference" // String - # of days to query into past
    let defaultLastLoadTimeKey = "lastLoadTime" // String - date of last load in normal format
    let defaultLastActivityTimeKey = "lastActivityTime" // String - date of last activity found in normal format

    // error related constants
    let errorDomainName = "LearningStudio"  // Custom error domain name
    let errorNoTermCode = 122   // Failed due to no current terms
    let errorNoTokenCode = 123  // Failed due to missing token. Should never happen
    let errorNoCoursesCode = 124 // Failed due no courses when they were required
    
    // MARK: - Public Variables
    
    // handle to view for login/logout
    var mainView: MainViewController!
    
    // user data for app to share
    var lastLoadTime: String?   // date to compare for detecting new data
    var userData: UserData? { // exposed user data that reloads if archived
        get {
            if userDataInternal == nil && isUserDataArchived {
                loadUserDataArchive()
            }
            
            return userDataInternal
        }
        
        set(data) {
            userDataInternal = data
        }
    }
    
    // MARK: - private variables
    
    // user credentials for session management
    private var username: String = ""
    private var password: String = ""
    
    // token data for session management
    private var tokens: AnyObject?
    private var tokenExpireDate: NSDate?
    
    // internal user data variables
    private var userDataInternal: UserData? // data source for userData
    private var isUserDataArchived: Bool = false    // indicator of archived data
    private var startSearchDate: String?    // start date for data search
    private var endSearchDate: String?  // end date for data search
    
    // config for api access
    private let config: Dictionary<String,String>   // configuration for accessing api
    
    // keychain services
    private let keychainWrapper = KeychainItemWrapper(identifier: "com.pearson.developer.LSDashboard", accessGroup: nil)
    
    // MARK: - Constructors
    
    init() {
        // load config for API access
        if let lsPropsPath = NSBundle.mainBundle().pathForResource("LearningStudio", ofType: "plist") {
            config = NSDictionary(contentsOfFile: lsPropsPath) as! Dictionary<String, String>
        }
        else {
            config = [:]
        }
    }
    
    // MARK: - Credential Management Methods
    
    // allows credentials to be changed on login screen
    func setCredentials(username newUsername: String, password newPassword: String) {
        self.username = newUsername
        self.password = newPassword
    }
    
    // save user credentials for future app launches
    private func saveCredentials() {
        NSUserDefaults.standardUserDefaults().setValue(username, forKey: defaultUsernameKey)
        keychainWrapper.setObject(password, forKey:kSecValueData)
    }
    
    // checks for saved credentials. restores them if possible
    func restoreCredentials() -> Bool {
        
        // credentials can be reloaded if tokens missing
        if tokens == nil {
            if let savedUsername = NSUserDefaults.standardUserDefaults().objectForKey(defaultUsernameKey) as? String{
                // keychain password is stored as v_Data by wrapper
                if let savedPassword = keychainWrapper.objectForKey("v_Data") as? String {
                    username = savedUsername
                    password = savedPassword
                }
            }
        }
        
        // just want to know if they are set
        return username != "" && password != ""
    }
    
    // clears credentials and all associated data
    private func clearCredentials() {
        // clear all variables
        username = ""
        password = ""
        tokens = nil
        tokenExpireDate=nil
        userData=nil
        lastLoadTime=nil
        startSearchDate=nil
        endSearchDate = nil
        
        // clear saved credentials and data archive
        NSUserDefaults.standardUserDefaults().removeObjectForKey(defaultUsernameKey)
        removeUserDataArchive()
        keychainWrapper.resetKeychainItem()
    }
    
    // MARK: - Generic Request Methods
    
    // retrieves token for API calls
    private func authenticate(callback:(accessToken: String?, error: NSError?) -> Void) {
        
        // a valid token might already exist
        if tokens != nil {
            if let accessToken = tokens!["access_token"] as? String {
                if(tokenExpireDate!.compare(NSDate()) == NSComparisonResult.OrderedDescending) {
                    callback(accessToken:accessToken, error:nil)
                    return
                }
            }
        }
        
        // If not, we'll need to get one
        var session = NSURLSession.sharedSession()
        
        // Only the app's id and client string are required
        // This only allows OAuth2 with the user's credentials
        // OAuth1 is not appropriate for a mobile app.
        let appId = config["app_id"]!
        let clientString = config["client_string"]!
        
        // post to the token url
        let tokenUrl = NSURL(string: apiDomain + "/token")
        var tokenRequest = NSMutableURLRequest(URL: tokenUrl!)
        tokenRequest.HTTPMethod = "POST"
        
        // with the app id, username, and password
        var fullUsername = config["client_string"]! + "\\" + username
        let postString = "grant_type=password&client_id=\(appId)&username=\(fullUsername)&password=\(password)"
        tokenRequest.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        
        var requestDate = NSDate()
        let tokenTask = session.dataTaskWithRequest(tokenRequest, completionHandler: { (tokenData, tokenResponse, tokenError) -> Void in
            
            // return on error
            if tokenError != nil {
                callback(accessToken:nil, error:tokenError)
                return
            }
            
            // parse the json
            var tokenErr: NSError?
            var tokenJson = NSJSONSerialization.JSONObjectWithData(tokenData, options: NSJSONReadingOptions.MutableContainers, error: &tokenErr) as! NSDictionary
            if tokenErr != nil {
                // return if there is an error parsing JSON
                callback(accessToken:nil, error: tokenErr)
                return
            }
            
            // extract the token
            if let accessToken = tokenJson["access_token"] as? String {
                // store the token and expriation date
                var expiresIn = tokenJson["expires_in"] as! Double
                self.tokenExpireDate = requestDate.dateByAddingTimeInterval(expiresIn)
                self.tokens=tokenJson // save the token for later
                callback(accessToken:accessToken, error:nil)
            }
            else {
                // return if the token is missing
                callback(accessToken:nil, error: NSError(domain: self.errorDomainName, code: self.errorNoTokenCode, userInfo: nil))
            }
        })
        tokenTask.resume()
    }
    
    // Asynchronously performs REST operation with JSON input and output
    private func doJsonOperation(httpMethod: String, path: String, data: AnyObject?, callback: (data:AnyObject?, error:NSError?) -> Void) {
        authenticate({ (accessToken, error) -> Void in
            
            // return if token not obtained
            if error != nil {
                callback(data:nil, error:error)
                return
            }
            
            // otherwise, perform the operation
            var session = NSURLSession.sharedSession()
 
            let dataUrl = NSURL(string: self.apiDomain + path)
            var dataRequest = NSMutableURLRequest(URL: dataUrl!)
            dataRequest.HTTPMethod = httpMethod
            // include request body if applicable
            if data != nil {
                if let jsonData = NSJSONSerialization.dataWithJSONObject(data!, options: nil, error: nil) {
                    if let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding) {
                        dataRequest.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding)
                    }
                }
            }
            // include token in header
            dataRequest.addValue("Access_Token access_token=\(accessToken!)", forHTTPHeaderField: "X-Authorization")
        
            // perform the operation
            let dataTask = session.dataTaskWithRequest(dataRequest, completionHandler: { (data, response, error) -> Void in
                
                // return error when present
                if error != nil {
                    callback(data:nil, error:error)
                    return
                }

                // return data if available
                if data != nil {
                    // parse the json
                    var err: NSError?
                    var json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err)
                    if err != nil {
                        callback(data:nil, error:err)
                        return
                    }
                    
                    callback(data: json, error: nil)
                }
                else {
                    callback(data: nil, error: nil)
                }
            })
            dataTask.resume()
        })
    }
    
    // Asynchronously performs GET operation that returns JSON
    private func getJson(path: String, callback: (data:AnyObject?, error:NSError?) -> Void) {
        doJsonOperation("GET",path: path,data: nil,callback: callback)
    }
    
    // Asynchronously performs PUT operation that returns JSON
    private func putJson(path: String, json: AnyObject, callback: (data:AnyObject?, error:NSError?) -> Void) {
        doJsonOperation("PUT",path: path,data: json,callback: callback)
    }
    
    // MARK: - API Route Wrappers
    
    // Retrieves user info and inits other data in userData container. Populates me attribute
    func getMe(callback: (error:NSError?) -> Void) {
        getJson("/me", callback: { (data, error) -> Void in
  
            if error == nil {
                self.userData = UserData() // init user data
                self.userData!.me = data!["me"] as? [String:AnyObject] // store user data
            }
            
            callback(error: error)
        })
    }
    
    // Retrieves courses in active terms. Populates courses and hiddenCourses attributes
    func getCourses(callback: (error:NSError?) -> Void) {
        
        getJson("/me/terms", callback: { (data, error) -> Void in
            if error == nil {
                
                var dateFormatter = NSDateFormatter()
                dateFormatter.timeZone = NSTimeZone(name: self.defaultTimeZone)
                dateFormatter.dateFormat = self.normalDateFormat
                var currentDate = dateFormatter.stringFromDate(NSDate())
                
                // find the earliest start and latest end
                var startDate: String?
                var endDate: String?

                var terms = data!["terms"] as! [[String:AnyObject]]
                for term in terms {
                    
                    var termStartDate = term["startDateTime"] as! String
                    var termEndDate = term["endDateTime"] as! String
                    // skip terms without startDate < currentDate < endDate
                    if currentDate.compare(termStartDate) == NSComparisonResult.OrderedAscending ||
                        currentDate.compare(termEndDate) == NSComparisonResult.OrderedDescending {
                        continue // not a current term
                    }
                
                    // keep the earliest start date
                    if startDate == nil {
                        startDate = termStartDate
                    }
                    else if startDate!.compare(termStartDate) == NSComparisonResult.OrderedDescending {
                        startDate = termStartDate
                    }
                    
                    // keep the latest end date
                    if endDate == nil {
                        endDate = termEndDate
                    }
                    else if endDate!.compare(termEndDate) == NSComparisonResult.OrderedAscending {
                        endDate = termEndDate
                    }
                }
                
                // return error if no terms apply to the current date
                if startDate == nil || endDate == nil {
                    callback(error: NSError(domain: self.errorDomainName, code: self.errorNoTermCode, userInfo: nil))
                    return
                }
                
                // convert to dates
                var start = dateFormatter.dateFromString(startDate!)
                var end = dateFormatter.dateFromString(endDate!)
                var current = dateFormatter.dateFromString(currentDate)
                
                // convert the date format
                dateFormatter.dateFormat = self.shortDateFormat
                startDate = dateFormatter.stringFromDate(start!)
                endDate = dateFormatter.stringFromDate(end!)
                currentDate = dateFormatter.stringFromDate(current!)
                
                // format the date ranges
                var startRange = "\(startDate!),\(currentDate)"
                var endRange = "\(currentDate),\(endDate!)"
                
                self.getJson("/me/courses?expand=course&startDatesBetween=\(startRange)&endDatesBetween=\(endRange)", callback: { (data, error) -> Void in

                    if error == nil {
                         // retrieve courses that user chose to ignore
                         var ignoredCourses = NSUserDefaults.standardUserDefaults().objectForKey(self.defaultIgnoredCoursesKey) as? [String:Bool]
                        
                        // remove unnecessary nesting in data
                        var newCourses: [[String:AnyObject]] = []
                        var hiddenCourses: [[String:AnyObject]] = []
                        var courses = data!["courses"] as! [AnyObject]
                        for course in courses {
                            var courseLinks = course["links"] as! [[String:AnyObject]]
                            var courseLinksCourse = courseLinks[0]["course"] as! [String:AnyObject]
                            
                            // check whether user chose to hide this course
                            var courseId = String(courseLinksCourse["id"] as! Int)
                            if ignoredCourses != nil && ignoredCourses![courseId] != nil && ignoredCourses![courseId] == true {
                                hiddenCourses.append(courseLinksCourse)
                                continue // skip this course
                            }
                            
                            newCourses.append(courseLinksCourse)
                        }
                        
                        // Store course start and end ranges for later
                        NSUserDefaults.standardUserDefaults().setObject(startRange, forKey: self.defaultCourseStartRangeKey)
                        NSUserDefaults.standardUserDefaults().setObject(endRange, forKey: self.defaultCourseEndRangeKey)
                        
                        // store course data
                        self.userData!.courses = newCourses
                        self.userData!.hiddenCourses = hiddenCourses
                    }

                    callback(error: error)
                })
            }
            else {
                callback(error: error)
            }
        })
    }
    
    // Retrieves activity from What's Happening Feed. Populates happenings attribute.
    func getHappenings(callback: (error:NSError?) -> Void) {
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = shortDateFormat
        var startDate = dateFormatter.dateFromString(startSearchDate!)
        dateFormatter.timeZone = NSTimeZone(name: defaultTimeZone) // doing this after date conversion keeps device TZ offset
        dateFormatter.dateFormat = normalDateFormat
        var happeningStartSearchDate = dateFormatter.stringFromDate(startDate!)
        
        getJson("/me/whatshappeningfeed?v=2&after=\(happeningStartSearchDate)", callback: { (data, error) -> Void in

            
            if error == nil {
                // unnest data
                var activityStream = data!["activityStream"] as! [String:AnyObject]
                var happenings = activityStream["items"] as! [[String:AnyObject]]
                
                // sort activity by course
                var newHappenings: [String: [[String:AnyObject]]] = [:]
                for happening in happenings {
                    
                    var target = happening["target"] as! [String:AnyObject]
                    var courseId = target["courseId"]! as! String
                    
                    if newHappenings[courseId] != nil {
                        newHappenings[courseId]!.append(happening)
                    }
                    else {
                        newHappenings[courseId] = [happening]
                    }
                    
                }

                // store happening data
                self.userData!.happenings = newHappenings
            }
            
            callback(error: error)
        })
    }
    
    // Retrieves events from Upcoming Events. Populates upcomingEvent attribute.
    func getUpcomingEvents(callback: (error:NSError?) -> Void) {
        getJson("/me/upcomingEvents?expand=schedule&until=\(endSearchDate!)", callback: { (data, error) -> Void in
            
            if error == nil {
                // sort events by course
                var events = data!["upcomingEvents"] as! [[String:AnyObject]]
                
                // filter out unwanted events and unnest schedule data
                var newEvents: [String: [[String:AnyObject]]] = [:]
                for eventIn in events {
                    var event = eventIn // allows schedule to be added later
                    
                    var category = event["category"] as! String
                    
                    if category != "due" { // only include due events
                        continue
                    }
                    
                    var courseId: String?
                    // hack to to get course id without another call... not recommended...
                    // also, extracting schedule while we're at it...
                    var links = event["links"] as! [[String:AnyObject]]
                    for link in links {
                        let rel = link["rel"] as! String
                        if rel == "https://api.learningstudio.com/rel/course" {
                            let href = link["href"] as! String
                            let hrefParts = href.componentsSeparatedByString("/") // split by slashes
                            courseId = hrefParts[hrefParts.count-1] // courseId is the last part
                            // quit if schedule already found
                            if event["schedule"] != nil {
                                break
                            }
                        }
                        else if rel == "https://api.learningstudio.com/rel/schedule" {
                            event["schedule"] = link["schedule"]
                            // quit if course is already found
                            if courseId != nil {
                                break
                            }
                        }
                    }
                    
                    if newEvents[courseId!] != nil {
                        newEvents[courseId!]!.append(event)
                    }
                    else {
                        newEvents[courseId!] = [event]
                    }
                    
                }
                
                // save upcoming events data
                self.userData!.upcomingEvents = newEvents
            }
            
            callback(error: error)
        })
    }
    
    // Retrieve grades to date by course id. Populates gradesToDate attribute with courseId as key.
    private func getGradeToDate(courseId: String, callback: (error:NSError?) -> Void) {
        getJson("/me/courses/\(courseId)/courseGradeToDate", callback: { (data, error) -> Void in
            
            if error == nil {
                // sort grades by course
                var gradeToDate = data!["courseGradeToDate"] as! [String:AnyObject]
                
                // just in case this method was called outside getGradesToDate
                if self.userData!.gradesToDate == nil {
                   self.userData!.gradesToDate = [:]
                }
                
                // save grade to date for course
                self.userData!.gradesToDate![courseId] = gradeToDate
            }
            
            callback(error: error)
        })
    }
    
    // Retrieve grades to date for all active courses. Populates gradesToDate for each courseId.
    func getGradesToDate(callback: (error:NSError?) -> Void) {
        if userData != nil && userData!.courses != nil {
            userData!.gradesToDate =  [:]
            
            // return if no active courses exist
            if userData!.courses!.count == 0 {
                callback(error:nil)
                return
            }
            
            // retreive grades for active courses
            for course in userData!.courses! {
                var courseId = String(course["id"] as! Int)
                getGradeToDate(courseId, callback: { (error:NSError?) -> Void in
                    // only proceed if error has not occurred
                    if self.userData!.gradesToDate != nil {
                        if error != nil { // abort on error
                            self.userData!.gradesToDate = nil // indicate error occurred
                            callback(error: error)
                        }
                        else if self.userData!.gradesToDate!.count == self.userData!.courses!.count { // return when all done
                            callback(error: error)
                        }
                    }
                })
            }
        }
        else { // error if courses not loaded
            callback(error: NSError(domain: errorDomainName, code: errorNoCoursesCode, userInfo: nil))
        }
    }
    
    // Retrieve announcements by course id. Populates announcements attribute with courseId as key.
    private func getAnnouncements(courseId: String, callback: (error:NSError?) -> Void) {
        
        // TODO - remove this block when the bug mentioned below is fixed...
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = shortDateFormat
        var announcementDate = dateFormatter.dateFromString(startSearchDate!)
        dateFormatter.timeZone = NSTimeZone(name: defaultTimeZone) // doing this after date conversion keeps device TZ offset
        dateFormatter.dateFormat = normalDateFormat
        let startAnnouncementDate = dateFormatter.stringFromDate(announcementDate!)
        
        
        // TODO - There's a bug with "since" in the API.
        //        It doesn't include today's announcements
        //        Restore the below line when it starts working again
        //getJson("/me/courses/\(courseId)/announcements?excludeInactive=true&since=\(startSearchDate!)", callback: { (data, error) -> Void in
        getJson("/me/courses/\(courseId)/announcements?excludeInactive=true", callback: { (data, error) -> Void in
            
            if error == nil {
                // sort announcements by course
                var announcements = data!["announcements"] as! [[String:AnyObject]]
                
                var unreadAnnouncements: [[String:AnyObject]] = []
                for announcement in announcements {
                    var readStatus = announcement["readstatus"] as! Bool
                    if  readStatus == false {
                        
                        // TODO - remove this block when the above mentioned bug is fixed
                        var startDateTime = announcement["startDisplayDate"] as? String
                        if startDateTime == nil ||
                            startDateTime!.compare(startAnnouncementDate) != NSComparisonResult.OrderedDescending {
                                continue
                        }

                        unreadAnnouncements.append(announcement)
                    }
                }
                
                // just in case this method was not called from getAnnouncements without courseId
                if self.userData!.announcements == nil {
                    self.userData!.announcements = [:]
                }
                
                // save announcements for course
                self.userData!.announcements![courseId] = unreadAnnouncements
            }
            
            callback(error: error)
        })
    }
    
    // Retrieve announcements for all active courses. Populates announcements for each courseId.
    func getAnnouncements(callback: (error:NSError?) -> Void) {
        if userData != nil && userData!.courses != nil {
            userData!.announcements =  [:]
            
            if userData!.courses!.count == 0 {
                callback(error:nil)
                return
            }
            
            for course in userData!.courses! {
                var courseId = String(course["id"] as! Int)
                getAnnouncements(courseId, callback: { (error:NSError?) -> Void in
                    // only proceed if error has not occurred
                    if self.userData!.announcements != nil {
                        if error != nil { // abort on error
                            self.userData!.announcements = nil // indicate error
                            callback(error: error)
                        }
                        else if self.userData!.announcements!.count == self.userData!.courses!.count { // return when all complete
                            callback(error: error)
                        }
                    }
                })
            }
        }
        else {
            callback(error: NSError(domain: errorDomainName, code: errorNoCoursesCode, userInfo: nil))
        }
    }
    
    // Updates read status of announcements
    func markAnnouncementAsRead(courseId: String, announcementId: String, callback: (error:NSError?) -> Void) {
        var data = ["announcementReadStatus" : ["markedAsRead" : true] ]
        putJson("/me/courses/\(courseId)/announcements/\(announcementId)/readstatus", json: data, callback: { (data, error) -> Void in
            callback(error: error)
        })
    }
    
    // Retrieve timezone of course. Populates timeZones for provided courseId.
    func getTimeZone(courseId: String, callback: (error:NSError?) -> Void) {
        getJson("/me/courses/\(courseId)/timeZone", callback: { (data, error) -> Void in
            
            if error == nil {
                // sort timezones by course
                var timeZone = data!["timeZone"] as! [String:AnyObject]
                
                if self.userData!.timeZones == nil {
                    self.userData!.timeZones = [:]
                }
                
                self.userData!.timeZones![courseId] = timeZone
            }
            
            callback(error: error)
        })
    }
    
    // Retrieve timezones for all active courses. Populates timeZones for each courseId
    func getTimeZones(callback: (error:NSError?) -> Void) {
        if userData != nil && userData!.courses != nil {
            userData!.timeZones =  [:]
            
            if userData!.courses!.count == 0 {
                callback(error:nil)
                return
            }
            
            for course in userData!.courses! {
                var courseId = String(course["id"] as! Int)
                getTimeZone(courseId, callback: { (error:NSError?) -> Void in
                    // only proceed if error has not occurred
                    if self.userData!.timeZones != nil {
                        if error != nil { // abort on error
                            self.userData!.timeZones = nil // indicate error
                            callback(error: error)
                        }
                        else if self.userData!.timeZones!.count == self.userData!.courses!.count { // return when all complete
                            callback(error: error)
                        }
                    }
                })
            }
        }
        else {
            callback(error: NSError(domain: errorDomainName, code: errorNoCoursesCode, userInfo: nil))
        }
        
    }
    
    // MARK: - Background Fetch Queries
    
    // Intended for background fetch use only, so not persisting the data like other methods

    // Retrieve new Upcoming Events
    func getEventsSince(startDate: String, callback: (data: AnyObject?, error:NSError?) -> Void) {
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = normalDateFormat
        dateFormatter.timeZone = NSTimeZone(name: defaultTimeZone)
        
        // convert date format
        var date = dateFormatter.dateFromString(startDate)
        dateFormatter.dateFormat = shortDateFormat
        let sinceDate = dateFormatter.stringFromDate(date!)
        
        // determine future preferences
        var futureDays = NSUserDefaults.standardUserDefaults().doubleForKey(defaultFutureViewDaysKey)
        if futureDays <= 0 { // default if missing
            futureDays = Double(futureViewDaysDefault)
        }
        futureDays = futureDays + 1 // looks are exclusine on end date
        
        // determine end date based on future preferences
        var endDate = date!.dateByAddingTimeInterval(futureDays * 24 * 60 * 60) // # days ahead
        var futureDate = dateFormatter.stringFromDate(endDate)
        
        // need a end date with time to filter future events by time later
        dateFormatter.dateFormat = normalDateFormat
        var futureDateTime = dateFormatter.stringFromDate(endDate)
        
        getJson("/me/upcomingEvents?expand=schedule&since=\(sinceDate)&until=\(futureDate)", callback: { (data, error) -> Void in
            
            if error == nil {
                var ignoredCourses = NSUserDefaults.standardUserDefaults().objectForKey(self.defaultIgnoredCoursesKey) as? [String:Bool]
                
                var events = data!["upcomingEvents"] as! [[String:AnyObject]]
                
                var newEvents: [[String:AnyObject]] = []
                for eventIn in events {
                    var event = eventIn // allows schedule to be added later
                    
                    var category = event["category"] as! String
                    
                    if category != "access_start" { // show start only for our purposes
                        continue
                    }
                    
                    var courseId: String?
                    // hack to to get course id without another call... not recommended...
                    // also, extracting schedule while we're at it...
                    var links = event["links"] as! [[String:AnyObject]]
                    for link in links {
                        let rel = link["rel"] as! String
                        if rel == "https://api.learningstudio.com/rel/course" {
                            let href = link["href"] as! String
                            let hrefParts = href.componentsSeparatedByString("/") // split by slashes
                            courseId = hrefParts[hrefParts.count-1] // courseId is last
                            // quit if schedule already found
                            if event["schedule"] != nil {
                                break
                            }
                        }
                        else if rel == "https://api.learningstudio.com/rel/schedule" {
                            event["schedule"] = link["schedule"]
                            // quit if course is already found
                            if courseId != nil {
                                break
                            }
                        }
                    }

                    // skip if schedule not present
                    if event["schedule"] == nil {
                        continue
                    }
                    
                    // skip if the user chose to ignore this course
                    if ignoredCourses != nil && ignoredCourses![courseId!] != nil && ignoredCourses![courseId!] == true {
                        continue
                    }

                    var schedule = event["schedule"] as! [String:AnyObject]
                    var accessSchedule = schedule["accessSchedule"] as! [String:AnyObject]

                    var startDateTime = accessSchedule["startDateTime"] as? String
                    var accessBefore = accessSchedule["canAccessBeforeStartDateTime"] as! Bool

                    // skip if not new
                    if startDateTime == nil ||
                        startDateTime!.compare(startDate) != NSComparisonResult.OrderedDescending ||
                        accessBefore == true {
                            continue
                    }
                    
                    // skip if beyond future preference
                    var dueDateTime = schedule["dueDate"] as? String
                    if dueDateTime == nil ||
                        dueDateTime!.compare(futureDateTime) == NSComparisonResult.OrderedDescending {
                            continue
                    }
                    
                    newEvents.append(event)
                }

                callback(data: newEvents, error: nil)
            }
            else {
                callback(data: nil, error: error)
            }
        })
    }
    
    // Retrieves new What's Happenning activity
    func getHappeningsSince(startDate: String, callback: (data: AnyObject?, error:NSError?) -> Void) {
        
        getJson("/me/whatshappeningfeed?v=2&after=\(startDate)", callback: { (data, error) -> Void in
            
            if error == nil {
                
                // retrieve course the user chose to ignore
                var ignoredCourses = NSUserDefaults.standardUserDefaults().objectForKey(self.defaultIgnoredCoursesKey) as? [String:Bool]
                
                // unnest data
                var activityStream = data!["activityStream"] as! [String:AnyObject]
                var happenings = activityStream["items"] as! [[String:AnyObject]]
                
                var newHappenings: [[String:AnyObject]] = []
                for happening in happenings {
                    
                    var startDateTime = happening["postedTime"] as? String
                    
                    // skip if before start time. query should not return these anyway
                    if startDateTime == nil ||
                        startDateTime!.compare(startDate) != NSComparisonResult.OrderedDescending {
                        continue
                    }
                    
                    // skip if the user chose to ignore this course
                    var target = happening["target"] as! [String:AnyObject]
                    var courseId = target["courseId"]! as! String
                    if ignoredCourses != nil && ignoredCourses![courseId] != nil && ignoredCourses![courseId] == true {
                        continue
                    }
                    
                    newHappenings.append(happening)
                }

                callback(data: newHappenings, error: nil)
            }
            else {
                callback(data: nil, error: error)
            }
        })
    }
    
    // Retrieves New Announcements
    func getAnnouncementsSince(startDate: String, callback: (data: AnyObject?, error:NSError?) -> Void) {
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = normalDateFormat
        dateFormatter.timeZone = NSTimeZone(name: defaultTimeZone)
        
        // convert date format
        var date = dateFormatter.dateFromString(startDate)
        dateFormatter.dateFormat = shortDateFormat
        let sinceDate = dateFormatter.stringFromDate(date!)
        
        // these are stored when courses are pulled during login/refresh
        var startRange = NSUserDefaults.standardUserDefaults().stringForKey(defaultCourseStartRangeKey)!
        var endRange = NSUserDefaults.standardUserDefaults().stringForKey(defaultCourseEndRangeKey)!
        
        getJson("/me/courses?expand=course&startDatesBetween=\(startRange)&endDatesBetween=\(endRange)", callback: { (data, error) -> Void in
            
            if error == nil {
                
                var courses = data!["courses"] as! [AnyObject]
                
                // return if not courses found
                if courses.count == 0 {
                    callback(data:[], error:nil)
                    return
                }
    
                // closure to handle root callback
                var allAnnouncements: ([[AnyObject]])? = []
                var rootCallback = { (data: [AnyObject]?, error :NSError?) -> Void in
                    // only proceed if error has not occurred
                    if allAnnouncements != nil {
                        if error != nil { // abort on error
                            allAnnouncements = nil // indicate error
                            callback(data:nil, error: error)
                        }
                        else {
                            allAnnouncements!.append(data!)
                            if allAnnouncements!.count == courses.count { // return when all complete
                                var collapsedAnnouncements: [AnyObject] = [] // return a single list
                                for announcements in allAnnouncements! {
                                    collapsedAnnouncements += announcements
                                }

                                callback(data:collapsedAnnouncements, error: nil)
                            }
                        }
                    }
                    else {
                        callback(data:nil, error: error)
                    }
                }
                
                // retrieve the course the user chose to ignore
                var ignoredCourses = NSUserDefaults.standardUserDefaults().objectForKey(self.defaultIgnoredCoursesKey) as? [String:Bool]
               
                // retrieve announcements for each course
                for course in courses {
                    // unnest course data
                    var courseLinks = course["links"] as! [[String:AnyObject]]
                    var courseLinksCourse = courseLinks[0]["course"] as! [String:AnyObject]
                    
                    var courseId = String(courseLinksCourse["id"] as! Int)
                    
                    // skip if the user chose to ignore this course
                    if ignoredCourses != nil && ignoredCourses![courseId] != nil && ignoredCourses![courseId] == true {
                        continue
                    }

                    // TODO - There's a bug with "since" in the API.
                    //        It doesn't include today's announcements
                    //        Restore the below line when it starts working again
                    //self.getJson("/me/courses/\(courseId)/announcements?excludeInactive=true&since=\(sinceDate)", callback: { (data, error) -> Void in
                    self.getJson("/me/courses/\(courseId)/announcements?excludeInactive=true", callback: { (data, error) -> Void in

                    
                        if error == nil {
                            var announcements = data!["announcements"] as! [[String:AnyObject]]
                            var unreadAnnouncements: [[String:AnyObject]] = []
                            for announcement in announcements {
                                var readStatus = announcement["readstatus"] as! Bool
                                // only include unread announcements
                                if  readStatus == false {
                                    // verify the display date/time is newer
                                    var startDateTime = announcement["startDisplayDate"] as? String
                                    if startDateTime == nil ||
                                        startDateTime!.compare(startDate) != NSComparisonResult.OrderedDescending {
                                            continue
                                    }
    
                                    unreadAnnouncements.append(announcement)
                                }
                            }
  
                            rootCallback(unreadAnnouncements, error)
                        }
                        else {
                            rootCallback(nil, error)
                        }
                    })
                }
            }
            else {
                callback(data: nil, error:error)
            }
        })

    }
    
    
    // MARK: - Utility Methods
    
    // Converts a UTC/default time for timezone of a specific course
    func convertCourseDate(courseId: String, dateString: String, humanize: Bool = false) -> String {
        
        // convert from default timezone
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = normalDateFormat
        dateFormatter.timeZone = NSTimeZone(name: defaultTimeZone)
        
        // covert string to date
        var date = dateFormatter.dateFromString(dateString)
        
        // might have been long format if it failed
        if date == nil {
            dateFormatter.dateFormat = longDateFormat
            date = dateFormatter.dateFromString(dateString)
            
            // give up this failed too
            if date == nil {
                return ""
            }
            
            dateFormatter.dateFormat = normalDateFormat
        }
        
        // humanize the output if requested
        if humanize {
            dateFormatter.dateFormat = "yyyy-MM-dd hh:mm a"
        }
        
        // convert to timezone specified for course
        var timeZone : [String:AnyObject] = userData!.timeZones![courseId]!
        dateFormatter.timeZone = NSTimeZone(name: timeZone["zoneName"] as! String)
        
        return dateFormatter.stringFromDate(date!)
    }
    
    
    // MARK: - UI Access Management
    
    // NOT ideal to control the view here, but better than referencing everywhere...
    
    // Shows login screen
    func promptForCredentials() {
        clearCredentials() // clear credentials before showing login UI
        mainView.showLogin()
    }
    
    // Shows loading screen after login
    func proceedWithCredentials() {
        if tokens != nil {
            if(tokenExpireDate!.compare(NSDate()) == NSComparisonResult.OrderedDescending) {
                mainView.showLoading()
                saveCredentials() // credentials can be saved now
            }
        }
    }
    
    // Shows loading screen during data refresh
    func proceedWithRefresh() {
        if tokens != nil {  // should have authenticated before
            mainView.showLoading()
        }
    }
    
    // Transitions from loading screen to main display
    func proceedToDashboard() {
        if tokens != nil {  // should have authenticated before and still be valid.
            if(tokenExpireDate!.compare(NSDate()) == NSComparisonResult.OrderedDescending) {
                mainView.showTabs()
            }
        }
    }
    
    // Handles errors with no chance of recovery by logging out after displaying message
    private func recoverFromError(shortReason: String, longReason: String) {
        clearCredentials() // clear credentials before logging out
        mainView.recoverFromError(shortReason, longReason: longReason)
    }
    
    // MARK - Composite data loads
    
    // Loads all data required for displaying dashboard
    private func loadInitialData(callback: (error:NSError?) -> Void) {
        LearningStudio.api.getCourses({ (error) -> Void in
            
            if error == nil {
                NSNotificationCenter.defaultCenter().postNotificationName("RefreshCourses", object:self)
                
                // need this data (timezones, upcomingevents) for the first tab.
                LearningStudio.api.getTimeZones({ (error) -> Void in
                    if error == nil {
                        // notify for external processing of new time zone data
                        NSNotificationCenter.defaultCenter().postNotificationName("RefreshTimeZones", object:self)
                        
                        LearningStudio.api.getUpcomingEvents({ (error) -> Void in
                            callback(error: error)
                            
                            if error == nil {
                                // notify for external processing of new event data
                                dispatch_async(dispatch_get_main_queue()) {
                                    NSNotificationCenter.defaultCenter().postNotificationName("RefreshUpcomingEvents", object:self)
                                }
                                
                                self.refreshUpcomingEvents() // do internal processing of new event data
                            }
                            else {
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.recoverFromError("Unreachable data", longReason: "Activity data could not be retrieved.")
                                }
                            }
                        })
                    }
                    else {
                        callback(error: error)
                        dispatch_async(dispatch_get_main_queue()) {
                            self.recoverFromError("Unreachable data", longReason: "Timezone data could not be retrieved.")
                        }
                    }
                })
                
                // The rest can be loaded behind the scenes
                LearningStudio.api.getHappenings({ (error) -> Void in
                    
                    if error == nil {
                        // notify for external processing of new happening data
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotificationName("RefreshHappenings", object:self)
                        }
                        self.refreshHappenings() // do internal processing of new happening data
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.recoverFromError("Unreachable data", longReason: "Happenings data could not be retrieved.")
                        }
                    }

                })
                LearningStudio.api.getGradesToDate({ (error) -> Void in

                    if error == nil {
                        // notify for external processing of new grade data
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotificationName("RefreshGradesToDate", object:self)
                        }
                        self.refreshGradesToDate() // do internal processing of new grade data
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.recoverFromError("Unreachable data", longReason: "Grades data could not be retrieved.")
                        }
                    }
                })
                LearningStudio.api.getAnnouncements({ (error) -> Void in
                        
                    if error == nil {
                        //  notify for external processing of new announcement data
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotificationName("RefreshAnnouncements", object:self)
                        }
                        self.refreshAnnouncements() // do internal processing of new announcement data
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.recoverFromError("Unreachable data", longReason: "Announcements data could not be retrieved.")
                        }
                    }

                })
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    callback(error: error)
                    self.recoverFromError("Unreachable data", longReason: "Course data could not be retrieved.")
                }
            }
            
        })
    }
    
    // Perform setup and teardown for loadInitialData by defining date ranges
    func reloadData(callback: (error:NSError?) -> Void) {
        // prepare date format
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: defaultTimeZone)
        dateFormatter.dateFormat = shortDateFormat
        
        var today = NSDate()
        // remove time from current date
        today = dateFormatter.dateFromString(dateFormatter.stringFromDate(today))!
        
        // apply user preference for past days
        var pastDays = NSUserDefaults.standardUserDefaults().doubleForKey(defaultPastViewDaysKey)
        if pastDays <= 0 { // default if missing
            pastDays = Double(pastViewDaysDefault)
        }
        pastDays = pastDays * -1
        
        // apply user preference for future days
        var futureDays = NSUserDefaults.standardUserDefaults().doubleForKey(defaultFutureViewDaysKey)
        if futureDays <= 0 { // default if missing
            futureDays = Double(futureViewDaysDefault)
        }
        futureDays = futureDays + 1 // looks are exclusine on end date
        
        // establish start and end date
        var startDate = today.dateByAddingTimeInterval(pastDays * 24 * 60 * 60) // # days back
        var endDate = today.dateByAddingTimeInterval(futureDays * 24 * 60 * 60) // # days ahead
        // store start and end date
        self.startSearchDate = dateFormatter.stringFromDate(startDate)
        self.endSearchDate = dateFormatter.stringFromDate(endDate)
        // store last load time for later comparisons
        self.lastLoadTime = NSUserDefaults.standardUserDefaults().objectForKey(defaultLastLoadTimeKey) as? String

        // load the data required for app display
        loadInitialData({ (error) -> Void in
            if error == nil {
                // remove previously archived data
                if self.isUserDataArchived {
                    self.removeUserDataArchive()
                }
                
                // need to keep track of last load and acivity time for future comparison
                let now = NSDate()
                dateFormatter.dateFormat = self.normalDateFormat
                let nowString = dateFormatter.stringFromDate(now)
                NSUserDefaults.standardUserDefaults().setValue(nowString, forKey: self.defaultLastLoadTimeKey) // app loaded
                NSUserDefaults.standardUserDefaults().setValue(nowString, forKey: self.defaultLastActivityTimeKey) // background fetch
            }
            
            callback(error: error)
        })
    }
    
    // MARK: - Internal Refresh Handlers
    
    // internal event handlers that compare date for differences since last load
    
    // looks for differences in upcomingEvents since last load after a refresh occurs
    private func refreshUpcomingEvents() {
        // look for changes since last load. want to display badge on tab
        if lastLoadTime != nil {
            var diffCount = 0
            // iterate the active courses
            for course in self.userData!.courses! {
                // skip if no events present for course
                var courseId = String(course["id"] as! Int)
                if self.userData!.upcomingEvents![courseId] == nil {
                    continue
                }
                // iterate events for course looking for new events
                for upcomingEvent in self.userData!.upcomingEvents![courseId]! {
                    var schedule = upcomingEvent["schedule"] as! [String:AnyObject]
                    var accessSchedule = schedule["accessSchedule"] as! [String:AnyObject]

                    // skip if start time not present
                    if accessSchedule["startDateTime"] == nil {
                        continue
                    }
                    
                    var eventDate = accessSchedule["startDateTime"] as! String
                    var accessBefore = accessSchedule["canAccessBeforeStartDateTime"] as! Bool
                    
                    // count as new if started since last load and could not access before
                    if eventDate.compare(lastLoadTime!) == NSComparisonResult.OrderedDescending &&
                        accessBefore == false {
                        diffCount++
                    }
                }
            }
            
            // fire notification of difference if new events
            if diffCount > 0 {
                var userInfo = [ "count" : diffCount ]
                dispatch_after( // must fire after tab controller loads
                    dispatch_time(DISPATCH_TIME_NOW,Int64(2 * Double(NSEC_PER_SEC))), // 2 seconds
                    dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotificationName("DiffUpcomingEvents", object:self, userInfo: userInfo)
                }
            }
        }
    }
    
    // looks for differences in happenings since last load after a refresh occurs
    private func refreshHappenings() {
        // look for changes since last load. want to display badge on tab
        if lastLoadTime != nil {
            var diffCount = 0
            // iterate the active courses
            for course in self.userData!.courses! {
                // skip if new happenings for course
                var courseId = String(course["id"] as! Int)
                if self.userData!.happenings![courseId] == nil {
                    continue
                }
                // iterate happenings for course
                for happening in self.userData!.happenings![courseId]! {
                    var happeningDate = happening["postedTime"] as! String
                    // count as new if posted since last load
                    if happeningDate.compare(lastLoadTime!) == NSComparisonResult.OrderedDescending {
                        diffCount++
                    }
                }
            }
            
            // fire notification of difference if new happenings
            if diffCount > 0 {
                var userInfo = [ "count" : diffCount ]
                dispatch_after( // must fire after tab controller loads
                    dispatch_time(DISPATCH_TIME_NOW,Int64(2 * Double(NSEC_PER_SEC))), // 2 seconds
                    dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotificationName("DiffHappenings", object:self, userInfo: userInfo)
                }
            }
        }
    }
    
    // looks for differences in announcements since last load after a refresh occurs
    private func refreshAnnouncements() {
        // look for changes since last load. want to display badge on tab
        if lastLoadTime != nil {
            var diffCount = 0
            // iterate active courses
            for course in self.userData!.courses! {
                var courseId = String(course["id"] as! Int)
                if self.userData!.announcements![courseId] == nil {
                    continue
                }
                // iterate announcements for course
                for announcement in self.userData!.announcements![courseId]! {
                    var announceDate = announcement["startDisplayDate"] as! String
                    // count as new if displayed after last load
                    if announceDate.compare(lastLoadTime!) == NSComparisonResult.OrderedDescending {
                        diffCount++
                    }
                }
            }
            
            // fire notification of difference if new announcements
            if diffCount > 0 {
                var userInfo = [ "count" : diffCount ]
                dispatch_after( // must fire after tab controller loads
                    dispatch_time(DISPATCH_TIME_NOW,Int64(2 * Double(NSEC_PER_SEC))), // 2 seconds
                    dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotificationName("DiffAnnouncements", object:self, userInfo: userInfo)
                }
            }
        }
    }
    
    // looks for differences in gradesToDate since last load after a refresh occurs
    private func refreshGradesToDate() {
        // no date to use for comparison here...
    }
    
    // MARK: - User Data Management
    
    // Container for all loaded data
    class UserData: NSObject, NSCoding {
        var me: [String:AnyObject]?
        var courses: [[String:AnyObject]]?
        var hiddenCourses: [[String:AnyObject]]?
        var happenings: [String: [[String:AnyObject]]]? // by courseId
        var upcomingEvents: [String: [[String:AnyObject]]]? // by courseId
        var gradesToDate: [String : [String:AnyObject]]? // by courseId
        var announcements: [String: [[String:AnyObject]]]? // by courseId
        var timeZones: [String: [String:AnyObject]]? // by courseId
        
        override init() {
            
        }
        
        // likely not ideal way to save and restore this data, but it's only for memory warnings...
        // and it's easy... Thanks to the following article for the technique.
        // http://www.thinkingswiftly.com/saving-spritekit-game-data-swift-easy-nscoder/
        
        required init(coder: NSCoder) {
            self.me = coder.decodeObjectForKey("me")! as? [String:AnyObject]
            self.courses = coder.decodeObjectForKey("courses")! as? [[String:AnyObject]]
            self.hiddenCourses = coder.decodeObjectForKey("hiddenCourses")! as? [[String:AnyObject]]
            self.happenings = coder.decodeObjectForKey("happenings")! as? [String: [[String:AnyObject]]]
            self.upcomingEvents = coder.decodeObjectForKey("upcomingEvents")! as? [String: [[String:AnyObject]]]
            self.gradesToDate =  coder.decodeObjectForKey("gradesToDate")! as? [String : [String:AnyObject]]
            self.announcements = coder.decodeObjectForKey("announcements")! as? [String: [[String:AnyObject]]]
            self.timeZones = coder.decodeObjectForKey("timeZones")! as? [String: [String:AnyObject]]
            super.init()
        }
        
        func encodeWithCoder(coder: NSCoder) {
            coder.encodeObject(self.me, forKey: "me")
            coder.encodeObject(self.courses, forKey: "courses")
            coder.encodeObject(self.hiddenCourses, forKey: "hiddenCourses")
            coder.encodeObject(self.happenings, forKey: "happenings")
            coder.encodeObject(self.upcomingEvents, forKey: "upcomingEvents")
            coder.encodeObject(self.gradesToDate, forKey: "gradesToDate")
            coder.encodeObject(self.announcements, forKey: "announcements")
            coder.encodeObject(self.timeZones, forKey: "timeZones")
        }
    }
    
    // Loads archived user data
    private func loadUserDataArchive() {
        // setup file location
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0] as! String
        let path = documentsDirectory.stringByAppendingPathComponent(dataArchiveFilename)
        let fileManager = NSFileManager.defaultManager()
        
        // check if file exists
        if fileManager.fileExistsAtPath(path) {
            // load the data
            if let rawData = NSData(contentsOfFile: path) {
                var dataObject: AnyObject? = NSKeyedUnarchiver.unarchiveObjectWithData(rawData)
                userDataInternal = dataObject as? UserData
            }
            // delete the archive
            var err: NSError?
            fileManager.removeItemAtPath(path, error: &err)
            if err != nil { // oh well. we tried...
                //println("FAILED TO DELETE USERDATA ARCHIVE \(err)")
            }
        }
        
        isUserDataArchived = false
    }
    
    // Removes archived user data
    func removeUserDataArchive() {
        // setup file location
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0] as! String
        let path = documentsDirectory.stringByAppendingPathComponent(dataArchiveFilename)
        let fileManager = NSFileManager.defaultManager()
        
        // check if file exists
        if fileManager.fileExistsAtPath(path) {
            // delete the archive
            var err: NSError?
            fileManager.removeItemAtPath(path, error: &err)
            if err != nil { // oh well. we tried...
                //println("FAILED TO DELETE USERDATA ARCHIVE \(err)")
            }
        }
        
        isUserDataArchived = false
    }
    
    // Archives user data
    func saveUserDataArchive() {
        // setup the file location
        let saveData = NSKeyedArchiver.archivedDataWithRootObject(self.userData!)
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent(dataArchiveFilename)
        
        // archive the data
        if saveData.writeToFile(path, atomically: true) {
            self.userData = nil
            self.isUserDataArchived = true
        }
        else { // on failure remove any archive that might already exist
            //println("FAILED TO SAVE USERDATA ARCHIVE")
            removeUserDataArchive()
        }
    }
    

}