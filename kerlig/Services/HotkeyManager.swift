import AppKit
import Carbon
import Foundation
import UniformTypeIdentifiers

class HotkeyManager {
  private var eventHandler: EventHandlerRef?
  private var callback: ((_ text: String) -> Void)?
  private var hotKeyRef: EventHotKeyRef?

  // Key combination for Option+Space
  private let keyCode = UInt32(kVK_Space)  // Space key
  private let modifiers = UInt32(1 << 11)  // Option key modifier flag (optionKey = 11)

  // Permission state tracking
  private var hasRequestedPermissions = false
  private var lastPermissionCheck: Date? = nil
  private let permissionCheckInterval: TimeInterval = 60 * 5  // 5 minutes

  private var textCaptureService = TextCaptureService()
  private var fileDetailsCapture = FileDetailsCapture()

  // Add a property for the Gemini Vision service
  private var geminiVisionService = GeminiVisionService()

  deinit {
    unregisterHotkey()
    removeKeyPressCallbacks()
  }

  // Register the hotkey with a callback that accepts the selected text
  func registerHotkey(_ callbackFn: @escaping (_ text: String) -> Void) -> Bool {
    self.callback = callbackFn

    // Unregister any existing hotkey first
    unregisterHotkey()

    // Create a unique four-character code for the hotkey
    let signature: OSType = 0x4B72_6C67  // 'Krlg' as hex for Kerlig
    let hotKeyID = EventHotKeyID(signature: signature, id: 1)

    // Register the hotkey
    var hotKeyRef: EventHotKeyRef?
    let registerErr = RegisterEventHotKey(
      keyCode,
      modifiers,
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )

    if registerErr == noErr {
      self.hotKeyRef = hotKeyRef
      NSLog(
        "✅ Successfully registered Option+Space hotkey with keycode \(keyCode) and modifiers \(modifiers)"
      )
      installEventHandler()
      return true
    } else {
      let errorDesc: String
      switch registerErr {
      case -9874: errorDesc = "hotKeyExistsErr: The hotkey is already registered by another app"
      case -50: errorDesc = "paramErr: Invalid parameters"
      case -108: errorDesc = "memFullErr: Not enough memory"
      default: errorDesc = "Error code: \(registerErr)"
      }
      NSLog("❌ Failed to register hotkey: \(errorDesc)")
      return false
    }
  }

  private func installEventHandler() {
    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

    let handlerAddress: EventHandlerUPP = { (nextHandler, eventRef, userData) -> OSStatus in
      var hotKeyID = EventHotKeyID()
      let status = GetEventParameter(
        eventRef,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
      )

      if status == noErr {
        // Only handle our specific hotkey
        if hotKeyID.signature == 0x4B72_6C67 && hotKeyID.id == 1 {
          NSLog("🔥 HotKey event received - signature: \(hotKeyID.signature), id: \(hotKeyID.id)")
          if let userDataPtr = userData {
            let hotkeyManager = Unmanaged<HotkeyManager>.fromOpaque(userDataPtr)
              .takeUnretainedValue()

            // Check if permissions are granted
            if hotkeyManager.hasAccessibilityPermission() {
              NSLog("✅ Accessibility permissions confirmed")
              hotkeyManager.handleHotkeyPressed()
            } else {
              NSLog("❌ No accessibility permissions when hotkey triggered")
              hotkeyManager.verifyAccessibilityPermissions()
            }
          } else {
            NSLog("❌ No userData available in event handler")
          }
        }
      } else {
        NSLog("❌ Failed to get hotkey ID from event: \(status)")
      }

      return noErr
    }

    let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    let osErr = InstallEventHandler(
      GetApplicationEventTarget(),
      handlerAddress,
      1,
      &eventType,
      selfPtr,
      &eventHandler
    )

    if osErr != noErr {
      NSLog("❌ Failed to install event handler: \(osErr)")
    } else {
      NSLog("✅ Event handler installed successfully")
    }
  }

  func unregisterHotkey() {
    if let hotKeyRef = hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
      self.hotKeyRef = nil
    }

    if let eventHandler = eventHandler {
      RemoveEventHandler(eventHandler)
      self.eventHandler = nil
    }
  }

  // Get text from either active selection or recent clipboard content
  func getTextFromSelectionOrClipboard() -> String {
    // Check if the frontmost app is Finder
    if let frontApp = NSWorkspace.shared.frontmostApplication,
      frontApp.bundleIdentifier == "com.apple.finder"
    {

      // Try to get selected files from Finder
      if let fileDetails = getSelectedFileDetailsFromFinder() {
        // Store the file details for later use
        NotificationCenter.default.post(
          name: Notification.Name("FileDetailsSelected"),
          object: nil,
          userInfo: ["fileDetails": fileDetails.toDictionary()]
        )

        // Return a formatted string with file details
        return fileDetails.toFormattedString()
      }
    }

    // If not Finder or no file selection, proceed with normal text capture
    textCaptureService.captureSelectedText()

    // Wait briefly for text capture to complete
    usleep(120000)  // 120ms delay

    // Get the text from the service's property
    let capturedText = textCaptureService.getTextFromSelection()
    if !capturedText.isEmpty {
      NSLog("📋 Got text via textCaptureService: \(capturedText.prefix(20))...")
      return capturedText
    }

    // Check if clipboard was recently changed
    let clipboardWasRecentlyChanged = wasClipboardRecentlyChanged()
    let pasteboard = NSPasteboard.general

    // Then check clipboard if it was recently changed
    if clipboardWasRecentlyChanged,
      let clipboardText = pasteboard.string(forType: .string),
      !clipboardText.isEmpty
    {
      NSLog("📋 Using recent clipboard text: \(clipboardText.prefix(20))...")
      return clipboardText
    }

    // If no active selection but clipboard has content, use that as fallback
    if let clipboardText = pasteboard.string(forType: .string), !clipboardText.isEmpty {
      NSLog("📋 Using clipboard text as fallback: \(clipboardText.prefix(20))...")
      return clipboardText
    }

    // Last resort - force capture via Cmd+C
    NSLog("📋 Attempting to force selection via Cmd+C")
    return getTextViaClipboard()
  }

  // Check if we need to show permissions dialog
  private func shouldShowPermissions() -> Bool {
    // If we've requested recently, don't ask again
    if let lastCheck = lastPermissionCheck,
      Date().timeIntervalSince(lastCheck) < permissionCheckInterval
    {
      return false
    }

    // Check if we have accessibility permission
    let options =
      [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
    let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)

    // Update last check time
    lastPermissionCheck = Date()

    // Only return true if we don't have permission
    return !accessibilityEnabled
  }

  // Ensure all needed permissions are requested
  private func ensureAccessibilityPermissions() {
    if hasRequestedPermissions {
      return
    }

    // Check if we need to request
    if shouldShowPermissions() {
      requestAccessibilityPermissions()
    }

    hasRequestedPermissions = true
  }

  // Request accessibility permissions specifically
  private func requestAccessibilityPermissions() {
    let options =
      [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
    print("Accessibility permissions enabled: \(accessibilityEnabled)")
  }

  // Helper function to get text using clipboard (Save original and restore after)
  private func getTextViaClipboard() -> String {
    // Save current clipboard content
    let pasteboard = NSPasteboard.general
    let originalContents = saveClipboardContent()

    // Clear the clipboard
    pasteboard.clearContents()

    // Improved key simulation with better timing
    simulateKeyCombination(virtualKey: 0x08)  // Command+C (copy)

    // Wait for clipboard to update - use polling for reliability
    var attempts = 0
    var selectedText = ""

    while attempts < 5 {
      // Check if clipboard content is available
      if let text = pasteboard.string(forType: .string), !text.isEmpty {
        selectedText = text
        break
      }

      // Delay before checking again
      usleep(50000)  // 50ms
      attempts += 1
    }

    // Restore original clipboard content
    restoreClipboardContent(originalContents)

    return selectedText
  }

  // Helper to simulate key combinations with proper timing
  private func simulateKeyCombination(
    virtualKey: CGKeyCode,
    withCommand: Bool = true,
    withOption: Bool = false,
    withShift: Bool = false,
    withControl: Bool = false
  ) {
    // Define source
    let source = CGEventSource(stateID: .combinedSessionState)

    // Calculate flags
    var flags: CGEventFlags = []
    if withCommand { flags.insert(.maskCommand) }
    if withOption { flags.insert(.maskAlternate) }
    if withShift { flags.insert(.maskShift) }
    if withControl { flags.insert(.maskControl) }

    // Key down
    if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true) {
      keyDown.flags = flags
      keyDown.post(tap: .cghidEventTap)
    }

    // Small delay between down and up for reliability
    usleep(10000)  // 10ms

    // Key up
    if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false) {
      keyUp.flags = flags
      keyUp.post(tap: .cghidEventTap)
    }
  }

  // Get the frontmost application's bundle identifier
  private func getFrontmostApp() -> String? {
    // Use NSWorkspace to get the frontmost application (no AppleScript required)
    if let frontmostApp = NSWorkspace.shared.frontmostApplication {
      return frontmostApp.bundleIdentifier
    }

    // Final fallback: return current app
    return Bundle.main.bundleIdentifier
  }

  // Accessibility API method (works with most native apps)
  private func getSelectedTextViaAccessibility() -> String? {
    // Get the frontmost application
    guard let app = NSWorkspace.shared.frontmostApplication else { return nil }

    // Log for debugging
    NSLog("🔍 Attempting to get text from: \(app.localizedName ?? "Unknown App")")

    // Create accessibility element for the app
    let axApp = AXUIElementCreateApplication(app.processIdentifier)

    // First, get the focused element
    var focusedElementRef: CFTypeRef?
    let focusedStatus = AXUIElementCopyAttributeValue(
      axApp, kAXFocusedUIElementAttribute as CFString, &focusedElementRef)

    if focusedStatus == .success, let focusedElement = focusedElementRef {
      // Try all possible methods to get selected text
      if let text = extractTextFromElement(focusedElement as! AXUIElement) {
        return text
      }

      // If direct extraction fails, try deeper traversal
      return traverseElementHierarchy(element: focusedElement as! AXUIElement)
    }

    // Try system-wide accessibility element as fallback
    return getSelectedTextViaSystemWide()
  }

  // Helper method to extract text from an element using multiple approaches
  private func extractTextFromElement(_ element: AXUIElement) -> String? {
    // Try selected text attribute first
    var selectedTextRef: CFTypeRef?
    var selectedRangeRef: CFTypeRef?
    var valueRef: CFTypeRef?

    // Check for selected text
    if AXUIElementCopyAttributeValue(
      element, kAXSelectedTextAttribute as CFString, &selectedTextRef) == .success,
      let textAsCFString = selectedTextRef as? String, !textAsCFString.isEmpty
    {
      NSLog("✅ Found text via kAXSelectedTextAttribute")
      return textAsCFString
    }

    // Try to get selection range and then extract text from value
    if AXUIElementCopyAttributeValue(
      element, kAXSelectedTextRangeAttribute as CFString, &selectedRangeRef) == .success,
      AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef) == .success,
      let value = valueRef as? String, !value.isEmpty
    {
      NSLog("✅ Found text via kAXValueAttribute with range")
      return value
    }

    // Try just getting the value
    if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef) == .success,
      let value = valueRef as? String, !value.isEmpty
    {
      NSLog("✅ Found text via kAXValueAttribute")
      return value
    }

    // Try the title attribute (useful for browser content)
    var titleRef: CFTypeRef?
    if AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef) == .success,
      let title = titleRef as? String, !title.isEmpty
    {
      NSLog("✅ Found text via kAXTitleAttribute")
      return title
    }

    // Try description attribute
    var descriptionRef: CFTypeRef?
    if AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descriptionRef)
      == .success,
      let description = descriptionRef as? String, !description.isEmpty
    {
      NSLog("✅ Found text via kAXDescriptionAttribute")
      return description
    }

    return nil
  }

  // Traverse the element hierarchy to find selected text
  private func traverseElementHierarchy(element: AXUIElement, depth: Int = 0) -> String? {
    // Prevent too deep traversal
    if depth > 5 {
      return nil
    }

    // Try to get children
    var childrenRef: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        == .success,
      let children = childrenRef as? [AXUIElement]
    else {
      return nil
    }

    // Try each child
    for child in children {
      // First try to extract text directly from this child
      if let text = extractTextFromElement(child), !text.isEmpty {
        return text
      }

      // Then recursively try its children
      if let text = traverseElementHierarchy(element: child, depth: depth + 1), !text.isEmpty {
        return text
      }
    }

    return nil
  }

  // Try using system-wide accessibility element
  private func getSelectedTextViaSystemWide() -> String? {
    let systemWide = AXUIElementCreateSystemWide()

    var focusedRef: CFTypeRef?
    let status = AXUIElementCopyAttributeValue(
      systemWide, kAXFocusedUIElementAttribute as CFString, &focusedRef)

    if status == .success, let focused = focusedRef {
      return extractTextFromElement(focused as! AXUIElement)
    }

    return nil
  }

  // Save clipboard content safely
  private func saveClipboardContent() -> [ClipboardItem] {
    let pasteboard = NSPasteboard.general
    var savedItems: [ClipboardItem] = []

    // For each pasteboard item, save its data for each type
    if let items = pasteboard.pasteboardItems {
      for item in items {
        var itemTypes: [ClipboardItemType] = []

        for type in item.types {
          if let data = item.data(forType: type) {
            itemTypes.append(ClipboardItemType(type: type, data: data))
          }
        }

        if !itemTypes.isEmpty {
          savedItems.append(ClipboardItem(types: itemTypes))
        }
      }
    }

    return savedItems
  }

  // Restore clipboard content safely
  private func restoreClipboardContent(_ items: [ClipboardItem]) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    for item in items {
      let newItem = NSPasteboardItem()

      for typeItem in item.types {
        newItem.setData(typeItem.data, forType: typeItem.type)
      }

      pasteboard.writeObjects([newItem])
    }
  }

  // Method to paste text back into source application
  func pasteText(_ text: String) -> Bool {
    // Check for required permissions first
    if !hasAutomationPermission() {
      // If no automation permission, show dialog and return failure
      DispatchQueue.main.async {
        self.showAllPermissionsDialog()
      }
      return false
    }

    // Use clipboard method (most reliable without AppleScript)
    let pasteboard = NSPasteboard.general

    // Save the current clipboard content
    let originalContents = saveClipboardContent()

    // Set the new text
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)

    // Try using AppleScript first (this requires automation permission)
    if pasteUsingAppleScript() {
      // Success with AppleScript - restore clipboard after delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.restoreClipboardContent(originalContents)
      }
      return true
    }

    // Fall back to CGEvent if AppleScript fails
    let success = simulateCommandV()

    // Delay restoration to ensure the paste completes
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      // Restore the original clipboard after a short delay
      self.restoreClipboardContent(originalContents)
    }

    return success
  }

  // Show permission dialog if not already granted
  func showAccessibilityPermissionsDialog() {
    // Check both types of permissions
    let hasAccess = hasAccessibilityPermission()
    let hasAutomation = hasAutomationPermission()

    if !hasAccess || !hasAutomation {
      // Use the comprehensive permissions dialog
      showAllPermissionsDialog()
    }
  }

  // Determine if the app has accessibility permissions
  func hasAccessibilityPermission() -> Bool {
    // Clear any potential permission cache to ensure fresh check
    let refreshOptions =
      [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary

    // Multiple check approach to ensure accurate results
    for _ in 1...3 {
      if AXIsProcessTrustedWithOptions(refreshOptions) {
        return true
      }
      // Small delay between checks
      usleep(10000)  // 10ms
    }

    // Try an alternative method by attempting an actual accessibility API call
    if examineProcessPrivileges() {
      return true
    }

    return false
  }

  // Force refresh permissions state and check again
  func refreshAndCheckPermissions() -> Bool {
    // First attempt without showing dialog
    let options =
      [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
    if AXIsProcessTrustedWithOptions(options) {
      return true
    }

    // Try different technique to refresh system permission cache
    let processIdentifier = ProcessInfo.processInfo.processIdentifier
    let axAppElement = AXUIElementCreateApplication(processIdentifier)
    var value: CFTypeRef?
    _ = AXUIElementCopyAttributeValue(axAppElement, kAXTitleAttribute as CFString, &value)

    // Try more aggressive cache clearing approach
    let workspace = NSWorkspace.shared
    let bundlePath = Bundle.main.bundlePath
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    if !bundlePath.isEmpty && !bundleId.isEmpty {
      workspace.launchApplication(
        withBundleIdentifier: bundleId,
        options: [.withoutActivation],
        additionalEventParamDescriptor: nil,
        launchIdentifier: nil)
    }

    // Check again after more thorough refresh attempts
    if AXIsProcessTrustedWithOptions(options) {
      return true
    }

    // Try the process privileges check as a final approach
    return examineProcessPrivileges()
  }

  // This function was accidentally removed in the previous edit
  private func simulateCommandV() -> Bool {
    // Try to simulate Cmd+V using CGEvent API
    guard let cmdDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x37, keyDown: true) else {
      return false
    }
    guard let vDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true) else {
      return false
    }
    guard let vUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false) else {
      return false
    }
    guard let cmdUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x37, keyDown: false) else {
      return false
    }

    // Set command flag for the V key events
    vDown.flags = .maskCommand
    vUp.flags = .maskCommand

    // Post the events in sequence
    cmdDown.post(tap: .cghidEventTap)
    vDown.post(tap: .cghidEventTap)
    vUp.post(tap: .cghidEventTap)
    cmdUp.post(tap: .cghidEventTap)

    // Assume success if we got here without exceptions
    return true
  }

  // Check if permissions were recently granted by examining process attributes
  func examineProcessPrivileges() -> Bool {
    let options =
      [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
    if AXIsProcessTrustedWithOptions(options) {
      return true
    }

    // Try to query our own process attributes as a test
    let pid = ProcessInfo.processInfo.processIdentifier
    let element = AXUIElementCreateApplication(pid)
    var testValue: CFTypeRef?

    // Test multiple attributes for more reliability
    for attribute in [kAXRoleAttribute, kAXTitleAttribute, kAXDescriptionAttribute] as [CFString] {
      let status = AXUIElementCopyAttributeValue(element, attribute, &testValue)
      if status == .success {
        return true
      }
    }

    // One more test - try to get the system-wide AX element
    let systemWideElement = AXUIElementCreateSystemWide()
    var systemValue: CFTypeRef?
    let systemStatus = AXUIElementCopyAttributeValue(
      systemWideElement, kAXRoleAttribute as CFString, &systemValue)

    return systemStatus == .success
  }

  // Advanced permission verification for reliable status detection
  func verifyAccessibilityPermissions(completion: @escaping (Bool) -> Void) {
    // Check with primary method
    if hasAccessibilityPermission() {
      completion(true)
      return
    }

    // Try to restart the accessibility subsystem
    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/System Events.app"))

    // Give System Events a moment to launch
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      // Force quit System Events after it's launched (it auto-restarts)
      let task = Process()
      task.launchPath = "/usr/bin/killall"
      task.arguments = ["System Events"]
      try? task.run()

      // Check if that helped
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if self.hasAccessibilityPermission() {
          completion(true)
          return
        }

        // Try the deep permission check with multiple attempts
        var checkCount = 0
        let maxChecks = 5

        func performDelayedCheck() {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.hasAccessibilityPermission() || self.examineProcessPrivileges() {
              completion(true)
            } else {
              checkCount += 1
              if checkCount < maxChecks {
                performDelayedCheck()
              } else {
                completion(false)
              }
            }
          }
        }

        performDelayedCheck()
      }
    }
  }

  // Handle the hotkey being pressed
  private func handleHotkeyPressed() {
    NSLog("🔑 Handling hotkey press")

    // Call the callback function on the main thread with selected text
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      // Get text (either from selection or clipboard)
      let selectedText = self.getTextFromSelectionOrClipboard()
      NSLog("📋 Selected/clipboard text length: \(selectedText.count)")

      // Call the callback with the text
      if let callback = self.callback {
        callback(selectedText)
      } else {
        NSLog("⚠️ No callback registered to handle hotkey")
      }
    }
  }

  // Improved permission handling methods
  func showAllPermissionsDialog() {
    // Check both permission types
    let hasAccessibility = hasAccessibilityPermission()
    let hasAutomation = hasAutomationPermission()

    if !hasAccessibility || !hasAutomation {
      // Show a comprehensive permissions dialog
      let alert = NSAlert()
      alert.messageText = "Permissions Required"

      // Customize message based on what's missing
      if !hasAccessibility && !hasAutomation {
        alert.informativeText = """
          Streamline needs two types of permissions to function properly:

          1. Accessibility - to capture selected text
          2. Automation - to control System Events for pasting

          Please click "Open Settings" and enable both permissions.
          """
      } else if !hasAccessibility {
        alert.informativeText = """
          Streamline needs Accessibility permission to capture selected text.

          Please grant accessibility permission in System Settings → Privacy & Security → Accessibility.
          """
      } else {
        alert.informativeText = """
          Streamline needs Automation permission to control System Events for pasting text.

          Please grant automation permission in System Settings → Privacy & Security → Automation.
          """
      }

      alert.addButton(withTitle: "Open Settings")
      alert.addButton(withTitle: "Try Manual Fix")
      alert.addButton(withTitle: "Later")

      let response = alert.runModal()

      if response == .alertFirstButtonReturn {
        // Open directly to Privacy settings
        if #available(macOS 13.0, *) {
          if !hasAccessibility {
            NSWorkspace.shared.open(
              URL(
                string:
                  "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
          } else {
            NSWorkspace.shared.open(
              URL(
                string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
              )!)
          }
        } else {
          NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
      } else if response == .alertSecondButtonReturn {
        // Try manual permission fixing
        manuallyFixPermissions()
      }
    }
  }

  // Check for automation permissions
  func hasAutomationPermission() -> Bool {
    // Create a scripting addition handler to check permissions
    let scriptSource = """
      tell application "System Events"
          return true
      end tell
      """

    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: scriptSource) {
      let result = scriptObject.executeAndReturnError(&error)
      // If no error, we have permission
      if error == nil {
        return true
      }
    }

    // Try with a different approach - check if we can access properties
    let systemEventsApp = NSRunningApplication.runningApplications(
      withBundleIdentifier: "com.apple.systemevents"
    ).first
    if let processID = systemEventsApp?.processIdentifier {
      let element = AXUIElementCreateApplication(processID)
      var value: CFTypeRef?
      let status = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value)
      if status == .success {
        return true
      }
    }

    return false
  }

  // Manual permission fixing approach
  private func manuallyFixPermissions() {
    // Show a processing dialog
    let processingAlert = NSAlert()
    processingAlert.messageText = "Attempting to fix permissions..."
    processingAlert.informativeText =
      "Please wait while we attempt to repair the permission settings."

    // Show alert without blocking the thread
    let alertWindow = processingAlert.window
    processingAlert.beginSheetModal(for: alertWindow) { _ in }

    DispatchQueue.global(qos: .userInitiated).async {
      // Step 1: Restart System Events
      self.restartSystemEvents()

      // Step 2: Force Automation permission prompt
      self.promptForAutomationPermission()

      // Step 3: Check if we now have permissions
      let hasAccess = self.hasAccessibilityPermission()
      let hasAutomation = self.hasAutomationPermission()

      DispatchQueue.main.async {
        // Dismiss the processing dialog
        alertWindow.sheetParent?.endSheet(alertWindow)

        // Show results
        let resultAlert = NSAlert()
        if hasAccess && hasAutomation {
          resultAlert.messageText = "Permissions Fixed"
          resultAlert.informativeText =
            "All required permissions are now granted. The app should work properly."
        } else {
          resultAlert.messageText = "Permission Fix Incomplete"
          resultAlert.informativeText = """
            Some permissions are still missing:
            - Accessibility: \(hasAccess ? "✓" : "✗")
            - Automation: \(hasAutomation ? "✓" : "✗")

            Please try to grant the missing permissions manually through System Settings.
            """

          // Add a button to open settings
          resultAlert.addButton(withTitle: "Open Settings")
          resultAlert.addButton(withTitle: "Close")
        }

        let response = resultAlert.runModal()
        if response == .alertFirstButtonReturn && (!hasAccess || !hasAutomation) {
          // Open settings
          if #available(macOS 13.0, *) {
            if !hasAccess {
              NSWorkspace.shared.open(
                URL(
                  string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
              )
            } else {
              NSWorkspace.shared.open(
                URL(
                  string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
            }
          } else {
            NSWorkspace.shared.open(
              URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
          }
        }
      }
    }
  }

  // Explicitly prompt for automation permission
  private func promptForAutomationPermission() {
    // This will force the automation permission dialog to appear
    let script = """
      tell application "System Events"
          set frontProcess to first process where it is frontmost
          set frontAppName to name of frontProcess
          return frontAppName
      end tell
      """

    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary?
    appleScript?.executeAndReturnError(&error)
  }

  // Restart System Events application
  private func restartSystemEvents() {
    // Launch and then forcefully quit System Events
    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/System Events.app"))

    // Wait for it to launch
    Thread.sleep(forTimeInterval: 0.5)

    // Kill the System Events process (it will auto-restart by the system)
    let task = Process()
    task.launchPath = "/usr/bin/killall"
    task.arguments = ["System Events"]

    do {
      try task.run()
      task.waitUntilExit()

      // Give System Events time to restart
      Thread.sleep(forTimeInterval: 1.0)
    } catch {
      print("Error restarting System Events: \(error)")
    }
  }

  // Alternative paste method using AppleScript
  private func pasteUsingAppleScript() -> Bool {
    let script = """
      tell application "System Events"
          tell process (path to frontmost application as text)
              keystroke "v" using command down
          end tell
      end tell
      """

    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary?
    appleScript?.executeAndReturnError(&error)

    return error == nil
  }

  // Verify accessibility permissions and show dialog if needed
  func verifyAccessibilityPermissions() {
    if !hasAccessibilityPermission() || !hasAutomationPermission() {
      NSLog("⚠️ App needs permissions")
      showAllPermissionsDialog()
    }
  }

  // Set up clipboard monitoring for better text capture
  func setupClipboardMonitoring() {
    // Track the initial clipboard state
    let pasteboard = NSPasteboard.general
    let initialChangeCount = pasteboard.changeCount

    // Store in UserDefaults for persistence
    UserDefaults.standard.set(initialChangeCount, forKey: "lastPasteboardChangeCount")
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastPasteboardChangeTime")

    // Set up a timer to monitor clipboard changes
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      guard self != nil else { return }

      let currentChangeCount = pasteboard.changeCount
      let lastChangeCount = UserDefaults.standard.integer(forKey: "lastPasteboardChangeCount")

      if currentChangeCount != lastChangeCount {
        // Clipboard content has changed
        UserDefaults.standard.set(currentChangeCount, forKey: "lastPasteboardChangeCount")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastPasteboardChangeTime")

        // For debugging
        if let clipText = pasteboard.string(forType: .string)?.prefix(20) {
          NSLog("📋 Clipboard changed: \(clipText)...")
        }
      }
    }
  }

  // Modified method to check if clipboard was recently changed
  private func wasClipboardRecentlyChanged() -> Bool {
    let now = Date().timeIntervalSince1970
    let lastChange = UserDefaults.standard.double(forKey: "lastPasteboardChangeTime")

    // Consider "recent" if within the last 5 seconds
    return (now - lastChange) < 5.0
  }

  // Process selected text with specific AI action and handle file details
  func processSelectedTextWithAction(
    action: AIAction, appState: AppState, floatingPanel: FloatingPanelController
  ) {
    // Check if this is an image analysis action
    if action == .analyzeImage {
      // For image analysis, use Gemini Vision
      processSelectedImageWithGeminiVision(appState: appState, floatingPanel: floatingPanel)
      return
    }

    // First get the selected text using our reliable methods
    let selectedText = getTextFromSelectionOrClipboard()

    // Check if this might be a file selection from Finder
    let mightBeFileSelection =
      NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"

    if !selectedText.isEmpty {
      if mightBeFileSelection {
        // Try to get file details
        if let fileDetails = getSelectedFileDetailsFromFinder() {
          // For image files and analyze image action, use Gemini Vision
          if action == .analyzeImage && fileDetails.type.lowercased().contains("image") {
            processSelectedImageWithGeminiVision(
              prompt: selectedText.isEmpty ? nil : selectedText,
              appState: appState,
              floatingPanel: floatingPanel)
            return
          }

          // Update app state with file details
          appState.selectedText = selectedText
          appState.updateFileDetails(fileDetails.toDictionary())

          // Set additional metadata about the selected action
          appState.textMetadata["action"] = action.title
          appState.textMetadata["actionType"] = action.rawValue

          // Show the panel with the text representation of file details
          floatingPanel.showPanel(with: selectedText, appState: appState)
          return
        }
      }

      // Regular text selection handling
      appState.selectedText = selectedText
      appState.updateSelectedText(selectedText, source: .directSelection)

      // Set additional metadata about the selected action
      appState.textMetadata["action"] = action.title
      appState.textMetadata["actionType"] = action.rawValue

      // Show the panel with this text
      floatingPanel.showPanel(with: selectedText, appState: appState)
    } else {
      // Show empty selection panel if no text is selected
      floatingPanel.showEmptySelectionPanel(appState: appState)
    }
  }

  // Helper method to perform text transformations
  func processTextTransformation(
    text: String, action: AIAction, completion: @escaping (String) -> Void
  ) {
    // This is a simplified version - in a full implementation you'd likely call an AI API

    switch action {
    case .fixSpellingGrammar:
      // Simple simulation of spelling/grammar correction
      var correctedText = text
      correctedText = correctedText.replacingOccurrences(of: " i ", with: " I ")
      correctedText = correctedText.replacingOccurrences(of: " dont ", with: " don't ")
      correctedText = correctedText.replacingOccurrences(of: " cant ", with: " can't ")
      correctedText = correctedText.replacingOccurrences(of: " wont ", with: " won't ")
      completion(correctedText)

    case .improveWriting:
      // Simulate improved writing
      completion("Enhanced version: \(text)")

    case .translate:
      // Simulate translation
      completion("Translation: \(text)")

    case .makeShorter:
      // Actually make it shorter by truncating
      let words = text.split(separator: " ")
      let shortenedCount = max(3, Int(Double(words.count) * 0.6))
      let shortenedText = words.prefix(shortenedCount).joined(separator: " ")
      completion("Shortened: \(shortenedText)")
    case .analyzeFile:
      // Actually make it shorter by truncating
      let words = text.split(separator: " ")
      let shortenedCount = max(3, Int(Double(words.count) * 0.6))
      let shortenedText = words.prefix(shortenedCount).joined(separator: " ")
      completion("Shortened: \(shortenedText)")
    case .analyzeImage:
      // Actually make it shorter by truncating
      let words = text.split(separator: " ")
      let shortenedCount = max(3, Int(Double(words.count) * 0.6))
      let shortenedText = words.prefix(shortenedCount).joined(separator: " ")
      completion("Shortened: \(shortenedText)")
    }
  }

  // Enhanced text source detection
  func determineTextSource(text: String) -> TextSource {
    // Check if text matches current clipboard contents
    if let clipboardText = NSPasteboard.general.string(forType: .string),
      text == clipboardText
    {
      return .clipboard
    }

    // Try to determine if it came from user input or selection
    // This is a heuristic approach that could be improved

    // Check if frontmost app is our own app
    if let frontApp = NSWorkspace.shared.frontmostApplication,
      frontApp.bundleIdentifier == Bundle.main.bundleIdentifier
    {
      return .userInput
    }

    // If the text contains multiple lines or is longer than typically manually typed
    if text.contains("\n") || text.count > 100 {
      return .directSelection
    }

    // Default to direct selection
    return .directSelection
  }

  // Public method to simulate key presses
  func simulateKeyPress(
    virtualKey: CGKeyCode, withCommand: Bool = false, withOption: Bool = false,
    withShift: Bool = false, withControl: Bool = false
  ) {
    simulateKeyCombination(
      virtualKey: virtualKey, withCommand: withCommand, withOption: withOption,
      withShift: withShift, withControl: withControl)
  }

  // Helper method to set up key press detection with a callback
  // This approach uses NSEvent monitoring instead of Carbon hotkeys
  private var keyPressEventMonitors: [Any] = []

  func simulateKeyPressWithCallback(
    keyCode: CGKeyCode, withCommand: Bool = false, withOption: Bool = false,
    callback: @escaping () -> Void
  ) {
    // Create a global event monitor for key down events
    let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
      // Check if the key code matches
      if event.keyCode == keyCode {
        // Check modifiers
        let hasCommand = event.modifierFlags.contains(.command)
        let hasOption = event.modifierFlags.contains(.option)

        // Trigger callback if modifiers match
        if (withCommand == hasCommand) && (withOption == hasOption) {
          NSLog("🔑 Detected Command+P hotkey from event monitor")
          callback()
        }
      }
    }

    // Store the monitor to prevent it from being deallocated
    if let monitor = monitor {
      keyPressEventMonitors.append(monitor)
    }

    // Also create a local monitor for when our app is active
    let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      // Check if the key code matches
      if event.keyCode == keyCode {
        // Check modifiers
        let hasCommand = event.modifierFlags.contains(.command)
        let hasOption = event.modifierFlags.contains(.option)

        // Trigger callback if modifiers match
        if (withCommand == hasCommand) && (withOption == hasOption) {
          NSLog("🔑 Detected Command+P hotkey from local monitor")
          callback()
          return nil  // Consume the event
        }
      }
      return event
    }

    // Store the local monitor as well
    if let localMonitor = localMonitor {
      keyPressEventMonitors.append(localMonitor)
    }

    NSLog(
      "✅ Set up key press detection for keyCode: \(keyCode) with Command: \(withCommand), Option: \(withOption)"
    )
  }

  // Clean up event monitors when no longer needed
  func removeKeyPressCallbacks() {
    for monitor in keyPressEventMonitors {
      NSEvent.removeMonitor(monitor)
    }
    keyPressEventMonitors.removeAll()
  }

  // Comprehensive permission check with helper method to avoid code duplication
  func checkAndRefreshPermissions(completion: @escaping (Bool) -> Void) {
    // First check if we already have permissions
    if hasAccessibilityPermission() {
      completion(true)
      return
    }

    // Try refreshing permissions
    if refreshAndCheckPermissions() {
      completion(true)
      return
    }

    // Advanced verification with dynamic subsystem restart
    verifyAccessibilityPermissions { granted in
      if granted {
        completion(true)
      } else {
        // Show a dialog to the user
        let dialog = NSAlert()
        dialog.messageText = "Permission Error"
        dialog.informativeText = "Please grant accessibility permissions to Kerlig."
        dialog.addButton(withTitle: "Open Settings")
        dialog.addButton(withTitle: "Close")

        let response = dialog.runModal()
        if response == .alertFirstButtonReturn {
          // Open System Settings
          if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(
              URL(
                string:
                  "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
          } else {
            NSWorkspace.shared.open(
              URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
          }
        }

        completion(false)
      }
    }
  }

  // Get selected file details from Finder using pasteboard
  private func getSelectedFileDetailsFromFinder() -> FileDetailsCapture.FileDetails? {
    NSLog("🔍 Attempting to get file from Finder via pasteboard")

    // Use the general pasteboard to access file URLs
    let pasteboard = NSPasteboard.general

    // Check if there are file URLs on the pasteboard
    if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
      !fileURLs.isEmpty
    {
      NSLog("✅ Found \(fileURLs.count) files on pasteboard")

      // Just use the first file for now
      let fileURL = fileURLs[0]

      // Make sure it's a file URL
      if fileURL.isFileURL {
        NSLog("📄 Selected file: \(fileURL.path)")
        return fileDetailsCapture.captureDetails(from: fileURL)
      }
    }

    // Fallback approach: simulate a copy operation to get file URLs into the pasteboard
    simulateKeyCombination(virtualKey: 0x08)  // Command+C (copy)

    // Wait briefly for the copy to complete
    usleep(100000)  // 100ms

    // Try again to read file URLs from the pasteboard
    if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
      !fileURLs.isEmpty
    {
      NSLog("✅ Found \(fileURLs.count) files on pasteboard after copy")

      // Just use the first file for now
      let fileURL = fileURLs[0]

      // Make sure it's a file URL
      if fileURL.isFileURL {
        NSLog("📄 Selected file: \(fileURL.path)")
        return fileDetailsCapture.captureDetails(from: fileURL)
      }
    }

    NSLog("❌ Could not find any files on pasteboard")
    return nil
  }

  // Get multiple selected file details from Finder using pasteboard
  private func getMultipleSelectedFilesFromFinder() -> [FileDetailsCapture.FileDetails] {
    NSLog("🔍 Attempting to get multiple files from Finder via pasteboard")

    // Use the general pasteboard to access file URLs
    let pasteboard = NSPasteboard.general

    // Try to read file URLs from the pasteboard
    if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
      !fileURLs.isEmpty
    {
      NSLog("✅ Found \(fileURLs.count) files on pasteboard")

      // Process each file
      var fileDetailsList: [FileDetailsCapture.FileDetails] = []
      for fileURL in fileURLs {
        if fileURL.isFileURL, let details = fileDetailsCapture.captureDetails(from: fileURL) {
          fileDetailsList.append(details)
        }
      }

      return fileDetailsList
    }

    // If no files found, try simulating copy and checking again
    simulateKeyCombination(virtualKey: 0x08)  // Command+C (copy)

    // Wait briefly for the copy to complete
    usleep(100000)  // 100ms

    // Try again to read file URLs from the pasteboard
    if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
      !fileURLs.isEmpty
    {
      NSLog("✅ Found \(fileURLs.count) files on pasteboard after copy")

      // Process each file
      var fileDetailsList: [FileDetailsCapture.FileDetails] = []
      for fileURL in fileURLs {
        if fileURL.isFileURL, let details = fileDetailsCapture.captureDetails(from: fileURL) {
          fileDetailsList.append(details)
        }
      }

      return fileDetailsList
    }

    NSLog("❌ Could not find any files on pasteboard")
    return []
  }

  // Add a method to handle Gemini Vision analysis of images
  func processSelectedImageWithGeminiVision(
    prompt: String? = nil, appState: AppState, floatingPanel: FloatingPanelController
  ) {
    NSLog("🔍 Attempting to process selected image with Gemini Vision")

    // Get file details from Finder
    if let fileDetails = getSelectedFileDetailsFromFinder() {
      // Make sure it's an image
      if fileDetails.type.lowercased().contains("image") {
        // Show loading state
        DispatchQueue.main.async {
          appState.isProcessing = true
          appState.selectedText = "Analyzing image with Gemini Vision..."
          appState.updateFileDetails(fileDetails.toDictionary())
          floatingPanel.showPanel(with: "Processing image...", appState: appState)
        }

        // Get the prompt from the user or use default
        let imagePrompt = prompt ?? "Describe this image in detail and analyze its contents."

        // Process the image with Gemini Vision
        geminiVisionService.processFileDetails(fileDetails: fileDetails, prompt: imagePrompt) {
          result in
          DispatchQueue.main.async {
            // Update state when processing completes
            appState.isProcessing = false

            switch result {
            case .success(let response):
              // Update UI with successful response
              appState.aiResponse = response
              floatingPanel.updateResponse(response)

            case .failure(let error):
              // Show error message
              let errorMessage = "Error analyzing image: \(error.localizedDescription)"
              appState.aiResponse = errorMessage
              floatingPanel.updateResponse(errorMessage)
            }
          }
        }
      } else {
        // Not an image
        let message = "Selected file is not an image. Please select an image file."
        NSLog("⚠️ \(message)")
        DispatchQueue.main.async {
          appState.selectedText = message
          floatingPanel.showPanel(with: message, appState: appState)
        }
      }
    } else {
      // No file selected
      let message = "No image file selected. Please select an image in Finder."
      NSLog("⚠️ \(message)")
      DispatchQueue.main.async {
        appState.selectedText = message
        floatingPanel.showPanel(with: message, appState: appState)
      }
    }
  }
}

// Helper structs to store pasteboard content safely
struct ClipboardItemType {
  let type: NSPasteboard.PasteboardType
  let data: Data
}

struct ClipboardItem {
  let types: [ClipboardItemType]
}

// Helper extension for String
extension Optional where Wrapped == String {
  var isNilOrEmpty: Bool {
    return self == nil || self!.isEmpty
  }
}
