//
//  FirstViewController.swift
//  testWether
//
//  Created by Felipe Ballesteros on 2017-08-07.
//  Copyright © 2017 Felipe Ballesteros. All rights reserved.
//

import UIKit
import CoreLocation

class FirstViewController: UIViewController, CLLocationManagerDelegate, UITextViewDelegate {
    
    let manager =               CLLocationManager() //Used to get user current location
    var timer:                  Timer?              //Used to initiates timmer that hanldes connection attmpts to weather API
    var longitude =             0.0                 //Stores user's current longitude
    var latitude =              0.0                 //Stores user's current latitude
    var temperatureK =          0.0                 //Stores temperature obtained directly from API request
    var temperatureF  =         0.0                 //Stores temperatureK equivalent to fahrenheit
    var temperatureC  =         0.0                 //Stores temperatureK equivalent to celsius
    var humidity =              0.0                 //Stores humidity obtained directly from API request
    var pressure =              0.0                 //Stores pressure obtained directly from API request
    var connectionAttempts =    0                   //Stores connection attempts to the weather API
    var city =                  ""                  //Stores city corresponding to current location obtained directly from API request
    var weatherDescription =    ""                  //Stores weather description obtained directly from API request
    var mainWeatherDescription = ""                 //Stores main weather description obtained directly from API request
    var sunRise =               ""                  //Stores sunrise obtained directly from API request obtained in UNIX format
    var sunSet =                ""                  //Stores sunset obtained directly from API request obtained in UNIX format
    var lastUpdateTime =        ""                  //Not currently used (work in progress)
    var isAppInitiated =        false               //Not currently used (work in progress)
    var isErrorNotified =       false               //Flag used to determine if an error viewAlert was displayed when connection to API is not successful
    var isLocationSet =         false               //Flag used to determine if current user location has been obtained
    var isTemperatureSet =      false               //Flag used to determine if weather information has been retrieved from weather API
    var showCelcious =          false               //Flag used to determine if user prefers temperarure display in celsius or fahrenheit
    var defaultsLoaded =        false               //Flag usused tod etermine if user default values for the current viewCobtroller are loaded
    
    @IBOutlet weak var connectionIndicator: UIActivityIndicatorView! //Indictator to provide feedback for connection response
    @IBOutlet weak var tittle:          UITextView!                  //Text View used to display current city tittle
    @IBOutlet weak var sunText:         UITextView!                  //Text View used to dsiplay sunrise and sunset at current location
    @IBOutlet weak var pressureText:    UITextView!                  //Text View used to display pressure at current location
    @IBOutlet weak var extrasText:      UITextView!                  //Text View used to display humidity at current location
    @IBOutlet weak var descriptionText: UITextView!                  //Text View used to display current location weather description
    @IBOutlet weak var tempText:        UITextView!                  //Text View used to display temperature at current weather
    @IBOutlet weak var loadText:        UITextView!                  //Text View used to display text to indicate to the user that data is being loaded
    
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
        loadText.text = "Loading data       "
        reloadHistory()
        manageFields()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        longitude = 0.0
        latitude = 0.0
        connectionAttempts = 0
        stopTimer()
        isLocationSet = false
        isErrorNotified = false
        isTemperatureSet = false
        loadText.text = "Loading data       "
        manager.stopUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        manageLocation()
    }
    
    /*
     * FUNCTION: manageLocation
     *
     * PUPOSE: Initiates the location manager and starts updatind users current location
     */
    func manageLocation(){
        tittle.delegate = self
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        connectionIndicator.startAnimating()
    }
    
    /*
     * FUNCTION: location manger
     *
     * PUPOSE: Gets current user location and intiates connection timer once location
     *         is obtained
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentlocation = locations[0]
        latitude = currentlocation.coordinate.latitude
        longitude = currentlocation.coordinate.longitude
        if !isLocationSet && latitude != 0.00 && longitude != 0.00 {
            isLocationSet = true
            manager.stopUpdatingLocation()
            runTimer()
        }
    }
    
    /*
     * FUNCTION: saveDefaults
     *
     * PUPOSE: Save the leatest weather infomation on the NSUserDefaults to be used
     *         next time the application restarts
     */
    func saveDefaults(){
        UserDefaults.standard.setValue(city, forKey: "City")
        UserDefaults.standard.setValue(temperatureK, forKey: "Tempk")
        UserDefaults.standard.setValue(mainWeatherDescription, forKey: "MainDesc")
        UserDefaults.standard.setValue(weatherDescription, forKey: "Desc")
        UserDefaults.standard.setValue(humidity, forKey: "Hum")
        UserDefaults.standard.setValue(pressure, forKey: "Press")
        UserDefaults.standard.setValue(sunSet, forKey: "SunSet")
        UserDefaults.standard.setValue(sunRise, forKey: "SunRise")
    }
    
    /*
     * FUNCTION: reloadHistory
     *
     * PUPOSE: Restores previous weather infomation to be diaplayed while current
     *         weather is updated
     */
    func reloadHistory(){
        defaultsLoaded = true
        if let cityTemp = (UserDefaults.standard.value(forKey: "City") as? String){
            city = cityTemp
        }
        else{
            print("Relode1")
            defaultsLoaded = false
        }
        if let temperaturekTemp = (UserDefaults.standard.value(forKey: "Tempk") as? Double){
            temperatureK = temperaturekTemp
            manageUnits()
        }
        else{
            print("Relode2")
            defaultsLoaded = false
        }
        if let mainDescTemp = (UserDefaults.standard.value(forKey: "MainDesc") as? String){
            mainWeatherDescription = mainDescTemp
        }
        else{
            print("Relode3")
            defaultsLoaded = false
        }
        
        if let descTemp = (UserDefaults.standard.value(forKey: "Desc") as? String){
            weatherDescription = descTemp
        }
        else{
            print("Relode4")
            defaultsLoaded = false
        }
        if let humTemp = (UserDefaults.standard.value(forKey: "Hum") as? Double){
            humidity = humTemp
        }
        else{
            print("Relode5")
            defaultsLoaded = false
        }
        if let pressureTemp = (UserDefaults.standard.value(forKey: "Press") as? Double){
            pressure = pressureTemp
        }
        else{
            print("Relode6")
            defaultsLoaded = false
        }
        if let sunSetTemp = (UserDefaults.standard.value(forKey: "SunSet") as? String){
            sunSet = sunSetTemp
        }
        else{
            print("Relode7")
            defaultsLoaded = false
        }
        if let sunRiseTemp = (UserDefaults.standard.value(forKey: "SunRise") as? String){
            sunRise = sunRiseTemp
        }
        else{
            print("Relode8")
            defaultsLoaded = false
        }
    }
    
    /*
     * FUNCTION: manageFields
     *
     * PUPOSE: Updates the current view "Text Views" and labels with the acquierd weather information
     */
    func manageFields(){
        print("Fields generales")
        print(defaultsLoaded)
        if isTemperatureSet || defaultsLoaded {
            if isTemperatureSet{
                loadText.text = ""
            }
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
            extrasText.text = " Humidity: \(humidity)%"
            pressureText.text = " Pressure: \(pressure) hPa"
            sunText.text = " Sunrise: \(sunRise)\n\n\n Sunset: \(sunSet)"
        }
        else{
            print("else fields")
            tempText.text = "--"
            tittle.text = "--"
            descriptionText.text = "--"
            extrasText.text = " Humidity: --"
            pressureText.text = " Pressure: --"
            sunText.text = " Sunrise: --\n\n\n Sunset: --"
        }
    }
    
    /*
     * FUNCTION: manageUnixTime
     *
     * PUPOSE: Converts the Unix time acquierd from the weather API response to "human readable time"
     *
     * PARAMETER: unixTimeStamp -> The Unix date stamp to be converted
     */
    func manageUnixTime(unixTimeStamp: Double ) -> String {
        var convertedDate = String(describing: NSDate(timeIntervalSince1970: unixTimeStamp))
        var fullArr = convertedDate.components(separatedBy: " ")
        let timeOnly = fullArr[1]
        convertedDate = UTCToLocal(date: timeOnly)
        return convertedDate
    }
    
    /*
     * FUNCTION: UTCToLocal
     *
     * PUPOSE: Converts a "human readable" UTC time to user's current time zone
     *
     * PARAMETER: date -> The UTC date to be converted
     */
    func UTCToLocal(date:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let dt = dateFormatter.date(from: date)
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: dt!)
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
    
    /*
     * FUNCTION: runTimer
     *
     * PUPOSE: Starts the timer that handles the connection attempts to the weather API
     */
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target:self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    /*
     * FUNCTION: runTimer
     *
     * PUPOSE: Manages the connection attemps to the weather API, as well as AlertViews in case of error and updates TexView fields
     */
    func updateTimer(){
        print("Timmer",isTemperatureSet,connectionAttempts)
        if !isTemperatureSet && connectionAttempts < 5 {
            getWeather()
            connectionAttempts += 1
        }
        else{
            if isTemperatureSet == true && connectionAttempts > 0{
                manageUnits()
                connectionIndicator.stopAnimating()
                manageFields()
                saveDefaults()
                stopTimer()
                connectionAttempts = 0
            }
        }
        if connectionAttempts >= 5 && !isErrorNotified && !isTemperatureSet {
            connectionAttempts = 0
            isErrorNotified = true
            connectionIndicator.stopAnimating()
            loadText.text = ""
            displayError()
        }
        if connectionAttempts == 5 && isErrorNotified && !isTemperatureSet{
            connectionAttempts = 0
        }
    }
    
    /*
     * FUNCTION: timeHandler (Not currently used (work in progress)
     *
     * PUPOSE: Handles weather updates depending when how much time and how further is the user from last updated location
     *
     * PARAMETER: update -> Flag indicating if an update is requiered
     */
    func timeHandler(update: Bool){
        if !update {
            let date = Date()
            let formatter: DateFormatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateTime = formatter.string(from: date)
            lastUpdateTime = dateTime
        }
        else{
            let dateR = Date()
            let formatterR: DateFormatter = DateFormatter()
            formatterR.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateTimeR = formatterR.string(from: dateR)
            if lastUpdateTime != dateTimeR{
            }
        }
    }
    
    /*
     * FUNCTION: displayError
     *
     * PUPOSE: Trigger a custom UIAlerView to display connection error
     */
    func displayError(){
        let alert = SCLAlertView()
        _ = alert.addButton("Settings", target:self, selector:#selector(FirstViewController.triggerSettings))
        _ = alert.showError("No Connection", subTitle: "Clound not connect to server. Please check your internet connection")
    }
    
    /*
     * FUNCTION: stopTimer
     *
     * PUPOSE: Stops connection timer
     */
    func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    /*
     * FUNCTION: manageUnits
     *
     * PUPOSE: Converts temperature obtained in Kelvin directlt from the weather API and converts it to Celcius and Fahrenheit
     */
    func manageUnits(){
        temperatureC = temperatureK - 273
        temperatureF = temperatureC * (9/5) + 32
    }
    
    /*
     * FUNCTION: getWeather
     *
     * PUPOSE: Creates the HTTP request to the weather API, once successful connection is stablished, it parses the response and stores information
     */
    func getWeather() {
        guard let url = URL(string: "http://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&APPID=0ed8f0fb0b7c44b7c3759672a64960ce") else { return }
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data, let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]{
                    if error == nil{
                        self.isTemperatureSet = true
                    }
                    if let content = json["main"] as! NSDictionary?{
                        if let temp = content["temp"] as! Double? {
                            self.temperatureK = temp
                        }
                        if let humi = content["humidity"] as! Double? {
                            self.humidity = humi
                        }
                        if let press = content["pressure"] as! Double? {
                            self.pressure = press
                        }
                    }
                    if let name = json["name"] as! String? {
                        self.city = name
                    }
                    if let descrip = json["weather"] as! NSArray?{
                        if let descript = descrip[0] as? NSDictionary{
                            
                            if let description = descript["description"] as! String? {
                                self.weatherDescription = description
                            }
                            if let mainDescription = descript["main"] as! String? {
                                self.mainWeatherDescription = mainDescription
                            }
                        }
                    }
                    if let sys = json["sys"] as! NSDictionary?{
                        if let sRise = sys["sunrise"] as! Double? {
                            self.sunRise = self.manageUnixTime(unixTimeStamp: sRise)
                        }
                        if let sSet = sys["sunset"] as! Double? {
                            self.sunSet = self.manageUnixTime(unixTimeStamp: sSet)
                        }
                    }
                }
            } catch {
                print("Error deserializing JSON: \(error)")
                
            }            }.resume()
    }
}
