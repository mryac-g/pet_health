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

// Rails側のNumberFormatterと表記を揃えるため、整数値でも小数第1位まで表示する
// (例: 5 → "5.0")。小数第1位を超える精度の値はそのまま表示する(丸めない)
function formatValue(value) {
  return Number.isInteger(value) ? value.toFixed(1) : String(value)
}

// 目盛り間隔を「1, 2, 5 × 10のべき乗」の中から選ぶことで、期間内の実際の変動幅に
// 対して読みやすい間隔にする。beginAtZero(0始まり)を使わないのは、体重をgで細かく
// 記録する小鳥のように、変動幅がベース値に対してごく小さい場合、0からの固定軸だと
// 目盛りが粗くなりすぎて変動が読み取れなくなるため
function niceStepSize(range, targetTicks = 5) {
  if (range <= 0) return 1

  const rawStep = range / targetTicks
  const magnitude = 10 ** Math.floor(Math.log10(rawStep))
  const residual = rawStep / magnitude

  let niceResidual
  if (residual < 1.5) niceResidual = 1
  else if (residual < 3) niceResidual = 2
  else if (residual < 7) niceResidual = 5
  else niceResidual = 10

  // 変動幅がごく小さい記録(1g未満の差など)でも、目盛りは小数第1位までに留める
  // (0.01や0.05のような細かすぎる間隔にはしない)。10g単位などの通常時は
  // 計算結果が元々0.1を上回るため、この下限が効くことはない
  return Math.max(niceResidual * magnitude, 0.1)
}

export default class extends Controller {
  static values = { data: Array, label: String }

  connect() {
    if (this.dataValue.length === 0) return

    const yValues = this.dataValue.map((point) => point.y)
    const yStepSize = niceStepSize(Math.max(...yValues) - Math.min(...yValues))

    this.chart = new Chart(this.element, {
      type: "line",
      data: {
        datasets: [
          {
            label: this.labelValue,
            data: this.dataValue,
            borderColor: "#4f46e5",
            backgroundColor: "#4f46e5",
            // tensionによるベジェ曲線は、軸をmin/maxでデータ範囲ぴったりに固定していると
            // 端点付近でデータの範囲外まで膨らむ(オーバーシュートする)ことがあり、それが
            // 軸の境界で切り取られて線や点が半分に割れたように見えてしまう。monotoneは
            // 隣接データ点のy範囲を超えないことが保証されるため、この問題が起きない
            cubicInterpolationMode: "monotone"
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
            // 目盛りは記録の日付ではなく均等な時間間隔にする。記録日に目盛りを
            // 合わせると密な時期は詰まり疎な時期はスカスカで不揃いになるため、
            // 記録の有無に関わらず一定間隔で軸を描いた方がものさしとして読みやすい。
            // 個々の記録の正確な日時はサマリー本文の一覧やホバーで確認できる
            ticks: { count: 8, callback: (value) => formatDate(value) }
          },
          y: { ticks: { stepSize: yStepSize } }
        },
        plugins: {
          tooltip: {
            callbacks: {
              title: (items) => items[0].raw.recorded_at,
              label: (item) => {
                const lines = [`${item.dataset.label}: ${formatValue(item.raw.y)}`]
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
