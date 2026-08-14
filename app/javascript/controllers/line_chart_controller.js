import { Controller } from "@hotwired/stimulus"
import {
  Chart,
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  Tooltip
} from "chart.js"

Chart.register(LineController, LineElement, PointElement, LinearScale, Tooltip)

// data-line-chart-data-value: [{ x: <recorded_atのミリ秒epoch>, y: <値>,
//   recorded_at: <"YYYY/MM/DD HH:MM">, note: <メモ or null> }, ...]
// X軸を記録の登録順ではなく実際の日時に基づいた連続的な軸にすることで、
// 同日の複数記録が間延びしたり、記録が空いた期間がグラフ上で見えなくなったり
// しないようにしている
function formatDate(epochMs) {
  const date = new Date(epochMs)
  return `${date.getMonth() + 1}/${date.getDate()}`
}

export default class extends Controller {
  static values = { data: Array, label: String }

  connect() {
    if (this.dataValue.length === 0) return

    this.chart = new Chart(this.element, {
      type: "line",
      data: {
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
        animation: false,
        scales: {
          x: {
            type: "linear",
            ticks: { count: 8, callback: (value) => formatDate(value) }
          },
          y: { beginAtZero: true }
        },
        plugins: {
          tooltip: {
            callbacks: {
              title: (items) => items[0].raw.recorded_at,
              label: (item) => {
                const lines = [`${item.dataset.label}: ${item.raw.y}`]
                if (item.raw.note) lines.push(`メモ: ${item.raw.note}`)
                return lines
              }
            }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
