//
//  ViewController.swift
//  FFPhotosLibrary
//
//  Created by cchengfei@outlook.com on 08/25/2022.
//  Copyright (c) 2022 cchengfei@outlook.com. All rights reserved.
//

import UIKit
import FFPhotosLibrary

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let config = FFPhotosConfig.init()
        let vc = FFPhotosViewController.init(config: config, delegate: self, mediaType: .image)
        vc.view.frame = self.view.frame
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: FFPhotosProtocol {
    func didSelectedItem(model: FFAssetItem, selectedDataSource: [FFAssetItem]) {
            
    }
    
    func didSelectedDone(selectedDataSource: [FFAssetItem]) {
        
    }
    
    func didPrewItem(model: FFAssetItem, selectedDataSource: [FFAssetItem], allDataSource: [FFAssetItem]) {
        
    }
    
    
}

