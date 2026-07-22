// frames <movie> <outPrefix> <t1> <t2> ... — dump JPEG frames at given seconds
import AVFoundation
import AppKit

let args = CommandLine.arguments
let asset = AVURLAsset(url: URL(fileURLWithPath: args[1]))
let gen = AVAssetImageGenerator(asset: asset)
gen.requestedTimeToleranceBefore = .init(seconds: 0.15, preferredTimescale: 600)
gen.requestedTimeToleranceAfter = .init(seconds: 0.15, preferredTimescale: 600)
print("duration:", CMTimeGetSeconds(asset.duration))
for t in args[3...] {
    let time = CMTime(seconds: Double(t)!, preferredTimescale: 600)
    let cg = try gen.copyCGImage(at: time, actualTime: nil)
    let rep = NSBitmapImageRep(cgImage: cg)
    let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.75])!
    try data.write(to: URL(fileURLWithPath: "\(args[2])-\(t)s.jpg"))
}
print("ok")
