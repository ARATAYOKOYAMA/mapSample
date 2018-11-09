//
//  ViewController.swift
//  MapTest
//
//  Created by 横山新 on 2018/11/10.
//  Copyright © 2018年 aratayokoyama. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    lazy var mapView: MKMapView = {
        let mapView = MKMapView(frame: view.frame)
        return mapView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
    }
}

