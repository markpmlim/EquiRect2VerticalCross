//
//  Renderer.swift
//  EquiRect2Crossmaps
//
//  Created by Mark Lim Pak Mun on 18/05/2022.
//  Copyright © 2022 Mark Lim Pak Mun. All rights reserved.
//

import Foundation
import MetalKit


class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let mtkView: MTKView
    let commandQueue: MTLCommandQueue!

    var time: Float = 0.0

    var vertexDescriptor: MTLVertexDescriptor!
    var renderPipelineState: MTLRenderPipelineState!
    var renderPassDescriptor: MTLRenderPassDescriptor!

    var mtlTexture: MTLTexture!

    init(view: MTKView, device: MTLDevice) {
        self.mtkView = view
        self.device = device
        // Create a new command queue
        self.commandQueue = device.makeCommandQueue()

        super.init()
        // The file name of the .hdr image and the Bool flag "isHDR" must be set correctly.
        // The filename is case sensitive because it is stored in the Resources folder
        let name = "EquiRectImage.hdr"
        buildResources(with: name, isHDR: true)
        buildPipelineStates()
    }

    func buildResources(with name: String, isHDR: Bool) {
        let textureLoader = MTKTextureLoader(device: self.device)
        if isHDR {
            do {
                mtlTexture = try textureLoader.newTexture(fromRadianceFile: name)
            }
            catch let error as NSError {
                Swift.print("Can't load hdr file:\(error)")
                exit(1)
            }
        }
        else {
            let mainBundle = Bundle.main
            let components = name.components(separatedBy: ".")
            let url = mainBundle.url(forResource: components[0],
                                     withExtension: components[1])
            let options = [
                convertFromMTKTextureLoaderOption(MTKTextureLoader.Option.SRGB) : NSNumber(value: false),
                convertFromMTKTextureLoaderOrigin(MTKTextureLoader.Origin.bottomLeft): NSNumber(value: false),
            ]

            do {
                mtlTexture = try textureLoader.newTexture(URL: url!,
                                                          options: convertToOptionalMTKTextureLoaderOptionDictionary(options))
            }
            catch let error {
                Swift.print("Can't load image file:\(error)")
                exit(1)
            }
        }
   }

    func buildPipelineStates() {
        // Load all the shader files with a metal file extension in the project
        guard let library = device.makeDefaultLibrary()
        else {
            fatalError("Could not load default library from main bundle")
        }

        ////// Create the render pipeline state for the drawable render pass.
        // Set up a descriptor for creating a pipeline state object
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Render Quad Pipeline"
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "screen_vert")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "EquiRect2VerticalCross")

        pipelineDescriptor.sampleCount = mtkView.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        // The attributes of the vertices are generated on the fly.
        pipelineDescriptor.vertexDescriptor = nil

        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch {
            fatalError("Could not create render pipeline state object: \(error)")
        }
        
        // do an offscreen render to get a vertical cross cubemap if we want to save it as an image.
    }


    // called per frame update
    func draw(in view: MTKView) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "Render Drawable"
        if  let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable {
            // These 4 statements are not necessary.
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderEncoder.setRenderPipelineState(renderPipelineState)

            renderEncoder.setFragmentTexture(mtlTexture,
                                             index: 0)

            // The attributes of the vertices are generated on the fly.
            renderEncoder.drawPrimitives(type: .triangle,
                                         vertexStart: 0,
                                         vertexCount: 3)

            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }


    // Called whenever the view size changes
    func mtkView(_ view: MTKView,
                 drawableSizeWillChange size: CGSize) {
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromMTKTextureLoaderOption(_ input: MTKTextureLoader.Option) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromMTKTextureLoaderOrigin(_ input: MTKTextureLoader.Origin) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalMTKTextureLoaderOptionDictionary(_ input: [String: Any]?) -> [MTKTextureLoader.Option: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (MTKTextureLoader.Option(rawValue: key), value)})
}
