import WidgetKit

/// Call after any data mutation so widgets reflect the new state immediately.
enum WidgetRefresher {
    static func refresh() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
