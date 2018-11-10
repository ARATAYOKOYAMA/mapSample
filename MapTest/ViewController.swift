//
//  ViewController.swift
//  MapTest
//
//  Created by 横山新 on 2018/11/10.
//  Copyright © 2018年 aratayokoyama. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var nowPlaceButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var infoView: UIView!

    // 上にかぶさるviewを表示するか否かのflag
    private var viewflag = true
    // 現在地にフォーカスするか否かのflag
    private var focusFlag = true

    // GPSを扱うため
    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        initMap: do {
            locationManager.delegate = self
            map.delegate = self
        }
        initView: do {
            // 上にかぶさるviewの角を丸くする 2行目はiOS11以上のみ動作
            infoView.layer.cornerRadius = 30
            infoView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            infoView.clipsToBounds = true
        }
        initPin: do {
            let pin = MKPointAnnotation()
            pin.coordinate = CLLocationCoordinate2D(latitude: 41.841519, longitude: 140.766969)
            pin.title = "大学"
            map.addAnnotation(pin)

            // TODO: 本来は複数のピンを指す
//            var annotationArray: [MKAnnotation] = []
//            for coordinate in coordinateArray! {
//                　　　　　　　　let annotation = MKPointAnnotation()
//                annotation.coordinate = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)
//                annotationArray.append(annotation)
//            }
//            self.mapView.addAnnotations(annotationArray)
        }
    }

    // MARK: タッチイベントが終了した後に呼ばれる
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        // 閾値は上にかぶさるviewの中心から上にかぶさるviewの高さ/4の位置
        let threshold = UIScreen.main.bounds.size.height - self.infoView.bounds.height / 4 - (self.tabBarController?.tabBar.frame.size.height)!
        if self.infoView.center.y < threshold {
            appearInfoView()
            return
        }

        hiddenInfoView()
    }

    // MARK: タッチイベント中に呼ばれる
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        // 上にかぶさるviewより上の位置でタッチされたものは無効とする
        guard touches.first!.previousLocation(in: infoView).y > 0 else {
            return
        }

        // 移動量
        let diff = touches.first!.previousLocation(in: infoView).y - touches.first!.location(in: infoView).y

        // 必要以上に上にいかないように，移動量込みで上にかぶさるviewのtopを上回っていることに限定
        guard self.infoView.frame.origin.y - diff >= UIScreen.main.bounds.size.height - self.infoView.bounds.height - (self.tabBarController?.tabBar.frame.size.height)! else {
            return
        }

        // ボタンとviewの位置を変更 origin.size.yだと，残像が残る？ためcenterで行う
        self.infoView.center.y -= diff
        self.nowPlaceButton.center.y -= diff
    }

    // MARK: ピンをタップしたら呼ばれる
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if viewflag {
            // タップしたピンが上にかぶさるviewに隠れるようなら，画面の中心を変更する
            if view.center.y > self.map.frame.height - self.infoView.frame.height {
                focusPlace(center: (view.annotation?.coordinate)!)
            }
            // containerview
            let targetVC = children[0] as! InfoView
            targetVC.shopName.text = (view.annotation?.title)!
            appearInfoView()
        }
    }

    // MARK: 地図上のどこをタップしても呼ばれる
    @IBAction func toHideInfoView(_ sender: Any) {
        if viewflag != true {
            hiddenInfoView()
        }
    }

    // MARK: 現在地にフォーカス
    @IBAction func toNowPlace(_ sender: Any) {
        focusFlag = true
    }

    // MARK: 上にかぶさるviewを表示する
    private func appearInfoView() {
        UIView.animate(
            withDuration: 0.5, //　アニメーションの秒数
            delay: 0.0, // 0秒後に開始
            options: .curveEaseInOut,
            animations: {
                // 上にかぶさるviewのtop 60はボタンとviewのマージン
                self.infoView.center.y = UIScreen.main.bounds.size.height - self.infoView.bounds.height / 2 - (self.tabBarController?.tabBar.frame.size.height)!
                self.nowPlaceButton.center.y = UIScreen.main.bounds.size.height - self.infoView.bounds.height - (self.tabBarController?.tabBar.frame.size.height)! - 60
            }, completion: { (finished: Bool) in
                self.viewflag = false
            })
    }

    // MARK: 上にかぶさるviewを隠す
    private func hiddenInfoView() {
        UIView.animate(
            withDuration: 0.5, //　アニメーションの秒数
            delay: 0.0, // 0秒後に開始
            options: .curveEaseInOut,
            animations: {
                // 上にかぶさるviewのtop 60はボタンとviewのマージン
                self.infoView.center.y = UIScreen.main.bounds.size.height + self.infoView.bounds.height / 2 - (self.tabBarController?.tabBar.frame.size.height)!
                self.nowPlaceButton.center.y = UIScreen.main.bounds.size.height - (self.tabBarController?.tabBar.frame.size.height)! - 60
            }, completion: { (finished: Bool) in
                self.viewflag = true
            })
    }
}

extension ViewController: CLLocationManagerDelegate {

    // MARK: GPSの使用許諾
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    // MARK: GPSが更新されるたびに呼ばれる
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = locations.last?.coordinate {

            guard focusFlag == true else {
                return
            }

            focusNowPlace(center: coordinate)
        }
    }

    // MARK: 現在にフォーカス
    private func focusNowPlace(center: CLLocationCoordinate2D) {
        // 現在地を拡大して表示する
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: center, span: span)
        map.region = region

        focusFlag = false
    }

    // MARK: 指定した場所にフォーカス
    private func focusPlace(center: CLLocationCoordinate2D) {
        // 現在地を拡大して表示する
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: center, span: span)
        map.region = region

    }
}
