//
//  PopImageViewController.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/6/25.
//  Copyright © 2020 Mike. All rights reserved.
//

import UIKit

class PopImageViewController: UIViewController {

    @IBOutlet weak var popImage: UIImageView!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let image = image{
            popImage.image = image
            self.preferredContentSize = image.size
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
