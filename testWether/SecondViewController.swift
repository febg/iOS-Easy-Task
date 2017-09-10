//
//  SecondViewController.swift
//  testWether
//
//  Created by Felipe Ballesteros on 2017-08-07.
//  Copyright © 2017 Felipe Ballesteros. All rights reserved.
//

import UIKit
import Foundation

class SecondViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var searchHistory =          [String: [String]]()
    var indices:                 [String] = []
    var pastCities:              [String] = []
    var pastCities2:             [String] = []
    var timer1:                  Timer?
    var timer2:                  Timer?
    var refresher:               UIRefreshControl!
    var temperatureK  =          0.0                    //Stores temperature obtained directly from API request
    var temperatureKUpdate =     0.0                    //Not currently used (work in progress)
    var temperatureF  =          0.0                    //Stores temperatureK equivalent to fahrenheit
    var temperatureC  =          0.0                    //Stores temperatureK equivalent to celsius
    var pastCitiesSize =         0                      //Not currently used (work in progress)
    var connectionAttempts =     0                      //Stores connection attempts to the weather API
    var timer2Count =            0                      //Not currently used (work in progress)
    var city =                   ""                     //Stores city corresponding to the user's search obtained directly
    var location =               ""                     //Stores city corresponding to the user's search obtained from textfield (User input)
    var weatherDescription =     ""                     //Stores weather description obtained directly from API request
    var mainWeatherDescription = ""                     //Stores main weather description obtained directly from API request
    var isTableUpdated =         true                   //Flag used to indicate if the tableView was updated after a new search has been requested
    var isCityFound =            true                   //Flag used to indicate if the city entered by the user was found on the Weather API
    var isTemperatureSet =       false                  //Flag used to determine if weather information has been retrieved from weather API
    var showCelcious =           false                  //Flag used to determine if user prefers temperarure display in celsius or fahrenheit
    var updateOnGoing =          false                  //Not currently used (work in progress)
    var isErrorNotified =        false                  //Flag used to determine if an error viewAlert was displayed when connection to API is not successful
    var readyToUpdate =          false                  //Not currently used (work in progress)
    
    @IBOutlet weak var searchIndicator: UIActivityIndicatorView!

    @IBOutlet weak var tempText: UILabel!
    
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var tittle:          UITextView!
    @IBOutlet weak var cityEntry:       UITextField!
    @IBOutlet weak var historyView: UITableView!
    
    @IBAction func searchCity(_ sender: Any){
        self.view.endEditing(true)
        if self.cityEntry.text != nil && (self.cityEntry.text?.characters.count)! > 2 {
            location = checkWhiteSpace(text: self.cityEntry.text!)
            searchIndicator.startAnimating()
            if !pastCities.contains(location){
                pastCities.append(location)
                pastCitiesSize = pastCities.count
            }
            isTemperatureSet = false
            getWeather()
            runTimer(timmer: 1)
        }
    }
    
    /*
     * FUNCTION: fToC
     *
     * PUPOSE: Reads switch current value and updates showCelsius flag value
     */
    @IBAction func fToC(_ sender: UISwitch) {
        if sender.isOn{
            showCelcious = false
        }
        else{
            showCelcious = true
        }
        manageFields()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        cityEntry.delegate = self
        reloadHistory()
    }
    
    /*
     * FUNCTION: reloadHistory
     *
     * PUPOSE: Restores previous weather infomation to be diaplayed on table while user unters a new search request
     */
    func reloadHistory(){
        if let history = (UserDefaults.standard.value(forKey: "Dic") as? [String: [String]]){
            searchHistory = history
            pastCities2 = searchHistory.keys.sorted()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopTimer(timmer: 1)
        stopTimer(timmer: 2)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return searchHistory.count
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DisplayCell
        var infoForTable = getHistoryName(indexPath: indexPath.row)
        cell.descriptionText.text = infoForTable["city"]
        cell.tempText.text = infoForTable["temp"]
        cell.wetherDesciptionText.text = infoForTable["description"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == UITableViewCellEditingStyle.delete
        {
            print("Entramos")
            let key = pastCities2[indexPath.row]
            searchHistory.removeValue(forKey: key)
            saveDefaults()
            reloadHistory()
            tableView.reloadData()
        }
    }
    
    
    func recordSearch(update: Bool){
        if update {
            var info = [String(temperatureKUpdate)]
            info.append(" \(weatherDescription)")
            searchHistory[location] = info
        }
        else{
            var info = [String(Int(temperatureF))]
            info.append(" \(weatherDescription)")
            searchHistory[city] = info
        }
        saveDefaults()
        
        isTableUpdated = true
    }
    
    /*
     * FUNCTION: saveDefaults
     *
     * PUPOSE: Save the leatest weather infomation on the NSUserDefaults to be used
     *         next time the application restarts
     */
    func saveDefaults(){
        UserDefaults.standard.setValue(searchHistory, forKey: "Dic")
        reloadHistory()
    }
    
    func getHistoryName(indexPath: Int) -> Dictionary<String, String> {
        //Dictionary<String, String>
        indices = searchHistory.keys.sorted()
        var pastSearchInfo = [String:String]()
        var cityName = indices[indexPath]
        let cityInfo = searchHistory[cityName]
        cityName.append(":")
        pastSearchInfo["city"] = cityName
        let temp = ("\(cityInfo!.flatMap({$0})[0]) F")
        let dec = ("\(cityInfo!.flatMap({$0})[1])").capitalized
        pastSearchInfo["temp"] = temp
        pastSearchInfo["description"] = dec
        return pastSearchInfo
    }
    
    /*
     * FUNCTION: runTimer
     *
     * PUPOSE: Starts the timer that handles the connection attempts to the weather API
     *
     * PARAMETER: timmer -> Indictaes which timer is being initialized
     */
    func runTimer(timmer: Int) {
        if timmer == 1{
            timer1 = Timer.scheduledTimer(timeInterval: 1.0, target:self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        }
        else if timmer == 2{
            timer2 = Timer.scheduledTimer(timeInterval: 4.0, target:self, selector: #selector(updateTimer2), userInfo: nil, repeats: true)
        }
    }
    
    func updateTimer(){
        if !isCityFound{
            searchIndicator.stopAnimating()
            connectionAttempts = 0
            stopTimer(timmer: 1)
            displayCityError()
        }
        if !isTemperatureSet && connectionAttempts < 6 {
            connectionAttempts += 1
        }
        else {
            if isTemperatureSet && connectionAttempts > 0{
                manageUnits()
                searchIndicator.stopAnimating()
                self.cityEntry.text = ""
                stopTimer(timmer: 1)
                manageFields()
                self.historyView.reloadData()
                connectionAttempts = 0
            }
        }
        if !isTemperatureSet && connectionAttempts >= 6 {
            print("PILAS Display", connectionAttempts)
            searchIndicator.stopAnimating()
            connectionAttempts = 0
            print("Attempting to stop timmer 1")
            stopTimer(timmer: 1)
            displayConnectionError()
        }
        if timer2 == nil && !pastCities.isEmpty && readyToUpdate {
            runTimer(timmer: 2)
            timer2Count = 0
        }
    }
    
    func updateTimer2(){
        if !updateOnGoing && timer2Count < pastCitiesSize && isTemperatureSet {
            updatePastCities(index: timer2Count)
            updateOnGoing  = true
            timer2Count += 1
        }
    }
    
    func updatePastCities(index: Int){
        location = pastCities[index]
        if index == (pastCitiesSize - 1){
            timer2Count = 0
            stopTimer(timmer: 2)
        }
    }
    
    /*
     * FUNCTION: stopTimer
     *
     * PUPOSE: Stops connection timer
     *
     * PARAMETER: timmer -> Indicates whichtimer is being stopped
     */
    func stopTimer(timmer: Int) {
        if timmer == 1 {
            if timer1 != nil {
                print("Timmer 1 stoped")
                timer1?.invalidate()
                timer1 = nil
            }
        }
        else if timmer == 2 {
            if timer2 != nil {
                timer2?.invalidate()
                timer2 = nil
            }
        }
    }
    
    /*
     * FUNCTION: displayConnectionError
     *
     * PUPOSE: Trigger a custom UIAlerView to display connection error
     */
    func displayConnectionError() {
        let alert = SCLAlertView()
        _ = alert.addButton("Settings", target:self, selector:#selector(SecondViewController.triggerSettings))
        _ = alert.showError("No Connection", subTitle: "Clound not connect to server. Please check your internet connection")
    }
    
    /*
     * FUNCTION: displayCityError
     *
     * PUPOSE: Trigger a custom UIAlerView to notify the user the city that was rquested could not be found
     */
    func displayCityError() {
        let alert = SCLAlertView()
        _ = alert.showError("City Not Found", subTitle: "Check you Entry and Try Again")
    }
    
    /*
     * FUNCTION: triggerSettings
     *
     * PUPOSE: In case of a connection failure, this function handles the redirection from the app to the settings apps
     */
    func triggerSettings() {
        let url = URL(string: "App-Prefs:root=WIFI") //for WIFI setting app
        let app = UIApplication.shared
        app.open(url!, options: [:], completionHandler: {sucess in
        })
    }
    
    func checkWhiteSpace(text: String)-> String{
        let trimmed = text.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        if trimmed.contains(" "){
            let noSpaceText = trimmed.replacingOccurrences(of: " ", with: "_")
            return noSpaceText
        }
        else{
            return trimmed
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /*
     * FUNCTION: manageUnits
     *
     * PUPOSE: Converts temperature obtained in Kelvin directlt from the weather API and converts it to Celcius and Fahrenheit
     */
    func manageUnits(){
        while(!isTemperatureSet){
        }
        temperatureC = temperatureK - 273
        temperatureF = temperatureC * (9/5) + 32
    }
    
    /*
     * FUNCTION: manageFields
     *
     * PUPOSE: Updates the current view "Text Views" and labels with the acquierd weather information
     */
    func manageFields(){
        if !showCelcious{
            tempText.text = "\(Int(temperatureF)) F"
        }
        else{
            tempText.text = "\(Int(temperatureC)) C"
        }
        tittle.text = "\(city)"
        
        if mainWeatherDescription.lowercased() == weatherDescription{
            descriptionText.text = "\(mainWeatherDescription)"
        }
        else{
            descriptionText.text = "\(mainWeatherDescription)\n\"\(weatherDescription)\""
        }
        recordSearch(update: false)
    }
    
    /*
     * FUNCTION: getWeather
     *
     * PUPOSE: Creates the HTTP request to the weather API, once successful connection is stablished, it parses the response and stores information
     */
    func getWeather() {
        guard let url = URL(string: "http://api.openweathermap.org/data/2.5/weather?q=\(location)&&APPID=a0db4b8b538dffea73366309de8395aa") else { return }
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data, let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]{
                    print("jason",json)
                    if self.updateOnGoing {
                        if let content = json["main"] as! NSDictionary?{
                            if let temp = content["temp"] as! Double? {
                                self.temperatureKUpdate = temp
                                self.updateOnGoing = false
                            }
                        }
                    }
                    else {
                        if let content = json["main"] as! NSDictionary?{
                            
                            if let temp = content["temp"] as! Double? {
                                self.temperatureK = temp
                                self.isTemperatureSet = true
                            }
                            
                        }else{
                            print("Error unable to obtain main component")
                            self.isCityFound = false
                        }
                        if let name = json["name"] as! String? {
                            self.city = name
                        }
                        else{
                            print("Error unable to obtain city")
                            self.isCityFound = false
                        }
                        if let descrip = json["weather"] as! NSArray?{
                            if let descript = descrip[0] as?NSDictionary{
                                if let description = descript["description"] as! String? {
                                    self.weatherDescription = description
                                }
                                if let mainDescription = descript["main"] as! String? {
                                    self.mainWeatherDescription = mainDescription
                                }
                            }
                        }
                        else{
                            print("Error unable to obtain Weather Component")
                            self.isCityFound = false
                        }
                    }
                }
            } catch {
                print("Error deserializing JSON: \(error)")
            }
            }.resume()
        connectionAttempts += 1
        
    }
}
