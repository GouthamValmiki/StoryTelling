import SwiftUI
import Combine
import PDFKit

enum PDFService {
    @MainActor
    static func generatePDF(for story: Story, language: AppLanguage) -> URL? {
        let pdfMeta = [
            kCGPDFContextCreator: Constants.appName,
            kCGPDFContextTitle: story.localizedTitle(lang: language)
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMeta as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { ctx in
            // Cover
            ctx.beginPage()
            drawCover(story: story, language: language, rect: pageRect)
            // Pages
            for page in story.pages {
                ctx.beginPage()
                drawPage(page: page, language: language, rect: pageRect)
            }
            // Final
            ctx.beginPage()
            drawFinal(story: story, rect: pageRect)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(story.id).pdf")
        try? data.write(to: url)
        return url
    }

    private static func drawCover(story: Story, language: AppLanguage, rect: CGRect) {
        UIColor(hex: "1A1033").setFill()
        UIRectFill(rect)

        let title = story.localizedTitle(lang: language) as NSString
        let desc = story.localizedDescription(lang: language) as NSString
        let emoji = story.coverEmoji as NSString

        let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 32, weight: .bold), .foregroundColor: UIColor.white]
        let descAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.white.withAlphaComponent(0.8)]

        emoji.draw(at: CGPoint(x: rect.midX-30, y: 180), withAttributes: [.font: UIFont.systemFont(ofSize: 60)])
        title.draw(in: CGRect(x: 30, y: 280, width: rect.width-60, height: 80), withAttributes: titleAttrs)
        desc.draw(in: CGRect(x: 30, y: 370, width: rect.width-60, height: 100), withAttributes: descAttrs)

        let footer = "WonderTales • \(story.category.rawValue) • \(story.readingTimeText)" as NSString
        footer.draw(in: CGRect(x: 30, y: rect.height-80, width: rect.width-60, height: 20), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.white.withAlphaComponent(0.6)])
    }

    private static func drawPage(page: StoryPage, language: AppLanguage, rect: CGRect) {
        UIColor.white.setFill()
        UIRectFill(rect)
        let text = (language == .telugu ? (page.textTe ?? page.text) : page.text) as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .regular), .foregroundColor: UIColor.darkText]
        let emoji = "📖" as NSString
        emoji.draw(at: CGPoint(x: rect.midX-20, y: 60), withAttributes: [.font: UIFont.systemFont(ofSize: 40)])
        let pageNum = "Page \(page.index+1)" as NSString
        pageNum.draw(at: CGPoint(x: rect.midX-30, y: 110), withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.gray])
        text.draw(in: CGRect(x: 40, y: 160, width: rect.width-80, height: rect.height-220), withAttributes: attrs)
    }

    private static func drawFinal(story: Story, rect: CGRect) {
        UIColor(hex: "1A1033").setFill()
        UIRectFill(rect)
        let msg = "And they lived happily ever after ✨" as NSString
        msg.draw(in: CGRect(x: 30, y: rect.midY-40, width: rect.width-60, height: 40), withAttributes: [.font: UIFont.systemFont(ofSize: 22, weight: .bold), .foregroundColor: UIColor.white])
        let sub = "You completed \(story.title)!" as NSString
        sub.draw(in: CGRect(x: 30, y: rect.midY+10, width: rect.width-60, height: 30), withAttributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.white.withAlphaComponent(0.8)])
    }
}

private extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF)/255
        let g = CGFloat((rgb >> 8) & 0xFF)/255
        let b = CGFloat(rgb & 0xFF)/255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
