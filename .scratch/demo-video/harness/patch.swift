// patch <base.png> <donor.png> <out.png> x y w h [x y w h ...]
// Copies rectangles (top-left origin, pixels) from the donor onto the base.
// Used to swap a pane that came out wrong in one shot with the same pane
// from a clean shot of the same window size.
import AppKit
import ImageIO
import UniformTypeIdentifiers

func load(_ p: String) -> CGImage {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: p) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("cannot read \(p)") }
    return img
}
let a = CommandLine.arguments
let base = load(a[1]), donor = load(a[2])
precondition(base.width == donor.width && base.height == donor.height, "size mismatch")
let W = base.width, H = base.height
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                    space: base.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(base, in: CGRect(x: 0, y: 0, width: W, height: H))
var i = 4
while i + 3 < a.count {
    let x = Int(a[i])!, y = Int(a[i+1])!, w = Int(a[i+2])!, h = Int(a[i+3])!
    let crop = donor.cropping(to: CGRect(x: x, y: y, width: w, height: h))!
    ctx.draw(crop, in: CGRect(x: x, y: H - y - h, width: w, height: h))
    i += 4
}
let out = ctx.makeImage()!
let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[3]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dst, out, nil)
precondition(CGImageDestinationFinalize(dst), "write failed")
print("wrote \(a[3]) \(W)x\(H)")
