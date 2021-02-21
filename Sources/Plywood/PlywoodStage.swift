import SwiftWayland
import SwiftWLR

private let stagePadding = 56.0
private let stageSpacing = 24.0
private let crossAxisFactor = 0.9

final class PlywoodStage {
    var toplevelViews: [[PlywoodView]] = []
    var focusedRowIndex: Int = 0

    private let state: PlywoodState

    private var lastHeight: Int32 = 0

    init(state: PlywoodState) {
        self.state = state
    }

    func insert(_ view: PlywoodView) {
        if toplevelViews.isEmpty {
            toplevelViews.append([])
        }

        var views = toplevelViews[focusedRowIndex]

        // Set size of view to "end" of queue.
        if views.isEmpty {
            // Set initial x to stage padding.
            view.position = (x: stagePadding, y: 0)
        } else {
            let lastView: PlywoodView = views.last!
            let offsetX: Double = lastView.position.x + Double(lastView.area.width) + stageSpacing

            view.position = (x: offsetX, y: 0)
        }

        views.append(view)
        self.centerView(view, height: lastHeight)

        toplevelViews[focusedRowIndex] = views
        state.logger.info("Inserted window to stage")
    }

    func remove(_ view: PlywoodView) {
        if toplevelViews.isEmpty {
            return
        }

        for i in 0..<toplevelViews.count {
            let views = toplevelViews[i]
            let index = views.firstIndex(where: { $0 === view })

            if index != nil {
                let view = views[index!]

                var offsetX: Double = Double(view.area.width) + stageSpacing
                // Make sure the new "first" item is aligned correctly.
                if index == 0 && views.count > 1 {
                    let secondView = views[1]
                    let secondViewNewX = secondView.position.x - offsetX

                    if secondViewNewX < stagePadding {
                        offsetX -= (stagePadding - secondViewNewX)
                    }
                }

                toplevelViews[i].remove(at: index!)

                // Reflow all views after this index.
                for j in (index!)..<(views.count - 1) {
                    toplevelViews[i][j].position.x -= offsetX
                }
                break
            }
        }
    }

    func focus(_ view: PlywoodView) {

    }

    func render(output: WLROutput, screenOffsetX: Int, resolution: Area) {
        if toplevelViews.isEmpty {
            return
        }

        // Cover edge case to make sure we always have a height.
        if lastHeight == 0 {
            updateCrossAxis(height: resolution.height)
        }

        for view in toplevelViews[focusedRowIndex] {
            view.forEachSurface { surface, position in
                // Quick return if occluded.
                if position.x > resolution.width {
                    return
                }

                view.render(surface: surface, output: output, position: position)
            }
        }
    }

    func findView(at position: Point) -> (
        view: PlywoodView,
        surface: WLRSurface,
        coordinates: Point
    )? {
        if toplevelViews.isEmpty {
            return nil
        }

        for view in toplevelViews[focusedRowIndex] {
            if let result = view.findSurface(at: position) {
                return (
                    view: view,
                    surface: result.surface,
                    coordinates: result.coordinates
                )
            }
        }

        return nil
    }

    // FIXME: For now, this always assumes rows go horizontally.
    func updateCrossAxis(height: Int32) {
        // Quick return if our height hasn't changed but we were still (?) notified.
        if lastHeight == height {
            return
        }
        lastHeight = height

        // FIXME: Do other rows? Lazy or all right now to be decided.
        if toplevelViews.isEmpty {
            return
        }

        for view in toplevelViews[focusedRowIndex] {
            self.centerView(view, height: height)
        }
    }

    private func centerView(_ view: PlywoodView, height: Int32) {
        if height == 0 {
            return
        }

        let areaHeight = Int32(Double(height) * crossAxisFactor)

        view.position = (x: view.position.x, y: Double(height) * (1 - crossAxisFactor) / 2)
        view.area = (width: view.area.width, height: areaHeight)
    }
}