import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "label", "iconSun", "iconMoon"]
  static values = {
    darkClass: { type: String, default: "rails-assessment-dark" },
    preferenceKey: { type: String, default: "rails-assessment-theme" },
    default: { type: String, default: "light" }
  }

  connect() {
    this.root = document.body
    this.applyInitialState()
  }

  toggle(event) {
    event.preventDefault()
    this.setDarkState(!this.isDark())
  }

  applyInitialState() {
    const stored = this.storage()?.getItem(this.preferenceKeyValue)
    if (stored === "dark" || stored === "light") {
      this.setDarkState(stored === "dark", false)
      return
    }

    const defaultDark = this.defaultValue === "dark"
    const initialDark = defaultDark || this.isDark()
    this.setDarkState(initialDark, false)
  }

  setDarkState(enabled, persist = true) {
    this.root.classList.toggle(this.darkClassValue, enabled)

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-pressed", enabled ? "true" : "false")
      this.buttonTarget.setAttribute(
        "title",
        enabled ? "Switch to light mode" : "Switch to dark mode"
      )
    }

    this.element.dataset.themeState = enabled ? "dark" : "light"
    this.updateVisualState(enabled)

    if (persist) {
      const storage = this.storage()
      if (storage) {
        storage.setItem(this.preferenceKeyValue, enabled ? "dark" : "light")
      }
    }
  }

  isDark() {
    return this.root.classList.contains(this.darkClassValue)
  }

  updateVisualState(enabled) {
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = enabled ? "Dark mode" : "Light mode"
    }

    if (this.hasIconSunTarget) {
      this.iconSunTarget.classList.toggle("is-active", !enabled)
    }

    if (this.hasIconMoonTarget) {
      this.iconMoonTarget.classList.toggle("is-active", enabled)
    }
  }

  storage() {
    try {
      return window.localStorage
    } catch (_error) {
      return null
    }
  }
}
