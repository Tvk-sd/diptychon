// gulfs <out.mp4>
// Motion-graphic explainer for the Substack post "Legibility beats speed".
//
// Bar semantics (Till's correction): a bar measures how far a gulf is CLOSED.
// 100% = closed = that half of the action is complete. So the story is:
// present both at 50%, reset to 0, execution snaps to 100% almost instantly,
// evaluation lags and stalls, a status cue lands and closes it to 100%.
// The earlier version had this inverted (bars grew as the gulf widened), which
// also bunched all captions at the end.
//
// Style follows Diptychon: rectangular, boxed, left-aligned on a grid, hairline
// separators, right-aligned value column. No rounded pills. Palette sampled from
// the product (pane #1d1d1d, chrome #1a1a1a, selection #0373ff, marker ≈#313131).
import AVFoundation
import AppKit

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "gulfs.mp4"
let W = 1920, H = 1080
let FPS = 30.0
let DURATION = 11.6

// MARK: palette
func c(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}
let bg = c(0x1a1a1a), paneBG = c(0x1d1d1d)
let hairline = c(0xffffff, 0.09)
let track = c(0xffffff, 0.06)
let fill = c(0x0373ff)
let marker = c(0x313131)
let textPrimary = c(0xf2f2f2), textSecondary = c(0x8a8a8a), textDim = c(0x6e6e6e)

// MARK: easing
func clamp01(_ x: Double) -> Double { min(max(x, 0), 1) }
func ease(_ x: Double) -> Double { let t = clamp01(x); return t * t * (3 - 2 * t) }
func seg(_ t: Double, _ a: Double, _ b: Double) -> Double { ease((t - a) / (b - a)) }
/// fade in over [a,b], hold, fade out over [c,d]
func window(_ t: Double, _ a: Double, _ b: Double, _ cc: Double, _ d: Double) -> Double {
    min(seg(t, a, b), 1 - seg(t, cc, d))
}
func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

// MARK: drawing
func font(_ size: CGFloat, _ w: NSFont.Weight = .regular) -> NSFont {
    .systemFont(ofSize: size, weight: w)
}
func monoFont(_ size: CGFloat, _ w: NSFont.Weight = .regular) -> NSFont {
    .monospacedDigitSystemFont(ofSize: size, weight: w)
}
func draw(_ s: String, at p: CGPoint, font f: NSFont, color: NSColor,
          alpha: Double, align: NSTextAlignment = .left, tracking: CGFloat = 0) {
    guard alpha > 0.004 else { return }
    var attrs: [NSAttributedString.Key: Any] = [
        .font: f, .foregroundColor: color.withAlphaComponent(color.alphaComponent * alpha),
    ]
    if tracking != 0 { attrs[.kern] = tracking }
    let a = NSAttributedString(string: s, attributes: attrs)
    var x = p.x
    if align == .right { x = p.x - a.size().width }
    a.draw(at: CGPoint(x: x, y: p.y))
}
func rect(_ ctx: CGContext, _ r: CGRect, _ color: NSColor, _ alpha: Double) {
    guard alpha > 0.004, r.width > 0.4, r.height > 0.4 else { return }
    ctx.setFillColor(color.withAlphaComponent(color.alphaComponent * alpha).cgColor)
    ctx.fill(r)
}

// MARK: layout grid — everything hangs off these edges
let GX = 360.0, GW = 1200.0          // content box
let GR = GX + GW                     // right edge (value column)
let PAD = 28.0
let LABEL_X = GX + PAD
let BAR_X = GX + 260.0
let BAR_W = 700.0
let BAR_H = 20.0
let VALUE_X = GR - PAD
let BOX_Y = 370.0, HEAD_H = 52.0
let ROW1 = 458.0, ROW2 = 602.0       // label baselines
let BOX_H = 396.0

func renderFrame(_ ctx: CGContext, t: Double) {
    ctx.setFillColor(bg.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

    // ---- title, left-aligned to the grid
    let titleA = seg(t, 0.2, 0.9)
    draw("Every action crosses two gulfs", at: CGPoint(x: GX, y: 252),
         font: font(46, .semibold), color: textPrimary, alpha: titleA)
    draw("Don Norman · The Design of Everyday Things", at: CGPoint(x: GX, y: 314),
         font: font(21), color: textSecondary, alpha: titleA * 0.9)

    // ---- panel
    let boxA = seg(t, 0.9, 1.6)
    rect(ctx, CGRect(x: GX, y: BOX_Y, width: GW, height: BOX_H), paneBG, boxA)
    // hairline frame
    rect(ctx, CGRect(x: GX, y: BOX_Y, width: GW, height: 1), hairline, boxA)
    rect(ctx, CGRect(x: GX, y: BOX_Y + BOX_H - 1, width: GW, height: 1), hairline, boxA)
    rect(ctx, CGRect(x: GX, y: BOX_Y, width: 1, height: BOX_H), hairline, boxA)
    rect(ctx, CGRect(x: GR - 1, y: BOX_Y, width: 1, height: BOX_H), hairline, boxA)
    // column header strip, like the file list
    draw("GULF", at: CGPoint(x: LABEL_X, y: BOX_Y + 18),
         font: font(15, .medium), color: textDim, alpha: boxA, tracking: 1.2)
    draw("CLOSED", at: CGPoint(x: VALUE_X, y: BOX_Y + 18),
         font: font(15, .medium), color: textDim, alpha: boxA, align: .right, tracking: 1.2)
    rect(ctx, CGRect(x: GX, y: BOX_Y + HEAD_H, width: GW, height: 1), hairline, boxA)
    // row separator
    rect(ctx, CGRect(x: GX, y: ROW2 - 44, width: GW, height: 1), hairline, boxA * 0.8)

    // ---- bar values. A bar measures how far the gulf is CLOSED.
    //  present at 50% → reset to 0 → execution snaps shut → evaluation lags →
    //  cue lands → evaluation snaps shut.
    let execFrac = lerp(0, 0.5, seg(t, 1.9, 2.6))
        + lerp(0, -0.5, seg(t, 3.2, 3.7))
        + lerp(0, 1.0, seg(t, 4.2, 4.45))          // instant
    let evalFrac = lerp(0, 0.5, seg(t, 2.1, 2.8))
        + lerp(0, -0.5, seg(t, 3.2, 3.7))
        + lerp(0, 0.22, seg(t, 4.4, 6.2))          // crawls, then stalls
        + lerp(0, 0.78, seg(t, 8.6, 9.1))          // the cue closes it

    let rowsA = seg(t, 1.6, 2.2)

    func gulfRow(_ y: Double, _ name: String, _ question: String, _ frac: Double) {
        draw(name, at: CGPoint(x: LABEL_X, y: y),
             font: font(22, .semibold), color: textPrimary, alpha: rowsA, tracking: 0.8)
        draw(question, at: CGPoint(x: LABEL_X, y: y + 34),
             font: font(18), color: textDim, alpha: rowsA)
        rect(ctx, CGRect(x: BAR_X, y: y + 4, width: BAR_W, height: BAR_H), track, rowsA)
        rect(ctx, CGRect(x: BAR_X, y: y + 4, width: BAR_W * frac, height: BAR_H), fill, rowsA)
        draw("\(Int((frac * 100).rounded()))%", at: CGPoint(x: VALUE_X, y: y),
             font: monoFont(22, .medium), color: textPrimary, alpha: rowsA, align: .right)
    }
    gulfRow(ROW1, "EXECUTION", "how do I do this?", execFrac)
    gulfRow(ROW2, "EVALUATION", "did it work, and where am I now?", evalFrac)

    // ---- captions, left-aligned to the same grid, one at a time
    func caption(_ s: String, _ a: Double, _ b: Double, _ cc: Double, _ d: Double) {
        draw(s, at: CGPoint(x: GX, y: 818), font: font(30, .medium),
             color: c(0xcfcfcf), alpha: window(t, a, b, cc, d))
    }
    caption("Both have to close before the action is done.", 2.2, 2.7, 3.0, 3.4)
    caption("An action begins. Both open again.", 3.4, 3.8, 4.0, 4.3)
    caption("Execution closes instantly.", 4.4, 4.8, 5.9, 6.3)
    caption("Evaluation stays open. Nothing said where you landed.", 6.4, 6.8, 8.4, 8.8)
    // last caption holds to the end: no fade to an empty frame in the GIF loop
    draw("A status cue closes it.", at: CGPoint(x: GX, y: 818),
         font: font(30, .medium), color: c(0xcfcfcf), alpha: seg(t, 8.4, 8.8))

}

// MARK: writer
try? FileManager.default.removeItem(atPath: outPath)
let writer = try AVAssetWriter(outputURL: URL(fileURLWithPath: outPath), fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: W, AVVideoHeightKey: H,
    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 7_000_000],
])
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: input,
    sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
        kCVPixelBufferWidthKey as String: W, kCVPixelBufferHeightKey as String: H,
    ])
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

let space = CGColorSpaceCreateDeviceRGB()
let total = Int(DURATION * FPS)
for i in 0..<total {
    while !input.isReadyForMoreMediaData { usleep(2000) }
    var pb: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
    guard let buf = pb else { fatalError("no pixel buffer") }
    CVPixelBufferLockBaseAddress(buf, [])
    let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buf), width: W, height: H,
                        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buf),
                        space: space,
                        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                            | CGBitmapInfo.byteOrder32Little.rawValue)!
    // flip to top-left origin so all layout numbers read like a design spec
    ctx.translateBy(x: 0, y: CGFloat(H))
    ctx.scaleBy(x: 1, y: -1)
    let prev = NSGraphicsContext.current
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
    renderFrame(ctx, t: Double(i) / FPS)
    NSGraphicsContext.current = prev
    CVPixelBufferUnlockBaseAddress(buf, [])
    adaptor.append(buf, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: CMTimeScale(FPS)))
}
input.markAsFinished()
let sem = DispatchSemaphore(value: 0)
writer.finishWriting { sem.signal() }
sem.wait()
if writer.status != .completed { fatalError("export failed: \(String(describing: writer.error))") }
print("ok \(outPath)")
