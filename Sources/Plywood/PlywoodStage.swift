import SwiftWayland
import SwiftWLR

import TweenKit

final class PlywoodStage {
    var toplevelViews: [[PlywoodView]] = []
    var focusedRowIndex: Int = 0
    var columnIndexOffsets: [(index: Int, x: Int32)] = []

    private let state: PlywoodState

    private var lastHeight: Int32 = 0

    // Keep track of animations so we can remove them in-flight if needed to reflow.
    private var pointAnimation: Animation? = nil
    private var columnAnimation: Animation? = nil

    private var focusedView: PlywoodView? {
        get {
            if toplevelViews.isEmpty || columnIndexOffsets.isEmpty {
                return nil
            }

            return toplevelViews[focusedRowIndex][columnIndexOffsets[focusedRowIndex].index]
        }
    }

    private var combinedResolution: Area {
        get {
            return state.outputLayout.combinedResolution
        }
    }

    init(state: PlywoodState) {
        self.state = state
    }

    func insert(_ view: PlywoodView) {
        if toplevelViews.isEmpty {
            toplevelViews.append([])
            columnIndexOffsets.append((index: 0, x: 0))
        }

        var views = toplevelViews[focusedRowIndex]

        // Set size of view to "end" of queue.
        if views.isEmpty {
            // Set initial x to stage padding.
            view.position = PointStruct(value: (x: PlywoodSettings.stagePadding, y: 0))
        } else {
            let lastView: PlywoodView = views.last!
            let offsetX: Double = lastView.position.x + Double(lastView.area.width) + PlywoodSettings.stageSpacing

            view.position = PointStruct(value: (x: offsetX, y: 0))
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

        removePointAnimation()

        for i in 0..<toplevelViews.count {
            let views = toplevelViews[i]
            let index = views.firstIndex(where: { $0 === view })

            if index != nil {
                let view = views[index!]

                var offsetX: Double = Double(view.area.width) + PlywoodSettings.stageSpacing
                // Make sure the new "first" item is aligned correctly.
                if index == 0 && views.count > 1 {
                    let secondView = views[1]
                    let secondViewNewX = secondView.position.x - offsetX

                    if secondViewNewX < PlywoodSettings.stagePadding {
                        offsetX -= (PlywoodSettings.stagePadding - secondViewNewX)
                    }
                }

                toplevelViews[i].remove(at: index!)
                // Make sure if we're focused on the last window it will go back.
                if index! != 0 && columnIndexOffsets[i].index >= views.count - 1 {
                    moveLeft()
                }

                // Reflow all views after this index (and add them to tween).
                var actions: [InterpolationAction<Double>] = []
                for j in (index!)..<(views.count - 1) {
                    let posX = toplevelViews[i][j].position.x

                    actions.append(InterpolationAction(
                        from: posX,
                        to: posX - offsetX,
                        duration: 0.5,
                        easing: .sineInOut,
                        update: { val in 
                            self.toplevelViews[i][j].position.x = val
                        }
                    ))
                }

                let actionGroup = ActionGroup(actions: actions)
                pointAnimation = state.scheduler.run(action: actionGroup)

                break
            }
        }
    }

    func focusView(_ view: PlywoodView) {
        let offsetX = columnIndexOffsets[focusedRowIndex].x
        let newIdx = toplevelViews[focusedRowIndex].firstIndex(where: { $0 === view }) ?? columnIndexOffsets[focusedRowIndex].index

        // If occluded (even partially) attempt to refocus.
        if view.position.x - Double(offsetX) < PlywoodSettings.stagePadding {
            moveLeft(amount: columnIndexOffsets[focusedRowIndex].index - newIdx)
            return
        }

        if Int32(view.position.x) + view.area.width - offsetX > combinedResolution.width {
            moveRight(amount: newIdx - columnIndexOffsets[focusedRowIndex].index)
            return
        }
    }

    func moveLeft(amount: Int = 1) {
        if columnIndexOffsets.isEmpty || toplevelViews.isEmpty || amount == 0 {
            return
        }

        if columnIndexOffsets[focusedRowIndex].index > amount - 1 {
            let oldX = Double(columnIndexOffsets[focusedRowIndex].x)

            removeColumnAnimation()
            columnIndexOffsets[focusedRowIndex].index -= amount
            runColumnAnimation(oldX: oldX)
        } else {
            runColumnAnimationElastic(magnitude: 1.0)
        }
        
        focusedView?.focus()
    }

    func moveRight(amount: Int = 1) {
        if columnIndexOffsets.isEmpty || toplevelViews.isEmpty || amount == 0 {
            return
        }

        if columnIndexOffsets[focusedRowIndex].index < toplevelViews[focusedRowIndex].count - amount {
            let oldX = Double(columnIndexOffsets[focusedRowIndex].x)

            removeColumnAnimation()
            columnIndexOffsets[focusedRowIndex].index += amount
            runColumnAnimation(oldX: oldX)
        } else {
            runColumnAnimationElastic(magnitude: -1.0)
        }

        focusedView?.focus()
    }

    func removePointAnimation() {
        if pointAnimation == nil { return }
        state.scheduler.remove(animation: pointAnimation!)
    }

    func removeColumnAnimation() {
        if columnAnimation == nil { return }
        state.scheduler.remove(animation: columnAnimation!)
    }

    func runColumnAnimation(oldX: Double) {
        // Since we've changed the index, focusedView will now be different.
        let currentView = self.focusedView!

        let action = InterpolationAction(
            from: oldX,
            to: currentView.position.x - PlywoodSettings.stagePadding,
            duration: 0.3,
            easing: .sineInOut,
            update: { val in 
                self.columnIndexOffsets[self.focusedRowIndex].x = Int32(val)
            }
        )

        columnAnimation = state.scheduler.run(action: action)
    }

    func runColumnAnimationElastic(magnitude: Double) {
        // Since we've changed the index, focusedView will now be different.
        let x = Double(columnIndexOffsets[focusedRowIndex].x)
        let destX = self.focusedView!.position.x - PlywoodSettings.stagePadding

        let action1 = InterpolationAction(
            from: x,
            to: destX + PlywoodSettings.stageSpacing * magnitude,
            duration: 0.1,
            easing: .sineInOut,
            update: { val in 
                self.columnIndexOffsets[self.focusedRowIndex].x = Int32(val)
            }
        )

        let action2 = InterpolationAction(
            from: destX + PlywoodSettings.stageSpacing * magnitude,
            to: destX,
            duration: 0.1,
            easing: .sineInOut,
            update: { val in 
                self.columnIndexOffsets[self.focusedRowIndex].x = Int32(val)
            }
        )

        let actionSequence = ActionSequence(actions: action1, action2)
        columnAnimation = state.scheduler.run(action: actionSequence)
    }

    func render(output: WLROutput, screenOffsetX: Int, resolution: Area) {
        if toplevelViews.isEmpty || toplevelViews[focusedRowIndex].isEmpty {
            return
        }

        for view in toplevelViews[focusedRowIndex] {
            view.forEachSurface { surface, position in
                let offsetX = self.columnIndexOffsets[self.focusedRowIndex].x

                // Quick return if occluded.
                if position.x - offsetX > resolution.width {
                    return
                }

                view.render(surface: surface, output: output, position: position - (x: offsetX, y: 0))
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

        // Translate by offset.
        let offsetX = columnIndexOffsets[focusedRowIndex].x

        for view in toplevelViews[focusedRowIndex] {
            if let result = view.findSurface(at: position + (x: offsetX, y: 0)) {
                return (
                    view: view,
                    surface: result.surface,
                    coordinates: result.coordinates
                )
            }
        }

        return nil
    }

    func updateOutputMode() {
        let height: Int32 = combinedResolution.height

        // Quick return if our height hasn't changed but we were still (?) notified.
        if lastHeight == height {
            return
        }
        lastHeight = height

        // FIXME: Do other rows? Decide if we should only do this row, or all rows.
        if toplevelViews.isEmpty {
            return
        }

        for view in toplevelViews[focusedRowIndex] {
            centerView(view, height: height)
        }
    }

    private func centerView(_ view: PlywoodView, height: Int32) {
        if height == 0 {
            return
        }

        let areaHeight = Int32(Double(height) * PlywoodSettings.crossAxisFactor)
        // Calculate this so we're actually centered.
        let dy = Double((view.surfaceArea.height - view.area.height) / 2)

        view.position.y = Double(height) * (1 - PlywoodSettings.crossAxisFactor) / 2 - dy
        view.area = (width: view.area.width, height: areaHeight)
    }

    func reflowView(_ view: PlywoodView) {
        // FIXME: This will probably break with multiple screens.
        if toplevelViews.isEmpty {
            return
        }
    
        // Make sure the view's width is bounded.
        view.area.width = min(view.area.width, (combinedResolution.width - 2 * Int32(PlywoodSettings.stagePadding)))
        // Center the view.
        centerView(view, height: combinedResolution.height)

        let views = toplevelViews[focusedRowIndex]
        let index = views.firstIndex(where: { $0 === view })

        // No need to reflow if we're at the end.
        if index == views.count - 1 {
            return
        }

        // FIXME: Update this in the background.
        if index == nil {
            state.logger.warning("Request to reflow view that isn't part of the current row. Ignoring.")
            return
        }

        removePointAnimation()

        let nextX: Double = view.position.x + Double(view.area.width) + PlywoodSettings.stageSpacing
        let offsetX: Double = views[index! + 1].position.x - nextX

        // Reflow all views after this index (and add them to tween).
        var actions: [InterpolationAction<Double>] = []
        for j in (index! + 1)..<(views.count) {
            let posX = toplevelViews[focusedRowIndex][j].position.x

            actions.append(InterpolationAction(
                from: posX,
                to: posX - offsetX,
                duration: 0.5,
                easing: .sineInOut,
                update: { val in 
                    self.toplevelViews[self.focusedRowIndex][j].position.x = val
                }
            ))
        }

        let actionGroup = ActionGroup(actions: actions)
        pointAnimation = state.scheduler.run(action: actionGroup)
    }
}