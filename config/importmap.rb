# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# chart.jsはpin -> vendorすると内部のchunkファイル(相対import)がPropshaftの
# フィンガープリント付きパスと噛み合わないため、esm.sh上のURLを直接pinする
pin "chart.js", to: "https://esm.sh/chart.js@4.5.1"
