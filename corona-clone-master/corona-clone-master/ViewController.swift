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

enum Seq {
    case None
    case Send
    case Ret
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
    
    var sequence = Seq.None
    var returnValue = ""
    
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
        sequence = Seq.None
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
            trainingButton.setTitle("Training", forState: UIControlState.Normal)
        }
    }
    
    internal func onClickAnalyzeButton(sender: UIButton) {
        sequence = Seq.None
        if (mode == Mode.Wait) {
            connector.connectionStart()
            
            analyzeStart()
        } else {
            mode = Mode.Wait
            analyzePointImageView.hidden = true
            
            // end analyze
            trainingButton.enabled = true
            mainLabel.text = "touch training or analyze button";
            analyzeButton.setTitle("Analyze", forState: UIControlState.Normal)
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
    
    func sendServer(url: String) {
        sequence = Seq.Send
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        let req = NSURLRequest(URL: NSURL(string: url)!)
        
        //NSURLSessionDownloadTask is retured from session.dataTaskWithRequest
        let task = session.dataTaskWithRequest(req, completionHandler: {
            (data, resp, err) in
            
            if let httpResponse = resp as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.returnValue = NSString(data:data!, encoding: NSUTF8StringEncoding)! as String
                }
            }
            
            self.sequence = Seq.Ret
        })
        task.resume()
    }
    
    func deleteTrainingData() {
        let url = "\(TRAINING_URL)/delete"
        sendServer(url)
    }
    
    func sendTrainingData() {
        // create the url-request
        let rssiString = rssiArray.joinWithSeparator(",")
        let url = "\(TRAINING_URL)/training?tag=\(nowPointName)&data=\(rssiString)"
        
        NSLog("training \(rssiString)")
        
        sendServer(url)
    }
    
    func training() {
        if (sequence == Seq.None) {
            let ret = connector.getRSSI()
            if (ret.success) {
                rssiArray += ["\(ret.rssi)"]
                if (rssiArray.count == RSSI_VERTOR_LENGTH) {
                    sendTrainingData()
                }
            }
        }else if (sequence == Seq.Ret) {
            sequence = Seq.None
            
            let count = Int(returnValue)
            mainLabel.text = "training(\(count)/\(TRAINING_COUNT))..."
            if (TRAINING_COUNT <= count) {
                // end training
                NSLog("end training \(nowPointName)")
                endTraining()
            }
            rssiArray.removeFirst()
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
        trainingButton.enabled = false

        mode = Mode.Analyze
        mainLabel.text = "analyze..."
        analyzeButton.setTitle("end analyze", forState: UIControlState.Normal) ;
        
        rssiArray.removeAll(keepCapacity: true)
    }
    
    func sendAnalyzeData() {
        let rssiString = rssiArray.joinWithSeparator(",")
        let url = "\(TRAINING_URL)/analyze?data=\(rssiString)"
        sendServer(url)
    }
    
    func analyze() {
        if (sequence == Seq.None) {
            let ret = connector.getRSSI()
            if (ret.success) {
                rssiArray += ["\(ret.rssi)"]
                if (rssiArray.count == RSSI_VERTOR_LENGTH) {
                    sendAnalyzeData()
                }
            }
        }else{
            sequence = Seq.None
            
            if let point = trainingPoint[returnValue]?.center {
                analyzePointImageView.center = point
                analyzePointImageView.hidden = false
                view.bringSubviewToFront(analyzePointImageView)
            }
            
            rssiArray.removeFirst()
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

