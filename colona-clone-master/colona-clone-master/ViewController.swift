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
}

class ViewController: UIViewController {
    @IBOutlet weak var trainingButton: UIButton!
    @IBOutlet weak var analyzeButton: UIButton!
    @IBOutlet weak var mainLabel: UILabel!

    var mode = Mode.Wait

    override func viewDidLoad() {
        super.viewDidLoad()

        trainingButton.addTarget(self, action: "onClickTrainingButton:", forControlEvents: .TouchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (mode == Mode.TrainingWait) {
            if let touch = touches.first {
                let point = touch.locationInView(view)
                NSLog("%f %f", point.x, point.y)

            }
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
        mainLabel.text = "touch training point...";
        trainingButton.setTitle("end training", forState: UIControlState.Normal)
    }


}

