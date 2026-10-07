.pragma library

// True for the keys that press a focused button or card: Enter and Space.
// Auto-repeat is ignored so holding a key presses once.
function activates(event) {
    return !event.isAutoRepeat
        && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space);
}
