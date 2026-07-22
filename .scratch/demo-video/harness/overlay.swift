// overlay <input.mov> <schedule.tsv> <output.mov>
// Burns keystroke badges into the video. schedule.tsv: start\tend\tlabel
// (seconds, video-relative). Badge: dark pill, bottom-left, fade in/out.
import AVFoundation
import AppKit

let args = CommandLine.arguments
let asset = AVURLAsset(url: URL(fileURLWithPath: args[1]))
guard let track = asset.tracks(withMediaType: .video).first else { fatalError("no video track") }
let size = track.naturalSize

let comp = AVMutableComposition()
let vtrack = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
try vtrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: track, at: .zero)

let videoLayer = CALayer()
videoLayer.frame = CGRect(origin: .zero, size: size)
let parent = CALayer()
parent.frame = videoLayer.frame
parent.addSublayer(videoLayer)

let font = NSFont.systemFont(ofSize: 60, weight: .semibold)
let textColor = NSColor.white
let schedule = try String(contentsOfFile: args[2], encoding: .utf8)
    .split(separator: "\n").map { line -> (Double, Double, String) in
        let p = line.split(separator: "\t", maxSplits: 2).map(String.init)
        return (Double(p[0])!, Double(p[1])!, p[2])
    }

func badgeImage(_ label: String) -> (CGImage, CGSize) {
    let attr = NSAttributedString(string: label, attributes: [.font: font, .foregroundColor: textColor])
    let textSize = attr.size()
    let padH: CGFloat = 42, padV: CGFloat = 22
    let size = CGSize(width: ceil(textSize.width) + padH * 2, height: ceil(textSize.height) + padV * 2)
    let img = NSImage(size: size)
    img.lockFocus()
    let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
    let path = NSBezierPath(roundedRect: rect, xRadius: size.height / 2, yRadius: size.height / 2)
    NSColor(calibratedWhite: 0.08, alpha: 0.82).setFill()
    path.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.16).setStroke()
    path.lineWidth = 1.5
    path.stroke()
    attr.draw(at: CGPoint(x: padH, y: padV))
    img.unlockFocus()
    var proposed = CGRect(origin: .zero, size: size)
    return (img.cgImage(forProposedRect: &proposed, context: nil, hints: nil)!, size)
}

for (start, end, label) in schedule {
    let (image, bsize) = badgeImage(label)
    let pill = CALayer()
    pill.frame = CGRect(x: (size.width - bsize.width) / 2, y: 260, width: bsize.width, height: bsize.height)
    pill.contents = image
    pill.opacity = 0

    let fadeIn = CABasicAnimation(keyPath: "opacity")
    fadeIn.fromValue = 0; fadeIn.toValue = 1
    fadeIn.beginTime = AVCoreAnimationBeginTimeAtZero + start
    fadeIn.duration = 0.1
    fadeIn.fillMode = .forwards; fadeIn.isRemovedOnCompletion = false
    let fadeOut = CABasicAnimation(keyPath: "opacity")
    fadeOut.fromValue = 1; fadeOut.toValue = 0
    fadeOut.beginTime = AVCoreAnimationBeginTimeAtZero + max(start + 0.15, end - 0.25)
    fadeOut.duration = 0.25
    fadeOut.fillMode = .forwards; fadeOut.isRemovedOnCompletion = false
    pill.add(fadeIn, forKey: "in"); pill.add(fadeOut, forKey: "out")
    parent.addSublayer(pill)
}

let vc = AVMutableVideoComposition(propertiesOf: comp)
vc.renderSize = size
vc.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parent)

let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetHighestQuality)!
export.outputURL = URL(fileURLWithPath: args[3])
export.outputFileType = .mov
export.videoComposition = vc
try? FileManager.default.removeItem(atPath: args[3])
let sem = DispatchSemaphore(value: 0)
export.exportAsynchronously { sem.signal() }
sem.wait()
if export.status != .completed { fatalError("export failed: \(String(describing: export.error))") }
print("ok \(args[3])")
