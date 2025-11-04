import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "nextButton", "backButton", "submitButton", "progress", "startScreen", "content"]
  static values = { total: Number, showStartScreen: Boolean }

  connect() {
    this.currentIndex = 0
    this.started = !this.showStartScreenValue

    if (this.started) {
      this.showCurrentStep()
      this.updateControls()
    }
  }

  start(event) {
    event.preventDefault()
    this.started = true

    if (this.hasStartScreenTarget) {
      this.startScreenTarget.classList.remove("is-active")
    }

    if (this.hasContentTarget) {
      this.contentTarget.classList.add("is-active")
    }

    this.showCurrentStep()
    this.updateControls()
  }

  markAnswered() {
    this.updateControls()
  }

  next(event) {
    event.preventDefault()
    if (!this.currentStepAnswered()) {
      this.highlightCurrentStep()
      return
    }

    if (this.currentIndex < this.lastIndex()) {
      this.currentIndex += 1
      this.showCurrentStep()
    }
  }

  previous(event) {
    event.preventDefault()
    if (this.currentIndex > 0) {
      this.currentIndex -= 1
      this.showCurrentStep()
    }
  }

  submit(event) {
    if (!this.currentStepAnswered()) {
      event.preventDefault()
      this.highlightCurrentStep()
    }
  }

  showCurrentStep() {
    this.stepTargets.forEach((element, index) => {
      element.classList.toggle("is-active", index === this.currentIndex)
    })
    this.updateControls()
  }

  updateControls() {
    if (this.hasBackButtonTarget) {
      this.backButtonTarget.toggleAttribute("disabled", this.currentIndex === 0)
    }

    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.toggleAttribute("hidden", this.currentIndex >= this.lastIndex())
      this.nextButtonTarget.toggleAttribute("disabled", !this.currentStepAnswered())
    }

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.toggleAttribute("hidden", this.currentIndex < this.lastIndex())
    }

    if (this.hasProgressTarget) {
      const total = this.totalValue || this.stepTargets.length
      const progress = Math.min(((this.currentIndex + 1) / total) * 100, 100)
      this.progressTarget.style.width = `${progress}%`
      this.progressTarget.style.setProperty("--progress", `${Math.round(progress)}%`)
    }
  }

  currentStepAnswered() {
    const step = this.stepTargets[this.currentIndex]
    if (!step) return true

    const required = step.dataset.required === "true"
    if (!required) return true

    const inputs = step.querySelectorAll("input[type='radio'], input[type='checkbox']")
    return Array.from(inputs).some((input) => input.checked)
  }

  highlightCurrentStep() {
    const step = this.stepTargets[this.currentIndex]
    if (!step) return

    step.classList.add("shake")
    clearTimeout(this._shakeTimeout)
    this._shakeTimeout = setTimeout(() => step.classList.remove("shake"), 500)
  }

  lastIndex() {
    return Math.max(this.stepTargets.length - 1, 0)
  }
}
