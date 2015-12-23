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
}

class ViewController: UIViewController, BluetoothStateDelegate {
    @IBOutlet weak var trainingButton: UIButton!
    @IBOutlet weak var analyzeButton: UIButton!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var trainingStartButton: UIButton!
    @IBOutlet weak var connectionLabel: UILabel!

    var mode = Mode.Wait

    var nowPointName = ""

    var touchPoint: CGPoint!
    var touchPointImageView: UIImageView!
    var connector = BluetoothConnector()

    var RSSI_VERTOR_LENGTH = 10 //
    var trainingCount = 0
    var rssiArray: [Double] = []

    var trainingPoint = Dictionary<String, UIImageView>()

    override func viewDidLoad() {
        super.viewDidLoad()

        connector.createManager(self)

        touchPoint = CGPoint.zero;

        let img:UIImage?  = UIImage(named: "blue.png")
        touchPointImageView = UIImageView(image: img)
        view.addSubview(touchPointImageView)
        touchPointImageView.hidden = true

        trainingButton.addTarget(self, action: "onClickTrainingButton:", forControlEvents: .TouchUpInside)

        trainingStartButton.addTarget(self, action: "onClickTrainingStartButton:", forControlEvents: .TouchUpInside)
        disableTrainingStartButton()

        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("onUpdate:"), userInfo: nil, repeats: true)
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
            connector.connectionStart()
        }
    }

    internal func onClickTrainingButton(sender: UIButton){
        if (mode == Mode.Wait) {
            // init training
            initTrainingMode();
        } else {
            // end training
            analyzeButton.enabled = true;
            mainLabel.text = "touch training button or ";
        }
    }

    internal func initTrainingMode() {
        mode = Mode.TrainingWait

        analyzeButton.enabled = false;
        mainLabel.text = "touch training point and set iphone";
        trainingButton.setTitle("end training", forState: UIControlState.Normal)
    }

    func changeState(text: String) {
        connectionLabel.text = "connection: " + text
    }

    func sendTrainingData() {
        NSLog("\(rssiArray)")
    }

    func training() {
        let ret = connector.getRSSI()
        if (ret.success) {
            rssiArray += [ret.rssi]
            if (rssiArray.count == RSSI_VERTOR_LENGTH) {
                sendTrainingData()
                rssiArray.removeFirst()
            }
        }
    }

    func onUpdate(timer: NSTimer) {
        switch mode {
        case Mode.Training:
            training()
            break
        default:
            break
        }
    }
}

