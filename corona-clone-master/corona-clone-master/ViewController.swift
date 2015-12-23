//
//  ViewController.swift
//  colona-clone-master
//
//  Created by ota42y on 2015/12/23.
//  Copyright © 2015年 ota42y. All rights reserved.
//

import UIKit

enum Mode {
    case Wait
    case TrainingWait
    case Training
    case Analyze
}

class ViewController: UIViewController, BluetoothStateDelegate {
    @IBOutlet weak var trainingButton: UIButton!
    @IBOutlet weak var analyzeButton: UIButton!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var trainingStartButton: UIButton!
    @IBOutlet weak var connectionLabel: UILabel!
    
    var RSSI_INTERVAL = 0.2 //
    var RSSI_VERTOR_LENGTH = 10 //
    var TRAINING_COUNT = 40
    var TRAINING_URL = "http://192.168.1.1:8080"  // change me
    
    var mode = Mode.Wait
    
    var nowPointName = ""
    
    var touchPoint: CGPoint!
    var touchPointImageView: UIImageView!
    var analyzePointImageView: UIImageView!
    var connector = BluetoothConnector()
    
    var rssiArray: [String] = []
    
    var trainingPoint = Dictionary<String, UIImageView>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connector.createManager(self)
        
        touchPoint = CGPoint.zero;
        
        let img:UIImage?  = UIImage(named: "blue.png")
        touchPointImageView = UIImageView(image: img)
        view.addSubview(touchPointImageView)
        touchPointImageView.hidden = true
        
        let orangeImg:UIImage?  = UIImage(named: "orange.png")
        analyzePointImageView = UIImageView(image: orangeImg)
        view.addSubview(analyzePointImageView)
        analyzePointImageView.hidden = true
        
        trainingButton.addTarget(self, action: "onClickTrainingButton:", forControlEvents: .TouchUpInside)
        analyzeButton.addTarget(self, action: "onClickAnalyzeButton:", forControlEvents: .TouchUpInside)
        
        trainingStartButton.addTarget(self, action: "onClickTrainingStartButton:", forControlEvents: .TouchUpInside)
        disableTrainingStartButton()
        
        NSTimer.scheduledTimerWithTimeInterval(RSSI_INTERVAL, target: self, selector: Selector("onUpdate:"), userInfo: nil, repeats: true)
        
        deleteTrainingData()
    }
    
    internal func enableTrainingStartButton() {
        trainingStartButton.enabled = true
        trainingStartButton.hidden = false
    }
    
    internal func disableTrainingStartButton() {
        trainingStartButton.enabled = false
        trainingStartButton.hidden = true
    }
    
    internal func showNowTrainingPoint() {
        touchPointImageView.center = touchPoint
        touchPointImageView.hidden = false
    }
    
    internal func hideTouchPoint() {
        touchPointImageView.hidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (mode == Mode.TrainingWait) {
            if let touch = touches.first {
                touchPoint = touch.locationInView(view)
                showNowTrainingPoint()
                enableTrainingStartButton()
            }
        }
    }
    
    internal func onClickTrainingStartButton(sender: UIButton) {
        if (mode == Mode.TrainingWait) {
            disableTrainingStartButton()
            hideTouchPoint()
            trainingButton.enabled = false
            
            mainLabel.text = "training..."
            mode = Mode.Training
            
            nowPointName = "pos_\(trainingPoint.count)"
            let img:UIImage?  = UIImage(named: "blue.png")
            trainingPoint[nowPointName] = UIImageView(image: img)
            trainingPoint[nowPointName]!.center = touchPoint
            view.addSubview(trainingPoint[nowPointName]!)
            
            rssiArray.removeAll(keepCapacity: true)
        }
    }
    
    internal func onClickTrainingButton(sender: UIButton){
        if (mode == Mode.Wait) {
            // init training
            connector.connectionStart()
            initTrainingMode();
        } else {
            // end training
            mode = Mode.Wait
            
            disableTrainingStartButton()
            hideTouchPoint()
            
            analyzeButton.enabled = true;
            mainLabel.text = "touch training or analyze button";
        }
    }
    
    internal func onClickAnalyzeButton(sender: UIButton) {
        if (mode == Mode.Wait) {
            connector.connectionStart()
            
            analyzeStart()
        } else {
            mode = Mode.Wait
            
            analyzePointImageView.hidden = true
            
            // end analyze
            trainingButton.enabled = true
            mainLabel.text = "touch training or analyze button";
        }
    }
    
    internal func initTrainingMode() {
        mode = Mode.TrainingWait
        
        analyzeButton.enabled = false;
        trainingButton.enabled = true
        mainLabel.text = "touch training point and set iphone";
        trainingButton.setTitle("end training", forState: UIControlState.Normal)
    }
    
    func changeState(text: String) {
        connectionLabel.text = "connection: " + text
    }
    
    func sendServer(url: String) -> NSString {
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        // set the method(HTTP-GET)
        request.HTTPMethod = "GET"
        
        do {
            var response: NSURLResponse?
            let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
            
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let str:NSString = NSString(data:data, encoding: NSUTF8StringEncoding)!
                    return str
                }
            }
        } catch (let e) {
            print(e)
        }
        return ""
    }
    
    func deleteTrainingData() {
        let url = "\(TRAINING_URL)/delete"
        sendServer(url)
    }
    
    func sendTrainingData() -> Int {
        // create the url-request
        let rssiString = rssiArray.joinWithSeparator(",")
        let url = "\(TRAINING_URL)/training?tag=\(nowPointName)&data=\(rssiString)"
        
        NSLog("training \(rssiString)")
        
        let res = sendServer(url)
        if res == "" {
            return 0
        }else{
            return res.integerValue
        }
    }
    
    func training() {
        let ret = connector.getRSSI()
        if (ret.success) {
            rssiArray += ["\(ret.rssi)"]
            if (rssiArray.count == RSSI_VERTOR_LENGTH) {
                let count = sendTrainingData()
                mainLabel.text = "training(\(count)/\(TRAINING_COUNT))..."
                if (TRAINING_COUNT <= count) {
                    // end training
                    NSLog("end training \(nowPointName)")
                    endTraining()
                }
                rssiArray.removeFirst()
            }
        }
    }
    
    func endTraining() {
        trainingPoint[nowPointName]!.removeFromSuperview()
        
        let img:UIImage?  = UIImage(named: "green.png")
        trainingPoint[nowPointName] = UIImageView(image: img)
        trainingPoint[nowPointName]!.center = touchPoint
        view.addSubview(trainingPoint[nowPointName]!)
        
        initTrainingMode()
    }
    
    internal func analyzeStart() {
        mode = Mode.Analyze
        mainLabel.text = "analyze..."
        
        rssiArray.removeAll(keepCapacity: true)
    }
    
    func sendAnalyzeData() -> String {
        let rssiString = rssiArray.joinWithSeparator(",")
        let url = "\(TRAINING_URL)/analyze?data=\(rssiString)"
        
        let res = sendServer(url)
        return res as String
    }
    
    func analyze() {
        let ret = connector.getRSSI()
        if (ret.success) {
            rssiArray += ["\(ret.rssi)"]
            if (rssiArray.count == RSSI_VERTOR_LENGTH) {
                let pointName = sendAnalyzeData()
                
                if let point = trainingPoint[pointName]?.center {
                    analyzePointImageView.center = point
                    analyzePointImageView.hidden = false
                    view.bringSubviewToFront(analyzePointImageView)
                }
                
                rssiArray.removeFirst()
            }
        }
    }
    
    func onUpdate(timer: NSTimer) {
        switch mode {
        case Mode.Training:
            training()
            break
        case Mode.Analyze:
            analyze()
            break
        default:
            break
        }
    }
}

