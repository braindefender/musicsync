//
//  UIButton+Square.swift
//  Music Sync
//
//  Created by Никита Широков on 01/11/2017.
//  Copyright © 2017 Ink Studios. All rights reserved.
//

import UIKit

class UIButtonSquare: UIButton {
    
    //MARK: - General Appearance
    @IBInspectable open var cornerRadius: CGFloat = 0{
        didSet{
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable open var borderWidth: CGFloat = 0{
        didSet{
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable open var borderColor: UIColor = UIColor.clear{
        didSet{
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
}
