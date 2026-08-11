// badgepng <schedule.tsv> <outDir>
// Renders one PNG per keystroke badge (same pill look as overlay.swift) so the
// badges can be composited with ffmpeg's overlay filter instead of
// AVVideoCompositionCoreAnimationTool — that tool blacks out a variable-length
// head of the export (0.76s..1.56s depending on input length), which cannot be
// trimmed reliably.
import AppKit

let schedulePath = CommandLine.arguments[1]
let outDir = CommandLine.arguments[2]
let font = NSFont.systemFont(ofSize: 60, weight: .semibold)

let lines = try String(contentsOfFile: schedulePath, encoding: .utf8)
    .split(separator: "\n")

for (i, line) in lines.enumerated() {
    let parts = line.split(separator: "\t", maxSplits: 2).map(String.init)
    let label = parts[2]
    let attr = NSAttributedString(string: label, attributes: [
        .font: font, .foregroundColor: NSColor.white,
    ])
    let textSize = attr.size()
    let padH: CGFloat = 42, padV: CGFloat = 22
    let size = CGSize(width: ceil(textSize.width) + padH * 2,
                      height: ceil(textSize.height) + padV * 2)
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
    let cg = img.cgImage(forProposedRect: &proposed, context: nil, hints: nil)!
    let rep = NSBitmapImageRep(cgImage: cg)
    rep.size = size
    let data = rep.representation(using: .png, properties: [:])!
    let url = URL(fileURLWithPath: "\(outDir)/badge\(i).png")
    try data.write(to: url)
    print("badge\(i).png  \(Int(size.width))x\(Int(size.height))  \(label)")
}
