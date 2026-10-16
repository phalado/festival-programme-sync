import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    wait: { type: Number, default: 300 }
  }

  timeout = null

  submit = () => {
    window.clearTimeout(this.timeout)
    this.timeout = window.setTimeout(() => {
      this.element.requestSubmit()
    }, this.waitValue)
  }

  disconnect = () => {
    window.clearTimeout(this.timeout)
  }
}
