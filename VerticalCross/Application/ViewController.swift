//
//  ViewController.swift
//  EquiRect2Crossmaps
//
//  Created by Mark Lim Pak Mun on 08/07/2022.
//  Copyright © 2022 Mark Lim Pak Mun. All rights reserved.

#if os(iOS)
import UIKit
typealias NSUIViewController = UIViewController
#else
import Cocoa
typealias NSUIViewController = NSViewController
#endif
import MetalKit

@available(OSX 10.13.4, *)
class ViewController: NSUIViewController {
    var mtkView: MTKView!

    var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let mtkView = self.view as? MTKView
        else {
            print("View of Gameview controller is not an MTKView")
            return
        }
        // The view seems to have been instantiated w/o a "device" property.
        guard let device = MTLCreateSystemDefaultDevice()
        else {
            print("Metal is not supported")
            return
        }
        mtkView.device = device
        // Configure
        mtkView.colorPixelFormat = .rgba16Float
        // A depth buffer is required
        renderer = Renderer(view: mtkView,
                            device: device)
        mtkView.delegate = renderer     // this is necessary.

        let size = mtkView.drawableSize
        // Ensure the view and projection matrices are setup
        renderer.mtkView(mtkView,
                         drawableSizeWillChange: size)
    }

#if os(macOS)
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func viewDidAppear() {
        self.mtkView.window!.makeFirstResponder(self)
    }
#else
#endif
}


