import { Controller } from "@hotwired/stimulus"
import {
  Chart,
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  Tooltip
} from "chart.js"

// ホバーできないPDF・印刷でも各点の値を読み取れるよう、点の近くに値を描画する。
// canvasへ直接描画するため画面・PDF・印刷のいずれでも同じように表示される
const pointValueLabelsPlugin = {
  id: "pointValueLabels",
  afterDatasetsDraw(chart) {
    const { ctx } = chart
    chart.data.datasets.forEach((dataset, datasetIndex) => {
      chart.getDatasetMeta(datasetIndex).data.forEach((point, index) => {
        ctx.save()
        ctx.fillStyle = "#1f2937"
        ctx.font = "10px sans-serif"
        ctx.textAlign = "center"
        ctx.fillText(dataset.data[index].y, point.x, point.y - 8)
        ctx.restore()
      })
    })
  }
}

Chart.register(LineController, LineElement, PointElement, LinearScale, Tooltip, pointValueLabelsPlugin)

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
            // 指定しないとChart.jsが「きりのいい」目盛りを作るために実際の
            // データ範囲より外側まで軸を広げてしまい、期間外に見えてしまう
            min: this.dataValue[0].x,
            max: this.dataValue[this.dataValue.length - 1].x,
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
