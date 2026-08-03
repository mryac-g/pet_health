import { Controller } from "@hotwired/stimulus"
import {
  Chart,
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Tooltip
} from "chart.js"

Chart.register(LineController, LineElement, PointElement, LinearScale, CategoryScale, Tooltip)

export default class extends Controller {
  static values = { labels: Array, data: Array, label: String }

  connect() {
    if (this.dataValue.length === 0) return

    this.chart = new Chart(this.element, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            label: this.labelValue,
            data: this.dataValue,
            borderColor: "#4f46e5",
            backgroundColor: "#4f46e5",
            tension: 0.2
          }
        ]
      },
      options: {
        responsive: true,
        scales: {
          y: { beginAtZero: true }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
