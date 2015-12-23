# Corona-clone

*This software' algolithm is only a part of original algorithm.*
*So this is very poor accuracy.*

This is [Corona: Positioning Adjacent Device with Asymmetric Bluetooth Low Energy RSSI Distributions](http://dl.acm.org/citation.cfm?doid=2807442.2807485)'s clone.

I don't implement original algorithm, but while not the same as the original , it becomes sufficient accuracy to test.


# How to use

- Launch server
- Write your server adress to `corona-clone-master/corona-clone-master/ViewController.swift`
- Change bundle identifer.
- Build corona-clone-master and install iPad.
- Build corona-clone-slave and install iPhone.
- Training positions.
- Start analyze


# Setup server
requires

- python 3 (I checked 3.5)
- scikit (http://scikit-learn.org/stable/install.html)
